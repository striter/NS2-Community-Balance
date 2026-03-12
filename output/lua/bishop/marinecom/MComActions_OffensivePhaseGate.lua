Script.Load("lua/Balance.lua")
Script.Load("lua/Entity.lua")
Script.Load("lua/Table.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/bots/LocationContention.lua")

Script.Load("lua/bishop/BishopSettings.lua")
Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetEntitiesForTeamByLocation = GetEntitiesForTeamByLocation
local GetEntitiesWithinRange = GetEntitiesWithinRange
local GetLocationContention = GetLocationContention
local ipairs = ipairs
local Shared_GetEntity = Shared.GetEntity
local Shared_GetTime = Shared.GetTime
local table_contains = table.contains

local GetActionWeight = Bishop.marineCom.GetActionWeight
local TraceBuildPosition = Bishop.utility.TraceBuildPosition

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kExtractorsForCostPenalty = 3 -- Save resources for an extractor if low.
local kMaxBuildRange = 9            -- Maximum build distance from power node.
local kMaxHiveRange = 60            -- Maximum phase gate distance from a Hive.
local kMaxPowerNodeRange = 12       -- Maximum marine range from a power node.
local kMinPhaseGateDistance = 60    -- Minumum separation between phase gates.
local kMinResources = 20            -- Minimum resources to consider an OPG.
local kTimeBetweenAttempts = 10     -- Time to wait between failed attempts.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kActionTypes = Bishop.marineCom.kActionTypes
local kExtractorCost = kExtractorCost
local kNilAction = Bishop.lib.constants.kNilAction
local kTechId = kTechId
local settings = Bishop.settings.marineCom

--------------------------------------------------------------------------------
-- Build and recycle offensive phase gates.
--------------------------------------------------------------------------------
-- Depending on the map, many marine pushes into hives end badly because the run
-- time to rejoin the fight is too long. This is particularly true on a huge map
-- like ns2_eclipse.

local function GetOffensivePhaseGatePosition(senses, com)
  local marines = senses:Get("marines")

  for _, marine in ipairs(marines) do
    local origin = marine:GetOrigin()
    local hives = GetEntitiesWithinRange("Hive", origin, kMaxHiveRange)
    
    for _, hive in ipairs(hives) do
      local powerNodes = GetEntitiesWithinRange("PowerPoint", origin,
        kMaxPowerNodeRange)
      
      if #powerNodes ~= 0 then
        return TraceBuildPosition(powerNodes[1]:GetOrigin(), 2, kMaxBuildRange,
          kTechId.PhaseGate, powerNodes[1]:GetLocationName(), com)
      end
    end
  end

  return nil
end

local function GetNearestHiveTechPoint(senses, position)
  local hives = senses:Get("enemyHives")
  local closestDistance
  local techPoint

  for _, hive in ipairs(hives) do
    local distance = position:GetDistance(hive:GetOrigin())

    if not closestDistance or distance < closestDistance then
      closestDistance = distance
      techPoint = hive:GetAttached()
    end
  end

  return techPoint
end

function Bishop.marineCom.actions.BuildOffensivePhaseGate(bot, brain, com)
  local senses = brain:GetSenses()
  local teamBrain = brain.teamBrain
  local spawnGate = brain:GetSenses():Get("mainPhaseGate")
  local minResources = kMinResources

  if #senses:Get("extractors") <= kExtractorsForCostPenalty then
    minResources = minResources + kExtractorCost
  end

  if teamBrain.offensivePhaseGateId
      or not settings.offensivePhase
      or com:GetTeamResources() < minResources
      or not senses:Get("doableTechIds")[kTechId.PhaseGate]
      or not spawnGate or not spawnGate:GetIsPowered()
      or Shared_GetTime() < teamBrain.offensivePhaseGateTime
        + kTimeBetweenAttempts then
    return kNilAction
  end

  local position = GetOffensivePhaseGatePosition(senses, com)

  if not position then
    return kNilAction
  end

  for _, phaseGate in ipairs(senses:Get("ent_phaseGates")) do
    if position:GetDistance(phaseGate:GetOrigin()) < kMinPhaseGateDistance then
      return kNilAction
    end
  end

  local techPoint = GetNearestHiveTechPoint(senses, position)
  if not techPoint then
    return kNilAction
  end

  return {
    name = "BuildOffensivePhaseGate",
    weight = GetActionWeight(kActionTypes.BuildOffensivePhaseGate),
    perform = function(move, bot, brain, com, action)
      local success = brain:ExecuteTechId(com, kTechId.PhaseGate, position, com)

      if success then
        local phaseGates = GetEntitiesWithinRange("PhaseGate", position, 5)
        if #phaseGates ~= 0 then
          teamBrain.offensivePhaseGateId = phaseGates[1]:GetId()
          teamBrain.offensivePhaseGateTechPoint = techPoint
          teamBrain.offensivePhaseGateTime = Shared_GetTime()
        end
      end
    end
  }
