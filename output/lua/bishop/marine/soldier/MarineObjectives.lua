Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/marine/Fireteam.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.marine.objectives = {}
Bishop.marine.soldier.objectives = {} -- TODO: Transition to this array instead.

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

Bishop.marine.kObjectiveTypes = enum({ -- Priority from high to low.
  -- Absolute priority, must be performed ASAP whenever relevant.
  "FollowOrder",
  "DefendTechPoint",
  "DefendPriority",

  -- High priority.
  "BuyWeapon",
  "BuyJetpack",
  "GuardARC", -- TODO: Added by Bot_Maintenance.
  "WaitForNaturals", -- Bot_Maintenance includes additional nodes.
  "FollowBuddyGL", -- TODO: Added by Bot_Maintenance.

  -- Medium priority.
  "RespondToThreat",
  "Retreat",
  "DefendNearbyStructures",
  "RespondToThreat_LOW",

  -- Fireteam leaders.
  "SecureResources",
  "SecureTechPoint",
  "TakeTerritory", -- In the event a marine has no fireteam.

  -- Gear acquisition.
  "BuyGrenade",
  "BuyMine",

  -- Construction and defence.
  "UseArmory",
  "BuyWelder",
  "RepairPower",
  "BuildStructure",
  "PlaceMine",

  -- Low priority response.
  "GoToCommPing",

  -- Fallback tasks.
  "MoveWithFireteam",
  "PhaseAndAssault",
  "PressureEnemyNaturals", -- TODO: Map-wide instead of just naturals.
  "GuardHuman",
  "GuardExo",
  "Explore"                -- TODO: Move up but limit to only 1 marine.
})

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kBotMaintenanceLoaded = #kMarineBrainObjectiveActions == 23
local kObjectiveCount = #Bishop.marine.kObjectiveTypes
local kObjectiveTypes = Bishop.marine.kObjectiveTypes
local kOldMarineObjectives = {}
local kOldMarineObjectiveTypes = {}

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

function Bishop.marine.GetObjectiveWeight(objectiveType)
  local objectiveIndex = kObjectiveTypes[kObjectiveTypes[objectiveType]]
  return kObjectiveCount - objectiveIndex + 1
end
local GetObjectiveWeight = Bishop.marine.GetObjectiveWeight

local function GetOldMarineObjectiveIndex(objectiveType)
  return kOldMarineObjectiveTypes[kOldMarineObjectiveTypes[objectiveType]]
end

local function GetOldMarineObjective(objectiveType)
  return kOldMarineObjectives[GetOldMarineObjectiveIndex(objectiveType)]
end

--------------------------------------------------------------------------------
-- Mod conflict detection.
--------------------------------------------------------------------------------

if not kBotMaintenanceLoaded and #kMarineBrainObjectiveActions ~= 20 then
  Bishop.Error("Another mod is interfering with Marine objectives.")
end

--------------------------------------------------------------------------------
-- Build a named enum of existing objectives.
--------------------------------------------------------------------------------
-- The ordering of this array MUST match the functions in
-- kMarineBrainObjectiveActions. This is used to pull the array index of a
-- function.

if not kBotMaintenanceLoaded then
  kOldMarineObjectiveTypes = enum({
    "FollowOrder",
    "RespondToThreat",
    "TakeTerritory",
    "UseArmory",
    "Retreat",
    "GoToCommPing",
    "DefendNearbyStructures",
    "BuildStructure",
    "PlaceMine",
    "BuyWelder",
    "BuyExo",
    "RepairPower",
    "BuyWeapon",
    "BuyJetpack",
    "BuyMine",
    "GuardHuman",
    "GuardExo",
    "WaitForNaturals",
    "PressureEnemyNaturals",
    "Explore"
  })
