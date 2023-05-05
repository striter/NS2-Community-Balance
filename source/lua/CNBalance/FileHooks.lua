ModLoader.SetupFileHook("lua/ClientUI.lua", "lua/CNBalance/ClientUI.lua", "replace")
ModLoader.SetupFileHook("lua/Client.lua", "lua/CNBalance/Client.lua", "post" )
ModLoader.SetupFileHook("lua/ClientLOSMixin.lua", "lua/CNBalance/ClientLOSMixin.lua", "post" )
ModLoader.SetupFileHook("lua/Player_Client.lua", "lua/CNBalance/Player_Client.lua", "post")

ModLoader.SetupFileHook("lua/Shared.lua", "lua/CNBalance/Shared.lua", "post")
ModLoader.SetupFileHook("lua/NS2Gamerules.lua", "lua/CNBalance/NS2Gamerules.lua", "post")
ModLoader.SetupFileHook("lua/Globals.lua", "lua/CNBalance/Globals.lua", "post" )
ModLoader.SetupFileHook("lua/Team.lua", "lua/CNBalance/Team.lua", "post")

ModLoader.SetupFileHook("lua/ScriptActor.lua", "lua/CNBalance/ScriptActor.lua", "post" )
ModLoader.SetupFileHook("lua/Utility.lua", "lua/CNBalance/Utility.lua", "post" )
ModLoader.SetupFileHook("lua/NS2Utility.lua", "lua/CNBalance/NS2Utility.lua", "post" )
ModLoader.SetupFileHook("lua/NS2Utility_Server.lua", "lua/CNBalance/NS2Utility_Server.lua", "post" )
ModLoader.SetupFileHook("lua/NS2ConsoleCommands_Server.lua", "lua/CNBalance/NS2ConsoleCommands_Server.lua", "post" )
ModLoader.SetupFileHook("lua/NetworkMessages.lua", "lua/CNBalance/NetworkMessages.lua", "post" )
ModLoader.SetupFileHook("lua/NetworkMessages_Server.lua", "lua/CNBalance/NetworkMessages_Server.lua", "post" )

ModLoader.SetupFileHook("lua/TechTreeConstants.lua", "lua/CNBalance/TechTreeConstants.lua", "post")
ModLoader.SetupFileHook("lua/TechData.lua", "lua/CNBalance/TechData.lua", "post")
ModLoader.SetupFileHook("lua/TechTree.lua", "lua/CNBalance/TechTree.lua", "post")
ModLoader.SetupFileHook("lua/TechTreeButtons.lua", "lua/CNBalance/TechTreeButtons.lua", "post")
ModLoader.SetupFileHook("lua/BuildUtility.lua", "lua/CNBalance/BuildUtility.lua", "post")
ModLoader.SetupFileHook("lua/MarineTechMap.lua", "lua/CNBalance/MarineTechMap.lua", "post")
ModLoader.SetupFileHook("lua/TeamInfo.lua", "lua/CNBalance/TeamInfo.lua", "post")
ModLoader.SetupFileHook("lua/PlayingTeam.lua", "lua/CNBalance/PlayingTeam.lua", "post")
ModLoader.SetupFileHook("lua/DamageTypes.lua", "lua/CNBalance/DamageTypes.lua", "replace")
ModLoader.SetupFileHook("lua/CommandStructure_Server.lua", "lua/CNBalance/CommandStructure_Server.lua", "post" )
ModLoader.SetupFileHook("lua/ReadyRoomTeam.lua", "lua/CNBalance/ReadyRoomTeam.lua", "post" )
ModLoader.SetupFileHook("lua/ReadyRoomEmbryo.lua", "lua/CNBalance/ReadyRoomEmbryo.lua", "post" )
ModLoader.SetupFileHook("lua/Scoreboard.lua", "lua/CNBalance/Scoreboard.lua", "post" )
ModLoader.SetupFileHook("lua/ScoringMixin.lua", "lua/CNBalance/ScoringMixin.lua", "post" )
ModLoader.SetupFileHook("lua/ServerStats.lua", "lua/CNBalance/ServerStats.lua", "replace" )