end

function Bishop.marineCom.actions.RecycleOffensivePhaseGate(bot, brain, com)
  local teamBrain = brain.teamBrain
  local phaseGateId = teamBrain.offensivePhaseGateId

  if not phaseGateId then
    return kNilAction
  end
  
  local phaseGate = Shared_GetEntity(phaseGateId)
  if not phaseGate or not phaseGate:GetIsAlive() then
    teamBrain.offensivePhaseGateId = nil
    return kNilAction
  end

  local safeTechPoints = brain:GetSenses():Get("safeTechPoints")

  if not table_contains(safeTechPoints, teamBrain.offensivePhaseGateTechPoint)
      then
    return kNilAction
  end

  -- There's no point recycling the offensive phase gate if it happens to be
  -- within the tech point itself. Promote it to a full gate.
  local location = GetLocationContention():GetLocationGroup(
    phaseGate:GetLocationName())
  if location and location.hasTechPoint then
    teamBrain.offensivePhaseGateId = nil
    teamBrain.offensiveArmoryId = nil
    return kNilAction
  end

  -- Make sure the target tech point has a newly built gate before recycling.
  local newPhaseGates = GetEntitiesForTeamByLocation("PhaseGate",
    kMarineTeamType, teamBrain.offensivePhaseGateTechPoint:GetLocationId())
  if #newPhaseGates <= 0 or not newPhaseGates[1]:GetIsBuilt()
      or not newPhaseGates[1]:GetIsPowered()
      or not newPhaseGates[1]:GetIsLinked() then
    return kNilAction
  end

  return {
    name = "RecycleOffensivePhaseGate",
    weight = GetActionWeight(kActionTypes.RecycleOffensivePhaseGate),
    perform = function(move, bot, brain, com, action)
      local success = brain:ExecuteTechId(com, kTechId.Recycle,
        phaseGate:GetOrigin(), phaseGate, phaseGateId)

      if success then
        teamBrain.offensivePhaseGateId = nil
        if teamBrain.offensiveArmoryId then
          local armory = Shared_GetEntity(teamBrain.offensiveArmoryId)
          if armory and armory:GetIsAlive() then
            brain:ExecuteTechId(com, kTechId.Recycle, armory:GetOrigin(),
              armory, teamBrain.offensiveArmoryId)
            teamBrain.offensiveArmoryId = nil
          end
        end
      end
    end
  }
end

local GetDestinationGate = Shine.GetUpValue(_G.PhaseGate.Update,
  "GetDestinationGate")

local function CountPhaseGateHops(fromGate, toGate)
  if not fromGate or not toGate or fromGate == toGate then
    return 0
  end

  local currentGate = fromGate
  local hopCount = 0

  while currentGate ~= toGate and currentGate and currentGate:GetIsLinked() do
    currentGate = GetDestinationGate(currentGate)
    hopCount = hopCount + 1
  end

  return hopCount
end

