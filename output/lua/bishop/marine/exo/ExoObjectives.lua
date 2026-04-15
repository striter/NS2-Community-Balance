Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.marine.exo.objectives = {}

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

Bishop.marine.exo.kObjectiveTypes = enum({ -- Priority from high to low.
  -- High priority response.
  "Retreat",
  "FollowOrder",
  "ProtectARC", -- TODO: Appropriate position?
  "DefendTechPoint",

  -- Fireteam leaders.
  "SecureResources",
  "SecureTechPoint",

  -- Low priority response.
  "MoveWithFireteam",
  "PhaseAndAssault",
  "GoToComPing",

  -- Fallback tasks.
  "Explore"
})

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kBotMaintenanceLoaded = #kExoBrainObjectives == 5
local kObjectiveCount = #Bishop.marine.exo.kObjectiveTypes
local kObjectiveTypes = Bishop.marine.exo.kObjectiveTypes
local kOldExoObjectives = {}
local kOldExoObjectiveTypes = {}
local kNilAction = Bishop.lib.constants.kNilAction

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

function Bishop.marine.exo.GetObjectiveWeight(objective)
  local objectiveIndex = kObjectiveTypes[kObjectiveTypes[objective]]
  return kObjectiveCount - objectiveIndex + 1
end
local GetObjectiveWeight = Bishop.marine.exo.GetObjectiveWeight

local function GetOldExoObjectiveIndex(objective)
  return kOldExoObjectiveTypes[kOldExoObjectiveTypes[objective]]
end

local function GetOldExoObjective(objective)
  return kOldExoObjectives[GetOldExoObjectiveIndex(objective)]
end

--------------------------------------------------------------------------------
-- Detection for Bot_Maintenance.
--------------------------------------------------------------------------------

if kBotMaintenanceLoaded then
  Bishop.Log("Compatibility with Bot_Maintenance Exo enabled.")
elseif #kExoBrainObjectives ~= 4 then
  Bishop.Error("Another mod is interfering with Exo actions.")
end

--------------------------------------------------------------------------------
-- Build a named enum of existing objectives.
--------------------------------------------------------------------------------
-- The ordering of this array MUST match the functions in kExoBrainObjectives.
-- This is used to pull the array index of a function.

if not kBotMaintenanceLoaded then
  kOldExoObjectiveTypes = enum({
    "FollowOrder",
    "Retreat",
    "GoToComPing",
    "Explore"
  })
else
  kOldExoObjectiveTypes = enum({
    "FollowOrder",
    "Retreat",
    "ProtectARC",
    "GoToComPing",
    "Explore"
  })
end

--------------------------------------------------------------------------------
-- Make a local copy of the Exo objectives array.
--------------------------------------------------------------------------------
-- Without a deep copy of the array, the old functions get replaced and hooks
-- will break.

for i, v in ipairs(kExoBrainObjectives) do
  kOldExoObjectives[i] = v
end

--------------------------------------------------------------------------------
-- TEMP: Extract PerformMove for use elsewhere.
--------------------------------------------------------------------------------

Bishop.marine.exo.PerformMove = Shine.GetUpValue(
  GetOldExoObjective(kOldExoObjectiveTypes.Explore), "PerformMove", true)
assert(Bishop.marine.exo.PerformMove)
-- This will fall down below if PerformMove is ever rewritten.
Script.Load("lua/bishop/marine/exo/ExoMovement.lua")

--------------------------------------------------------------------------------
-- Load the Exo objectives.
--------------------------------------------------------------------------------

Script.Load("lua/bishop/marine/MarineObjectives_DefendTechPoint.lua")
Script.Load("lua/bishop/marine/MarineObjectives_MoveWithFireteam.lua")
Script.Load("lua/bishop/marine/MarineObjectives_PhaseAndAssault.lua")
Script.Load("lua/bishop/marine/MarineObjectives_SecureResources.lua")
Script.Load("lua/bishop/marine/MarineObjectives_SecureTechPoint.lua")

--------------------------------------------------------------------------------
-- Ensure shared objectives have the correct weights for Exos.
--------------------------------------------------------------------------------

local MoveWithFireteam = Bishop.marine.objectives.MoveWithFireteam

function Bishop.marine.exo.objectives.MoveWithFireteam(bot, brain, exo)
  local objective = MoveWithFireteam(bot, brain, exo)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.MoveWithFireteam)
  end

  return objective
end

