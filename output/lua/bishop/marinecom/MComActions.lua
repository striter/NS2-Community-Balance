Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local ipairs = ipairs
local Shared_GetTime = Shared.GetTime

Bishop.marineCom.actions = {}

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

Bishop.marineCom.kActionTypes = enum({ -- Priority from high to low.
  "ItsGameOverMan",

  -- Emergency actions.
  "EmergencyBeacon",
  "EmergencyRecycleGhost",
  "EmergencyPowerSurgePhaseGate",

  -- Marine support.
  "SupportMedPack",
  "SupportPreemptiveMedPack",
  "SupportAmmoPack",
  "SupportSpecialPack",

  -- Research and main base construction.
  "BuildTechPointInfantryPortal", -- Emergency if IPs are low early game.
  "BuildInfantryPortal",
  "Research",
  "BuildExtractor",

  -- Hive assault.
  "ScanHive",
  "BuildOffensivePhaseGate",
  "BuildOffensiveArmory",
  "RecycleOffensivePhaseGate",
  "ReverseOffensivePhaseGate",

  -- Secondary base construction.
  "BuildTechPointPhaseGate",
  "BuildTechPointArmory",
  "BuildTechPointCommandStation",
  "BuildTechPointObservatory",

  "BuildSentry",
  "BuildSentryBattery",
  "RecycleSentries",

  -- Low priority and excessive resources.
  "DropWeapon",
  "DropJetpack",
  "DropMines",
  "DropWelder",

  -- Other.
  "Scan",
  "ScanTunnel",
  "ScanShade",
  "BuildMAC",
  "BuildARC",
  "AttackOrder",
  "GiveOrder",

  -- Geddafuckouttahere.
  "Idle"
})

local kTimeBetweenMoveOrders = 20 -- Delay between Bot_Maintenance move orders.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kActionCount = #Bishop.marineCom.kActionTypes
local kActionTypes = Bishop.marineCom.kActionTypes
local kBotMaintenanceLoaded = #kMarineComBrainActions == 30
local kOldComActions = {}
local kOldComActionTypes = {}
local kNilAction = Bishop.lib.constants.kNilAction

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

function Bishop.marineCom.GetActionWeight(actionType)
  local actionIndex = kActionTypes[kActionTypes[actionType]]
  return kActionCount - actionIndex + 1
end
local GetActionWeight = Bishop.marineCom.GetActionWeight

local function GetOldComActionIndex(actionType)
  return kOldComActionTypes[kOldComActionTypes[actionType]]
end

local function GetOldComAction(actionType)
  return kOldComActions[GetOldComActionIndex(actionType)]
end

--------------------------------------------------------------------------------
-- Detection for Bot_Maintenance.
--------------------------------------------------------------------------------

if kBotMaintenanceLoaded then
  Bishop.Log("Compatibility with Bot_Maintenance MCom enabled.")
elseif #kMarineComBrainActions ~= 18 then
  Bishop.Error("Another mod is interfering with MCom actions.")
end

--------------------------------------------------------------------------------
-- Build a named enum of existing actions.
--------------------------------------------------------------------------------
-- The ordering of this array MUST match the functions in
-- kMarineComBrainActions. This is used to pull the array index of a function.

if not kBotMaintenanceLoaded then
  kOldComActionTypes = enum({ -- Vanilla actions.
    "Nothing",
    "Recycle",
    "BuildPhaseGate",
    "BuildArmory",
    "BuildObservatory",
    "BuildInfantryPortal",
    "Research",
    "Beacon",
    "DropJetpack",
    "DropWeapon",
    "BuildExtractor",
    "Scan",
    "PowerSurge",
    "DropSupport",
    "DropPack",
    "DropSecondPack",
    "BuildAndManageMAC",
    "Idle"
  })
