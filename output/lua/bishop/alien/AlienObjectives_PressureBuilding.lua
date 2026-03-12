Script.Load("lua/Globals.lua")
Script.Load("lua/Table.lua")
Script.Load("lua/Utility.lua")
Script.Load("lua/bots/BotUtils.lua")
Script.Load("lua/bots/CommonAlienActions.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/alien/Lifeform.lua")
Script.Load("lua/bishop/alien/Pack.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetTunnelDistanceForAlien = GetTunnelDistanceForAlien
local kAlienTeamType = kAlienTeamType
local select = select
local table_random = table.random

local GetCurrentLifeform = Bishop.alien.lifeform.GetCurrentLifeform
local GetMoveFunction = Bishop.utility.GetMoveFunction
local kNilAction = Bishop.lib.constants.kNilAction
local LeavePack = Bishop.alien.pack.LeavePack
local SearchMemoriesForAny = Bishop.utility.SearchMemoriesForAny
local sharedObjectives = Bishop.alien.objectives

--------------------------------------------------------------------------------
-- Balance values and function constants.
--------------------------------------------------------------------------------

-- Building types to consider pressuring.
local kBuildingTypes = {
  kMinimapBlipType.Extractor,
  kMinimapBlipType.InfantryPortal,
  kMinimapBlipType.PhaseGate,
  kMinimapBlipType.Armory,
  kMinimapBlipType.AdvancedArmory,
  kMinimapBlipType.Observatory,
  kMinimapBlipType.CommandStation,
  kMinimapBlipType.SentryBattery,
  kMinimapBlipType.Sentry
}

local kMaxDistanceToComplete = 5 -- Distance to flag completion.
local kResourceLimit = 70        -- Force Skulk completion if taking too long.

--------------------------------------------------------------------------------
-- Select an enemy building from known buildings.
--------------------------------------------------------------------------------
-- This reduces the chance of aliens aimlessly wandering the map if they know
-- about an enemy building.

local function PerformPressureBuilding(move, bot, brain, alien, action)
  -- Skulks can drop their pack to harass marine tech.
  if alien:isa("Skulk") then
    -- Drop this objective if the Skulk is ignoring its evolution path.
    if alien:GetPersonalResources() > kResourceLimit then
      brain.packLock = false
      return true
    end
    brain.packLock = true
    if brain.pack then
      LeavePack(brain)
    end
  end
  local distance = select(2, GetTunnelDistanceForAlien(alien, action.origin))

  if distance <= kMaxDistanceToComplete then
    brain.packLock = false
    return true
  end

  brain.teamBrain:AssignPlayerToEntity(alien, "pressure-" .. action.entityId)
  bot:GetMotion():SetDesiredViewTarget()
  action.Move(alien:GetEyePos(), action.origin, bot, brain, move)
end

local function ValidatePressureBuilding(bot, brain, alien, action)
  return true
end

function sharedObjectives.PressureBuilding(bot, brain, alien)
  local targets = SearchMemoriesForAny(kAlienTeamType, kBuildingTypes)
  local selectedMemory = table_random(targets)
  brain.packLock = false

  -- Don't allow roaming if an evolution is required.
  if alien:isa("Skulk") and alien:GetPersonalResources() > kResourceLimit then
    return kNilAction
  end

  if not selectedMemory then
    return kNilAction
  end

  if brain.teamBrain:GetNumOthersAssignedToEntity(alien,
      "pressure-" .. selectedMemory.entId) > 0 then
    return kNilAction
  end

  return {
    name = "PressureBuilding",
    perform = PerformPressureBuilding,
    validate = ValidatePressureBuilding,
    weight = 1, -- Override per lifeform.

    -- Objective metadata.
    entityId = selectedMemory.entId,
    Move = GetMoveFunction(GetCurrentLifeform(alien)),
    origin = selectedMemory.lastSeenPos
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
