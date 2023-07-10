--Resources system starts here
kPlayingTeamInitialTeamRes = 60   --60
kMarineInitialIndivRes = 15
kAlienInitialIndivRes = 12
kResourceTowerResourceInterval = 6
kTeamResourceWithoutTower = 0.5
kMaxEfficiencyTowers = 4
kTeamResourceEachTower = 1
kTeamResourceEachTowerAboveThreshold = 0.5
kPlayerResEachTower = 0.125
kPlayerResEachTowerAboveThreshold = 0.05

--Pres reward for aggressive playing (too many farmers?)
kTechDataPersonalResOnKill = {
    --Marines
    [kTechId.Extractor] = 2.5, [kTechId.PoweredExtractor] = 4,
    [kTechId.RoboticsFactory] = 2.5, [kTechId.ARCRoboticsFactory] = 2.5,
    [kTechId.Armory] = 1,[kTechId.Observatory] = 2.5, [kTechId.PhaseGate] = 4,
    [kTechId.CommandStation] = 10, [kTechId.StandardStation] = 15, [kTechId.ExplosiveStation] = 15, [kTechId.ArmorStation] = 15, [ kTechId.ElectronicStation ] = 15,
    [kTechId.Mine] = 0.2, [kTechId.InfantryPortal] = 2, [kTechId.MarineSentry] = 0.8,   --PPVE
    [kTechId.MAC] = 0.2,    [kTechId.SentryBattery] = 4, [kTechId.Sentry] = 1,[kTechId.ARC] = 2.5,      --CPVE
    [kTechId.Shotgun] = 1, [kTechId.HeavyMachineGun] = 1, [kTechId.GrenadeLauncher] = 1, [kTechId.Flamethrower] = 1,     --Special one for gorgie

    --Aliens
    [kTechId.Egg] = 0.2,[kTechId.Cyst] = 0.2,
    [kTechId.Hydra] = 0.2,[kTechId.SporeMine] = 0.2,[kTechId.BabblerEgg] = 2,       --PPVE
    [kTechId.Shell] = 5, [kTechId.Veil] = 5, [kTechId.Spur] = 5,
    [kTechId.Whip] = 2.5, [kTechId.Shift] = 5, [kTechId.Crag] = 5, [kTechId.Shade] = 5,       --CPVE
    [kTechId.Harvester] = 5, [kTechId.Tunnel] = 5, [kTechId.InfestedTunnel] = 7.5,
    [kTechId.Hive] = 15, [kTechId.ShiftHive] = 20, [kTechId.CragHive] = 20, [kTechId.ShadeHive] = 20,
}

--TRes reward to kill certain structures, snowball rolling
kTechDataTeamResOnKill = {
    --Marines
    [kTechId.ARC] = 4,      --Super aggressive one i mean
    [kTechId.CommandStation] = 15, [kTechId.StandardStation] = 20, [kTechId.ExplosiveStation] = 20, [kTechId.ArmorStation] = 20, [kTechId.ElectronicStation] = 20,
    
    --Aliens
    [kTechId.Hive] = 15, [kTechId.ShiftHive] = 20, [kTechId.CragHive] = 20, [kTechId.ShadeHive] = 20,
}

-- Resource refund base on teams total income minus (anti snowball,could cause "miracle")
kTeamResourceRefundBase = 100
kTechDataTeamResRefundOnKill = {
    [kTechId.Exo] = 10,  [kTechId.JetpackMarine] = 5,  --[kTechId.Exosuit] = 0.05, Aint working due to its not attached with pointgivermixin
    [kTechId.Gorge] = 3, [kTechId.Prowler] = 5, [kTechId.Lerk] = 8, [kTechId.Fade] = 10, [kTechId.Onos] = 15,
    [kTechId.Extractor] = 10, [kTechId.PoweredExtractor] = 10, [kTechId.Harvester] = 10,
    [kTechId.PhaseGate] = 10, [kTechId.Tunnel] = 10,[kTechId.InfestedTunnel] = 10,
}

