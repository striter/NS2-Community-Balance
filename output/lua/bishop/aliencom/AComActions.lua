Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.alienCom.actions = {}

local actions = Bishop.alienCom.actions

--------------------------------------------------------------------------------
-- Action priorities.
--------------------------------------------------------------------------------
-- Higher in the enum is higher priority.

local actionTypes = enum({
  -- General construction.
  "BuildHarvester",
  "BuildTunnel",
  "BuildCyst",

  -- Research and main base construction.
  "UpgradeHive",
  "BuildUpgradeChamber",
  "BuildHiveCrag",
  "BuildHiveShade",
  "BuildHiveWhip",
  "BuildHive",
  "StartResearch",
  "BuildShade",

  -- Alien support.
  "UpgradeEgg",
  "AbilityBonewall",
  "AbilityShadeInk",
  "AbilityRupture",
  "AbilityNutrientMist",
  "AbilityContamination",
  "AbilityHatchEggs",

  -- Other.
  "BuildDrifter",
  "ManageOffensiveTunnel",
  "MoveBuilding",

  -- Mostly.
  "TheyMostlyComeAtNight"
})

Bishop.alienCom.actionTypes = actionTypes
local kActionCount = #actionTypes

local function GetActionWeight(action)
  local actionIndex = actionTypes[actionTypes[action]]

  return kActionCount - actionIndex + 1
end

Bishop.alienCom.GetActionWeight = GetActionWeight

--------------------------------------------------------------------------------
-- Detection for Bot_Maintenance.
--------------------------------------------------------------------------------

local kBotMaintenanceLoaded = #kAlienComBrainActions == 21

if kBotMaintenanceLoaded then
  Bishop.Log("Compatibility with Bot_Maintenance ACom enabled.")
elseif #kAlienComBrainActions ~= 18 then
  Bishop.Error("Another mod is interfering with ACom actions.")
end

--------------------------------------------------------------------------------
-- Build a named enum of existing actions.
--------------------------------------------------------------------------------
-- The ordering of this array MUST match the functions in kAlienComBrainActions.
-- This is used to pull the array index of a function.

local kOldComActionTypes

if not kBotMaintenanceLoaded then
  kOldComActionTypes = enum({ -- Vanilla actions.
    "BuildHiveCrag",
    "BuildHiveShade",
    "BuildHiveWhip",
    "BuildHiveUpgrade",
    "UpgradeHive",
    "StartResearch",
    "BuildHarvester",
    "AbilityBonewall",
    "AbilityShadeInk",
    "AbilityRupture",
    "AbilityNutrientMist",
    "AbilityContamination",
    "BuildCyst",
    "Idle",
    "AbilityHatchEggs",
    "BuildDrifter",
    "BuildHive",
    "BuildTunnel"
  })
else
  kOldComActionTypes = enum({ -- Bot_Maintenance actions.
    "BuildHiveCrag",
    "BuildDoubleTunnel",
    "BuildShadeDouble",
    "BuildHiveShade",
    "BuildHiveWhip",
    "BuildHiveUpgrade",
    "UpgradeHive",
    "StartResearch",
    "BuildHarvester",
    "AbilityBonewall",
    "AbilityBonewallExo",
    "AbilityShadeInk",
    "AbilityRupture",
    "AbilityNutrientMist",
    "AbilityContamination",
    "BuildCyst",
    "Idle",
    "AbilityHatchEggs",
    "BuildDrifter",
    "BuildHive",
    "BuildTunnel"
  })
end

local function GetOldComActionIndex(action)
  return kOldComActionTypes[kOldComActionTypes[action]]
end

--------------------------------------------------------------------------------
-- Make a local copy of the brain actions array.
--------------------------------------------------------------------------------
-- Without a deep copy of the array, the old functions get replaced and hooks
-- will break.

local kOldComActions = {}

for i, v in ipairs(kAlienComBrainActions) do
  kOldComActions[i] = v
end

local function GetOldComAction(action)
  return kOldComActions[GetOldComActionIndex(action)]
end

--------------------------------------------------------------------------------
-- Load the commander actions.
--------------------------------------------------------------------------------

Script.Load("lua/bishop/aliencom/AComActions_Abilities.lua")
Script.Load("lua/bishop/aliencom/AComActions_Cyst.lua")
Script.Load("lua/bishop/aliencom/AComActions_Harvester.lua")
Script.Load("lua/bishop/aliencom/AComActions_Hive.lua")
Script.Load("lua/bishop/aliencom/AComActions_OffensiveTunnel.lua")
Script.Load("lua/bishop/aliencom/AComActions_Research.lua")
Script.Load("lua/bishop/aliencom/AComActions_Tunnel.lua")
Script.Load("lua/bishop/aliencom/AComActions_UpgradeEgg.lua")

--------------------------------------------------------------------------------
-- Convert the remaining unmodded actions to Bishop priorities.
--------------------------------------------------------------------------------

local BuildHiveCrag = GetOldComAction(kOldComActionTypes.BuildHiveCrag)

function actions.BuildHiveCrag(bot, brain, com)
  local action = BuildHiveCrag(bot, brain, com)
  action.name = "BuildHiveCrag"

  if (action.weight > 0) then
    action.weight = GetActionWeight(actionTypes.BuildHiveCrag)
  end

  return action
end

local BuildHiveShade = GetOldComAction(kOldComActionTypes.BuildHiveShade)

