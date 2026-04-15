Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/alien/Pack.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.alien.skulk.objectives = {}

local LeavePack = Bishop.alien.pack.LeavePack
local objectives = Bishop.alien.skulk.objectives
local kNilAction = Bishop.lib.constants.kNilAction
local sharedObjectives = Bishop.alien.objectives

--------------------------------------------------------------------------------
-- Objective priorities.
--------------------------------------------------------------------------------
-- Higher in the enum is higher priority.

local objectiveTypes = enum({
  -- Max priority.
  "DefendHive",
  "Retreat",

  -- Responsive.
  "TakeEgg",
  "Evolve",
  "AssaultTechPoint",
  "RespondToThreat",

  -- Role priority.
  "PressureBuilding",

  -- Situational.
  "Pheromone",
  "GoToComPing",

  -- Pack logic.
  "MoveWithPack",

  -- Fallback.
  "PressureEnemyNaturals",
  "GuardHumans",
  "Explore"
})

Bishop.alien.skulk.objectiveTypes = objectiveTypes
local kObjectiveCount = #objectiveTypes

local function GetObjectiveWeight(objective)
  local objectiveIndex = objectiveTypes[objectiveTypes[objective]]

  return kObjectiveCount - objectiveIndex + 1
end

Bishop.alien.skulk.GetObjectiveWeight = GetObjectiveWeight

--------------------------------------------------------------------------------
-- Build a named enum of existing objectives.
--------------------------------------------------------------------------------
-- The ordering of this array MUST match the functions in kSkulkBrainObjectives.
-- This is used to pull the array index of a function.

if #kSkulkBrainObjectives ~= 9 then
  Bishop.Error("Another mod is interfering with Skulk objectives.")
end

local kOldSkulkObjectiveTypes = enum({
  "DefendHive",
  "Retreat",
  "RespondToThreat",
  "Evolve",
  "Pheromone",
  "GoToComPing",
  "PressureEnemyNaturals",
  "GuardHumans",
  "Explore"
})

local function GetOldSkulkObjectiveIndex(objective)
  return kOldSkulkObjectiveTypes[kOldSkulkObjectiveTypes[objective]]
end

--------------------------------------------------------------------------------
-- Make a local copy of the Skulk objectives array.
--------------------------------------------------------------------------------
-- Without a deep copy of the array, the old functions get replaced and hooks
-- will break.

local kOldSkulkObjectives = {}

for i, v in ipairs(kSkulkBrainObjectives) do
  kOldSkulkObjectives[i] = v
end

local function GetOldSkulkObjective(objective)
  return kOldSkulkObjectives[GetOldSkulkObjectiveIndex(objective)]
end

--------------------------------------------------------------------------------
-- Load the Skulk objectives.
--------------------------------------------------------------------------------

Script.Load("lua/bishop/alien/AlienObjectives_Evolve.lua")
Script.Load("lua/bishop/alien/AlienObjectives_Pack.lua")
Script.Load("lua/bishop/alien/AlienObjectives_PressureBuilding.lua")
Script.Load("lua/bishop/alien/skulk/SkulkMovement.lua")
Script.Load("lua/bishop/alien/skulk/SkulkObjectives_TakeEgg.lua")

--------------------------------------------------------------------------------
-- Ensure shared objectives have the correct weights for Skulks.
--------------------------------------------------------------------------------

local Evolve = sharedObjectives.Evolve

function objectives.Evolve(bot, brain, skulk)
  local objective = Evolve(bot, brain, skulk)

  if (objective.weight > 0) then
    objective.weight = GetObjectiveWeight(objectiveTypes.Evolve)
  end

  return objective
end

local MoveWithPack = sharedObjectives.MoveWithPack

function objectives.MoveWithPack(bot, brain, skulk)
  local objective = MoveWithPack(bot, brain, skulk)

  if (objective.weight > 0) then
    objective.weight = GetObjectiveWeight(objectiveTypes.MoveWithPack)
  end

  return objective
end

local AssaultTechPoint = sharedObjectives.AssaultTechPoint

function objectives.AssaultTechPoint(bot, brain, skulk)
  local objective = AssaultTechPoint(bot, brain, skulk)

  if (objective.weight > 0) then
    objective.weight = GetObjectiveWeight(objectiveTypes.AssaultTechPoint)
  end

  return objective
end

local PressureBuilding = sharedObjectives.PressureBuilding

function objectives.PressureBuilding(bot, brain, skulk)
  local objective = PressureBuilding(bot, brain, skulk)

  if (objective.weight > 0) then
    objective.weight = GetObjectiveWeight(objectiveTypes.PressureBuilding)
  end

  return objective
