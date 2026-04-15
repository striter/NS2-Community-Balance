Script.Load("lua/Entity.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/Table.lua")
Script.Load("lua/bots/BotUtils.lua")
Script.Load("lua/bots/CommonAlienActions.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/alien/Lifeform.lua")
Script.Load("lua/bishop/alien/Retreat.lua")
Script.Load("lua/bishop/global/SharedBotSenses.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.alien.sharedSenses = {}

local FilterEntitiesArray = FilterEntitiesArray
local GetEntitiesAliveForTeam = GetEntitiesAliveForTeam
local GetMinTableEntry = GetMinTableEntry
local GetTunnelDistanceForAlien = GetTunnelDistanceForAlien
local ipairs = ipairs
local kAlienTeamType = kAlienTeamType
local select = select
local table_insert = table.insert
local table_removevalue = table.removevalue

local GetClosestEntityTo = Bishop.lib.entity.GetClosestEntityTo
local GetCurrentLifeform = Bishop.alien.lifeform.GetCurrentLifeform
local GetRetreatHealth = Bishop.alien.retreat.GetRetreatHealth

local kWithinHiveDistance = 30 -- Distance considered within a Hive room.

---@class EntityMoveDistance
---@field entity Entity|nil
---@field moveDistance number|nil

---@param alien Player
---@param entities table
---@return EntityMoveDistance
local function GetClosestTunnelEntityTo(alien, entities)
  local minDistance = math.huge
  local closestEntity

  for _, ent in ipairs(entities) do
    if ent then
      local _, distance = GetTunnelDistanceForAlien(alien, ent)
      local distanceSqr = alien:GetDistanceSquared(ent)
      if distance < minDistance then
        minDistance = distance
        closestEntity = ent
      end
    end
  end

  return {
    entity = closestEntity,
    moveDistance = closestEntity and minDistance or nil
  }
end

--------------------------------------------------------------------------------
-- Retrieve the nearest Gorge and its distance.
--------------------------------------------------------------------------------
-- Used to provide an alternate retreat target to a Hive.

local function NearestGorge(senses, alien)
  local gorges = GetEntitiesAliveForTeam("Gorge", kAlienTeamType)
  table_removevalue(gorges, alien)

  local distance, gorge = GetMinTableEntry(gorges,
    function(gorge)
      return select(2, GetTunnelDistanceForAlien(alien, gorge))
    end)

  return {
    entity = gorge,
    distance = distance
  }
end

--------------------------------------------------------------------------------
-- Retrieve the nearest Hive and its distance.
--------------------------------------------------------------------------------
-- The Lerk, Gorge and Fade version of "nearestHive" returned the entity under
-- "hive" instead of "entity", causing a nil hive with the shared retreat
-- objective. The temporary workaround is to just return both.

local function NearestHive(senses, alien)
  local hives = GetEntitiesAliveForTeam("Hive", kAlienTeamType)
  local builtHives = {}

  for _, hive in ipairs(hives) do
    if hive:GetIsBuilt() then
      table_insert(builtHives, hive)
    end
  end

  local distance, hive = GetMinTableEntry(builtHives,
    function(hive)
      return select(2, GetTunnelDistanceForAlien(alien, hive))
    end)

  return {
    entity = hive,
    hive = hive,
    distance = distance
  }
end

--------------------------------------------------------------------------------
-- Retrieve the nearest Hive, including ones that aren't built.
--------------------------------------------------------------------------------
-- This can be used as a fallback incase the only remaining Hive is still under
-- construction.

local function NearestHiveAll(senses, alien)
  local hives = GetEntitiesAliveForTeam("Hive", kAlienTeamType)

  local distance, hive = GetMinTableEntry(hives,
    function(hive)
      return select(2, GetTunnelDistanceForAlien(alien, hive))
    end)

  return {
    entity = hive,
    hive = hive,
    distance = distance
  }
end

---@param senses BrainSenses
---@param alien Player
---@return EntityDistanceSqr
local function Ent_Hive_Nearest(senses, alien)
  return GetClosestEntityTo(alien, senses:Get("ent_hives_alive"))
end

---@param senses BrainSenses
---@param alien Player
---@return EntityDistanceSqr
local function Ent_Hive_NearestBuilt(senses, alien)
  return GetClosestEntityTo(alien, senses:Get("ent_hives_built"))
end

---@param senses BrainSenses
---@param alien Player
---@return EntityMoveDistance
local function Ent_Hive_NearestBuiltMove(senses, alien)
  return GetClosestTunnelEntityTo(alien, senses:Get("ent_hives_built"))
end

---@param senses BrainSenses
---@param alien Player
local function Ent_Hives_Alive(senses, alien)
  return GetEntitiesAliveForTeam("Hive", alien:GetTeamNumber())
end

---@param senses BrainSenses
---@param alien Player
local function Ent_Hives_Built(senses, alien)
  local builtFilter = Lambda [=[args ent; ent:GetIsBuilt()]=]
  return FilterEntitiesArray(senses:Get("ent_hives_alive"), builtFilter)
end

---@param senses BrainSenses
---@param alien Player
local function Ent_Teammate_Nearest(senses, alien)
  local teammates = senses:Get("ent_teammates_alive")
  return GetClosestEntityTo(alien, teammates)
end

---Perception of danger based on health and surrounding situation.
---@param senses BrainSenses
---@param alien Player
---@return boolean
local function Per_Danger(senses, alien)
  local health = alien:GetHealthScalar()
  local nearestHive = senses:Get("ent_hive_nearestBuiltMove")

  -- Disable any perception of danger if there is no Hive to retreat to.
  if not nearestHive.entity then
    return false
  end

  local outnumberedBy = nearestHive.moveDistance > kWithinHiveDistance and
    senses:Get("per_outnumbered_count") or 0
  return health < GetRetreatHealth(GetCurrentLifeform(alien), outnumberedBy)
end

--------------------------------------------------------------------------------
-- Retrieve the nearest threat by physical distance.
--------------------------------------------------------------------------------
-- Some of the lifeforms had "nearestThreat" senses that used the tunnel
-- distance instead of the physical distance. This was blocking evolution when
-- marines were near the other end of a tunnel.

local function NearestThreat(senses, alien)
  local position = alien:GetOrigin()
  local threats = senses:Get("allThreats")
  
  local distance, memory = GetMinTableEntry(threats,
    function(memory)
      return position:GetDistance(memory.lastSeenPos)
    end)

  return {
    distance = distance,
    memory = memory
  }
end

---@param senses BrainSenses
function Bishop.alien.PopulateSharedSenses(senses)
  Bishop.global.PopulateSharedBotSenses(senses)

  senses:Add("ent_hive_nearest", Ent_Hive_Nearest)
  senses:Add("ent_hive_nearestBuilt", Ent_Hive_NearestBuilt)
  senses:Add("ent_hive_nearestBuiltMove", Ent_Hive_NearestBuiltMove)
  senses:Add("ent_hives_alive", Ent_Hives_Alive)
  senses:Add("ent_hives_built", Ent_Hives_Built)
  senses:Add("ent_teammate_nearest", Ent_Teammate_Nearest)
  senses:Add("per_danger", Per_Danger)
  senses:Add("nearestGorge", NearestGorge)
  senses:Add("nearestHive", NearestHive)
  senses:Add("nearestHiveAll", NearestHiveAll)
  senses:Add("nearestThreat", NearestThreat)
end

-- TODO: Can't remove these until Lerk has been sorted out.
Bishop.alien.sharedSenses.NearestGorge = NearestGorge
Bishop.alien.sharedSenses.NearestHive = NearestHive
Bishop.alien.sharedSenses.NearestHiveAll = NearestHiveAll
Bishop.alien.sharedSenses.NearestThreat = NearestThreat

Bishop.debug.FileExit(debug.getinfo(1, "S"))
