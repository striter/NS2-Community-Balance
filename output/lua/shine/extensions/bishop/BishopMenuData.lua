Bishop.debug.FileEntry(debug.getinfo(1, "S"))

--------------------------------------------------------------------------------
-- Bots tabs.
--------------------------------------------------------------------------------

-- TODO: last = could be made implicit in code.

local kBotsTabs = {
  {
    name = "Manage",
    icon = nil,
    settings = {
      {
        text = "Automate the addition and removal of bots from the game:",
        type = "label"
      },
      {
        text = "Auto-manage bots",
        type = "checkbox",
        container = "botManager",
        variable = "manage"
      },
      {
        text = "Continue game without humans",
        type = "checkbox",
        container = "botManager",
        variable = "continueGame",
        requires = {"manage"}
      },
      {
        text = "Start game without humans",
        type = "checkbox",
        container = "botManager",
        variable = "forceGame",
        requires = {"manage", "continueGame"}
      },
      {
        text = "",
        type = "label"
      },
      {
        text = "Allow automatic management of:",
        type = "label"
      },
      {
        text = "Marines",
        type = "checkbox",
        container = "botManager",
        variable = "marines",
        requires = {"manage"}
      },
      {
        text = "Aliens",
        type = "checkbox",
        container = "botManager",
        variable = "aliens",
        requires = {"manage"}
      },
      {
        text = "Marine commander",
        type = "checkbox",
        container = "botManager",
        variable = "marineCommander",
        requires = {"manage"}
      },
      {
        text = "Alien commander",
        type = "checkbox",
        container = "botManager",
        variable = "alienCommander",
        requires = {"manage"}
      },
      {
        text = "",
        type = "label"
      },
      {
        text = "Target team sizes (includes human players):",
        type = "label"
      },
      {
        text = "Marines",
        type = "slider",
        min = 0,
        max = 25,
        integersOnly = true,
        container = "botManager",
        variable = "marineTeamSize",
        requires = {"manage", "marines"}
      },
      {
        text = "Aliens",
        type = "slider",
        min = 0,
        max = 25,
        integersOnly = true,
        container = "botManager",
        variable = "alienTeamSize",
        requires = {"manage", "aliens"}
      }
    }
  },
  {
    name = "Customization",
    icon = nil,
    settings = {
      {
        text = "Enable chat messages:",
        type = "label"
      },
      {
        text = "Regular bots",
        type = "checkbox",
        container = "customization",
        variable = "botChat"
      },
      {
        text = "Commander bots",
        type = "checkbox",
        container = "customization",
        variable = "botChatCom"
      }
    }
  },
  {
    name = "Marine Com",
    icon = nil,
    settings = {
      {
        text = "Build offensive Phase Gates for Hive assaults:",
        type = "label"
      },
      {
        text = "Phase Gate",
        type = "checkbox",
        container = "marineCom",
        variable = "offensivePhase"
      },
      {
        text = "Armory",
        type = "checkbox",
        container = "marineCom",
        variable = "offensivePhaseArm",
        requires = {"offensivePhase"},
        last = true
      }
    }
  },
  {
    name = "Marines",
    icon = nil,
    settings = {
      {
        text = "Allow Jetpack purchases with LMG",
        type = "checkbox",
        container = "marine",
        variable = "jetpackLmg",
        last = true
      }
    }
  }
}

--------------------------------------------------------------------------------
-- About tabs.
--------------------------------------------------------------------------------

local kAboutTabs = {
  {
    name = "Credits",
    icon = nil,
    settings = {
      {
        text = "Bishop: Bot Mod by Bhaz.",
        type = "label"
      },
      {
        text = "",
        type = "label"
      },
      {
        text = "Credits:",
        type = "label"
      },
      {
        text = "   Delnaxsis: For hundreds of hours of MP testing.",
        type = "label"
      },
      {
        text = "   Predator: For creating Bot_Maintenance and providing tons "
          .. "of bug reports and feedback.",
        type = "label"
      },
      {
        text = "   Shine developers: For providing an insanely useful API.",
        type = "label",
        last = true
      }
    }
  }
}

--------------------------------------------------------------------------------
-- Vertical tabs.
--------------------------------------------------------------------------------

BishopS.MenuGUI.Data = {
  {
    name = "Bots",
    longName = "Bot Settings",
    data = kBotsTabs,
    icon = Shine.GUI.Icons.Ionicons.PersonAdd
  },
  {
    name = "About",
    longName = "Bishop: Bot Mod",
    data = kAboutTabs,
    icon = Shine.GUI.Icons.Ionicons.Help
  }
}

Bishop.debug.FileExit(debug.getinfo(1, "S"))