else
  kOldComActionTypes = enum({ -- Bot_Maintenance actions.
    "Nothing",
    "Recycle",
    "BuildCommandStation",
    "BuildPhaseGate",
    "BuildArmory",
    "BuildCommandStation2",
    "PhaseGateDouble",
    "BuildRoboticsFactory",
    "BuildObservatory",
    "BuildInfantryPortal",
    "Research",
    "Beacon",
    "DropJetpack",
    "DropWeapon",
    "DropMines",
    "DropWelder",
    "BuildExtractor",
    "Scan",
    "ScanShade",
    "PowerSurge",
    "DropSupport",
    "DropPack",
    "DropSecondPack",
    "BuildAndManageMAC",
    "BuildAndManageARC",
    "BuildOrder",
    "AttackOrder",
    "MoveOrder",
    "WeldOrder",
    "Idle"
  })
end

--------------------------------------------------------------------------------
-- Make a local copy of the brain actions array.
--------------------------------------------------------------------------------
-- Without a deep copy of the array, the old functions get replaced and hooks
-- will break.

for i, v in ipairs(kMarineComBrainActions) do
  kOldComActions[i] = v
end

--------------------------------------------------------------------------------
-- Load the commander actions.
--------------------------------------------------------------------------------

Script.Load("lua/bishop/marinecom/MComActions_AttackOrder.lua")
Script.Load("lua/bishop/marinecom/MComActions_OffensivePhaseGate.lua")
Script.Load("lua/bishop/marinecom/MComActions_Research.lua")
Script.Load("lua/bishop/marinecom/MComActions_Scan.lua")
Script.Load("lua/bishop/marinecom/MComActions_ScanTunnel.lua")
Script.Load("lua/bishop/marinecom/MComActions_Sentry.lua")
Script.Load("lua/bishop/marinecom/MComActions_Support.lua")
Script.Load("lua/bishop/marinecom/MComActions_TechPoint.lua")

--------------------------------------------------------------------------------
-- Convert the remaining unmodded actions to Bishop priorities.
--------------------------------------------------------------------------------

local ItsGameOverMan = GetOldComAction(kOldComActionTypes.Nothing)

function Bishop.marineCom.actions.ItsGameOverMan(bot, brain, com)
  local action = ItsGameOverMan(bot, brain, com)
  action.name = "ItsGameOverMan"

  if action.weight > 0 then
    action.weight = GetActionWeight(kActionTypes.ItsGameOverMan)
  end

  return action
end

local EmergencyBeacon = GetOldComAction(kOldComActionTypes.Beacon)

function Bishop.marineCom.actions.EmergencyBeacon(bot, brain, com)
  local action = EmergencyBeacon(bot, brain, com)
  action.name = "EmergencyBeacon"

  if action.weight > 0 then
    action.weight = GetActionWeight(kActionTypes.EmergencyBeacon)
  end

  return action
end

local EmergencyRecycleGhost = GetOldComAction(kOldComActionTypes.Recycle)

function Bishop.marineCom.actions.EmergencyRecycleGhost(bot, brain, com)
  local action = EmergencyRecycleGhost(bot, brain, com)
  action.name = "EmergencyRecycleGhost"

  if action.weight > 0 then
    action.weight = GetActionWeight(kActionTypes.EmergencyRecycleGhost)
  end

  return action
end

local EmergencyPowerSurgePhaseGate =
  GetOldComAction(kOldComActionTypes.PowerSurge)

function Bishop.marineCom.actions.EmergencyPowerSurgePhaseGate(bot, brain, com)
  local action = EmergencyPowerSurgePhaseGate(bot, brain, com)
  action.name = "EmergencyPowerSurgePhaseGate"

  if action.weight > 0 then
    action.weight = GetActionWeight(kActionTypes.EmergencyPowerSurgePhaseGate)
  end

  return action
end

local SupportSpecialPack = GetOldComAction(kOldComActionTypes.DropSupport)

function Bishop.marineCom.actions.SupportSpecialPack(bot, brain, com)
  local action = SupportSpecialPack(bot, brain, com)
  action.name = "SupportSpecialPack"

  if action.weight > 0 then
    action.weight = GetActionWeight(kActionTypes.SupportSpecialPack)
  end

  return action
end

