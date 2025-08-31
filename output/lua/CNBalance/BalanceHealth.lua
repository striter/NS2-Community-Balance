--(*) In replaced of special condition,usually receive few damage.  |*| Stands for Focus    --MP Stands for military protocol(Disable all weapons, marines should be tougher i mean)
-- Marine     Skulk      Lerk        Fade        Onos             MP     Skulk      Lerk        Fade        Onos           
--A    ehp    75|125     60|100      80|128      90               ehp   
--0    160    3(2)|2(1)  3   |2      2|2         2   |1           170    3(2)|2(1)   3   |2      2|2         2   |1    
--1    200    3   |2     4(3)|2      3|2         3(2)|2(1)        220    4(3)|2      4           3           3
--2    240    4   |2     4   |3      3|2         3   |2           250    4   |3(2)   5(4)        4(3)        3
--3    280    4   |3     5   |3      4|3         4(3)|2           290    5(4)|3      6(5)        4           4
-- Jetpack
--A    ehp   
--0    210    3|2        4(3)|2      3   |2      3(2)|2(1)        210    4(3)        4          3           3
--1    260    4|2        5(4)|3(2)   3   |2      3   |2           260    4           5          4           4(3)
--2    310    4|3        5   |3      4   |3      4   |2           310    5           6          5(4)        4
--3    360    5|3        6   |3      5   |3      4   |2           360    6(5)        7(6)       6(5)        5(4)
-- Exosuit    
--A    ehp
--0    640    9          11          8           8  
--1    700    10         12          9           8                 
--2    760    11         13          10          9                 
--3    820    12         14          11          10

kMarineHealth = 100    kMarineArmor = 30    kArmorPerUpgradeLevel = 20          kNanoMarineArmor = 35    kNanoArmorPerUpgradeLevel = 20
kJetpackHealth = 100    kJetpackArmor = 50   kJetpackArmorPerUpgradeLevel = 20  kMPJetpackMarineArmor = 50   kMPJetpackArmorPerUpgradeLevel = 20  
kExosuitHealth = 100    kExosuitArmor = 320  kExosuitArmorPerUpgradeLevel = 30  kExosuitMPArmor = 320 kExosuitMPArmorPerUpgradeLevel = 30
kMarinePointValue = 5   kJetpackPointValue = 12   kExosuitPointValue = 20

kMedpackHeal = 40   kMedpackRegen = 10
kMedpackHealWhenRegening = 25 kMedpackRegenWhenRegening = 25
kMedpackPickupDelay = 0.45
kMarineRegenerationHeal = 20 --Amount of hp per second

kMineHealth = 30    kMineArmor = 9    kMinePointValue = 5

--2000 -1800
kCommandStationHealth = 1800    kCommandStationArmor = 1500    kCommandStationPointValue = 20
kUpgradedCommandStationHealth = 1800 kUpgradedCommandStationArmor = 1800 kUpgradedCommandStationPointValue = 30
kCommandStationHealthPerPlayerAdd = 75

--2000   1000
kPowerPointHealth = 1250  kPowerPointArmor = 1000  kPowerPointPointValue = 10
kPowerPointHealthPerPlayerAdd = 0  kPowerPointHealthAddOnTechPoint = 800

--2400 1050
kExtractorHealth = 2400 kExtractorArmor = 1050 kExtractorPointValue = 15
kPoweredExtractorHealth = 2400 kPoweredExtractorArmor = 1500 kPoweredExtractorPointValue = 30

--1525 500
kInfantryPortalHealth = 1525  kInfantryPortalArmor = 500  kInfantryPortalPointValue = 10
kInfantryPortalHealthPerPlayerAdd = 50

-- 1500  800  10
kPhaseGateHealth = 1500  kPhaseGateArmor = 800    kPhaseGatePointValue = 10 
kPhaseGateHealthPerPlayerAdd = 60

--700 500
kObservatoryHealth = 600    kObservatoryArmor = 500    kObservatoryPointValue = 15     -- 750 500
kObservatoryHealthPerPlayerAdd = 50

--1650 500
kArmsLabHealth = 1650    kArmsLabArmor = 500    kArmsLabPointValue = 15
kArmsLabHealthPerPlayerAdd = 50

--2600 400   -- 2600 0
kARCHealth = 2600    kARCArmor = 400    kARCPointValue = 10 
kARCDeployedHealth = 2600    kARCDeployedArmor = 0
kARCHealthPerPlayerAdd = 60