function actions.BuildHiveShade(bot, brain, com)
  local action = BuildHiveShade(bot, brain, com)
  action.name = "BuildHiveShade"

  if (action.weight > 0) then
    action.weight = GetActionWeight(actionTypes.BuildHiveShade)
  end

  return action
end

local BuildHiveWhip = GetOldComAction(kOldComActionTypes.BuildHiveWhip)

function actions.BuildHiveWhip(bot, brain, com)
  local action = BuildHiveWhip(bot, brain, com)
  action.name = "BuildHiveWhip"

  if (action.weight > 0) then
    action.weight = GetActionWeight(actionTypes.BuildHiveWhip)
  end

  return action
end

local AbilityBonewall = GetOldComAction(kOldComActionTypes.AbilityBonewall)

function actions.AbilityBonewall(bot, brain, com)
  local action = AbilityBonewall(bot, brain, com)
  action.name = "AbilityBonewall"

  if (action.weight > 0) then
    action.weight = GetActionWeight(actionTypes.AbilityBonewall)
  end

  return action
end

local AbilityBonewallExo = nil
if kBotMaintenanceLoaded then
  local AbilityBonewallExo =
    GetOldComAction(kOldComActionTypes.AbilityBonewallExo)

  function actions.AbilityBonewallExo(bot, brain, com)
    local action = AbilityBonewallExo(bot, brain, com)
    action.name = "AbilityBonewallExo"

    if action.weight > 0 then
      action.weight = GetActionWeight(actionTypes.AbilityBonewall)
    end

    return action
  end
end

local AbilityShadeInk = GetOldComAction(kOldComActionTypes.AbilityShadeInk)

function actions.AbilityShadeInk(bot, brain, com)
  local action = AbilityShadeInk(bot, brain, com)
  action.name = "AbilityShadeInk"

  if (action.weight > 0) then
    action.weight = GetActionWeight(actionTypes.AbilityShadeInk)
  end

  return action
end

local AbilityRupture = GetOldComAction(kOldComActionTypes.AbilityRupture)

function actions.AbilityRupture(bot, brain, com)
  local action = AbilityRupture(bot, brain, com)
  action.name = "AbilityRupture"

  if (action.weight > 0) then
    action.weight = GetActionWeight(actionTypes.AbilityRupture)
  end

  return action
end

local AbilityNutrientMist =
  GetOldComAction(kOldComActionTypes.AbilityNutrientMist)

function actions.AbilityNutrientMist(bot, brain, com)
  local action = AbilityNutrientMist(bot, brain, com)
  action.name = "AbilityNutrientMist"

  if (action.weight > 0) then
    action.weight = GetActionWeight(actionTypes.AbilityNutrientMist)
  end

  return action
end

local BuildDrifter = GetOldComAction(kOldComActionTypes.BuildDrifter)

function actions.BuildDrifter(bot, brain, com)
  local action = BuildDrifter(bot, brain, com)
  action.name = "BuildDrifter"

  if (action.weight > 0) then
    action.weight = GetActionWeight(actionTypes.BuildDrifter)
  end

  return action
end

local TheyMostlyComeAtNight = GetOldComAction(kOldComActionTypes.Idle)

function actions.TheyMostlyComeAtNight(bot, brain, com)
  local action = TheyMostlyComeAtNight(bot, brain, com)
  action.name = "TheyMostlyComeAtNight"

  if (action.weight > 0) then
    action.weight = GetActionWeight(actionTypes.TheyMostlyComeAtNight)
  end

  return action
end

--------------------------------------------------------------------------------
-- Setup the actions array.
--------------------------------------------------------------------------------

if not kBotMaintenanceLoaded then
  kAlienComBrainActions = {
    actions.AbilityBonewall,
    actions.AbilityShadeInk,
    actions.AbilityRupture,
    actions.AbilityNutrientMist,
    actions.AbilityContamination,
    actions.AbilityHatchEggs,
    actions.StartResearch,
    actions.UpgradeHive,
    actions.BuildUpgradeChamber,
    actions.BuildHiveCrag,
    actions.BuildHiveShade,
    actions.BuildHiveWhip,
    actions.BuildHive,
    actions.CystToHarvester,
    actions.CystToTechPoint,
    actions.CystToRequest,
    actions.RecystBuilding,
    actions.BuildHarvester,
    actions.BuildTunnelEntrance,
    actions.BuildTunnelExit,
    actions.BuildOffensiveTunnel,
    actions.ManageOffensiveTunnel,
    actions.BuildDrifter,
    actions.TheyMostlyComeAtNight,
    Bishop.alienCom.actions.UpgradeEgg,
  }
else
  kAlienComBrainActions = {
    actions.AbilityBonewall,
    actions.AbilityBonewallExo,
    actions.AbilityShadeInk,
    actions.AbilityRupture,
    actions.AbilityNutrientMist,
    actions.AbilityContamination,
    actions.AbilityHatchEggs,
    actions.StartResearch,
    actions.UpgradeHive,
    actions.BuildUpgradeChamber,
    actions.BuildHiveCrag,
    actions.BuildHiveShade,
    actions.BuildHiveWhip,
    actions.BuildHive,
    actions.CystToHarvester,
    actions.CystToTechPoint,
    actions.CystToRequest,
    actions.RecystBuilding,
    actions.BuildHarvester,
    actions.BuildTunnelEntrance,
    actions.BuildTunnelExit,
    actions.BuildOffensiveTunnel,
    actions.ManageOffensiveTunnel,
    actions.BuildDrifter,
    actions.TheyMostlyComeAtNight,
    Bishop.alienCom.actions.UpgradeEgg,
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
