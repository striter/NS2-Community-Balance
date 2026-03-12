-- The very first file to be loaded. Be careful in here, it loads everywhere. No
-- other work beyond registering the mod's file hooks should be performed.

if Server or Client then
  Script.Load("lua/bishop/BishopDebug.lua")
end

if Server then
  Bishop.debug.FileEntry(debug.getinfo(1, "S"))

  ---@class BishopHook
  ---@field vanilla string
  ---@field modded string[]
  ---@field mode string

  ---@type BishopHook[]
  local hookFiles = {
    {
      vanilla = "lua/AlienTeam.lua",
      modded = {"lua/bishop/alien/AlienTeam.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/Exo.lua",
      modded = {"lua/bishop/fixes/Exo.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/Harvester.lua",
      modded = {"lua/bishop/fixes/Harvester.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/Hydra.lua",
      modded = {"lua/bishop/fixes/Hydra.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/NS2Gamerules.lua",
      modded = {"lua/bishop/fixes/NS2Gamerules.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/ObstacleMixin.lua",
      modded = {"lua/bishop/fixes/ObstacleMixin.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/PlayerHallucinationMixin.lua",
      modded = {"lua/bishop/fixes/PlayerHallucinationMixin.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/ScoringMixin.lua",
      modded = {"lua/bishop/fixes/ScoringMixin.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/bots/AlienCommanderBrain.lua",
      modded = {"lua/bishop/aliencom/AComBrain.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/bots/AlienCommanderBrain_Data.lua",
      modded = {"lua/bishop/aliencom/AComActions.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/bots/AlienCommanderBrain_Senses.lua",
      modded = {"lua/bishop/aliencom/AComSenses.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/bots/AlienCommanderBrain_TechPathData.lua",
      modded = {"lua/bishop/aliencom/AComResearch.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/bots/AlienTeamBrain.lua",
      modded = {"lua/bishop/alien/AlienTeamBrain.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/bots/BotAim.lua",
      modded = {"lua/bishop/global/BotAim.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/bots/Bot_Server.lua",
      modded = {"lua/bishop/global/Bot_Server.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/bots/BotMotion.lua",
      modded = {"lua/bishop/global/BotMotion.lua"},
      mode = "replace"
    },
    {
      vanilla = "lua/bots/BrainSenses.lua",
      modded = {"lua/bishop/global/BrainSenses.lua"},
      mode = "replace"
    },
    {
      vanilla = "lua/bots/CommanderBrain.lua",
      modded = {"lua/bishop/global/ComBrain.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/bots/ExoBrain_Data.lua",
      modded = {
        "lua/bishop/marine/exo/ExoActions.lua",
        "lua/bishop/marine/exo/ExoObjectives.lua",
        "lua/bishop/marine/exo/ExoSenses.lua"
      },
      mode = "post"
    },
    {
      vanilla = "lua/bots/FadeBrain_Data.lua",
      modded = {
        "lua/bishop/alien/fade/FadeActions.lua",
        "lua/bishop/alien/fade/FadeObjectives.lua",
        "lua/bishop/alien/fade/FadeSenses.lua"
      },
      mode = "post"
    },
    {
      vanilla = "lua/bots/GorgeBrain.lua",
      modded = {"lua/bishop/alien/gorge/GorgeBrain.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/bots/GorgeBrain_Data.lua",
      modded = {
        "lua/bishop/alien/gorge/GorgeActions.lua",
        "lua/bishop/alien/gorge/GorgeSenses.lua"
      },
      mode = "post"
    },
    {
      vanilla = "lua/bots/LerkBrain.lua",
      modded = {"lua/bishop/alien/lerk/LerkBrain.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/bots/LerkBrain_Data.lua",
      modded = {
        "lua/bishop/alien/lerk/LerkActions.lua",
        "lua/bishop/alien/lerk/LerkObjectives.lua",
        "lua/bishop/alien/lerk/LerkSenses.lua"
      },
      mode = "post"
    },
    {
      vanilla = "lua/bots/MarineBrain.lua",
      modded = {"lua/bishop/marine/soldier/MarineBrain.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/bots/MarineBrain_Data.lua",
      modded = {
        "lua/bishop/marine/soldier/MarineActions.lua",
        "lua/bishop/marine/soldier/MarineObjectives.lua",
        "lua/bishop/marine/soldier/MarineSenses.lua"
      },
      mode = "post"
    },
    {
      vanilla = "lua/bots/MarineCommanderBrain.lua",
      modded = {"lua/bishop/marinecom/MComBrain.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/bots/MarineCommanderBrain_Data.lua",
      modded = {"lua/bishop/marinecom/MComActions.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/bots/MarineCommanderBrain_Senses.lua",
      modded = {"lua/bishop/marinecom/MComSenses.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/bots/MarineCommanerBrain_TechPath.lua", -- Vanilla typo.
      modded = {"lua/bishop/marinecom/MComResearch.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/bots/MarineTeamBrain.lua",
      modded = {"lua/bishop/marine/MarineTeamBrain.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/bots/MinigunBrain.lua",
      modded = {"lua/bishop/marine/exo/MinigunBrain.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/bots/OnosBrain_Data.lua",
      modded = {
        "lua/bishop/alien/onos/OnosActions.lua",
        "lua/bishop/alien/onos/OnosObjectives.lua",
        "lua/bishop/alien/onos/OnosSenses.lua"
      },
      mode = "post"
    },
    {
      vanilla = "lua/bots/PlayerBot_Server.lua",
      modded = {"lua/bishop/global/PlayerBot_Server.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/bots/RailgunBrain.lua",
      modded = {"lua/bishop/marine/exo/RailgunBrain.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/bots/SkulkBrain.lua",
      modded = {"lua/bishop/alien/skulk/SkulkBrain.lua"},
      mode = "post"
    },
    {
      vanilla = "lua/bots/SkulkBrain_Data.lua",
      modded = {
        "lua/bishop/alien/skulk/SkulkActions.lua",
        "lua/bishop/alien/skulk/SkulkObjectives.lua",
        "lua/bishop/alien/skulk/SkulkSenses.lua"
      },
      mode = "post"
    },
    {
      vanilla = "lua/bots/TeamBrain.lua",
      modded = {"lua/bishop/global/TeamBrain.lua"},
      mode = "post"
    }
  }

  local function SetupHooks()
    for _, hook in ipairs(hookFiles) do
      for _, file in ipairs(hook.modded) do
        ModLoader.SetupFileHook(hook.vanilla, file, hook.mode)
      end
    end
  end

  if Shine then
    Bishop.Log("HAS ARRIVED.")
    if Bishop.debug.system then
      Bishop.debug.SystemLog("Setting up file hooks.")
    end
    SetupHooks()
  else
    Bishop.Error("Shine is not loaded.")
  end

  Bishop.debug.FileExit(debug.getinfo(1, "S"))
end
