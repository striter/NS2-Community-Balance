Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/alien/Pack.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.alien.lerk.objectives = {}

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

Bishop.alien.lerk.kObjectiveTypes = enum({ -- Priority from high to low.
  -- Max priority.
  "Retreat",

  -- Responsive.
  "Evolve",
  "AssaultTechPoint",
  "RespondToThreat",

  -- Situational.
  "Pheromone",

  -- Pack logic.
  "MoveWithPack",

  -- Fallback.
  "Explore"
})

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kObjectiveCount = #Bishop.alien.lerk.kObjectiveTypes
local kObjectiveTypes = Bishop.alien.lerk.kObjectiveTypes
local kOldLerkObjectives = {}
local kOldLerkObjectiveTypes = {}

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

function Bishop.alien.lerk.GetObjectiveWeight(objective)
  local objectiveIndex = kObjectiveTypes[kObjectiveTypes[objective]]
  return kObjectiveCount - objectiveIndex + 1
end
local GetObjectiveWeight = Bishop.alien.lerk.GetObjectiveWeight

local function GetOldLerkObjectiveIndex(objective)
  return kOldLerkObjectiveTypes[kOldLerkObjectiveTypes[objective]]
end

local function GetOldLerkObjective(objective)
  return kOldLerkObjectives[GetOldLerkObjectiveIndex(objective)]
end

--------------------------------------------------------------------------------
-- Build a named enum of existing objectives.
--------------------------------------------------------------------------------
-- The ordering of this array MUST match the functions in kLerkBrainObjectives.
-- This is used to pull the array index of a function.

if #kLerkBrainObjectives ~= 5 then
  Bishop.Error("Another mod is interfering with Lerk objectives.")
end

kOldLerkObjectiveTypes = enum({
  "Retreat",
  "RespondToThreat",
  "Evolve",
  "Pheromone",
  "Explore"
})

--------------------------------------------------------------------------------
-- Make a local copy of the Lerk objectives array.
--------------------------------------------------------------------------------
-- Without a deep copy of the array, the old functions get replaced and hooks
-- will break.

for i, v in ipairs(kLerkBrainObjectives) do
  kOldLerkObjectives[i] = v
end

--------------------------------------------------------------------------------
-- Load the Lerk objectives.
--------------------------------------------------------------------------------

Script.Load("lua/bishop/alien/AlienObjectives_Evolve.lua")
Script.Load("lua/bishop/alien/AlienObjectives_Pack.lua")
Script.Load("lua/bishop/alien/AlienObjectives_Retreat.lua")
Script.Load("lua/bishop/alien/lerk/LerkMovement.lua")

--------------------------------------------------------------------------------
-- Ensure shared objectives have the correct weights for Lerks.
--------------------------------------------------------------------------------

local Retreat = Bishop.alien.objectives.Retreat

function Bishop.alien.lerk.objectives.Retreat(bot, brain, lerk)
  local objective = Retreat(bot, brain, lerk)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.Retreat)
  end

  return objective
end

local Evolve = Bishop.alien.objectives.Evolve

function Bishop.alien.lerk.objectives.Evolve(bot, brain, lerk)
  local objective = Evolve(bot, brain, lerk)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.Evolve)
  end

  return objective
end

local MoveWithPack = Bishop.alien.objectives.MoveWithPack

function Bishop.alien.lerk.objectives.MoveWithPack(bot, brain, lerk)
  local objective = MoveWithPack(bot, brain, lerk)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.MoveWithPack)
  end

  return objective
end

local AssaultTechPoint = Bishop.alien.objectives.AssaultTechPoint

function Bishop.alien.lerk.objectives.AssaultTechPoint(bot, brain, lerk)
  local objective = AssaultTechPoint(bot, brain, lerk)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.AssaultTechPoint)
  end

  return objective
end

--------------------------------------------------------------------------------
-- Convert the remaining unmodded actions to Bishop priorities.
--------------------------------------------------------------------------------

local RespondToThreat =
  GetOldLerkObjective(kOldLerkObjectiveTypes.RespondToThreat)

function Bishop.alien.lerk.objectives.RespondToThreat(bot, brain, lerk)
  local objective = RespondToThreat(bot, brain, lerk)
  objective.name = "RespondToThreat"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.RespondToThreat)
  end

  return objective
end

local Pheromone = GetOldLerkObjective(kOldLerkObjectiveTypes.Pheromone)

function Bishop.alien.lerk.objectives.Pheromone(bot, brain, lerk)
  local objective = Pheromone(bot, brain, lerk)
  objective.name = "Pheromone"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.Pheromone)
  end

  return objective
end

local Explore = GetOldLerkObjective(kOldLerkObjectiveTypes.Explore)

function Bishop.alien.lerk.objectives.Explore(bot, brain, lerk)
  local objective = Explore(bot, brain, lerk)
  objective.name = "Explore"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.Explore)
  end

  return objective
end

--------------------------------------------------------------------------------
-- Setup the objectives array.
--------------------------------------------------------------------------------

kLerkBrainObjectives = {
  Bishop.alien.lerk.objectives.Retreat,
  Bishop.alien.lerk.objectives.RespondToThreat,
  Bishop.alien.lerk.objectives.Evolve,
  Bishop.alien.lerk.objectives.Pheromone,
  Bishop.alien.lerk.objectives.Explore,
  Bishop.alien.lerk.objectives.MoveWithPack,
  Bishop.alien.lerk.objectives.AssaultTechPoint
}

--------------------------------------------------------------------------------
-- Drop in the modified PerformMove function to all objectives.
--------------------------------------------------------------------------------

for _, action in ipairs(kOldLerkObjectives) do
  Shine.SetUpValue(action, "PerformMove", Bishop.alien.lerk.DoMove, true)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