--If a player kills too many players and crushing the game 
kAssistMinimumDamageFraction = 0.3      --Avoid parasiter or babbler assists ,feels pretty weird
kBountyScoreEachAssist = 1 kBountyScoreEachKill = 2 kMaxBountyScore = 512       --You can't kill 256 players in 1 life
kBountyClaimMinMarine = 7 kBountyClaimMinJetpack = 9 kBountyClaimMinExo = 12 
kBountyClaimMinSkulk = 7 kBountyClaimMinAlien = 10  kBountyClaimMinOnos = 14
kPResPerBountyClaimAsMarine = 0.4  kPResPerBountyClaimAsAlien = 0.25  kBountyClaimMultiplier = 2   kBountyCooldown = 24
kBountyTargetDamageReceiveStep = 18  kBountyDamageReceiveBaseEachStep = (0.1 / kBountyTargetDamageReceiveStep)      --0-10%,20%-40%,40%-80%, increase its damage receive by steps.

--Toy for marine commander (remove all marines passive income, harsh one)
kMilitaryProtocolResearchCost = 10
kMilitaryProtocolResearchTime = 20
kMilitaryProtocolResearchDurationMultiply = 1.2     --1.33?
kMilitaryProtocolAggressivePersonalResourcesScalar = 2      --They don't need too much pres to buy defensive or grenades/welders (and they can shared it tbh)
kMilitaryProtocolTResPerBountyClaim = 0.5   --Bounty score, don't give them pres, its doomed
kMilitaryProtocolTeamResourcesPerKill = {          --Use this when military protocol enabled
    [kTechId.Harvester] = 2, [kTechId.Tunnel] = 2, [kTechId.InfestedTunnel] = 2,
    [kTechId.Whip] = 2, [kTechId.Shift] = 2, [kTechId.Crag] = 2, [kTechId.Shade] = 2,
    [kTechId.Skulk] = 1.5, [kTechId.Gorge] = 2,[kTechId.Prowler] = 2, [kTechId.Lerk] = 2, [kTechId.Fade] = 3, [kTechId.Onos] = 3,
    [kTechId.Shell] = 2, [kTechId.Veil] = 2, [kTechId.Spur] = 2,
    [kTechId.Hive] = 15, [kTechId.ShiftHive] = 20, [kTechId.CragHive] = 20, [kTechId.ShadeHive] = 20,
}
kMilitaryProtocolPassiveTeamResourceResearchesScalar = {
    [kTechId.MinesTech] = 0.1, [kTechId.ShotgunTech] = 0.2, 
    [kTechId.AdvancedArmory] = 0.2, [kTechId.JetpackTech] = 0.2, [kTechId.ExosuitTech] = 0.3,
}
kMilitaryProtocolResourcesScalarPlayerAboveLimit = 0.1  --Multiply upon one

kMatchMinPlayers = 10
kRespawnPlayersMinExtend = 2
kRespawnTimeExtendPerPlayer = 1
kMarineRespawnTime = 9
kAlienSpawnTime = 10

kEggGenerationRate = 11  --13
kAlienEggsPerHive = 2

kWelderDropCost = 2
kWelderDropCooldown = 0

kMineResearchCost  = 10
kMineResearchTime  = 45

kGrenadeTechResearchCost = 10   --10
kGrenadeTechResearchTime = 45   --45

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
kRifleClipSize = 50  kMPRifleClipSize = {52,53,54,55}

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
kCommandStationUpgradeTime = 60
kUpgradedCommandStationCost = kCommandStationCost + kCommandStationUpgradeCost

kExtractorCost = 10
kPoweredExtractorCost = 30

-- Standard Supply
kDragonBreathResearchCost = 15
kDragonBreathResearchTime = 60
kLightMachineGunUpgradeCost = 20
kLightMachineGunUpgradeTime = 90
kCannonTechResearchCost = 30
kCannonTechResearchTime = 90

--Explosive Supply
kMinesUpgradeResearchCost = 10
kMinesUpgradeResearchTime = 60
kGrenadeLauncherUpgradeResearchCost = 20
kGrenadeLauncherUpgradeResearchTime = 75
kMACEMPBlastResearchCost = 15
kMACEMPBlastResearchTime = 60
kMACEmpBlastDetectInterval = 0.5
kMACEmpBlastDetectRadius = kPowerSurgeEMPDamageRadius
kMACEmpBlastTriggerInterval = 5

