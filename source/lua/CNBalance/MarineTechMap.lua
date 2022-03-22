kMarineTechMap =
{

        { kTechId.NanoShieldSupport, 6, -1 }, { kTechId.CatPackSupport, 7, -1 }, { kTechId.PowerSurgeSupport, 8, -1 },

        { kTechId.Extractor, 5, -0 },{ kTechId.CommandStation, 7, -0 },{ kTechId.InfantryPortal, 9, -0 },
        
        { kTechId.RoboticsFactory, 9, 2 },{ kTechId.ARCRoboticsFactory, 10, 1},{ kTechId.ARC, 11, 1 },
                                          { kTechId.MAC, 10, 2 },
                                          { kTechId.SentryBattery, 10, 3 },{ kTechId.Sentry, 11, 3 },
                                   
                                   { kTechId.Armor1, 4, 2 },  { kTechId.Armor2, 3, 2 },{ kTechId.Armor3, 2, 2 },
        { kTechId.ArmsLab, 5, 3 }, { kTechId.LifeSustain, 4, 3 }, { kTechId.NanoArmor, 3, 3 },
                                   { kTechId.Weapons1, 4, 4 },{ kTechId.Weapons2, 3, 4 },{ kTechId.Weapons3, 2, 4 },
                                          

        { kTechId.Observatory, 9, 5 },{ kTechId.PhaseTech, 10, 5 },{ kTechId.PhaseGate, 11, 5 },
                 

        --L
                        { kTechId.Welder, 3, 6 },               { kTechId.ShotgunTech, 4, 6 },
                    { kTechId.GrenadeTech, 3, 7 },            { kTechId.Armory, 4, 7 },
                        { kTechId.MinesTech, 3, 8 },


        --M
                    { kTechId.AdvancedWeaponry, 6, 6 },                        { kTechId.HeavyMachineGunTech, 8, 6 },
                                                    { kTechId.AdvancedArmory, 7, 7 }, 

        --R
                                            { kTechId.JetpackTech, 11, 6.5 },       --{ kTechId.JetpackFuelTech, 12, 6.5 },   
                { kTechId.PrototypeLab, 10, 7 },       
                                                    { kTechId.ExosuitTech, 11,7.5 },

        --Supply
                                 { kTechId.StandardSupply, 4, 9 },                                             { kTechId.KinematicSupply, 7, 9 },                                                                        { kTechId.ExplosiveSupply, 10, 9 },
                { kTechId.PistolAxeUpgrade, 3.5 ,10 },  { kTechId.RifleUpgrade, 4.5, 10 },         { kTechId.DragonBreath,6.5 ,10 },{ kTechId.CannonTech,7.5 ,10 },                  {kTechId.MinesUpgrade,9,10},   { kTechId.GrenadeLauncherDetectionShot, 10, 10 },{ kTechId.GrenadeLauncherAllyBlast, 11, 10 },         
                                                                                                                                                                                                                        { kTechId.GrenadeLauncherUpgrade, 11, 11 },
                                                                                                                                                                                                                                  
}

kMarineLines = 
{
    GetLinePositionForTechMap(kMarineTechMap, kTechId.CommandStation, kTechId.Extractor),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.CommandStation, kTechId.InfantryPortal),
    
    { 7, 0, 7, 4 },

    
    --Arms lab
    { 7, 3, 5, 3 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ArmsLab, kTechId.Weapons1),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Weapons1, kTechId.Weapons2),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Weapons2, kTechId.Weapons3),
    
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ArmsLab, kTechId.LifeSustain),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.LifeSustain, kTechId.NanoArmor),

    GetLinePositionForTechMap(kMarineTechMap, kTechId.ArmsLab, kTechId.Armor1),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armor1, kTechId.Armor2),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armor2, kTechId.Armor3),
    
    
    --Factory
    { 7, 2, 9, 2 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.RoboticsFactory, kTechId.ARCRoboticsFactory),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ARCRoboticsFactory, kTechId.ARC),

    GetLinePositionForTechMap(kMarineTechMap, kTechId.RoboticsFactory, kTechId.MAC),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.RoboticsFactory, kTechId.SentryBattery),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.SentryBattery, kTechId.Sentry),

    -- observatory:
    { 7, 5, 9, 5 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Observatory, kTechId.PhaseTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.PhaseTech, kTechId.PhaseGate),


    { 7, 4, 7, 7 },
    -- Armory
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.GrenadeTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.Welder),

    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.MinesTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.ShotgunTech),

    -- Advanced Armory
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.AdvancedArmory),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.AdvancedArmory, kTechId.HeavyMachineGunTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.AdvancedArmory, kTechId.AdvancedWeaponry),

    --Supply
    { 7, 4, 7, 8 },
    { 4, 8, 10, 8 },

    -- Standard Supply
    { 4, 8, 4, 9 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.StandardSupply, kTechId.PistolAxeUpgrade),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.StandardSupply, kTechId.RifleUpgrade),

    -- Kinematic Supply
    { 7, 8, 7, 9 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.KinematicSupply, kTechId.DragonBreath),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.KinematicSupply, kTechId.CannonTech),

    --Explosive Supply
    { 10, 8, 10, 9 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ExplosiveSupply, kTechId.MinesUpgrade),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ExplosiveSupply, kTechId.GrenadeLauncherDetectionShot),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ExplosiveSupply, kTechId.GrenadeLauncherAllyBlast),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.GrenadeLauncherAllyBlast, kTechId.GrenadeLauncherUpgrade),

    --Prototype Lab
    GetLinePositionForTechMap(kMarineTechMap, kTechId.AdvancedArmory, kTechId.PrototypeLab),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.PrototypeLab, kTechId.ExosuitTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.PrototypeLab, kTechId.JetpackTech),

    --GetLinePositionForTechMap(kMarineTechMap, kTechId.JetpackTech, kTechId.JetpackFuelTech),

    -- AdvancedMarineSupport:
    GetLinePositionForTechMap(kMarineTechMap, kTechId.CommandStation, kTechId.CatPackSupport),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.CommandStation, kTechId.NanoShieldSupport),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.CommandStation, kTechId.PowerSurgeSupport),
}