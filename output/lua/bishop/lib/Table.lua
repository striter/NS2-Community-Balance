Script.Load("lua/Table.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

---Contains functions that manipulate tables for use with entities and bots.
Bishop.lib.table = {}

local TClear = table.clear

---Retrieves or creates a cached table for object under tableName. Used for
---short-lived hash tables to prevent frequent allocation and deletion.
---@param object table|Entity
---@param tableName string
---@return table
function Bishop.lib.table.GetCachedTable(object, tableName)
  if not object.bishopCache or not object.bishopCache[tableName] then
    if not object.bishopCache then
      object.bishopCache = {}
    end
    object.bishopCache[tableName] = {}
  end

  return object.bishopCache[tableName]
end

local GetCachedTable = Bishop.lib.table.GetCachedTable

---Retrieves or creates an empty cached table for object under tableName. Used
---for short-lived arrays to prevent frequent allocation and deletion.
---@param object table|Entity
---@param tableName string
---@return table
function Bishop.lib.table.GetClearCachedTable(object, tableName)
  local table = GetCachedTable(object, tableName)
  TClear(table)

  return table
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