--Effects
ModLoader.SetupFileHook("lua/GeneralEffects.lua", "lua/CNBalance/Effects/GeneralEffects.lua", "post" )
ModLoader.SetupFileHook("lua/PlayerEffects.lua", "lua/CNBalance/Effects/PlayerEffects.lua", "post" )
ModLoader.SetupFileHook("lua/DamageEffects.lua", "lua/CNBalance/Effects/DamageEffects.lua", "post" )
ModLoader.SetupFileHook("lua/MarineStructureEffects.lua", "lua/CNBalance/Effects/MarineStructureEffects.lua", "post")
ModLoader.SetupFileHook("lua/MarineWeaponEffects.lua", "lua/CNBalance/Effects/MarineWeaponEffects.lua", "post")
ModLoader.SetupFileHook("lua/AlienWeaponEffects.lua", "lua/CNBalance/Effects/AlienWeaponEffects.lua", "post" )
ModLoader.SetupFileHook("lua/SoundEffect.lua", "lua/CNBalance/SoundEffect.lua", "post" )

--Mixin
ModLoader.SetupFileHook("lua/Weapons/BulletsMixin.lua", "lua/CNBalance/Weapons/BulletsMixin.lua", "post")
ModLoader.SetupFileHook("lua/CloakableMixin.lua", "lua/CNBalance/Mixin/CloakableMixin.lua", "replace")
ModLoader.SetupFileHook("lua/BabblerOwnerMixin.lua", "lua/CNBalance/Mixin/BabblerOwnerMixin.lua", "post")
ModLoader.SetupFileHook("lua/RegenerationMixin.lua", "lua/CNBalance/Mixin/RegenerationMixin.lua", "post")
ModLoader.SetupFileHook("lua/ShieldableMixin.lua", "lua/CNBalance/Mixin/ShieldableMixin.lua", "post" )
ModLoader.SetupFileHook("lua/PlayerHallucinationMixin.lua", "lua/CNBalance/Mixin/PlayerHallucinationMixin.lua", "post" )
ModLoader.SetupFileHook("lua/UmbraMixin.lua", "lua/CNBalance/Mixin/UmbraMixin.lua", "post" )
ModLoader.SetupFileHook("lua/TeamDeathMessageMixin.lua", "lua/CNBalance/Mixin/TeamDeathMessageMixin.lua", "post" )
ModLoader.SetupFileHook("lua/PointGiverMixin.lua", "lua/CNBalance/Mixin/PointGiverMixin.lua", "post" )

ModLoader.SetupFileHook("lua/Player.lua", "lua/CNBalance/Player.lua", "post" )
ModLoader.SetupFileHook("lua/HitSounds.lua", "lua/CNBalance/HitSounds.lua", "post" )

ModLoader.SetupFileHook("lua/Balance.lua", "lua/CNBalance/Balance.lua", "post")
ModLoader.SetupFileHook("lua/BalanceHealth.lua", "lua/CNBalance/BalanceHealth.lua", "post")
ModLoader.SetupFileHook("lua/BalanceMisc.lua", "lua/CNBalance/BalanceMisc.lua", "post")

