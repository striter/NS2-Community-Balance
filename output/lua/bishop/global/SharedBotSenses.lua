Script.Load("lua/Globals.lua")
Script.Load("lua/bots/BotUtils.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetClearCachedTable = Bishop.lib.table.GetClearCachedTable
local GetClosestMemoryTo = Bishop.utility.GetClosestMemoryTo

local kNearbyRadiusSqr = 20 * 20 -- Distance^2 a target is considered "nearby."

---@param senses BrainSenses
---@param player Player
---@return Entity[]
local function Ent_Players_Alive(senses, player)
  return GetEntitiesAliveForTeam("Player", player:GetTeamNumber())
end

---@param senses BrainSenses
---@param player Player
---@return Entity[]
local function Ent_Teammates_Alive(senses, player)
  local teammates = table.QuickCopy(senses:Get("ent_players_alive"))
  table.removevalue(teammates, player)
  return teammates
end

---@param senses BrainSenses
---@param player Player
---@return Entity[]
local function Ent_Teammates_Nearby(senses, player)
  local nearbyTeammates = GetClearCachedTable(player, "ent_teammates_nearby")
  local i = 1

  ---@param ent Entity
  for _, ent in ipairs(senses:Get("ent_teammates_alive")) do
    if player:GetDistanceSquared(ent) <= kNearbyRadiusSqr then
      nearbyTeammates[i] = ent
      i = i + 1
    end
  end

  return nearbyTeammates
end

---@param senses BrainSenses
---@param player Player
---@return MemoryDistanceSqr
local function Mem_Threat_Nearest(senses, player)
  return GetClosestMemoryTo(player, senses:Get("mem_threats"))
end

---@param senses BrainSenses
---@param player Player
---@return TeamBrain.Memory[]
local function Mem_Threats_Nearby(senses, player)
  local nearbyThreats = GetClearCachedTable(player, "mem_threats_nearby")
  local i = 1

  ---@param mem TeamBrain.Memory
  for _, mem in ipairs(senses:Get("mem_threats")) do
    if player:GetDistanceSquared(mem.lastSeenPos) <= kNearbyRadiusSqr then
      nearbyThreats[i] = mem
      i = i + 1
    end
  end

  return nearbyThreats
end

---@param senses BrainSenses
---@param player Player
---@return integer
local function Per_Outnumbered_Count(senses, player)
  local outnumberedBy = 0

  -- Onos and Exo are considered as two players due to their HP and damage.
  ---@param ent Entity
  for _, ent in ipairs(senses:Get("ent_teammates_nearby")) do
    if ent then
      outnumberedBy = outnumberedBy - 1
      if ent:isa("Exo") or ent:isa("Onos") then
        outnumberedBy = outnumberedBy - 1
      end
    end
  end

  ---@param mem TeamBrain.Memory
  for _, mem in ipairs(senses:Get("mem_threats_nearby")) do
    outnumberedBy = outnumberedBy + 1
    if mem.btype == kMinimapBlipType.Exo
        or mem.btype == kMinimapBlipType.Onos then
      outnumberedBy = outnumberedBy + 1
    end
  end

  return outnumberedBy
end

---@param senses BrainSenses
function Bishop.global.PopulateSharedBotSenses(senses)
  senses:Add("ent_players_alive", Ent_Players_Alive)
  senses:Add("ent_teammates_alive", Ent_Teammates_Alive)
  senses:Add("ent_teammates_nearby", Ent_Teammates_Nearby)
  senses:Add("mem_threat_nearest", Mem_Threat_Nearest)
  senses:Add("mem_threats_nearby", Mem_Threats_Nearby)
  senses:Add("per_outnumbered_count", Per_Outnumbered_Count)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
