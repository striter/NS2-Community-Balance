kMarineTechMap =
{
        { kTechId.PoweredExtractor, 5, -1 }, { kTechId.Extractor, 7, -1 },
        
                                        { kTechId.ARCRoboticsFactory, 10, -0.5},{ kTechId.ARC, 11, -0.5 },
        { kTechId.RoboticsFactory, 9, 0.5 },{ kTechId.MAC, 10, 0.5 },
                                          { kTechId.SentryBattery, 10, 1.5 },{ kTechId.Sentry, 11, 1.5 },
                                   
                                   { kTechId.Armor1, 4, 1.5 },  { kTechId.Armor2, 3, 1.5 },{ kTechId.Armor3, 2, 1.5 },
        { kTechId.ArmsLab, 5, 2 }, 
                                   { kTechId.Weapons1, 4, 2.5 },{ kTechId.Weapons2, 3, 2.5},{ kTechId.Weapons3, 2, 2.5 },

                                        { kTechId.MotionTrack, 10, 2.5 },
        { kTechId.Observatory, 9, 3 },
                                        { kTechId.PhaseTech, 10, 3.5 },{ kTechId.PhaseGate, 11, 3.5 },
                 

        --L
                        { kTechId.Welder, 3, 4.5 },               { kTechId.ShotgunTech, 4, 4.5 },
                    { kTechId.GrenadeTech, 3, 5.5 },            { kTechId.Armory, 4, 5.5 },
                    { kTechId.CombatBuilder, 3, 6.5 },            { kTechId.MinesTech, 4, 6.5 },         


        --M
                                                    { kTechId.AdvancedArmory, 7, 5.5 },
                    { kTechId.AdvancedWeaponry, 6, 6.5 },                        { kTechId.HeavyMachineGunTech, 8, 6.5 },
    --R
                                            { kTechId.JetpackPrototypeLab, 11, 4.5 },       --{ kTechId.JetpackFuelTech, 12, 6.5 },   
                { kTechId.PrototypeLab, 10, 5.5 },       { kTechId.ExosuitPrototypeLab, 11,5.5 },
                                            { kTechId.CannonPrototypeLab,11 ,6.5 },


                                                                                                                                                      { kTechId.MilitaryProtocol, 5, 8 },{ kTechId.CommandStation, 7, 8 }, {kTechId.InfantryPortal, 9, 8 },
    { kTechId.LightMachineGunUpgrade, 0.5, 10 }, { kTechId.StandardStation, 1.5, 10 },{kTechId.CatPack, 2.5 ,10 },             { kTechId.LifeSustain, 4, 10 },       { kTechId.ArmorStation, 5, 10 },  { kTechId.NanoShield, 6, 10 },                    { kTechId.PoweredExtractorTech,8,10}, { kTechId.ElectronicStation, 9, 10 }, { kTechId.PowerSurge, 10, 10 },        { kTechId.MinesUpgrade,11.5,10}, { kTechId.ExplosiveStation, 12.5, 10 }, { kTechId.MineDeploy, 13.5, 10 },
                                                    { kTechId.DragonBreath,1.5 , 11 },                                                                                { kTechId.ArmorRegen, 5, 11 },                                                                                          { kTechId.MACEMPBlast, 9, 11 },                                                                                   { kTechId.GrenadeLauncherUpgrade, 12.5, 11},

}

kMarineLines = 
{
    { 7, 5.5, 7, -1 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Extractor, kTechId.PoweredExtractor),
    
    --Arms lab
    { 7, 2, 5, 2 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ArmsLab, kTechId.Weapons1),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Weapons1, kTechId.Weapons2),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Weapons2, kTechId.Weapons3),
    
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ArmsLab, kTechId.Armor1),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armor1, kTechId.Armor2),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armor2, kTechId.Armor3),
    
    --Factory 
    { 7, 0.5, 9, 0.5 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.RoboticsFactory, kTechId.ARCRoboticsFactory),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ARCRoboticsFactory, kTechId.ARC),

    GetLinePositionForTechMap(kMarineTechMap, kTechId.RoboticsFactory, kTechId.MAC),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.RoboticsFactory, kTechId.SentryBattery),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.SentryBattery, kTechId.Sentry),

    -- observatory:
    { 7, 3, 9, 3 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Observatory, kTechId.MotionTrack),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Observatory, kTechId.PhaseTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.PhaseTech, kTechId.PhaseGate),
    
    -- Armory
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.GrenadeTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.Welder),

    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.MinesTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.ShotgunTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.MinesTech, kTechId.CombatBuilder),

    -- Advanced Armory
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.AdvancedArmory),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.AdvancedArmory, kTechId.HeavyMachineGunTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.AdvancedArmory, kTechId.AdvancedWeaponry),

    --Command Station
    --Supplies
    GetLinePositionForTechMap(kMarineTechMap, kTechId.CommandStation, kTechId.InfantryPortal),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.CommandStation, kTechId.MilitaryProtocol),
    { 7, 8, 7, 9 },
    { 1.5, 9, 12.5, 9 },

    -- Standard Supply
    { 1.5, 9, 1.5, 10 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.StandardStation, kTechId.CatPack),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.StandardStation, kTechId.DragonBreath),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.StandardStation, kTechId.LightMachineGunUpgrade),

    --Armor Supply
    { 5, 9, 5, 10 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ArmorStation, kTechId.LifeSustain),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ArmorStation, kTechId.ArmorRegen),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ArmorStation, kTechId.NanoShield),
    
    --Electronic Supply
    { 9, 9, 9, 10 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ElectronicStation, kTechId.PowerSurge),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ElectronicStation, kTechId.MACEMPBlast),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ElectronicStation, kTechId.PoweredExtractorTech),

    --Explosive Supply
    { 12.5, 9, 12.5, 10 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ExplosiveStation, kTechId.MinesUpgrade),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ExplosiveStation, kTechId.MineDeploy),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ExplosiveStation, kTechId.GrenadeLauncherUpgrade),

    --Prototype Lab
    GetLinePositionForTechMap(kMarineTechMap, kTechId.AdvancedArmory, kTechId.PrototypeLab),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.PrototypeLab, kTechId.ExosuitPrototypeLab),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.PrototypeLab, kTechId.JetpackPrototypeLab),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.PrototypeLab, kTechId.CannonPrototypeLab),

}