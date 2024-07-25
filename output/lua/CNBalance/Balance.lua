kMatchMinPlayers = 8

--Resources system starts here
kShowDeathStatus = true
kPlayingTeamInitialTeamRes = 60   --60
kMarineInitialIndivRes = 15
kAlienInitialIndivRes = 12
kResourceTowerResourceInterval = 6
kTeamResourceWithoutTower = 0.5
kMaxEfficiencyTowers = 3
kTeamResourceEachTower = 1
kPlayerResEachTower = 0.13 kPlayerResDeductionAboveLimit = 0.0025

--Pres reward for aggressive playing (too many farmers?)
kTechDataPersonalResOnKill = {
    --Marines
    [kTechId.PowerPoint] = 0.8,
    [kTechId.MAC] = 0.3,    [kTechId.SentryBattery] = 4, [kTechId.Sentry] = 1, [kTechId.ARC] = 2.5,      --CPVE
    [kTechId.Extractor] = 3, [kTechId.PoweredExtractor] = 5,
    [kTechId.RoboticsFactory] = 3, [kTechId.ARCRoboticsFactory] = 5,
    [kTechId.Armory] = 3,[kTechId.Observatory] = 3, [kTechId.PhaseGate] = 5,
    [kTechId.CommandStation] = 12, [kTechId.StandardStation] = 15, [kTechId.ExplosiveStation] = 15, [kTechId.ArmorStation] = 15, [ kTechId.ElectronicStation ] = 15,
    [kTechId.Mine] = 0.3, [kTechId.InfantryPortal] = 2, [kTechId.MarineSentry] = 1,   --PPVE
    
    [kTechId.Shotgun] = 1.5, [kTechId.HeavyMachineGun] = 1.5, [kTechId.GrenadeLauncher] = 1.5, [kTechId.Flamethrower] = 1.5, [kTechId.Cannon] = 1.5,    --Special one for gorgie
    [kTechId.Welder] = 0.1, [kTechId.CombatBuilder] = 0.2,
    
    --Aliens
    [kTechId.Spores] = 0.1,
    [kTechId.Egg] = 0.2,[kTechId.Cyst] = 0.2, [kTechId.Drifter] = 0.3,    --[kTechId.DrifterEgg] = 0.5,
    [kTechId.Hydra] = 0.1,[kTechId.SporeMine] = 0.1,[kTechId.BabblerEgg] = 1,       --PPVE
    [kTechId.Shell] = 2.5, [kTechId.Veil] = 2.5, [kTechId.Spur] = 2.5,
    [kTechId.Whip] = 1.5, [kTechId.Shift] = 2, [kTechId.Crag] = 2, [kTechId.Shade] = 2,       --CPVE
    [kTechId.Harvester] = 2, [kTechId.Tunnel] = 3, [kTechId.InfestedTunnel] = 3, [kTechId.GorgeTunnel] = 3,
    [kTechId.Hive] = 12, [kTechId.ShiftHive] = 15, [kTechId.CragHive] = 15, [kTechId.ShadeHive] = 15,
}

--TRes reward to kill certain structures, snowball rolling
kTechDataTeamResOnKill = {
    --Marines
    [kTechId.CommandStation] = 12, [kTechId.StandardStation] = 15, [kTechId.ExplosiveStation] = 15, [kTechId.ArmorStation] = 15, [kTechId.ElectronicStation] = 15,
    
    --Aliens
    [kTechId.Hive] = 15, [kTechId.ShiftHive] = 20, [kTechId.CragHive] = 20, [kTechId.ShadeHive] = 20,
}

--If a player kills too many players and crushing the game 
kAssistMinimumDamageFraction = 0.35      --Avoid parasiter or babbler assists ,feels pretty weird
kBountyScoreEachAssist = 1 kBountyScoreEachKill = 2 kMaxBountyScore = 512       --You can't kill 256 players in a row?
kBountyClaimMinMarine = 5 kBountyClaimMinJetpack = 8 kBountyClaimMinExo = 12
kBountyClaimMinSkulk = 5 kBountyClaimMinAlien = 8 kBountyClaimMinFade = 8 kBountyClaimMinOnos = 12
kPResPerBountyClaimAsMarine = 0.25  kPResPerBountyClaimAsAlien = 0.25  kBountyClaimMultiplier = 2   kBountyCooldown = 20


