Script.Load("lua/AlienTunnelManager.lua")
Script.Load("lua/BuildUtility.lua")
Script.Load("lua/Entity.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")
Script.Load("lua/Table.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/Utility.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/aliencom/OffensiveTunnel.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetEntitiesAliveForTeamByLocation = GetEntitiesAliveForTeamByLocation
local GetIsBuildLegal = GetIsBuildLegal
local GetTeamInfoEntity = GetTeamInfoEntity
local ipairs = ipairs
local kAlienTeamType = kAlienTeamType
local kStructureSnapRadius = kStructureSnapRadius
local min = math.min
local random = math.random
local Shared_GetTime = Shared.GetTime
local table_contains = table.contains
local table_random = table.random

local actions = Bishop.alienCom.actions
local actionTypes = Bishop.alienCom.actionTypes
local GetActionWeight = Bishop.alienCom.GetActionWeight
local GetOffensiveCystPosition =
  Bishop.alienCom.offensiveTunnel.GetOffensiveCystPosition
local GetOffensiveTunnel =
  Bishop.alienCom.offensiveTunnel.GetOffensiveTunnel
local IsPositionSafe = Bishop.utility.IsPositionSafe
local kNilAction = Bishop.lib.constants.kNilAction
local kTunnelState = Bishop.alienCom.offensiveTunnel.kTunnelState
local LogOT = Bishop.debug.OffensiveTunnelLog
local OffensiveTunnelExists =
  Bishop.alienCom.offensiveTunnel.OffensiveTunnelExists
local TraceFromAbove = Bishop.utility.TraceFromAbove

--------------------------------------------------------------------------------
-- Balance values and constants.
--------------------------------------------------------------------------------

local kMaxCystHeightDelta = 0.32 -- Disallow tunnel above the cyst.
local kMaxHiveHeightDelta = -2.38 -- Disallow tunnel above the hive.
local kMinHarvestersForTunnel = 3
local kTimeBetweenOffensiveTunnels = 30
local kTunnelDistanceFromHive = 13
local kTunnelDistanceOffensive = kInfestationRadius

local kDebug = Bishop.debug.offensiveTunnel

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

local function LocationsTunneled(senses, locationa, locationb)
  local tunnels = senses:Get("allTunnelEntrances")

  for _, tunnel in ipairs(tunnels) do
    local locationId = tunnel:GetLocationId()
    if locationId == locationa then
      local connectedTunnel = tunnel:GetOtherEntrance()
      if connectedTunnel and connectedTunnel:GetLocationId() == locationb then
        return true
      end
    end
  end

  return false
end

local function GetSuitableTunnelHive(senses, teamBrain, tunnel)
  local hives = senses:Get("hives")
  local safeHives = senses:Get("safeHives")
  local tunnelLocationId = tunnel:GetLocationId()
  local tunnelPosition = tunnel:GetOrigin()
  local maxDistance = 0
  local suitableHive
  local furthestHive

  for _, hive in ipairs(hives) do
    local distance = tunnelPosition:GetDistance(hive:GetOrigin())
    local locationId = hive:GetLocationId()

    -- This is a fallback for all hives being suitably tunneled.
    if tunnelLocationId ~= locationId and distance > maxDistance
        and not LocationsTunneled(senses, locationId, tunnelLocationId) then
      maxDistance = distance
      furthestHive = hive
    end

    local tunnels = GetEntitiesAliveForTeamByLocation("TunnelEntrance",
      kAlienTeamType, locationId)

    if #tunnels == 0
        or (#tunnels == 1 and OffensiveTunnelExists(teamBrain)
          and tunnels[1] == GetOffensiveTunnel(teamBrain)) then
      suitableHive = hive
    end
  end

  if suitableHive and not table_contains(safeHives, suitableHive) then
    return nil
  end

  return suitableHive or furthestHive
end

local function GetTunnelTechId(brain, doables, tunnel)
  local tunnelManager = GetTeamInfoEntity(kAlienTeamType):GetTunnelManager()
  tunnelManager:GetTechButtons()

  if not tunnel then
    return brain:GetTunnelBuildTechTechIdForEmptyPair(tunnelManager, doables)
  end

  return tunnelManager:GetComplimentaryBuildTechIdForTunnelEntrance(
    tunnel:GetId())
end

--------------------------------------------------------------------------------
-- Build tunnels between hives.
--------------------------------------------------------------------------------

local function PerformBuildTunnel(move, bot, brain, com, action)
  local position = action.position
  brain:ExecuteTechId(com, action.techId, position, com)
  local teamBrain = brain.teamBrain

  if action.isOffensive then
    local tunnels = GetEntitiesWithinRange("TunnelEntrance", position, 5)
    teamBrain.nextOffensiveTunnelTime = Shared_GetTime()
      + kTimeBetweenOffensiveTunnels

    if (#tunnels ~= 0) then
      teamBrain.offensiveTunnelId = tunnels[1]:GetId()
      teamBrain.offensiveTunnelPosition = position
      teamBrain.offensiveTunnelState = kTunnelState.Built
      if kDebug then LogOT("Tunnel has been placed.") end
    else
      Bishop.Error("PerformBuildTunnel couldn't locate its tunnel.")
    end
  end
end

function actions.BuildTunnelEntrance(bot, brain, com)
  local senses = brain:GetSenses()
  local teamBrain = brain.teamBrain
  local tunnels = senses:Get("numTunnelEntrances")
  local maxTunnels = min(#senses:Get("builtHives") * 2, 8)

  if tunnels == maxTunnels or senses:Get("unConnectedTunnelEntrance")
      or senses:Get("numHarvesters") < kMinHarvestersForTunnel then
    return kNilAction
  end

  local safeHives = senses:Get("safeHives")
  local hive = table_random(safeHives)
  local doables = senses:Get("doableTechIds")
  local techId = GetTunnelTechId(brain, doables)

  if not hive or not doables[techId] then
    return kNilAction
  end

  local hivePosition = hive:GetOrigin()

  if not IsPositionSafe(kAlienTeamType, brain, hivePosition) then
    return kNilAction
  end

  local radius = random() * kTunnelDistanceFromHive
  local trace = TraceFromAbove(hivePosition, radius)
  local isLegal
  local position

  if trace then
    isLegal, position = GetIsBuildLegal(techId, trace.endPoint, 0,
      kStructureSnapRadius, com)
  end
  
  if not isLegal or position.y - hivePosition.y >= kMaxHiveHeightDelta then
    return kNilAction
  end

  -- TODO: Make sure chosen position matches location for hive.
  return {
    name = "BuildTunnelEntrance",
    perform = PerformBuildTunnel,
    weight = GetActionWeight(actionTypes.BuildTunnel),

    -- Action metadata.
    position = position,
    techId = techId
  }
end

function actions.BuildTunnelExit(bot, brain, com)
  local senses = brain:GetSenses()
  local teamBrain = brain.teamBrain
  local availableTunnels = min(#senses:Get("builtHives") * 2, 8)
    - senses:Get("numTunnelEntrances")
  local unconnectedTunnel = senses:Get("unConnectedTunnelEntrance")

  -- Always reserve one tunnel exit for offensive usage.
  if availableTunnels == 0
      or not unconnectedTunnel
      or senses:Get("numHarvesters") < kMinHarvestersForTunnel
      or (availableTunnels == 1 and not OffensiveTunnelExists(teamBrain)) then
    return kNilAction
  end

  local doables = senses:Get("doableTechIds")
  local techId = GetTunnelTechId(brain, doables, unconnectedTunnel)
  local hive = GetSuitableTunnelHive(senses, teamBrain, unconnectedTunnel)

  if not hive or not doables[techId] then
    return kNilAction
  end

  local hivePosition = hive:GetOrigin()

  if not IsPositionSafe(kAlienTeamType, brain, hivePosition) then
    return kNilAction
  end

  local radius = random() * kTunnelDistanceFromHive
  local trace = TraceFromAbove(hivePosition, radius)
  local isLegal
  local position

  if trace then
    isLegal, position = GetIsBuildLegal(techId, trace.endPoint, 0,
      kStructureSnapRadius, com)
  end
  
  if not isLegal or position.y - hivePosition.y >= kMaxHiveHeightDelta then
    return kNilAction
  end
  
  -- TODO: Make sure chosen position matches location for hive.
  return {
    name = "BuildTunnelExit",
    perform = PerformBuildTunnel,
    weight = GetActionWeight(actionTypes.BuildTunnel),

    -- Action metadata.
    position = position,
    techId = techId
  }
end

--------------------------------------------------------------------------------
-- Build the tunnel exit for an offensive tunnel.
--------------------------------------------------------------------------------
-- The position is calculated in AComActions_OffensiveTunnel.lua and passed here
-- via the team brain.

function actions.BuildOffensiveTunnel(bot, brain, com)
  local senses = brain:GetSenses()
  local teamBrain = brain.teamBrain

  if teamBrain.offensiveTunnelState ~= kTunnelState.CystReady then
    return kNilAction
  end

  local doables = senses:Get("doableTechIds")
  local tunnel = senses:Get("unConnectedTunnelEntrance")
  local techId = GetTunnelTechId(brain, doables, tunnel)
  local time = Shared_GetTime()

  if not tunnel or not doables[techId]
      or time < teamBrain.nextOffensiveTunnelTime
      or senses:Get("numHarvesters") < kMinHarvestersForTunnel then
    return kNilAction
  end

  local cystPosition = GetOffensiveCystPosition(teamBrain)

  if not IsPositionSafe(kAlienTeamType, brain, cystPosition) then
    return kNilAction
  end

  local radius = random() * kTunnelDistanceOffensive
  local trace = TraceFromAbove(cystPosition, radius)
  local isLegal
  local position

  if trace then
    isLegal, position = GetIsBuildLegal(techId, trace.endPoint, 0,
      kStructureSnapRadius, com)
  end
  
  if not isLegal or position.y - cystPosition.y >= kMaxCystHeightDelta then
    return kNilAction
  end

  return {
    name = "BuildOffensiveTunnel",
    perform = PerformBuildTunnel,
    weight = GetActionWeight(actionTypes.BuildTunnel),

    -- Action metadata.
    isOffensive = true,
    position = position,
    techId = techId
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
