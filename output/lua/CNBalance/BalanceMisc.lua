-- kInitialMACs = 1
-- kInitialDrifters = 1
kMaxTunnelCount = {1,3,4,4,4,4,4,4,4,4}

kPistolWeight = 0.0
kRifleWeight = 0.13
kHeavyRifleWeight = 0.25
kHeavyMachineGunWeight = 0.2
kCannonWeight = 0.23
kGrenadeLauncherWeight = 0.15
kFlamethrowerWeight = 0.14
kShotgunWeight = 0.14

kMaxInfantryPortalsPerCommandStation = 5
kNumMines = 2
kGrenadeLauncherPlayersAlert = 5
kFlameThrowerPlayersAlert = 3
-- Jetpack
kUpgradedJetpackUseFuelRate = 0.18
kJetpackingAccel = 0.8
kJetpackUseFuelRate = 0.18  --0.21
kJetpackReplenishFuelRate = 0.24 --0.21

kItemStayTime = 20
kWeaponStayTime = 20
kWeaponDropRateLimit = 0.2

kAlienStructureMoveSpeed = 1.5

kAlienRegenerationTime = 2

kAlienInnateRegenerationPercentage  = 0.02
kAlienMinInnateRegeneration = 3
kAlienMaxInnateRegeneration = 20

kAlienRegenerationPercentage = 0.08
kAlienMinRegeneration = 10
kAlienMaxRegeneration = 80

kAlienCrushDamagePercentByLevel = 0.111 --0.007

kCelerityAddSpeed = 1.5 -- 1.5

kFocusAttackSlowAtMax = 2
kFocusDamageBonusAtMax = 1

kSpitFocusAttackSlowAtMax = 0
kSpitFocusDamageBonusAtMax = 0.66

kVolleyFocusDamageBonusAtMax = 0.33
kVolleyFocusAttackSlowAtMax = 0

kAlienRegenerationCombatModifier = 0.5

kHydrasPerHive = 3
kClogsPerHive = 10
kNumWebsPerGorge = 3

kMACSpeedAmount = 1

kCarapaceSpeedReduction = 0.0
kSkulkCarapaceSpeedReduction = 0 --0.08
kGorgeCarapaceSpeedReduction = 0 --0.08
kLerkCarapaceSpeedReduction = 0 --0.15
kFadeCarapaceSpeedReduction = 0 --0.15
kOnosCarapaceSpeedReduction = 0 --0.12
kFadeAdrenalineSpeedReduction = 0

kBiteLeapVampirismScalar = 0.05   --0.0466

kParasiteVampirismScalar = 0.02    --0
kSpitVampirismScalar = 0.05   --0.026
kVolleyRappelVampirismScalar = 0.02 --0.02
kHealSprayVampirismScalar = 0.02   --0
kLerkBiteVampirismScalar = 0.037   --0.0267
kSpikesVampirismScalar = 0.01      --0
kSwipeVampirismScalar = 0.03
kStabVampirismScalar = 0.07
kGoreVampirismScalar = 0.02

-- Supply

kStartSupply = 120
kSupplyEachTechPoint = 40

kMACSupply = 0
kArmorySupply = 5
kObservatorySupply = 20
kARCSupply = 20
kSentrySupply = 0
kSentryBatterySupply = 35
kRoboticsFactorySupply = 10
kInfantryPortalSupply = 0
kPhaseGateSupply = 10
kSentriesPerBattery = 3

kDrifterSupply = 5
kWhipSupply = 5
kCragSupply = 20
kShadeSupply = 20
kShiftSupply = 20

kBountyMinKills = 4
kPResPerBountyKills = 0.5
kTechDataPersonalResOnKill = {
    --Marines
    [kTechId.Extractor] = 2.5, [kTechId.PoweredExtractor] = 4,
    [kTechId.RoboticsFactory] = 2.5, [kTechId.ARCRoboticsFactory] = 2.5,
    [kTechId.Armory] = 1,[kTechId.Observatory] = 2.5, [kTechId.PhaseGate] = 4,
    [kTechId.CommandStation] = 10, [kTechId.StandardStation] = 15, [kTechId.ExplosiveStation] = 15, [kTechId.ArmorStation] = 15,
    [kTechId.Mine] = 0.2, [kTechId.InfantryPortal] = 2, [kTechId.MarineSentry] = 0.8,   --PPVE
    [kTechId.MAC] = 0.2,    [kTechId.SentryBattery] = 4, [kTechId.Sentry] = 1,[kTechId.ARC] = 2.5,      --CPVE
    --[kTechId.JetpackMarine] = 5, [kTechId.Exo] = 10, [kTechId.Exosuit] = 20,

    --Aliens
    [kTechId.Harvester] = 6,
    [kTechId.Cyst] = 0.2,
    [kTechId.Hive] = 20, [kTechId.ShiftHive] = 30, [kTechId.CragHive] = 30, [kTechId.ShadeHive] = 30,
    [kTechId.Shell] = 4, [kTechId.Veil] = 4, [kTechId.Spur] = 4,
    [kTechId.Whip] = 3, [kTechId.Shift] = 6, [kTechId.Crag] = 6, [kTechId.Shade] = 6,       --CPVE
    [kTechId.Tunnel] = 6, [kTechId.InfestedTunnel] = 8,
    --[kTechId.Gorge] = 1,[kTechId.Prowler] = 2,[kTechId.Lerk] = 3,[kTechId.Fade] = 5,[kTechId.Onos] = 10,
}

kTechDataTeamResOnKill = {
    [kTechId.ARC] = 4,
    [kTechId.CommandStation] = 15, [kTechId.StandardStation] = 20, [kTechId.ExplosiveStation] = 20, [kTechId.ArmorStation] = 20,
    [kTechId.Hive] = 15, [kTechId.ShiftHive] = 20, [kTechId.CragHive] = 20, [kTechId.ShadeHive] = 20,
}

-- Nanoarmor 
kMarinePhaseArmorDeduct = 20
kMarineArmorDeductRegen = 20

kMarineNanoArmorPerSecond = 4
kJetpackMarineArmorPerSecond = 3
kJetpackMarineNanoArmorPerSecond = 6
kExoArmorPerSecond = 8
kExoNanoArmorPerSecond = 15
--& Lifesustain
kLifeRegenHPS = 4
kLifeRegenMaxCap = 0.8
kLifeSustainHPS = 10
kLifeSustainMaxCap = 1

kProwlerFov = 100

kMarineBuildBlockRadius = 0.75
kMarineBuildRadius = 1.5

kSporeMineMatureTime = 5

kPlayerEnergyPerEnergize = 10  --15
kEnergizeUpdateRate = 1
