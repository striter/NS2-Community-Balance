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
        [kTechDataId] = kTechId.AxeUpgrade,
        [kTechDataCostKey] = kAxeUpgradeCost,
        [kTechDataResearchTimeKey] = kAxeUpgradeResearchTime,
        [kTechDataDisplayName] = "AXE_UPGRADE",
        [kTechDataTooltipInfo] = "AXE_UPGRADE_TOOLTIP",
        [kTechDataResearchName] = "AXE_UPGRADE",
    })
                
    table.insert(techData, {
        [kTechDataId] = kTechId.LightMachineGunUpgrade,
        [kTechDataCostKey] = kLightMachineGunUpgradeCost,
        [kTechDataResearchTimeKey] = kLightMachineGunUpgradeTime,
        [kTechDataDisplayName] = "LIGHTMACHINEGUN_UPGRADE",
        [kTechDataTooltipInfo] = "LIGHTMACHINEGUN_UPGRADE_TOOLTIP",
        [kTechDataResearchName] = "LIGHTMACHINEGUN_UPGRADE",
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
        [kTechDataId] = kTechId.Knife,
        [kTechDataMapName] = Knife.kMapName,
        [kTechDataDisplayName] = "KNIFE",
        [kTechDataModel] = Knife.kModelName,
        [kTechDataDamageType] = kKnifeDamageType,
        [kTechDataCostKey] = kKnifeCost,
        [kTechDataTooltipInfo] = "KNIFE_TOOLTIP",
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

	table.insert(techData,{ 
	
        [kTechDataId] = kTechId.SubMachineGun,
        [kTechDataMaxHealth] = kMarineWeaponHealth,
        [kTechDataPointValue] = kSubMachineGunPointValue,
        [kTechDataMapName] = SubMachineGun.kMapName,
        [kTechDataTooltipInfo] = "SUBMACHINEGUN_TOOLTIP",
        [kTechDataDisplayName] = "SUBMACHINEGUN",
        [kTechDataModel] = SubMachineGun.kModelName,
        [kTechDataDamageType] = kSubMachineGunDamageType,
        [kTechDataCostKey] = kSubMachineGunCost,
    })

	table.insert(techData,{ 
	
        [kTechDataId] = kTechId.LightMachineGun,
        [kTechDataMaxHealth] = kMarineWeaponHealth,
        [kTechDataPointValue] = kLightMachineGunPointValue,
        [kTechDataMapName] = LightMachineGun.kMapName,
        [kTechDataTooltipInfo] = "LIGHTMACHINEGUN_TOOLTIP",
        [kTechDataDisplayName] = "LIGHTMACHINEGUN",
        [kTechDataModel] = LightMachineGun.kModelName,
        [kTechDataDamageType] = kLightMachineGunDamageType,
        [kTechDataCostKey] = kLightMachineGunCost,
    })

    table.insert(techData,{ 
        [kTechDataId] = kTechId.Cannon,
        [kTechDataMaxHealth] = kMarineWeaponHealth,
        [kTechDataTooltipInfo] = "CANNON_TOOLTIP",
        [kTechDataPointValue] = kCannonPointValue,
        [kTechDataMapName] = Cannon.kMapName,
        [kTechDataDisplayName] = "CANNON",
        [kTechDataModel] = Cannon.kModelName,
        [kTechDataDamageType] = kCannonDamageType,
        [kTechDataCostKey] = kCannonCost,
    } )

    table.insert(techData,{
        [kTechDataId] = kTechId.CannonTech,
        [kTechDataCostKey] = kCannonTechResearchCost,
        [kTechDataResearchTimeKey] = kCannonTechResearchTime,
        [kTechDataDisplayName] = "RESEARCH_CANNON",
        [kTechDataTooltipInfo] = "CANNON_TOOLTIP", 
    } )

    table.insert(techData,{ 
        [kTechDataId] = kTechId.DropCannon,
        [kTechDataMapName] = Cannon.kMapName,
        [kTechDataDisplayName] = "CANNON_DROP",
        [kTechIDShowEnables] = false,
        [kTechDataTooltipInfo] = "CANNON_TOOLTIP",
        [kTechDataModel] = Cannon.kModelName,
        [kTechDataCostKey] = kCannonCost,
        [kStructureAttachId] = { kTechId.AdvancedArmory },
        [kStructureAttachRange] = kArmoryWeaponAttachRange,
        [kStructureAttachRequiresPower] = true, 
    } )

    table.insert(techData,{ 
        [kTechDataId] = kTechId.CombatBuilder,
        [kTechDataDisplayName] = "COMBATBUILDER",
        [kTechDataMapName] = CombatBuilder.kMapName,
        [kTechDataModel] = CombatBuilder.kModelName,
        [kTechDataCostKey] = kCombatBuilderCost, 
        [kTechDataMaxHealth] = kMarineWeaponHealth,
        [kTechDataPointValue] = kCombatBuilderPointValue,
    })
    
    table.insert(techData,{ 
        [kTechDataId] = kTechId.WeaponCache, 	          
        [kTechDataDisplayName] = "WEAPON_CACHE",    
        [kTechDataHint] = "WEAPON_CACHE_HINT", 
        [kTechDataGhostModelClass] = "MarineGhostModel", 
        [kTechDataRequiresPower] = false,      
        [kTechDataMapName] = WeaponCache.kMapName,                   
        [kTechDataBuildTime] = kWeaponCacheBuildTime, 
        [kTechDataMaxHealth] = kWeaponCacheHealth, 
        [kTechDataMaxArmor] = kWeaponCacheArmor, 
        [kTechDataEngagementDistance] = kArmoryEngagementDistance, 
        [kTechDataModel] = WeaponCache.kModelName, 
        [kTechDataPointValue] = kWeaponCachePointValue, 
        [kTechDataNotOnInfestation] = kPreventMarineStructuresOnInfestation,
        [kTechDataCostKey] = kWeaponCacheCost,             
        -- [kTechDataTooltipInfo] = "WEAPONCACHE_TOOLIP", 
        [kTechDataAllowConsumeDrop] = true, 
        [kTechDataMaxAmount] = 1 
    })

    table.insert(techData,  {
        [kTechDataId] = kTechId.Sentry,
        [kTechDataSupply] = kSentrySupply,
        [kTechDataBuildMethodFailedMessage] = "COMMANDERERROR_TOO_MANY_SENTRIES",
        [kTechDataHint] = "SENTRY_HINT",
        [kTechDataGhostModelClass] = "MarineGhostModel",
        [kTechDataMapName] = Sentry.kMapName,
        [kTechDataDisplayName] = "SENTRY_TURRET",
        [kTechDataCostKey] = kSentryCost,
        [kTechDataPointValue] = kSentryPointValue,
        [kTechDataModel] = Sentry.kModelName,
        [kTechDataBuildTime] = kSentryBuildTime,
        [kTechDataMaxHealth] = kSentryHealth,
        [kTechDataMaxArmor] = kSentryArmor,
        [kTechDataDamageType] = kSentryAttackDamageType,
        [kTechDataSpecifyOrientation] = true,
        [kTechDataHotkey] = Move.S,
        [kTechDataInitialEnergy] = kSentryInitialEnergy,
        [kTechDataMaxEnergy] = kSentryMaxEnergy,
        [kTechDataNotOnInfestation] = kPreventMarineStructuresOnInfestation,
        [kTechDataEngagementDistance] = kSentryEngagementDistance,
        [kTechDataTooltipInfo] = "SENTRY_TOOLTIP",
        [kStructureBuildNearClass] = "SentryBattery",
        [kStructureAttachRange] = SentryBattery.kRange,
        [kTechDataBuildRequiresMethod] = GetCheckSentryLimit,
        [kTechDataGhostGuidesMethod] = GetBatteryInRange,
        [kTechDataObstacleRadius] = 0.25,
        [kTechDataMaxAmount] = 2,
        [kTechDataAllowConsumeDrop] = true, 
    })


----- Aliens

    -- Fix Gorge Visualize

    table.insert(techData,{
        [kTechDataId] = kTechId.BellySlide,
        [kTechDataCategory] = kTechId.Gorge,
        [kTechDataDisplayName] = "BELLY_SLIDE",
        [kTechDataTooltipInfo] = "BELLY_SLIDE_TOOLTIP",
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.BuildAbility,
        [kTechDataMapName] = DropStructureAbility.kMapName,
        [kTechDataCategory] = kTechId.Gorge,
        [kTechDataDisplayName] = "BUILD_ABILITY",
        [kTechDataTooltipInfo] = "BUILD_ABILITY_TOOLTIP",
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.SporeMine,
        -- [kTechDataCategory] = kTechId.Gorge,
        [kTechDataAllowConsumeDrop] = true,
        [kTechDataMaxAmount] = kNumSporeMinesPerGorge,
        [kTechDataCostKey] = kSporeMineCost,
        [kTechDataBuildTime] = kSporeMineBuildTime,
        [kTechDataMapName] = SporeMine.kMapName,
        [kTechDataModel] = SporeMine.kModelName,
        [kTechDataMaxHealth] = kSporeMineHealth,
        [kTechDataMaxArmor] = kSporeMineArmor,
        [kTechDataPointValue] = kSporeMinepointValue,
        [kTechDataDisplayName] = "SPORE_MINE",
        [kTechDataHint] = "SPORE_MINE_TOOLTIP",
        [kTechDataTooltipInfo] = "SPORE_MINE_TOOLTIP", 
    })

    --Prowler

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
	
    table.insert(techData, { 
        [kTechDataId] = kTechId.HallucinateProwler,             
        [kTechDataMapName] = ProwlerHallucination.kMapName,
        [kTechDataModel] = Prowler.kModelName,
        [kTechDataCostKey] = kProwlerCost,
        [kTechDataMaxHealth] = kProwlerHallucinationHealth,
        [kTechDataMaxArmor] = Prowler.kArmor,
        [kTechDataRequiresMature] = true, 
        [kTechDataDisplayName] = "HALLUCINATE_DRIFTER", 
        [kTechDataTooltipInfo] = "HALLUCINATE_DRIFTER_TOOLTIP", 
    })


    -- Devour
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
                
        
    --Tunnels
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
        [kTechDataCostKey] = kTunnelEntranceCost,
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
        [kTechDataCostKey] = kTunnelEntranceCost,
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
        [kTechDataCostKey] = kTunnelEntranceCost,
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
        [kTechDataCostKey] = kTunnelEntranceCost,
        [kTechDataMaxHealth] = kTunnelEntranceHealth,
        [kTechDataMaxArmor] = kTunnelEntranceArmor,
        [kTechDataBuildTime] = kTunnelBuildTime,
        [kTechDataModel] = TunnelEntrance.kModelName,
        [kTechDataPointValue] = kTunnelEntrancePointValue,
    })
    return techData
end