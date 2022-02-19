kMarineTechMap =
{

        { kTechId.NanoShieldSupport, 6, -1 }, { kTechId.CatPackSupport, 7, -1 }, { kTechId.PowerSurgeSupport, 8, -1 },

        { kTechId.Extractor, 5, -0 },{ kTechId.CommandStation, 7, -0 },{ kTechId.InfantryPortal, 9, -0 },
        
        { kTechId.RoboticsFactory, 9, 2 },{ kTechId.ARCRoboticsFactory, 10, 1},{ kTechId.ARC, 11, 1 },
                                          { kTechId.MAC, 10, 2 },
                                          { kTechId.SentryBattery, 10, 3 },{ kTechId.Sentry, 11, 3 },
                                   
                                                               { kTechId.NanoArmor, 3, 1.5 },
        { kTechId.ArmsLab, 5, 3 },{ kTechId.Armor1, 4, 2.5 },  { kTechId.Armor2, 3, 2.5 },{ kTechId.Armor3, 2, 2.5 },
                                  { kTechId.Weapons1, 4, 3.5 },{ kTechId.Weapons2, 3, 3.5 },{ kTechId.Weapons3, 2, 3.5 },
                                                               { kTechId.RifleUpgrade, 3, 4.5 },
                                          

        { kTechId.Observatory, 9, 5 },{ kTechId.PhaseTech, 10, 5 },{ kTechId.PhaseGate, 11, 5 },
                 

                            { kTechId.Welder, 2, 6 }, { kTechId.GrenadeTech, 3.5, 6 },
                                        { kTechId.Armory, 2.75, 7 },
                        { kTechId.MinesTech, 2, 8 },{ kTechId.ShotgunTech, 3.5, 8 },
                        { kTechId.MinesSupply, 2, 9 }, { kTechId.ShotgunSupply, 3.5, 9 },

                        
                                                                                                                        { kTechId.AdvancedArmory, 7, 7 }, 
                                { kTechId.GrenadeLauncherTech, 5.5, 8 },                                                { kTechId.FlamethrowerTech, 7, 8 },                        { kTechId.HeavyMachineGunTech, 8.5, 8 },
                                { kTechId.GrenadeLauncherSupply, 5.5, 9 },                                             { kTechId.FlamethrowerSupply, 7, 9 },                       { kTechId.HeavyMachineGunSupply, 8.5, 9 },
            { kTechId.GrenadeLauncherImpactShot, 5, 10 }, { kTechId.GrenadeLauncherAllyBlast, 6, 10 },
            { kTechId.GrenadeLauncherDetectionShot, 5, 11 }, { kTechId.GrenadeLauncherUpgrade, 6, 11 },


                        { kTechId.PrototypeLab, 11.25, 7 },
        { kTechId.JetpackTech, 10.5, 8 },               { kTechId.ExosuitTech, 12,8 },
        { kTechId.JetpackSupply,10.5, 9 },             { kTechId.ExosuitSupply, 12, 9 }, 
        { kTechId.JetpackFuelTech, 10.5, 10 },
        
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
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Weapons2, kTechId.RifleUpgrade),
    
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ArmsLab, kTechId.Armor1),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armor1, kTechId.Armor2),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armor2, kTechId.Armor3),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armor2, kTechId.NanoArmor),
    
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
    GetLinePositionForTechMap(kMarineTechMap, kTechId.MinesTech, kTechId.MinesSupply),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ShotgunTech, kTechId.ShotgunSupply),

    -- Advanced Armory
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.AdvancedArmory),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.AdvancedArmory, kTechId.HeavyMachineGunTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.AdvancedArmory, kTechId.GrenadeLauncherTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.AdvancedArmory, kTechId.FlamethrowerTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.GrenadeLauncherTech, kTechId.GrenadeLauncherSupply),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.GrenadeLauncherSupply, kTechId.GrenadeLauncherImpactShot),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.GrenadeLauncherImpactShot, kTechId.GrenadeLauncherDetectionShot),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.GrenadeLauncherSupply, kTechId.GrenadeLauncherAllyBlast),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.GrenadeLauncherAllyBlast, kTechId.GrenadeLauncherUpgrade),

    GetLinePositionForTechMap(kMarineTechMap, kTechId.HeavyMachineGunTech, kTechId.HeavyMachineGunSupply),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.FlamethrowerTech, kTechId.FlamethrowerSupply),

    --Prototype Lab
    GetLinePositionForTechMap(kMarineTechMap, kTechId.AdvancedArmory, kTechId.PrototypeLab),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.PrototypeLab, kTechId.ExosuitTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.PrototypeLab, kTechId.JetpackTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ExosuitTech, kTechId.ExosuitSupply),

    GetLinePositionForTechMap(kMarineTechMap, kTechId.JetpackTech, kTechId.JetpackSupply),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.JetpackSupply, kTechId.JetpackFuelTech),

    -- AdvancedMarineSupport:
    GetLinePositionForTechMap(kMarineTechMap, kTechId.CommandStation, kTechId.CatPackSupport),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.CommandStation, kTechId.NanoShieldSupport),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.CommandStation, kTechId.PowerSurgeSupport),
}