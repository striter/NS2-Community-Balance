
kResourceTowerResourceInterval = 6 --6
kPlayerResPerInterval = 0.125
kTeamResourcePerTick = 1
kPlayingTeamInitialTeamRes = 60   --60
kMarineInitialIndivRes = 15
kAlienInitialIndivRes = 12

kBountyMinKills = 4
kPResPerBountyKills = 0.5

kMarineRespawnTime = 9

kAlienSpawnTime = 10
kEggGenerationRate = 10  --13
kAlienEggsPerHive = 2

kWelderDropCost = 3
kWelderDropCooldown = 0

kGrenadeTechResearchCost = 10   --10
kGrenadeTechResearchTime = 60   --45

kMineCost = 10
kMineDamage = 135
kDropMineCost = 10
kDropMineCooldown = 0

kShotgunTechResearchCost = 20
kShotgunTechResearchTime = 60
kShotgunCost = 20
kShotgunDropCost = 12
kShotgunDropCooldown = 0

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
kHeavyMachineGunDropCost = 12
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
kCommandStationUpgradeTime = 90
kUpgradedCommandStationCost = 30

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
kGrenadeLauncherUpgradeResearchCost = 30
kGrenadeLauncherUpgradeResearchTime = 90
kMACEMPBlastResearchCost = 15
kMACEMPBlastResearchTime = 60
kMACEmpBlastDetectInterval = 0.5
kMACEmpBlastDetectRadius = 4
kMACEmpBlastTriggerInterval = 5

--kGrenadeLauncherDetectionShotResearchCost = 15
--kGrenadeLauncherDetectionShotResearchTime = 60
--kGrenadeLauncherAllyBlastResearchCost = 15
--kGrenadeLauncherAllyBlastResearchTime = 60

kGrenadeLauncherCost = 20
kGrenadeLauncherDropCost = 12
kGrenadeLauncherDropCooldown = 0

kGrenadeLauncherGrenadeDamageType = kDamageType.GrenadeLauncher
kGrenadeLauncherGrenadeDamage = 100
kGrenadeLauncherGrenadeDamageRadius = 4.8
kGrenadeLauncherDetectionShotRadius = 3

kGrenadeLauncherImpactGrenadeDamage = 100
kGrenadeLauncherSelfDamageReduction = 0.7
kGrenadeLauncherAllyBlastReduction = 0.4

--Armor Supply
kCombatBuilderResearchCost = 10
kCombatBuilderResearchTime = 60
kLifeSustainResearchCost = 20
kLifeSustainResearchTime = 120
kNanoArmorResearchCost = 25
kNanoArmorResearchTime = 120

kGrenadeLauncherClipSize = 4
kGrenadeLauncherWeapons1DamageScalar = 1.08
kGrenadeLauncherWeapons2DamageScalar = 1.17
kGrenadeLauncherWeapons3DamageScalar = 1.25

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
kMachineGunMeleeDamage = 25

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
kCannonDropCost = 12

kFlamethrowerCost = 20
kFlamethrowerDropCost = 12
kFlamethrowerDropCooldown = 0

kBurnDamagePerSecond = 8
kFlamethrowerBurnDuration = 1
kFlamethrowerMaxBurnDuration = 6

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

kRoboticsFactoryCost = 5
kUpgradeRoboticsFactoryCost = 10
kUpgradeRoboticsFactoryTime = 30
kARCCost = 15
kARCBuildTime = 20
kMACCost = 4

kSentryDamage = 5
kSentryCost = 5
kSentryBuildTime = 3
kSentryBatteryCost = 10
kSentryBatteryBuildTime = 5

kAdvancedArmoryUpgradeCost = 25
kAdvancedArmoryResearchTime = 90
kRoboticsFactoryBuildTime = 8

kPrototypeLabCost = 30

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

kOnosDevourCost = 10
kOnosDevourTime = 40

kUmbraBulletModifier = 0.8

kDevourEnergyCost = 60 --50
kDevourPunchDamage = 70 --100

kTunnelUpgradeCost = 20
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

--Skulk
kParasiteEnergyCost = 30
kAdrenalineParasiteEnergyCost = 18

kXenocideResearchCost = 20
kXenocideResearchTime = 60

kXenocideDamage = 120   --200
kXenocideDamageType = kDamageType.Structural
kXenocideRange = 9  -- 14
kXenocideEnergyCost = 30
kXenocideSpawnReduction = 0.8

kXenocideFuelCost = 35
kXenocideFuelTime = 120
kXenocideFuelDamage = 160
kXenocideFuelRange = 12
kXenocideFuelSpawnReduction = 0.6

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
kRappelWebTime = 2.5

kRappelResearchCost = 10
kRappelResearchTime = 20
kRappelEnergyCost = 10
kRappelReelEnergyCost = 15
kRappelRange = 35

kAcidSprayResearchCost = 10
kAcidSprayResearchTime = 60
kAcidSprayEnergyCost = 19
kAcidSprayDamage = 22.5  -- 3 missiles
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
kChargeDamage = 30
kStompEnergyCost = 25
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
kContaminationCost = 5
kContaminationCooldown = 10
kBoneWallCost = 3
kRuptureCost = 1
kDrifterCost = 6
kHydraDamage = 15
kHydraAttackDamageType = kDamageType.Structural
kHealsprayDamage = 10
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
kPowerSurgeEMPDamage = 20
kPowerSurgeEMPDamageRadius = 6
kPowerSurgeEMPElectrifiedDuration = 2

kNanoShieldPlayerDuration = 3
kNanoShieldStructureDuration = 5
kNanoShieldCost = 3
kNanoShieldCooldown = 5
kNanoShieldDamageReductionDamage = 0.68


kCombatBuilderCost = 2
kCombatBuilderDropCost = 5
kCombatBuilderPointValue = 2

kMarineSentryCost = 1
kMarineSentryDamage = 3
kMarineSentryBuildTime = 3

kWeaponCacheCost = 2
kWeaponCachePersonalCost = 10
kWeaponCacheBuildTime = 6
kWeaponCachePersonalCarries = 1

kMarineSentryPersonalCost = 6
kMarineSentryPersonalCarries = 2

kSporeMineCost = 0
kSporeMineBuildTime = 2
kNumSporeMinesPerGorge = 3
kSporeMineDamage = 125 -- per second
kSporeMineDamageType = kDamageType.Corrode
kSporeMineDamageDuration = 3
kSporeMineDamageRadius = 7
kSporeMineDotInterval = 0.4