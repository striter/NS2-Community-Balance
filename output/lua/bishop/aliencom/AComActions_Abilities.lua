Script.Load("lua/BuildUtility.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/Table.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/Utility.lua")
Script.Load("lua/bots/BotUtils.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetIsBuildLegal = GetIsBuildLegal
local ipairs = ipairs
local IsValid = IsValid
local kAlienTeamType = kAlienTeamType
local kStructureSnapRadius = kStructureSnapRadius
local kTechId = kTechId
local Shared_GetEntity = Shared.GetEntity
local Shared_GetTime = Shared.GetTime
local table_random = table.random

local actions = Bishop.alienCom.actions
local actionTypes = Bishop.alienCom.actionTypes
local GetActionWeight = Bishop.alienCom.GetActionWeight
local kNilAction = Bishop.lib.constants.kNilAction
local SearchMemoriesForAny = Bishop.utility.SearchMemoriesForAny
local TraceFromAbove = Bishop.utility.TraceFromAbove

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kContaminateBuildingTypes = {
  kMinimapBlipType.ARC,
  kMinimapBlipType.InfantryPortal,
  kMinimapBlipType.PhaseGate,
  kMinimapBlipType.CommandStation,
  kMinimapBlipType.Observatory,
  kMinimapBlipType.ArmsLab,
  kMinimapBlipType.PrototypeLab,
  kMinimapBlipType.Extractor,
  kMinimapBlipType.MAC,
  kMinimapBlipType.PowerPoint,
  kMinimapBlipType.Armory,
  kMinimapBlipType.RoboticsFactory
}
local kCystDistance = 1
local kHiveCombatTime = 10
local kMinResourcesForContaminate = 80
local kTimeBetweenContaminate = 5
local kTimeBetweenNonCombatHatch = 30

--------------------------------------------------------------------------------
-- Allow contaminate to target any known marine building.
--------------------------------------------------------------------------------

function actions.AbilityContamination(bot, brain, com)
  local techId = kTechId.Contamination
  local time = Shared_GetTime()

  if not brain:GetSenses():Get("doableTechIds")[techId]
      or time < brain.nextContaminateTime
      or com:GetTeamResources() < kMinResourcesForContaminate then
    return kNilAction
  end

  local targets = SearchMemoriesForAny(kAlienTeamType,
    kContaminateBuildingTypes)
  local selectedMemory = table_random(targets)
  if not selectedMemory then
    return kNilAction
  end
  local target = Shared_GetEntity(selectedMemory.entId)

  if not IsValid(target) or not target:GetIsAlive() then
    return kNilAction
  end

  local extent = target:GetExtents():GetLengthXZ() + kCystDistance
  local trace = TraceFromAbove(target:GetOrigin(), extent)
  local isLegal
  local position

  if trace then
    isLegal, position = GetIsBuildLegal(techId, trace.endPoint, 0,
      kStructureSnapRadius, com)
  end

  if not isLegal then
    return kNilAction
  end

  return {
    name = "AbilityContamination",
    weight = GetActionWeight(actionTypes.AbilityContamination),
    perform = function(move, bot, brain, com, action)
      local success = brain:ExecuteTechId(com, techId, position, com)

      if success then
        brain.nextContaminateTime = time + kTimeBetweenContaminate
      end
    end
  }
end

--------------------------------------------------------------------------------
-- Limit the use of hatch unless a hive is under threat.
--------------------------------------------------------------------------------
-- The commander was dropping way too many resources on hatch when it wasn't
-- really necessary, which was gimping progression.

function actions.AbilityHatchEggs(bot, brain, com)
  local senses = brain:GetSenses()
  local techId = kTechId.ShiftHatch
  local time = Shared_GetTime()

  if not senses:Get("doableTechIds")[techId] or com:GetTeam():GetEggCount() ~= 0
      then
    return kNilAction
  end

  local hives = senses:Get("hives")
  local selectedHive = nil
  local nonCombat = false

  for _, hive in ipairs(hives) do
    local lastTimeDamaged = hive:GetTimeOfLastDamage()

    if hive:GetIsAlive() and lastTimeDamaged
        and lastTimeDamaged + kHiveCombatTime > time then
      selectedHive = hive
      break
    end
  end

  if not selectedHive
      and time < brain.lastNonCombatHatchTime + kTimeBetweenNonCombatHatch then
    return kNilAction
  else
    selectedHive = hives[1]
    nonCombat = true
  end

  local position = selectedHive:GetOrigin()

  return {
    name = "AbilityHatchEggs",
    weight = GetActionWeight(actionTypes.AbilityHatchEggs),
    perform = function(move, bot, brain, com, action)
      local success = brain:ExecuteTechId(com, techId, position, selectedHive)

      if success and nonCombat then
        brain.lastNonCombatHatchTime = time
      end
    end
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
