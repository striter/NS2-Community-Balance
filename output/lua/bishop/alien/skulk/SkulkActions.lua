Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.alien.skulk.actions = {}

local actions = Bishop.alien.skulk.actions

--------------------------------------------------------------------------------
-- Action priorities.
--------------------------------------------------------------------------------
-- Higher in the enum is higher priority.

local actionTypes = enum({
  -- We attack attack attack attack.
  "Attack",
  "DestroyExosuit",
  "Interrupt"
})

Bishop.alien.skulk.actionTypes = actionTypes
local kActionCount = #actionTypes

local function GetActionWeight(action)
  local actionIndex = actionTypes[actionTypes[action]]

  return kActionCount - actionIndex + 1
end

Bishop.alien.skulk.GetActionWeight = GetActionWeight

--------------------------------------------------------------------------------
-- Detection for Bot_Maintenance.
--------------------------------------------------------------------------------

local kBotMaintenanceLoaded = #kSkulkBrainActions == 3

if kBotMaintenanceLoaded then
  Bishop.Log("Compatibility with Bot_Maintenance Skulk enabled.")
elseif #kSkulkBrainActions ~= 2 then
  Bishop.Error("Another mod is interfering with Skulk actions.")
end

--------------------------------------------------------------------------------
-- Build a named enum of existing actions.
--------------------------------------------------------------------------------
-- The ordering of this array MUST match the functions in kSkulkBrainActions.
-- This is used to pull the array index of a function.

local kOldSkulkActionTypes

if not kBotMaintenanceLoaded then
  kOldSkulkActionTypes = enum({
    "Attack",
    "Interrupt"
  })
else
  kOldSkulkActionTypes = enum({
    "DestroyExosuit",
    "Attack",
    "Interrupt"
  })
end

local function GetOldSkulkActionIndex(action)
  return kOldSkulkActionTypes[kOldSkulkActionTypes[action]]
end

--------------------------------------------------------------------------------
-- Make a local copy of the brain actions array.
--------------------------------------------------------------------------------
-- Without a deep copy of the array, the old functions get replaced and hooks
-- will break.

local kOldSkulkActions = {}

for i, v in ipairs(kSkulkBrainActions) do
  kOldSkulkActions[i] = v
end

local function GetOldSkulkAction(action)
  return kOldSkulkActions[GetOldSkulkActionIndex(action)]
end

--------------------------------------------------------------------------------
-- Load the Skulk actions.
--------------------------------------------------------------------------------

Script.Load("lua/bishop/alien/AlienActions_Attack.lua")
Script.Load("lua/bishop/alien/skulk/SkulkActions_Attack.lua")
Script.Load("lua/bishop/alien/skulk/SkulkMovement.lua")

--------------------------------------------------------------------------------
-- Convert the remaining unmodded actions to Bishop priorities.
--------------------------------------------------------------------------------

local Interrupt = GetOldSkulkAction(kOldSkulkActionTypes.Interrupt)

function actions.Interrupt(bot, brain, skulk)
  local action = Interrupt(bot, brain, skulk)
  action.name = "Interrupt"

  if (action.weight > 0) then
    action.weight = GetActionWeight(actionTypes.Interrupt)
  end

  return action
end

local Attack = GetOldSkulkAction(kOldSkulkActionTypes.Attack)
Bishop.utility.SetPerformAttackFunction(kTechId.Skulk, Shine.GetUpValue(Attack,
  "kExecAttackAction", true))
Shine.SetUpValue(Attack, "GetAttackUrgency", actions.GetAttackUrgency, true)

local execAttack = Shine.GetUpValue(Attack, "kExecAttackAction", true)
local DoMove = Bishop.alien.skulk.DoMove

-- TODO: Temporary wrapper until adequate Skulk LoS checks are done on attack.
local function AttackWrapper(move, bot, brain, skulk, action)
  -- The attack action overrides movement when the target is very close, without
  -- calling DoMove. This behaviour breaks vent logic in some cases.
  if bot.ventPath and bot.ventPath.active and not brain.hasMoved then
    DoMove(skulk:GetOrigin(), action.bestMem.lastSeenPos, bot, brain, move)
    brain.hasMoved = true
  end

  execAttack(move, bot, brain, skulk, action)
end

Shine.SetUpValue(Attack, "kExecAttackAction", AttackWrapper, true)

--Bishop.utility.SetPerformAttackFunction(kTechId.Skulk,
--  Bishop.alien.skulk.PerformAttack2)
--local Attack = Bishop.alien.actions.Attack

function actions.Attack(bot, brain, skulk)
  local action = Attack(bot, brain, skulk)
  action.name = "Attack"

  if action.weight > 0 then
    action.weight = GetActionWeight(actionTypes.Attack)
  end

  return action
end

local DestroyExosuit

if kBotMaintenanceLoaded then
  DestroyExosuit = GetOldSkulkAction(kOldSkulkActionTypes.DestroyExosuit)

  function actions.DestroyExosuit(bot, brain, skulk)
    local action = DestroyExosuit(bot, brain, skulk)
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
  kSkulkBrainActions = {
    actions.Interrupt,
    actions.Attack
  }
else
  kSkulkBrainActions = {
    actions.Interrupt,
    actions.Attack,
    actions.DestroyExosuit
  }
end

--------------------------------------------------------------------------------
-- Drop in the modified PerformMove function to all actions.
--------------------------------------------------------------------------------

for _, action in ipairs(kOldSkulkActions) do
  Shine.SetUpValue(action, "PerformMove", Bishop.alien.skulk.DoMove, true)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
