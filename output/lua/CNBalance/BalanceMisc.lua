kDeadlockTimeExtend = {
    [kTechId.Extractor] = 30, [kTechId.PoweredExtractor] = 30,
    [kTechId.PhaseGate] = 60,
    [kTechId.CommandStation] = 180, [kTechId.StandardStation] = 240, [kTechId.ExplosiveStation] = 240, [kTechId.ArmorStation] = 240, [ kTechId.ElectronicStation ] = 240,

    [kTechId.Harvester] = 30,
    [kTechId.Tunnel] = 60, [kTechId.InfestedTunnel] = 60, [kTechId.GorgeTunnel] = 60,
    [kTechId.Hive] = 180, [kTechId.ShiftHive] = 240, [kTechId.CragHive] = 240, [kTechId.ShadeHive] = 240,
}
kDeadlockVisibleTime = 120

kTechReputationByPass = {
    [kTechId.CombatBuilder] = 50,
    [kTechId.SubMachineGun] = 70,
    [kTechId.Revolver] = 80,
    [kTechId.Knife] = 90, 
    [kTechId.Cannon] = 150,
    
    [kTechId.Prowler] = 100,
    [kTechId.Vokex] = 200,
}

--Gorge Ability
kDropStructureEnergyCost = 15

-- kInitialMACs = 1
-- kInitialDrifters = 1
kMaxTunnelCount = {1,3,4,4,4,4,4,4,4,4}
kHiveInfestationRadius = 20
kInfestationRadius = 7.5    kInfestationPerBiomass = 0.4

kPistolWeight = 0.0
kRifleWeight = 0.12
kHeavyRifleWeight = 0.2
kHeavyMachineGunWeight = 0.18
kCannonWeight = 0.2
kGrenadeLauncherWeight = 0.15
kFlamethrowerWeight = 0.14
kShotgunWeight = 0.14
kKnifeWeight = -0.01
kSubMachineGunWeight = 0.08
kLightMachineGunWeight = 0.13
kRevolverWeight = 0

kMaxInfantryPortalsPerCommandStation = 99
kNumMines = 4
kGrenadeLauncherPlayersAlert = 5
kFlameThrowerPlayersAlert = 3

kFlameThrowerEntityBurnReward = 1
kFlameThrowerEntityBurnRewardInterval = kFlameThrowerEntityBurnReward * 3
kFlameThrowerEntityBurnScoreRewardEachInterval = 1
kFlameThrowerEntityBurnPResRewardEachInterval = 0.1

-- Jetpack
--kUpgradedJetpackUseFuelRate = 0.18
kJetpackingAccel = 0.8
kJetpackUseFuelRate = 0.18  --0.21
kJetpackReplenishFuelRate = 0.24 --0.21

kItemStayTime = 20
kWeaponStayTime = 20 kMilitaryProtocolWeaponAdditionalStayTime = 10
kWeaponDropRateLimit = 0.2

kAlienStructureMoveSpeed = 1.5

kAlienRegenerationTime = 2

kAlienInnateRegenerationPercentage  = 0.02
kAlienMinInnateRegeneration = 3
kAlienMaxInnateRegeneration = 20

kAlienRegenerationPercentage = 0.06
kAlienMinRegeneration = 10
kAlienMaxRegeneration = 80

kAlienCrushDamagePercentByLevel = 0.07 --0.07


kFocusDamageBonusAtMax = 0.66 kFocusAttackSlowAtMax = 2
kSpitFocusDamageBonusAtMax = 0.5  kSpitFocusAttackSlowAtMax = 0
kVolleyFocusDamageBonusAtMax = 0.2  kVolleyFocusAttackSlowAtMax = 0
kSwipeFocusDamageBonusAtMax = 0.6
kGoreFocusDamageBonusAtMax = 1  kGoreFocusAttackSlowAtMax = 1

kAlienRegenerationCombatModifier = 1

kHydrasPerHive = 3
kClogsPerHive = 10
kNumWebsPerGorge = 3

kMACSpeedAmount = 1

kCelerityAddSpeed = 1.5 -- 1.5
kOnosCeleritySpeedMultiply = 0.66

kCarapaceSpeedReduction = 0.0
kSkulkCarapaceSpeedReduction = 0 --0.08
kGorgeCarapaceSpeedReduction = 0 --0.08
kLerkCarapaceSpeedReduction = 0 --0.15
kFadeCarapaceSpeedReduction = 0 --0.15
kOnosCarapaceSpeedReduction = 0.12 --0.12
kFadeAdrenalineSpeedReduction = 0

kBiteLeapVampirismScalar = 0.05   --0.0466

kParasiteVampirismScalar = 0.02    --0
kSpitVampirismScalar = 0.05   --0.026
kVolleyRappelVampirismScalar = 0.012 --0.02
kHealSprayVampirismScalar = 0.02   --0
kLerkBiteVampirismScalar = 0.0267   --0.0267
kSpikesVampirismScalar = 0.01      --0
kSwipeVampirismScalar = 0.03
kSwipeShadowStepVampirismScalar = 0.03
kStabVampirismScalar = 0.07
kGoreVampirismScalar = 0.02

-- Supply

kStartSupply = 120
kSupplyEachTechPoint = 40

kMACSupply = 0
kArmorySupply = 10
kObservatorySupply = 25
kARCSupply = 20
kSentrySupply = 0
kSentryBatterySupply = 35
kRoboticsFactorySupply = 10
kInfantryPortalSupply = 0
kPhaseGateSupply = 10
kSentriesPerBattery = 3

kDrifterSupply = 10
kWhipSupply = 8
kCragSupply = 20
kShadeSupply = 20
kShiftSupply = 20

-- Nanoarmor 
kMarinePhaseArmorDeduct = 20
kMarineArmorDeductRegen = 20

kMarineNanoArmorPerSecond = 4
kJetpackMarineArmorPerSecond = 3
kJetpackMarineNanoArmorPerSecond = 6
kExoArmorPerSecond = 8
kExoNanoArmorPerSecond = 15
--& Lifesustain
kLifeRegenMaxCap = 0.8 kLifeSustainMaxCap = 1
kLifeRegenHPS = 4   kLifeSustainHPS = 10
kJetpackLifeRegenHPS = 6   kJetpackLifeSustainHPS = 12


kAutoMedCooldown = 6    kAutoMedPRes = 0.8
kAutoAmmoCooldown = 40  kAutoAmmoPRes = 1.5

kAutoMistPRes = 1.5 kAutoMistCooldown = 30

kProwlerFov = 100

kMarineBuildBlockRadius = 0.75
kMarineBuildRadius = 1.5

kSporeMineMatureTime = 5

kPlayerEnergyPerEnergize = 15  --15
kPlayerEnergyPerEnergizeInCombat = 6
kEnergizeUpdateRate = 1