else
  kOldMarineObjectiveTypes = enum({
    "FollowOrder",
    "RespondToThreat",
    "TakeTerritory",
    "UseArmory",
    "Retreat",
    "GoToCommPing",
    "DefendNearbyStructures",
    "BuildStructure",
    "PlaceMine",
    "BuyWelder",
    "BuyExo",
    "RepairPower",
    "BuyWeapon",
    "BuyJetpack",
    "BuyMine",
    "BuyGrenade", -- Bot_Maintenance.
    "GuardHuman",
    "GuardExo",
    "FollowBuddyGL", -- TODO: New Bot_Maintenance action.
    "GuardARC", -- TODO: New Bot_Maintenance action.
    "WaitForNaturals",
    "PressureEnemyNaturals",
    "Explore"
  })
end

--------------------------------------------------------------------------------
-- Make a local copy of the Fade objectives array.
--------------------------------------------------------------------------------
-- Without a deep copy of the array, the old functions get replaced and hooks
-- will break.

for i, v in ipairs(kMarineBrainObjectiveActions) do
  kOldMarineObjectives[i] = v
end

--------------------------------------------------------------------------------
-- TEMP: Extract PerformMove for use elsewhere.
--------------------------------------------------------------------------------

Bishop.marine.PerformMove = Shine.GetUpValue(
  GetOldMarineObjective(kOldMarineObjectiveTypes.Explore), "PerformMove", true)
assert(Bishop.marine.PerformMove)
Script.Load("lua/bishop/marine/soldier/MarineMovement.lua")

--------------------------------------------------------------------------------
-- Load Marine objectives.
--------------------------------------------------------------------------------

Script.Load("lua/bishop/marine/soldier/SoldierObjectives_BuyWeapon.lua")
Script.Load("lua/bishop/marine/MarineObjectives_DefendPriority.lua")
Script.Load("lua/bishop/marine/MarineObjectives_DefendTechPoint.lua")
Script.Load("lua/bishop/marine/MarineObjectives_MoveWithFireteam.lua")
Script.Load("lua/bishop/marine/MarineObjectives_PhaseAndAssault.lua")
Script.Load("lua/bishop/marine/MarineObjectives_SecureResources.lua")
Script.Load("lua/bishop/marine/MarineObjectives_SecureTechPoint.lua")

--------------------------------------------------------------------------------
-- Ensure shared objectives have the correct weights for marines.
--------------------------------------------------------------------------------

local MoveWithFireteam = Bishop.marine.objectives.MoveWithFireteam

function Bishop.marine.soldier.objectives.MoveWithFireteam(bot, brain, marine)
  local objective = MoveWithFireteam(bot, brain, marine)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.MoveWithFireteam)
  end

  return objective
end

local DefendTechPoint = Bishop.marine.objectives.DefendTechPoint

function Bishop.marine.soldier.objectives.DefendTechPoint(bot, brain, marine)
  local objective = DefendTechPoint(bot, brain, marine)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.DefendTechPoint)
  end

  return objective
end

local PhaseAndAssault = Bishop.marine.objectives.PhaseAndAssault

function Bishop.marine.soldier.objectives.PhaseAndAssault(bot, brain, marine)
  local objective = PhaseAndAssault(bot, brain, marine)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.PhaseAndAssault)
  end

  return objective
end

local SecureResources = Bishop.marine.objectives.SecureResources

function Bishop.marine.soldier.objectives.SecureResources(bot, brain, marine)
  local objective = SecureResources(bot, brain, marine)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.SecureResources)
  end

  return objective
end

local SecureTechPoint = Bishop.marine.objectives.SecureTechPoint

function Bishop.marine.soldier.objectives.SecureTechPoint(bot, brain, marine)
  local objective = SecureTechPoint(bot, brain, marine)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.SecureTechPoint)
  end

  return objective
end

--------------------------------------------------------------------------------
-- Convert the remaining unmodded actions to Bishop priorities.
--------------------------------------------------------------------------------

local FollowOrder = GetOldMarineObjective(kOldMarineObjectiveTypes.FollowOrder)

function Bishop.marine.objectives.FollowOrder(bot, brain, marine)
  local objective = FollowOrder(bot, brain, marine)
  objective.name = "FollowOrder"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.FollowOrder)
  end

  return objective
end

