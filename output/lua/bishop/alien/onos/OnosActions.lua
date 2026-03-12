Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.alien.onos.actions = {}

local actions = Bishop.alien.onos.actions

--------------------------------------------------------------------------------
-- Action priorities.
--------------------------------------------------------------------------------
-- Higher in the enum is higher priority.

local actionTypes = enum({
  "Attack",
  "DestroyExosuit"
})

Bishop.alien.onos.actionTypes = actionTypes
local kActionCount = #actionTypes

local function GetActionWeight(action)
  local actionIndex = actionTypes[actionTypes[action]]

  return kActionCount - actionIndex + 1
end

Bishop.alien.onos.GetActionWeight = GetActionWeight

--------------------------------------------------------------------------------
-- Detection for Bot_Maintenance.
--------------------------------------------------------------------------------

local kBotMaintenanceLoaded = #kOnosBrainActions == 2

if kBotMaintenanceLoaded then
  Bishop.Log("Compatibility with Bot_Maintenance Onos enabled.")
elseif #kOnosBrainActions ~= 1 then
  Bishop.Error("Another mod is interfering with Onos actions.")
end

--------------------------------------------------------------------------------
-- Build a named enum of existing actions.
--------------------------------------------------------------------------------
-- The ordering of this array MUST match the functions in kOnosBrainActions.
-- This is used to pull the array index of a function.

local kOldOnosActionTypes

if not kBotMaintenanceLoaded then
  kOldOnosActionTypes = enum({
    "Attack",
  })
else
  kOldOnosActionTypes = enum({
    "DestroyExosuit",
    "Attack"
  })
end

local function GetOldOnosActionIndex(action)
  return kOldOnosActionTypes[kOldOnosActionTypes[action]]
end

--------------------------------------------------------------------------------
-- Make a local copy of the brain actions array.
--------------------------------------------------------------------------------
-- Without a deep copy of the array, the old functions get replaced and hooks
-- will break.

local kOldOnosActions = {}

for i, v in ipairs(kOnosBrainActions) do
  kOldOnosActions[i] = v
end

local function GetOldOnosAction(action)
  return kOldOnosActions[GetOldOnosActionIndex(action)]
end

--------------------------------------------------------------------------------
-- TEMP: Get the kExecAttackAction from vanilla for use with Attack.
--------------------------------------------------------------------------------

actions.kExecAttackAction = Shine.GetUpValue(
  GetOldOnosAction(kOldOnosActionTypes.Attack), "kExecAttackAction", true)
assert(actions.kExecAttackAction)
actions.GetAttackUrgency = Shine.GetUpValue(
  GetOldOnosAction(kOldOnosActionTypes.Attack), "GetAttackUrgency", true)

--------------------------------------------------------------------------------
-- Load the Onos actions.
--------------------------------------------------------------------------------

-- TEMP: Ensure the objectives load before the actions. This is only necessary
-- until PerformMove has been rewritten.
Script.Load("lua/bishop/alien/onos/OnosObjectives.lua")

Script.Load("lua/bishop/alien/onos/OnosActions_Attack.lua")

--------------------------------------------------------------------------------
-- Convert the remaining unmodded actions to Bishop priorities.
--------------------------------------------------------------------------------

local DestroyExosuit

if kBotMaintenanceLoaded then
  DestroyExosuit = GetOldOnosAction(kOldOnosActionTypes.DestroyExosuit)

  function actions.DestroyExosuit(bot, brain, onos)
    local action = DestroyExosuit(bot, brain, onos)
    action.name = "DestroyExosuit"

    if (action.weight > 0) then
      action.weight = GetActionWeight(actionTypes.DestroyExosuit)
    end

    return action
  end
end

--------------------------------------------------------------------------------
-- Setup the actions array.
--------------------------------------------------------------------------------

if not kBotMaintenanceLoaded then
  kOnosBrainActions = {
    actions.Attack
  }
else
  kOnosBrainActions = {
    actions.Attack,
    actions.DestroyExosuit
  }
end

--------------------------------------------------------------------------------
-- Drop in the modified PerformMove function to all actions.
--------------------------------------------------------------------------------

for _, action in ipairs(kOldOnosActions) do
  Shine.SetUpValue(action, "PerformMove", Bishop.alien.onos.DoMove, true)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
