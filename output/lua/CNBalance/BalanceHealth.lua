--(*) In replaced of special condition,usually receive few damage.  |*| Stands for Focus    --MP Stands for military protocol(Disable all weapons, marines should be tougher i mean)
-- Marine     Skulk      Lerk        Fade        Onos             MP     Skulk      Lerk        Fade        Onos           
--A    ehp    75|125     60|100      80|128      90               ehp   
--0    160    3(2)|2(1)  3   |2      2|2         2   |1           160    3(2)|2(1)   3   |2      2|2         2   |1    
--1    200    3   |2     4(3)|2      3|2         3(2)|2(1)        210    4(3)|2      4           3           3
--2    240    4   |2     4   |3      3|2         3   |2           260    4   |3(2)   5(4)        4(3)        3
--3    280    4   |3     5   |3      4|3         4(3)|2           310    5(4)|3      6(5)        4           4
-- Jetpack
--A    ehp   
--0    200    3|2        4(3)|2      3   |2      3(2)|2(1)        210    4(3)        4          3           3
--1    240    4|2        5(4)|3(2)   3   |2      3   |2           260    4           5          4           4(3)
--2    280    4|3        5   |3      4   |3      4   |2           310    5           6          5(4)        4
--3    320    5|3        6   |3      5   |3      4   |2           360    6(5)        7(6)       6(5)        5(4)
-- Exosuit    
--A    ehp
--0    640    9          11          8           8  
--1    700    10         12          9           8                 
--2    760    11         13          10          9                 
--3    820    12         14          11          10


kMarineHealth = 100    kMarineArmor = 30    kArmorPerUpgradeLevel = 20     kMPMarineArmor = 35    kMPMarineArmorPerUpgradeLevel = 20
kJetpackHealth = 120    kJetpackArmor = 45   kJetpackArmorPerUpgradeLevel = 25   kMPJetpackMarineArmor = 45   kMPJetpackArmorPerUpgradeLevel = 25  
kExosuitHealth = 100    kExosuitArmor = 320  kExosuitArmorPerUpgradeLevel = 30
kMarinePointValue = 5   kJetpackPointValue = 12   kExosuitPointValue = 20

kMineHealth = 30    kMineArmor = 9    kMinePointValue = 5

--2000 -1800
kCommandStationHealth = 2000    kCommandStationArmor = 2000    kCommandStationPointValue = 20
kUpgradedCommandStationHealth = 2200 kUpgradedCommandStationArmor = 2200 kUpgradedCommandStationPointValue = 30
kCommandStationHealthPerPlayerAdd = 100

--2000   1000
kPowerPointHealth = 2000  kPowerPointArmor = 1200  kPowerPointPointValue = 10
kPowerPointHealthPerPlayerAdd = 75

--2400 1050
kExtractorHealth = 2400 kExtractorArmor = 1200 kExtractorPointValue = 15
kPoweredExtractorHealth = 3000 kPoweredExtractorArmor = 1600 kPoweredExtractorPointValue = 30
kExtractorHealthPerPlayerAdd = 80

--1525 500
kInfantryPortalHealth = 1500  kInfantryPortalArmor = 600  kInfantryPortalPointValue = 10
kInfantryPortalHealthPerPlayerAdd = 50

-- 1500  800  10
kPhaseGateHealth = 1800  kPhaseGateArmor = 800    kPhaseGatePointValue = 10 
kPhaseGateHealthPerPlayerAdd = 60

--700 500
kObservatoryHealth = 850    kObservatoryArmor = 500    kObservatoryPointValue = 15     -- 750 500
kObservatoryHealthPerPlayerAdd = 50

--1650 500
kArmsLabHealth = 1800    kArmsLabArmor = 500    kArmsLabPointValue = 15
kArmsLabHealthPerPlayerAdd = 50

--2600 400   -- 2600 0
kARCHealth = 3000    kARCArmor = 400    kARCPointValue = 10 
kARCDeployedHealth = 3000    kARCDeployedArmor = 0

kRoboticsFactoryHealth = 2500    kRoboticsFactoryArmor = 400    kRoboticsFactoryPointValue = 5
kARCRoboticsFactoryHealth = 3000    kARCRoboticsFactoryArmor = 600    kARCRoboticsFactoryPointValue = 7
kSentryBatteryHealth = 800    kSentryBatteryArmor = 200    kSentryBatteryPointValue = 5
kSentryHealth = 500    kSentryArmor = 125    kSentryPointValue = 4

kExplosiveSelfDamage =
{
    ["Grenade"] = 40,
    ["ClusterGrenade"] = 20,
    ["ClusterFragment"] = 5,
    ["ImpactGrenade"] = 40,
    ["PulseGrenade"] = 40,
    ["Mine"] = 60,
}

--Alien
kHealingClampMaxHPAmount = 0.15

kSkulkHealth = 75    kSkulkArmor = 10    kSkulkPointValue = 5  kSkulkHealthPerBioMass = 3 kSkulkHealthPerPlayerAboveLimit = 1
kSkulkDamageReduction = {
    ["Shotgun"] = 0.88,
    ["Grenade"] = 0.8,
    ["ImpactGrenade"] = 0.8,
    ["Cannon"] = 0.9,
    ["PulseGrenade"] = 0.8,
    --["Railgun"] = 0.9,
}

kGorgeHealth = 180   kGorgeArmor = 50    kGorgePointValue = 7 kGorgeHealthPerBioMass = 3

