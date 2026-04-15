Script.Load("lua/NS2Utility.lua")
Script.Load("lua/Utility.lua")
Script.Load("lua/bots/CommonAlienActions.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/global/Stuck.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local AddMoveCommand = AddMoveCommand
local DebugLine = DebugLine
local HandleAlienTunnelMove = HandleAlienTunnelMove
local DotProduct = Math.DotProduct ---@type function
local GetTime = Shared.GetTime ---@type function
local Sin = math.sin

local GetClosestPointIndex = Bishop.lib.math.GetClosestPointIndex
local StuckMove = Bishop.global.stuck.StuckMove

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kRetreatDistance = 16 -- Target distance for retreat.

local kStuckProgress = 2  -- Minimum acceptable progress per threshold ticks.
local kStuckThreshold = 8 -- Number of stuck ticks before a path is deleted.

local kFlightHeight = 3                              -- Standard height.
local kFlightHeightAmplitude = 0.5                   -- Max variation up & down.
local kHeightVariationPanicSpeed = 1 / (2 * math.pi) -- Retreat vertical glide.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kDebug = Bishop.debug.lerkPathing

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

local function FindBackwardsPathPoint(to, targetLength, iter, brain)
  -- The vanilla FindBackwardsPathPoint always returned iter. Perhaps this was
  -- an oversight.
  for i = iter, 1, -1 do
    local length = (brain.savedPathPoints[i] - to):GetLengthXZ()
    if length >= targetLength then
      return i
    end
  end

  -- The path wasn't long enough, so return the furthest point possible.
  return 1
end

local function FindClosestPathPoint(from, iter, brain)
--[[   local currentPoint = brain.savedPathPoints[iter]
  local currentLength = (currentPoint - from):GetLengthXZ()

  for i = iter, #brain.savedPathPoints do
    local length = (brain.savedPathPoints[i] - from):GetLengthXZ()
    if length < currentLength then
      iter = i
      currentLength = length
    else
      break
    end
  end

  for i = iter, 0, -1 do
    local length = (brain.savedPathPoints[i] - from):GetLengthXZ()
    if length < currentLength then
      iter = i
      currentLength = length
    else
      break
    end
  end ]]
  local currentLength = math.huge

  for i = 1, #brain.savedPathPoints do
    local length = (brain.savedPathPoints[i] - from):GetLengthXZ()
    if length < currentLength then
      iter = i
      currentLength = length
    end
  end

  return iter
end

-- Passing in a memory uses the existing path to the target only if the path has
-- a valid route backwards to kRetreatDistance, otherwise a new path is
-- generated using the nearest Hive. Passing in nil for the memory will force a
-- path generation from the nearest Hive.
-- TODO: This is a contender for being used with more types of bots, maybe even
-- marines (to the nearest Command Station, etc.).
function Bishop.alien.lerk.GenerateRetreatPath(from, to, memory, brain)
  if (to - from):GetLengthXZ() < kRetreatDistance then
    local hive = brain:GetSenses():Get("nearestHive")
    from = hive.hive and hive.hive:GetOrigin() or from
  end

  local reachable
  if memory and memory.entId == brain.lastAttackEntityId
      and brain.savedPathPoints and #brain.savedPathPoints > 0
      and (to - brain.savedPathPoints[1]):GetLengthXZ() < kRetreatDistance then
    brain.savedPathPointsIt = GetClosestPointIndex(brain.savedPathPoints, from)
    --brain.savedPathPointsIt = FindClosestPathPoint(from,
    --  brain.savedPathPointsIt, brain)
  else
    brain.savedPathPoints = PointArray()
    brain.savedPathPointsIt = 1

    reachable = Pathing.GetPathPoints(from, to, brain.savedPathPoints)
  end

  if memory and reachable and #brain.savedPathPoints > 0 then
    brain.lastAttackEntityId = memory.entId
  end
end
local GenerateRetreatPath = Bishop.alien.lerk.GenerateRetreatPath

--------------------------------------------------------------------------------
-- Force path regeneration if the path has become impossible.
--------------------------------------------------------------------------------
-- Detect if the Lerk hasn't made any progress over the last several ticks and
-- delete its generated path. Lerks tend to overshoot their waypoints between
-- ticks then get confused when the next waypoint becomes unreachable due to an
-- obstacle.

local function StuckSanityCheck(bot, brain, lerk)
  local origin = lerk:GetOrigin()
  local progress = lerk:GetOrigin():GetDistance(brain.lerkStuckPosition)
  if progress >= kStuckProgress then
    brain.lerkStuckCounter = 0
    brain.lerkStuckPosition = origin
  else
    brain.lerkStuckCounter = brain.lerkStuckCounter + 1
  end

  if brain.lerkStuckCounter > kStuckThreshold then
    if kDebug then
      -- Light blue line displays for one second at the Lerk's path reset point.
      DebugLine(origin, origin + Vector(0, 2, 0), 1, 0, 1, 1, 1)
    end
    bot:GetMotion().currPathPoints = nil
    brain.lerkStuckCounter = 0
  end
end

--------------------------------------------------------------------------------
-- Simplify flap/glide logic.
--------------------------------------------------------------------------------
-- Moved to a static flap rate unless trying to save energy. Taking off has been
-- moved into HandleHeight.

local function HandleFlap(brain, lerk, move, cosine)
  local speed = lerk:GetVelocity():GetLength() / lerk:GetMaxSpeed()
  local time = GetTime()
  local flapSpeed = brain.activeRecovery and 0.6 or 0.25

  -- Flap to gain speed or correct heading.
  if (speed < 0.9 or cosine < 0.7)
      and not lerk.flapPressed and brain.timeOfJump + 0.20 < time then
    move.commands = AddMoveCommand(move.commands, Move.Jump)
    brain.timeOfJump = time

  -- Make sure jump stays held beyond the target speed. (Glide mode.)
  elseif speed >= 0.9 and not lerk:GetIsOnGround() then
    move.commands = AddMoveCommand(move.commands, Move.Jump)

  -- Take off for all movement if the Lerk is walking.
  elseif lerk:GetIsOnGround() and not lerk.flapPressed then
    move.commands = AddMoveCommand(move.commands, Move.Jump)
  end
end

--------------------------------------------------------------------------------
-- Expand PerformMove to allow for point skipping.
--------------------------------------------------------------------------------
-- The default PerformMove for Lerks only checked for cosine > 0.2 against the
-- target position. This meant the Lerk was completely unable to correct itself
-- if gliding in the wrong direction or intentionally moving away from its
-- target (i.e. in a U-shaped hallway.)
-- Swapping this out for currMoveDir allows flapping to continue when the Lerk's
-- velocity doesn't match its intended direction.

function Bishop.alien.lerk.DoMove(from, to, bot, brain, move)
  local lerk = bot:GetPlayer()
  local origin = lerk:GetOrigin()

  if StuckMove(bot, lerk, move, origin, to) then
    return
  end

  local distanceSqr
  do
    StuckSanityCheck(bot, brain, lerk)
    local terminate, _, movePos, tunnel = HandleAlienTunnelMove(from, to, bot,
      brain, move)
    to = movePos -- HandleAlienTunnelMove might want to override the target.
    distanceSqr = (to - from):GetLengthSquared()

    if terminate or (tunnel and distanceSqr < 25) then
      return
    end
  end

  if distanceSqr > 10 or brain.forceFlap then
    brain.forceFlap = false
    local cosine = DotProduct(bot:GetMotion().currMoveDir,
      lerk:GetVelocity():GetUnit())
    HandleFlap(brain, lerk, move, cosine)
  end
end

local DoMove = Bishop.alien.lerk.DoMove

--------------------------------------------------------------------------------
-- Retreat movement.
--------------------------------------------------------------------------------

function Bishop.alien.lerk.PerformRetreatMove(eyePos, aimPos, bot, brain,
    target, move)
  local hive = brain:GetSenses():Get("nearestHive").entity
  if not hive then
    hive = brain:GetSenses():Get("nearestHiveAll").entity
    if not hive then
      -- If this block runs, the team has no Hives anyway and the game is over.
      local direction = (eyePos - aimPos):GetUnit()
      bot:GetMotion():SetDesiredMoveDirection(direction)
      return
    end
  end

  if not brain.lastAttackEntityId == target:GetId() or not brain.savedPathPoints
      or #brain.savedPathPoints == 0 then
    GenerateRetreatPath(eyePos, aimPos, nil, brain)
  end

  if brain.savedPathPoints and #brain.savedPathPoints ~= 0 then
    local iter = FindBackwardsPathPoint(target:GetOrigin(), kRetreatDistance,
      brain.savedPathPointsIt, brain)
    local position = brain.savedPathPoints[iter]
    local height = kFlightHeightAmplitude
      * Sin(kHeightVariationPanicSpeed * GetTime())
      + kFlightHeight
    position.y = position.y + height
    DoMove(eyePos, position, bot, brain, move)
  else
    -- Fallback path to the hive if path generation has completely failed.
    local hive = brain:GetSenses():Get("nearestHive").entity
    if hive then
      DoMove(eyePos, hive:GetOrigin(), bot, brain, move)
    end
  end
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
