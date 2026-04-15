Script.Load("lua/Balance.lua")
Script.Load("lua/Entity.lua")
Script.Load("lua/TechTreeConstants.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetEntitiesForTeamByLocation = GetEntitiesForTeamByLocation
local ipairs = ipairs

local GetActionWeight = Bishop.marineCom.GetActionWeight
local IsTechStarted = Bishop.utility.IsTechStarted
local TraceBuildPosition = Bishop.utility.TraceBuildPosition

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kMinBuildDistance = 5  -- Min radius from tech point.
local kMaxBuildDistance = 15 -- Max radius from tech point.

local kExtractorPenalty = 3  -- Apply a resource penalty if <= #extractors.
local kMaxObservatories = 2  -- Doesn't include the observatory via research.
local kMinResources = 10     -- Don't construct beyond Phase Gate below res.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kActionTypes = Bishop.marineCom.kActionTypes
local kExtractorCost = kExtractorCost
local kPhaseGateCost = kPhaseGateCost
local kNilAction = Bishop.lib.constants.kNilAction
local kTechId = kTechId

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

local function IsBuildingInLocation(buildingClass, locationId, teamNumber)
  return #GetEntitiesForTeamByLocation(buildingClass, teamNumber, locationId)
    > 0
end

local function GetBuildPositionAtTechPoint(com, senses, techId, preReq)
  local team = com:GetTeamNumber()
  local buildClass = kTechId[techId]
  local techPoints = senses:Get("safeTechPoints")

  for _, techPoint in ipairs(techPoints) do
    local locationId = techPoint:GetLocationId()
    local locationName = techPoint:GetLocationName()

    if (not preReq or IsBuildingInLocation(preReq, locationId, team))
        and not IsBuildingInLocation(buildClass, locationId, team) then
      if techId == kTechId.CommandStation then
        return techPoint:GetOrigin()
      end

      return TraceBuildPosition(techPoint:GetOrigin(), kMinBuildDistance,
        kMaxBuildDistance, techId, locationName, com)
    end
  end

  return nil
end

--------------------------------------------------------------------------------
-- Construction specific to the "main" base.
--------------------------------------------------------------------------------

function Bishop.marineCom.actions.BuildInfantryPortal(bot, brain, com)
  local senses = brain:GetSenses()
  local techId = kTechId.InfantryPortal
  local commandStation = senses:Get("mainCommandStation")
  local teamDead = senses:Get("numDeadPlayers")
  local teamSize = senses:Get("numPlayersForTeam")

  if not senses:Get("doableTechIds")[techId] or not commandStation
      or teamSize == 0 then
    return kNilAction
  end

  local team = com:GetTeamNumber()
  local locationId = commandStation:GetLocationId()
  local maxInfantryPortals = senses:Get("maxInfantryPortals")
  local infantryPortals = #GetEntitiesForTeamByLocation("InfantryPortal",
    team, locationId)
  
  if infantryPortals >= maxInfantryPortals then
    return kNilAction
  end

  local position = nil

  if infantryPortals == 0 or not senses:Get("isEarlyGame")
      or teamDead > teamSize / 2 then
    position = TraceBuildPosition(commandStation:GetOrigin(), kMinBuildDistance,
      kMaxBuildDistance, techId, commandStation:GetLocationName(), com)
  end

  if not position then
    return kNilAction
  end

  return {
    name = "BuildBaseInfantryPortal",
    weight = GetActionWeight(kActionTypes.BuildInfantryPortal),
    perform = function(move, bot, brain, com, action)
      brain:ExecuteTechId(com, techId, position, com)
    end
  }
end

--------------------------------------------------------------------------------
-- Build bases at all secure tech points.
--------------------------------------------------------------------------------
-- Extra emphasis is placed on only using excess resources because building a
-- second base should never come at the expense of research progression or
-- survival.

function Bishop.marineCom.actions.BuildTechPointPhaseGate(bot, brain, com)
  local senses = brain:GetSenses()
  local techId = kTechId.PhaseGate
  local minResources = kPhaseGateCost

  if #senses:Get("extractors") <= kExtractorPenalty then
    minResources = minResources + kExtractorCost
  end

  -- Securing tech points is a high priority, so the resource check is not in
  -- place here unless extractors are low.
  if not senses:Get("doableTechIds")[techId]
      or not senses:Get("mainPhaseGate")
      or com:GetTeamResources() < minResources then
    return kNilAction
  end

  local position = GetBuildPositionAtTechPoint(com, senses, techId)

  if not position then
    return kNilAction
  end

  return {
    name = "BuildTechPointPhaseGate",
    weight = GetActionWeight(kActionTypes.BuildTechPointPhaseGate),
    perform = function(move, bot, brain, com, action)
      brain:ExecuteTechId(com, techId, position, com)
    end
  }