--Toy for marine commander (remove all marines passive income, harsh one)
kMilitaryProtocolResearchCost = 0
kMilitaryProtocolResearchTime = 12
kMilitaryProtocolTResPerBountyClaim = 0.5
kMilitaryProtocolResearchDurationMultiply = 1.2     --1.33?
kMilitaryProtocolTeamResourcesPerKill = {          --Append kTechDataTeamResOnKill above
    [kTechId.Drifter] = 1,
    [kTechId.Harvester] = 2, [kTechId.Tunnel] = 2, [kTechId.InfestedTunnel] = 2, [kTechId.GorgeTunnel] = 3,
    [kTechId.Whip] = 2, [kTechId.Shift] = 2, [kTechId.Crag] = 2, [kTechId.Shade] = 2,
    [kTechId.Skulk] = 2, [kTechId.Gorge] = 5,[kTechId.Prowler] = 8, [kTechId.Lerk] = 10, [kTechId.Fade] = 15, [kTechId.Onos] = 18,
    [kTechId.Shell] = 2, [kTechId.Veil] = 2, [kTechId.Spur] = 2,
    [kTechId.Hive] = 15, [kTechId.ShiftHive] = 20, [kTechId.CragHive] = 20, [kTechId.ShadeHive] = 20
}
kMilitaryProtocolPlayerResourcesPerKill = {
    [kTechId.Skulk] = 1, [kTechId.Gorge] = 2, [kTechId.Prowler] = 3, [kTechId.Lerk] = 4, [kTechId.Fade] = 6, [kTechId.Onos] = 8,
}

kMarineRespawnTime = 9
kAlienSpawnTime = 10

kEggGenerationRate = 11  --13
kAlienEggsPerHive = 2

kWelderDropCost = 2
kWelderDropCooldown = 0

kMineResearchCost  = 10
kMineResearchTime  = 20

kGrenadeTechResearchCost = 10   --10
kGrenadeTechResearchTime = 20   --45

kMineCost = 10
kMineDamage = 135
kDropMineCost = 7
kDropMineCooldown = 0

kShotgunTechResearchCost = 20
kShotgunTechResearchTime = 60
kShotgunCost = 20
kShotgunDropCost = 15
kShotgunDropCooldown = 0

kRifleDamage = 10
kRifleDamageType = kDamageType.Normal
kRifleClipSize = 50

kPistolRateOfFire = 0.01
kPistolDamage = 20

kShotgunDamage = 11.33 --11.33
kShotgunDamageType = kDamageType.Normal
kShotgunClipSize = 7
kShotGunClipNum = 3
kShotgunSpreadDistance = 10
kShotgunWeapons1DamageScalar = 1.1
kShotgunWeapons2DamageScalar = 1.2
kShotgunWeapons3DamageScalar = 1.3

kHeavyMachineGunCost = 20
kHeavyMachineGunDropCost = 15
kHeavyMachineGunDropCooldown = 0

kHeavyMachineGunDamage = 7.5  --8
kHeavyMachineGunDamageType = kDamageType.MachineGun
kHeavyMachineGunClipSize = 150  --100
kHeavyMachineGunClipNum = 3 --4
kHeavyMachineGunRange = 100
kHeavyMachineGunSecondaryRange = 1.1
kHeavyMachineGunSpread = Math.Radians(5)  --4

kCommandStationCost = 20
kCommandStationUpgradeCost = 10
kCommandStationUpgradeTime = 30
kUpgradedCommandStationCost = kCommandStationCost + kCommandStationUpgradeCost

kObservatoryCost = 10
kPhaseGateCost = 15
kPhaseTechResearchCost = 10


-- Standard Supply
kDragonBreathResearchCost = 30
kDragonBreathResearchCost = 30
kDragonBreathResearchTime = 60
kLightMachineGunUpgradeCost = nil --20
kLightMachineGunUpgradeTime = nil --90

--Explosive Supply
kMinesUpgradeResearchCost = nil--10
kMinesUpgradeResearchTime = nil--60
kGrenadeLauncherUpgradeResearchCost = 25
kGrenadeLauncherUpgradeResearchTime = 60
kMineDeployCost = 4


kMACEMPBlastResearchCost = 15
kMACEMPBlastResearchTime = 60
kMACEmpBlastDetectInterval = 0.5
kMACEmpBlastDetectRadius = kPowerSurgeEMPDamageRadius
kMACEmpBlastTriggerInterval = 5

kExtractorCost = 10
kPoweredExtractorCost = 30

