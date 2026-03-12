Script.Load("lua/Balance.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/bots/MarineCommanderBrain_Utility.lua")
Script.Load("lua/bots/MarineCommanerBrain_TechPath.lua") -- Not a typo.

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetBaseUnitFromDoables = GetBaseUnitFromDoables
local GetCostForTech = GetCostForTech
local GetMarineComNextTechStep = GetMarineComNextTechStep

local GetActionWeight = Bishop.marineCom.GetActionWeight
local Log = Bishop.debug.MarineResearchLog

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kMinBuildDistance = 3
local kMaxBuildDistance = 15
local kMaxBuildDistanceOverride = {
  [kTechId.ArmsLab] = 5.5
}

local kMinExtractors = 4 -- Save for an Extractor when below kMinExtractors.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kActionTypes_Research = Bishop.marineCom.kActionTypes.Research
local kDebug = Bishop.debug.marineResearch
local kExtractorCost = kExtractorCost
local kMarineTeamType = kMarineTeamType
local kNilAction = Bishop.lib.constants.kNilAction
local kTechId = kTechId
local kTechType = kTechType

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

local function GetBaseBuildPosition(techId, senses, brain, com)
  local commandStation = senses:Get("mainCommandStation")
  if not commandStation then
    return nil
  end

  local locationName = commandStation:GetLocationName()
  if not brain:GetIsSafeToDropInLocation(locationName, kMarineTeamType) then
    return nil
  end

  local buildDistance = kMaxBuildDistanceOverride[techId] or kMaxBuildDistance
  return Bishop.utility.TraceBuildPosition(commandStation:GetOrigin(),
    kMinBuildDistance, buildDistance, techId, locationName, com)
end

--------------------------------------------------------------------------------
-- Leave a buffer for Extractors if below a threshold.
--------------------------------------------------------------------------------
-- Make sure the commander doesn't run the team down to zero resources if the
-- number of Extractors is below an acceptable threshold.

local function PerformResearch(move, bot, brain, com, action)
  brain:ExecuteTechId(com, action.techId, action.position, action.unit)
end

function Bishop.marineCom.actions.Research(bot, brain, com)
  local senses = brain:GetSenses()
  local doables = senses:Get("doableTechIds")
  local techId, techType = GetMarineComNextTechStep(bot, brain, com)
  if #senses:Get("activeInfantryPortals") <= 0
      or not techId or techId == kTechId.None or not doables[techId] then
    return kNilAction
  end

  -- Make sure enough resources are left for an Extractor when running low.
  local resources = com:GetTeamResources()
  if #senses:Get("extractors") < kMinExtractors
      and techId ~= kTechId.Armor1 then
    resources = resources - kExtractorCost
  end
  if resources < GetCostForTech(techId) then
    if kDebug and #senses:Get("extractors") < kMinExtractors then
      Log("Delayed %s to save for an Extractor.", kTechId[techId])
    end
    return kNilAction
  end

  local position = nil
  local unit = com
  if techType == kTechType.Research or techType == kTechType.Upgrade then
    unit = GetBaseUnitFromDoables(senses, brain, doables[techId])
    position = Vector(0, 0, 0)
  elseif techType == kTechType.Build then
    position = GetBaseBuildPosition(techId, senses, brain, com)
  end

  if not position or not unit then
    if kDebug then
      Log("Can't research %s: position = %s, unit = %s.", kTechId[techId],
        position, unit)
    end
    return kNilAction
  end

  if kDebug then
    Log("Researching / building %s with unit %s.", kTechId[techId], unit)
  end

  return {
    name = "Research",
    perform = PerformResearch,
    weight = GetActionWeight(kActionTypes_Research),

    -- Action metadata.
    position = position,
    techId = techId,
    unit = unit
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