--Marines
ModLoader.SetupFileHook("lua/AmmoPack.lua", "lua/CNBalance/AmmoPack.lua", "post")
ModLoader.SetupFileHook("lua/GUIMarineBuyMenu.lua", "lua/CNBalance/GUIMarineBuyMenu.lua", "replace" )
ModLoader.SetupFileHook("lua/GUIActionIcon.lua", "lua/CNBalance/GUIActionIcon.lua", "replace")
ModLoader.SetupFileHook("lua/GUIPickups.lua", "lua/CNBalance/GUIPickups.lua", "post")
ModLoader.SetupFileHook("lua/MarineTeam.lua", "lua/CNBalance/MarineTeam.lua", "post")
ModLoader.SetupFileHook("lua/MarineTeamInfo.lua", "lua/CNBalance/MarineTeamInfo.lua", "replace")
ModLoader.SetupFileHook("lua/ArmsLab.lua", "lua/CNBalance/ArmsLab.lua", "post")
ModLoader.SetupFileHook("lua/PrototypeLab.lua", "lua/CNBalance/PrototypeLab.lua", "post")
ModLoader.SetupFileHook("lua/CommandStation.lua", "lua/CNBalance/CommandStation.lua", "post")
ModLoader.SetupFileHook("lua/Armory.lua", "lua/CNBalance/Armory.lua", "post")
ModLoader.SetupFileHook("lua/Observatory.lua", "lua/CNBalance/Observatory.lua", "post")
ModLoader.SetupFileHook("lua/Sentry.lua", "lua/CNBalance/Sentry.lua", "replace")
ModLoader.SetupFileHook("lua/SentryBattery.lua", "lua/CNBalance/SentryBattery.lua", "post")
ModLoader.SetupFileHook("lua/ARC.lua", "lua/CNBalance/ARC.lua", "post")
ModLoader.SetupFileHook("lua/MedPack.lua", "lua/CNBalance/MedPack.lua", "post")
ModLoader.SetupFileHook("lua/Mine.lua", "lua/CNBalance/Mine.lua", "post")

ModLoader.SetupFileHook("lua/Marine.lua", "lua/CNBalance/Marine.lua", "post")
ModLoader.SetupFileHook("lua/MarineSpectator.lua", "lua/CNBalance/MarineSpectator.lua", "post")
ModLoader.SetupFileHook("lua/JetpackMarine.lua", "lua/CNBalance/JetpackMarine.lua", "post")
ModLoader.SetupFileHook("lua/Exo.lua", "lua/CNBalance/Exo.lua", "post")
ModLoader.SetupFileHook("lua/Exosuit.lua", "lua/CNBalance/Exosuit.lua", "post")

ModLoader.SetupFileHook("lua/Weapons/WeaponDisplayManager.lua", "lua/CNBalance/Weapons/WeaponDisplayManager.lua", "post" )
ModLoader.SetupFileHook("lua/Weapons/Weapon.lua", "lua/CNBalance/Weapons/Weapon.lua", "post")
ModLoader.SetupFileHook("lua/Weapons/Marine/ClipWeapon.lua", "lua/CNBalance/Weapons/Marine/ClipWeapon.lua", "post")

ModLoader.SetupFileHook("lua/Weapons/Marine/Welder.lua", "lua/CNBalance/Weapons/Marine/Welder.lua", "post")
ModLoader.SetupFileHook("lua/Weapons/Marine/Axe.lua", "lua/CNBalance/Weapons/Marine/Axe.lua", "post")
ModLoader.SetupFileHook("lua/Weapons/Marine/Pistol.lua", "lua/CNBalance/Weapons/Marine/Pistol.lua", "post")
ModLoader.SetupFileHook("lua/Weapons/Marine/Rifle.lua", "lua/CNBalance/Weapons/Marine/Rifle.lua", "post")
-- ModLoader.SetupFileHook("lua/Weapons/Marine/PulseGrenade.lua", "lua/CNBalance/Weapons/Marine/PulseGrenade.lua", "post")
ModLoader.SetupFileHook("lua/Weapons/Marine/ClusterGrenade.lua", "lua/CNBalance/Weapons/Marine/ClusterGrenade.lua", "post")
ModLoader.SetupFileHook("lua/Weapons/Marine/Shotgun.lua", "lua/CNBalance/Weapons/Marine/Shotgun.lua", "post")
ModLoader.SetupFileHook("lua/Weapons/Marine/HeavyMachineGun.lua", "lua/CNBalance/Weapons/Marine/HeavyMachineGun.lua", "post")
ModLoader.SetupFileHook("lua/GUIHeavyMachineGunDisplay.lua", "lua/CNBalance/GUI/GUIHeavyMachineGunDisplay.lua", "post")