local BuildExtractor = GetOldComAction(kOldComActionTypes.BuildExtractor)

function Bishop.marineCom.actions.BuildExtractor(bot, brain, com)
  local action = BuildExtractor(bot, brain, com)
  action.name = "BuildExtractor"

  if action.weight > 0 then
    action.weight = GetActionWeight(kActionTypes.BuildExtractor)
  end

  return action
end

local BuildMAC = GetOldComAction(kOldComActionTypes.BuildAndManageMAC)

function Bishop.marineCom.actions.BuildMAC(bot, brain, com)
  local action = BuildMAC(bot, brain, com)
  action.name = "BuildMAC"

  if action.weight > 0 then
    action.weight = GetActionWeight(kActionTypes.BuildMAC)
  end

  return action
end

local DropJetpack = GetOldComAction(kOldComActionTypes.DropJetpack)

function Bishop.marineCom.actions.DropJetpack(bot, brain, com)
  local action = DropJetpack(bot, brain, com)
  action.name = "DropJetpack"

  if action.weight > 0 then
    action.weight = GetActionWeight(kActionTypes.DropJetpack)
  end

  return action
end

local Idle = GetOldComAction(kOldComActionTypes.Idle)

function Bishop.marineCom.actions.Idle(bot, brain, com)
  local action = Idle(bot, brain, com)
  action.name = "Idle"
  action.weight = GetActionWeight(kActionTypes.Idle)

  return action
end

local DropWeapon

if not kBotMaintenanceLoaded then
  DropWeapon = GetOldComAction(kOldComActionTypes.DropWeapon)

  function Bishop.marineCom.actions.DropWeapon(bot, brain, com)
    local action = DropWeapon(bot, brain, com)
    action.name = "DropWeapon"

    if action.weight > 0 then
      action.weight = GetActionWeight(kActionTypes.DropWeapon)
    end

    return action
  end
end

