--
--	ns2siege+ Custom Game Mode
--	ZycaR (c) 2016
--

ModLoader.SetupFileHook( "lua/GameInfo.lua", "lua/sg_GameInfo.lua" , "post" )
ModLoader.SetupFileHook( "lua/NS2Gamerules.lua", "lua/sg_NS2Gamerules.lua" , "post" )

-- Truce mode untill front/siege doors are closed
ModLoader.SetupFileHook( "lua/DamageMixin.lua", "lua/sg_DamageMixin.lua" , "post" )

-- Sudden death mode disable repair of CommandStation and heal Hive
ModLoader.SetupFileHook( "lua/CommandStation.lua", "lua/sg_CommandStation.lua" , "post" )
ModLoader.SetupFileHook( "lua/CommandStructure.lua", "lua/sg_CommandStructure.lua" , "post" )

-- Special dynamicaly generated obstacles for func_doors
ModLoader.SetupFileHook( "lua/ObstacleMixin.lua", "lua/sg_ObstacleMixin.lua" , "post" )

-- Cyst placement will emit signal for all func_maid entites on map ( in range of 1000 )
ModLoader.SetupFileHook( "lua/Cyst.lua", "lua/sg_Cyst.lua" , "post" )
ModLoader.SetupFileHook( "lua/DrifterEgg.lua", "lua/sg_DrifterEgg.lua" , "post" )
ModLoader.SetupFileHook( "lua/CommAbilities/Alien/Contamination.lua", "lua/sg_Contamination.lua" , "post" )
ModLoader.SetupFileHook( "lua/TunnelEntrance.lua", "lua/sg_TunnelEntrance.lua" , "post" )

-- Hook custom gui elements
ModLoader.SetupFileHook( "lua/GUIWorldText.lua", "lua/sg_GUIScriptLoader.lua" , "post" )

ModLoader.SetupFileHook( "lua/GUIInsight_TopBar.lua", "lua/sg_GUIInsight_TopBar.lua" , "replace" )
ModLoader.SetupFileHook( "lua/GUIFirstPersonSpectate.lua", "lua/sg_GUIFirstPersonSpectate.lua" , "replace" )


-- tech tree changes according doors
ModLoader.SetupFileHook( "lua/TechTree_Server.lua", "lua/sg_TechTree_Server.lua" , "post" )

ModLoader.SetupFileHook( "lua/TechData.lua", "lua/sg_TechData.lua" , "post" )

-- fix hive healing (yes, it's a replace.... the file is garbo)
ModLoader.SetupFileHook( "lua/Hive_Server.lua", "lua/sg_Hive_Server.lua" , "replace" )


-- fix concede sequence errors (yes, also a replace, yes, the file is garbo as well)
ModLoader.SetupFileHook( "lua/ConcedeSequence.lua", "lua/sg_ConcedeSequence.lua" , "replace" )

-- enable commander bots
--ModLoader.SetupFileHook( "lua/bots/BotUtils.lua", "lua/bots/sg_BotUtils.lua" , "post" )
--ModLoader.SetupFileHook( "lua/bots/CommonActions.lua", "lua/bots/sg_CommonActions.lua" , "post" )
--ModLoader.SetupFileHook( "lua/bots/CommanderBrain.lua", "lua/bots/sg_CommanderBrain.lua" , "post" )

-- bot replacements :(
--ModLoader.SetupFileHook( "lua/bots/AlienCommanderBrain_Data.lua", "lua/bots/sg_AlienCommanderBrain_Data.lua" , "replace" )
--ModLoader.SetupFileHook( "lua/bots/MarineCommanderBrain_Data.lua", "lua/bots/sg_MarineCommanderBrain_Data.lua" , "replace" )
--ModLoader.SetupFileHook( "lua/bots/MarineBrain_Data.lua", "lua/bots/sg_MarineBrain_Data.lua" , "replace" )
--ModLoader.SetupFileHook( "lua/bots/SkulkBrain_Data.lua", "lua/bots/sg_SkulkBrain_Data.lua" , "replace" )
--ModLoader.SetupFileHook( "lua/bots/GorgeBrain_Data.lua", "lua/bots/sg_GorgeBrain_Data.lua" , "replace" )
--ModLoader.SetupFileHook( "lua/bots/BotMotion.lua", "lua/bots/sg_BotMotion.lua" , "replace" )

--updated by cn community:
--alien health value adjustments
--remove the function siege's bot's tunnel action
ModLoader.SetupFileHook( "lua/bots/CommonAlienActions.lua", "lua/sg_CommonAlienActions.lua" , "post" )
ModLoader.SetupFileHook( "lua/Drifter.lua", "lua/sg_Drifter.lua" , "post" )

ModLoader.SetupFileHook( "lua/BalanceHealth.lua", "lua/sg_BalanceHealth.lua" , "post" )
ModLoader.SetupFileHook( "lua/BalanceMisc.lua", "lua/sg_BalanceMisc.lua" , "post" )
ModLoader.SetupFileHook( "lua/Balance.lua", "lua/sg_Balance.lua" , "post" )

--diasblead,unable to load the right animation
--ModLoader.SetupFileHook( "lua/MarineWeaponEffects.lua", "lua/Effects/sg_MarineWeaponEffects.lua" , "post" )

--Modify the judgment of placing tunnels
ModLoader.SetupFileHook( "lua/BuildUtility.lua", "lua/sg_BuildUtility.lua" , "post" )

--limit onos numbers
--ModLoader.SetupFileHook( "lua/GUIAlienBuyMenu.lua","lua/sg_GUIAlienBuyMenu.lua","post")

