Script.Load("lua/BalanceMisc.lua")
Script.Load("lua/CollisionRep.lua")
Script.Load("lua/Entity.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/MixinUtility.lua")
Script.Load("lua/PhysicsGroups.lua")
Script.Load("lua/Table.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/Utility.lua")
Script.Load("lua/Weapons/Alien/DropStructureAbility.lua")
Script.Load("lua/Weapons/Alien/HydraAbility.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local cos = math.cos
local DebugBox = DebugBox
local DebugLine = DebugLine
local EntityFilterAll = EntityFilterAll
local EntityFilterOneAndIsa = EntityFilterOneAndIsa
local GetEntities = GetEntities
local GetEntitiesAliveForTeam = GetEntitiesAliveForTeam
local HasMixin = HasMixin
local IsValid = IsValid
local max = math.max
local Pathing_GetClosestPoint = Pathing.GetClosestPoint
local random = math.random
local Shared_GetEntity = Shared.GetEntity
local Shared_GetTime = Shared.GetTime
local Shared_TraceBox = Shared.TraceBox
local Shared_TraceRay = Shared.TraceRay
local sin = math.sin
local table_insertunique = table.insertunique
local table_addtable = table.addtable
local table_random = table.random
local table_remove = table.remove

local actions = Bishop.alien.gorge.actions
local Log = Bishop.debug.HydraLog
local DoMove = Bishop.alien.gorge.DoMove

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kScanHeight = 5          -- Height above entity origin to scan.
local kMaxDistance = 10        -- Furthest distance from the target entity.
local kMoveRange = 2           -- Distance before attempting placement.

local kHydraPanicDistance = 10 -- Distance from marines for reactive placement.

local kMinActionWeight = 4 -- Action weight lerps from [min,max] over distance.
local kMaxActionWeight = 10
local kActionWeightDistance = 60

local kTimeBetweenHydraScan = 15

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local CollisionRep_Damage = CollisionRep.Damage
local DropStructureAbility_kMapName = DropStructureAbility.kMapName
local kActionWeightDelta = kMaxActionWeight - kMinActionWeight
local kAlienTeamType = kAlienTeamType
local kCircle = 2 * math.pi
local kDebug = Bishop.debug.hydra
local kDropRange = HydraStructureAbility.kDropRange
local kEnergyCost = HydraStructureAbility.GetEnergyCost(nil)
local kHydrasPerHive = kHydrasPerHive
local kMaxTraceAttempts = 5
local kNilAction = Bishop.lib.constants.kNilAction
local kStructureId = 1 -- Index into DropStructureAbility.kSupportedStructures.
local kTechId_Hydra = kTechId.Hydra
local PhysicsMask_Bullets = PhysicsMask.Bullets

--------------------------------------------------------------------------------
-- Debug options.
--------------------------------------------------------------------------------

local kDebugPlacement = Bishop.debug.hydra -- Show visual cues.
local kDebugSpam = false                   -- Anywhere and max priority.
local kDebugPanic = false                  -- Place Hydras around self.

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

local function GetBotHydraCount(gorge)
  return gorge:GetTeam():GetNumDroppedGorgeStructures(gorge, kTechId_Hydra)
end

local function EntityCalculateHydraFilter(entity)
  return function (test)
    return EntityFilterOneAndIsa(entity, "Clog") or test:isa("Hydra")
  end
end

local function GenerateHydraPosition(gorge, entity)
  local trace
  for i = 1, kMaxTraceAttempts do
    local angle = random() * kCircle;
    local origin = entity:GetOrigin()
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

  if trace.fraction == 1 then
    return nil
  end
  local position = trace.endPoint
  local normal = trace.normal
  local extents = GetExtents(kTechId_Hydra) / 2.25 -- Vanilla placement box.
  local traceStart = position + normal * 0.15
  local traceEnd = position + normal * extents.y
  trace = Shared_TraceBox(extents, traceStart, traceEnd, CollisionRep_Damage,
    PhysicsMask_Bullets, EntityCalculateHydraFilter(gorge))

  if trace.fraction ~= 1 then
    return nil
  elseif kDebugPlacement then
    DebugBox(traceStart, traceEnd, extents, 10, 0, 1, 0, 1)
  end

  if kDebug and GetLocationForPoint(position) then
    Log("Hydra postion found at %s.", GetLocationForPoint(position):GetName())
  elseif kDebug then
    Log("Hydra position found at (no location) %s.", position)
  end
  return position, normal
end

local function UpdateHydraQueue(brain)
  -- The alert queue doesn't seem to catch all structures being attacked, so
  -- the GetIsInCombat() route seems to be the only way for now.
  local time = Shared_GetTime()
  if time > brain.timeNextHydraScan then
    brain.timeNextHydraScan = time + kTimeBetweenHydraScan

    -- All Harvesters and Hives under attack.
    local entities = GetEntitiesAliveForTeam("Harvester", kAlienTeamType)
    table_addtable(GetEntitiesAliveForTeam("Hive", kAlienTeamType), entities)
    for _, entity in ipairs(entities) do
      if entity:GetIsInCombat() then
        if kDebug then Log("Inserting %s into Hydra queue.", entity) end
        table_insertunique(brain.hydraQueue, entity:GetId())
      end
    end

    -- All unclaimed tech points.
    entities = GetEntities("TechPoint")
    for _, entity in ipairs(entities) do
      if not entity:GetAttached() then
        if kDebug then Log("Inserting %s into Hydra queue.", entity) end
        table_insertunique(brain.hydraQueue, entity:GetId())
      end
    end
  end
end

local function GetVulnerableEntity(brain)
  UpdateHydraQueue(brain)
  if #brain.hydraQueue == 0 then
    return nil
  end

  local vulnerable = nil
  while #brain.hydraQueue > 0 do
    local entity = Shared_GetEntity(brain.hydraQueue[1])
    table_remove(brain.hydraQueue, 1)
    if IsValid(entity) and ((HasMixin(entity, "Live") and entity:GetIsAlive())
        or entity:isa("TechPoint")) then
      vulnerable = entity
      break
    elseif kDebug then
      Log("Removed invalid entity from Hydra queue.")
    end
  end

  if kDebug and vulnerable then
    Log("Retrieved valid entity from Hydra queue.")
  end
  return vulnerable
end

local function GetAppropriateHydraPosition(brain, gorge)
  local harvester
  if kDebugSpam then
    local harvesters = GetEntitiesAliveForTeam("Harvester", kAlienTeamType)
    if #harvesters > 0 then
      harvester = table_random(harvesters)
    end
  else
    harvester = GetVulnerableEntity(brain)
  end

  if not harvester then
    return nil
  end

  local position, normal = GenerateHydraPosition(gorge, harvester)
  if not position or Pathing_GetClosestPoint(position) == position then
    return nil
  end

  if kDebug then
    Log("Hydra position found for %s at %s.", harvester, position)
  end
  brain.hydraCount = GetBotHydraCount(gorge)
  brain.hydraPosition = position
  brain.hydraNormal = normal
  brain.hydraMovePosition = Pathing_GetClosestPoint(position)
  return position
end

local function GetActionWeight(distance)
  if kDebugSpam then
    return kMaxActionWeight
  end

  local interp = max(0, 1 - distance / kActionWeightDistance)
  return interp * kActionWeightDelta + kMinActionWeight
end

--------------------------------------------------------------------------------
-- Place a Hydra in an appropriate position.
--------------------------------------------------------------------------------
-- An appropriate Hydra position is currently based off of recently attacked
-- Harvesters and Hives, or unclaimed tech points. The Gorge will add positions
-- to a FIFO set for later processing.

local function PerformBuildHydra(move, bot, brain, gorge, action)
  local eyePosition = gorge:GetEyePos()
  local placePoint = brain.hydraPosition
  local movePosition = brain.hydraMovePosition
  local placeDistance = eyePosition:GetDistance(placePoint)
  local inRange = eyePosition:GetDistance(movePosition) < kMoveRange
    or placeDistance < kDropRange

  if placeDistance < kDropRange * 2 then
    bot:GetMotion():SetDesiredViewTarget(placePoint)
  end

  if inRange and gorge:GetEnergy() >= kEnergyCost then
    gorge:SetActiveWeapon(DropStructureAbility_kMapName, true)
    local buildAbility = gorge:GetWeapon(DropStructureAbility_kMapName)
    buildAbility:SetActiveStructure(kStructureId)
    local placePosition, isValid, _, placeNormal =
      buildAbility:GetPositionForStructure(eyePosition,
        gorge:GetViewCoords().zAxis, HydraStructureAbility, placePoint,
        brain.hydraNormal)

    if not isValid then
      brain.hydraPanicPosition = nil
      brain.hydraPosition = nil
      brain.hydraCount = nil
      if kDebug then Log("Placement position was invalid.") end
      return
    end

    buildAbility:OnDropStructure(gorge:GetOrigin(), gorge:GetViewCoords().zAxis,
      kStructureId, placePosition, placeNormal)
  elseif not inRange then
    bot:GetMotion():SetDesiredViewTarget()
    DoMove(eyePosition, movePosition, bot, brain, move)
  end
end

function actions.BuildHydra(bot, brain, gorge)
  if gorge.isHallucination then
    return kNilAction
  end

  -- A Hydra dying will cancel this action without actually placing the
  -- desired Hydra. In reality, this adds some nice dynamicness to it. On a
  -- successful drop this will be triggered on the next tick.
  local hydraCount = GetBotHydraCount(gorge)
  if brain.hydraCount and hydraCount ~= brain.hydraCount then
    if kDebug then Log("A Hydra was placed or destroyed.") end
    brain.hydraPanicPosition = nil
    brain.hydraPosition = nil
    brain.hydraCount = nil
  end

  if hydraCount >= kHydrasPerHive
      or gorge:GetIsInCombat() then
    return kNilAction
  end

  local position = brain.hydraPosition
    or GetAppropriateHydraPosition(brain, gorge)
  if not position then
    return kNilAction
  end

  return {
    name = "BuildHydra",
    perform = PerformBuildHydra,
    weight = GetActionWeight(gorge:GetOrigin():GetDistance(position))
  }
end

--------------------------------------------------------------------------------
-- Panic placement of a Hydra when near a threat.
--------------------------------------------------------------------------------
-- This will cause a Gorge to abandon its current Hydra target and preemptively
-- place a Hydra when danger is approaching.

function actions.PanicHydra(bot, brain, gorge)
  if gorge.isHallucination then
    return kNilAction
  end

  local hydraCount = GetBotHydraCount(gorge)
  if hydraCount >= kHydrasPerHive then
    return kNilAction
  end

  local position = brain.hydraPanicPosition
  if not position then
    local threat = brain:GetSenses():Get("nearestThreat")
    if threat.distance and threat.distance < kHydraPanicDistance
        or kDebugPanic then
      local normal
      position, normal = GenerateHydraPosition(gorge, gorge)
      if position then
        if kDebug and brain.hydraPosition then
          Log("Replacing defensive Hydra position with panic.")
        elseif kDebug then
          Log("Generated new panic Hydra position.")
        end
        brain.hydraPanicPosition = position -- To avoid regenerating the point.
        brain.hydraPosition = position
        brain.hydraNormal = normal
        brain.hydraMovePosition = Pathing_GetClosestPoint(position)
      end
    end
  end

  if not position then
    return kNilAction
  end

  return {
    name = "PanicHydra",
    perform = PerformBuildHydra,
    weight = GetActionWeight(gorge:GetOrigin():GetDistance(position))
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