if kBotMaintenanceLoaded then
  local Scan = GetOldComAction(kOldComActionTypes.Scan)

  function Bishop.marineCom.actions.Scan(bot, brain, com)
    local action = Scan(bot, brain, com)
    action.name = "Scan"

    if action.weight > 0 then
      action.weight = GetActionWeight(kActionTypes.Scan)
    end

    return action
  end

  local PhaseGateDouble = GetOldComAction(kOldComActionTypes.PhaseGateDouble)

  function Bishop.marineCom.actions.PhaseGateDouble(bot, brain, com)
    local action = PhaseGateDouble(bot, brain, com)
    action.name = "PhaseGateDouble"

    if action.weight > 0 then
      action.weight = GetActionWeight(kActionTypes.BuildOffensivePhaseGate)
    end

    return action
  end

  local BuildARC = GetOldComAction(kOldComActionTypes.BuildAndManageARC)

  function Bishop.marineCom.actions.BuildARC(bot, brain, com)
    local action = BuildARC(bot, brain, com)
    action.name = "BuildARC"

    if (action.weight > 0) then
      action.weight = GetActionWeight(kActionTypes.BuildARC)
    end

    return action
  end

  local BuildOrder = GetOldComAction(kOldComActionTypes.BuildOrder)

  function Bishop.marineCom.actions.BuildOrder(bot, brain, com)
    local action = BuildOrder(bot, brain, com)
    action.name = "BuildOrder"

    if (action.weight > 0) then
      action.weight = GetActionWeight(kActionTypes.GiveOrder)
    end

    return action
  end

  local MoveOrder = GetOldComAction(kOldComActionTypes.MoveOrder)

  function Bishop.marineCom.actions.MoveOrder(bot, brain, com)
    local time = Shared_GetTime()

    -- Bishop builds secondary bases later in the tech tree, so an artificial
    -- cooldown is added to Bot_Maintenance's move order to prevent a marine
    -- being permanently locked in to a tech point without a command station.
    if time > brain.nextMoveOrderTime then
      local action = MoveOrder(bot, brain, com)
      action.name = "MoveOrder"

      if (action.weight > 0) then
        brain.nextMoveOrderTime = time + kTimeBetweenMoveOrders
        action.weight = GetActionWeight(kActionTypes.GiveOrder)
      end

      return action
    end

    return kNilAction
  end

  local WeldOrder = GetOldComAction(kOldComActionTypes.WeldOrder)

  function Bishop.marineCom.actions.WeldOrder(bot, brain, com)
    local action = WeldOrder(bot, brain, com)
    action.name = "WeldOrder"

    if (action.weight > 0) then
      action.weight = GetActionWeight(kActionTypes.GiveOrder)
    end

    return action
  end

  local DropWeapon = GetOldComAction(kOldComActionTypes.DropWeapon)

  function Bishop.marineCom.actions.DropWeapon(bot, brain, com)
    local action = DropWeapon(bot, brain, com)
    action.name = "DropWeapon"

    if action.weight > 0 then
      action.weight = GetActionWeight(kActionTypes.DropWeapon)
    end

    return action
  end

  local DropMines = GetOldComAction(kOldComActionTypes.DropMines)

  function Bishop.marineCom.actions.DropMines(bot, brain, com)
    local action = DropMines(bot, brain, com)
    action.name = "DropMines"

    if action.weight > 0 then
      action.weight = GetActionWeight(kActionTypes.DropMines)
    end

    return action
  end

  local DropWelder = GetOldComAction(kOldComActionTypes.DropWelder)

  function Bishop.marineCom.actions.DropWelder(bot, brain, com)
    local action = DropWelder(bot, brain, com)
    action.name = "DropWelder"

    if action.weight > 0 then
      action.weight = GetActionWeight(kActionTypes.DropWelder)
    end

    return action
  end

  local ScanShade = GetOldComAction(kOldComActionTypes.ScanShade)

  function Bishop.marineCom.actions.ScanShade(bot, brain, com)
    local action = ScanShade(bot, brain, com)
    action.name = "ScanShade"

    if action.weight > 0 then
      action.weight = GetActionWeight(kActionTypes.ScanShade)
    end

    return action
  end

  local AttackOrder = GetOldComAction(kOldComActionTypes.AttackOrder)

  function Bishop.marineCom.actions.AttackOrder2(bot, brain, com)
    local action = AttackOrder(bot, brain, com)
    action.name = "AttackOrder"

    if action.weight > 0 then
      action.weight = GetActionWeight(kActionTypes.AttackOrder)
    end

    return action
  end
end

--------------------------------------------------------------------------------
-- Clean up old entries from the alert queue.
--------------------------------------------------------------------------------
-- Rather than have a bunch of cleanup code spread throughout each action, just
-- sweep through at the end of each commander tick and nuke the old entries.
-- TODO: Is there a better place for this?

function Bishop.marineCom.actions.CleanAlertQueue(bot, brain, com)
  local kMaxAlertAge = 30
  local currentTime = Shared_GetTime()
  local alertQueue = com:GetAlertQueue()
  local n = #alertQueue
  local i = 1

  while i <= n do
    if currentTime - alertQueue[i].time > kMaxAlertAge then
      alertQueue[i], alertQueue[n] = alertQueue[n], nil
      n = n - 1
    else
      i = i + 1
    end
  end

  com:SetAlertQueue(alertQueue)

  return kNilAction
end

--------------------------------------------------------------------------------
-- Setup the actions array.
--------------------------------------------------------------------------------

