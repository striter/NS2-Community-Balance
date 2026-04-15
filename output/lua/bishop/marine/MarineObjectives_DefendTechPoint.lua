Script.Load("lua/Entity.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/bots/LocationContention.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetEntitiesAliveForTeam = GetEntitiesAliveForTeam
local GetEntitiesForTeamByLocation = GetEntitiesForTeamByLocation
local GetLocationContention = GetLocationContention
local Shared_GetTime = Shared.GetTime

local GetMarineMoveFunction = Bishop.utility.GetMarineMoveFunction

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kCompletionRadiusSqr = 7 * 7 -- Radius from command chair to complete.
local kCriticalDamage      = 0.65  -- Structures below this HP are in danger.
local kTimeout             = 10    -- Expiry time to reconsider objectives.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kMarineTeamType = kMarineTeamType
local kMaxTechPoints = 4
local kNilAction = Bishop.lib.constants.kNilAction

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

local function AliensPresentAtLocation(locationName)
  local locationGroup = GetLocationContention():GetLocationGroup(locationName)
  if not locationGroup or locationGroup:GetNumAlienPlayers() <= 0 then
    return false
  end
  return true
end

local function TechPointVulnerable(commandStation, numCommandStations)
  if not AliensPresentAtLocation(commandStation:GetLocationName()) then
    return false
  end

  -- Alien presence at a Tech Point without an Observatory, Phase Gate, or an
  -- Observatory, Phase Gate or Command Station about to be destroyed are
  -- considered high priority.
  -- The Observatory check is ignored when marines hold four Tech Points,
  -- because the 4th Tech Point will not have an Observatory.
  local observatories = GetEntitiesForTeamByLocation("Observatory",
    kMarineTeamType, commandStation:GetLocationId())
  local phaseGates = GetEntitiesForTeamByLocation("PhaseGate", kMarineTeamType,
    commandStation:GetLocationId())
  local checkObs = numCommandStations < kMaxTechPoints
  if (checkObs and #observatories <= 0)
      or #phaseGates <= 0
      or (checkObs and observatories[1]:GetArmorScalar() < kCriticalDamage
        and observatories[1]:GetIsUnderFire())
      or (phaseGates[1]:GetArmorScalar() < kCriticalDamage
        and phaseGates[1]:GetIsUnderFire())
      or (commandStation:GetArmorScalar() < kCriticalDamage
        and commandStation:GetIsUnderFire()) then
    return true
  end
  return false
end

--------------------------------------------------------------------------------
-- Rush to the defence of a Tech Point when vulnerable.
--------------------------------------------------------------------------------
-- The #1 cause of marine bots losing Tech Points are the Infantry Portals or
-- Observatory going down, whilst the rest of the team ignore its destruction.
-- This objective ensures marines attempt a rushed defence when in these
-- situations.

local function PerformDefendTechPoint(move, bot, brain, marine, action)
  local distanceSqr = marine:GetOrigin():GetDistanceSquared(action.position)
  if distanceSqr <= kCompletionRadiusSqr
      or Shared_GetTime() >= action.expires then
    return true
  end

  GetMarineMoveFunction(marine)
    (marine:GetOrigin(), action.position, bot, brain, move)
end

local function ValidateDefendTechPoint(bot, brain, marine, action)
  return true
end

function Bishop.marine.objectives.DefendTechPoint(bot, brain, marine)
  local commandStations = GetEntitiesAliveForTeam("CommandStation",
    kMarineTeamType)
  for _, commandStation in ipairs(commandStations) do
    if TechPointVulnerable(commandStation, #commandStations) then
      return {
        name = "DefendTechPoint",
        perform = PerformDefendTechPoint,
        validate = ValidateDefendTechPoint,
        weight = 1, -- Weight per class.

        -- Objective metadata.
        expires = Shared_GetTime() + kTimeout,
        position = commandStation:GetOrigin()
      }
    end
  end

  return kNilAction
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
