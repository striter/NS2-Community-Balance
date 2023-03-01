kTechId = enum {

    'None', 'PingLocation',

    'VoteConcedeRound',

    'SpawnMarine', 'SpawnAlien', 'CollectResources', 'TransformResources', 'Research',

    -- General orders and actions ("Default" is right-click)
    'Default', 'Move', 'Patrol', 'Attack', 'Build', 'Construct', 'AutoConstruct', 'Grow', 'Cancel', 'Recycle', 'Consume', 'Weld', 'AutoWeld', 'Stop', 'SetRally', 'SetTarget', 'Follow', 'HoldPosition', 'FollowAlien',
    -- special mac order (follows the target, welds the target as priority and others in range)
    'FollowAndWeld',

    -- Alien specific orders
    'AlienMove', 'AlienAttack', 'AlienConstruct', 'Heal', 'AutoHeal',

    -- Commander menus for selected units
    'RootMenu', 'BuildMenu', 'AdvancedMenu', 'AssistMenu', 'MarkersMenu', 'UpgradesMenu', 'WeaponsMenu','ProtosMenu',

    -- Robotics factory menus
    'RoboticsFactoryARCUpgradesMenu', 'RoboticsFactoryMACUpgradesMenu', 'UpgradeRoboticsFactory',

    'ReadyRoomPlayer', 'ReadyRoomEmbryo', 'ReadyRoomExo',

    -- Doors
    'Door', 'DoorOpen', 'DoorClose', 'DoorLock', 'DoorUnlock',

    -- Misc
    'ResourcePoint', 'TechPoint', 'SocketPowerNode', 'Mine',

    ------------/
    -- Marines --
    ------------/

    -- Marine classes + spectators
    'Marine', 'Exo', 'MarineCommander', 'JetpackMarine' , 'HeavyMarine', 'Spectator', 'AlienSpectator',

    -- Marine alerts (specified alert sound and text in techdata if any)
    'MarineAlertAcknowledge', 'MarineAlertNeedMedpack', 'MarineAlertNeedAmmo', 'MarineAlertNeedOrder', 'MarineAlertNeedStructure', 'MarineAlertHostiles', 'MarineCommanderEjected', 'MACAlertConstructionComplete',
    'MarineAlertSentryFiring', 'MarineAlertCommandStationUnderAttack',  'MarineAlertSoldierLost', 'MarineAlertCommandStationComplete',

    'MarineAlertInfantryPortalUnderAttack', 'MarineAlertSentryUnderAttack', 'MarineAlertStructureUnderAttack', 'MarineAlertExtractorUnderAttack', 'MarineAlertSoldierUnderAttack',

    'MarineAlertResearchComplete', 'MarineAlertManufactureComplete', 'MarineAlertUpgradeComplete', 'MarineAlertOrderComplete', 'MarineAlertWeldingBlocked', 'MarineAlertMACBlocked', 'MarineAlertNotEnoughResources', 'MarineAlertObjectiveCompleted', 'MarineAlertConstructionComplete',

    -- Marine orders/
    'Defend',

    -- Special tech
    'TwoCommandStations', 'ThreeCommandStations',

    -- Marine tech
    'CommandStation', 'MAC', 'Armory', 'InfantryPortal', 'Extractor', 'ExtractorArmor', 'Sentry', 'ARC',

    
    'PowerPoint', 'AdvancedArmoryUpgrade', 'Observatory', 'Detector', 'DistressBeacon', 'PhaseGate', 'RoboticsFactory', 'ARCRoboticsFactory', 'ArmsLab',
    'SentryBattery', 'PrototypeLab', 'AdvancedArmory',

    -- Weapon tech
    'ShotgunTech', 'HeavyRifleTech','HeavyMachineGunTech','GrenadeLauncherTech','AdvancedWeaponry','FlamethrowerTech', 'DetonationTimeTech', 'FlamethrowerAltTech', 'WelderTech', 'MinesTech',
    'GrenadeTech', 'ClusterGrenade', 'ClusterGrenadeProjectile', 'ClusterGrenadeProjectileFragment', 'GasGrenade', 'GasGrenadeProjectile', 'PulseGrenade', 'PulseGrenadeProjectile',
    
---------------
    'WeaponCache',

    'StandardSupply',
    'LightMachineGunUpgrade',
    'DragonBreath',
    'Cannon','CannonTech','DropCannon',

    'ExplosiveSupply',
    'MinesUpgrade','GrenadeLauncherDetectionShot','GrenadeLauncherAllyBlast','GrenadeLauncherUpgrade',
---------------

    -- Marine buys
    'FlamethrowerAlt',

    -- Research
    'AdvancedMarineSupport',
    'PhaseTech', 'MACSpeedTech', 'MACEMPTech', 'ARCArmorTech', 'ARCSplashTech', 'JetpackTech', 'ExosuitTech',
    'DualMinigunTech', 'DualMinigunExosuit', 'UpgradeToDualMinigun',
    'ClawRailgunTech', 'ClawRailgunExosuit',
    'DualRailgunTech', 'DualRailgunExosuit', 'UpgradeToDualRailgun',

    --Proto Supply Upgrade
    'ExosuitLockdownTech', 'ExosuitUpgradeTech',
    'JetpackFuelTech', 'JetpackArmorTech',
    
    -- MAC (build bot) abilities
    'MACEMP', 'Welding',

    -- Weapons
    'Rifle', 'Pistol', 'Shotgun', 'HeavyMachineGun', 'Claw', 'Minigun', 'Railgun', 'GrenadeLauncher', 'Flamethrower', 'Axe', 'LayMines', 'Welder',
    'Revolver','SubMachineGun','LightMachineGun','Knife','CombatBuilder',

    -- Armor
    'Jetpack',  'Exosuit', 'Heavy',

    -- Marine upgrades
    'Weapons1', 'Weapons2', 'Weapons3', 
    'Armor1', 'Armor2', 'Armor3',

---------------
    'CombatBuilderTech',
    'LifeSustain','NanoArmor',
---------------
    -- Activations
    'ARCDeploy', 'ARCUndeploy',

    -- Marine Commander abilities
    'NanoShield', 'PowerSurge', 'Scan', 'AmmoPack', 'MedPack', 'CatPack', 'SelectObservatory', 'ReversePhaseGate',

    
    -- Weapon drop
    'DropWelder', 'DropMines', 'DropShotgun', 'DropHeavyMachineGun', 'DropGrenadeLauncher', 'DropFlamethrower',
    'DropJetpack', 'DropExosuit', 'DropHeavy',

    ------------
    -- Aliens --
    ------------

    -- bio mass levels
    'Biomass', 'BioMassOne', 'BioMassTwo', 'BioMassThree', 'BioMassFour', 'BioMassFive', 'BioMassSix', 'BioMassSeven', 'BioMassEight', 'BioMassNine', 'BioMassTen', 'BioMassEleven', 'BioMassTwelve',
    -- those are available at the hive
    'ResearchBioMassOne', 'ResearchBioMassTwo', 'ResearchBioMassThree', 'ResearchBioMassFour',

    'DrifterEgg', 'Drifter',

    -- Alien lifeforms
    'Skulk', 'Gorge', 'Lerk', 'Fade', 'Onos', "AlienCommander", "AllAliens", "Hallucination", "DestroyHallucination",

    -- Special tech
    'TwoHives', 'ThreeHives', 'UpgradeToCragHive', 'UpgradeToShadeHive', 'UpgradeToShiftHive',

    'HydraSpike',

    'LifeFormMenu', 'SkulkMenu', 'GorgeMenu', 'LerkMenu', 'FadeMenu', 'OnosMenu',

    -- Alien structures
    'Hive', 'HiveHeal', 'CragHive', 'ShadeHive', 'ShiftHive','Harvester', 'Egg', 'Embryo', 'Hydra', 'Cyst', 'Clog', 'GorgeTunnel', 'EvolutionChamber',
    'GorgeEgg', 'LerkEgg', 'FadeEgg', 'OnosEgg',

    -- Infestation upgrades
    'MucousMembrane',

    -- personal upgrade levels
    'Shell', 'TwoShells', 'ThreeShells', 'SecondShell', 'ThirdShell', 'FullShell',
    'Veil', 'TwoVeils', 'ThreeVeils', 'SecondVeil', 'ThirdVeil', 'FullVeil',
    'Spur', 'TwoSpurs', 'ThreeSpurs', 'SecondSpur', 'ThirdSpur', 'FullSpur',

    -- Upgrade buildings and abilities (structure, upgraded structure, passive, triggered, targeted)
    'Crag', 'TwoCrags', 'CragHeal',
    'Whip', 'TwoWhips', 'EvolveBombard', 'WhipBombard', 'WhipBombardCancel', 'WhipBomb', 'Slap',
    'Shift', 'TwoShifts', 'SelectShift', 'EvolveEcho', 'ShiftHatch', 'ShiftEcho', 'ShiftEnergize',
    'Shade', 'TwoShades', 'EvolveHallucinations', 'ShadeDisorient', 'ShadeCloak', 'ShadePhantomMenu', 'ShadePhantomStructuresMenu',

    'DrifterCamouflage', 'DrifterCelerity', 'DrifterRegeneration',

    'CystCamouflage', 'CystCelerity', 'CystCarapace',

    'Return',

    'DefensivePosture', 'OffensivePosture', 'AlienMuscles', 'AlienBrain',

    'UpgradeSkulk', 'UpgradeGorge', 'UpgradeLerk', 'UpgradeFade', 'UpgradeOnos',

    'ContaminationTech', 'RuptureTech', 'BoneWallTech',

    -- Tunnnel Tech
    -- Warning: Don't change order or otherwise the tunnelmanager won't work properly
    'Tunnel', 'TunnelExit', 'TunnelRelocate', 'TunnelCollapse', 'InfestedTunnel', 'UpgradeToInfestedTunnel', 'TunnelTube',

    'BuildTunnelMenu',
    
    "BuildTunnelEntryOne", "BuildTunnelEntryTwo", "BuildTunnelEntryThree", "BuildTunnelEntryFour",
    "BuildTunnelExitOne", "BuildTunnelExitTwo", "BuildTunnelExitThree", "BuildTunnelExitFour",

    "SelectTunnelEntryOne", "SelectTunnelEntryTwo", "SelectTunnelEntryThree", "SelectTunnelEntryFour",
    "SelectTunnelExitOne", "SelectTunnelExitTwo", "SelectTunnelExitThree", "SelectTunnelExitFour",

---------------
    'FastTunnel',
---------------
    -- Skulk abilities
    'Bite', 'Sneak', 'Parasite', 'Leap', 'Xenocide',
    'SkulkBoost',
    'XenocideFuel',

-----------
    'Prowler','ProwlerMenu','ProwlerEgg','HallucinateProwler',
    'Volley','Rappel','AcidSpray',
-----------

--------
    'Vokex','VokexMenu','VokexEgg','HallucinateVokex',
    'SwipeShadowStep','MetabolizeShadowStep','AcidRocket',    
--------

    -- gorge abilities
    'Spit', 'Spray', 'BellySlide', 'BabblerTech', 'BuildAbility', 'BabblerAbility', 'Babbler', 'BabblerEgg', 'GorgeTunnelTech',
    'BuildAbility', 'BileBomb',  'WebTech', 'Web', 'HydraTech','SporeMine',

    -- lerk abilities
    'LerkBite', 'Cling', 'Spikes', 'Umbra', 'Spores',

    -- fade abilities
    'Swipe', 'Blink', 'ShadowStep', 'Vortex', 'Stab', 'MetabolizeEnergy', 'MetabolizeHealth',

    -- onos abilities
    'Gore', 'Smash', 'Charge', 'BoneShield', 'Stomp', 'Shockwave',
---------------
    'Devour',
---------------

    -- echo menu
    'TeleportHydra', 'TeleportWhip', 'TeleportTunnel', 'TeleportCrag', 'TeleportShade', 'TeleportShift', 'TeleportVeil', 'TeleportSpur', 'TeleportShell', 'TeleportHive', 'TeleportEgg', 'TeleportHarvester',

    -- Whip movement
    'WhipRoot', 'WhipUnroot',

    ---- Alien abilities and upgrades

    --CragHive
    'Vampirism',
    'Carapace',
    'Regeneration',

    --ShadeHive
    'Aura',
    'Focus',
    'Camouflage',

    --ShiftHive
    'Crush',
    'Celerity',
    'Adrenaline',

    -- Alien alerts
    'AlienAlertNeedHarvester', 'AlienAlertNeedMist', 'AlienAlertNeedDrifter', 'AlienAlertNeedHealing', 'AlienAlertStructureUnderAttack', 'AlienAlertHiveUnderAttack', 'AlienAlertHiveDying', 'AlienAlertHarvesterUnderAttack',
    'AlienAlertLifeformUnderAttack', 'AlienAlertGorgeBuiltHarvester', 'AlienCommanderEjected',
    'AlienAlertOrderComplete',
    'AlienAlertNotEnoughResources', 'AlienAlertResearchComplete', 'AlienAlertManufactureComplete', 'AlienAlertUpgradeComplete', 'AlienAlertHiveComplete', 'AlienAlertNeedStructure',

    -- Pheromones
    'ThreatMarker', 'LargeThreatMarker', 'NeedHealingMarker', 'WeakMarker', 'ExpandingMarker',

    -- Infestation
    'Infestation',

    -- Commander abilities
    'NutrientMist', 'Rupture', 'BoneWall', 'Contamination', 'SelectDrifter', 'HealWave', 'CragUmbra', 'ShadeInk', 'EnzymeCloud', 'Hallucinate', 'SelectHallucinations', 'Storm',

    -- Alien Commander hallucinations
    'HallucinateDrifter', 'HallucinateSkulk', 'HallucinateGorge', 'HallucinateLerk', 'HallucinateFade', 'HallucinateOnos',
    'HallucinateHive', 'HallucinateWhip', 'HallucinateShade', 'HallucinateCrag', 'HallucinateShift', 'HallucinateHarvester', 'HallucinateHydra',

    -- Voting commands
    'VoteDownCommander1', 'VoteDownCommander2', 'VoteDownCommander3',

    'GameStarted',

    'DeathTrigger',

    'Max' -- Unused, for legacy reasons, do NOT use!

}