kLerkHealth = 180    kLerkArmor = 30     kLerkPointValue = 15 kLerkHealthPerBioMass = 3
kLerkDamageReduction = {
    --["Shotgun"] = 0.92,
    ["Cannon"] = 0.8,
    ["Grenade"] = 0.75,
    ["ImpactGrenade"] = 0.75,
    --["Railgun"] = 0.8,
    --["PulseGrenade"] = 0.75,
}

kFadeHealth = 280    kFadeArmor = 80     kFadePointValue = 20 kFadeHealthPerBioMass = 5 
kFadeDamageReduction = {
    --["MarineSentry"] = 1.1,
    ["Mine"] = 1.1,
    ["HeavyMachineGun"] = 0.92,
}

--700 450 50
kOnosHealth = 700    kOnosArmor = 500    kOnosPointValue = 30 kOnosHealtPerBioMass = 50 kOnosHealthPerPlayerAboveLimit = 35
kOnosBoneShieldDefaultReduction = 0.2
kOnosBoneShieldDamageReduction = {
    ["HeavyMachineGun"] = 0.25,
    ["Minigun"] = 0.25,
    ["Railgun"] = 0,
}
kOnosDamageReduction = {
    ["Rifle"] = 0.92,
    ["SubMachineGun"] = 0.92,
    ["LightMachineGun"] = 0.92,
    ["Shotgun"] = 0.88,
    --["HeavyMachineGun"] = 1.08,
}

kProwlerHealth = 120 kProwlerArmor  = 20 kProwlerPointValue = 15 kProwlerHealthPerBioMass = 7
kProwlerDamageReduction = {
    --["Shotgun"] = 0.9,
    ["Grenade"] = 0.75,
    ["ImpactGrenade"] = 0.75,
    ["Railgun"] = 0.9,
    ["Cannon"] = 0.9,
    ["PulseGrenade"] = 0.75,
}

kVokexHealth = 200   kVokexArmor = 80    kVokexPointvalue = 25   kVokexHealthPerBioMass = 4

kParasitePlayerPointValue = 1

kSkulkBaseCarapaceUpgradeAmount = 9    kSkulkCarapaceArmorPerBiomass = 1
kGorgeBaseCarapaceUpgradeAmount = 25    kGorgeCarapaceArmorPerBiomass = 1.25
kProwlerBaseCarapaceUpgradeAmount = 10  kProwlerCarapaceArmorPerBiomass = 1.25 --kProwlerArmorFullyUpgradedAmount = 28
kLerkBaseCarapaceUpgradeAmount  = 25    kLerkCarapaceArmorPerBiomass  = 1.25
kFadeBaseCarapaceUpgradeAmount  = 30    kFadeCarapaceArmorPerBiomass  = 2.5
kOnosBaseCarapaceUpgradeAmount  = 150   kOnosCarapaceArmorPerBiomass  = 10
kVokexBaseCarapaceUpgradeAmount = 50    kVokexCarapaceArmorPerBiomass = 0

--4000 750 6000 1400
kHiveHealth = 4000    kHiveArmor = 1000 kMatureHiveHealth = 5000 kMatureHiveArmor = 2500
kHiveHealthPerPlayerAdd = 200

--2000 200 2300 320 
kHarvesterHealth = 2000 kHarvesterArmor = 320 kMatureHarvesterHealth = 2300 kMatureHarvesterArmor = 500  kHarvesterPointValue = 15
kHarvesterHealthPerPlayerAdd = 75

--1000 ---100    --1250 -200
kTunnelEntranceHealth = 1000  kTunnelEntranceArmor = 200 kMatureTunnelEntranceHealth = 1250 kMatureTunnelEntranceArmor = 400
kTunnelEntranceHealthPerPlayerAdd = 50 kCragTunnelArmorAdditive = 400 kTunnelEntrancePointValue = 5

--These stuff is required but , won't called due to its matured when infested
kMatureInfestedTunnelEntranceHealth = kMatureTunnelEntranceHealth    kMatureInfestedTunnelEntranceArmor = kMatureTunnelEntranceArmor
kInfestedTunnelEntranceHealth = kTunnelEntranceHealth    kInfestedTunnelEntranceArmor = kTunnelEntranceArmor    

kCystHealth = 50    kCystArmor = 1
kMatureCystHealth = 400    kMatureCystArmor = 1    kCystPointValue = 1
kMinMatureCystHealth = 200 kMinCystScalingDistance = 48 kMaxCystScalingDistance = 168

kClogHealth = 250  kClogArmor = 0  kClogHealthPerBioMass = 10 kClogPointValue = 0

kHydraHealth = 100    kHydraArmor = 10  kHydraHealthPerBioMass = 20   kHydraPointValue = 1
kMatureHydraHealth = 130   kMatureHydraArmor = 20  kMatureHydraPointValue = 0

kSporeMineHealth = 50 kSporeMineArmor = 0 kSporeMineHealthPerBioMass = 12 kSporeMinePointValue = 1
kMatureSporeMineHealth = 120 kMatureSporeMineArmor = 0

kBabblerEggHealth = 100  kBabblerEggArmor = 0 kBabblerEggHealthPerBiomass = 15  kBabblerEggPointValue = 3
kMatureBabblerEggHealth = 200 kMatureBabblerEggArmor = 0

kBoneWallHealth = 100 kBoneWallArmor = 200    kBoneWallHealthPerBioMass = 75
kContaminationHealth = 1000 kContaminationArmor = 0    kContaminationPointValue = 2


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
kMarineSentryHealth = 500    kMarineSentryArmor = 50    kMarineSentryPointValue = 8