--2500 400
kRoboticsFactoryHealth = 1200    kRoboticsFactoryArmor = 250    kRoboticsFactoryPointValue = 5
kARCRoboticsFactoryHealth = 1500    kARCRoboticsFactoryArmor = 400    kARCRoboticsFactoryPointValue = 7

kArmoryHealth = 1200    kArmoryArmor = 150    kArmoryPointValue = 5
kAdvancedArmoryHealth = 2400    kAdvancedArmoryArmor = 500    kAdvancedArmoryPointValue = 10

kSentryBatteryHealth = 1200    kSentryBatteryArmor = 200    kSentryBatteryPointValue = 5     --600 200
kSentryHealth = 400    kSentryArmor = 125    kSentryPointValue = 3      --500 125

kPrototypeLabHealth = 1800 kPrototypeLabArmor = 500    kPrototypeLabPointValue = 10
kUpgradedPrototypeLabHealth = 2400 kUpgradedPrototypeLabArmor = 500 kUpgradedPrototypeLabPointValue = 20

kExplosiveSelfDamage =
{
    ["Grenade"] = 60,
    ["ImpactGrenade"] = 40,
    ["ClusterGrenade"] = 20, ["ClusterFragment"] = 5,
    ["PulseGrenade"] = 40,
    ["Mine"] = 80,
    ["Cannon"] = 40,
}

kJetpackDamageReduction = {
    ["VolleyRappel"] = 1.33,
    ["Spike"] = 1.5,
    ["Spit"] = 1.66,
    ["Hydra"] = 1.66,
    ["LerkBite"] = 1.25,
    ["Parasite"] = 2,
}

kExoDamageReduction = {
    ["VolleyRappel"] = 0.75,
    ["Spike"] = 0.75,
    ["SwipeBlink"] = 0.9375,     --To 75
    --["BiteLeap"] = 0.8, 
    --["Spit"] = 1,
}

--Alien
kHealingClampMaxHPAmount = 0.12
kMaxBiomassHealthMultiplyLevel = 8 --N-1

kSkulkHealth = 75 kSkulkArmor = 10    kSkulkPointValue = 5  kSkulkHealthPerBioMass = 3 
kSkulkDamageReduction = {
    ["Grenade"] = 0.8,
    ["ImpactGrenade"] = 0.8,
    ["PulseGrenade"] = 0.8,
    ["Cannon"] = 0.8,
    --["Shotgun"] = 0.88,
    --["Railgun"] = 0.9,
}

kGorgeHealth = 180   kGorgeArmor = 50    kGorgePointValue = 7 kGorgeHealthPerBioMass = 5
kGorgeDamageReduction = {
    ["Sentry"] = 0.5,
    ["MarineSentry"] = 0.5,
    ["Mine"] = 0.5,
}

kLerkHealth = 180    kLerkArmor = 30  kLerkPointValue = 15 kLerkHealthPerBioMass = 3
kLerkDamageReduction = {
    ["Grenade"] = 0.8,
    ["ImpactGrenade"] = 0.8,
    --["Shotgun"] = 0.88,
    --["Railgun"] = 0.8,
    --["PulseGrenade"] = 0.75,
}

kFadeHealth = 270  kFadeArmor = 80  kFadePointValue = 20 kFadeHealthPerBioMass = 5
kFadeDamageReduction = {
    --["Mine"] = 1.25,
    --["MarineSentry"] = 1.1,
    --["HeavyMachineGun"] = 0.92,
}

--700 450 50
kOnosHealth = 700    kOnosArmor = 450    kOnosPointValue = 30 kOnosHealtPerBioMass = 50 
kOnosBoneShieldDefaultReduction = 0.2
kOnosBoneShieldDamageReduction = {
    --["HeavyMachineGun"] = 0.25,
    --["Minigun"] = 0.3,
    ["Railgun"] = 0,
    ["Cannon"] = 0,
}

kOnosDamageReduction = {
    ["Sentry"] = 0.5,
    ["MarineSentry"] = 0.5,
    ["Mine"] = 0.5,
    ["Shotgun"] = 0.92,
    ["Grenade"] = 0.5,
    --["Rifle"] = 0.92,
    --["SubMachineGun"] = 0.92,
    --["LightMachineGun"] = 0.92,
    --["HeavyMachineGun"] = 1.08,
}

kProwlerHealth = 150 kProwlerArmor  = 20 kProwlerPointValue = 15 kProwlerHealthPerBioMass = 5
kProwlerDamageReduction = {
    ["Grenade"] = 0.75,
    ["ImpactGrenade"] = 0.75,
    ["PulseGrenade"] = 0.75,
    --["Shotgun"] = 0.8,
    --["Railgun"] = 0.9,
    --["Cannon"] = 0.9,
}

