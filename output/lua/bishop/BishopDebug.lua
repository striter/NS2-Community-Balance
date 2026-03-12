-- This is the second file to be loaded and is run directly by FileHooks.lua. Do
-- not place any Script.Load calls in here because it can interfere with other
-- mods that haven't registered their hooks yet.

Bishop = {}
Bishop.debug = {}

-- TODO: These should be distributed to their appropriate files. For now they
-- can live here so nothing breaks.

Bishop.alien = {}
Bishop.alien.actions = {}
Bishop.alien.objectives = {}
Bishop.alien.fade = {}
Bishop.alien.gorge = {}
Bishop.alien.lerk = {}
Bishop.alien.onos = {}
Bishop.alien.skulk = {}
Bishop.alienCom = {}
Bishop.global = {}
Bishop.global.stuck = {}
Bishop.global.vents = {}
Bishop.lib = {}
Bishop.marine = {}
Bishop.marine.exo = {}
Bishop.marine.soldier = {}
Bishop.marineCom = {}
Bishop.utility = {}

local Log = Log

if Client then
  Bishop.debug.devTools = false
end

if Server or Client then
  Bishop.debug.system = false
  Bishop.debug.systemVerbose = false
  Bishop.debug.userInterface = false
  Bishop.debug.settings = false
end

if Server then
  -- Commander.
  Bishop.debug.rayTrace = false

  -- Alien commander.
  Bishop.debug.offensiveTunnel = false

  -- Marine commander.
  Bishop.debug.marineResearch = false

  -- Bots.
  Bishop.debug.stuck = false
  Bishop.debug.vents = false

  -- Aliens.
  Bishop.debug.alienClass = nil -- Set to class name, i.e. "Onos".
  Bishop.debug.bodyBlock = false
  Bishop.debug.lifeform = false
  Bishop.debug.pack = false

  -- Skulk.
  Bishop.debug.skulk = false

  -- Gorge.
  Bishop.debug.bileMine = false
  Bishop.debug.hydra = false
  Bishop.debug.web = false

  -- Lerk.
  Bishop.debug.lerkPathing = false

  -- Marines.
  Bishop.debug.fireteams = false
  Bishop.debug.weapons = false
end

if Server or Client then
  function Bishop.Log(message, ...)
    Log("Bishop: " .. message, ...)
  end

  local Log = Bishop.Log

  function Bishop.Error(message, ...)
    Log("Error: " .. message, ...)
  end

  function Bishop.debug.SystemLog(message, ...)
    Log("System: " .. message, ...)
  end

  function Bishop.debug.FileEntry(fileInfo)
    if Bishop.debug.system and fileInfo and fileInfo.source then
      Bishop.debug.SystemLog("Loading %s.", fileInfo.source)
    end
  end

  function Bishop.debug.FileExit(fileInfo)
    if Bishop.debug.system and Bishop.debug.systemVerbose and fileInfo
        and fileInfo.source then
      Bishop.debug.SystemLog("Loaded %s.", fileInfo.source)
    end
  end

  if Bishop.debug.system then
    Bishop.debug.SystemLog("Debug enabled. Verbose: %s.",
      Bishop.debug.systemVerbose)
    Bishop.debug.FileEntry(debug.getinfo(1, "S"))
  end

  function Bishop.debug.UILog(message, ...)
    Log("UI: " .. message, ...)
  end
  if Bishop.debug.userInterface then
    Bishop.debug.UILog("Debug enabled.")
  end

  function Bishop.debug.SettingsLog(message, ...)
    Log("Settings: " .. message, ...)
  end
  if Bishop.debug.settings then
    Bishop.debug.SettingsLog("Debug enabled.")
  end
end

if Server then
  ---@diagnostic disable-next-line: redefined-local
  local Log = Bishop.Log

  function Bishop.debug.OffensiveTunnelLog(message, ...)
    Log("Offensive tunnel: " .. message, ...)
  end
  if Bishop.debug.offensiveTunnel then
    Bishop.debug.OffensiveTunnelLog("Debug enabled.")
  end

  function Bishop.debug.MarineResearchLog(message, ...)
    Log("Marine research: " .. message, ...)
  end
  if Bishop.debug.marineResearch then
    Bishop.debug.MarineResearchLog("Debug enabled.")
  end

  function Bishop.debug.StuckLog(message, ...)
    Log("Stuck: " .. message, ...)
  end
  if Bishop.debug.stuck then
    Bishop.debug.StuckLog("Debug enabled.")
  end

  function Bishop.debug.VentLog(message, ...)
    Log("Vents: " .. message, ...)
  end
  if Bishop.debug.vents then
    Bishop.debug.VentLog("Debug enabled.")
  end

  function Bishop.debug.LifeformLog(message, ...)
    Log("Lifeform: " .. message, ...)
  end
  if Bishop.debug.lifeform then
    Bishop.debug.LifeformLog("Debug enabled.")
  end

  function Bishop.debug.PackLog(message, ...)
    Log("Pack: " .. message, ...)
  end
  if Bishop.debug.pack then
    Bishop.debug.PackLog("Debug enabled.")
  end

  function Bishop.debug.BileMineLog(message, ...)
    Log("Bile Mine: " .. message, ...)
  end
  if Bishop.debug.bileMine then
    Bishop.debug.BileMineLog("Debug enabled.")
  end

  function Bishop.debug.HydraLog(message, ...)
    Log("Hydra: " .. message, ...)
  end
  if Bishop.debug.hydra then
    Bishop.debug.HydraLog("Debug enabled.")
  end

  function Bishop.debug.WebLog(message, ...)
    Log("Web: " .. message, ...)
  end
  if Bishop.debug.web then
    Bishop.debug.WebLog("Debug enabled.")
  end

  function Bishop.debug.FireteamLog(message, ...)
    Log("Fireteam: " .. message, ...)
  end
  if Bishop.debug.fireteams then
    Bishop.debug.FireteamLog("Debug enabled.")
  end

  function Bishop.debug.WeaponsLog(message, ...)
    Log("Weapons: " .. message, ...)
  end
  if Bishop.debug.weapons then
    Bishop.debug.WeaponsLog("Debug enabled.")
  end
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
