--(*) In replaced of special condition,usually receive few damage.  |*| Stands for Focus
-- Marine
--A    ehp    Skulk      Lerk        Fade        Onos
--0    160    3(2)|2(1)  3   |2      2|1         2   |1
--1    200    3   |2     4(3)|2      3|2         3(2)|2(1)
--2    240    4   |2     4   |2      3|2         3   |2
--3    280    4   |2     5   |3      4|2         4(3)|2
-- Jetpack Marine
--A    ehp    Skulk      Lerk        Fade        Onos
--0    210    3|2        4(3)|2      3   |2      3(2)|2(1)
--1    260    4|2        5(4)|3(2)   4(3)|2      3   |2
--2    310    5|3        5   |3      4   |2      4   |2
--3    360    5|3        6   |3      5   |3      4   |2

kMarineHealth = 100    kMarineArmor = 30    kMarinePointValue = 5
kJetpackMarineArmor = 55    kJetpackMarineArmorPerUpgradeLevel = 25
kExosuitHealth = 100    kExosuitArmor = 320    kExosuitPointValue = 20
kExosuitArmorPerUpgradeLevel = 30

kCommandStationHealth = 3000    kCommandStationArmor = 1800    kCommandStationPointValue = 20   --2000 -1800
kPowerPointHealth = 2200    kPowerPointArmor = 1250    kPowerPointPointValue = 10 -- 2000 1000  10
kExtractorHealth = 2400 kExtractorArmor = 1350 kExtractorPointValue = 15 --2400 1050

kMineHealth = 30    kMineArmor = 9    kMinePointValue = 5

kObservatoryHealth = 1050    kObservatoryArmor = 500    kObservatoryPointValue = 15     -- 750 500

kRoboticsFactoryHealth = 1900    kRoboticsFactoryArmor = 400    kRoboticsFactoryPointValue = 5
kARCRoboticsFactoryHealth = 3000    kARCRoboticsFactoryArmor = 600    kARCRoboticsFactoryPointValue = 7
kSentryBatteryHealth = 700    kSentryBatteryArmor = 200    kSentryBatteryPointValue = 5
kSentryHealth = 500    kSentryArmor = 100    kSentryPointValue = 4

kARCHealth = 3100    kARCArmor = 400    kARCPointValue = 10   --2600 400
kARCDeployedHealth = 3100    kARCDeployedArmor = 0      -- 2600 0

kPhaseGateHealth = 1950    kPhaseGateArmor = 800    kPhaseGatePointValue = 10 -- 1500  800  10

--Alien
kHealingClampMaxHPAmount = 0.15

kSkulkHealth = 75    kSkulkArmor = 10    kSkulkPointValue = 5    kSkulkHealthPerBioMass = 3
kSkulkDamageReduction = {
    ["Shotgun"] = 0.85,
    ["Grenade"] = 0.8,
    ["ImpactGrenade"] = 0.8,
    ["Cannon"] = 0.9,
    ["PulseGrenade"] = 0.8,
    --["Railgun"] = 0.9,
}

kGorgeHealth = 180   kGorgeArmor = 50    kGorgePointValue = 7    kGorgeHealthPerBioMass = 3

kLerkHealth = 180    kLerkArmor = 30     kLerkPointValue = 15    kLerkHealthPerBioMass = 3
kLerkDamageReduction = {
    ["Shotgun"] = 0.9,
    ["Cannon"] = 0.8,
    ["Grenade"] = 0.75,
    ["ImpactGrenade"] = 0.75,
    --["Railgun"] = 0.8,
    --["PulseGrenade"] = 0.75,
}

kFadeHealth = 280    kFadeArmor = 80     kFadePointValue = 20    kFadeHealthPerBioMass = 5
kFadeDamageReduction = {
    ["MarineSentry"] = 1.33,
    ["Mine"] = 1.1,
    ["HeavyMachineGun"] = 0.92,
}

kOnosHealth = 750    kOnosArmor = 500    kOnosPointValue = 30    kOnosHealtPerBioMass = 50
kOnosBoneShieldDefaultReduction = 0.2
kOnosBoneShieldDamageReduction = {
    ["HeavyMachineGun"] = 0.28,
    ["Minigun"] = 0.32,
    ["Railgun"] = 0,
}
kOnosDamageReduction = {
    ["Rifle"] = 0.92,
    ["SubMachineGun"] = 0.92,
    ["LightMachineGun"] = 0.92,
    ["Shotgun"] = 0.88,
    ["HeavyMachineGun"] = 1.05
}

kProwlerHealth = 135 kProwlerArmor  = 20 kProwlerPointValue = 15 kProwlerHealthPerBioMass = 5
kProwlerDamageReduction = {
    --["Shotgun"] = 0.9,
    ["Grenade"] = 0.75,
    ["Railgun"] = 0.9,
    ["Cannon"] = 0.9,
    ["PulseGrenade"] = 0.75,
    ["ImpactGrenade"] = 0.75,
}

kVokexHealth = 200   kVokexArmor = 80    kVokexPointvalue = 25   kVokexHealthPerBioMass = 4