kVokexHealth = 250   kVokexArmor = 70   kVokexPointvalue = 25   kVokexHealthPerBioMass = 5

kParasitePlayerPointValue = 1

kSkulkBaseCarapaceUpgradeAmount = 10    kSkulkCarapaceArmorPerBiomass = 1
kGorgeBaseCarapaceUpgradeAmount = 25    kGorgeCarapaceArmorPerBiomass = 1.25
kProwlerBaseCarapaceUpgradeAmount = 10  kProwlerCarapaceArmorPerBiomass = 1.25 --kProwlerArmorFullyUpgradedAmount = 28
kLerkBaseCarapaceUpgradeAmount  = 25    kLerkCarapaceArmorPerBiomass  = 1.25
kFadeBaseCarapaceUpgradeAmount  = 22.5    kFadeCarapaceArmorPerBiomass  = 2.5
kOnosBaseCarapaceUpgradeAmount  = 180   kOnosCarapaceArmorPerBiomass  = 10
kVokexBaseCarapaceUpgradeAmount = 22.5    kVokexCarapaceArmorPerBiomass = 2.5

--4000 750 6000 1400
kHiveHealth = 3600    kHiveArmor = 750 kMatureHiveHealth = 5000 kMatureHiveArmor = 1900
kHiveHealthPerPlayerAdd = 200

--2000 200 2300 320
kHarvesterHealth = 2000 kHarvesterArmor = 200 kMatureHarvesterHealth = 2300 kMatureHarvesterArmor = 320  kHarvesterPointValue = 15

--1000 ---100    --1250 -200
kTunnelEntranceHealth = 1000  kTunnelEntranceArmor = 100 kMatureTunnelEntranceHealth = 1250 kMatureTunnelEntranceArmor = 200
kTunnelEntranceHealthPerPlayerAdd = 75 kCragTunnelArmorAdditive = 400 kTunnelEntrancePointValue = 5

--These stuff is required but , won't called due to its matured when infested
kMatureInfestedTunnelEntranceHealth = kMatureTunnelEntranceHealth    kMatureInfestedTunnelEntranceArmor = kMatureTunnelEntranceArmor
kInfestedTunnelEntranceHealth = kTunnelEntranceHealth    kInfestedTunnelEntranceArmor = kTunnelEntranceArmor    

kCystHealth = 125    kCystArmor = 1
kMatureCystHealth = 400    kMatureCystArmor = 1    kCystPointValue = 1
kMinMatureCystHealth = 200 kMinCystScalingDistance = 48 kMaxCystScalingDistance = 168

kClogHealth = 250  kClogArmor = 0  kClogHealthPerBioMass = 10 kClogPointValue = 0

kHydraHealth = 150    kHydraArmor = 10  kHydraHealthPerBioMass = 20   kHydraPointValue = 1
kMatureHydraHealth = 200   kMatureHydraArmor = 20  kMatureHydraPointValue = 0

kSporeMineHealth = 50 kSporeMineArmor = 0 kSporeMineHealthPerBioMass = 12 kSporeMinePointValue = 1
kMatureSporeMineHealth = 120 kMatureSporeMineArmor = 0

kBabblerEggHealth = 100  kBabblerEggArmor = 0 kBabblerEggHealthPerBiomass = 15  kBabblerEggPointValue = 3
kMatureBabblerEggHealth = 200 kMatureBabblerEggArmor = 0

kBabblerHealth = 12    kBabblerArmor = 0    kBabblerPointValue = 0
kBabblerDefaultLifeTime = 5 kBabblerEggHatchLifetime = 30 kBabblerPheromoneHatchLifeTime = 8

kBoneWallHealth = 200 kBoneWallArmor = 200    kBoneWallHealthPerBioMass = 75 kBoneWallExtraHealthPerPlayer = 25
kContaminationHealth = 1450 kContaminationArmor = 0    kContaminationPointValue = 2

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

kSporeCloudHealth = 5   kSporeCloudHealthPerBiomass = 25   kSporeCloudPointValue = 1 --Spore Only plays with stuffs down below
kWelderSporeDamagePerSecond = 250 kFlamethrowerSporeDamagePerSecond = 1000

--Combat
kWeaponCacheHealth = 800    kWeaponCacheArmor = 150   kWeaponCachePointValue = 10
kMarineSentryHealth = 500    kMarineSentryArmor = 50    kMarineSentryPointValue = 8

kBioformSuppressorHealth = 1800 kBioformSuppressorArmor = 1800 kBioformSuppressorPointValue = 30