kPoweredExtractorResearchCost = nil--10
kPoweredExtractorResearchTime = nil--60
kPoweredExtractorUpgradeCost = 25
kPoweredExtractorUpgradeTime = 30
kPoweredExtractorChargingInterval = 5
kPoweredExtractorDamageDistance = 5
kPoweredExtractorDamage = 40
kPoweredExtractorElectrifyDuration = 5
--kGrenadeLauncherDetectionShotResearchCost = 15
--kGrenadeLauncherDetectionShotResearchTime = 60
--kGrenadeLauncherAllyBlastResearchCost = 15
--kGrenadeLauncherAllyBlastResearchTime = 60

kGrenadeLauncherCost = 20
kGrenadeLauncherDropCost = 15
kGrenadeLauncherDropCooldown = 0

kGrenadeLauncherGrenadeDamageType = kDamageType.GrenadeLauncher
kGrenadeLauncherGrenadeDamage = 100
kGrenadeLauncherGrenadeDamageRadius = 4.8

kGrenadeLauncherImpactGrenadeDamage = 80
kGrenadeLauncherDetectionShotRadius = 3.5

kGrenadeLauncherClipSize = 4

kCombatBuilderResearchCost = 10
kCombatBuilderResearchTime = 20

--Armor Supply
kLifeSustainResearchCost = 15
kLifeSustainResearchTime = 60
kNanoArmorResearchCost = 30
kNanoArmorResearchTime = 90

--Revolver
kRevolverRateOfFire = 0.1
kRevolverDamage = 27.5
kRevolverDamageType = kDamageType.Normal
kRevolverClipSize = 6
kRevolverNumClips = 5
kRevolverCost = 0
kRevolverWeight = 0.01
--

--SubMachineGun
kSubMachineGunClipSize = 42
kSubMachineGunClipNum = 5
kSubMachineGunWeight = 0.08
kSubMachineGunDamage = 11
kSubMachineGunDamageType = kDamageType.Normal
kSubMachineGunCost = 0
kSubMachineGunPointValue = 0
-- kSubMachineGunTechResearchCost = 15
-- kSubMachineGunTechResearchTime = 30
--

kRifleMeleeDamage = 10

--Knife
kKnifeWeight = -0.05
kKnifeDamage = 20
kKnifeRange = 1.3
kKnifeCost = 0
kKnifeDamageType = kDamageType.Structural
--

kAxeDamage = 25
kAxeDamageType = kDamageType.Structural

--Light Machine Gun
kLightMachineGunClipSize = 55
kLightMachineGunClipNum = 4
kLightMachineGunWeight = 0.11
kLightMachineGunDamage = 10
kLightMachineGunDamageType = kDamageType.Normal
kLightMachineGunCost = 0
kLightMachineGunAcquireCost = 30
kLightMachineGunPointValue = 0

--Heavy Marine
kHeavyMarineHealth = 200
kHeavyMarineArmor = 150
kHeavyMarineArmorPerUpgradeLevel = 40


kFlamethrowerCost = 20
kFlamethrowerDropCost = 15
kFlamethrowerDropCooldown = 0

kOnFireHealingScalar = 1
kOnFireEnergyRecuperationScalar = 0.66

kFirePlayerDOTDelay = 1
kPlayerFireDOTPerSecond = 3
kDragonBreathPlayerFireDamagePerStack = { 0.7 , 0.8 , 0.9 , 1 }  kFlameThrowerPlayerFireDamagePerStack = { 5 , 5 , 5 , 5 }
kPlayerFireDamageMaxStack = { 12, 16, 20, 24 }

kFireStructureDOTDelay = 0.5
kStructureFireDOTPerSecond = 8.0
kDragonBreathStructureFireDamagePerStack = { kStructureFireDOTPerSecond / 100, kStructureFireDOTPerSecond / 90,kStructureFireDOTPerSecond/ 80, kStructureFireDOTPerSecond / 70 }--kStructureFireDOTPerSecond / 20, kStructureFireDOTPerSecond / 18, kStructureFireDOTPerSecond / 16, kStructureFireDOTPerSecond / 14}
kFlamethrowerStructureDamagePerStack = { kStructureFireDOTPerSecond, kStructureFireDOTPerSecond, kStructureFireDOTPerSecond, kStructureFireDOTPerSecond }
kStructureFireDamageMaxStack = { kStructureFireDOTPerSecond * 3 , kStructureFireDOTPerSecond * 4, kStructureFireDOTPerSecond * 5, kStructureFireDOTPerSecond * 6  }

