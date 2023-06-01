kMarineTechMap =
{
                                { kTechId.Extractor, 7, -1 },
        
                                        { kTechId.ARCRoboticsFactory, 10, 0},{ kTechId.ARC, 11, 0 },
        { kTechId.RoboticsFactory, 9, 1 },{ kTechId.MAC, 10, 1 },
                                          { kTechId.SentryBattery, 10, 2 },{ kTechId.Sentry, 11, 2 },
                                   
                                   { kTechId.Armor1, 4, 1.5 },  { kTechId.Armor2, 3, 1.5 },{ kTechId.Armor3, 2, 1.5 },
        { kTechId.ArmsLab, 5, 2 }, 
                                   { kTechId.Weapons1, 4, 2.5 },{ kTechId.Weapons2, 3, 2.5},{ kTechId.Weapons3, 2, 2.5 },
                                          

        { kTechId.Observatory, 9, 3.5 },{ kTechId.PhaseTech, 10, 3.5 },{ kTechId.PhaseGate, 11, 3.5 },
                 

        --L
                        { kTechId.Welder, 3, 4.5 },               { kTechId.ShotgunTech, 4, 4.5 },
                    { kTechId.GrenadeTech, 3, 5.5 },            { kTechId.Armory, 4, 5.5 },
                        { kTechId.MinesTech, 3, 6.5 },


        --M
                    { kTechId.AdvancedWeaponry, 6, 4.5 },                        { kTechId.HeavyMachineGunTech, 8, 4.5 },
                                                    { kTechId.AdvancedArmory, 7, 5.5 }, 

        --R
                                            { kTechId.JetpackTech, 11, 5 },       --{ kTechId.JetpackFuelTech, 12, 6.5 },   
                { kTechId.PrototypeLab, 10, 5.5 },       
                                                    { kTechId.ExosuitTech, 11,6 },
        
                                                                                                                                                                    { kTechId.CommandStation, 7, 7 }, {kTechId.InfantryPortal, 9, 7 },
                        { kTechId.LightMachineGunUpgrade, 2.5, 9 }, { kTechId.StandardStation, 3.5, 9 },{kTechId.CatPack, 4.5 ,9 },                       { kTechId.CombatBuilderTech, 6, 9 },       { kTechId.ArmorStation, 7, 9 },  { kTechId.NanoShield, 8, 9 },                                                       { kTechId.MinesUpgrade,9.5,9}, { kTechId.ExplosiveStation, 10.5, 9 }, { kTechId.PowerSurge, 11.5, 9 },
                                                        { kTechId.DragonBreath,3 , 10 },{ kTechId.CannonTech,4 ,10 },                                                           { kTechId.LifeSustain, 6.5, 10 }, { kTechId.ArmorRegen, 7.5, 10 },                                                                               { kTechId.GrenadeLauncherUpgrade, 10, 10},   { kTechId.MACEMPBlast, 11, 10 },
                                                                                                                                                                                                                                                                                                                                                                       
}


kMarineLines = 
{
    { 7, 5.5, 7, -1 },
    
    --Arms lab
    { 7, 2, 5, 2 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ArmsLab, kTechId.Weapons1),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Weapons1, kTechId.Weapons2),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Weapons2, kTechId.Weapons3),
    
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ArmsLab, kTechId.Armor1),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armor1, kTechId.Armor2),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armor2, kTechId.Armor3),
    
    --Factory 
    { 7, 1, 9, 1 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.RoboticsFactory, kTechId.ARCRoboticsFactory),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ARCRoboticsFactory, kTechId.ARC),

    GetLinePositionForTechMap(kMarineTechMap, kTechId.RoboticsFactory, kTechId.MAC),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.RoboticsFactory, kTechId.SentryBattery),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.SentryBattery, kTechId.Sentry),

    -- observatory:
    { 7, 3.5, 9, 3.5 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Observatory, kTechId.PhaseTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.PhaseTech, kTechId.PhaseGate),
    
    -- Armory
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.GrenadeTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.Welder),

    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.MinesTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.ShotgunTech),

    -- Advanced Armory
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.AdvancedArmory),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.AdvancedArmory, kTechId.HeavyMachineGunTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.AdvancedArmory, kTechId.AdvancedWeaponry),

    --Command Station
    --Supplies
    GetLinePositionForTechMap(kMarineTechMap, kTechId.CommandStation, kTechId.InfantryPortal),
    { 7, 7, 7, 8 },
    { 3.5, 8, 10.5, 8 },

    -- Standard Supply
    { 3.5, 8, 3.5, 9 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.StandardStation, kTechId.CatPack),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.StandardStation, kTechId.DragonBreath),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.StandardStation, kTechId.LightMachineGunUpgrade),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.StandardStation, kTechId.CannonTech),

    --Armor Supply
    { 7, 8, 7, 9 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ArmorStation, kTechId.LifeSustain),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ArmorStation, kTechId.ArmorRegen),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ArmorStation, kTechId.NanoShield),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ArmorStation, kTechId.CombatBuilderTech),
    
    --Explosive Supply
    { 10.5, 8, 10.5, 9 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ExplosiveStation, kTechId.MinesUpgrade),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ExplosiveStation, kTechId.PowerSurge),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ExplosiveStation, kTechId.MACEMPBlast),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ExplosiveStation, kTechId.GrenadeLauncherUpgrade),

    --Prototype Lab
    GetLinePositionForTechMap(kMarineTechMap, kTechId.AdvancedArmory, kTechId.PrototypeLab),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.PrototypeLab, kTechId.ExosuitTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.PrototypeLab, kTechId.JetpackTech),

}