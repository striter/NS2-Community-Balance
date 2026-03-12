Script.Load("lua/Balance.lua")
Script.Load("lua/Cyst.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")
Script.Load("lua/Table.lua")
Script.Load("lua/TechTreeConstants.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/aliencom/OffensiveTunnel.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetCystPoints = GetCystPoints
local GetIsPointOnInfestation = GetIsPointOnInfestation
local GetLocationForPoint = GetLocationForPoint
local ipairs = ipairs
local Shared_GetTime = Shared.GetTime
local table_addtable = table.addtable

local GetActionWeight = Bishop.alienCom.GetActionWeight
local GetOffensiveCystPosition =
  Bishop.alienCom.offensiveTunnel.GetOffensiveCystPosition
local LogOT = Bishop.debug.OffensiveTunnelLog
local TraceBuildPosition = Bishop.utility.TraceBuildPosition

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kMaxCystedResPoints = 2          -- Maximum cysts to empty resource nodes.
local kMaxCystedTechPoints = 1         -- Maximum cysts to empty tech points.
local kTimeBetweenCysts = 8            -- Cooldown after successful placement.

local kOffensiveTunnelMaxAttempts = 10 -- Reset tunnel if placement fails.
local kOffensiveTunnelRadius = 4       -- Radius around requested position.

local kCystRadius = 6                  -- Default cyst radius around buildings.
local kCystRadiusHarvester = 2         -- Radius override for Harvesters.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local actionTypes = Bishop.alienCom.actionTypes
local kAlienTeamType = kAlienTeamType
local kDebugTun = Bishop.debug.offensiveTunnel
local kHarvesterCost = kHarvesterCost
local kNilAction = Bishop.lib.constants.kNilAction
local kTechId_Cyst = kTechId.Cyst
local kTunnelState = Bishop.alienCom.offensiveTunnel.kTunnelState

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

local function IsBuildingCysted(building)
  return GetIsPointOnInfestation(building:GetOrigin())
end

local function IsCystChainSafe(brain, cystChain)
  local lastTestedLocation = ""

  for _, cyst in ipairs(cystChain) do
    local location = GetLocationForPoint(cyst)
    local locationName = ""

    if location then
      locationName = location:GetName()
    end

    if locationName ~= lastTestedLocation and locationName ~= "" then
      if not brain:GetIsSafeToDropInLocation(locationName, kAlienTeamType) then
        return false
      end

      lastTestedLocation = locationName
    end
  end

  return true
end

local function GetValidCystChain(position, radius, com)
  local buildPosition = TraceBuildPosition(position, radius, radius,
    kTechId_Cyst, "", com)
  if not buildPosition then
    return nil
  end

  local cystChain = GetCystPoints(buildPosition)
  if #cystChain == 0 then
    return nil
  end

  return cystChain
end

local function GetBestSafeCystChain(brain, com, senses, buildings)
  local cystPosition = nil
  local bestCystLength = nil

  for _, building in ipairs(buildings) do
    local position = building:GetOrigin()
    local radius = kCystRadius

    if building:isa("ResourcePoint") then
      radius = kCystRadiusHarvester
    end

    if not GetCystForPoint(senses, position) and not IsBuildingCysted(building)
        then
      local cystChain = GetValidCystChain(position, radius, com)
      
      if cystChain and #cystChain > 0 and IsCystChainSafe(brain, cystChain)
          and (not bestCystLength or #cystChain < bestCystLength) then
        cystPosition = cystChain[#cystChain]
        bestCystLength = #cystChain
      end
    end
  end

  return cystPosition, bestCystLength
end

--------------------------------------------------------------------------------
-- Dropping cysts for Harvesters.
--------------------------------------------------------------------------------

local function PerformBuildCyst(move, bot, brain, com, action)
  brain:ExecuteTechId(com, kTechId_Cyst, action.position, com)
  brain.lastCystBuildTime = Shared_GetTime()
end

function Bishop.alienCom.actions.CystToHarvester(bot, brain, com)
  local senses = brain:GetSenses()
  local nodes = senses:Get("availResPoints")
  local techId = kTechId_Cyst
  local time = Shared_GetTime()
  local resources = com:GetTeamResources()

  if #nodes == 0 or not senses:Get("doableTechIds")[techId]
      or time < brain.lastCystBuildTime + kTimeBetweenCysts
      or #senses:Get("cystedAvailResPoints") >= kMaxCystedResPoints
      or resources < kHarvesterCost then
    return kNilAction
  end

  local cystPosition, length = GetBestSafeCystChain(brain, com, senses, nodes)
  if not cystPosition or resources < length + kHarvesterCost then
    return kNilAction
  end

  return {
    name = "CystToHarvester",
    perform = PerformBuildCyst,
    weight = GetActionWeight(actionTypes.BuildCyst),

    -- Action metadata.
    position = cystPosition
  }
end

--------------------------------------------------------------------------------
-- Dropping cysts for Hives.
--------------------------------------------------------------------------------

function Bishop.alienCom.actions.CystToTechPoint(bot, brain, com)
  local senses = brain:GetSenses()
  local techPoints = senses:Get("availTechPoints")
  local techId = kTechId_Cyst
  local time = Shared_GetTime()

  if #techPoints == 0 or not senses:Get("doableTechIds")[techId]
      or time < brain.lastCystBuildTime + kTimeBetweenCysts
      or #senses:Get("cystedAvailTechPoints") >= kMaxCystedTechPoints then
    return kNilAction
  end

  local cystPosition, length = GetBestSafeCystChain(brain, com, senses,
    techPoints)
  
  if not cystPosition or com:GetTeamResources() < length then
    return kNilAction
  end

  return {
    name = "CystToTechPoint",
    perform = PerformBuildCyst,
    weight = GetActionWeight(actionTypes.BuildCyst),

    -- Action metadata.
    position = cystPosition
  }
end

--------------------------------------------------------------------------------
-- Repair broken cyst chains.
--------------------------------------------------------------------------------
-- Vanilla waits until the building has lost its cyst and is being damaged. This
-- is often too late.

function Bishop.alienCom.actions.RecystBuilding(bot, brain, com)
  local senses = brain:GetSenses()
  local techId = kTechId_Cyst
  local time = Shared_GetTime()

  if not senses:Get("doableTechIds")[techId]
      or time < brain.lastCystBuildTime + kTimeBetweenCysts then
    return kNilAction
  end

  local buildings = {}
  table_addtable(senses:Get("harvesters"), buildings)
  table_addtable(senses:Get("allTunnelEntrances"), buildings)

  local cystPosition = nil
  local length = nil

  for _, building in ipairs(buildings) do
    local position = building:GetOrigin()
    local cyst = GetCystForPoint(senses, position)

    if not IsBuildingCysted(building)
        or (cyst and not cyst:GetIsActuallyConnected()) then
      local cystChain

      if cyst then
        cystChain = GetCystPoints(cyst:GetOrigin())
      else
        cystChain = GetValidCystChain(position, kCystRadiusHarvester, com)
      end

      if cystChain and #cystChain > 0 and IsCystChainSafe(brain, cystChain) then
        cystPosition = cystChain[#cystChain]
        length = #cystChain
        break
      end
    end
  end
  
  if not cystPosition or com:GetTeamResources() < length then
    return kNilAction
  end

  return {
    name = "RecystBuilding",
    perform = PerformBuildCyst,
    weight = GetActionWeight(actionTypes.BuildCyst),

    -- Action metadata.
    position = cystPosition
  }
end

--------------------------------------------------------------------------------
-- Manual cyst drops.
--------------------------------------------------------------------------------
-- For cysts requested by other parts of the codebase, currently used only for
-- offensive tunnels.

local function PerformBuildCystRequest(move, bot, brain, com, action)
  local position = action.position
  local teamBrain = brain.teamBrain

  brain:ExecuteTechId(com, kTechId_Cyst, position, com)
  brain.lastCystBuildTime = Shared_GetTime()
  local cysts = GetEntitiesWithinRange("Cyst", position, 5)

  if (#cysts ~= 0) then
    teamBrain.offensiveTunnelCystId = cysts[1]:GetId()
    teamBrain.offensiveTunnelCystPosition = position
    if teamBrain.offensiveTunnelState == kTunnelState.CystRequested then
      teamBrain.offensiveTunnelState = kTunnelState.CystReady
    else
      teamBrain.offensiveTunnelState = kTunnelState.NewCystReady
    end
    if kDebugTun then LogOT("Cyst has been placed.") end
  else
    Bishop.Error("PerformBuildCystRequest couldn't locate its cyst.")
  end
end

function Bishop.alienCom.actions.CystToRequest(bot, brain, com)
  local senses = brain:GetSenses()
  local teamBrain = brain.teamBrain
  local techId = kTechId_Cyst

  if teamBrain.offensiveTunnelState ~= kTunnelState.CystRequested
      and teamBrain.offensiveTunnelState ~= kTunnelState.NewCystRequested then
    return kNilAction
  end

  local position = GetOffensiveCystPosition(teamBrain)
  local time = Shared_GetTime()
  local cyst = GetCystForPoint(senses, position)

  if cyst then
    teamBrain.offensiveTunnelCystId = cyst:GetId()
    teamBrain.offensiveTunnelCystPosition = cyst:GetOrigin()

    if teamBrain.offensiveTunnelState == kTunnelState.CystRequested then
      teamBrain.offensiveTunnelState = kTunnelState.CystReady
    else
      teamBrain.offensiveTunnelState = kTunnelState.NewCystReady
    end
    if kDebugTun then LogOT("Existing cyst reused.") end
    return kNilAction
  end

  if not senses:Get("doableTechIds")[techId]
      or time < brain.lastCystBuildTime + kTimeBetweenCysts
      or time < brain.nextOffensiveCystAttempt then
    return kNilAction
  end

  local cystChain = GetValidCystChain(position, kOffensiveTunnelRadius, com)
  local cystPosition
  local length

  if cystChain and #cystChain > 0 and IsCystChainSafe(brain, cystChain) then
    cystPosition = cystChain[#cystChain]
    length = #cystChain
  end

  if not cystPosition then
    teamBrain.offensiveTunnelAttempts = teamBrain.offensiveTunnelAttempts + 1

    if teamBrain.offensiveTunnelAttempts >= kOffensiveTunnelMaxAttempts then
      if teamBrain.offensiveTunnelState == kTunnelState.CystRequested then
        teamBrain.offensiveTunnelState = kTunnelState.Unbuilt
        if kDebugTun then LogOT("Area is unsafe, reverting to unbuilt.") end
      else
        teamBrain.offensiveTunnelState = kTunnelState.Irrelevant
        if kDebugTun then LogOT("Area is unsafe, reverting to irrelevant.") end
      end
    end
  end
  
  if not cystPosition or com:GetTeamResources() < length then
    return kNilAction
  end

  return {
    name = "CystToRequest",
    perform = PerformBuildCystRequest,
    weight = GetActionWeight(actionTypes.BuildCyst),

    -- Action metadata.
    position = cystPosition
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