end

function Bishop.marineCom.actions.BuildTechPointArmory(bot, brain, com)
  local senses = brain:GetSenses()
  local techId = kTechId.Armory

  if not senses:Get("doableTechIds")[techId]
      or com:GetTeamResources() < kMinResources then
    return kNilAction
  end

  local position = GetBuildPositionAtTechPoint(com, senses, techId, "PhaseGate")

  if not position then
    return kNilAction
  end

  return {
    name = "BuildTechPointArmory",
    weight = GetActionWeight(kActionTypes.BuildTechPointArmory),
    perform = function(move, bot, brain, com, action)
      brain:ExecuteTechId(com, techId, position, com)
    end
  }
end

function Bishop.marineCom.actions.BuildTechPointCommandStation(bot, brain, com)
  local senses = brain:GetSenses()
  local techId = kTechId.CommandStation

  if not senses:Get("doableTechIds")[techId]
      or com:GetTeamResources() < kMinResources
      or not IsTechStarted(com, kTechId.Armor2)
      or not IsTechStarted(com, kTechId.Weapons1) then
    return kNilAction
  end

  local position = GetBuildPositionAtTechPoint(com, senses, techId, "PhaseGate")

  if not position then
    return kNilAction
  end

  return {
    name = "BuildTechPointCommandStation",
    weight = GetActionWeight(kActionTypes.BuildTechPointCommandStation),
    perform = function(move, bot, brain, com, action)
      brain:ExecuteTechId(com, techId, position, com)
    end
  }
end

function Bishop.marineCom.actions.BuildTechPointObservatory(bot, brain, com)
  local senses = brain:GetSenses()
  local techId = kTechId.Observatory

  if not senses:Get("doableTechIds")[techId]
      or #senses:Get("forwardObservatories") >= kMaxObservatories
      or com:GetTeamResources() < kMinResources then
    return kNilAction
  end

  local position = GetBuildPositionAtTechPoint(com, senses, techId,
    "CommandStation")

  if not position then
    return kNilAction
  end

  return {
    name = "BuildTechPointObservatory",
    weight = GetActionWeight(kActionTypes.BuildTechPointObservatory),
    perform = function(move, bot, brain, com, action)
      brain:ExecuteTechId(com, techId, position, com)
    end
  }
end

function Bishop.marineCom.actions.BuildTechPointInfantryPortal(bot, brain, com)
  local senses = brain:GetSenses()
  local techId = kTechId.InfantryPortal
  local maxInfantryPortals = senses:Get("maxInfantryPortals")
  local emergency = #senses:Get("infantryPortals") <= 2

  -- This prevents more than two tech points worth of infantry portals being
  -- built. Previously the commander would drop "maxInfantryPortals" at every
  -- held tech point.
  if not senses:Get("doableTechIds")[techId]
      or com:GetTeamResources() < kMinResources
      or #senses:Get("infantryPortals") >= 2 * maxInfantryPortals
      or (senses:Get("gameMinutes") < 11 and not emergency) then
    return kNilAction
  end

  local team = com:GetTeamNumber()
  local techPoints = senses:Get("safeTechPoints")
  local position = nil

  for _, techPoint in ipairs(techPoints) do
    local locationId = techPoint:GetLocationId()
    local infantryPortals = #GetEntitiesForTeamByLocation("InfantryPortal",
      team, locationId)

    if infantryPortals < maxInfantryPortals
        and (IsBuildingInLocation("Observatory", locationId, team)
          or (emergency
          and IsBuildingInLocation("CommandStation", locationId, team)))
        then
      position = TraceBuildPosition(techPoint:GetOrigin(), kMinBuildDistance,
        kMaxBuildDistance, techId, techPoint:GetLocationName(), com)
      break
    end
  end

  if not position then
    return kNilAction
  end

  return {
    name = "BuildTechPointInfantryPortal",
    weight = GetActionWeight(kActionTypes.BuildTechPointInfantryPortal),
    perform = function(move, bot, brain, com, action)
      brain:ExecuteTechId(com, techId, position, com)
    end
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
