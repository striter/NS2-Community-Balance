-- Credit to the Shine developers: Most of this is an adaptation of their
-- configuration UI.

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local Log = Bishop.debug.UILog

local hasOpened = false -- Flag used to request all settings at first open.
local kDebug = Bishop.debug.userInterface -- UI debugging flag.
local kSpamLimit = 1 -- Kerb menu button spam to prevent errors.
local lastOpenTime = 0 -- Time the last menu toggle was accepted.

---Called by the handler for the Bishop_MenuOpen network message.
---@param visible boolean
function BishopS.MenuGUI:Show(visible)
  if kDebug then Log("Show(%s)", visible) end

  -- Clients need to request all current settings from the server when opening
  -- the menu for the first time.
  if not hasOpened then
    hasOpened = true
    BishopS.Plugin:SendNetworkMessage("Bishop_GetAllSettings", {}, true)
  end

  local time = Shared.GetTime()
  if time > lastOpenTime + kSpamLimit then
    lastOpenTime = time
    self:SetIsVisible(visible)
  end
end

Script.Load("lua/shine/extensions/bishop/BishopMenuGUI.lua")

Bishop.debug.FileExit(debug.getinfo(1, "S"))
