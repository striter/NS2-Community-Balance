Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local Plugin = ...
local SGUI = Shine.GUI

BishopS.MenuGUI = {}
BishopS.Plugin = Plugin
local BishopMenuGUI = BishopS.MenuGUI
local Log = Bishop.debug.UILog
local SLog = Bishop.debug.SettingsLog

local kDebug = Bishop.debug.userInterface -- UI debugging flag.
local kSDebug = Bishop.debug.settings -- Settings debug flag.

--------------------------------------------------------------------------------
-- Network message hooks.
--------------------------------------------------------------------------------

function Plugin:ReceiveBishop_MenuOpen()
  if kDebug then Log("ReceiveBishop_MenuOpen()") end
  local handler = Shine.BuildErrorHandler("Failed to create Bishop menu.")
  local visible = BishopMenuGUI.visible

  if xpcall(BishopMenuGUI.Show, handler, BishopMenuGUI, not visible) then
    if not visible and BishopMenuGUI.visible
        and SGUI.IsValid(BishopMenuGUI.menu) then
      SGUI:SetWindowFocus(BishopMenuGUI.menu)
    end
  end
end

function Plugin:ReceiveBishop_Setting(data)
  local container, variable, value = data.Container, data.Setting, data.Value
  if kSDebug then
    SLog("ReceiveBishop_Setting()")
    SLog("  container: %s, variable: %s, value: %s", container, variable, value)
  end
  Bishop.SettingUpdater.UpdateSetting(Plugin, container, variable, value)
end

Script.Load("lua/shine/extensions/bishop/BishopMenu.lua")

Bishop.debug.FileExit(debug.getinfo(1, "S"))
