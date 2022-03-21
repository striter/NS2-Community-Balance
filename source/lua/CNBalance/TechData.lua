local oldBuildTechData = BuildTechData
function BuildTechData()
    
    local techData = oldBuildTechData()

    table.insert(techData, {
        [kTechDataId] = kTechId.NanoArmor,
        [kTechDataCostKey] = kNanoArmorResearchCost,
        [kTechDataResearchTimeKey] = kNanoArmorResearchTime,
        [kTechDataDisplayName] = "NANO_ARMOR",
        [kTechDataTooltipInfo] = "NANO_ARMOR_TOOLTIP",
        [kTechDataResearchName] = "NANO_ARMOR",
    })
            
    table.insert(techData, {
        [kTechDataId] = kTechId.LifeSustain,
        [kTechDataCostKey] = kLifeSustainResearchCost,
        [kTechDataResearchTimeKey] = kLifeSustainResearchTime,
        [kTechDataDisplayName] = "LIFE_SUSTAIN",
        [kTechDataTooltipInfo] = "LIFE_SUSTAIN_TOOLTIP",
        [kTechDataResearchName] = "LIFE_SUSTAIN",
    })        

    table.insert(techData, {
        [kTechDataId] = kTechId.PowerSurgeSupport,
        [kTechDataCostKey] = kPowerSurgeSupportCost,
        [kTechDataResearchTimeKey] = kPowerSurgeSupportTime,
        [kTechDataDisplayName] = "POWER_SURGE_SUPPORT",
        [kTechDataTooltipInfo] = "POWER_SURGE_TOOLTIP",
        [kTechDataResearchName] = "POWER_SURGE_SUPPORT",
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.NanoShieldSupport,
        [kTechDataCostKey] = kNanoShieldSupportCost,
        [kTechDataResearchTimeKey] = kNanoShieldSupportTime,
        [kTechDataDisplayName] = "NANO_SHIELD_SUPPORT",
        [kTechDataTooltipInfo] = "NANO_SHIELD_TOOLTIP",
        [kTechDataResearchName] = "NANO_SHIELD_SUPPORT",
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.CatPackSupport,
        [kTechDataCostKey] = kCatPackSupportCost,
        [kTechDataResearchTimeKey] = kCatPackSupportTime,
        [kTechDataDisplayName] = "CAT_PACK_SUPPORT",
        [kTechDataTooltipInfo] = "CAT_PACK_TOOLTIP",
        [kTechDataResearchName] = "CAT_PACK_SUPPORT",
    })


    table.insert(techData, {
        [kTechDataId] = kTechId.JetpackFuelTech,
        [kTechDataCostKey] = kJetpackFuelTechResearchCost,
        [kTechDataResearchTimeKey] = kJetpackFuelTechResearchTime,
        [kTechDataDisplayName] = "JETPACK_FUEL_TECH",
        [kTechDataTooltipInfo] = "JETPACK_FUEL_TOOLTIP",
        [kTechDataResearchName] = "JETPACK_FUEL_TECH",
        [kTechDataHotkey] = Move.F,
    })        
                
    table.insert(techData, {
        [kTechDataId] = kTechId.StandardSupply,
        [kTechDataCostKey] = kStandardSupplyResearchCost,
        [kTechDataResearchTimeKey] = kStandardSupplyResearchTime,
        [kTechDataDisplayName] = "STANDARD_SUPPLY",
        [kTechDataTooltipInfo] = "STANDARD_SUPPLY_TOOLTIP",
        [kTechDataResearchName] = "STANDARD_SUPPLY",
    })
                
    table.insert(techData, {
        [kTechDataId] = kTechId.PistolAxeUpgrade,
        [kTechDataCostKey] = kPistolAxeResearchCost,
        [kTechDataResearchTimeKey] = kPistolAxeResearchTime,
        [kTechDataDisplayName] = "PISTOL_AXE_UPGRADE",
        [kTechDataTooltipInfo] = "PISTOL_AXE_UPGRADE_TOOLTIP",
        [kTechDataResearchName] = "PISTOL_AXE_UPGRADE",
    })
                
    table.insert(techData, {
        [kTechDataId] = kTechId.RifleUpgrade,
        [kTechDataCostKey] = kRifleUpgradeResearchCost,
        [kTechDataResearchTimeKey] = kRifleUpgradeResearchTime,
        [kTechDataDisplayName] = "MARINE_RIFLE_UPGRADE",
        [kTechDataTooltipInfo] = "MARINE_RIFLE_UPGRADE_TOOLTIP",
        [kTechDataResearchName] = "MARINE_RIFLE_UPGRADE",
    })
                
    table.insert(techData, {
        [kTechDataId] = kTechId.KinematicSupply,
        [kTechDataCostKey] = kKinematicSupplyResearchCost,
        [kTechDataResearchTimeKey] = kKinematicSupplyResearchTime,
        [kTechDataDisplayName] = "KINEMATIC_SUPPLY",
        [kTechDataTooltipInfo] = "KINEMATIC_SUPPLY_TOOLTIP",
        [kTechDataResearchName] = "KINEMATIC_SUPPLY",
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.DragonBreath,
        [kTechDataCostKey] = kDragonBreathResearchCost,
        [kTechDataResearchTimeKey] = kDragonBreathResearchTime,
        [kTechDataDisplayName] = "DRAGON_BREATH",
        [kTechDataTooltipInfo] = "DRAGON_BREATH_TOOLTIP",
        [kTechDataResearchName] = "DRAGON_BREATH",
    })
         
    table.insert(techData, {
        [kTechDataId] = kTechId.ExplosiveSupply,
        [kTechDataCostKey] = kExplosiveSupplyResearchCost,
        [kTechDataResearchTimeKey] = kExplosiveSupplyResearchTime,
        [kTechDataDisplayName] = "EXPLOSIVE_SUPPLY",
        [kTechDataTooltipInfo] = "EXPLOSIVE_SUPPLY_TOOLTIP",
        [kTechDataResearchName] = "EXPLOSIVE_SUPPLY",
    })
                
    table.insert(techData, {
        [kTechDataId] = kTechId.MinesUpgrade,
        [kTechDataCostKey] = kMinesUpgradeResearchCost,
        [kTechDataResearchTimeKey] = kMinesUpgradeResearchTime,
        [kTechDataDisplayName] = "MINES_UPGRADE",
        [kTechDataTooltipInfo] = "MINES_UPGRADE_TOOLTIP",
        [kTechDataResearchName] = "MINES_UPGRADE",
    })
                
    table.insert(techData, {
        [kTechDataId] = kTechId.GrenadeLauncherDetectionShot,
        [kTechDataCostKey] = kGrenadeLauncherDetectionShotResearchCost,
        [kTechDataResearchTimeKey] = kGrenadeLauncherDetectionShotResearchTime,
        [kTechDataDisplayName] = "GRENADE_LAUNCHER_DETECTION_SHOT",
        [kTechDataTooltipInfo] = "GRENADE_LAUNCHER_DETECTION_SHOT_TOOLTIP",
        [kTechDataResearchName] = "GRENADE_LAUNCHER_DETECTION_SHOT",
    })
                
    table.insert(techData, {
        [kTechDataId] = kTechId.GrenadeLauncherAllyBlast,
        [kTechDataCostKey] = kGrenadeLauncherAllyBlastResearchCost,
        [kTechDataResearchTimeKey] = kGrenadeLauncherAllyBlastResearchTime,
        [kTechDataDisplayName] = "GRENADE_LAUNCHER_ALLY_BLAST",
        [kTechDataTooltipInfo] = "GRENADE_LAUNCHER_ALLY_BLAST_TOOLTIP",
        [kTechDataResearchName] = "GRENADE_LAUNCHER_ALLY_BLAST",
    })
                
    table.insert(techData, {
        [kTechDataId] = kTechId.GrenadeLauncherUpgrade,
        [kTechDataCostKey] = kGrenadeLauncherUpgradeResearchCost,
        [kTechDataResearchTimeKey] = kGrenadeLauncherUpgradeResearchTime,
        [kTechDataDisplayName] = "GRENADE_LAUNCHER_UPGRADE",
        [kTechDataTooltipInfo] = "GRENADE_LAUNCHER_UPGRADE_TOOLTIP",
        [kTechDataResearchName] = "GRENADE_LAUNCHER_UPGRADE",
    })
			
    table.insert(techData, {
        [kTechDataId] = kTechId.Revolver,
        [kTechDataMaxHealth] = kMarineWeaponHealth,
        [kTechDataMapName] = Revolver.kMapName,
        [kTechDataModel] = Revolver.kModelName,
        [kTechDataDamageType] = kRevolverDamageType,
        [kTechDataCostKey] = kRevolverCost,
        [kTechDataDisplayName] = "REVOLVER",
        [kTechDataTooltipInfo] = "REVOLVER_TOOLTIP",
    })

