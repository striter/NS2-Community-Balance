Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.marine.exo.actions = {}

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

Bishop.marine.exo.kActionTypes = enum({ -- Priority from high to low.
  "Attack",
  "ClearCysts",
  "Interrupt"
})

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kActionCount = #Bishop.marine.exo.kActionTypes
local kActionTypes = Bishop.marine.exo.kActionTypes
local kOldExoActions = {}
local kOldExoActionTypes = {}

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

function Bishop.marine.exo.GetActionWeight(action)
  local actionIndex = kActionTypes[kActionTypes[action]]
  return kActionCount - actionIndex + 1
end
local GetActionWeight = Bishop.marine.exo.GetActionWeight

local function GetOldExoActionIndex(action)
  return kOldExoActionTypes[kOldExoActionTypes[action]]
end

local function GetOldExoAction(action)
  return kOldExoActions[GetOldExoActionIndex(action)]
end

--------------------------------------------------------------------------------
-- Build a named enum of existing actions.
--------------------------------------------------------------------------------
-- The ordering of this array MUST match the functions in kExoBrainActions. This
-- is used to pull the array index of a function.

kOldExoActionTypes = enum({
  "Attack",
  "ClearCysts",
  "Interrupt"
})

--------------------------------------------------------------------------------
-- Make a local copy of the brain actions array.
--------------------------------------------------------------------------------
-- Without a deep copy of the array, the old functions get replaced and hooks
-- will break.

for i, v in ipairs(kExoBrainActions) do
  kOldExoActions[i] = v
end

--------------------------------------------------------------------------------
-- Load the Exo actions.
--------------------------------------------------------------------------------

-- TEMP: Ensure the objectives load before the actions. This is only necessary
-- until PerformMove has been rewritten.
Script.Load("lua/bishop/marine/exo/ExoObjectives.lua")

-- TODO

--------------------------------------------------------------------------------
-- Convert the remaining unmodded actions to Bishop priorities.
--------------------------------------------------------------------------------

local Attack = GetOldExoAction(kOldExoActionTypes.Attack)

function Bishop.marine.exo.actions.Attack(bot, brain, exo)
  local action = Attack(bot, brain, exo)
  action.name = "Attack"

  if action.weight > 0 then
    action.weight = GetActionWeight(kActionTypes.Attack)
  end

  return action
end

local ClearCysts = GetOldExoAction(kOldExoActionTypes.ClearCysts)

function Bishop.marine.exo.actions.ClearCysts(bot, brain, exo)
  local action = ClearCysts(bot, brain, exo)
  action.name = "ClearCysts"

  if action.weight > 0 then
    action.weight = GetActionWeight(kActionTypes.ClearCysts)
  end

  return action
end

local Interrupt = GetOldExoAction(kOldExoActionTypes.Interrupt)

function Bishop.marine.exo.actions.Interrupt(bot, brain, exo)
  local action = Interrupt(bot, brain, exo)
  action.name = "Interrupt"

  if action.weight > 0 then
    action.weight = GetActionWeight(kActionTypes.Interrupt)
  end

  return action
end

--------------------------------------------------------------------------------
-- Setup the actions array.
--------------------------------------------------------------------------------

kExoBrainActions = {
  Bishop.marine.exo.actions.Attack,
  Bishop.marine.exo.actions.ClearCysts,
  Bishop.marine.exo.actions.Interrupt
}

--------------------------------------------------------------------------------
-- Drop in the modified PerformMove function to all actions.
--------------------------------------------------------------------------------

for _, action in ipairs(kExoBrainActions) do
  Shine.SetUpValue(action, "PerformMove", Bishop.marine.exo.DoMove, true)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
