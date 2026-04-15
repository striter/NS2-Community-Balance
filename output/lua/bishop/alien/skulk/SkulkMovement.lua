Script.Load("lua/Balance.lua")
Script.Load("lua/NS2Utility.lua")
Script.Load("lua/bots/CommonAlienActions.lua")

Script.Load("lua/bishop/global/PathHistory.lua")
Script.Load("lua/bishop/global/Stuck.lua")
Script.Load("lua/bishop/global/Vents.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local AddMoveCommand = AddMoveCommand
local DotProduct = Math.DotProduct
local HandleAlienTunnelMove = HandleAlienTunnelMove
local random = math.random
local RemoveMoveCommand = RemoveMoveCommand
local Shared_GetTime = Shared.GetTime

local HandleVentMove = Bishop.global.vents.HandleVentMove
local StuckMove = Bishop.global.stuck.StuckMove
local UpdatePathHistory = Bishop.global.pathHistory.UpdatePathHistory

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kBunnyhopDistSqr  = 5 * 5 -- Bunnyhop when moving long distances.
local kLeapDistSqr      = 3 * 3 -- Leap to close gaps.

local kDesiredSpeed     = 7.0   -- Build speed before attempting a bunnyhop.
local kLeapSpeed        = 9.0   -- Leap when it will provide a bonus.
local kSlowSpeed        = 5.0   -- Enforce a bunnyhop cooldown below this speed.
local kReserveEnergy    = 15    -- Don't leap if it will drain too much energy.

local kExtraJumpChance  = 0.01  -- Probability per tick to jump in combat.
local kTimeBetweenJumps = 0.45  -- Seconds between successive jumps.
local kTimeJumpRecovery = 2.00  -- Seconds between bunnyhop attempts.
local kTimeBetweenLeaps = 0.85  -- Seconds between successive leaps.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kLeapEnergyCost = kLeapEnergyCost

--------------------------------------------------------------------------------
-- Replace much of the randomized logic with goal-oriented logic.
--------------------------------------------------------------------------------
-- Chain jumps properly when trying to move fast and recognize when a bunnyhop
-- has failed (moving too slowly) and reset it.

function Bishop.alien.skulk.DoMove(from, to, bot, brain, move)
  if brain.hasMoved then return end

  local skulk = bot:GetPlayer()
  if StuckMove(bot, skulk, move, skulk:GetOrigin(), to) then
    return
  end

  local distance
  -- If the tunnel manager has control of the Skulk, abort early to prevent
  -- messing up its inputs.
  do
    local term, moveTo
    term, distance, moveTo = HandleAlienTunnelMove(from, to, bot, brain, move)
    if term then
      return
    else
      if moveTo then
        to = moveTo
      end
      term, distance, moveTo = HandleVentMove(from, to, bot, brain, move)
      if term then
        return
      end
    end
    if moveTo then
      to = moveTo
    end
  end

  -- Determine if the desired point is way higher or lower and adjust the camera
  -- angle to apply the correction.
  local targetHigh = distance > 2.5 and distance < (to.y - from.y) * 1.5
  local targetLow = distance > 2.5 and distance < -(to.y - from.y) * 1.5
  local motion = bot:GetMotion()
  local time = Shared_GetTime()

  -- When the target is up high, scurry up the wall with random jitter to avoid
  -- props and obstacles.
  if targetHigh then
    motion:SetDesiredViewTarget(to + Vector(0, distance, 0))

    local jitter = Vector(random() - 0.5, random() - 0.5, random() - 0.5) * 0.25
    motion:SetDesiredMoveDirection((to - from):GetUnit() + jitter)
    move.commands = AddMoveCommand(move.commands, Move.Jump)

  -- When the target is too low, dive the camera down and force detachment from
  -- the wall.
  elseif targetLow then
    motion:SetDesiredViewTarget(to + Vector(0, -distance, 0))
    move.commands = AddMoveCommand(move.commands, Move.Jump)
    move.commands = AddMoveCommand(move.commands, Move.Crouch)
  end

  -- The Skulk has been declared stuck, head for the floor.
  -- The variable isJammedUp is disabled in vanilla, but I leave it here incase
  -- work is done in the future.
  if brain.isJammedUp and brain.lastStuckFallTime + brain.kSkulkStuckFallTime
      >= time then
    move.commands = RemoveMoveCommand(move.commands, Move.Jump)
    move.commands = AddMoveCommand(move.commands, Move.Crouch)
    motion:SetDesiredMoveDirection(Vector(0, -1, 0))
    return
  end

  local sneaking = skulk.movementModiferState -- UWE's typo, it's intentional.
    and not skulk:GetIsInCombat()
  local distanceSquared = (to - from):GetLengthSquared()
  local wrongDirection = DotProduct(motion.currMoveDir,
    skulk:GetVelocity():GetUnit()) < 0.2

  -- Bunnyhop when the target is far. Disabled if the Skulk is trying to reach a
  -- high target.
  if not targetHigh and not sneaking and distanceSquared > kBunnyhopDistSqr then
    move.commands = AddMoveCommand(move.commands, Move.Crouch)

    -- Abort a bunnyhop if the Skulk has devolved to hopping slower than run
    -- speed. This allows the skulk to rebuild run speed on the ground before
    -- the next attempt.
    if not skulk.jumpHandled
        and skulk:GetVelocity():GetLengthXZ() > kDesiredSpeed
        and not wrongDirection
        and (not skulk.timeOfLastJump or skulk.timeOfLastJump
          + kTimeBetweenJumps < time)
        and brain.nextBunnyhopTime < time then
      move.commands = AddMoveCommand(move.commands, Move.Jump)

    -- Enforce a cooldown for the next bunnyhop attempt to allow the Skulk to
    -- regain forward momentum.
    elseif skulk:GetVelocity():GetLengthXZ() < kSlowSpeed then
      brain.nextBunnyhopTime = time + kTimeJumpRecovery
    end
  
  -- Throw in random jumps when in combat to confuse the target.
  elseif not sneaking then
    move.commands = AddMoveCommand(move.commands, Move.Crouch)
    if random() < kExtraJumpChance then
      move.commands = AddMoveCommand(move.commands, Move.Jump)
    end
  end

  -- Leap if the Skulk is below speed or drifting in an undesired direction.
  if not sneaking and distanceSquared > kLeapDistSqr
      and time >= brain.nextLeapTime
      and skulk:GetEnergy() > kLeapEnergyCost + kReserveEnergy
      and (skulk:GetVelocityLength() < kLeapSpeed or wrongDirection)
      and skulk:GetVelocityLength() > 1 then
    move.commands = AddMoveCommand(move.commands, Move.SecondaryAttack)
    brain.nextLeapTime = time + kTimeBetweenLeaps
  end

  -- UpdatePathHistory(skulk)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