end

--------------------------------------------------------------------------------
-- Convert the remaining unmodded actions to Bishop priorities.
--------------------------------------------------------------------------------

local DefendHive = GetOldSkulkObjective(kOldSkulkObjectiveTypes.DefendHive)

function objectives.DefendHive(bot, brain, skulk)
  local objective = DefendHive(bot, brain, skulk)
  objective.name = "DefendHive"

  if (objective.weight > 0) then
    objective.weight = GetObjectiveWeight(objectiveTypes.DefendHive)
  end

  return objective
end

local Retreat = GetOldSkulkObjective(kOldSkulkObjectiveTypes.Retreat)

function objectives.Retreat(bot, brain, skulk)
  local objective = Retreat(bot, brain, skulk)
  objective.name = "Retreat"

  if (objective.weight > 0) then
    if brain.pack then
      LeavePack(brain)
    end
    
    objective.weight = GetObjectiveWeight(objectiveTypes.Retreat)
  end

  return objective
end

local RespondToThreat =
  GetOldSkulkObjective(kOldSkulkObjectiveTypes.RespondToThreat)

function objectives.RespondToThreat(bot, brain, skulk)
  local objective = RespondToThreat(bot, brain, skulk)
  objective.name = "RespondToThreat"

  if (objective.weight > 0) then
    objective.weight = GetObjectiveWeight(objectiveTypes.RespondToThreat)
  end

  return objective
end

local Pheromone = GetOldSkulkObjective(kOldSkulkObjectiveTypes.Pheromone)

function objectives.Pheromone(bot, brain, skulk)
  local objective = Pheromone(bot, brain, skulk)
  objective.name = "Pheromone"

  if (objective.weight > 0) then
    objective.weight = GetObjectiveWeight(objectiveTypes.Pheromone)
  end

  return objective
end

local GoToComPing = GetOldSkulkObjective(kOldSkulkObjectiveTypes.GoToComPing)

function objectives.GoToComPing(bot, brain, skulk)
  local objective = GoToComPing(bot, brain, skulk)
  objective.name = "GoToComPing"

  if (objective.weight > 0) then
    objective.weight = GetObjectiveWeight(objectiveTypes.GoToComPing)
  end

  return objective
end

local PressureEnemyNaturals =
  GetOldSkulkObjective(kOldSkulkObjectiveTypes.PressureEnemyNaturals)

function objectives.PressureEnemyNaturals(bot, brain, skulk)
  local objective = PressureEnemyNaturals(bot, brain, skulk)
  objective.name = "PressureEnemyNaturals"

  if (objective.weight > 0) then
    objective.weight = GetObjectiveWeight(objectiveTypes.PressureEnemyNaturals)
  end

  return objective
end

local GuardHumans = GetOldSkulkObjective(kOldSkulkObjectiveTypes.GuardHumans)

function objectives.GuardHumans(bot, brain, skulk)
  local objective = GuardHumans(bot, brain, skulk)
  objective.name = "GuardHumans"

  if (objective.weight > 0) then
    objective.weight = GetObjectiveWeight(objectiveTypes.GuardHumans)
  end

  return objective
end

local Explore = GetOldSkulkObjective(kOldSkulkObjectiveTypes.Explore)

function objectives.Explore(bot, brain, skulk)
  local objective = Explore(bot, brain, skulk)
  objective.name = "Explore"

  if (objective.weight > 0) then
    objective.weight = GetObjectiveWeight(objectiveTypes.Explore)
  end

  return objective
end

--------------------------------------------------------------------------------
-- Setup the objectives array.
--------------------------------------------------------------------------------

kSkulkBrainObjectives = {
  objectives.DefendHive,
  objectives.Retreat,
  objectives.RespondToThreat,
  objectives.Evolve,
  objectives.Pheromone,
  objectives.GoToComPing,
  -- objectives.PressureEnemyNaturals,
  objectives.GuardHumans,
  objectives.Explore,
  objectives.MoveWithPack,
  objectives.AssaultTechPoint,
  objectives.PressureBuilding,
  Bishop.alien.skulk.objectives.TakeEgg,
}

--------------------------------------------------------------------------------
-- Drop in the modified PerformMove function to all objectives.
--------------------------------------------------------------------------------

for _, action in ipairs(kOldSkulkObjectives) do
  Shine.SetUpValue(action, "PerformMove", Bishop.alien.skulk.DoMove, true)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