kMinigunDamage = 9
kMinigunDamageType = kDamageType.Exosuit
kRailgunDamage = 10
kRailgunChargeDamage = 150
kRailgunDamageType = kDamageType.Exosuit

kPulseGrenadeDamageRadius = 4
kPulseGrenadeEnergyDamageRadius = 4
kPulseGrenadeDamage = 90  --75
kPulseGrenadeEnergyDamage = 35  --25

kClusterGrenadeDamageRadius = 10
kClusterGrenadeDamage = 80
kClusterGrenadeDamageType = kDamageType.ClusterFlame

kClusterFragmentDamageRadius = 6
kClusterFragmentDamage = 20
kClusterGrenadeFragmentDamageType = kDamageType.ClusterFlameFragment

kInfantryPortalBuildTime = 7
kInfantryPortalCost = 15

kRoboticsFactoryCost = 10
kUpgradeRoboticsFactoryCost = 5
kUpgradeRoboticsFactoryTime = 20
kARCDamage = 570
kARCCost = 15
kARCBuildTime = 5
kMACCost = 4

kSentryDamage = 4  kSentryWeapon1Scalar = 1.125 kSentryWeapon2Scalar = 1.25 kSentryWeapon3Scalar = 1.375
kSentryCost = 4
kSentryBuildTime = 3
kSentryBatteryCost = 12
kSentryBatteryBuildTime = 5

kAdvancedArmoryUpgradeCost = 25
kAdvancedArmoryResearchTime = 90
kPrototypeLabCost = 25

kCannonTechResearchCost = 20
kCannonTechResearchTime = 120

kJetpackTechResearchCost = 25
kJetpackTechResearchTime = 120

kExosuitTechResearchCost = 20
kExosuitTechResearchTime = 120

kRoboticsFactoryBuildTime = 8

kJetpackCost = 25
kJetpackDropCost = 18
kJetpackDropCooldown = 0

--Cannon
kCannonCost = 25
kCannonDropCost = 18

kCannonDamage = 25
kCannonAoeRadius = 2.5
kCannonRateOfFire = 0.88
kCannonAoeDamage = 80
kCannonClipSize = 6
kCannonPointValue = 15
kCannonDamageType = kDamageType.Exosuit

kDualExosuitCost = 55
kDualRailgunExosuitCost = 55
kDualExosuitDropCost = 36
kExosuitCost = kDualExosuitCost   --Used in some ways... (newcomer protection from )

kOnosDevourCost = 10
kOnosDevourTime = 40

kUmbraBulletModifier = 0.8

kDevourEnergyCost = 55 --50
kDevourPunchDamage = 65 --100

kTunnelUpgradeTime = 60
kShiftTunnelUpgradeCost = 25
kShadeTunnelUpgradeCost = 15
kCragTunnelUpgradeCost = 15

kEggGestateTime = 15
kGorgeCost = 10
kGorgeEggCost = 15
kLerkCost = 21
kLerkEggCost = 30
kFadeCost = 37
kFadeEggCost = 70
kOnosCost = 62
kOnosEggCost = 100

kTunnelEntranceCost = 7
kTunnelRelocateCost = 5

--Research with skill activation
kResearchBioMassOneCost = 30
kBioMassOneTime = 45
kResearchBioMassTwoCost = 50
kBioMassTwoTime = 60
kResearchBioMassThreeCost = 65
kBioMassThreeTime = 90

--Recover
kRecoverBioMassOneCost = 10
kRecoverBioMassOneTime = 15
kRecoverBioMassTwoCost = 15
kRecoverBioMassTwoTime = 20
kRecoverBioMassThreeCost = 20
kRecoverBioMassThreeTime = 25

--Skulk
kParasiteEnergyCost = 30
kAdrenalineParasiteEnergyCost = 17.5
kParasiteDamageType = kDamageType.Normal

kXenocideResearchCost = 20
kXenocideResearchTime = 60

kXenocideFuelCost = 35
kXenocideFuelTime = 120

kXenocideEnergyCost = 30
kXenocideDamageType = kDamageType.Structural
kXenocideDamage = 150  kXenocideFuelDamage = 210 --200
kXenocideRange = 8 kXenocideFuelRange = 12 -- 14
kXenocideDamageScalarEmptyHealth = 0.2 kXenocideDamageHealthScalar = 1 - kXenocideDamageScalarEmptyHealth
kXenocideSpawnReduction = 1 kXenocideFuelSpawnReduction = 0.5

