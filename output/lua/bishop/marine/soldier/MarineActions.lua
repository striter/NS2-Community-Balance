Script.Load("lua/BalanceMisc.lua")
Script.Load("lua/Entity.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.marine.actions = {}

local GetEntitiesWithinRange = GetEntitiesWithinRange
local GetEntity = Shared.GetEntity ---@type function
local ipairs = ipairs

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kActionTypes = enum({ -- Higher in the enum is higher priority.
  -- High priority overrides.
  "WeldExo_HIGH",
  "PickupWeapon_HIGH",
  "ReloadWeapon_OOC",
  "ReloadPistol_OOC",
  "BuildStructure_OOC",
  "MountExo_HIGH",

  -- Combat.
  "AttackLifeforms",
  "AttackBabblers",
  "AttackStructures",
  "ClearCysts",

  "ReloadWeapon",
  "ReloadPistol",

  -- Survival.
  "FindMedpack",
  "FindAmmopack",
  "PickupJetpack",
  "PickupWeapon",

  -- Support.
  "WeldExo",
  "BuildStructure",
  "Weld",
  "MountExo",

  -- Other.
  "Interrupt",
})

local kHighPriorityObjectives = {
  "FollowOrder",
  "RespondToThreat",
  "UseArmory",
  "Retreat",
  "DefendNearbyStructures",
  "RespondToThreat_LOW"
}

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

Bishop.marine.kActionTypes = kActionTypes
local kActionCount = #kActionTypes
local kBotMaintenanceLoaded = #kMarineBrainActions == 16
local kOldMarineActions = {}
local kOldMarineActionTypes = {}

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

function Bishop.marine.GetActionWeight(actionType)
  local actionIndex = kActionTypes[kActionTypes[actionType]]
  return kActionCount - actionIndex + 1
end
local GetActionWeight = Bishop.marine.GetActionWeight

local function GetOldMarineActionIndex(actionType)
  return kOldMarineActionTypes[kOldMarineActionTypes[actionType]]
end

local function GetOldMarineAction(actionType)
  return kOldMarineActions[GetOldMarineActionIndex(actionType)]
end

--------------------------------------------------------------------------------
-- Detection for Bot_Maintenance.
--------------------------------------------------------------------------------

if kBotMaintenanceLoaded then
  Bishop.Log("Compatibility with Bot_Maintenance Marine enabled.")
elseif #kMarineBrainActions ~= 13 then
  Bishop.Error("Another mod is interfering with Marine actions.")
end

--------------------------------------------------------------------------------
-- Build a named enum of existing actions.
--------------------------------------------------------------------------------
-- The ordering of this array MUST match the functions in kMarineBrainActions.
-- This is used to pull the array index of a function.

if not kBotMaintenanceLoaded then
  kOldMarineActionTypes = enum({
    "AttackLifeforms",
    "AttackStructures",
    "AttackBabblers",
    "ReloadWeapon",
    "ReloadPistol",
    "Interrupt",
    "FindMedpack",
    "FindAmmopack",
    "PickupWeapon",
    "ClearCysts",
    "BuildStructure",
    "Weld",
    "MountExo",
  })
else
  kOldMarineActionTypes = enum({
    "AttackLifeforms",
    "AttackStructures",
    "AttackBabblers",
    "ReloadWeapon",
    "ReloadPistol",
    "Interrupt",
    "FindMedpack",
    "FindAmmopack",
    "PickupMine",
    "PickupWelder",
    "PickupJetpack",
    "PickupWeapon",
    "ClearCysts",
    "BuildStructure",
    "Weld",
    "MountExo"
  })
end

--------------------------------------------------------------------------------
-- Make a local copy of the brain actions array.
--------------------------------------------------------------------------------
-- Without a deep copy of the array, the old functions get replaced and hooks
-- will break.

for i, v in ipairs(kMarineBrainActions) do
  kOldMarineActions[i] = v
end

--------------------------------------------------------------------------------
-- Load Marine actions.
--------------------------------------------------------------------------------

-- TEMP: Ensure the objectives load before the actions. This is only necessary
-- until PerformMove has been rewritten.
Script.Load("lua/bishop/marine/soldier/MarineObjectives.lua")

--------------------------------------------------------------------------------
-- Convert the remaining unmodded actions to Bishop priorities.
--------------------------------------------------------------------------------

local AttackLifeforms =
  GetOldMarineAction(kOldMarineActionTypes.AttackLifeforms)

function Bishop.marine.actions.AttackLifeforms(bot, brain, marine)
  local action = AttackLifeforms(bot, brain, marine)
  action.name = "AttackLifeforms"

  if action.weight > 0 then
    action.weight = GetActionWeight(kActionTypes.AttackLifeforms)
  end

  return action
end

local AttackStructures =
  GetOldMarineAction(kOldMarineActionTypes.AttackStructures)
local kExecClearCysts = Shine.GetUpValue(
  GetOldMarineAction(kOldMarineActionTypes.ClearCysts), "kExecClearCysts", true)

function Bishop.marine.actions.AttackStructures(bot, brain, marine)
  local action = AttackStructures(bot, brain, marine)
  action.name = "AttackStructures"

  if action.weight > 0 then
    action.weight = GetActionWeight(kActionTypes.AttackStructures)
    local target = GetEntity(action.threat.entId)

    if target and target:isa("Harvester") then
      local origin = target:GetOrigin()
      local cysts = GetEntitiesWithinRange("Cyst", origin, kInfestationRadius)

      if #cysts > 0 then
        action.name = "ClearCystsOverride"
        action.perform = kExecClearCysts
        action.cyst = { entity = cysts[1], distance = 5 }
      end
    end
  end

  return action
end

local AttackBabblers = GetOldMarineAction(kOldMarineActionTypes.AttackBabblers)

function Bishop.marine.actions.AttackBabblers(bot, brain, marine)
  local action = AttackBabblers(bot, brain, marine)
  action.name = "AttackBabblers"

  if (action.weight > 0) then
    action.weight = GetActionWeight(kActionTypes.AttackBabblers)
  end

  return action
end

local ReloadWeapon = GetOldMarineAction(kOldMarineActionTypes.ReloadWeapon)

function Bishop.marine.actions.ReloadWeapon(bot, brain, marine)
  local action = ReloadWeapon(bot, brain, marine)

  if action.weight > 0 then
    if action.weight >= 200 then
      action.name = "ReloadWeapon_OOC"
      action.weight = GetActionWeight(kActionTypes.ReloadWeapon_OOC)
    else
      action.name = "ReloadWeapon"
      action.weight = GetActionWeight(kActionTypes.ReloadWeapon)
    end
  end

  return action
end

local ReloadPistol = GetOldMarineAction(kOldMarineActionTypes.ReloadPistol)

function Bishop.marine.actions.ReloadPistol(bot, brain, marine)
  local action = ReloadPistol(bot, brain, marine)

  if action.weight > 0 then
    if action.weight >= 200 then
      action.name = "ReloadPistol_OOC"
      action.weight = GetActionWeight(kActionTypes.ReloadPistol_OOC)
    else
      action.name = "ReloadPistol"
      action.weight = GetActionWeight(kActionTypes.ReloadPistol)
    end
  end

  return action
end

local Interrupt = GetOldMarineAction(kOldMarineActionTypes.Interrupt)

function Bishop.marine.actions.Interrupt(bot, brain, marine)
  local action = Interrupt(bot, brain, marine)
  action.name = "Interrupt"

  if (action.weight > 0) then
    action.weight = GetActionWeight(kActionTypes.Interrupt)
  end

  return action
end

local FindMedpack = GetOldMarineAction(kOldMarineActionTypes.FindMedpack)

function Bishop.marine.actions.FindMedpack(bot, brain, marine)
  local action = FindMedpack(bot, brain, marine)
  action.name = "FindMedpack"

  if (action.weight > 0) then
    action.weight = GetActionWeight(kActionTypes.FindMedpack)
  end

  return action
end

local FindAmmopack = GetOldMarineAction(kOldMarineActionTypes.FindAmmopack)

function Bishop.marine.actions.FindAmmopack(bot, brain, marine)
  local action = FindAmmopack(bot, brain, marine)
  action.name = "FindAmmopack"

  if (action.weight > 0) then
    action.weight = GetActionWeight(kActionTypes.FindAmmopack)
  end

  return action
end

local PickupWeapon = GetOldMarineAction(kOldMarineActionTypes.PickupWeapon)

function Bishop.marine.actions.PickupWeapon(bot, brain, marine)
  local action = PickupWeapon(bot, brain, marine)

  if action.weight > 0 then
    if action.weight >= 200 then
      action.name = "PickupWeapon_HIGH"
      action.weight = GetActionWeight(kActionTypes.PickupWeapon_HIGH)
    else
      action.name = "PickupWeapon"
      action.weight = GetActionWeight(kActionTypes.PickupWeapon)
    end
  end

  return action
end

local ClearCysts = GetOldMarineAction(kOldMarineActionTypes.ClearCysts)

function Bishop.marine.actions.ClearCysts(bot, brain, marine)
  local action = ClearCysts(bot, brain, marine)
  action.name = "ClearCysts"

  if (action.weight > 0) then
    action.weight = GetActionWeight(kActionTypes.ClearCysts)
  end

  return action
end

local BuildStructure = GetOldMarineAction(kOldMarineActionTypes.BuildStructure)

function Bishop.marine.actions.BuildStructure(bot, brain, marine)
  local action = BuildStructure(bot, brain, marine)

  if action.weight > 0 then
    if action.weight >= 200 then
      action.name = "BuildStructure_OOC"
      action.weight = GetActionWeight(kActionTypes.BuildStructure_OOC)
    else
      action.name = "BuildStructure"
      action.weight = GetActionWeight(kActionTypes.BuildStructure)
    end
  end

  return action
end

local Weld = GetOldMarineAction(kOldMarineActionTypes.Weld)
local kExecAttackStructures = Shine.GetUpValue(AttackStructures,
  "kExecAttackStructures", true)

function Bishop.marine.actions.Weld(bot, brain, marine)
  local action = Weld(bot, brain, marine)

  if action.weight > 0 then
    -- When the target is an Exo (occupied or empty) the action weight is
    -- multiplied by 2. From there, an occupied Exo is either increased by 300
    -- if the bot has a bad weapon, or set to 0 if another bot is already
    -- welding it. The +200 option is not logically possible on its own, which
    -- leaves only 3 total options: "Weld", "WeldExo" and "WeldExo_HIGH"
    -- respectively.
    -- TODO: Ideally this could later be split into completely separate actions
    -- to simplify the logic.
    if not kBotMaintenanceLoaded then
      -- Quick fix for marines welding targets at full health.
      if not action.weldTarget
          or action.weldTarget:GetArmorScalar() > 0.9999 then
        action.weight = 0
      elseif action.weight >= 200 then
        action.name = "WeldExo_HIGH"
        action.weight = GetActionWeight(kActionTypes.WeldExo_HIGH)
      elseif action.weight >= 30 then
        action.name = "WeldExo"
        action.weight = GetActionWeight(kActionTypes.WeldExo)
      else
        action.name = "Weld"
        action.weight = GetActionWeight(kActionTypes.Weld)
      end
    else
      -- Adjust default weight but allow Bot_Maintenance scaling.
      action.name = "Weld"
      if action.weight == 2 then
        action.weight = GetActionWeight(kActionTypes.Weld)
      end
    end

    if action.weldTarget and not action.weldTarget:isa("Player") then
      local origin = action.weldTarget:GetOrigin()
      local cysts = GetEntitiesWithinRange("Cyst", origin, kInfestationRadius)
      local targets = GetEntitiesWithinRange("TunnelEntrance", origin,
        kInfestationRadius)
      table.addtable(GetEntitiesWithinRange("Hydra", origin, Hydra.kRange),
        targets)

      if #cysts > 0 then
        action.name = "ClearCystsOverride"
        action.perform = kExecClearCysts
        action.cyst = { entity = cysts[1], distance = 5 }
      elseif #targets > 0 then
        local memory = brain.teamBrain:GetMemoryOfEntity(targets[1]:GetId())

        -- Only swap the action if the team knows about the target, otherwise
        -- this would be a cheat.
        if memory then
          action.name = "AttackStructuresOverride"
          action.perform = kExecAttackStructures
          action.threat = memory
        end
      end
    end
  end

  return action
end

local MountExo = GetOldMarineAction(kOldMarineActionTypes.MountExo)

function Bishop.marine.actions.MountExo(bot, brain, marine)
  local action = MountExo(bot, brain, marine)

  if action.weight > 0 then
    if action.weight >= 200 then
      action.name = "MountExo_HIGH"
      action.weight = GetActionWeight(kActionTypes.MountExo_HIGH)
    else
      action.name = "MountExo"
      action.weight = GetActionWeight(kActionTypes.MountExo)
    end
  end

  return action
end

if kBotMaintenanceLoaded then
  local PickupJetpack = GetOldMarineAction(kOldMarineActionTypes.PickupJetpack)

  function Bishop.marine.actions.PickupJetpack(bot, brain, marine)
    local action = PickupJetpack(bot, brain, marine)
    action.name = "PickupJetpack"

    if action.weight > 0 then
      action.weight = GetActionWeight(kActionTypes.PickupJetpack)
    end

    return action
  end

  local PickupMine = GetOldMarineAction(kOldMarineActionTypes.PickupMine)

  function Bishop.marine.actions.PickupMine(bot, brain, marine)
    local action = PickupMine(bot, brain, marine)
    action.name = "PickupMine"

    if action.weight > 0 then
      action.weight = GetActionWeight(kActionTypes.PickupWeapon)
    end

    return action
  end

  local PickupWelder = GetOldMarineAction(kOldMarineActionTypes.PickupWelder)

  function Bishop.marine.actions.PickupWelder(bot, brain, marine)
    local action = PickupWelder(bot, brain, marine)
    action.name = "PickupWelder"

    if action.weight > 0 then
      action.weight = GetActionWeight(kActionTypes.PickupWeapon)
    end

    return action
  end
end

--------------------------------------------------------------------------------
-- Setup the actions array.
--------------------------------------------------------------------------------

if not kBotMaintenanceLoaded then
  kMarineBrainActions = {
    Bishop.marine.actions.AttackLifeforms,
    Bishop.marine.actions.AttackStructures,
    Bishop.marine.actions.AttackBabblers,
    Bishop.marine.actions.ReloadWeapon,
    Bishop.marine.actions.ReloadPistol,
    Bishop.marine.actions.Interrupt,
    Bishop.marine.actions.FindMedpack,
    Bishop.marine.actions.FindAmmopack,
    Bishop.marine.actions.PickupWeapon,
    Bishop.marine.actions.ClearCysts,
    Bishop.marine.actions.BuildStructure,
    Bishop.marine.actions.Weld,
    Bishop.marine.actions.MountExo
  }
else
  kMarineBrainActions = {
    Bishop.marine.actions.AttackLifeforms,
    Bishop.marine.actions.AttackStructures,
    Bishop.marine.actions.AttackBabblers,
    Bishop.marine.actions.ReloadWeapon,
    Bishop.marine.actions.ReloadPistol,
    Bishop.marine.actions.Interrupt,
    Bishop.marine.actions.FindMedpack,
    Bishop.marine.actions.FindAmmopack,
    Bishop.marine.actions.PickupWeapon,
    Bishop.marine.actions.ClearCysts,
    Bishop.marine.actions.BuildStructure,
    Bishop.marine.actions.Weld,
    Bishop.marine.actions.MountExo,
    Bishop.marine.actions.PickupJetpack,
    Bishop.marine.actions.PickupMine,
    Bishop.marine.actions.PickupWelder
  }
end

--------------------------------------------------------------------------------
-- Redefine what it means to be high priority.
--------------------------------------------------------------------------------
-- Marines would ignore construction and cysts when on a "high priority task."
-- With the inclusion of defend waypoints this resulted in incorrect behaviour.

-- Returns false if the marine has a defend or weld order, or the current
-- objective is not in kHighPriorityObjectives. Returns true otherwise.
local function HasHighPriorityTask(bot, brain)
  local orderType = bot:GetPlayerOrder() and bot:GetPlayerOrder():GetType()
  if orderType == kTechId.Defend or orderType == kTechId.Weld then
    return false
  end

  if brain.goalAction
      and table.contains(kHighPriorityObjectives, brain.goalAction.name) then
    return true
  end
  return false
end

for _, action in ipairs(kMarineBrainActions) do
  Shine.SetUpValue(action, "HasHighPriorityTask", HasHighPriorityTask, true)
end

--------------------------------------------------------------------------------
-- Fix for dodgy building actions. (Prototype Lab, Sentries.)
--------------------------------------------------------------------------------

local PerformMove = Shine.GetUpValue(BuildStructure, "PerformMove", true)
local PerformMoveToUsePosition = Shine.GetUpValue(BuildStructure,
  "PerformMoveToUsePosition", true)

local function PerformUse(marine, target, bot, brain, move)
  local position = target:GetEngagementPoint()
  local distance = GetDistanceToTouch(marine, target)
  local lineOfSight = distance < 5 and bot:GetBotCanSeeTarget(target)
  local adjustment =
    target:isa("Sentry") and Vector(0, -0.3, 0)
    or target:isa("Observatory") and Vector(0, 0, 0)
    or Vector(0, 0.2, 0)

  if lineOfSight and math.random() < 0.01 then
    -- Swap with hugging movement, get as close as possible.
    PerformMove(marine:GetOrigin(), target:GetOrigin(), bot, brain, move, true,
      false)
  elseif distance < (target.GetUseMaxRange and target:GetUseMaxRange() or
      kPlayerUseRange) then
    -- Enagement point shifted up, bots look too far down.
    bot:GetMotion():SetDesiredViewTarget(position + adjustment)
    bot:GetMotion():SetDesiredMoveTarget()
    move.commands = AddMoveCommand(move.commands, Move.Use)
  else
    PerformMoveToUsePosition(marine, target, bot, brain, move)
  end
end

Shine.SetUpValue(BuildStructure, "PerformUse", PerformUse, true)

--------------------------------------------------------------------------------
-- Drop in the modified PerformMove function to all actions.
--------------------------------------------------------------------------------

for _, action in ipairs(kMarineBrainActions) do
  Shine.SetUpValue(action, "PerformMove", Bishop.marine.DoMove, true)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
