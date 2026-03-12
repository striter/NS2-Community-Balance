Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.alien.gorge.actions = {}

local actions = Bishop.alien.gorge.actions

--------------------------------------------------------------------------------
-- Detection for Bot_Maintenance.
--------------------------------------------------------------------------------

local kBotMaintenanceLoaded = #kGorgeBrainActions == 11

if kBotMaintenanceLoaded then
  Bishop.Log("Compatibility with Bot_Maintenance Gorge enabled.")
elseif #kGorgeBrainActions ~= 9 then
  Bishop.Error("Another mod is interfering with Gorge actions.")
end

--------------------------------------------------------------------------------
-- Build a named enum of existing actions.
--------------------------------------------------------------------------------
-- The ordering of this array MUST match the functions in kGorgeBrainActions.
-- This is used to pull the array index of a function.

local kOldGorgeActionTypes

if not kBotMaintenanceLoaded then
  kOldGorgeActionTypes = enum({
    "Explore",
    "Evolve",
    "Attack",
    "Bombard",
    "Heal",
    "Pheromone",
    "Order",
    "Retreat",
    "Build"
  })
else
  kOldGorgeActionTypes = enum({
    "Explore",
    "Evolve",
    "Attack",
    "Bombard",
    "Heal",
    "Pheromone",
    "Order",
    "Retreat",
    "HealHive",
    "HealBuilding",
    "Build"
  })
end

local function GetOldGorgeActionIndex(action)
  return kOldGorgeActionTypes[kOldGorgeActionTypes[action]]
end

--------------------------------------------------------------------------------
-- Make a local copy of the brain actions array.
--------------------------------------------------------------------------------
-- Without a deep copy of the array, the old functions get replaced and hooks
-- will break.

local kOldGorgeActions = {}

for i, v in ipairs(kGorgeBrainActions) do
  kOldGorgeActions[i] = v
end

local function GetOldGorgeAction(action)
  return kOldGorgeActions[GetOldGorgeActionIndex(action)]
end

--------------------------------------------------------------------------------
-- TEMP: Extract PerformMove for use elsewhere.
--------------------------------------------------------------------------------

Bishop.alien.gorge.PerformMove = Shine.GetUpValue(
  GetOldGorgeAction(kOldGorgeActionTypes.Explore), "PerformMove", true)
assert(Bishop.alien.gorge.PerformMove)
-- This will fall down below if PerformMove is ever rewritten.
Script.Load("lua/bishop/alien/gorge/GorgeMovement.lua")

--------------------------------------------------------------------------------
-- Load the Gorge actions.
--------------------------------------------------------------------------------

Script.Load("lua/bishop/alien/AlienObjectives_Evolve.lua")
Script.Load("lua/bishop/alien/gorge/GorgeActions_BileMine.lua")
Script.Load("lua/bishop/alien/gorge/GorgeActions_Hydra.lua")
Script.Load("lua/bishop/alien/gorge/GorgeActions_Retreat.lua")
Script.Load("lua/bishop/alien/gorge/GorgeActions_Web.lua")

--------------------------------------------------------------------------------
-- Ensure shared objectives have the correct weights for Gorge.
--------------------------------------------------------------------------------

local Evolve = Bishop.alien.objectives.Evolve

function actions.Evolve(bot, brain, gorge)
  local objective = Evolve(bot, brain, gorge)

  if objective.weight > 0 then
    objective.weight = 10
  end

  return objective
end

--------------------------------------------------------------------------------
-- Adjust Gorge action weights.
--------------------------------------------------------------------------------

local Attack = GetOldGorgeAction(kOldGorgeActionTypes.Attack)

function actions.Attack(bot, brain, gorge)
  local action = Attack(bot, brain, gorge)
  action.name = "Attack"

  action.weight = action.weight * 1.5;

  return action
end

local Bombard = GetOldGorgeAction(kOldGorgeActionTypes.Bombard)

function actions.Bombard(bot, brain, gorge)
  local action = Bombard(bot, brain, gorge)
  action.name = "Bombard"

  action.weight = action.weight * 1.5;

  return action
end

local Heal = GetOldGorgeAction(kOldGorgeActionTypes.Heal)

function actions.Heal(bot, brain, gorge)
  local action = Heal(bot, brain, gorge)
  
  -- Quick fix for Gorges stuck healing a target at 99.9% health.
  local healTarget = action.healTarget
  if not healTarget
      or healTarget:GetHealthScalar() > 0.998
      or healTarget:isa("Cyst")
      or healTarget:isa("Web")
      or (not healTarget:isa("Player") and gorge:GetIsUnderFire()) then
    action.weight = 0
  end

  return action
end

if kBotMaintenanceLoaded then
  local HealBuilding = GetOldGorgeAction(kOldGorgeActionTypes.HealBuilding)

  function actions.HealBuilding(bot, brain, gorge)
    local action = HealBuilding(bot, brain, gorge)
    
    -- Quick fix for Gorges stuck healing a target at 99.9% health.
    local structure = action.structure
    if not structure or structure:GetHealthScalar() > 0.998
        or structure:isa("Cyst")
        or structure:isa("Web")
        or gorge:GetIsUnderFire() then
      action.weight = 0
    end

    return action
  end
end

--------------------------------------------------------------------------------
-- Setup the actions array.
--------------------------------------------------------------------------------

if not kBotMaintenanceLoaded then
  kGorgeBrainActions = {
    GetOldGorgeAction(kOldGorgeActionTypes.Explore),
    actions.Evolve,
    actions.Attack,
    actions.Bombard,
    actions.Heal,
    GetOldGorgeAction(kOldGorgeActionTypes.Pheromone),
    GetOldGorgeAction(kOldGorgeActionTypes.Order),
    GetOldGorgeAction(kOldGorgeActionTypes.Build),
    actions.BuildHydra,
    actions.PanicHydra,
    actions.BuildBileMine,
    actions.BuildWeb,
    Bishop.alien.gorge.actions.Retreat
  }
else
  kGorgeBrainActions = {
    GetOldGorgeAction(kOldGorgeActionTypes.Explore),
    actions.Evolve,
    actions.Attack,
    actions.Bombard,
    actions.Heal,
    GetOldGorgeAction(kOldGorgeActionTypes.Pheromone),
    GetOldGorgeAction(kOldGorgeActionTypes.Order),
    GetOldGorgeAction(kOldGorgeActionTypes.HealHive),
    actions.HealBuilding,
    GetOldGorgeAction(kOldGorgeActionTypes.Build),
    actions.BuildHydra,
    actions.PanicHydra,
    actions.BuildBileMine,
    actions.BuildWeb,
    Bishop.alien.gorge.actions.Retreat
  }
end

--------------------------------------------------------------------------------
-- Drop in the modified PerformMove function to all actions.
--------------------------------------------------------------------------------

for _, action in ipairs(kOldGorgeActions) do
  Shine.SetUpValue(action, "PerformMove", Bishop.alien.gorge.DoMove, true)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