ModLoader.SetupFileHook("lua/Weapons/Marine/GrenadeThrower.lua", "lua/CNBalance/Weapons/Marine/GrenadeThrower.lua", "post")
ModLoader.SetupFileHook("lua/Weapons/Marine/GrenadeLauncher.lua", "lua/CNBalance/Weapons/Marine/GrenadeLauncher.lua", "post")
--------------------

--Combat Weapon Hacks
ModLoader.SetupFileHook("lua/Weapons/Marine/Axe.lua", "lua/Combat/Knife.lua", "post")
ModLoader.SetupFileHook("lua/Weapons/Marine/ClipWeapon.lua", "lua/Combat/Revolver.lua", "post") 
ModLoader.SetupFileHook("lua/Weapons/Marine/ClipWeapon.lua", "lua/Combat/SubMachineGun.lua", "post")
ModLoader.SetupFileHook("lua/Weapons/Marine/ClipWeapon.lua", "lua/Combat/LightMachineGun.lua", "post")
ModLoader.SetupFileHook("lua/Weapons/Marine/ClipWeapon.lua", "lua/Combat/Cannon.lua", "post")
ModLoader.SetupFileHook("lua/Weapons/Marine/Welder.lua", "lua/Combat/CombatBuilder.lua", "post")
ModLoader.SetupFileHook("lua/BabblerEgg.lua", "lua/Combat/SporeMine.lua", "post")

-- Aliens
ModLoader.SetupFileHook( "lua/CommAbilities/Alien/HallucinationCloud.lua", "lua/CNBalance/HallucinationCloud.lua", "post" )
ModLoader.SetupFileHook( "lua/AlienHallucination.lua", "lua/CNBalance/AlienHallucination.lua", "post" )
ModLoader.SetupFileHook( "lua/Hallucination.lua", "lua/CNBalance/Hallucination.lua", "replace" )

ModLoader.SetupFileHook("lua/AlienBuy_Client.lua", "lua/CNBalance/AlienBuy_Client.lua", "post" )
ModLoader.SetupFileHook("lua/AlienTeam.lua", "lua/CNBalance/AlienTeam.lua", "post")
ModLoader.SetupFileHook("lua/AlienTechMap.lua", "lua/CNBalance/AlienTechMap.lua", "post")

ModLoader.SetupFileHook("lua/Alien.lua", "lua/CNBalance/Alien.lua", "post")
ModLoader.SetupFileHook("lua/Alien_Server.lua", "lua/CNBalance/Alien_Server.lua", "post")
ModLoader.SetupFileHook("lua/Skulk.lua", "lua/CNBalance/Lifeforms/Skulk.lua", "post")
ModLoader.SetupFileHook("lua/Skulk.lua", "lua/Prowler/Prowler.lua", "post")     --Hack
ModLoader.SetupFileHook("lua/Fade.lua", "lua/CNBalance/Lifeforms/Vokex.lua", "post")     --Hack

ModLoader.SetupFileHook("lua/Lerk.lua", "lua/CNBalance/Lifeforms/Lerk.lua", "post")
ModLoader.SetupFileHook("lua/Fade.lua", "lua/CNBalance/Lifeforms/Fade.lua", "post")
ModLoader.SetupFileHook("lua/Gorge.lua", "lua/CNBalance/Lifeforms/Gorge.lua", "post")
ModLoader.SetupFileHook("lua/Onos.lua", "lua/CNBalance/Lifeforms/Onos.lua", "post")
ModLoader.SetupFileHook("lua/Weapons/Alien/Shockwave.lua", "lua/CNBalance/Weapons/Alien/Shockwave.lua", "post")

