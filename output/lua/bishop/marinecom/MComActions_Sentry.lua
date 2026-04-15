Script.Load("lua/Entity.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/SentryBattery.lua")
Script.Load("lua/Table.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/Utility.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetEntitiesForTeamByLocation = GetEntitiesForTeamByLocation
local GetEntitiesWithinRange = GetEntitiesWithinRange
local GetYawFromVector = GetYawFromVector
local ipairs = ipairs
local IsValid = IsValid
local table_insert = table.insert
local table_random = table.random

local GetActionWeight = Bishop.marineCom.GetActionWeight
local TraceBuildPosition = Bishop.utility.TraceBuildPosition

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kMaxBatteryDistance = 15 -- Max battery distance from Phase Gate.
local kMinBatteryDistance = 4  -- Min battery distance from Phase Gate.
local kMaxSentryDistance = SentryBattery.kRange * 0.98 -- Distance from battery.
local kMinSentryDistance = SentryBattery.kRange * 0.8  -- Distance from battery.
local kMinSpacing = 2.75       -- Min turret distance from other turrets.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kActionTypes = Bishop.marineCom.kActionTypes
local kMarineTeamType = kMarineTeamType
local kNilAction = Bishop.lib.constants.kNilAction
local kTechId = kTechId

--------------------------------------------------------------------------------
-- Build a battery and sentries at a secured tech point.
--------------------------------------------------------------------------------

local function PerformBuildSentryBattery(move, bot, brain, com, action)
  brain:ExecuteTechId(com, kTechId.SentryBattery, action.position, com)
end

function Bishop.marineCom.actions.BuildSentryBattery(bot, brain, com)
  local senses = brain:GetSenses()
  if senses:Get("mainARCRoboticsFactory")
      or #senses:Get("allSentryBatteries") > 0
      or not senses:Get("doableTechIds")[kTechId.SentryBattery] then
    return kNilAction
  end

  local techPoints = senses:Get("safeTechPoints")
  local safeGates = {}
  for _, techPoint in ipairs(techPoints) do
    local phaseGates = GetEntitiesForTeamByLocation("PhaseGate",
      kMarineTeamType, techPoint:GetLocationId())
    if #phaseGates > 0 then
      table_insert(safeGates, phaseGates[1])
    end
  end

  local phaseGate = table_random(safeGates)
  if not phaseGate then
    return kNilAction
  end

  local position = TraceBuildPosition(phaseGate:GetOrigin(),
    kMinBatteryDistance, kMaxBatteryDistance, kTechId.SentryBattery,
    phaseGate:GetLocationName(), com)
  if not position then
    return kNilAction
  end

  return {
    name = "BuildSentryBattery",
    weight = GetActionWeight(kActionTypes.BuildSentryBattery),
    perform = PerformBuildSentryBattery,

    -- Action metadata.
    position = position
  }
end

local function PerformBuildSentry(move, bot, brain, com, action)
  brain:ExecuteTechId(com, kTechId.Sentry, action.position, com, nil, nil,
    action.angle)
end

function Bishop.marineCom.actions.BuildSentry(bot, brain, com)
  local senses = brain:GetSenses()
  local batteries = senses:Get("allSentryBatteries")
  local sentries = senses:Get("allSentries")

  if senses:Get("mainARCRoboticsFactory")
      or #batteries <= 0
      or #sentries >= #batteries * 3
      or not senses:Get("doableTechIds")[kTechId.Sentry] then
    return kNilAction
  end

  local battery = table.random(batteries)
  local position = TraceBuildPosition(battery:GetOrigin(), kMinSentryDistance,
    kMaxSentryDistance, kTechId.Sentry, battery:GetLocationName(), com)
  if not position
      or #GetEntitiesWithinRange("Sentry", position, kMinSpacing) > 0 then
    return kNilAction
  end

  return {
    name = "BuildSentry",
    weight = GetActionWeight(kActionTypes.BuildSentry),
    perform = PerformBuildSentry,

    -- Action metadata.
    angle = GetYawFromVector(battery:GetOrigin() - position),
    position = position
  }
end

--------------------------------------------------------------------------------
-- Recycle sentries once an ARC Factory is ready.
--------------------------------------------------------------------------------

local function PerformRecycleSentries(move, bot, brain, com, action)
  if not IsValid(action.entity) then
    return
  end

  brain:ExecuteTechId(com, kTechId.Recycle, action.entity:GetOrigin(),
    action.entity, action.entity:GetId())
end

function Bishop.marineCom.actions.RecycleSentries(bot, brain, com)
  local senses = brain:GetSenses()
  if not senses:Get("mainARCRoboticsFactory") then
    return kNilAction
  end

  local recycleEntities = senses:Get("allSentryEquipment")
  if #recycleEntities <= 0 or recycleEntities[1]:GetIsRecycling() then
    return kNilAction
  end

  return {
    name = "RecycleSentries",
    weight = GetActionWeight(kActionTypes.RecycleSentries),
    perform = PerformRecycleSentries,

    -- Action metadata.
    entity = recycleEntities[1]
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
