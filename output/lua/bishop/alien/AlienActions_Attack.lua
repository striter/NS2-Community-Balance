-- This file is experimental and not currently in use.

-- TODO: Retreat should be an action.
-- TODO: Bodyblock attack should be an action.
-- TODO: Bodyblock avoid should be an action.

Script.Load("lua/Globals.lua")
Script.Load("lua/bots/CommonAlienActions.lua")
Script.Load("lua/bots/LocationContention.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/alien/Lifeform.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetLocationContention = GetLocationContention
local GetTunnelDistanceForAlien = GetTunnelDistanceForAlien
local max = math.max

local GetCachedTable = Bishop.lib.table.GetCachedTable
local GetEntityIfAlive = Bishop.lib.entity.GetEntityIfAlive
local GetCurrentLifeform = Bishop.alien.lifeform.GetCurrentLifeform
local GetPerformAttackFunction = Bishop.utility.GetPerformAttackFunction

local kMinimapBlipType = kMinimapBlipType
local kNilAction = Bishop.lib.constants.kNilAction

local kAssignmentCountIndex = 1
local kLowPriorityIndex = 2
local kHighPriorityIndex = 3

local kMinUrgency = 0.01
local kUrgencies = {
  [kMinimapBlipType.Exo] =              {4, 0.50, 1.15},
  [kMinimapBlipType.Marine] =           {3, 0.45, 1.10},
  [kMinimapBlipType.JetpackMarine] =    {2, 0.45, 1.05},
  [kMinimapBlipType.Sentry] =           {2, 0.40, 1.00},

  [kMinimapBlipType.ARC] =              {3, 0.35, 0.95},
  [kMinimapBlipType.PowerPoint] =       {4, 0.30, 0.90},
  [kMinimapBlipType.InfantryPortal] =   {3, 0.30, 0.90},
  [kMinimapBlipType.PhaseGate] =        {3, 0.30, 0.90},
  [kMinimapBlipType.Observatory] =      {3, 0.25, 0.85},
  [kMinimapBlipType.CommandStation] =   {3, 0.20, 0.65},
  [kMinimapBlipType.ArmsLab] =          {3, 0.20, 0.60},
  [kMinimapBlipType.PrototypeLab] =     {3, 0.20, 0.55},
  [kMinimapBlipType.SentryBattery] =    {2, 0.20, 0.50},
  [kMinimapBlipType.Extractor] =        {3, 0.20, 0.50},
  [kMinimapBlipType.MAC] =              {1, 0.15, 0.40},
  [kMinimapBlipType.Armory] =           {2, 0.10, 0.20},
  [kMinimapBlipType.RoboticsFactory] =  {2, 0.10, 0.20},
}
local kValidGhostStructures = {
  [kMinimapBlipType.CommandStation] = true,
  [kMinimapBlipType.Extractor] = true,
  [kMinimapBlipType.PhaseGate] = true,
}

local kFastUpdateRange = 20
local kMaxTargetRange = 40
local kMaxTargetRangeClamp = 50
local kIgnorePassiveRadiusSqr = 7 * 7

local kMaxUrgencyBonus = 0.7
local kUrgencyBonusRadiusSqr = 20 * 20
local kPriorityOverrideRadiusSqr = 10 * 10

local kPassiveBonus = 0.4

local kThreatBonusRadiusSqr = 20 * 20

local kLowHealthUrgencyBonus = 1.2
local kLowHealth = 0.07

local kMinPoweredBuildings = 3

---@param powerPoint ScriptActor|PowerPoint
local function ShouldAttackPowerPoint(powerPoint)
  if not powerPoint:HasConsumerRequiringPower() then
    return false
  end

  local locGroup = GetLocationContention():GetLocationGroup(
    powerPoint:GetLocationName())
  if locGroup and locGroup:GetNumMarineStructures() < kMinPoweredBuildings then
    return false
  end

  return true
end

---Calculates an attack urgency metric based on the alien's current situation.
---Only pass enemy memories into this function, it assumes they are attackable.
---@param mem TeamBrain.Memory
---@param isThreat boolean
---@param isUnderFire boolean
---@param alien Player
---@param teamBrain TeamBrain
---@return number urgency
local function GetAttackUrgency(mem, isThreat, isUnderFire, alien, teamBrain)
  local ent = GetEntityIfAlive(mem.entId)
  if not ent then
    return -1.0
  end

  local distanceSqr = alien:GetDistanceSquared(ent)
  --local urgencyRow = kUrgencies[mem.btype] or isThreat and kDefaultThreatUrgency
  --  or kDefaultPassiveUrgency
  local urgencyRow = kUrgencies[mem.btype]

  if not urgencyRow then
    Bishop.Error("MapBlip %s is unhandled, isThreat: %s.",
      kMinimapBlipType[mem.btype], isThreat)
    return -1.0
  end

  local urgency = ((distanceSqr <= kPriorityOverrideRadiusSqr or
    teamBrain:GetNumOthersAssignedToEntity(alien, mem.entId)
    >= urgencyRow[kAssignmentCountIndex]) and urgencyRow[kHighPriorityIndex]
    or urgencyRow[kLowPriorityIndex])
    + max(0, (kUrgencyBonusRadiusSqr - distanceSqr) / kUrgencyBonusRadiusSqr)
    * kMaxUrgencyBonus

  if isThreat then
    return urgency + (distanceSqr < kThreatBonusRadiusSqr and mem.threat or 0.0)
  elseif ent.GetIsGhostStructure and ent:GetIsGhostStructure()
      and not kValidGhostStructures[mem.btype] then
    return kMinUrgency
  elseif mem.btype == kMinimapBlipType.PowerPoint
      and not ShouldAttackPowerPoint(ent) then
    return -1.0
  else
    return urgency + (not isUnderFire and kPassiveBonus or 0.0)
      + (ent:GetHealthScalar() <= kLowHealth and kLowHealthUrgencyBonus or 0.0)
  end
end

---@param memories TeamBrain.Memory[]
---@param isThreat boolean
---@param alien Player
---@param teamBrain TeamBrain
---@return TeamBrain.Memory?
---@return number urgency
local function GetMostUrgentMemory(memories, isThreat, alien, teamBrain)
  local memory
  local highestUrgency = 0.0
  local isUnderFire = alien:GetIsUnderFire()

  for i = 1, #memories do
    local urgency = GetAttackUrgency(memories[i], isThreat, isUnderFire, alien,
      teamBrain)
    if urgency > highestUrgency then
      memory = memories[i]
      highestUrgency = urgency
    end
  end

  return memory, highestUrgency
end

---@param action table
---@param alien Player
---@param mem TeamBrain.Memory
---@param isFastUpdate boolean
---@return table
local function FillActionData(action, alien, mem, isFastUpdate)
  if not action.name then
    action.name = "Attack"
    action.perform = GetPerformAttackFunction(GetCurrentLifeform(alien))
    action.weight = 1
  end

  action.memory = mem
  action.bestMem = mem -- TODO: Temp entry for Skulks.
  action.fastUpdate = isFastUpdate

  return action
end

---@param _ Bot
---@param brain PlayerBrain
---@param alien Player
---@return table
function Bishop.alien.actions.Attack(_, brain, alien)
  local mem, passiveMem
  local threatUrgency = 0.0
  local passiveUrgency = 0.0
  local senses = brain:GetSenses()

  mem, threatUrgency = GetMostUrgentMemory(senses:Get("mem_threats"),
    true, alien, brain.teamBrain)

  if not mem or alien:GetDistanceSquared(mem.lastSeenPos)
      > kIgnorePassiveRadiusSqr then
    passiveMem, passiveUrgency = GetMostUrgentMemory(senses:Get("mem_passives"),
      false, alien, brain.teamBrain)
    if passiveUrgency > threatUrgency then
      mem = passiveMem
    end
  end

  if not mem then
    return kNilAction
  end

  local actionData = GetCachedTable(alien, "action_attack")
  local maxDistance = actionData.memory == mem and kMaxTargetRangeClamp
    or kMaxTargetRange
  local distance = select(2, GetTunnelDistanceForAlien(alien, mem.lastSeenPos))
  if distance > maxDistance then
    return kNilAction
  end

  return FillActionData(actionData, alien, mem, distance < kFastUpdateRange)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