local DefendTechPoint = Bishop.marine.objectives.DefendTechPoint

function Bishop.marine.exo.objectives.DefendTechPoint(bot, brain, exo)
  local objective = DefendTechPoint(bot, brain, exo)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.DefendTechPoint)
  end

  return objective
end

local PhaseAndAssault = Bishop.marine.objectives.PhaseAndAssault

function Bishop.marine.exo.objectives.PhaseAndAssault(bot, brain, exo)
  local objective = PhaseAndAssault(bot, brain, exo)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.PhaseAndAssault)
  end

  return objective
end

local SecureResources = Bishop.marine.objectives.SecureResources

function Bishop.marine.exo.objectives.SecureResources(bot, brain, exo)
  local objective = SecureResources(bot, brain, exo)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.SecureResources)
  end

  return objective
end

local SecureTechPoint = Bishop.marine.objectives.SecureTechPoint

function Bishop.marine.exo.objectives.SecureTechPoint(bot, brain, exo)
  local objective = SecureTechPoint(bot, brain, exo)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.SecureTechPoint)
  end

  return objective
end

--------------------------------------------------------------------------------
-- Convert the remaining unmodded actions to Bishop priorities.
--------------------------------------------------------------------------------

local FollowOrder = GetOldExoObjective(kOldExoObjectiveTypes.FollowOrder)

function Bishop.marine.exo.objectives.FollowOrder(bot, brain, exo)
  local objective = FollowOrder(bot, brain, exo)
  objective.name = "FollowOrder"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.FollowOrder)
  end

  return objective
end

local Retreat = GetOldExoObjective(kOldExoObjectiveTypes.Retreat)

function Bishop.marine.exo.objectives.Retreat(bot, brain, exo)
  local objective = Retreat(bot, brain, exo)
  objective.name = "Retreat"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.Retreat)
  end

  return objective
end

local ProtectARC = nil
if kBotMaintenanceLoaded then
  ProtectARC = GetOldExoObjective(kOldExoObjectiveTypes.ProtectARC)

  function Bishop.marine.exo.objectives.ProtectARC(bot, brain, exo)
    local objective = ProtectARC(bot, brain, exo)
    objective.name = "ProtectARC"

    if objective.weight > 0 then
      objective.weight = GetObjectiveWeight(kObjectiveTypes.ProtectARC)
    end

    return objective
  end
end

local GoToComPing = GetOldExoObjective(kOldExoObjectiveTypes.GoToComPing)

function Bishop.marine.exo.objectives.GoToComPing(bot, brain, exo)
  local objective = GoToComPing(bot, brain, exo)
  objective.name = "GoToComPing"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.GoToComPing)
  end

  return objective
end

local Explore = GetOldExoObjective(kOldExoObjectiveTypes.Explore)

function Bishop.marine.exo.objectives.Explore(bot, brain, exo)
  local objective = Explore(bot, brain, exo)
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
  kExoBrainObjectives = {
    Bishop.marine.exo.objectives.FollowOrder,
    Bishop.marine.exo.objectives.Retreat,
    Bishop.marine.exo.objectives.GoToComPing,
    Bishop.marine.exo.objectives.Explore,
    Bishop.marine.exo.objectives.MoveWithFireteam,
    Bishop.marine.exo.objectives.DefendTechPoint,
    Bishop.marine.exo.objectives.PhaseAndAssault,
    Bishop.marine.exo.objectives.SecureResources,
    Bishop.marine.exo.objectives.SecureTechPoint,
  }
else
  kExoBrainObjectives = {
    Bishop.marine.exo.objectives.FollowOrder,
    Bishop.marine.exo.objectives.Retreat,
    Bishop.marine.exo.objectives.GoToComPing,
    Bishop.marine.exo.objectives.Explore,
    Bishop.marine.exo.objectives.MoveWithFireteam,
    Bishop.marine.exo.objectives.DefendTechPoint,
    Bishop.marine.exo.objectives.PhaseAndAssault,
    Bishop.marine.exo.objectives.SecureResources,
    Bishop.marine.exo.objectives.SecureTechPoint,
    Bishop.marine.exo.objectives.ProtectARC
  }
end

--------------------------------------------------------------------------------
-- Drop in the modified PerformMove function to all objectives.
--------------------------------------------------------------------------------

for _, action in ipairs(kExoBrainObjectives) do
  Shine.SetUpValue(action, "PerformMove", Bishop.marine.exo.DoMove, true)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
