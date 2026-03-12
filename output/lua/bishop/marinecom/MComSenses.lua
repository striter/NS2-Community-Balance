Script.Load("lua/Entity.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/Table.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/bots/BotUtils.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/marine/MarineSharedSenses.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetEnemyTeamNumber = GetEnemyTeamNumber
local GetEntitiesAliveForTeam = GetEntitiesAliveForTeam
local GetEntitiesAliveForTeamByLocation = GetEntitiesAliveForTeamByLocation
local GetMinDistToEntities = GetMinDistToEntities
local ipairs = ipairs
local Shared_GetStringIndex = Shared.GetStringIndex
local table_addtable = table.addtable

local IsTechStarted = Bishop.utility.IsTechStarted

local kMarineTeamType = kMarineTeamType
local kTechId = kTechId

--------------------------------------------------------------------------------
-- Add a sense that returns all enemy hives.
--------------------------------------------------------------------------------
-- This may seem cheaty at a glance, but realistically all human players know
-- which hives are up pretty quickly anyway.
-- FUTURE: Is there a realistic way to stop them from cheating? This is used
-- within the OffensivePhaseGate and Scan actions.

local function EnemyHives(senses)
  return GetEntitiesAliveForTeam("Hive",
    GetEnemyTeamNumber(senses.bot:GetTeamNumber()))
end

--------------------------------------------------------------------------------
-- Add a sense that determines the closest hive to a marine.
--------------------------------------------------------------------------------
-- ARC turrets are included to ensure correct scan behaviour.

local function ClosestHiveToMarines(senses)
  local hives = senses:Get("enemyHives")
  local marines = senses:Get("marines")
  table_addtable(GetEntitiesAliveForTeam("ARC", kMarineTeamType), marines)
  local closestHive
  local closestDistance

  for _, hive in ipairs(hives) do
    local distance = GetMinDistToEntities(hive, marines)

    if not closestDistance or distance < closestDistance then
      closestHive = hive
      closestDistance = distance
    end
  end

  return {
    hive = closestHive,
    distance = closestDistance
  }
end

--------------------------------------------------------------------------------
-- Sense for base robotics factory.
--------------------------------------------------------------------------------

local function MainRoboticsFactory(senses)
  local locationId = Shared_GetStringIndex(
    senses.bot.brain:GetStartingTechPoint() or "")
  local roboticsFactories = GetEntitiesAliveForTeamByLocation("RoboticsFactory",
    senses.bot:GetTeamNumber(), locationId)
  
  if #roboticsFactories == 0 then
      return nil
  end

  return roboticsFactories[1]
end

local function MainARCRoboticsFactory(senses)
  local locationId = Shared_GetStringIndex(senses.bot.brain:GetStartingTechPoint() or "")
  local arcRoboticsFactories = GetEntitiesAliveForTeamByLocationWithTechId("RoboticsFactory", senses.bot:GetTeamNumber(), locationId, kTechId.ARCRoboticsFactory)

  if #arcRoboticsFactories == 0 then
    return nil
  end

  return arcRoboticsFactories[1]
end

--------------------------------------------------------------------------------
-- Senses to get sentries and batteries.
--------------------------------------------------------------------------------

local function AllSentries(senses)
  return GetEntitiesAliveForTeam("Sentry", kMarineTeamType)
end

local function AllSentryBatteries(senses)
  return GetEntitiesAliveForTeam("SentryBattery", kMarineTeamType)
end

local function AllSentryEquipment(senses)
  local result = {}
  table_addtable(senses:Get("allSentries"), result)
  table_addtable(senses:Get("allSentryBatteries"), result)
  return result
end

---@param senses BrainSenses
---@param com Player
local function NumExtractorsForRoundTime(senses, com)
  local teamBrain = senses.bot.brain.teamBrain

  if teamBrain.earlyGameFinished then
    return 1000
  elseif not IsTechStarted(com, kTechId.Armor1) then
    return 3 -- Spawn plus naturals.
  elseif IsTechStarted(com, kTechId.Armor2)
      or IsTechStarted(com, kTechId.Weapons1) then
    teamBrain.earlyGameFinished = true
  end

  return 4 -- Spawn plus naturals plus 1.
end

--------------------------------------------------------------------------------
-- Apply all the above functions to the sense DB.
--------------------------------------------------------------------------------

local OldCreateMarineComSenses = CreateMarineComSenses

function CreateMarineComSenses()
  local senses = OldCreateMarineComSenses()
  Bishop.marine.PopulateSharedSenses(senses)

  senses:Add("enemyHives", EnemyHives)
  senses:Add("closestHiveToMarines", ClosestHiveToMarines)
  senses:Add("mainRoboticsFactory", MainRoboticsFactory)
  senses:Add("mainARCRoboticsFactory", MainARCRoboticsFactory)
  senses:Add("allSentries", AllSentries)
  senses:Add("allSentryBatteries", AllSentryBatteries)
  senses:Add("allSentryEquipment", AllSentryEquipment)
  senses:Add("numExtractorsForRoundTime", NumExtractorsForRoundTime)

  return senses
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
