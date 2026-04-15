-- NOTE: The values of settings in this file are the defaults. If a setting
-- isn't found by the Shine .json file, these values are used instead.

Script.Load("lua/bishop/system/SettingUpdater.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.settings = {}

-- Bot manager settings.
Bishop.settings.botManager = {}
local botManager = Bishop.settings.botManager

-- Bots are not automatically added or removed in any way if manage is false.
botManager.manage = false         -- Enable automatic management.
botManager.forceGame = false      -- Enable auto-start without humans.
botManager.continueGame = true    -- Enable continuation without humans.
botManager.marineCommander = true -- Enable marine commander bot.
botManager.alienCommander = true  -- Enable alien commander bot.
botManager.marines = true         -- Enable marine bots.
botManager.aliens = true          -- Enable alien bots.
botManager.marineTeamSize = 10    -- Target marine team size.
botManager.alienTeamSize = 10     -- Target alien team size.

-- Customization.
Bishop.settings.customization = {}
local customization = Bishop.settings.customization

customization.botChat = true    -- Enable bot chat messages.
customization.botChatCom = true -- Enable commander chat messages.

-- Marine commander settings.
Bishop.settings.marineCom = {}
local marineCom = Bishop.settings.marineCom

marineCom.offensivePhase = true    -- Enable construction of offensive PG.
marineCom.offensivePhaseArm = true -- Construct Armory next to offensive PG.

-- Marine settings.
Bishop.settings.marine = {}
local marine = Bishop.settings.marine

marine.jetpackLmg = true -- Allow purchasing jetpacks with an LMG.

Bishop.debug.FileExit(debug.getinfo(1, "S"))
