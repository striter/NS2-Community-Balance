-- TODO: This file needs a brutal clean-up, it's a fucking mess.

Script.Load("lua/BuildUtility.lua")
Script.Load("lua/Entity.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/Table.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/Utility.lua")
Script.Load("lua/bots/LocationGraph.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/aliencom/OffensiveTunnel.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetEntitiesWithinRange = GetEntitiesWithinRange
local GetIsBuildLegal = GetIsBuildLegal
local GetLocationGraph = GetLocationGraph
local huge = math.huge
local ientitylist = ientitylist
local ipairs = ipairs
local IsValid = IsValid
local kAlienTeamType = kAlienTeamType
local kMinimapBlipType = kMinimapBlipType
local kTechId = kTechId
local kStructureSnapRadius = kStructureSnapRadius
local pairs = pairs
local Pathing_GetClosestPoint = Pathing.GetClosestPoint
local random = math.random
local Shared_GetEntitiesWithClassname = Shared.GetEntitiesWithClassname
local Shared_GetEntity = Shared.GetEntity
local Shared_GetTime = Shared.GetTime
local table_contains = table.contains
local table_insert = table.insert
local table_random = table.random

local actions = Bishop.alienCom.actions
local actionTypes = Bishop.alienCom.actionTypes
local GetActionWeight = Bishop.alienCom.GetActionWeight
local GetOffensiveCystPosition =
  Bishop.alienCom.offensiveTunnel.GetOffensiveCystPosition
local GetOffensiveTunnel = Bishop.alienCom.offensiveTunnel.GetOffensiveTunnel
local GetOffensiveTunnelPosition =
  Bishop.alienCom.offensiveTunnel.GetOffensiveTunnelPosition
local IsPositionSafe = Bishop.utility.IsPositionSafe
local kNilAction = Bishop.lib.constants.kNilAction
local kTunnelState = Bishop.alienCom.offensiveTunnel.kTunnelState
local Log = Bishop.debug.OffensiveTunnelLog
local OffensiveTunnelCystExists =
  Bishop.alienCom.offensiveTunnel.OffensiveTunnelCystExists
local OffensiveTunnelExists =
  Bishop.alienCom.offensiveTunnel.OffensiveTunnelExists
local SearchMemoriesFor = Bishop.utility.SearchMemoriesFor
local TraceFromAbove = Bishop.utility.TraceFromAbove

--------------------------------------------------------------------------------
-- Balance variables and constants.
--------------------------------------------------------------------------------

local kMinHarvestersForOffensiveShade = 3
local kMinTunnelDistance = 40
local kOffensiveTunnelShadeRadius = 5
local kTimeBetweenOffensiveShades = 30
local kTimeBetweenOffensiveTunnelScans = 20

local kDebug = Bishop.debug.offensiveTunnel

--------------------------------------------------------------------------------
-- Step 1: Locate a suitable position for an offensive tunnel and cyst to it.
--------------------------------------------------------------------------------
-- The actual cyst building is done in AComActions_Cyst.lua.

local function ClosestTunnelDistance(tunnels, position)
  local closestDistance = huge

  for _, tunnel in ipairs(tunnels) do
    local distance = position:GetDistance(tunnel:GetOrigin())
    if distance < closestDistance then
      closestDistance = distance
    end
  end

  return closestDistance
end

-- Returns true if the map has two resource nodes in one location.
local function GetMapHasDouble()
  if Bishop.utility.hasDouble ~= nil then
    return Bishop.utility.hasDouble
  end

  local locations = {}
  for _, res in ientitylist(Shared_GetEntitiesWithClassname("ResourcePoint")) do
    local location = res:GetLocationName()

    if location ~= "" and table_contains(locations, location) then
      Bishop.utility.hasDouble = true
      Bishop.utility.doublePosition = res:GetOrigin()
      if kDebug then Log("Double found in %s.", location) end
      return true
    end

    table_insert(locations, location)
  end

  if kDebug then Log("Map has no double.") end
  Bishop.utility.hasDouble = false
  return false
end

local function GetClosestLocationPosition(position)
  local locationGraph = GetLocationGraph()
  local positions = locationGraph.locationExplorePositions
  local closestDistance = huge
  local closestLocation = ""
  local closestPosition = nil

  for location, explorePosition in pairs(positions) do
    local distance = position:GetDistance(explorePosition)
    
    if distance < closestDistance then
      closestDistance = distance
      closestLocation = location
      closestPosition = explorePosition
    end
  end

  if kDebug then
    Log("Next best was %s at %s.", closestLocation, closestPosition)
  end

  return closestPosition
end

local function GetRandomTechPointMidpoint(teamBrain, senses)
  -- If the map has a double res node, it's usually in a pretty central
  -- location and should be secured.
  if GetMapHasDouble() then
    if kDebug then Log("Chose DOUBLE as cyst location.") end
    return Bishop.utility.doublePosition
  end

  -- Otherwise, get a central average of all available tech points.
  local techPoints = senses:Get("availTechPoints")
  local position = Vector(0, 0, 0)

  for _, techPoint in ipairs(techPoints) do
    position = position + techPoint:GetOrigin()
  end

  local position = position / #techPoints
  if kDebug then Log("Chose map-control %s as cyst location.", position) end
  local correctedPosition = Pathing_GetClosestPoint(position)

  -- Pathing.GetClosestPoint will return the input if nothing is found. In this
  -- case, iterate through the location graph for the closest named location.
  if kDebug then
    Log("position = %s, correctedPosition = %s, equal = %s", position,
      correctedPosition, position == correctedPosition)
  end
  if position == correctedPosition then
    if kDebug then
      Log("Position is way off navmesh. Finding nearest location.")
    end
    position = GetClosestLocationPosition(position)
    correctedPosition = Pathing.GetClosestPoint(position)
  end
  if kDebug then Log("Position corrected to %s", correctedPosition) end
  -- DebugLine(position + Vector(0, 10, 0), correctedPosition, 15, 1, 1, 1, 1)

  return correctedPosition
end

local function GetSuitableTunnelPositions(brain, senses)
  local locations = {}
  local tunnels = senses:Get("allTunnelEntrances")

  -- If the team isn't ready for an ultra late-game tunnel, include one that
  -- maximizes map control.
  if #senses:Get("builtHives") < 3 and #senses:Get("availTechPoints") > 1 then
    local midPoint = GetRandomTechPointMidpoint(brain.teamBrain, senses)
    
    if ClosestTunnelDistance(tunnels, midPoint) >= kMinTunnelDistance then
      table_insert(locations, midPoint)
    end
  end
  
  local memories = SearchMemoriesFor(kAlienTeamType,
    kMinimapBlipType.CommandStation)
  if kDebug then Log("Found %s memories of command stations.", #memories) end
  
  for _, memory in ipairs(memories) do
    commandStation = Shared_GetEntity(memory.entId)

    if IsValid(commandStation) and commandStation:GetIsAlive() then
      local location = commandStation:GetLocationName()
      local locationGraph = GetLocationGraph()
      local neighbours = locationGraph:GetDirectPathsForLocationName(location)
      if kDebug then Log("Command station in %s:", location) end
  
      for i = 1, #neighbours do
        local locNeighbour = neighbours[i]
        if kDebug then Log("  Neighbouring location %s", locNeighbour) end
        local position = locationGraph.locationExplorePositions[locNeighbour]

        if locNeighbour ~= ""
            and position
            and brain:GetIsSafeToDropInLocation(locNeighbour, kAlienTeamType)
            and ClosestTunnelDistance(tunnels, position)
              >= kMinTunnelDistance then
          if kDebug then Log("  Neighbour %s added!", locNeighbour) end
          -- DebugLine(position + Vector(0, 10, 0), position, 15, 1, 1, 1, 1)
          table_insert(locations, position)
        end
      end
    end
  end

  return locations
end

local function RequestOffensiveTunnelCyst(brain, senses)
  local positions = GetSuitableTunnelPositions(brain, senses)
  local position = table_random(positions)
  local teamBrain = brain.teamBrain

  if position then
    teamBrain.offensiveTunnelCystPosition = position

    if teamBrain.offensiveTunnelState == kTunnelState.Unbuilt then
      teamBrain.offensiveTunnelState = kTunnelState.CystRequested
    else
      teamBrain.offensiveTunnelState = kTunnelState.NewCystRequested
    end

    teamBrain.offensiveTunnelAttempts = 0
    if kDebug then
      Log("Cyst has been requested from %s potentials.", #positions)
    end
  else
    if kDebug then Log("No valid cyst potentials.") end
  end
end

--------------------------------------------------------------------------------
-- Step 2: Once the cyst is placed, build a tunnel on it.
--------------------------------------------------------------------------------
-- Also keep track of the special cyst and revert to step 1 if it's destroyed.
-- If the tunnel is fully matured a cyst is no longer required.

local function PrepareOffensiveTunnel(brain, teamBrain)
  local time = Shared_GetTime()

  if teamBrain.offensiveTunnelState == kTunnelState.CystReady
      and not OffensiveTunnelCystExists(teamBrain) then
    teamBrain.offensiveTunnelCystId = nil
    teamBrain.offensiveTunnelState = kTunnelState.Unbuilt
    if kDebug then Log("Cyst lost, reverting to unbuilt.") end
  end

  if teamBrain.offensiveTunnelState == kTunnelState.NewCystReady
      and not OffensiveTunnelCystExists(teamBrain) then
    teamBrain.offensiveTunnelCystId = nil
    teamBrain.offensiveTunnelState = kTunnelState.Irrelevant
    if kDebug then Log("New cyst lost, reverting to irrelevant.") end
  end

  if (teamBrain.offensiveTunnelState == kTunnelState.Unbuilt
      or teamBrain.offensiveTunnelState == kTunnelState.Irrelevant)
      and time >= teamBrain.nextOffensiveTunnelScan then
    RequestOffensiveTunnelCyst(brain, brain:GetSenses())
    teamBrain.nextOffensiveTunnelScan = time + kTimeBetweenOffensiveTunnelScans
  end
end

--------------------------------------------------------------------------------
-- Step 3: Supplement the tunnel with extra buildings.
--------------------------------------------------------------------------------
-- Start here. Calls nest from bottom to top.

local function PerformBuildOffensiveShade(move, bot, brain, com, action)
  local position = action.position
  brain:ExecuteTechId(com, kTechId.Shade, position, com)
  local teamBrain = brain.teamBrain

  local shades = GetEntitiesWithinRange("Shade", position, 5)
  teamBrain.nextOffensiveShadeTime = Shared_GetTime() +
    kTimeBetweenOffensiveShades

  if (#shades ~= 0) then
    teamBrain.offensiveShade = true
    teamBrain.offensiveShadeId = shades[1]:GetId()
    teamBrain.offensiveTunnelState = kTunnelState.Shaded
    if kDebug then Log("Shade has been placed.") end
  else
    Bishop.Error("PerformBuildOffensiveShade couldn't locate its Shade.")
  end
end

local function BuildOffensiveShade(brain, com)
  local senses = brain:GetSenses()

  if not senses:Get("doableTechIds")[kTechId.Shade]
      or senses:Get("numHarvesters") < kMinHarvestersForOffensiveShade then
    return kNilAction
  end

  local teamBrain = brain.teamBrain
  local position = GetOffensiveTunnelPosition(teamBrain)

  if not IsPositionSafe(kAlienTeamType, brain, position) then
    return kNilAction
  end

  local radius = random() * kOffensiveTunnelShadeRadius
  local trace = TraceFromAbove(position, radius)
  local isLegal
  local position

  if trace then
    isLegal, position = GetIsBuildLegal(kTechId.Shade, trace.endPoint, 0,
      kStructureSnapRadius, com)
  end

  if not isLegal then
    return kNilAction
  end

  return {
    name = "BuildOffensiveShade",
    perform = PerformBuildOffensiveShade,
    weight = GetActionWeight(actionTypes.BuildShade),

    -- Action metadata.
    position = position
  }
end

local function PerformMoveOffensiveShade(move, bot, brain, com, action)
  local position = action.position
  local teamBrain = brain.teamBrain
  local shade = Shared_GetEntity(teamBrain.offensiveShadeId)

  if IsValid(shade) and shade:GetIsAlive() then
    if kDebug then Log("Moving Shade to new tunnel location.") end
    shade:GiveOrder(kTechId.Move, nil, position, nil, true, true, com)

    teamBrain.nextOffensiveShadeTime = Shared_GetTime() +
      kTimeBetweenOffensiveShades
  end
end

local function MoveOffensiveShade(teamBrain, com)
  if Shared_GetTime() < teamBrain.nextOffensiveShadeTime then
    return kNilAction
  end

  local position = GetOffensiveCystPosition(teamBrain)
  local shade = Shared_GetEntity(teamBrain.offensiveShadeId)

  if position:GetDistance(shade:GetOrigin()) < kOffensiveTunnelShadeRadius then
    teamBrain.offensiveTunnelState = kTunnelState.Shaded
    if kDebug then Log("Shade move complete.") end
    return kNilAction
  end

  local radius = random() * kOffensiveTunnelShadeRadius
  local trace = TraceFromAbove(position, radius)
  local isLegal
  local position

  if trace then
    isLegal, position = GetIsBuildLegal(kTechId.Shade, trace.endPoint, 0,
      kStructureSnapRadius, com)
  end

  if not isLegal then
    return kNilAction
  end

  return {
    name = "MoveOffensiveShade",
    perform = PerformMoveOffensiveShade,
    weight = GetActionWeight(actionTypes.MoveBuilding),

    -- Action metadata.
    position = position
  }
end

local function CheckTunnelRelevancy(brain, teamBrain)
  local offensiveTunnel = GetOffensiveTunnel(teamBrain)
  local offensiveTunnelPosition = offensiveTunnel:GetOrigin()
  local tunnels = brain:GetSenses():Get("allTunnelEntrances")
  local minDistance = huge

  for _, tunnel in ipairs(tunnels) do
    local distance = offensiveTunnelPosition:GetDistance(tunnel:GetOrigin())
    if tunnel ~= offensiveTunnel and distance < minDistance then
      minDistance = distance
    end
  end

  if minDistance < kMinTunnelDistance then
    teamBrain.offensiveTunnelState = kTunnelState.Irrelevant
    if kDebug then Log("Tunnel marked as irrelevant.") end
  end
end

local function PerformCollapseOffensiveTunnel(move, bot, brain, com, action)
  local teamBrain = brain.teamBrain
  local tunnel = Shared_GetEntity(teamBrain.offensiveTunnelId)

  if IsValid(tunnel) and tunnel:GetIsAlive() then
    brain:ExecuteTechId(com, kTechId.TunnelCollapse, tunnel:GetOrigin(), tunnel)
    teamBrain.offensiveTunnelId = nil
    teamBrain.offensiveTunnelPosition = nil
    teamBrain.offensiveTunnelState = kTunnelState.CystReady
    if kDebug then Log("Tunnel has been collapsed.") end
  end
end

local function CollapseOffensiveTunnel(brain, teamBrain, com)
  local position = GetOffensiveCystPosition(teamBrain)

  if not IsPositionSafe(kAlienTeamType, brain, position) then
    return kNilAction
  end

  return {
    name = "CollapseOffensiveTunnel",
    perform = PerformCollapseOffensiveTunnel,
    weight = GetActionWeight(actionTypes.MoveBuilding),
  }
end

function actions.ManageOffensiveTunnel(bot, brain, com)
  -- TODO: Clean this abhorrent mess up. Some of this could be hidden away in
  -- OffensiveTunnel.lua behind a call. All state movement should be right the
  -- fuck out of this file. All multi-state checking could be done with calls.

  local teamBrain = brain.teamBrain

  if teamBrain.offensiveShade then
    local shade = Shared_GetEntity(teamBrain.offensiveShadeId)

    if not IsValid(shade) or not shade:GetIsAlive() then
      if kDebug then Log("Shade lost") end
      teamBrain.offensiveShade = false

      if teamBrain.offensiveTunnelState == kTunnelState.Shaded then
        if kDebug then Log("Reverted to built") end
        teamBrain.offensiveTunnelState = kTunnelState.Built
      end
    end
  end

  if teamBrain.offensiveTunnelState <= kTunnelState.CystReady
      or teamBrain.offensiveTunnelState <= kTunnelState.Irrelevant
      or teamBrain.offensiveTunnelState <= kTunnelState.NewCystReady then
    PrepareOffensiveTunnel(brain, teamBrain)
  end

  if teamBrain.offensiveTunnelState >= kTunnelState.Built
      and not OffensiveTunnelExists(teamBrain) then
    teamBrain.offensiveTunnelState = kTunnelState.Unbuilt
    if kDebug then Log("Tunnel lost") end
  end

  if teamBrain.offensiveTunnelState == kTunnelState.Built
      and Shared_GetTime() >= teamBrain.nextOffensiveShadeTime then
    if not teamBrain.offensiveShade then
      return BuildOffensiveShade(brain, com)
    else
      return MoveOffensiveShade(teamBrain, com)
    end
  end

  if teamBrain.offensiveTunnelState == kTunnelState.NewCystReady then
    return CollapseOffensiveTunnel(brain, teamBrain, com)
  end

  if teamBrain.offensiveTunnelState == kTunnelState.Built
      or teamBrain.offensiveTunnelState == kTunnelState.Shaded then
    CheckTunnelRelevancy(brain, teamBrain)
  end

  return kNilAction
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
