Script.Load("lua/Entity.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/Pheromone.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/bots/CommanderBrain.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetEntitiesAliveForTeamByLocation = GetEntitiesAliveForTeamByLocation
local huge = math.huge
local ipairs = ipairs
local kAlienTeamType = kAlienTeamType
local kTechId = kTechId
local min = math.min
local pairs = pairs

local actions = Bishop.alienCom.actions
local actionTypes = Bishop.alienCom.actionTypes
local CreatePheromone = CreatePheromone
local GetActionWeight = Bishop.alienCom.GetActionWeight
local IsTechStarted = Bishop.utility.IsTechStarted
local kNilAction = Bishop.lib.constants.kNilAction
local TraceBuildPosition = Bishop.utility.TraceBuildPosition

--------------------------------------------------------------------------------
-- Balance values and constants.
--------------------------------------------------------------------------------

local kMaxChamberBuildRadius = 15
local kMaxChambers = 3
local kMinBiomassForHive = 2
local kMinBiomassForHiveUpgrade = 2

local kChamberTechs = {
  kTechId.Shell,
  kTechId.Spur,
  kTechId.Veil
}

local kChamberTechSenses = {
  [kTechId.Shell] = "numShells",
  [kTechId.Spur] = "numSpurs",
  [kTechId.Veil] = "numVeils"
}

local kHiveTypeIndices = {
  [kTechId.Shell] = "numCragHives",
  [kTechId.Spur] = "numShiftHives",
  [kTechId.Veil] = "numShadeHives",
  [kTechId.UpgradeToCragHive] = "numCragHives",
  [kTechId.UpgradeToShiftHive] = "numShiftHives",
  [kTechId.UpgradeToShadeHive] = "numShadeHives"
}

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

local function ChooseHiveUpgrade(order, hiveTypes)
  for _, upgradeTech in ipairs(order) do
    if hiveTypes[kHiveTypeIndices[upgradeTech]] == 0 then
      return upgradeTech
    end
  end
  return nil
end

--------------------------------------------------------------------------------
-- Hive drop under normal circumstances.
--------------------------------------------------------------------------------

function actions.BuildHive(bot, brain, com)
  local senses = brain:GetSenses()
  local techId = kTechId.Hive

  if not senses:Get("doableTechIds")[techId]
      or senses:Get("biomassLevel") < kMinBiomassForHive then
    return kNilAction
  end

  -- TODO: techPointToTake prioritizes distance, is there a better way?
  local techPoint = senses:Get("techPointToTake")
  if not techPoint then
    techPoint = senses:Get("techPointToTakeInfest")
  end
  if not techPoint and com:GetTeamResources() == 200 then
    local techPoints = senses:Get("availTechPoints")
    if #techPoints > 0 then
      techPoint = techPoints[1]
    end
  end  
  if not techPoint then
    return kNilAction
  end

  local position = techPoint:GetOrigin()

  return {
    name = "BuildHive",
    weight = GetActionWeight(actionTypes.BuildHive),
    perform = function(move, bot, brain, com, action)
      brain:ExecuteTechId(com, techId, position, com)
      CreatePheromone(kTechId.ExpandingMarker, position, kAlienTeamType)
    end
  }
end

--------------------------------------------------------------------------------
-- Delay upgrade of initial hive.
--------------------------------------------------------------------------------
-- Upgrading to Crag is delayed in order to get biomass up early, and to save
-- some resources to be greedy with map control.

function actions.UpgradeHive(bot, brain, com)
  local senses = brain:GetSenses()
  local biomass = senses:Get("biomassLevel")
  local hiveTypes = senses:Get("hiveTypes")

  if biomass < kMinBiomassForHiveUpgrade or hiveTypes.numNormalHives == 0 then
    return kNilAction
  end

  local techId = ChooseHiveUpgrade(brain.teamBrain.chamberOrder, hiveTypes)
  if not techId or not senses:Get("doableTechIds")[techId] then
    return kNilAction
  end

  local hive = hiveTypes.normalHives[1]
  local position = hive:GetOrigin()

  return {
    name = "UpgradeHive",
    weight = GetActionWeight(actionTypes.UpgradeHive),
    perform = function(move, bot, brain, com, action)
      brain:ExecuteTechId(com, techId, position, hive)
    end
  }
end

--------------------------------------------------------------------------------
-- Drop upgrade chambers.
--------------------------------------------------------------------------------

local function GetChamberGoal(biomass, hasLeap, numCappableTechPoints)
  if biomass < 2 then
    return 0
  elseif biomass <= 3 and numCappableTechPoints > 0 then
    return 2
  elseif biomass <= 3 then
    return 3
  -- This exists to ensure the commander grabs leap before all three chambers
  -- of the second Hive, or prioritizes resources for an early third Hive.
  elseif biomass >= 4 and (not hasLeap or numCappableTechPoints > 0) then
    return 4
  end

  return 9
end

local function GetChamberHive(safeHives)
  local bestHive = nil
  local lowestChamberCount = huge

  for _, hive in ipairs(safeHives) do
    local chamberCount = 0
    local locationId = hive:GetLocationId()

    for _, chamberTech in ipairs(kChamberTechs) do
      local count = #GetEntitiesAliveForTeamByLocation(kTechId[chamberTech],
        kAlienTeamType, locationId)
      chamberCount = chamberCount + count
    end

    if chamberCount < lowestChamberCount then
      bestHive = hive
      lowestChamberCount = chamberCount
    end
  end

  return bestHive
end

local function GetMissingChambers(senses)
  local hiveTypes = senses:Get("hiveTypes")
  local chambers = {}
  chambers.missing = 0
  chambers.total = 0

  for techId, sense in pairs(kChamberTechSenses) do
    if hiveTypes[kHiveTypeIndices[techId]] > 0 then
      -- If a human player has jumped in the hive and built a bunch of extra
      -- chambers, these shouldn't be counted.
      local existing = min(kMaxChambers, senses:Get(kChamberTechSenses[techId]))
      local missing = kMaxChambers - existing

      chambers[techId] = missing
      chambers.missing = chambers.missing + missing
      chambers.total = chambers.total + existing
    else
      chambers[techId] = 0
    end
  end

  return chambers
end

function actions.BuildUpgradeChamber(bot, brain, com)
  local senses = brain:GetSenses()
  local biomass = senses:Get("biomassLevel")
  local hasLeap = IsTechStarted(com, kTechId.Leap)
  local safeTechPoints = senses:Get("safeTechPoints")

  local chamberGoal = GetChamberGoal(biomass, hasLeap,
    #senses:Get("cystedAvailTechPoints"))
  local chambers = GetMissingChambers(senses)
  
  if chambers.missing == 0 or chambers.total >= chamberGoal then
    return kNilAction
  end

  local hive = GetChamberHive(senses:Get("safeHives"))

  if not hive then
    return kNilAction
  end

  local techId = kTechId.None

  for _, chamberTech in ipairs(kChamberTechs) do
    if chambers[chamberTech] > 0 then
      techId = chamberTech
      break
    end
  end

  if not senses:Get("doableTechIds")[techId] then
    return kNilAction
  end

  local position = TraceBuildPosition(hive:GetOrigin(), 1,
    kMaxChamberBuildRadius, techId, hive:GetLocationName(), com)
  if not position then
    return kNilAction
  end

  return {
    name = "BuildUpgradeChamber",
    weight = GetActionWeight(actionTypes.BuildUpgradeChamber),
    perform = function(move, bot, brain, com, action)
      brain:ExecuteTechId(com, techId, position, com)
    end
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