local RespondToThreat = GetOldMarineObjective(
  kOldMarineObjectiveTypes.RespondToThreat)

function Bishop.marine.objectives.RespondToThreat(bot, brain, marine)
  local objective = RespondToThreat(bot, brain, marine)
  objective.name = "RespondToThreat"

  if objective.weight > 1800 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.RespondToThreat)
  elseif objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.RespondToThreat_LOW)
  end

  return objective
end

local TakeTerritory = GetOldMarineObjective(
  kOldMarineObjectiveTypes.TakeTerritory)

function Bishop.marine.objectives.TakeTerritory(bot, brain, marine)
  local objective = TakeTerritory(bot, brain, marine)
  objective.name = "TakeTerritory"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.TakeTerritory)
  end

  return objective
end

local UseArmory = GetOldMarineObjective(kOldMarineObjectiveTypes.UseArmory)

function Bishop.marine.objectives.UseArmory(bot, brain, marine)
  local objective = UseArmory(bot, brain, marine)
  objective.name = "UseArmory"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.UseArmory)
  end

  return objective
end

local Retreat = GetOldMarineObjective(kOldMarineObjectiveTypes.Retreat)

function Bishop.marine.objectives.Retreat(bot, brain, marine)
  local objective = Retreat(bot, brain, marine)
  objective.name = "Retreat"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.Retreat)
  end

  return objective
end

local GoToCommPing = GetOldMarineObjective(
  kOldMarineObjectiveTypes.GoToCommPing)

function Bishop.marine.objectives.GoToCommPing(bot, brain, marine)
  local objective = GoToCommPing(bot, brain, marine)
  objective.name = "GoToCommPing"

  if objective.weight > 0 then
    if GetGameMinutesPassed() < 1 then
      objective.weight = 0
    else
      objective.weight = GetObjectiveWeight(kObjectiveTypes.GoToCommPing)
    end
  end

  return objective
end

local DefendNearbyStructures = GetOldMarineObjective(
  kOldMarineObjectiveTypes.DefendNearbyStructures)

function Bishop.marine.objectives.DefendNearbyStructures(bot, brain, marine)
  local objective = DefendNearbyStructures(bot, brain, marine)
  objective.name = "DefendNearbyStructures"

  if objective.weight > 0 then
    -- TODO: Vanilla's dynamic weight on this function effectively did nothing.
    -- Perhaps they intended to multiply instead of add?
    objective.weight = GetObjectiveWeight(
      kObjectiveTypes.DefendNearbyStructures)
  end

  return objective
end

local BuildStructure = GetOldMarineObjective(
  kOldMarineObjectiveTypes.BuildStructure)

function Bishop.marine.objectives.BuildStructure(bot, brain, marine)
  local objective = BuildStructure(bot, brain, marine)
  objective.name = "BuildStructure"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.BuildStructure)
  end

  return objective
end

local PlaceMine = GetOldMarineObjective(kOldMarineObjectiveTypes.PlaceMine)

function Bishop.marine.objectives.PlaceMine(bot, brain, marine)
  local objective = PlaceMine(bot, brain, marine)
  objective.name = "PlaceMine"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.PlaceMine)
  end

  return objective
end

local BuyWelder = GetOldMarineObjective(kOldMarineObjectiveTypes.BuyWelder)

function Bishop.marine.objectives.BuyWelder(bot, brain, marine)
  local objective = BuyWelder(bot, brain, marine)
  objective.name = "BuyWelder"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.BuyWelder)
  end

  return objective
end

local RepairPower = GetOldMarineObjective(kOldMarineObjectiveTypes.RepairPower)

function Bishop.marine.objectives.RepairPower(bot, brain, marine)
  local objective = RepairPower(bot, brain, marine)
  objective.name = "RepairPower"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.RepairPower)
  end

  return objective
end

local BuyJetpack = GetOldMarineObjective(kOldMarineObjectiveTypes.BuyJetpack)

