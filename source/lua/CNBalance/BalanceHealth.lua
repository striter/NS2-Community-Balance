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
kExtractorHealth = 2400 kExtractorArmor = 1200 kExtractorPointValue = 15 --2400 1050

kMineHealth = 26    kMineArmor = 5    kMinePointValue = 5

kObservatoryHealth = 750    kObservatoryArmor = 500    kObservatoryPointValue = 10

kRoboticsFactoryHealth = 1900    kRoboticsFactoryArmor = 400    kRoboticsFactoryPointValue = 5
kARCRoboticsFactoryHealth = 3000    kARCRoboticsFactoryArmor = 600    kARCRoboticsFactoryPointValue = 7
kSentryBatteryHealth = 700    kSentryBatteryArmor = 200    kSentryBatteryPointValue = 5
kSentryHealth = 500    kSentryArmor = 100    kSentryPointValue = 4

kARCHealth = 2600    kARCArmor = 600    kARCPointValue = 10   --2600 400
kARCDeployedHealth = 2600    kARCDeployedArmor = 0      -- 2600 0

kPhaseGateHealth = 1850    kPhaseGateArmor = 800    kPhaseGatePointValue = 10 -- 1500  800  10

--Alien
kHealingClampMaxHPAmount = 0.20

kSkulkHealth = 75    kSkulkArmor = 10    kSkulkPointValue = 5    kSkulkHealthPerBioMass = 3
kGorgeHealth = 180   kGorgeArmor = 50    kGorgePointValue = 7    kGorgeHealthPerBioMass = 3
kLerkHealth = 180    kLerkArmor = 30     kLerkPointValue = 15    kLerkHealthPerBioMass = 3
kFadeHealth = 250    kFadeArmor = 80     kFadePointValue = 20    kFadeHealthPerBioMass = 5
kOnosHealth = 800    kOnosArmor = 500    kOnosPointValue = 30    kOnosHealtPerBioMass = 50

kProwlerHealth = 140 kProwlerArmor  = 25 kProwlerPointValue = 12 kProwlerHealthPerBioMass = 5
kVokexHealth = 200   kVokexArmor = 80    kVokexPointvalue = 25   kVokexHealthPerBioMass = 4

kParasitePlayerPointValue = 1
kAlienRegenerationPercentage = 0.08

kSkulkBaseCarapaceUpgradeAmount = 10    kSkulkCarapaceArmorPerBiomass = 1.875
kGorgeBaseCarapaceUpgradeAmount = 25    kGorgeCarapaceArmorPerBiomass = 1.25
kVokexCarapaceArmorPerBiomass = 0       kProwlerBaseCarapaceUpgradeAmount = 10.5  --kProwlerArmorFullyUpgradedAmount = 28
kLerkBaseCarapaceUpgradeAmount  = 25    kLerkCarapaceArmorPerBiomass  = 1.25
kFadeBaseCarapaceUpgradeAmount  = 40    kFadeCarapaceArmorPerBiomass  = 0
kOnosBaseCarapaceUpgradeAmount  = 150   kOnosCarapaceArmorPerBiomass  = 10
kVokexBaseCarapaceUpgradeAmount = 50    kProwlerCarapaceArmorPerBiomass = 0

kHiveHealth = 5200    kHiveArmor = 750   --4000 750
kMatureHiveHealth = 7800 kMatureHiveArmor = 1400    -- 6000 1400
kHarvesterHealth = 2000 kHarvesterArmor = 200 kHarvesterPointValue = 15
kMatureHarvesterHealth = 2300 kMatureHarvesterArmor = 500  --2300 320

kCystHealth = 50    kCystArmor = 1
kMatureCystHealth = 400    kMatureCystArmor = 1    kCystPointValue = 1
kMinMatureCystHealth = 200 kMinCystScalingDistance = 48 kMaxCystScalingDistance = 168

kClogHealth = 250  kClogArmor = 0 kClogPointValue = 0
kClogHealthPerBioMass = 10

kHydraHealth = 125    kHydraArmor = 5    kHydraPointValue = 0
kMatureHydraHealth = 160   kMatureHydraArmor = 20    kMatureHydraPointValue = 0
kHydraHealthPerBioMass = 20

kBoneWallHealth = 100 kBoneWallArmor = 200    kBoneWallHealthPerBioMass = 75
kContaminationHealth = 1000 kContaminationArmor = 0    kContaminationPointValue = 2

kTunnelEntranceHealth = 1050   kTunnelEntranceArmor = 250    --1000 ---100
kMatureTunnelEntranceHealth = 1300    kMatureTunnelEntranceArmor = 350    --1250 -200
kInfestedTunnelEntranceHealth = 1300    kInfestedTunnelEntranceArmor = 350  --1250 200
kMatureInfestedTunnelEntranceHealth = 1450    kMatureInfestedTunnelEntranceArmor = 400    --1400 250
kTunnelEntrancePointValue = 5

kBabblerEggHealth = 50    kBabblerEggArmor = 0    kBabblerEggPointValue = 0
kMatureBabblerEggHealth = 150 kMatureBabblerEggArmor = 0

kCragHealth = 480    kCragArmor = 160    kCragPointValue = 10
kMatureCragHealth = 560    kMatureCragArmor = 272    kMatureCragPointValue = 10
        
kWhipHealth = 650    kWhipArmor = 175    kWhipPointValue = 10
kMatureWhipHealth = 720    kMatureWhipArmor = 240    kMatureWhipPointValue = 10

kShadeHealth = 600    kShadeArmor = 0    kShadePointValue = 10
kMatureShadeHealth = 1200    kMatureShadeArmor = 0    kMatureShadePointValue = 10

kShiftHealth = 600    kShiftArmor = 60    kShiftPointValue = 10
kMatureShiftHealth = 880    kMatureShiftArmor = 120    kMatureShiftPointValue = 10

kShellHealth = 600     kShellArmor = 150     kShellPointValue = 12
kMatureShellHealth = 1000     kMatureShellArmor = 300 -- 700 200
   
kSpurHealth = 800     kSpurArmor = 50     kSpurPointValue = 12
kMatureSpurHealth = 900  kMatureSpurArmor = 300  kMatureSpurPointValue = 15  --900 100

kVeilHealth = 900     kVeilArmor = 0     kVeilPointValue = 12
kMatureVeilHealth = 1500     kMatureVeilArmor = 0     kVeilPointValue = 15  -- 1100 0


--Combat
kWeaponCacheHealth = 500    kWeaponCacheArmor = 150   kWeaponCachePointValue = 10
kMarineSentryHealth = 200    kMarineSentryArmor = 125    kMarineSentryPointValue = 6

kSporeMineHealth = 50 kSporeMineArmor = 0 kSporeMinepointValue=0
kMatureSporeMineHealth = 100 kMatureSporeMineArmor = 0