ModLoader.SetupFileHook("lua/GUIEggDisplay.lua", "lua/CNBalance/GUIEggDisplay.lua", "post" )
ModLoader.SetupFileHook("lua/GUIAlienBuyMenu.lua", "lua/CNBalance/GUIAlienBuyMenu.lua", "post" )
ModLoader.SetupFileHook("lua/EvolutionChamber.lua", "lua/CNBalance/EvolutionChamber.lua", "post")
ModLoader.SetupFileHook("lua/AlienTunnelManager.lua", "lua/CNBalance/AlienTunnelManager.lua", "post")
ModLoader.SetupFileHook("lua/Hive.lua", "lua/CNBalance/Hive.lua", "post")
ModLoader.SetupFileHook("lua/Tunnel.lua", "lua/CNBalance/Tunnel.lua", "post")
ModLoader.SetupFileHook("lua/Crag.lua", "lua/CNBalance/Crag.lua", "post")
ModLoader.SetupFileHook("lua/TunnelEntrance.lua", "lua/CNBalance/TunnelEntrance.lua", "post")

ModLoader.SetupFileHook("lua/Cyst_Server.lua", "lua/CNBalance/Cyst_Server.lua", "post")
ModLoader.SetupFileHook("lua/Cyst.lua", "lua/CNBalance/Cyst.lua", "post")
ModLoader.SetupFileHook("lua/Hydra.lua", "lua/CNBalance/Hydra.lua", "post")
ModLoader.SetupFileHook("lua/BabblerEgg.lua", "lua/CNBalance/BabblerEgg.lua", "post")

ModLoader.SetupFileHook("lua/Weapons/Alien/Ability.lua", "lua/CNBalance/Weapons/Alien/Ability.lua", "post")
ModLoader.SetupFileHook("lua/Weapons/Alien/Web.lua", "lua/CNBalance/Weapons/Alien/Web.lua", "post")
ModLoader.SetupFileHook("lua/Weapons/Alien/Parasite.lua", "lua/CNBalance/Weapons/Alien/Parasite.lua", "post")
ModLoader.SetupFileHook("lua/Weapons/Alien/XenocideLeap.lua", "lua/CNBalance/Weapons/Alien/XenocideLeap.lua", "post")
ModLoader.SetupFileHook("lua/Weapons/Alien/Metabolize.lua", "lua/CNBalance/Weapons/Alien/Metabolize.lua", "replace")
ModLoader.SetupFileHook("lua/Weapons/Alien/BoneShield.lua", "lua/CNBalance/Weapons/Alien/BoneShield.lua", "replace")
ModLoader.SetupFileHook("lua/Weapons/Alien/BabblerPheromone.lua", "lua/CNBalance/Weapons/Alien/BabblerPheromone.lua", "post")
ModLoader.SetupFileHook("lua/Weapons/Alien/HydraAbility.lua", "lua/CNBalance/Weapons/Alien/HydraAbility.lua", "post")

--Commander
ModLoader.SetupFileHook("lua/Commander_Buttons.lua", "lua/CNBalance/Commander_Buttons.lua", "post" )
ModLoader.SetupFileHook("lua/Commander_Server.lua", "lua/CNBalance/Commander_Server.lua", "post" )
ModLoader.SetupFileHook("lua/AlienCommander.lua", "lua/CNBalance/AlienCommander.lua", "post" )
ModLoader.SetupFileHook("lua/MarineCommander.lua", "lua/CNBalance/MarineCommander.lua", "replace")

--Bot
ModLoader.SetupFileHook("lua/bots/MarineCommanerBrain_TechPath.lua", "lua/Bots/MarineCommanderBrain_TechPath.lua", "replace" )
ModLoader.SetupFileHook("lua/bots/AlienCommanderBrain_TechPathData.lua", "lua/Bots/AlienCommanderBrain_TechPathData.lua", "replace" )

if AddHintModPanel then
    local panelMaterial = PrecacheAsset("materials/CNPlaygroundBalance/Banner.material")
    AddHintModPanel(panelMaterial, "https://docs.qq.com/doc/DUEZSeUtrR0tWTGJ4","看看司马策划又改了什么东西")
end

Shared.Message("[CN] Natural Selection 2.0 Mounted 2023.1.7")