function Bishop.marineCom.actions.ReverseOffensivePhaseGate(bot, brain, com)
  local phaseGateId = brain.teamBrain.offensivePhaseGateId

  if not phaseGateId then
    return kNilAction
  end

  local phaseGate = Shared_GetEntity(phaseGateId)
  local spawnGate = brain:GetSenses():Get("mainPhaseGate")

  if not phaseGate or not phaseGate:GetIsBuilt() or not phaseGate:GetIsPowered()
      or not phaseGate:GetIsLinked() or not spawnGate
      or not spawnGate:GetIsLinked() then
    return kNilAction
  end

  local hopsToGate = CountPhaseGateHops(spawnGate, phaseGate)
  local hopsFromGate = CountPhaseGateHops(phaseGate, spawnGate)

  if hopsToGate <= hopsFromGate then
    return kNilAction
  end

  return {
    name = "ReverseOffensivePhaseGate",
    weight = GetActionWeight(kActionTypes.ReverseOffensivePhaseGate),
    perform = function(move, bot, brain, com, action)
      brain:ExecuteTechId(com, kTechId.ReversePhaseGate, phaseGate:GetOrigin(),
        phaseGate, phaseGateId)
    end
  }
end

--------------------------------------------------------------------------------
-- Build an Armory near the offensive Phase Gate.
--------------------------------------------------------------------------------

local function PerformBuildOffensiveArmory(move, bot, brain, com, action)
  local success = brain:ExecuteTechId(com, kTechId.Armory, action.position, com)

  if success then
    local armories = GetEntitiesWithinRange("Armory", action.position, 5)
    if #armories ~= 0 then
      brain.teamBrain.offensiveArmoryId = armories[1]:GetId()
    end
  end
end

local function IsMarineInRange(brain, origin)
  local range = kMaxPowerNodeRange * kMaxPowerNodeRange
  local marines = brain:GetSenses():Get("marines")

  for _, marine in ipairs(marines) do
    if marine:GetOrigin():GetDistanceSquared(origin) <= range then
      return true
    end
  end

  return false
end

local function ShouldBuildOffensiveArmory(brain, com)
  local teamBrain = brain.teamBrain
  local phaseGateId = teamBrain.offensivePhaseGateId
  local armoryId = teamBrain.offensiveArmoryId

  -- Offensive armories don't have a dedicated recycle action, so check for
  -- destruction here.
  if armoryId then
    local armory = Shared_GetEntity(armoryId)
    if not armory or not armory:GetIsAlive() then
      teamBrain.offensiveArmoryId = nil
      armoryId = nil
    elseif not phaseGateId then
      -- If the offensive Phase Gate was destroyed, try to get resources back
      -- from the Armory.
      brain:ExecuteTechId(com, kTechId.Recycle, armory:GetOrigin(), armory,
        armoryId)
      teamBrain.offensiveArmoryId = nil
    end
  end

  if not settings.offensivePhaseArm or not phaseGateId or armoryId then
    return false
  end
  local phaseGate = Shared_GetEntity(phaseGateId)
  if not phaseGate or not phaseGate:GetIsBuilt()
      or not phaseGate:GetIsPowered()
      or not IsMarineInRange(brain, phaseGate:GetOrigin()) then
    return false
  end

  return true
end

local function CanAffordOffensiveArmory(brain, com)
  local minResources = kMinResources
  local senses = brain:GetSenses()

  if #senses:Get("extractors") <= kExtractorsForCostPenalty then
    minResources = minResources + kExtractorCost
  end
  if com:GetTeamResources() < minResources
      or not senses:Get("doableTechIds")[kTechId.Armory] then
    return false
  end

  return true
end

function Bishop.marineCom.actions.BuildOffensiveArmory(bot, brain, com)
  if not ShouldBuildOffensiveArmory(brain, com)
      or not CanAffordOffensiveArmory(brain, com) then
    return kNilAction
  end

  local phaseGate = Shared_GetEntity(brain.teamBrain.offensivePhaseGateId)
  local position = TraceBuildPosition(phaseGate:GetOrigin(), 4, kMaxBuildRange,
    kTechId.Armory, phaseGate:GetLocationName(), com)
  if not position then
    return kNilAction
  end

  return {
    name = "BuildOffensiveArmory",
    weight = GetActionWeight(kActionTypes.BuildOffensiveArmory),
    perform = PerformBuildOffensiveArmory,

    -- Action metadata.
    position = position
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
