Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/alien/Pack.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.alien.fade.objectives = {}

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

Bishop.alien.fade.kObjectiveTypes = enum({ -- Priority from high to low.
  -- Max priority.
  "Retreat",

  -- Responsive.
  "Evolve",
  "AssaultTechPoint",
  "RespondToThreat",

  -- Situational.
  "Pheromone",
  "GoToComPing",

  -- Pack logic.
  "MoveWithPack",

  -- Fallback.
  "Explore"
})

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kObjectiveCount = #Bishop.alien.fade.kObjectiveTypes
local kObjectiveTypes = Bishop.alien.fade.kObjectiveTypes
local kOldFadeObjectives = {}
local kOldFadeObjectiveTypes = {}

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

function Bishop.alien.fade.GetObjectiveWeight(objective)
  local objectiveIndex = kObjectiveTypes[kObjectiveTypes[objective]]
  return kObjectiveCount - objectiveIndex + 1
end
local GetObjectiveWeight = Bishop.alien.fade.GetObjectiveWeight

local function GetOldFadeObjectiveIndex(objective)
  return kOldFadeObjectiveTypes[kOldFadeObjectiveTypes[objective]]
end

local function GetOldFadeObjective(objective)
  return kOldFadeObjectives[GetOldFadeObjectiveIndex(objective)]
end

--------------------------------------------------------------------------------
-- Build a named enum of existing objectives.
--------------------------------------------------------------------------------
-- The ordering of this array MUST match the functions in kFadeBrainObjectives.
-- This is used to pull the array index of a function.

if #kFadeBrainObjectives ~= 6 then
  Bishop.Error("Another mod is interfering with Fade objectives.")
end

kOldFadeObjectiveTypes = enum({
  "RespondToThreat",
  "Retreat",
  "Evolve",
  "Pheromone",
  "GoToComPing",
  "Explore"
})

--------------------------------------------------------------------------------
-- Make a local copy of the Fade objectives array.
--------------------------------------------------------------------------------
-- Without a deep copy of the array, the old functions get replaced and hooks
-- will break.

for i, v in ipairs(kFadeBrainObjectives) do
  kOldFadeObjectives[i] = v
end

--------------------------------------------------------------------------------
-- Load the Fade objectives.
--------------------------------------------------------------------------------

Script.Load("lua/bishop/alien/AlienObjectives_Evolve.lua")
Script.Load("lua/bishop/alien/AlienObjectives_Pack.lua")
Script.Load("lua/bishop/alien/AlienObjectives_Retreat.lua")
Script.Load("lua/bishop/alien/fade/FadeMovement.lua")

--------------------------------------------------------------------------------
-- Ensure shared objectives have the correct weights for Fades.
--------------------------------------------------------------------------------

local Retreat = Bishop.alien.objectives.Retreat

function Bishop.alien.fade.objectives.Retreat(bot, brain, fade)
  local objective = Retreat(bot, brain, fade)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.Retreat)
  end

  return objective
end

local Evolve = Bishop.alien.objectives.Evolve

function Bishop.alien.fade.objectives.Evolve(bot, brain, fade)
  local objective = Evolve(bot, brain, fade)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.Evolve)
  end

  return objective
end

local MoveWithPack = Bishop.alien.objectives.MoveWithPack

function Bishop.alien.fade.objectives.MoveWithPack(bot, brain, fade)
  local objective = MoveWithPack(bot, brain, fade)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.MoveWithPack)
  end

  return objective
end

local AssaultTechPoint = Bishop.alien.objectives.AssaultTechPoint

function Bishop.alien.fade.objectives.AssaultTechPoint(bot, brain, fade)
  local objective = AssaultTechPoint(bot, brain, fade)

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.AssaultTechPoint)
  end

  return objective
end

--------------------------------------------------------------------------------
-- Convert the remaining unmodded actions to Bishop priorities.
--------------------------------------------------------------------------------

local RespondToThreat =
  GetOldFadeObjective(kOldFadeObjectiveTypes.RespondToThreat)

function Bishop.alien.fade.objectives.RespondToThreat(bot, brain, fade)
  local objective = RespondToThreat(bot, brain, fade)
  objective.name = "RespondToThreat"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.RespondToThreat)
  end

  return objective
end

local Pheromone = GetOldFadeObjective(kOldFadeObjectiveTypes.Pheromone)

function Bishop.alien.fade.objectives.Pheromone(bot, brain, fade)
  local objective = Pheromone(bot, brain, fade)
  objective.name = "Pheromone"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.Pheromone)
  end

  return objective
end

local GoToComPing = GetOldFadeObjective(kOldFadeObjectiveTypes.GoToComPing)

function Bishop.alien.fade.objectives.GoToComPing(bot, brain, fade)
  local objective = GoToComPing(bot, brain, fade)
  objective.name = "GoToComPing"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.GoToComPing)
  end

  return objective
end

local Explore = GetOldFadeObjective(kOldFadeObjectiveTypes.Explore)

function Bishop.alien.fade.objectives.Explore(bot, brain, fade)
  local objective = Explore(bot, brain, fade)
  objective.name = "Explore"

  if objective.weight > 0 then
    objective.weight = GetObjectiveWeight(kObjectiveTypes.Explore)
  end

  return objective
end

--------------------------------------------------------------------------------
-- Setup the objectives array.
--------------------------------------------------------------------------------

kFadeBrainObjectives = {
  Bishop.alien.fade.objectives.Retreat,
  Bishop.alien.fade.objectives.RespondToThreat,
  Bishop.alien.fade.objectives.Evolve,
  Bishop.alien.fade.objectives.Pheromone,
  Bishop.alien.fade.objectives.GoToComPing,
  Bishop.alien.fade.objectives.Explore,
  Bishop.alien.fade.objectives.MoveWithPack,
  Bishop.alien.fade.objectives.AssaultTechPoint
}

--------------------------------------------------------------------------------
-- Drop in the modified PerformMove function to all objectives.
--------------------------------------------------------------------------------

for _, action in ipairs(kOldFadeObjectives) do
  Shine.SetUpValue(action, "PerformMove", Bishop.alien.fade.DoMove, true)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