kPoweredExtractorResearchCost = 10
kPoweredExtractorResearchTime = 60
kPoweredExtractorUpgradeCost = 20
kPoweredExtractorUpgradeTime = 45
kPoweredExtractorChargingInterval = 2.5
kPoweredExtractorDamageDistance = 3
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
kGrenadeLauncherDetectionShotRadius = 3

kGrenadeLauncherClipSize = 4

kGrenadeLauncherImpactGrenadeDamage = 100

kGrenadeLauncherWeapons1DamageScalar = 1.1
kGrenadeLauncherWeapons2DamageScalar = 1.2
kGrenadeLauncherWeapons3DamageScalar = 1.3

kCombatBuilderResearchCost = 15
kCombatBuilderResearchTime = 60

--Armor Supply
kLifeSustainResearchCost = 15
kLifeSustainResearchTime = 60
kNanoArmorResearchCost = 25
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
kLightMachineGunClipSize = 50
kLightMachineGunClipNum = 4
kLightMachineGunWeight = 0.11
kLightMachineGunDamage = 10.5
kLightMachineGunDamageType = kDamageType.Normal
kLightMachineGunCost = 0
kLightMachineGunPointValue = 0

--Heavy Marine
kHeavyMarineHealth = 200
kHeavyMarineArmor = 150
kHeavyMarineArmorPerUpgradeLevel = 40

--Cannon
kCannonCost = 20

kCannonDamage = 95
kCannonRateOfFire = 0.7
kCannonAoeDamage = 0
kCannonSelfDamage = kCannonAoeDamage
kCannonClipSize = 6
kCannonPointValue = 15
kCannonDamageType = kDamageType.Structural
kCannonDropCost = 15

kFlamethrowerCost = 20
kFlamethrowerDropCost = 15
kFlamethrowerDropCooldown = 0

kFirePlayerDOTDelay = 1
kPlayerFireDOTPerSecond = 3
kDragonBreathPlayerFireDamagePerStack = { 1 , 1.1 , 1.2 , 1.3 }
kFlameThrowerPlayerFireDamagePerStack = { 6 , 6 , 6 , 6 }
kPlayerFireDamageMaxStack = { 12, 18, 24, 30 }
kFireStructureDOTDelay = 0.5
kStructureFireDOTPerSecond = 8.0
kDragonBreathStructureFireDamagePerStack = { kStructureFireDOTPerSecond / 100, kStructureFireDOTPerSecond / 90,kStructureFireDOTPerSecond/ 80, kStructureFireDOTPerSecond / 70 }--kStructureFireDOTPerSecond / 20, kStructureFireDOTPerSecond / 18, kStructureFireDOTPerSecond / 16, kStructureFireDOTPerSecond / 14}
kFlamethrowerStructureDamagePerStack = { kStructureFireDOTPerSecond, kStructureFireDOTPerSecond, kStructureFireDOTPerSecond, kStructureFireDOTPerSecond }
kStructureFireDamageMaxStack = { kStructureFireDOTPerSecond * 3 , kStructureFireDOTPerSecond * 4, kStructureFireDOTPerSecond * 5, kStructureFireDOTPerSecond * 6  }

kMinigunDamage = 8.5
kMinigunDamageType = kDamageType.Exosuit
kRailgunDamage = 10
kRailgunChargeDamage = 140
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
kARCCost = 15
kARCBuildTime = 10
kMACCost = 4

kSentryDamage = 4  kSentryWeapon1Scalar = 1.125 kSentryWeapon2Scalar = 1.25 kSentryWeapon3Scalar = 1.375
kSentryCost = 3
kSentryBuildTime = 3
kSentryBatteryCost = 10
kSentryBatteryBuildTime = 5

kAdvancedArmoryUpgradeCost = 25
kAdvancedArmoryResearchTime = 90
kRoboticsFactoryBuildTime = 8

kPrototypeLabCost = 35

kJetpackTechResearchCost = 25
kJetpackTechResearchTime = 90
kJetpackCost = 25
kJetpackDropCost = 18
kJetpackDropCooldown = 0

kExosuitTechResearchCost = 20
kExosuitTechResearchTime = 90
kDualExosuitCost = 55
kDualRailgunExosuitCost = 55
kDualExosuitDropCost = 40
kExosuitCost = kDualExosuitCost   --Used in some ways... (newcomer protection from )