kParasitePlayerPointValue = 1
kAlienRegenerationPercentage = 0.08

kSkulkBaseCarapaceUpgradeAmount = 10    kSkulkCarapaceArmorPerBiomass = 1.25
kGorgeBaseCarapaceUpgradeAmount = 25    kGorgeCarapaceArmorPerBiomass = 1.25
kProwlerBaseCarapaceUpgradeAmount = 10  kProwlerCarapaceArmorPerBiomass = 1.25 --kProwlerArmorFullyUpgradedAmount = 28
kLerkBaseCarapaceUpgradeAmount  = 25    kLerkCarapaceArmorPerBiomass  = 1.25
kFadeBaseCarapaceUpgradeAmount  = 30    kFadeCarapaceArmorPerBiomass  = 2.5
kOnosBaseCarapaceUpgradeAmount  = 150   kOnosCarapaceArmorPerBiomass  = 10
kVokexBaseCarapaceUpgradeAmount = 50    kVokexCarapaceArmorPerBiomass = 0

kHiveHealth = 5200    kHiveArmor = 750   --4000 750
kMatureHiveHealth = 7800 kMatureHiveArmor = 1400    -- 6000 1400
kHarvesterHealth = 2000 kHarvesterArmor = 200 kHarvesterPointValue = 15
kMatureHarvesterHealth = 2500 kMatureHarvesterArmor = 500  --2300 320

kCystHealth = 50    kCystArmor = 1
kMatureCystHealth = 400    kMatureCystArmor = 1    kCystPointValue = 1
kMinMatureCystHealth = 200 kMinCystScalingDistance = 48 kMaxCystScalingDistance = 168

kClogHealth = 250  kClogArmor = 0  kClogHealthPerBioMass = 10 kClogPointValue = 0

kHydraHealth = 100    kHydraArmor = 10    kHydraPointValue = 0
kMatureHydraHealth = 130   kMatureHydraArmor = 20  kHydraHealthPerBioMass = 20  kMatureHydraPointValue = 0

kBoneWallHealth = 100 kBoneWallArmor = 200    kBoneWallHealthPerBioMass = 75
kContaminationHealth = 1000 kContaminationArmor = 0    kContaminationPointValue = 2

kTunnelEntranceHealth = 1050   kTunnelEntranceArmor = 250  --1000 ---100  
kMatureTunnelEntranceHealth = 1300    kMatureTunnelEntranceArmor = 350  kMatureCragTunnelEntranceArmor = 750  --1250 -200
kInfantryPortalHealth = 1825    kInfantryPortalArmor = 500    kInfantryPortalPointValue = 10

kInfestedTunnelEntranceHealth = 1300    kInfestedTunnelEntranceArmor = 350 --1250 200
kMatureInfestedTunnelEntranceHealth = 1450    kMatureInfestedTunnelEntranceArmor = 400 kMatureCragInfestedTunnelEntranceArmor = 800   --1400 250
kTunnelEntrancePointValue = 5

kBabblerEggHealth = 50    kBabblerEggArmor = 0    kBabblerEggPointValue = 0
kMatureBabblerEggHealth = 150 kMatureBabblerEggArmor = 0
   
kWhipHealth = 650    kWhipArmor = 175    kWhipPointValue = 6
kMatureWhipHealth = 720    kMatureWhipArmor = 240  kWhipHealthPerBioMass = 120  kMatureWhipPointValue = 6

kCragHealth = 480    kCragArmor = 160    kCragPointValue = 8
kMatureCragHealth = 560    kMatureCragArmor = 272  kCragHealthPerBioMass = 100 kMatureCragPointValue = 8

kShadeHealth = 600    kShadeArmor = 0    kShadePointValue = 8
kMatureShadeHealth = 1200    kMatureShadeArmor = 0  kShadeHealthPerBioMass = 100  kMatureShadePointValue = 8

kShiftHealth = 600    kShiftArmor = 60    kShiftPointValue = 8
kMatureShiftHealth = 880    kMatureShiftArmor = 120  kShiftHealthPerBioMass = 100  kMatureShiftPointValue = 8

kShellHealth = 600     kShellArmor = 150     kShellPointValue = 12
kMatureShellHealth = 1000     kMatureShellArmor = 300 -- 700 200
   
kSpurHealth = 800     kSpurArmor = 50     kSpurPointValue = 12
kMatureSpurHealth = 900  kMatureSpurArmor = 300  kMatureSpurPointValue = 15  --900 100

kVeilHealth = 900     kVeilArmor = 0     kVeilPointValue = 12
kMatureVeilHealth = 1500     kMatureVeilArmor = 0     kVeilPointValue = 15  -- 1100 0

--Combat
kWeaponCacheHealth = 800    kWeaponCacheArmor = 150   kWeaponCachePointValue = 10
kMarineSentryHealth = 500    kMarineSentryArmor = 125    kMarineSentryPointValue = 8

kSporeMineHealth = 50 kSporeMineArmor = 0 kSporeMinepointValue=0
kMatureSporeMineHealth = 100 kMatureSporeMineArmor = 0