kBileBombResearchCost = 10
kBileBombResearchTime = 40

--Lerk
kSpikeSpread = Math.Radians(3.8)
kUmbraResearchCost = 20
kSporesResearchCost = 20
kSporesResearchTime = 60

-- Prowler
kProwlerCost = 18 --14
kProwlerGestateTime = 6
kProwlerUpgradeCost = 1

kVolleySpread = Math.Radians(3)
kProwlerDamagePerPellet = 8 -- there are 6 pellets
kVolleyRappelDamageType = kDamageType.Normal
kVolleyEnergyCost = 7.0 --7.0
kVolleyWebTime = 1.5

kRappelDamage = 10 kRappelContinuousDamage = 5 kRappelContinuousDamageAgainstStructure = 80
kRappelReelInitialSpeed = 10 kRappelReelContinuousSpeed = 4
kRappelResearchCost = 10
kRappelResearchTime = 20
kRappelEnergyCost = 15
kRappelReelEnergyCost = 20
kRappelRange = 25

kAcidSprayResearchCost = 10
kAcidSprayResearchTime = 60
kAcidSprayEnergyCost = 22
kAcidSprayDamage = 20  -- 3 missiles
kAcidSprayDamageType = kDamageType.Normal

-- Fade
kSwipeDamageType = kDamageType.Puncture
kSwipeDamage = 40
kSwipeEnergyCost = 7

kStabDamage = 119
kStabDamageType = kDamageType.Structural
kStabEnergyCost = 29

kStartBlinkEnergyCost = 11 --12
kBlinkEnergyCost = 30 --32
kHealthOnBlink = 0

--Vokex
kVokexCost = 42
kVokexUpgradeCost = 6

kVokexShadowStepStartCost = 15
kVokexShadowStepCost = 15

kVokexGestateTime = 25
kVokexEggCost = 80
kVokexBabblerShieldPercent = 0.25

kShadowStepResearchCost = 15
kShadowStepResearchTime = 40

kAcidRocketResearchCost = 25
kAcidRocketResearchTime = 40

kAcidRocketVelocity = 35
kAcidRocketEnergyCost = 15
kAcidRocketFireDelay = 0.01
kAcidRocketBombDamageType = kDamageType.Normal
kAcidRocketBombDamage = 30
kAcidRocketBombRadius = 0.3
kAcidRocketBombSplashRadius = 4
kAcidRocketBombDotIntervall = 0.5
kAcidRocketBombDotDamage = 10
kAcidRocketBombDuration = 1

-- Onos
kBoneShieldResearchCost = 20
kBoneShieldResearchTime = 40

kStompResearchCost = 25
kStompResearchTime = 90

kChargeEnergyCost = 22
kChargeDamage = 12

kBoneShieldCooldown = 16
kBoneShieldMinimumEnergyNeeded = 0
kBoneShieldMinimumFuel = 0.15
kBoneShieldMaxDuration = 10

kStompEnergyCost = 40
kStompDamageType = kDamageType.Structural
kStompDamage = 60
kStompFirstPDamage = 0  kStompDisruptTime = 3
kStompSecondPDamage = 0 kStompSecondDisruptTime = 1.5
kStompElseDamage = 0
kStompRange = 12 



kDisruptMarineTimeout = 4

kBabblerShieldPercent = 0.1
kSkulkBabblerShieldPercent = 0.23
kGorgeBabblerShieldPercent = 0.15
kLerkBabblerShieldPercent = 0.16
kFadeBabblerShieldPercent = 0.16
kProwlerBabblerShieldPercent = 0.18

kBabblerShieldMaxAmount = 120
kWebZeroVisDistance = 3.0
kWebFullVisDistance = 2.0
kWhipCost = 10
kShadeCost = 12
kShiftCost = 12
kCragCost = 12

kSpurCost = 15
kShellCost = 15
kVeilCost = 15

kContaminationCost = 5
kContaminationCooldown = 10
kBoneWallCost = 3
kRuptureCost = 1
kDrifterCost = 6

kHydraDamage = 15
kHydraAttackDamageType = kDamageType.Normal
kHealsprayDamage = 10
kBabblerCost = 3

