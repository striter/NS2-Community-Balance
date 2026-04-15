Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

---@class BotAim
---@field UpdateAim function

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

BotAim.kAccuracies[kBotAccWeaponGroup.Bullets] =
  {17.5, 21.5, 25, 30.5, 35, 36.5, 38.5}

BotAim.kAccuracies[kBotAccWeaponGroup.LerkBite] =
  {50, 55, 60, 65, 70, 75, 80}
BotAim.kAccuracies[kBotAccWeaponGroup.LerkSpikes] =
  {50, 55, 60, 65, 70, 75, 80}

-- Mirroring changes made by Bot_Maintenance.
BotAim.kAccuracies[kBotAccWeaponGroup.ExoMinigun] =
  {25, 28, 32, 36, 40, 45, 50}
BotAim.kAccuracies[kBotAccWeaponGroup.ExoRailgun] =
  {30, 35, 40, 45, 50, 55, 60}

Bishop.debug.FileExit(debug.getinfo(1, "S"))
