Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

BishopS = {}

local Log = Bishop.debug.UILog

local kDebug = Bishop.debug.userInterface -- UI debugging flag.

--------------------------------------------------------------------------------
-- Shine plugin setup.
--------------------------------------------------------------------------------

local Plugin = Shine.Plugin(...)

Plugin.Version = "1.0"
Plugin.HasConfig = true
Plugin.ConfigName = "Bishop.json"
Plugin.DefaultConfig = {}
Plugin.CheckConfig = false
Plugin.CheckConfigTypes = false
Plugin.CheckConfigRecursively = false
Plugin.DefaultState = true
Plugin.SilentConfigSave = true

Plugin.Conflicts = {
  DisableThem = {"botmanager"},
  DisableUs = {}
}

--------------------------------------------------------------------------------
-- Bishop plugin commands.
--------------------------------------------------------------------------------

function Plugin:SetupDataTable()
  if kDebug then Log("SetupDataTable()") end
  self:AddNetworkMessage("Bishop_MenuOpen", {}, "Client")
  self:AddNetworkMessage("Bishop_Setting",
    {
      Container = "string (20)",
      Setting = "string (20)",
      Value = "string (16)"
    }, "Client")
  self:AddNetworkMessage("Bishop_GetSetting",
    {
      Container = "string (20)",
      Setting = "string (20)"
    }, "Server")
  self:AddNetworkMessage("Bishop_GetAllSettings", {}, "Server")
  self:AddNetworkMessage("Bishop_SetSetting",
    {
      Container = "string (20)",
      Setting = "string (20)",
      Value = "string (16)"
    }, "Server")
end

function Plugin:CreateServerCommands()
  if kDebug then Log("CreateServerCommands()") end
  self:BindCommand("bishop_menu", "bishop",
    function(client)
      self:SendNetworkMessage(client, "Bishop_MenuOpen", {}, true)
    end, true, true):Help("Open Bishop's configuration menu.")

  -- If the player is running a local server, they shouldn't need to set up a
  -- Shine config file, so just give all users access to bishop_set.
  local dedicated = Server.IsDedicated()
  local set = self:BindCommand("bishop_set", nil,
    function(client, container, variable, value)
      Bishop.SettingUpdater.UpdateSetting(Plugin, container, variable, value)
    end, not dedicated)
  set:AddParam{Type = "string"}
  set:AddParam{Type = "string"}
  set:AddParam{Type = "string"}
end

--------------------------------------------------------------------------------
-- Plugin load.
--------------------------------------------------------------------------------

local function LoadConfig(Plugin)
  if kDebug then Log("LoadConfig()") end
  for section, container in pairs(Bishop.settings) do
    if kDebug then Log("  Checking for %s table.", section) end
    if Plugin.Config[section] and type(Plugin.Config[section]) == "table" then
      for variable, _ in pairs(container) do
        if kDebug then Log("    Checking for %s variable.", variable) end
        local value = Plugin.Config[section][variable]
        if type(value) == "string" then
          if kDebug then Log("      Loading %s from config.", variable) end
          Bishop.SettingUpdater.UpdateSetting(Plugin, section, variable, value)
        end
      end
    end
  end
end

function Plugin:Initialise()
  if kDebug then Log("Initialise() - Shine plugin shared.lua.") end
  if not Bishop then
    return false, "Bishop Shine plugin somehow enabled without workshop mod."
  end
  if Server then
    self:CreateServerCommands()
    LoadConfig(self)
  end
  return true
end

--------------------------------------------------------------------------------
-- Plugin unload.
--------------------------------------------------------------------------------

function Plugin:Cleanup()
  if kDebug then Log("Cleanup() - Shine plugin shared.lua.") end
  self.BaseClass.Cleanup(self)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))

return Plugin