----- Aliens
    table.insert(techData, { 
        [kTechDataId] = kTechId.ProwlerMenu,            
        [kTechDataDisplayName] = "UPGRADE_PROWLER",  
        [kTechDataTooltipInfo] = "UPGRADE_PROWLER_TOOLTIP", 
    })
    table.insert(techData, { 
        [kTechDataId] = kTechId.Volley,           
        [kTechDataCategory] = kTechId.Prowler, 
        [kTechDataDisplayName] = "VOLLEY", 
        [kTechDataDamageType] = kVolleyDamageType, 
        [kTechDataTooltipInfo] = "VOLLEY_TOOLTIP"
    })
    table.insert(techData, { 
        [kTechDataId] = kTechId.Rappel,           
        [kTechDataCategory] = kTechId.Prowler, 
        [kTechDataDisplayName] = "RAPPEL", 
        [kTechDataCostKey] = kRappelResearchCost, 
        [kTechDataResearchTimeKey] = kRappelResearchTime, 
        [kTechDataTooltipInfo] = "RAPPEL_TOOLTIP" 
    })
    table.insert(techData, { 
        [kTechDataId] = kTechId.AcidSpray,           
        [kTechDataCategory] = kTechId.Prowler, 
        [kTechDataMapName] = AcidSpray.kMapName, 
        [kTechDataDisplayName] = "ACID_SPRAY", 
        [kTechDataCostKey] = kAcidSprayResearchCost, 
        [kTechDataResearchTimeKey] = kAcidSprayResearchTime, 
        [kTechDataTooltipInfo] = "ACID_SPRAY_TOOLTIP" 
    })
    table.insert(techData,  { 
		[kTechDataId] = kTechId.Prowler, 
		[kTechDataUpgradeCost] = kProwlerUpgradeCost, 
		[kTechDataMapName] = Prowler.kMapName, 
		[kTechDataGestateName] = Prowler.kMapName,                      
		[kTechDataGestateTime] = kProwlerGestateTime, 
		[kTechDataDisplayName] = "PROWLER",  
		[kTechDataTooltipInfo] = "PROWLER_TOOLTIP",        
		[kTechDataModel] = Prowler.kModelName, 
		[kTechDataCostKey] = kProwlerCost, 
		[kTechDataMaxHealth] = Prowler.kHealth, 
		[kTechDataMaxArmor] = Prowler.kArmor, 
		[kTechDataEngagementDistance] = kPlayerEngagementDistance, 
		[kTechDataMaxExtents] = Vector(Prowler.kXExtents, Prowler.kYExtents, Prowler.kZExtents), 
		[kTechDataPointValue] = kProwlerPointValue
	})
	
    table.insert(techData, { [kTechDataId] = kTechId.HallucinateProwler,             
                             [kTechDataMapName] = ProwlerHallucination.kMapName,
                             [kTechDataModel] = Prowler.kModelName,
                             [kTechDataCostKey] = kProwlerCost,
                             [kTechDataMaxHealth] = kProwlerHallucinationHealth,
                             [kTechDataMaxArmor] = Prowler.kArmor,
                             [kTechDataRequiresMature] = true, 
                             [kTechDataDisplayName] = "HALLUCINATE_DRIFTER", 
                             [kTechDataTooltipInfo] = "HALLUCINATE_DRIFTER_TOOLTIP", 
                             [kTechDataCostKey] = kHallucinateLerkEnergyCost })

    table.insert(techData, {
        [kTechDataId] = kTechId.Devour, 
        [kTechDataCategory] = kTechId.Onos,
        [kTechDataMapName] = Devour.kMapName,
        [kTechDataCostKey] = kOnosDevourCost,
        [kTechDataResearchTimeKey] = kOnosDevourTime, 
        [kTechDataDisplayName] = "ONOS_DEVOUR",
        [kTechDataTooltipInfo] = "ONOS_DEVOUR_TOOLTIP",
        [kTechDataResearchName] = "ONOS_DEVOUR",
    })
                
        
    table.insert(techData, {
        [kTechDataId] = kTechId.FastTunnel,
        [kTechDataCostKey] = kFastTunnelCost,
        [kTechDataResearchTimeKey] = kFastTunnelTime,
        [kTechDataDisplayName] = "FAST_TUNNEL",
        [kTechDataTooltipInfo] = "FAST_TUNNEL_TOOLTIP",
        [kTechDataResearchName] = "FAST_TUNNEL",
    })
                
        
    table.insert(techData, {
        [kTechDataId] = kTechId.BuildTunnelEntryOne,
        [kTechDataMaxExtents] = Vector(0.6,0.6,0.6),
        [kTechDataTooltipInfo] = "TUNNEL_TOOLTIP",
        [kTechDataGhostModelClass] = "AlienGhostModel",
        [kTechDataMapName] = TunnelEntrance.kMapName,
        [kTechDataDisplayName] = "TUNNEL_ENTRY",
        [kTechDataHint] = "TUNNEL_ENTRANCE_HINT",
        [kTechDataCostKey] = kTunnelEntranceCost,
        [kTechDataMaxHealth] = kTunnelEntranceHealth,
        [kTechDataMaxArmor] = kTunnelEntranceArmor,
        [kTechDataBuildTime] = kTunnelBuildTime,
        [kTechDataModel] = TunnelEntrance.kModelName,
        [kTechDataPointValue] = kTunnelEntrancePointValue,
    })
                
        
    table.insert(techData, {
        [kTechDataId] = kTechId.BuildTunnelExitOne,
        [kTechDataMaxExtents] = Vector(0.6,0.6,0.6),
        [kTechDataTooltipInfo] = "TUNNEL_EXIT_TOOLTIP",
        [kTechDataGhostModelClass] = "AlienGhostModel",
        [kTechDataMapName] = TunnelEntrance.kMapName,
        [kTechDataDisplayName] = "TUNNEL_EXIT",
        [kTechDataHint] = "TUNNEL_ENTRANCE_HINT",
        [kTechDataCostKey] = kTunnelExitCost,
        [kTechDataMaxHealth] = kTunnelEntranceHealth,
        [kTechDataMaxArmor] = kTunnelEntranceArmor,
        [kTechDataBuildTime] = kTunnelBuildTime,
        [kTechDataModel] = TunnelEntrance.kModelName,
        [kTechDataPointValue] = kTunnelEntrancePointValue,
    })
                
        
    table.insert(techData, {
        [kTechDataId] = kTechId.BuildTunnelEntryTwo,
        [kTechDataMaxExtents] = Vector(0.6,0.6,0.6),
        [kTechDataTooltipInfo] = "TUNNEL_TOOLTIP",
        [kTechDataGhostModelClass] = "AlienGhostModel",
        [kTechDataMapName] = TunnelEntrance.kMapName,
        [kTechDataDisplayName] = "TUNNEL_ENTRY",
        [kTechDataHint] = "TUNNEL_ENTRANCE_HINT",
        [kTechDataCostKey] = kTunnelEntranceCost,
        [kTechDataMaxHealth] = kTunnelEntranceHealth,
        [kTechDataMaxArmor] = kTunnelEntranceArmor,
        [kTechDataBuildTime] = kTunnelBuildTime,
        [kTechDataModel] = TunnelEntrance.kModelName,
        [kTechDataPointValue] = kTunnelEntrancePointValue,
    })
                
        
    table.insert(techData, {
        [kTechDataId] = kTechId.BuildTunnelExitTwo,
        [kTechDataMaxExtents] = Vector(0.6,0.6,0.6),
        [kTechDataTooltipInfo] = "TUNNEL_EXIT_TOOLTIP",
        [kTechDataGhostModelClass] = "AlienGhostModel",
        [kTechDataMapName] = TunnelEntrance.kMapName,
        [kTechDataDisplayName] = "TUNNEL_EXIT",
        [kTechDataHint] = "TUNNEL_ENTRANCE_HINT",
        [kTechDataCostKey] = kTunnelExitCost,
        [kTechDataMaxHealth] = kTunnelEntranceHealth,
        [kTechDataMaxArmor] = kTunnelEntranceArmor,
        [kTechDataBuildTime] = kTunnelBuildTime,
        [kTechDataModel] = TunnelEntrance.kModelName,
        [kTechDataPointValue] = kTunnelEntrancePointValue,
    })
                
        
    table.insert(techData, {
        [kTechDataId] = kTechId.BuildTunnelEntryThree,
        [kTechDataMaxExtents] = Vector(0.6,0.6,0.6),
        [kTechDataTooltipInfo] = "TUNNEL_TOOLTIP",
        [kTechDataGhostModelClass] = "AlienGhostModel",
        [kTechDataMapName] = TunnelEntrance.kMapName,
        [kTechDataDisplayName] = "TUNNEL_ENTRY",
        [kTechDataHint] = "TUNNEL_ENTRANCE_HINT",
        [kTechDataCostKey] = kTunnelEntranceCost,
        [kTechDataMaxHealth] = kTunnelEntranceHealth,
        [kTechDataMaxArmor] = kTunnelEntranceArmor,
        [kTechDataBuildTime] = kTunnelBuildTime,
        [kTechDataModel] = TunnelEntrance.kModelName,
        [kTechDataPointValue] = kTunnelEntrancePointValue,
    })
                
        
    table.insert(techData, {
        [kTechDataId] = kTechId.BuildTunnelExitThree,
        [kTechDataMaxExtents] = Vector(0.6,0.6,0.6),
        [kTechDataTooltipInfo] = "TUNNEL_EXIT_TOOLTIP",
        [kTechDataGhostModelClass] = "AlienGhostModel",
        [kTechDataMapName] = TunnelEntrance.kMapName,
        [kTechDataDisplayName] = "TUNNEL_EXIT",
        [kTechDataHint] = "TUNNEL_ENTRANCE_HINT",
        [kTechDataCostKey] = kTunnelExitCost,
        [kTechDataMaxHealth] = kTunnelEntranceHealth,
        [kTechDataMaxArmor] = kTunnelEntranceArmor,
        [kTechDataBuildTime] = kTunnelBuildTime,
        [kTechDataModel] = TunnelEntrance.kModelName,
        [kTechDataPointValue] = kTunnelEntrancePointValue,
    })
                
        
    table.insert(techData, {
        [kTechDataId] = kTechId.BuildTunnelEntryFour,
        [kTechDataMaxExtents] = Vector(0.6,0.6,0.6),
        [kTechDataTooltipInfo] = "TUNNEL_TOOLTIP",
        [kTechDataGhostModelClass] = "AlienGhostModel",
        [kTechDataMapName] = TunnelEntrance.kMapName,
        [kTechDataDisplayName] = "TUNNEL_ENTRY",
        [kTechDataHint] = "TUNNEL_ENTRANCE_HINT",
        [kTechDataCostKey] = kTunnelEntranceCost,
        [kTechDataMaxHealth] = kTunnelEntranceHealth,
        [kTechDataMaxArmor] = kTunnelEntranceArmor,
        [kTechDataBuildTime] = kTunnelBuildTime,
        [kTechDataModel] = TunnelEntrance.kModelName,
        [kTechDataPointValue] = kTunnelEntrancePointValue,
    })
                
        
    table.insert(techData, {
        [kTechDataId] = kTechId.BuildTunnelExitFour,
        [kTechDataMaxExtents] = Vector(0.6,0.6,0.6),
        [kTechDataTooltipInfo] = "TUNNEL_EXIT_TOOLTIP",
        [kTechDataGhostModelClass] = "AlienGhostModel",
        [kTechDataMapName] = TunnelEntrance.kMapName,
        [kTechDataDisplayName] = "TUNNEL_EXIT",
        [kTechDataHint] = "TUNNEL_ENTRANCE_HINT",
        [kTechDataCostKey] = kTunnelExitCost,
        [kTechDataMaxHealth] = kTunnelEntranceHealth,
        [kTechDataMaxArmor] = kTunnelEntranceArmor,
        [kTechDataBuildTime] = kTunnelBuildTime,
        [kTechDataModel] = TunnelEntrance.kModelName,
        [kTechDataPointValue] = kTunnelEntrancePointValue,
    })

    return techData

end