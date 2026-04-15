Script.Load("lua/Balance.lua")
Script.Load("lua/NS2Utility.lua")
Script.Load("lua/bots/CommonAlienActions.lua")

Script.Load("lua/bishop/global/Stuck.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local AddMoveCommand = AddMoveCommand
local band = bit.band
local HandleAlienTunnelMove = HandleAlienTunnelMove
local Math_DotProduct = Math.DotProduct

local StuckMove = Bishop.global.stuck.StuckMove

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kBlinkCosTolerance = 0.6  -- Cosine of intended to actual move direction.
local kGoalSpeed         = 11.5 -- Blink when below this speed.
local kJumpDistanceSqr   = 2    -- Stop jumping when this close to target.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kBlinkEnergyCost = kBlinkEnergyCost

--------------------------------------------------------------------------------
-- Simplify movement logic to allow for more Blinking and Metabolize spam.
--------------------------------------------------------------------------------

function Bishop.alien.fade.DoMove(from, to, bot, brain, move)
  local fade = bot:GetPlayer()
  if StuckMove(bot, fade, move, fade:GetOrigin(), to) then
    return
  end

  if HandleAlienTunnelMove(from, to, bot, brain, move) then
    return
  end

  -- The Fade will Blink to maintain speed or to correct its motion when
  -- drifting in an unintended direction (i.e. sideways).
  if fade:GetEnergy() >= kBlinkEnergyCost
      and (fade:GetVelocityLength() < kGoalSpeed
      or Math_DotProduct(bot:GetMotion().currMoveDir,
        fade:GetVelocity():GetUnit()) < kBlinkCosTolerance) then
    move.commands = AddMoveCommand(move.commands, Move.SecondaryAttack)

  -- Maximize use of Metabolize when Blink and Swipe are inactive.
  elseif band(move.commands, Move.PrimaryAttack) == 0 then
    move.commands = AddMoveCommand(move.commands, Move.MovementModifier)
  end

  -- Chain bunnyhops correctly to maintain momentum unless at the target.
  if (to - from):GetLengthSquared() > kJumpDistanceSqr
      and not fade.jumpHandled then
    move.commands = AddMoveCommand(move.commands, Move.Jump)
  end

  -- Crouch when under fire to reduce damage.
  -- See: https://www.youtube.com/watch?v=Ivt6WfQStes
  if fade:GetIsUnderFire() then
    move.commands = AddMoveCommand(move.commands, Move.Crouch)
  end
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
