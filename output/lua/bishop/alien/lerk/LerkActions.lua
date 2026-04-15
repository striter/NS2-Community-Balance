Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.alien.lerk.actions = {}

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

Bishop.alien.lerk.kActionTypes = enum({ -- Priority from high to low.
  "RecoverEnergy",
  "Umbra",
  "Spore",
  "Attack",
  "Interrupt"
})

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kActionCount = #Bishop.alien.lerk.kActionTypes
local kActionTypes = Bishop.alien.lerk.kActionTypes
local kOldLerkActions = {}
local kOldLerkActionTypes = {}

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

function Bishop.alien.lerk.GetActionWeight(action)
  local actionIndex = kActionTypes[kActionTypes[action]]
  return kActionCount - actionIndex + 1
end
local GetActionWeight = Bishop.alien.lerk.GetActionWeight

local function GetOldLerkActionIndex(action)
  return kOldLerkActionTypes[kOldLerkActionTypes[action]]
end

local function GetOldLerkAction(action)
  return kOldLerkActions[GetOldLerkActionIndex(action)]
end

--------------------------------------------------------------------------------
-- Build a named enum of existing actions.
--------------------------------------------------------------------------------
-- The ordering of this array MUST match the functions in kLerkBrainActions.
-- This is used to pull the array index of a function.

kOldLerkActionTypes = enum({
  "Umbra",
  "Spore",
  "Attack",
  "Interrupt"
})

--------------------------------------------------------------------------------
-- Make a local copy of the brain actions array.
--------------------------------------------------------------------------------
-- Without a deep copy of the array, the old functions get replaced and hooks
-- will break.

for i, v in ipairs(kLerkBrainActions) do
  kOldLerkActions[i] = v
end

--------------------------------------------------------------------------------
-- TEMP: Get the PerformSporeHostiles from vanilla for use with Attack.
--------------------------------------------------------------------------------

Bishop.alien.lerk.PerformSporeHostiles = Shine.GetUpValue(
  GetOldLerkAction(kOldLerkActionTypes.Spore), "PerformSporeHostiles", true)
assert(Bishop.alien.lerk.PerformSporeHostiles)

--------------------------------------------------------------------------------
-- Load the Lerk actions.
--------------------------------------------------------------------------------

Script.Load("lua/bishop/alien/lerk/LerkActions_Attack.lua")
Script.Load("lua/bishop/alien/lerk/LerkMovement.lua")

--------------------------------------------------------------------------------
-- Convert the remaining unmodded actions to Bishop priorities.
--------------------------------------------------------------------------------

local Interrupt = GetOldLerkAction(kOldLerkActionTypes.Interrupt)

function Bishop.alien.lerk.actions.Interrupt(bot, brain, lerk)
  local action = Interrupt(bot, brain, lerk)
  action.name = "Interrupt"

  if action.weight > 0 then
    action.weight = GetActionWeight(kActionTypes.Interrupt)
  end

  return action
end

local Umbra = GetOldLerkAction(kOldLerkActionTypes.Umbra)

function Bishop.alien.lerk.actions.Umbra(bot, brain, lerk)
  local action = Umbra(bot, brain, lerk)
  action.name = "Umbra"

  if action.weight > 0 then
    action.weight = GetActionWeight(kActionTypes.Umbra)
  end

  return action
end

--------------------------------------------------------------------------------
-- Setup the actions array.
--------------------------------------------------------------------------------

kLerkBrainActions = {
  Bishop.alien.lerk.actions.RecoverEnergy,
  Bishop.alien.lerk.actions.Umbra,
  Bishop.alien.lerk.actions.Spore,
  Bishop.alien.lerk.actions.Attack,
  Bishop.alien.lerk.actions.Interrupt
}

--------------------------------------------------------------------------------
-- Drop in the modified PerformMove function to all actions.
--------------------------------------------------------------------------------

for _, action in ipairs(kOldLerkActions) do
  Shine.SetUpValue(action, "PerformMove", Bishop.alien.lerk.DoMove, true)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
