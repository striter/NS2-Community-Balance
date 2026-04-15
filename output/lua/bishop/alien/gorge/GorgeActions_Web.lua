Script.Load("lua/BalanceMisc.lua")
Script.Load("lua/CollisionRep.lua")
Script.Load("lua/PhysicsGroups.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/Utility.lua")
Script.Load("lua/Weapons/Alien/DropStructureAbility.lua")
Script.Load("lua/Weapons/Alien/WebsAbility.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local cos = math.cos
local DebugLine = DebugLine
local EntityFilterAll = EntityFilterAll
local max = math.max
local Pathing_GetClosestPoint = Pathing.GetClosestPoint
local random = math.random
local Shared_GetTime = Shared.GetTime
local Shared_TraceRay = Shared.TraceRay
local sin = math.sin

local Log = Bishop.debug.WebLog
local DoMove = Bishop.alien.gorge.DoMove

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kScanHeight = 2.2     -- Height above Gorge for wall scan.
local kOffsetDistance = 1.2 -- Random offset so webs aren't perfectly straight.
local kPlacementRadius = 12 -- Threats within this range before generating.
local kMoveRange = 1.5      -- Distance to move point before placement.
local kTimeBetweenAttempts = 2
local kTimeInvalidate = 10

local kMaxActionWeight = 7.5
local kMinActionWeight = 2
local kActionWeightDistance = 60

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local CollisionRep_Damage = CollisionRep.Damage
local DropStructureAbility_kMapName = DropStructureAbility.kMapName
local kActionWeightDelta = kMaxActionWeight - kMinActionWeight
local kCircle = 2 * math.pi
local kDebug = Bishop.debug.web
local kEnergyCost = WebsAbility.GetEnergyCost(nil)
local kMaxDistance = 5
local kNumWebsPerGorge = kNumWebsPerGorge
local kMaxTraceAttempts = 1
local kOffsetDistanceHalf = kOffsetDistance / 2
local kNilAction = Bishop.lib.constants.kNilAction
local kStructureId = 3 -- Index into DropStructureAbility.kSupportedStructures.
local kTechId_Web = kTechId.Web
local kWebDistance = kMaxWebLength * 0.9 -- Slightly lowered for offset.
local PhysicsMask_Bullets = PhysicsMask.Bullets

--------------------------------------------------------------------------------
-- Debug options.
--------------------------------------------------------------------------------

local kDebugPlacement = Bishop.debug.web -- Show visual cues.
local kDebugSpam = false                 -- Place webs ASAP anywhere.

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

local function GetBotWebCount(gorge)
  return gorge:GetTeam():GetNumDroppedGorgeStructures(gorge, kTechId_Web)
end

local function GenerateWebPosition(brain, gorge)
  -- Step 1: Generate a valid point from the Gorge to the wall.
  local trace
  for i = 1, kMaxTraceAttempts do
    local angle = random() * kCircle;
    local origin = gorge:GetOrigin()
    local outward = Vector(
      cos(angle) * kMaxDistance + origin.x,
      origin.y + kScanHeight,
      sin(angle) * kMaxDistance + origin.z)
    trace = Shared_TraceRay(origin, outward, CollisionRep_Damage,
      PhysicsMask_Bullets, EntityFilterAll())

    if trace.fraction == 1 then
      if kDebugPlacement then
        DebugLine(origin, outward, 3, 1, 0, 0, 1)
      end
    else
      if kDebugPlacement then
        DebugLine(origin, outward, 5, 1, 1, 0, 1)
      end
      break
    end
  end

  -- Tracing too many rays per tick could cause server lag, so give up and try
  -- again later.
  if trace.fraction == 1 then
    if kDebug then Log("Failed to trace to wall.") end
    return nil
  end

  -- Step 2: Trace along the wall's normal from the end point to find the
  -- opposite wall. Randomly offset the second point so the web isn't perfectly
  -- straight.
  brain.webStartPosition = trace.endPoint
  brain.webStartNormal = trace.normal
  local offsetPoint = trace.endPoint + trace.normal * kWebDistance
    + Vector(
        random() * kOffsetDistance - kOffsetDistanceHalf,
        sin(Shared_GetTime()) * kOffsetDistance,
        random() * kOffsetDistance - kOffsetDistanceHalf)
  trace = Shared_TraceRay(trace.endPoint, offsetPoint, CollisionRep_Damage,
    PhysicsMask_Bullets, EntityFilterAll())
  if trace.fraction == 1 then
    if kDebugPlacement then
      DebugLine(brain.webStartPosition, trace.endPoint, 3, 1, 0, 0, 1)
    end
    if kDebug then Log("Failed to find opposite wall.") end
    return nil
  end

  -- Step 3: Ensure the second point of the web is in a pathable position.
  brain.webMovePosition = Pathing_GetClosestPoint(trace.endPoint)
  if brain.webMovePosition == trace.endPoint then
    if kDebugPlacement then
      DebugLine(brain.webStartPosition, trace.endPoint, 3, 1, 0, 1, 1)
    end
    if kDebug then Log("Second point of web was unpathable.") end
    return nil
  elseif kDebugPlacement then
    DebugLine(brain.webStartPosition, trace.endPoint, 10, 0, 0, 1, 1)
  end

  -- Success! Lock in the position for future placement.
  if kDebug then Log("Web points generated.") end
  brain.webPosition = trace.endPoint
  brain.webCount = GetBotWebCount(gorge)
  brain.webInvalidateTime = Shared_GetTime() + kTimeInvalidate
  return trace.endPoint
end

local function ResetWebPosition(brain)
  brain.webPosition = nil
  brain.webCount = nil
  brain.webInvalidateTime = nil
  brain.timeNextWebAttempt = Shared_GetTime() + kTimeBetweenAttempts
end

local function GetActionWeight(distance)
  if kDebugSpam then
    return kMaxActionWeight
  end

  local interp = max(0, 1 - distance / kActionWeightDistance)
  return interp * kActionWeightDelta + kMinActionWeight
end

--------------------------------------------------------------------------------
-- Place webs nearby marine threats.
--------------------------------------------------------------------------------
-- Reactively place webs in areas of marine traffic.

local function PerformBuildWeb(move, bot, brain, gorge, action)
  local eyePosition = gorge:GetEyePos()
  local placePoint = brain.webPosition
  local movePosition = brain.webMovePosition
  local placeDistance = eyePosition:GetDistance(placePoint)
  local inRange = eyePosition:GetDistance(movePosition) < kMoveRange
  bot:GetMotion():SetDesiredViewTarget(placePoint)

  if inRange and gorge:GetEnergy() >= kEnergyCost then
    gorge:SetActiveWeapon(DropStructureAbility_kMapName, true)
    local buildAbility = gorge:GetWeapon(DropStructureAbility_kMapName)
    buildAbility:SetActiveStructure(kStructureId)
    local placePosition, isValid, _, placeNormal =
      buildAbility:GetPositionForStructure(eyePosition,
        gorge:GetViewCoords().zAxis, WebsAbility, brain.webStartPosition,
        brain.webStartNormal)

    if not isValid then
      if kDebug then Log("Placement position was invalid.") end
      ResetWebPosition(brain)
      return
    end

    buildAbility:OnDropStructure(gorge:GetOrigin(), gorge:GetViewCoords().zAxis,
      kStructureId, brain.webStartPosition, brain.webStartNormal)
  elseif not inRange then
    DoMove(eyePosition, movePosition, bot, brain, move)
  end
end

function Bishop.alien.gorge.actions.BuildWeb(bot, brain, gorge)
  if gorge.isHallucination then
    return kNilAction
  end
  local time = Shared_GetTime()
  local webCount = GetBotWebCount(gorge)
  if brain.webCount and webCount ~= brain.webCount then
    if kDebug then Log("A Web was placed or destroyed.") end
    ResetWebPosition(brain)
  elseif brain.webInvalidateTime and brain.webInvalidateTime <= time then
    if kDebug then Log("Position timed out, resetting.") end
    ResetWebPosition(brain)
  end

  if webCount >= kNumWebsPerGorge
      or gorge:GetEnergy() < kEnergyCost
      or time < brain.timeNextWebAttempt
      or gorge:GetIsUnderFire() then
    return kNilAction
  end

  local position = brain.webPosition
  if not position then
    local threat = brain:GetSenses():Get("nearestThreat")
    if threat.distance and threat.distance < kPlacementRadius
        or kDebugSpam then
      position = GenerateWebPosition(brain, gorge)
    end
  end

  if not position then
    return kNilAction
  end

  return {
    name = "BuildWeb",
    perform = PerformBuildWeb,
    weight = GetActionWeight(gorge:GetOrigin():GetDistance(position))
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
