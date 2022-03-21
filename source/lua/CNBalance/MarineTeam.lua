
function MarineTeam:InitTechTree()

    PlayingTeam.InitTechTree(self)

    -- Marine tier 1
    self.techTree:AddBuildNode(kTechId.CommandStation,            kTechId.None,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.Extractor,                 kTechId.None,                kTechId.None)

    self.techTree:AddUpgradeNode(kTechId.ExtractorArmor)

    -- Count recycle like an upgrade so we can have multiples
    self.techTree:AddUpgradeNode(kTechId.Recycle, kTechId.None, kTechId.None)

    self.techTree:AddPassive(kTechId.Welding)
    self.techTree:AddPassive(kTechId.SpawnMarine)
    self.techTree:AddPassive(kTechId.CollectResources, kTechId.Extractor)
    self.techTree:AddPassive(kTechId.Detector)

    self.techTree:AddSpecial(kTechId.TwoCommandStations)
    self.techTree:AddSpecial(kTechId.ThreeCommandStations)

    -- When adding marine upgrades that morph structures, make sure to add to GetRecycleCost() also
    self.techTree:AddBuildNode(kTechId.InfantryPortal,            kTechId.CommandStation,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.Sentry,                    kTechId.RoboticsFactory,     kTechId.None, true)
    self.techTree:AddBuildNode(kTechId.Armory,                    kTechId.CommandStation,      kTechId.None)
    self.techTree:AddBuildNode(kTechId.ArmsLab,                   kTechId.CommandStation,                kTechId.None)
    self.techTree:AddManufactureNode(kTechId.MAC,                 kTechId.RoboticsFactory,                kTechId.None,  true)

    self.techTree:AddBuyNode(kTechId.Axe,                         kTechId.None,              kTechId.None)
    self.techTree:AddBuyNode(kTechId.Pistol,                      kTechId.None,                kTechId.None)
    self.techTree:AddBuyNode(kTechId.Revolver,                    kTechId.None,                kTechId.None)
    self.techTree:AddBuyNode(kTechId.Rifle,                       kTechId.None,                kTechId.None)

    self.techTree:AddBuildNode(kTechId.SentryBattery,             kTechId.RoboticsFactory,      kTechId.None)

    self.techTree:AddOrder(kTechId.Defend)
    self.techTree:AddOrder(kTechId.FollowAndWeld)

    -- Commander abilities
    self.techTree:AddTargetedActivation(kTechId.MedPack,          kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.AmmoPack,         kTechId.None)

    self.techTree:AddResearchNode(kTechId.PowerSurgeSupport)
    self.techTree:AddTargetedActivation(kTechId.PowerSurge,             kTechId.PowerSurgeSupport)
    
    self.techTree:AddResearchNode(kTechId.CatPackSupport)
    self.techTree:AddTargetedActivation(kTechId.CatPack,             kTechId.CatPackSupport)

    self.techTree:AddResearchNode(kTechId.NanoShieldSupport)
    self.techTree:AddTargetedActivation(kTechId.NanoShield,             kTechId.NanoShieldSupport)
    
    self.techTree:AddTargetedActivation(kTechId.Scan,             kTechId.Observatory)

    self.techTree:AddAction(kTechId.SelectObservatory)

    -- Armory upgrades
    self.techTree:AddUpgradeNode(kTechId.AdvancedArmoryUpgrade,  kTechId.Armory)

    -- arms lab upgrades

    self.techTree:AddResearchNode(kTechId.Armor1,                 kTechId.ArmsLab)
    self.techTree:AddResearchNode(kTechId.Armor2,                 kTechId.Armor1, kTechId.None)
    self.techTree:AddResearchNode(kTechId.Armor3,                 kTechId.Armor2, kTechId.None)

    self.techTree:AddResearchNode(kTechId.LifeSustain,  kTechId.ArmsLab)
    self.techTree:AddResearchNode(kTechId.NanoArmor,  kTechId.LifeSustain)

    self.techTree:AddResearchNode(kTechId.Weapons1,               kTechId.ArmsLab)
    self.techTree:AddResearchNode(kTechId.Weapons2,               kTechId.Weapons1, kTechId.None)
    self.techTree:AddResearchNode(kTechId.Weapons3,               kTechId.Weapons2, kTechId.None)

    -- Marine tier 2
    self.techTree:AddBuildNode(kTechId.AdvancedArmory,               kTechId.Armory,        kTechId.None)
    self.techTree:AddResearchNode(kTechId.PhaseTech,                    kTechId.Observatory,        kTechId.None)
    self.techTree:AddBuildNode(kTechId.PhaseGate,                    kTechId.PhaseTech,        kTechId.None, true)


    self.techTree:AddBuildNode(kTechId.Observatory,               kTechId.InfantryPortal,       kTechId.Armory)      
    self.techTree:AddActivation(kTechId.DistressBeacon,           kTechId.Observatory)
    self.techTree:AddActivation(kTechId.ReversePhaseGate,         kTechId.None)

    self.techTree:AddResearchNode(kTechId.ShotgunTech,           kTechId.Armory)
    self.techTree:AddTargetedActivation(kTechId.DropShotgun,     kTechId.Armory)
    self.techTree:AddTargetedBuyNode(kTechId.Shotgun,            kTechId.ShotgunTech)

    self.techTree:AddResearchNode(kTechId.MinesTech,            kTechId.Armory)
    self.techTree:AddTargetedActivation(kTechId.DropMines,      kTechId.Armory)
    self.techTree:AddTargetedBuyNode(kTechId.LayMines,          kTechId.MinesTech)
    
    self.techTree:AddResearchNode(kTechId.GrenadeTech,           kTechId.Armory)
    self.techTree:AddTargetedBuyNode(kTechId.ClusterGrenade,     kTechId.Armory,kTechId.GrenadeTech)
    self.techTree:AddTargetedBuyNode(kTechId.GasGrenade,         kTechId.Armory,kTechId.GrenadeTech)
    self.techTree:AddTargetedBuyNode(kTechId.PulseGrenade,       kTechId.Armory,kTechId.GrenadeTech)


    self.techTree:AddTargetedBuyNode(kTechId.Welder,          kTechId.Armory,        kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.DropWelder,   kTechId.Armory,        kTechId.None)

    -- Door actions
    -- self.techTree:AddBuildNode(kTechId.Door, kTechId.None, kTechId.None)
    -- self.techTree:AddActivation(kTechId.DoorOpen)
    -- self.techTree:AddActivation(kTechId.DoorClose)
    -- self.techTree:AddActivation(kTechId.DoorLock)
    -- self.techTree:AddActivation(kTechId.DoorUnlock)

    -- Marine tier 3
    -- self.techTree:AddTargetedActivation(kTechId.GrenadeLauncherTech,      kTechId.AdvancedArmory,      kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.HeavyMachineGunTech,      kTechId.AdvancedArmory,      kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.AdvancedWeaponry,      kTechId.AdvancedArmory,      kTechId.None)
    -- self.techTree:AddTargetedActivation(kTechId.FlamethrowerTech,      kTechId.AdvancedArmory,      kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.DropGrenadeLauncher,  kTechId.AdvancedArmory,      kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.DropHeavyMachineGun,     kTechId.AdvancedArmory,      kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.DropFlamethrower,  kTechId.AdvancedArmory,      kTechId.None)
    
    self.techTree:AddTargetedBuyNode(kTechId.GrenadeLauncher ,kTechId.AdvancedArmory)
    self.techTree:AddTargetedBuyNode(kTechId.HeavyMachineGun ,kTechId.AdvancedArmory)
    self.techTree:AddTargetedBuyNode(kTechId.Flamethrower ,kTechId.AdvancedArmory)

    self.techTree:AddResearchNode(kTechId.StandardSupply,  kTechId.Armory)
    self.techTree:AddResearchNode(kTechId.PistolAxeUpgrade,  kTechId.StandardSupply)
    self.techTree:AddResearchNode(kTechId.RifleUpgrade,  kTechId.StandardSupply)
    
    self.techTree:AddResearchNode(kTechId.KinematicSupply,  kTechId.Armory)
    self.techTree:AddResearchNode(kTechId.DragonBreath,  kTechId.KinematicSupply)

    self.techTree:AddResearchNode(kTechId.ExplosiveSupply,  kTechId.Armory)
    self.techTree:AddResearchNode(kTechId.MinesUpgrade,  kTechId.MinesTech,kTechId.ExplosiveSupply )
    self.techTree:AddResearchNode(kTechId.GrenadeLauncherDetectionShot,      kTechId.ExplosiveSupply,kTechId.AdvancedArmory)
    self.techTree:AddResearchNode(kTechId.GrenadeLauncherAllyBlast , kTechId.ExplosiveSupply,kTechId.AdvancedArmory)
    self.techTree:AddResearchNode(kTechId.GrenadeLauncherUpgrade, kTechId.GrenadeLauncherAllyBlast,kTechId.AdvancedArmory)
    
    self.techTree:AddBuildNode(kTechId.PrototypeLab,          kTechId.AdvancedArmory,              kTechId.None)

    -- Jetpack
    self.techTree:AddResearchNode(kTechId.JetpackTech,           kTechId.PrototypeLab)
    self.techTree:AddTargetedActivation(kTechId.DropJetpack,    kTechId.JetpackTech,      kTechId.None)
    self.techTree:AddBuyNode(kTechId.Jetpack,                    kTechId.JetpackTech)
    --self.techTree:AddResearchNode(kTechId.JetpackFuelTech,           kTechId.JetpackTech)

    -- Exosuit
    self.techTree:AddResearchNode(kTechId.ExosuitTech,           kTechId.PrototypeLab, kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.DropExosuit,     kTechId.ExosuitTech, kTechId.None)
    self.techTree:AddBuyNode(kTechId.DualMinigunExosuit, kTechId.ExosuitTech, kTechId.None)
    self.techTree:AddBuyNode(kTechId.DualRailgunExosuit, kTechId.ExosuitTech, kTechId.None)

     
    -- Robotics factory menus
    self.techTree:AddMenu(kTechId.RoboticsFactoryARCUpgradesMenu)
    self.techTree:AddMenu(kTechId.RoboticsFactoryMACUpgradesMenu)

    self.techTree:AddMenu(kTechId.WeaponsMenu)
    self.techTree:AddMenu(kTechId.ProtosMenu)

    -- ARCs
    self.techTree:AddBuildNode(kTechId.RoboticsFactory,                    kTechId.InfantryPortal,    kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.UpgradeRoboticsFactory,           kTechId.None,              kTechId.RoboticsFactory)
    self.techTree:AddBuildNode(kTechId.ARCRoboticsFactory,                 kTechId.None,              kTechId.RoboticsFactory)

    self.techTree:AddTechInheritance(kTechId.RoboticsFactory, kTechId.ARCRoboticsFactory)

    self.techTree:AddManufactureNode(kTechId.ARC,    kTechId.ARCRoboticsFactory,     kTechId.None, true)
    self.techTree:AddActivation(kTechId.ARCDeploy)
    self.techTree:AddActivation(kTechId.ARCUndeploy)

    --self.techTree:AddResearchNode(kTechId.DualMinigunTech,       kTechId.ExosuitTech, kTechId.TwoCommandStations)
    --self.techTree:AddResearchNode(kTechId.DualMinigunExosuit,    kTechId.DualMinigunTech, kTechId.TwoCommandStations)
    --self.techTree:AddResearchNode(kTechId.ClawRailgunExosuit,    kTechId.ExosuitTech, kTechId.None)
    --self.techTree:AddResearchNode(kTechId.DualRailgunTech,       kTechId.ExosuitTech, kTechId.TwoCommandStations)
    --self.techTree:AddResearchNode(kTechId.DualRailgunExosuit,    kTechId.DualMinigunTech, kTechId.TwoCommandStations)

    self.techTree:AddActivation(kTechId.SocketPowerNode,    kTechId.None,   kTechId.None)

    self.techTree:SetComplete()

end