kEchoWhipCost = 2
kEchoCragCost = 2
kEchoShadeCost = 2
kEchoShiftCost = 2
kEchoVeilCost = 2
kEchoSpurCost = 2
kEchoShellCost = 2
kEchoEggCost = 1

kShadeHiveInkCooldown = 17.5
kNormalShadeInkCooldown = kShadeHiveInkCooldown + kShadeInkDuration
kShadeInkDuration = 6.3

kWhipSlapDamage = 50
kWhipBombardDamage = 45
kWhipBombardDamageType = kDamageType.Structural

kObservatoryScanCost = 4
kScanCooldown = 5
kObservatoryDistressBeaconCost = 10

kArmsLabCost = 15

kWeapons1ResearchCost = 25 kWeapons1ResearchTime = 75
kWeapons2ResearchCost = 35 kWeapons2ResearchTime = 105
kWeapons3ResearchCost = 45 kWeapons3ResearchTime = 135

kArmor1ResearchCost = 25 kArmor1ResearchTime = 75
kArmor2ResearchCost = 35 kArmor2ResearchTime = 105
kArmor3ResearchCost = 45 kArmor3ResearchTime = 135

kAdvancedMarineSupportResearchCost = 20
kAdvancedMarineSupportResearchTime = 90
kAmmoPackCost = 1
kAmmoPackCooldown = 0
kMedPackCost = 1
kMedPackCooldown = 0

kCatPackCost = 1
kCatPackCooldown = 0
kCatPackMoveAddSpeed = 1.25
kCatPackWeaponSpeed = 1.5
kCatPackDuration = 5
kCatPackPickupDelay = 4

kPowerSurgeCost = 3
kPowerSurgeCooldown = 5
kPowerSurgeDuration = 10
kPowerSurgeTriggerEMP = true
kPowerSurgeEMPDamage = 20  kEMPDamageWeapons1Scalar = 1.25 kEMPDamageWeapons2Scalar = 1.5 kEMPDamageWeapons3Scalar = 1.75
kPowerSurgeEMPDamageRadius = 6
kPowerSurgeEMPElectrifiedDuration = 2

kNanoShieldPlayerDuration = 3
kNanoShieldStructureDuration = 5
kNanoShieldCost = 3
kNanoShieldCooldown = 5
kNanoShieldDamageReductionDamage = 0.68

kWelderPointValue = 1

kCombatBuilderCost = 3
kCombatBuilderDropCost = 5
kCombatBuilderPointValue = 2

kMarineSentryCost = 2
kMarineSentryPersonalCost = 10
kMarineSentryDamage = 3  kMarineSentryWeapon1Scalar = 1.11  kMarineSentryWeapon2Scalar = 1.22 kMarineSentryWeapon3Scalar = 1.33
kMarineSentryBuildTime = 3

kWeaponCacheCost = 3
kWeaponCachePersonalCost = 15
kWeaponCacheBuildTime = 6
kWeaponCachePersonalCarries = 1
kMarineSentryPersonalCarries = 2

kMotionTrackInterval = 6
kMotionTrackMinSpeed = 5
kMotionTrackResearchCost = 35
kMotionTrackResearchTime = 90

kSporeMineCost = 0
kSporeMineBuildTime = 4
kNumSporeMinesPerGorge = 1
kSporeMineDamage = 125 -- per second
kSporeMineDamageType = kDamageType.Corrode
kSporeMineDamageDuration = 3
kSporeMineDamageRadius = 5
kSporeMineDotInterval = 0.4

kSporeMineCloudCastRadius = 20
kSporeMineCloudCastInterval = 3
kSporeMineCloudTravelSpeed = 5

--Babbler Egg

--Explode
kBabblerEggBuildTime = 8
kNumBabblerEggsPerGorge = 1
kBabblerEggDamage = 125
kBabblerEggDamageType = kDamageType.Corrode
kBabblerEggDamageDuration = 3
kBabblerEggDamageRadius = 7
kBabblerEggDotInterval = 0.4

kBabblerDamage = 8
kBabblerExplosionRange = 4
kBabblerExplosionDamage = 16
kBabblerDamageType = kDamageType.Normal
kBabblerCost = 0

--Hatch
kBabblerExplodeAmount = 6
kBabblerEggHatchInterval = 3
kBabblerEggHatchRadius = 22

