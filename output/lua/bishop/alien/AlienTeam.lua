Script.Load("lua/Table.lua")
Script.Load("lua/TechData.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local LookupTechData = LookupTechData
local table_insert = table.insert
local table_insertunique = table.insertunique

--------------------------------------------------------------------------------
-- Redirect Gorge structure functions to use botId for virtual clients.
--------------------------------------------------------------------------------
-- Gives the ability for each bot to have its own set of buildings. See
-- Bot_Server.lua for more info.

local AddGorgeStructure = _G.AlienTeam.AddGorgeStructure
local GetDroppedGorgeStructures = _G.AlienTeam.GetDroppedGorgeStructures

function AlienTeam:AddGorgeStructure(player, structure)
  if not player:GetClient():GetIsVirtual() then
    return AddGorgeStructure(self, player, structure)
  elseif player == nil or structure == nil then
    return
  end

  local botId = player:GetClient().bot.botId
  local structureId = structure:GetId()
  local techId = structure:GetTechId()

  if not self.clientOwnedStructures[botId] then
    table_insert(self.clientStructuresOwner, botId)
    self.clientOwnedStructures[botId] = {
      techIds = {}
    }
  end

  local structureTypeTable = self.clientOwnedStructures[botId]
  if not structureTypeTable[techId] then
    structureTypeTable[techId] = {}
    table_insert(structureTypeTable.techIds, techId)
  end
  table_insertunique(structureTypeTable[techId], structureId)

  local structureLimit = LookupTechData(techId, kTechDataMaxAmount, -1)
  if structureLimit >= 0 and #structureTypeTable[techId] > structureLimit then
    self:RemoveGorgeStructureFromClient(techId, botId)
  end
end

function AlienTeam:GetDroppedGorgeStructures(player, techId)
  if not player:GetClient():GetIsVirtual() then
    return GetDroppedGorgeStructures(self, player, techId)
  end

  local botId = player:GetClient().bot.botId
  local structureTypeTable = self.clientOwnedStructures[botId]
  if not structureTypeTable then
    return nil
  end

  return structureTypeTable[techId]
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