if not kBotMaintenanceLoaded then
  kMarineComBrainActions = {
    Bishop.marineCom.actions.ItsGameOverMan,
    Bishop.marineCom.actions.EmergencyBeacon,
    Bishop.marineCom.actions.EmergencyRecycleGhost,
    Bishop.marineCom.actions.EmergencyPowerSurgePhaseGate,
    Bishop.marineCom.actions.SupportMedPack,
    Bishop.marineCom.actions.SupportPreemptiveMedPack,
    Bishop.marineCom.actions.SupportAmmoPack,
    Bishop.marineCom.actions.SupportSpecialPack,
    Bishop.marineCom.actions.BuildInfantryPortal,
    Bishop.marineCom.actions.Research,
    Bishop.marineCom.actions.BuildExtractor,
    Bishop.marineCom.actions.ScanHive,
    Bishop.marineCom.actions.ScanTunnel,
    Bishop.marineCom.actions.BuildOffensivePhaseGate,
    Bishop.marineCom.actions.BuildOffensiveArmory,
    Bishop.marineCom.actions.RecycleOffensivePhaseGate,
    Bishop.marineCom.actions.ReverseOffensivePhaseGate,
    Bishop.marineCom.actions.BuildTechPointPhaseGate,
    Bishop.marineCom.actions.BuildTechPointArmory,
    Bishop.marineCom.actions.BuildTechPointCommandStation,
    Bishop.marineCom.actions.BuildTechPointObservatory,
    Bishop.marineCom.actions.BuildTechPointInfantryPortal,
    Bishop.marineCom.actions.BuildSentry,
    Bishop.marineCom.actions.BuildSentryBattery,
    Bishop.marineCom.actions.RecycleSentries,
    Bishop.marineCom.actions.BuildMAC,
    Bishop.marineCom.actions.AttackOrder,
    Bishop.marineCom.actions.DropWeapon,
    Bishop.marineCom.actions.DropJetpack,
    Bishop.marineCom.actions.Idle,
    Bishop.marineCom.actions.CleanAlertQueue
  }
else
  kMarineComBrainActions = {
    Bishop.marineCom.actions.ItsGameOverMan,
    Bishop.marineCom.actions.EmergencyBeacon,
    Bishop.marineCom.actions.EmergencyRecycleGhost,
    Bishop.marineCom.actions.EmergencyPowerSurgePhaseGate,
    Bishop.marineCom.actions.SupportMedPack,
    Bishop.marineCom.actions.SupportPreemptiveMedPack,
    Bishop.marineCom.actions.SupportAmmoPack,
    Bishop.marineCom.actions.SupportSpecialPack,
    Bishop.marineCom.actions.BuildInfantryPortal,
    Bishop.marineCom.actions.Research,
    Bishop.marineCom.actions.BuildExtractor,
    -- Bishop.marineCom.actions.ScanHive, Conflicting with Bot_Maintenance.
    Bishop.marineCom.actions.ScanTunnel,
    Bishop.marineCom.actions.BuildOffensivePhaseGate,
    Bishop.marineCom.actions.BuildOffensiveArmory,
    Bishop.marineCom.actions.RecycleOffensivePhaseGate,
    Bishop.marineCom.actions.ReverseOffensivePhaseGate,
    Bishop.marineCom.actions.BuildTechPointPhaseGate,
    Bishop.marineCom.actions.BuildTechPointArmory,
    Bishop.marineCom.actions.BuildTechPointCommandStation,
    Bishop.marineCom.actions.BuildTechPointObservatory,
    Bishop.marineCom.actions.BuildTechPointInfantryPortal,
    Bishop.marineCom.actions.BuildSentry,
    Bishop.marineCom.actions.BuildSentryBattery,
    Bishop.marineCom.actions.RecycleSentries,
    Bishop.marineCom.actions.PhaseGateDouble,
    Bishop.marineCom.actions.BuildMAC,
    Bishop.marineCom.actions.BuildARC,
    Bishop.marineCom.actions.BuildOrder,
    Bishop.marineCom.actions.MoveOrder,
    Bishop.marineCom.actions.WeldOrder,
    Bishop.marineCom.actions.AttackOrder,
    Bishop.marineCom.actions.Scan,
    Bishop.marineCom.actions.DropJetpack,
    Bishop.marineCom.actions.Idle,
    Bishop.marineCom.actions.DropWeapon,
    Bishop.marineCom.actions.DropMines,
    Bishop.marineCom.actions.DropWelder,
    Bishop.marineCom.actions.ScanShade,
    Bishop.marineCom.actions.AttackOrder2,
    Bishop.marineCom.actions.CleanAlertQueue
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
