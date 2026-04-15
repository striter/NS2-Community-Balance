Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/alien/Pack.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.alien.onos.objectives = {}

local objectives = Bishop.alien.onos.objectives
local sharedObjectives = Bishop.alien.objectives

--------------------------------------------------------------------------------
-- Objective priorities.
--------------------------------------------------------------------------------
-- Higher in the enum is higher priority.

-- TODO: The Onos doesn't have "DefendHive", "PressureEnemyNaturals" and
-- "GuardHumans" objectives. The latter is probably common sense, but the former
-- two could make a meaningful difference to their behaviour.
-- TODO: Even though GoToComPing is present in the objective types, it was not
-- actually implemented.

local objectiveTypes = enum({
  -- Max priority.
  "Retreat",

  -- Responsive.
  "AssaultTechPoint",
  "RespondToThreat",

  -- Situational.
  "Evolve",
  "Pheromone",
  "GoToComPing",

  -- Pack logic.
  "MoveWithPack",

  -- Fallback.
  "PressureBuilding",
  "Explore"
})

Bishop.alien.onos.objectiveTypes = objectiveTypes
local kObjectiveCount = #objectiveTypes

local function GetObjectiveWeight(objective)
  local objectiveIndex = objectiveTypes[objectiveTypes[objective]]

  return kObjectiveCount - objectiveIndex + 1
end

Bishop.alien.onos.GetObjectiveWeight = GetObjectiveWeight

--------------------------------------------------------------------------------
-- Build a named enum of existing objectives.
--------------------------------------------------------------------------------
-- The ordering of this array MUST match the functions in kOnosBrainObjectives.
-- This is used to pull the array index of a function.

if #kOnosBrainObjectives ~= 5 then
  Bishop.Error("Another mod is interfering with Onos objectives.")
end

local kOldOnosObjectiveTypes = enum({
  "Retreat",
  "Evolve",
  "RespondToThreat",
  "Pheromone",
  "Explore"
})

local function GetOldOnosObjectiveIndex(objective)
  return kOldOnosObjectiveTypes[kOldOnosObjectiveTypes[objective]]
end

--------------------------------------------------------------------------------
-- Make a local copy of the Onos objectives array.
--------------------------------------------------------------------------------
-- Without a deep copy of the array, the old functions get replaced and hooks
-- will break.

local kOldOnosObjectives = {}

for i, v in ipairs(kOnosBrainObjectives) do
  kOldOnosObjectives[i] = v
end

local function GetOldOnosObjective(objective)
  return kOldOnosObjectives[GetOldOnosObjectiveIndex(objective)]
end

--------------------------------------------------------------------------------
-- TEMP: Extract PerformMove for use elsewhere.
--------------------------------------------------------------------------------

Bishop.alien.onos.PerformMove = Shine.GetUpValue(
  GetOldOnosObjective(kOldOnosObjectiveTypes.Explore), "PerformMove", true)
assert(Bishop.alien.onos.PerformMove)
Script.Load("lua/bishop/alien/onos/OnosMovement.lua")

--------------------------------------------------------------------------------
-- Load the Onos objectives.
--------------------------------------------------------------------------------

Script.Load("lua/bishop/alien/AlienObjectives_Evolve.lua")
Script.Load("lua/bishop/alien/AlienObjectives_Pack.lua")
Script.Load("lua/bishop/alien/AlienObjectives_PressureBuilding.lua")
Script.Load("lua/bishop/alien/AlienObjectives_Retreat.lua")

--------------------------------------------------------------------------------
-- Ensure shared objectives have the correct weights for Onos.
--------------------------------------------------------------------------------

local Retreat = sharedObjectives.Retreat

function objectives.Retreat(bot, brain, onos)
  local objective = Retreat(bot, brain, onos)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(objectiveTypes.Retreat)
  end

  return objective
end

local Evolve = sharedObjectives.Evolve

function objectives.Evolve(bot, brain, onos)
  local objective = Evolve(bot, brain, onos)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(objectiveTypes.Evolve)
  end

  return objective
end

local MoveWithPack = sharedObjectives.MoveWithPack

function objectives.MoveWithPack(bot, brain, onos)
  local objective = MoveWithPack(bot, brain, onos)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(objectiveTypes.MoveWithPack)
  end

  return objective
end

local AssaultTechPoint = sharedObjectives.AssaultTechPoint

function objectives.AssaultTechPoint(bot, brain, onos)
  local objective = AssaultTechPoint(bot, brain, onos)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(objectiveTypes.AssaultTechPoint)
  end

  return objective
end

local PressureBuilding = sharedObjectives.PressureBuilding

function objectives.PressureBuilding(bot, brain, onos)
  local objective = PressureBuilding(bot, brain, onos)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(objectiveTypes.PressureBuilding)
  end

  return objective
end

--------------------------------------------------------------------------------
-- Convert the remaining unmodded actions to Bishop priorities.
--------------------------------------------------------------------------------

local RespondToThreat =
  GetOldOnosObjective(kOldOnosObjectiveTypes.RespondToThreat)

function objectives.RespondToThreat(bot, brain, onos)
  local objective = RespondToThreat(bot, brain, onos)
  objective.name = "RespondToThreat"

  if (objective.weight > 0) then
    objective.weight = GetObjectiveWeight(objectiveTypes.RespondToThreat)
  end

  return objective
end

local Pheromone = GetOldOnosObjective(kOldOnosObjectiveTypes.Pheromone)

function objectives.Pheromone(bot, brain, onos)
  local objective = Pheromone(bot, brain, onos)
  objective.name = "Pheromone"

  if (objective.weight > 0) then
    objective.weight = GetObjectiveWeight(objectiveTypes.Pheromone)
  end

  return objective
end

local Explore = GetOldOnosObjective(kOldOnosObjectiveTypes.Explore)

function objectives.Explore(bot, brain, onos)
  local objective = Explore(bot, brain, onos)
  objective.name = "Explore"

  if (objective.weight > 0) then
    objective.weight = GetObjectiveWeight(objectiveTypes.Explore)
  end

  return objective
end

--------------------------------------------------------------------------------
-- Setup the objectives array.
--------------------------------------------------------------------------------

kOnosBrainObjectives = {
  objectives.Retreat,
  objectives.RespondToThreat,
  objectives.Evolve,
  objectives.Pheromone,
  objectives.Explore,
  objectives.MoveWithPack,
  objectives.AssaultTechPoint,
  objectives.PressureBuilding
}

--------------------------------------------------------------------------------
-- Drop in the modified PerformMove function to all objectives.
--------------------------------------------------------------------------------

for _, action in ipairs(kOldOnosObjectives) do
  Shine.SetUpValue(action, "PerformMove", Bishop.alien.onos.DoMove, true)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
