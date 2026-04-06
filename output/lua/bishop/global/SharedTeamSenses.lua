Script.Load("lua/Globals.lua")
Script.Load("lua/bots/BotUtils.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local FilterTable = FilterTable
local GetTeamMemories = GetTeamMemories
local ipairs = ipairs
local kMinimapBlipType = kMinimapBlipType

---@param mem TeamBrain.Memory
local function IsMemoryTypePassive(mem)
  local type = mem.btype
  return not ((type >= kMinimapBlipType.Marine and type <= kMinimapBlipType.Gorge) 
    or type == kMinimapBlipType.Sentry
    or type == kMinimapBlipType.Prowler or type == kMinimapBlipType.Vokex
    or type == kMinimapBlipType.Whip or type == kMinimapBlipType.Hydra
    or type == kMinimapBlipType.Drifter)
end

---@param mem TeamBrain.Memory
local function IsMemoryTypeStructure(mem)
  local type = mem.btype
  return (type >= kMinimapBlipType.Sentry and type <= kMinimapBlipType.BoneWall)
    or type == kMinimapBlipType.PowerPoint
    or type == kMinimapBlipType.SentryBattery
end

---@param mem TeamBrain.Memory
local function IsMemoryTypeThreat(mem)
  return not IsMemoryTypePassive(mem)
end

---@param mem TeamBrain.Memory
local function IsMemoryTypeUnit(mem)
  local type = mem.btype
  return (type >= kMinimapBlipType.Marine and type <= kMinimapBlipType.Gorge)
    or type == kMinimapBlipType.Prowler
    or type == kMinimapBlipType.Vokex
    or (type >= kMinimapBlipType.ARC and type <= kMinimapBlipType.MAC)
end

---@param mem TeamBrain.Memory
local function IsMemoryTypeUnitOrStructure(mem)
  return IsMemoryTypeUnit(mem) or IsMemoryTypeStructure(mem)
end

---@param senses BrainSenses
---@return TeamBrain.Memory[]
local function Mem_Enemies(senses)
  local enemies = {}
  local teamNumber = senses:GetTeamNumber()

  for _, mem in ipairs(GetTeamMemories(teamNumber)) do
    if mem.team ~= teamNumber and IsMemoryTypeUnitOrStructure(mem) then
      enemies[#enemies+1] = mem
    end
  end

  return enemies
end

---@param senses BrainSenses
---@return TeamBrain.Memory[]
local function Mem_Enemy_Structures(senses)
  return FilterTable(senses:Get("mem_enemies"), IsMemoryTypeStructure)
end

---@param senses BrainSenses
---@return TeamBrain.Memory[]
local function Mem_Enemy_Units(senses)
  return FilterTable(senses:Get("mem_enemies"), IsMemoryTypeUnit)
end

---@param senses BrainSenses
---@return TeamBrain.Memory[]
local function Mem_Passives(senses)
  return FilterTable(senses:Get("mem_enemies"), IsMemoryTypePassive)
end

---Threats only include memories that can actively harm the player.
---@param senses BrainSenses
---@return TeamBrain.Memory[]
local function Mem_Threats(senses)
  return FilterTable(senses:Get("mem_enemies"), IsMemoryTypeThreat)
end

---@param senses BrainSenses
function Bishop.global.PopulateSharedTeamSenses(senses)
  senses:Add("mem_enemies", Mem_Enemies)
  senses:Add("mem_enemy_structures", Mem_Enemy_Structures)
  senses:Add("mem_passives", Mem_Passives)
  senses:Add("mem_threats", Mem_Threats)
  senses:Add("mem_enemy_units", Mem_Enemy_Units)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
