Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.alien.fade.actions = {}

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

Bishop.alien.fade.kActionTypes = enum({ -- Priority from high to low.
  "Attack",
  "Interrupt"
})

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kActionCount = #Bishop.alien.fade.kActionTypes
local kActionTypes = Bishop.alien.fade.kActionTypes
local kOldFadeActions = {}
local kOldFadeActionTypes = {}

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

function Bishop.alien.fade.GetActionWeight(action)
  local actionIndex = kActionTypes[kActionTypes[action]]
  return kActionCount - actionIndex + 1
end
local GetActionWeight = Bishop.alien.fade.GetActionWeight

local function GetOldFadeActionIndex(action)
  return kOldFadeActionTypes[kOldFadeActionTypes[action]]
end

local function GetOldFadeAction(action)
  return kOldFadeActions[GetOldFadeActionIndex(action)]
end

--------------------------------------------------------------------------------
-- Build a named enum of existing actions.
--------------------------------------------------------------------------------
-- The ordering of this array MUST match the functions in kFadeBrainActions.
-- This is used to pull the array index of a function.

kOldFadeActionTypes = enum({
  "Attack",
  "Interrupt"
})

--------------------------------------------------------------------------------
-- Make a local copy of the brain actions array.
--------------------------------------------------------------------------------
-- Without a deep copy of the array, the old functions get replaced and hooks
-- will break.

for i, v in ipairs(kFadeBrainActions) do
  kOldFadeActions[i] = v
end

--------------------------------------------------------------------------------
-- Load the Fade actions.
--------------------------------------------------------------------------------

Script.Load("lua/bishop/alien/fade/FadeActions_Attack.lua")
Script.Load("lua/bishop/alien/fade/FadeMovement.lua")

--------------------------------------------------------------------------------
-- Convert the remaining unmodded actions to Bishop priorities.
--------------------------------------------------------------------------------

local Interrupt = GetOldFadeAction(kOldFadeActionTypes.Interrupt)

function Bishop.alien.fade.actions.Interrupt(bot, brain, fade)
  local action = Interrupt(bot, brain, fade)
  action.name = "Interrupt"

  if action.weight > 0 then
    action.weight = GetActionWeight(kActionTypes.Interrupt)
  end

  return action
end

--------------------------------------------------------------------------------
-- Setup the actions array.
--------------------------------------------------------------------------------

kFadeBrainActions = {
  Bishop.alien.fade.actions.Attack,
  Bishop.alien.fade.actions.Interrupt
}

--------------------------------------------------------------------------------
-- Drop in the modified PerformMove function to all actions.
--------------------------------------------------------------------------------

for _, action in ipairs(kOldFadeActions) do
  Shine.SetUpValue(action, "PerformMove", Bishop.alien.fade.DoMove, true)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
