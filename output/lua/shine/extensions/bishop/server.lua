Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local Plugin = ...
local SGUI = Shine.GUI

BishopS.MenuGUI = {}
BishopS.Plugin = Plugin
local BishopMenuGUI = BishopS.MenuGUI
local Log = Bishop.debug.SettingsLog

local kDebug = Bishop.debug.settings -- Settings debugging flag.

--------------------------------------------------------------------------------
-- Network message hooks.
--------------------------------------------------------------------------------

function Plugin:ReceiveBishop_GetSetting(client, data)
  local container, variable = data.Container, data.Setting

  if kDebug then
    Log("ReceiveBishop_GetSetting()")
    Log("  container: %s, variable: %s", container, variable)
  end

  Bishop.SettingUpdater.GetSetting(Plugin, client, container, variable)
end

function Plugin:ReceiveBishop_GetAllSettings(client, data)
  if kDebug then Log("ReceiveBishop_GetAllSettings()") end
  Bishop.SettingUpdater.Broadcast(Plugin, client)
end

function Plugin:ReceiveBishop_SetSetting(client, data)
  if kDebug then Log("ReceiveBishop_SetSetting()") end
  local container, variable, value = data.Container, data.Setting, data.Value

  if Server.IsDedicated() and not Shine:HasAccess(client, "bishop_set") then
    Shine:SendNotification(client, Shine.NotificationType.ERROR,
      "You do not have access to the bishop_set command on this server.")
    return
  elseif not Server.IsDedicated() and not client:GetIsLocalClient() then
    Shine:SendNotification(client, Shine.NotificationType.ERROR,
      "Only the host may change Bishop settings.")
    return
  end

  Bishop.SettingUpdater.UpdateSetting(Plugin, container, variable, value)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