function Bishop.marine.objectives.BuyJetpack(bot, brain, marine)
  do
    local currentWeapon = marine:GetWeaponInHUDSlot(1)
    if currentWeapon and currentWeapon:GetTechId() == kTechId.Rifle
        and not Bishop.settings.marine.jetpackLmg then
      return Bishop.lib.constants.kNilAction
    end
  end

  local objective = BuyJetpack(bot, brain, marine)
  objective.name = "BuyJetpack"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.BuyJetpack)
  end

  return objective
end

local BuyMine = GetOldMarineObjective(kOldMarineObjectiveTypes.BuyMine)

function Bishop.marine.objectives.BuyMine(bot, brain, marine)
  local objective = BuyMine(bot, brain, marine)
  objective.name = "BuyMine"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.BuyMine)
  end

  return objective
end

if kBotMaintenanceLoaded then
  local BuyGrenade = GetOldMarineObjective(kOldMarineObjectiveTypes.BuyGrenade)

  function Bishop.marine.objectives.BuyGrenade(bot, brain, marine)
    local objective = BuyGrenade(bot, brain, marine)
    objective.name = "BuyGrenade"

    if objective.weight > 0 then
      objective.weight = GetObjectiveWeight(kObjectiveTypes.BuyGrenade)
    end

    return objective
  end

  local FollowBuddyGL =
    GetOldMarineObjective(kOldMarineObjectiveTypes.FollowBuddyGL)

  function Bishop.marine.objectives.FollowBuddyGL(bot, brain, marine)
    local objective = FollowBuddyGL(bot, brain, marine)
    objective.name = "FollowBuddyGL"

    if objective.weight > 0 then
      objective.weight = GetObjectiveWeight(kObjectiveTypes.FollowBuddyGL)

      -- If this bot intends to follow another bot, ensure it isn't a fireteam
      -- leader to prevent a stare-off.
      if Bishop.marine.fireteam.IsFireteamLeader(brain) then
        Bishop.marine.fireteam.LeaveFireteam(brain)
      end
    end

    return objective
  end

  local GuardARC = GetOldMarineObjective(kOldMarineObjectiveTypes.GuardARC)

  function Bishop.marine.objectives.GuardARC(bot, brain, marine)
    local objective = GuardARC(bot, brain, marine)
    objective.name = "GuardARC"

    if objective.weight > 0 then
      objective.weight = GetObjectiveWeight(kObjectiveTypes.GuardARC)
    end

    return objective
  end
end

local GuardHuman = GetOldMarineObjective(kOldMarineObjectiveTypes.GuardHuman)

function Bishop.marine.objectives.GuardHuman(bot, brain, marine)
  local objective = GuardHuman(bot, brain, marine)
  objective.name = "GuardHuman"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.GuardHuman)
  end

  return objective
end

local GuardExo = GetOldMarineObjective(kOldMarineObjectiveTypes.GuardExo)

function Bishop.marine.objectives.GuardExo(bot, brain, marine)
  local objective = GuardExo(bot, brain, marine)
  objective.name = "GuardExo"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.GuardExo)
  end

  return objective
end

local WaitForNaturals = GetOldMarineObjective(
  kOldMarineObjectiveTypes.WaitForNaturals)

function Bishop.marine.objectives.WaitForNaturals(bot, brain, marine)
  local objective = WaitForNaturals(bot, brain, marine)
  objective.name = "WaitForNaturals"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.WaitForNaturals)

    -- Bot_Maintenance will send marines to Tech Points without a Command
    -- Station. Since Bishop delays construction of a Station, this can result
    -- in idle marines at TPs.
    if objective.resNode and objective.resNode:isa("TechPoint") then
      local phaseGates = GetEntitiesAliveForTeamByLocation("PhaseGate",
        marine:GetTeamNumber(), objective.resNode:GetLocationId())

      if #phaseGates > 0 then objective.weight = 0 end
    end
  end

  return objective
end

local PressureEnemyNaturals = GetOldMarineObjective(
  kOldMarineObjectiveTypes.PressureEnemyNaturals)