kOnosDevourCost = 10
kOnosDevourTime = 40

kUmbraBulletModifier = 0.8

kDevourEnergyCost = 55 --50
kDevourPunchDamage = 70 --100

kTunnelUpgradeCost = 15
kTunnelUpgradeTime = 60

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
kResearchBioMassTwoCost = 45
kBioMassTwoTime = 60
kResearchBioMassThreeCost = 60
kBioMassThreeTime = 90

--Recover
kRecoverBioMassOneCost = 10
kRecoverBioMassOneTime = 20
kRecoverBioMassTwoCost = 15
kRecoverBioMassTwoTime = 3
kRecoverBioMassThreeCost = 20
kRecoverBioMassThreeTime = 40

--Skulk
kParasiteEnergyCost = 30
kAdrenalineParasiteEnergyCost = 18

kXenocideResearchCost = 20
kXenocideResearchTime = 60

kXenocideFuelCost = 35
kXenocideFuelTime = 120

kXenocideEnergyCost = 30
kXenocideDamageType = kDamageType.Structural
kXenocideDamage = 120  kXenocideFuelDamage = 160 --200
kXenocideRange = 9 kXenocideFuelRange = 12 -- 14
kXenocideSpawnReduction = 0.75 kXenocideFuelSpawnReduction = 0.5

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
kRappelDamage = 10
kRappelParasiteTime = 5
kRappelWebTime = 2 kVolleyWebTime = 1

kRappelResearchCost = 10
kRappelResearchTime = 20
kRappelEnergyCost = 15
kRappelReelEnergyCost = 12
kRappelRange = 35

kAcidSprayResearchCost = 10
kAcidSprayResearchTime = 60
kAcidSprayEnergyCost = 22
kAcidSprayDamage = 20  -- 3 missiles
kAcidSprayDamageType = kDamageType.Structural

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

kAcidRocketVelocity = 40
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
kChargeDamage = 12
kStompEnergyCost = 35
kStompDamageType = kDamageType.Structural
kStompDamage = 45
kStompRange = 12

kDisruptMarineTime = 1
kDisruptMarineTimeout = 2

kBabblerShieldPercent = 0.1
kSkulkBabblerShieldPercent = 0.23
kGorgeBabblerShieldPercent = 0.15
kLerkBabblerShieldPercent = 0.16
kFadeBabblerShieldPercent = 0.16
kProwlerBabblerShieldPercent = 0.18

kBabblerShieldMaxAmount = 120
kWebZeroVisDistance = 3.0
kWebFullVisDistance = 2.0
kWhipCost = 8
kShadeCost = 10
kShiftCost = 10
kCragCost = 10

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
kEchoVeilCost = 4
kEchoSpurCost = 4
kEchoShellCost = 4
kEchoEggCost = 1

kObservatoryScanCost = 3
kScanCooldown = 0
kObservatoryDistressBeaconCost = 10

kArmsLabCost = 15

kWeapons1ResearchTime = 75
kWeapons2ResearchTime = 105
kWeapons3ResearchTime = 135

kWeapons1ResearchCost = 20
kWeapons2ResearchCost = 30
kWeapons3ResearchCost = 40

kArmor1ResearchTime = 75
kArmor2ResearchTime = 90
kArmor3ResearchTime = 120
kArmor1ResearchCost = 20
kArmor2ResearchCost = 30
kArmor3ResearchCost = 40

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


kCombatBuilderCost = 3
kCombatBuilderDropCost = 5
kCombatBuilderPointValue = 5

kMarineSentryCost = 2
kMarineSentryPersonalCost = 10
kMarineSentryDamage = 3  kMarineSentryWeapon1Scalar = 1.11  kMarineSentryWeapon2Scalar = 1.22 kMarineSentryWeapon3Scalar = 1.33
kMarineSentryBuildTime = 3

kWeaponCacheCost = 3
kWeaponCachePersonalCost = 15
kWeaponCacheBuildTime = 6
kWeaponCachePersonalCarries = 1
kMarineSentryPersonalCarries = 2

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

--Hatch
kBabblerExplodeAmount = 6
kBabblerHatchMaxAmount = 15
kBabblerEggHatchInterval = 2.5
kBabblerEggHatchRadius = 17