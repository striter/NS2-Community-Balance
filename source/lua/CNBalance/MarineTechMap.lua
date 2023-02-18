kMarineTechMap =
{
        { kTechId.Extractor, 5, -1 },{ kTechId.CommandStation, 7, -1 },{ kTechId.InfantryPortal, 9, -1 },
        
                                        { kTechId.ARCRoboticsFactory, 10, 0},{ kTechId.ARC, 11, 0 },
        { kTechId.RoboticsFactory, 9, 1 },{ kTechId.MAC, 10, 1 },
                                          { kTechId.SentryBattery, 10, 2 },{ kTechId.Sentry, 11, 2 },
                                   
                                   { kTechId.Armor1, 4, 1 },  { kTechId.Armor2, 3, 1 },{ kTechId.Armor3, 2, 1 },
        { kTechId.ArmsLab, 5, 2 }, { kTechId.LifeSustain, 4, 2 }, { kTechId.NanoArmor, 3, 2 },
                                   { kTechId.Weapons1, 4, 3 },{ kTechId.Weapons2, 3, 3},{ kTechId.Weapons3, 2, 3 },
                                          

        { kTechId.Observatory, 9, 4 },{ kTechId.PhaseTech, 10, 4 },{ kTechId.PhaseGate, 11, 4 },
                 

        --L
                        { kTechId.Welder, 3, 5 },               { kTechId.ShotgunTech, 4, 5 },
                    { kTechId.GrenadeTech, 3, 6 },            { kTechId.Armory, 4, 6 },
                        { kTechId.MinesTech, 3, 7 },


        --M
                    { kTechId.AdvancedWeaponry, 6, 5 },                        { kTechId.HeavyMachineGunTech, 8, 5 },
                                                    { kTechId.AdvancedArmory, 7, 6 }, 

        --R
                                            { kTechId.JetpackTech, 11, 5.5 },       --{ kTechId.JetpackFuelTech, 12, 6.5 },   
                { kTechId.PrototypeLab, 10, 6 },       
                                                    { kTechId.ExosuitTech, 11,6.5 },

        --Supply
                                        { kTechId.StandardSupply, 5, 8 },                                                                                                             { kTechId.ExplosiveSupply, 9, 8 },
        { kTechId.DragonBreath,4 , 9 },{ kTechId.NanoShield, 5, 9 },  { kTechId.LightMachineGunUpgrade, 6, 9 },                                { kTechId.MinesUpgrade,8,9},       { kTechId.PowerSurge, 9, 9 },  { kTechId.GrenadeLauncherAllyBlast, 10, 9 },
                                        {kTechId.CatPack, 5 ,10 },     { kTechId.CannonTech,6 ,10 },                                                                  { kTechId.GrenadeLauncherDetectionShot, 9, 10 },  { kTechId.GrenadeLauncherUpgrade, 10, 10 },
                                                                                                                                                                                                                                  
}

kMarineLines = 
{
    GetLinePositionForTechMap(kMarineTechMap, kTechId.CommandStation, kTechId.Extractor),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.CommandStation, kTechId.InfantryPortal),
    
    { 7, -1, 7, 3 },

    
    --Arms lab
    { 7, 2, 5, 2 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ArmsLab, kTechId.Weapons1),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Weapons1, kTechId.Weapons2),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Weapons2, kTechId.Weapons3),
    
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ArmsLab, kTechId.LifeSustain),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.LifeSustain, kTechId.NanoArmor),

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
    { 7, 4, 9, 4 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Observatory, kTechId.PhaseTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.PhaseTech, kTechId.PhaseGate),
    
    { 7, 3, 7, 6 },
    -- Armory
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.GrenadeTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.Welder),

    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.MinesTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.ShotgunTech),

    -- Advanced Armory
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.AdvancedArmory),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.AdvancedArmory, kTechId.HeavyMachineGunTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.AdvancedArmory, kTechId.AdvancedWeaponry),

    --Supplies
    { 7, 4, 7, 7 },
    { 5, 7, 9, 7 },

    -- Standard Supply
    { 5, 7, 5, 8 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.StandardSupply, kTechId.NanoShield),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.NanoShield, kTechId.CatPack),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.StandardSupply, kTechId.DragonBreath),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.StandardSupply, kTechId.LightMachineGunUpgrade),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.LightMachineGunUpgrade, kTechId.CannonTech),

    --Explosive Supply
    { 9, 7, 9, 8 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ExplosiveSupply, kTechId.MinesUpgrade),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ExplosiveSupply, kTechId.PowerSurge),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.PowerSurge, kTechId.GrenadeLauncherDetectionShot),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ExplosiveSupply, kTechId.GrenadeLauncherAllyBlast),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.GrenadeLauncherAllyBlast, kTechId.GrenadeLauncherUpgrade),

    --Prototype Lab
    GetLinePositionForTechMap(kMarineTechMap, kTechId.AdvancedArmory, kTechId.PrototypeLab),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.PrototypeLab, kTechId.ExosuitTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.PrototypeLab, kTechId.JetpackTech),

}