function Bishop.marine.objectives.PressureEnemyNaturals(bot, brain, marine)
  local objective = PressureEnemyNaturals(bot, brain, marine)
  objective.name = "PressureEnemyNaturals"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.PressureEnemyNaturals)
  end

  return objective
end

local Explore = GetOldMarineObjective(kOldMarineObjectiveTypes.Explore)

function Bishop.marine.objectives.Explore(bot, brain, marine)
  local objective = Explore(bot, brain, marine)
  objective.name = "Explore"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.Explore)
  end

  return objective
end

--------------------------------------------------------------------------------
-- Setup the objectives array.
--------------------------------------------------------------------------------

if not kBotMaintenanceLoaded then
  kMarineBrainObjectiveActions = {
    Bishop.marine.objectives.FollowOrder,
    Bishop.marine.objectives.RespondToThreat,
    Bishop.marine.objectives.TakeTerritory,
    Bishop.marine.objectives.UseArmory,
    Bishop.marine.objectives.Retreat,
    Bishop.marine.objectives.GoToCommPing,
    Bishop.marine.objectives.DefendNearbyStructures,
    Bishop.marine.objectives.BuildStructure,
    Bishop.marine.objectives.PlaceMine,
    Bishop.marine.objectives.BuyWelder,
    Bishop.marine.soldier.objectives.BuyWeapon,
    Bishop.marine.objectives.RepairPower,
    Bishop.marine.objectives.BuyJetpack,
    Bishop.marine.objectives.BuyMine,
    Bishop.marine.objectives.GuardHuman,
    Bishop.marine.objectives.GuardExo,
    Bishop.marine.objectives.WaitForNaturals,
    Bishop.marine.objectives.PressureEnemyNaturals,
    Bishop.marine.objectives.Explore,
    Bishop.marine.soldier.objectives.MoveWithFireteam,
    Bishop.marine.soldier.objectives.SecureTechPoint,
    Bishop.marine.soldier.objectives.SecureResources,
    Bishop.marine.soldier.objectives.PhaseAndAssault,
    Bishop.marine.soldier.objectives.DefendTechPoint,
    Bishop.marine.objectives.DefendPriority,
  }
else
  kMarineBrainObjectiveActions = {
    Bishop.marine.objectives.FollowOrder,
    Bishop.marine.objectives.RespondToThreat,
    Bishop.marine.objectives.TakeTerritory,
    Bishop.marine.objectives.UseArmory,
    Bishop.marine.objectives.Retreat,
    Bishop.marine.objectives.GoToCommPing,
    Bishop.marine.objectives.DefendNearbyStructures,
    Bishop.marine.objectives.BuildStructure,
    Bishop.marine.objectives.PlaceMine,
    Bishop.marine.objectives.BuyWelder,
    Bishop.marine.soldier.objectives.BuyWeapon,
    Bishop.marine.objectives.RepairPower,
    Bishop.marine.objectives.BuyJetpack,
    Bishop.marine.objectives.BuyMine,
    Bishop.marine.objectives.BuyGrenade,
    Bishop.marine.objectives.GuardHuman,
    Bishop.marine.objectives.GuardExo,
    Bishop.marine.objectives.WaitForNaturals,
    Bishop.marine.objectives.PressureEnemyNaturals,
    Bishop.marine.objectives.Explore,
    Bishop.marine.soldier.objectives.MoveWithFireteam,
    Bishop.marine.soldier.objectives.SecureTechPoint,
    Bishop.marine.soldier.objectives.SecureResources,
    Bishop.marine.soldier.objectives.PhaseAndAssault,
    Bishop.marine.soldier.objectives.DefendTechPoint,
    Bishop.marine.objectives.FollowBuddyGL,
    Bishop.marine.objectives.GuardARC,
    Bishop.marine.objectives.DefendPriority,
  }
end

--------------------------------------------------------------------------------
-- Drop in the modified PerformMove function to all objectives.
--------------------------------------------------------------------------------

for _, action in ipairs(kMarineBrainObjectiveActions) do
  Shine.SetUpValue(action, "PerformMove", Bishop.marine.DoMove, true)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