kDrifterHatchTime = 12
--
kMarkerCost = 0 kMarkerCooldown = 5 
kRallyCost = 0 kRallyCooldown = 30
kRallyRadius = 4
kRallyResultDuration = 5
kRallyScoreEachDuration = 2
kRallyPResEachDuration = 0.2

kGorgeDropCooldown = 1
kGorgeDropEnergyReductionPerBiomass = 0.09
kGorgeDropCooldownReductionPerBiomass = 0.09
kGorgeReductionMin = 0.1

kHydraCost = 0
kClogCost = 0
kGorgeTunnelCost = 4
kGorgeTunnelBuildTime = 18.5

kBalanceOffInfestationHurtPercentPerSecond = 0.02
kMinOffInfestationHurtPerSecond = 20

kOriginFormResearchCost = 0
kOriginFormResearchTime = 12

kOriginFormOnInfestationHealPercentPerSecond = 0.01
kOriginFormOnInfestationMinHealPerSecond = 10

kGorgeAbilitiesCost = {
    [kTechId.Hydra] = 0, [kTechId.Clog] = 0, [kTechId.Web] = 0,[kTechId.SporeMine] = 0, [kTechId.BabblerEgg] = 3,
    [kTechId.Cyst] = 0.5,    [kTechId.Egg] = 1.5, [kTechId.Tunnel] = 4, [kTechId.TunnelExit] = 4,
    [kTechId.Whip] = 8, [kTechId.Shift] = 12, [kTechId.Shade] = 12, [kTechId.Crag] = 12,
    [kTechId.Harvester] = 8, [kTechId.ShiftHive] = 40, [kTechId.CragHive] = 40, [kTechId.ShadeHive] = 40,
                         [kTechId.Spur] = 12, [kTechId.Shell] = 12, [kTechId.Veil] = 12,
}
kGorgeStructureScorePerRes = 0.4
kOriginPersonalResourcesPerKill = {
    [kTechId.Marine] = 2, [kTechId.JetpackMarine] = 3, [kTechId.Exo] = 4, [kTechId.Exosuit] = 2,
}

kGorgeHiveBuildTime = kHiveBuildTime

kOriginFormAdditionalTRes = 40
kOriginFormInitialGorgePRes = 60
kOriginFormExtraGorgePRes = 20
kOriginFormTeamResourceFetchThreshold = 10
kOriginFormTeamResScalarHiveCount = { 0.75 , 0.25 , 0.125 , 0.125 , 0.125 , 0.125,0.125}

kBiomassPerTower = {0,1,3,6}
function GetOriginFormBiomassLevel(count)
    local level = 0
    for _,v in ipairs(kBiomassPerTower) do
        if count >= v then
            level = level + 1
        end
    end
    return level
end

kTechRespawnTimeExtension = 
{
    --[kTechId.Armor1] = 0,[kTechId.Weapons1] = 0, [kTechId.Observatory] = 0,
    --[kTechId.MinesTech] = 0,[kTechId.ShotgunTech] = 0,
    [kTechId.Armor2] = 1,[kTechId.Weapons2] = 1, [kTechId.Armor3] = 2, [kTechId.Weapons3] = 2,
    [kTechId.PhaseGate] = 1, [kTechId.AdvancedArmory] = 1,
    [kTechId.ExosuitPrototypeLab] = 2, [kTechId.JetpackPrototypeLab] = 2, [kTechId.CannonPrototypeLab] = 2,
    [kTechId.DragonBreath] = 2, [kTechId.ArmorRegen] = 2,  [kTechId.MotionTrack] = 2, --[kTechId.MACEmpBlast] = 1,[kTechId.GrenadeLauncherUpgrade] = 1,
    
    --[kTechId.BioMassOne] = 0, [kTechId.BioMassTwo] = 0, 
    [kTechId.BioMassThree] = 1, [kTechId.BioMassFour] = 1, [kTechId.BioMassFive] = 1, [kTechId.BioMassSix] = 1,
    [kTechId.TwoVeils] = 1,[kTechId.ThreeVeils] = 1,[kTechId.TwoShells] = 1,[kTechId.ThreeShells] = 1,[kTechId.TwoSpurs] = 1, [kTechId.ThreeSpurs] = 1,
    [kTechId.BioMassSeven] = 2, [kTechId.BioMassEight] = 2,
    [kTechId.BioMassNine] = 3, [kTechId.BioMassTen] = 3,
    --[kTechId.BioMassEleven] = 1, [kTechId.BioMassTwelve] = 1,
}
