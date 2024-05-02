
kTechDataPlayersRestrictionKey = "playersrestrictionkey"
kTechDataPersonalCostKey = "costpersonalkey"
kTechDataLayoutKey     = "layoutKey"
kTechDataTeamResOnKillKey = "tResOnKillKey"

local oldBuildTechData = BuildTechData
function BuildTechData()

    local techData = oldBuildTechData()
    table.insert(techData,{
        [kTechDataId] = kTechId.MilitaryProtocol,
        [kTechDataCostKey] = kMilitaryProtocolResearchCost,
        [kTechDataResearchTimeKey] = kMilitaryProtocolResearchTime,
        [kTechDataDisplayName] = "MILITARY_PROTOCOL",
        [kTechDataTooltipInfo] = "MILITARY_PROTOCOL_TOOLTIP",
        [kTechDataResearchName] = "MILITARY_PROTOCOL",
    } )

    table.insert(techData,{
        [kTechDataId] = kTechId.MotionTrack,
        [kTechDataCostKey] = kMotionTrackResearchCost,
        [kTechDataResearchTimeKey] = kMotionTrackResearchTime,
        [kTechDataDisplayName] = "MOTION_TRACK",
        [kTechDataTooltipInfo] = "MOTION_TRACK_TOOLTIP",
        [kTechDataResearchName] = "MOTION_TRACK",
    } )

    table.insert(techData, {
        [kTechDataId] = kTechId.CombatBuilderTech,
        [kTechDataCostKey] = kCombatBuilderResearchCost,
        [kTechDataResearchTimeKey] = kCombatBuilderResearchTime,
        [kTechDataDisplayName] = "COMBATBUILDER",
        [kTechDataTooltipInfo] = "COMBATBUILDER_TOOLTIP",
        [kTechDataResearchName] = "COMBATBUILDER",
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
        [kTechDataId] = kTechId.StandardSupply,
        [kTechDataCostKey] = kCommandStationUpgradeCost,
        [kTechDataResearchTimeKey] = kCommandStationUpgradeTime,
        [kTechDataDisplayName] = "STANDARD_SUPPLY",
        [kTechDataTooltipInfo] = "STANDARD_SUPPLY_TOOLTIP",
        [kTechDataResearchName] = "STANDARD_SUPPLY",
        [kTechDataUpgradeTech] = kTechId.CommandStation,
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.StandardStation,
        [kTechDataMapName] = CommandStation.kMapName,
        [kTechDataModel] = CommandStation.kModelName,
        [kTechDataMaxHealth] = kUpgradedCommandStationHealth,
        [kTechDataMaxArmor] = kUpgradedCommandStationArmor,
        [kTechDataPointValue] = kUpgradedCommandStationPointValue,
        [kTechDataHint] = "STANDARD_STATION_HINT",
        [kTechDataDisplayName] = "STANDARD_STATION",
        [kTechDataTooltipInfo] = "STANDARD_SUPPLY_TOOLTIP",
        [kStructureAttachClass] = "TechPoint",
        [kTechDataGhostModelClass] = "MarineGhostModel",
        [kTechDataCostKey] = kUpgradedCommandStationCost,
        [kTechDataEngagementDistance] = kCommandStationEngagementDistance,
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
        [kTechDataId] = kTechId.DragonBreath,
        [kTechDataCostKey] = kDragonBreathResearchCost,
        [kTechDataResearchTimeKey] = kDragonBreathResearchTime,
        [kTechDataDisplayName] = "DRAGON_BREATH",
        [kTechDataTooltipInfo] = "DRAGON_BREATH_TOOLTIP",
        [kTechDataResearchName] = "DRAGON_BREATH",
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.ArmorSupply,
        [kTechDataCostKey] = kCommandStationUpgradeCost,
        [kTechDataResearchTimeKey] = kCommandStationUpgradeTime,
        [kTechDataDisplayName] = "ARMOR_SUPPLY",
        [kTechDataTooltipInfo] = "ARMOR_SUPPLY_TOOLTIP",
        [kTechDataResearchName] = "ARMOR_SUPPLY",
        [kTechDataUpgradeTech] = kTechId.CommandStation,
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.ArmorStation,
        [kTechDataMapName] = CommandStation.kMapName,
        [kTechDataModel] = CommandStation.kModelName,
        [kTechDataMaxHealth] = kUpgradedCommandStationHealth,
        [kTechDataMaxArmor] = kUpgradedCommandStationArmor,
        [kTechDataPointValue] = kUpgradedCommandStationPointValue,
        [kTechDataHint] = "ARMOR_STATION_HINT",
        [kTechDataDisplayName] = "ARMOR_STATION",
        [kTechDataTooltipInfo] = "ARMOR_SUPPLY_TOOLTIP",
        [kStructureAttachClass] = "TechPoint",
        [kTechDataGhostModelClass] = "MarineGhostModel",
        [kTechDataCostKey] = kUpgradedCommandStationCost,
        [kTechDataEngagementDistance] = kCommandStationEngagementDistance,
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
        [kTechDataId] = kTechId.ArmorRegen,
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
        [kTechDataId] = kTechId.ExplosiveSupply,
        [kTechDataCostKey] = kCommandStationUpgradeCost,
        [kTechDataResearchTimeKey] = kCommandStationUpgradeTime,
        [kTechDataDisplayName] = "EXPLOSIVE_SUPPLY",
        [kTechDataResearchName] = "EXPLOSIVE_SUPPLY",
        [kTechDataTooltipInfo] = "EXPLOSIVE_SUPPLY_TOOLTIP",
        [kTechDataUpgradeTech] = kTechId.CommandStation,
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.ExplosiveStation,
        [kTechDataMapName] = CommandStation.kMapName,
        [kTechDataModel] = CommandStation.kModelName,
        [kTechDataMaxHealth] = kUpgradedCommandStationHealth,
        [kTechDataMaxArmor] = kUpgradedCommandStationArmor,
        [kTechDataPointValue] = kUpgradedCommandStationPointValue,
        [kTechDataHint] = "EXPLOSIVE_STATION_HINT",
        [kTechDataDisplayName] = "EXPLOSIVE_STATION",
        [kTechDataTooltipInfo] = "EXPLOSIVE_SUPPLY_TOOLTIP",
        [kStructureAttachClass] = "TechPoint",
        [kTechDataGhostModelClass] = "MarineGhostModel",
        [kTechDataCostKey] = kUpgradedCommandStationCost,
        [kTechDataEngagementDistance] = kCommandStationEngagementDistance,
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.MineDeploy,
        [kTechDataMapName] = Mine.kMapName,
        [kTechDataDisplayName] = "MINE_DEPLOY",
        [kTechDataCostKey] = kMineDeployCost,
        [kTechDataModel] = Mine.kModelName,
        [kTechDataTooltipInfo] = "MINE_DEPLOY_TOOLTIP",
        [kTechDataSpawnHeightOffset] = kCommanderDropSpawnHeight,
    })
    --table.insert(techData, {
    --    [kTechDataId] = kTechId.GrenadeLauncherDetectionShot,
    --    [kTechDataCostKey] = kGrenadeLauncherDetectionShotResearchCost,
    --    [kTechDataResearchTimeKey] = kGrenadeLauncherDetectionShotResearchTime,
    --    [kTechDataDisplayName] = "GRENADE_LAUNCHER_DETECTION_SHOT",
    --    [kTechDataTooltipInfo] = "GRENADE_LAUNCHER_DETECTION_SHOT_TOOLTIP",
    --    [kTechDataResearchName] = "GRENADE_LAUNCHER_DETECTION_SHOT",
    --})
    --
    --table.insert(techData, {
    --    [kTechDataId] = kTechId.GrenadeLauncherAllyBlast,
    --    [kTechDataCostKey] = kGrenadeLauncherAllyBlastResearchCost,
    --    [kTechDataResearchTimeKey] = kGrenadeLauncherAllyBlastResearchTime,
    --    [kTechDataDisplayName] = "GRENADE_LAUNCHER_ALLY_BLAST",
    --    [kTechDataTooltipInfo] = "GRENADE_LAUNCHER_ALLY_BLAST_TOOLTIP",
    --    [kTechDataResearchName] = "GRENADE_LAUNCHER_ALLY_BLAST",
    --})


    table.insert(techData,{
        [kTechDataId] = kTechId.ElectronicSupply,
        [kTechDataCostKey] = kCommandStationUpgradeCost,
        [kTechDataResearchTimeKey] = kCommandStationUpgradeTime,
        [kTechDataDisplayName] = "ELECTRONIC_SUPPLY",
        [kTechDataResearchName] = "ELECTRONIC_SUPPLY",
        [kTechDataTooltipInfo] = "ELECTRONIC_SUPPLY_TOOLTIP",
        [kTechDataUpgradeTech] = kTechId.CommandStation,
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.ElectronicStation,
        [kTechDataMapName] = CommandStation.kMapName,
        [kTechDataModel] = CommandStation.kModelName,
        [kTechDataMaxHealth] = kUpgradedCommandStationHealth,
        [kTechDataMaxArmor] = kUpgradedCommandStationArmor,
        [kTechDataPointValue] = kUpgradedCommandStationPointValue,
        [kTechDataHint] = "ELECTRONIC_STATION_HINT",
        [kTechDataDisplayName] = "ELECTRONIC_STATION",
        [kTechDataTooltipInfo] = "ELECTRONIC_SUPPLY_TOOLTIP",
        [kStructureAttachClass] = "TechPoint",
        [kTechDataGhostModelClass] = "MarineGhostModel",
        [kTechDataCostKey] = kUpgradedCommandStationCost,
        [kTechDataEngagementDistance] = kCommandStationEngagementDistance,
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.MACEMPBlast,
        [kTechDataCostKey] = kMACEMPBlastResearchCost,
        [kTechDataResearchTimeKey] = kMACEMPBlastResearchTime,
        [kTechDataDisplayName] = "MAC_EMP_BLAST",
        [kTechDataTooltipInfo] = "MAC_EMP_BLAST_TOOLTIP",
        [kTechDataResearchName] = "MAC_EMP_BLAST",
    })
    table.insert(techData, {
        [kTechDataId] = kTechId.PoweredExtractorTech,
        [kTechDataCostKey] = kPoweredExtractorResearchCost,
        [kTechDataResearchTimeKey] = kPoweredExtractorResearchTime,
        [kTechDataDisplayName] = "POWERED_EXTRACTOR_TECH",
        [kTechDataTooltipInfo] = "POWERED_EXTRACTOR_TECH_TOOLTIP",
        [kTechDataResearchName] = "POWERED_EXTRACTOR_TECH",
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.PoweredExtractor,
        [kTechDataIgnorePathingMesh] = true,
        [kTechDataSpawnBlock] = true,
        [kTechDataCollideWithWorldOnly] = true,
        [kTechDataAllowStacking] = true,
        [kTechDataGhostModelClass] = "MarineGhostModel",
        [kTechDataRequiresPower] = true,
        [kTechDataMapName] = PoweredExtractor.kMapName,
        [kTechDataDisplayName] = "POWERED_EXTRACTOR",
        [kTechDataBuildTime] = kExtractorBuildTime,
        [kTechDataEngagementDistance] = kExtractorEngagementDistance,
        [kTechDataModel] = Extractor.kModelName,
        [kStructureAttachClass] = "ResourcePoint",
        [kTechDataHotkey] = Move.E,
        [kTechDataNotOnInfestation] = kPreventMarineStructuresOnInfestation,
        [kTechDataTooltipInfo] = "POWERED_EXTRACTOR_TECH_TOOLTIP",
        [kTechDataHint] = "POWERED_EXTRACTOR_HINT",
        [kTechDataObstacleRadius] = 1.35,
        [kTechDataMaxHealth] = kPoweredExtractorHealth,
        [kTechDataMaxArmor] = kPoweredExtractorArmor,
        [kTechDataPointValue] = kPoweredExtractorPointValue,
        [kTechDataCostKey] = kPoweredExtractorCost,
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.PoweredExtractorUpgrade,
        [kTechDataCostKey] = kPoweredExtractorUpgradeCost,
        [kTechDataResearchTimeKey] = kPoweredExtractorUpgradeTime,
        [kTechDataDisplayName] = "POWERED_EXTRACTOR_TECH",
        [kTechDataTooltipInfo] = "POWERED_EXTRACTOR_TECH_TOOLTIP",
        [kTechDataResearchName] = "POWERED_EXTRACTOR_TECH",
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.InfantryPortal,
        [kTechDataHint] = "INFANTRY_PORTAL_HINT",
        [kTechDataSupply] = kInfantryPortalSupply,
        [kTechDataGhostModelClass] = "MarineGhostModel",
        [kTechDataRequiresPower] = true,
        [kTechDataGhostGuidesMethod] = GetInfantryPortalGhostGuides,
        [kTechDataBuildRequiresMethod] = GetCommandStationIsBuilt,
        [kTechDataMapName] = InfantryPortal.kMapName,
        [kTechDataDisplayName] = "INFANTRY_PORTAL",
        [kTechDataCostKey] = kInfantryPortalCost,
        [kTechDataPointValue] = kInfantryPortalPointValue,
        [kTechDataBuildTime] = kInfantryPortalBuildTime,
        [kTechDataMaxHealth] = kInfantryPortalHealth,
        [kTechDataMaxArmor] = kInfantryPortalArmor,
        [kTechDataModel] = InfantryPortal.kModelName,
        [kStructureBuildNearClass] = "CommandStation",
        [kStructureAttachId] = {kTechId.CommandStation,kTechId.StandardStation,kTechId.ArmorStation,kTechId.ExplosiveStation,kTechId.ElectronicStation},        --For Stations
        [kStructureAttachRange] = kInfantryPortalAttachRange,
        [kTechDataEngagementDistance] = kInfantryPortalEngagementDistance,
        [kTechDataHotkey] = Move.P,
        [kTechDataNotOnInfestation] = kPreventMarineStructuresOnInfestation,
        [kTechDataTooltipInfo] = "INFANTRY_PORTAL_TOOLTIP",
        [kTechDataObstacleRadius] = 1.125,
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.Scan,
        [kTechDataAllowStacking] = true,
        [kTechDataCollideWithWorldOnly] = true,
        [kTechDataIgnorePathingMesh] = true,
        [kTechDataMapName] = Scan.kMapName,
        [kTechDataDisplayName] = "SCAN",
        [kTechDataHotkey] = Move.S,
        [kVisualRange] = kScanRadius,
        [kTechDataCostKey] = kObservatoryScanCost,
        [kTechDataCooldown] = kScanCooldown,
        [kTechDataTooltipInfo] = "SCAN_TOOLTIP",
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
        [kTechDataId] = kTechId.LightMachineGunAcquire,
        [kTechDataTooltipInfo] = "LIGHTMACHINEGUN_TOOLTIP",
        [kTechDataDisplayName] = "LIGHTMACHINEGUN",
        [kTechDataMapName] = LightMachineGun.kMapName,
        [kTechDataCostKey] = kLightMachineGunAcquireCost,
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.LightMachineGunUpgrade,
        [kTechDataMapName] = LightMachineGun.kMapName,
        [kTechDataTooltipInfo] = "LIGHTMACHINEGUN_TOOLTIP",
        [kTechDataDisplayName] = "LIGHTMACHINEGUN",
        [kTechDataCostKey] = kLightMachineGunUpgradeCost,
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.GrenadeLauncher,
        [kTechDataMaxHealth] = kMarineWeaponHealth,
        [kTechDataPointValue] = kGrenadeLauncherPointValue,
        [kTechDataMapName] = GrenadeLauncher.kMapName,
        [kTechDataDisplayName] = "GRENADE_LAUNCHER",
        [kTechDataTooltipInfo] = "GRENADE_LAUNCHER_TOOLTIP",
        [kTechDataModel] = GrenadeLauncher.kModelName,
        [kTechDataDamageType] = kRifleDamageType,
        [kTechDataCostKey] = kGrenadeLauncherCost,
        [kStructureAttachId] = kTechId.Armory,
        [kStructureAttachRange] = kArmoryWeaponAttachRange,
        [kStructureAttachRequiresPower] = true,
        [kTechDataPlayersRestrictionKey] = kGrenadeLauncherPlayersAlert,
    } )

    table.insert(techData,{
        [kTechDataId] = kTechId.Flamethrower,
        [kTechDataMaxHealth] = kMarineWeaponHealth,
        [kTechDataPointValue] = kFlamethrowerPointValue,
        [kTechDataMapName] = Flamethrower.kMapName,
        [kTechDataDisplayName] = "FLAMETHROWER",
        [kTechDataTooltipInfo] = "FLAMETHROWER_TOOLTIP",
        [kTechDataModel] = Flamethrower.kModelName,
        [kTechDataDamageType] = kFlamethrowerDamageType,
        [kTechDataCostKey] = kFlamethrowerCost,
        [kStructureAttachId] = kTechId.Armory,
        [kStructureAttachRange] = kArmoryWeaponAttachRange,
        [kStructureAttachRequiresPower] = true,
        [kTechDataPlayersRestrictionKey] = kFlameThrowerPlayersAlert,
    } )


    table.insert(techData,{
        [kTechDataId] = kTechId.Welder,
        [kTechDataMaxHealth] = kMarineWeaponHealth,
        [kTechDataMapName] = Welder.kMapName,
        [kTechDataDisplayName] = "WELDER",
        [kTechDataModel] = Welder.kModelName,
        [kTechDataDamageType] = kWelderDamageType,
        [kTechDataCostKey] = kWelderCost,
        [kTechDataPointValue] = kWelderPointValue,
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.Mine,
        [kTechDataMapName] = Mine.kMapName,
        [kTechDataHint] = "MINE_HINT",
        [kTechDataDisplayName] = "MINE_SINGULAR",
        [kTechDataEngagementDistance] = kMineDetonateRange,
        [kTechDataMaxHealth] = kMineHealth,
        [kTechDataTooltipInfo] = "MINE_TOOLTIP",
        [kTechDataMaxArmor] = kMineArmor,
        [kTechDataModel] = Mine.kModelName,
        [kTechDataPointValue] = kMinePointValue,
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.CombatBuilder,
        [kTechDataDisplayName] = "COMBATBUILDER",
        [kTechDataMapName] = CombatBuilder.kMapName,
        [kTechDataCostKey] = kCombatBuilderCost,
        [kTechDataMaxHealth] = kMarineWeaponHealth,
        [kTechDataPointValue] = kCombatBuilderPointValue,
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.DropCombatBuilder,
        [kTechDataMapName] = CombatBuilder.kMapName,
        [kTechDataDisplayName] = "COMBATBUILDER",
        [kTechDataTooltipInfo] = "COMBATBUILDER_TOOLTIP",
        [kTechDataModel] = CombatBuilder.kModelName,
        [kTechDataCostKey] = kCombatBuilderDropCost,
        [kStructureAttachId] = { kTechId.Armory, kTechId.AdvancedArmory },
        [kStructureAttachRange] = kArmoryWeaponAttachRange,
        [kStructureAttachRequiresPower] = true,
    } )

    table.insert(techData,{
        [kTechDataId] = kTechId.WeaponCache,
        [kTechDataDisplayName] = "WEAPON_CACHE",
        [kTechDataHint] = "WEAPON_CACHE_HINT",
        --[kTechDataTooltipInfo] = "WEAPONCACHE_TOOLIP",
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
        [kTechDataPersonalCostKey] = kWeaponCachePersonalCost,
        [kTechDataAllowConsumeDrop] = true,
    })

    table.insert(techData,  {
        [kTechDataId] = kTechId.SentryBattery,
        [kTechDataSupply] = kSentryBatterySupply,
        [kTechDataBuildRequiresMethod] = GetRoomHasNoSentryBattery,
        [kTechDataBuildMethodFailedMessage] = "COMMANDERERROR_ONLY_ONE_BATTERY_PER_ROOM",
        [kTechDataHint] = "SENTRY_BATTERY_HINT",
        [kTechDataGhostModelClass] = "MarineGhostModel",
        [kTechDataMapName] = SentryBattery.kMapName,
        [kTechDataDisplayName] = "SENTRY_BATTERY",
        [kTechDataCostKey] = kSentryBatteryCost,
        [kTechDataPointValue] = kSentryBatteryPointValue,
        [kTechDataModel] = SentryBattery.kModelName,
        [kTechDataEngagementDistance] = 2,
        [kTechDataBuildTime] = kSentryBatteryBuildTime,
        [kTechDataMaxHealth] = kSentryBatteryHealth,
        [kTechDataMaxArmor] = kSentryBatteryArmor,
        [kTechDataTooltipInfo] = "SENTRY_BATTERY_TOOLTIP",
        [kTechDataHotkey] = Move.S,
        [kTechDataNotOnInfestation] = kPreventMarineStructuresOnInfestation,
        [kVisualRange] = SentryBattery.kRange,
        [kTechDataObstacleRadius] = 0.55,
    })

    table.insert(techData,  {
        [kTechDataId] = kTechId.MarineSentry,
        [kTechDataMapName] = MarineSentry.kMapName,
        [kTechDataModel] = MarineSentry.kModelName,
        [kTechDataGhostModelClass] = "MarineGhostModel",
        [kTechDataHint] = "MARINE_SENTRY_HINT",
        [kTechDataDisplayName] = "MARINE_SENTRY",
        --[kTechDataTooltipInfo] = "MARINE_SENTRY_TOOLTIP",
        [kTechDataPointValue] = kMarineSentryPointValue,
        [kTechDataBuildTime] = kMarineSentryBuildTime,
        [kTechDataMaxHealth] = kMarineSentryHealth,
        [kTechDataMaxArmor] = kMarineSentryArmor,
        [kTechDataDamageType] = kSentryAttackDamageType,
        [kTechDataEngagementDistance] = kSentryEngagementDistance,
        [kTechDataObstacleRadius] = 0.25,
        [kTechDataAllowConsumeDrop] = true,
        [kTechDataCostKey] = kMarineSentryCost,
        [kTechDataPersonalCostKey] = kMarineSentryPersonalCost,
        [kTechDataAllowConsumeDrop] = true,
    })

    table.insert(techData,
            {
                [kTechDataId] = kTechId.BuildMenu,
                [kTechDataDisplayName] = "BUILD",
                [kTechDataHotkey] = Move.W,
                [kTechDataTooltipInfo] = "BUILD_TOOLTIP",
                [kTechDataAllowConsumeDrop] = true,
            })

    table.insert(techData,
            {
                [kTechDataId] = kTechId.AdvancedMenu,
                [kTechDataDisplayName] = "ADVANCED",
                [kTechDataHotkey] = Move.W,
                [kTechDataTooltipInfo] = "ADVANCED_TOOLTIP",
                [kTechDataAllowConsumeDrop] = true,
            })

    table.insert(techData,
            {
                [kTechDataId] = kTechId.ProtosMenu,
                [kTechDataDisplayName] = "PROTOS_MENU",
                [kTechDataTooltipInfo] = "PROTOS_MENU_TOOLTIP",
            })

    table.insert(techData,
            {
                [kTechDataId] = kTechId.JetpackProtoUpgrade,
                [kTechDataCostKey] = kJetpackTechResearchCost,
                [kTechDataResearchTimeKey] = kJetpackTechResearchTime,
                [kTechIDShowEnables] = false,
                [kTechDataDisplayName] = "JETPACK_PROTOTYPE_UPGRADE",
                [kTechDataTooltipInfo] = "JETPACK_PROTOTYPE_LAB_TOOLTIP",
                [kTechDataResearchName] = "JETPACK_PROTOTYPE_UPGRADE"
            })
    table.insert(techData,
            {
                [kTechDataId] = kTechId.ExosuitProtoUpgrade,
                [kTechDataCostKey] = kExosuitTechResearchCost,
                [kTechDataResearchTimeKey] = kExosuitTechResearchTime,
                [kTechIDShowEnables] = false,
                [kTechDataDisplayName] = "EXOSUIT_PROTOTYPE_UPGRADE",
                [kTechDataTooltipInfo] = "EXOSUIT_PROTOTYPE_LAB_TOOLTIP",
                [kTechDataResearchName] = "EXOSUIT_PROTOTYPE_UPGRADE"
            })

    table.insert(techData,
            {
                [kTechDataId] = kTechId.CannonProtoUpgrade,
                [kTechDataCostKey] = kCannonTechResearchCost,
                [kTechDataResearchTimeKey] = kCannonTechResearchTime,
                [kTechIDShowEnables] = false,
                [kTechDataDisplayName] = "CANNON_PROTOTYPE_UPGRADE",
                [kTechDataTooltipInfo] = "CANNON_PROTOTYPE_LAB_TOOLTIP",
                [kTechDataResearchName] = "CANNON_PROTOTYPE_UPGRADE"
            })
    table.insert(techData,{
        [kTechDataId] = kTechId.ExosuitPrototypeLab,
        [kTechDataGhostModelClass] = "MarineGhostModel",
        [kTechDataRequiresPower] = true,
        [kTechDataNotOnInfestation] = kPreventMarineStructuresOnInfestation,
        [kTechDataMapName] = ExosuitPrototypeLab.kMapName,
        [kTechDataCostKey] = kPrototypeLabCost + kExosuitTechResearchCost,
        [kTechDataMaxHealth] = kUpgradedPrototypeLabHealth,
        [kTechDataMaxArmor] = kUpgradedPrototypeLabArmor,
        [kTechDataPointValue] = kUpgradedPrototypeLabPointValue,
        [kTechDataDisplayName] = "EXOSUIT_PROTOTYPE_LAB",
        [kTechDataTooltipInfo] = "EXOSUIT_PROTOTYPE_LAB_TOOLTIP",
        [kTechDataHint] = "EXOSUIT_PROTOTYPE_LAB_HINT",
        [kTechDataObstacleRadius] = 0.65,
        [kTechDataUpgradeTech] = kTechId.PrototypeLab,
    } )

    table.insert(techData,{
        [kTechDataId] = kTechId.CannonPrototypeLab,
        [kTechDataGhostModelClass] = "MarineGhostModel",
        [kTechDataRequiresPower] = true,
        [kTechDataNotOnInfestation] = kPreventMarineStructuresOnInfestation,
        [kTechDataMapName] = CannonPrototypeLab.kMapName,
        [kTechDataCostKey] = kPrototypeLabCost + kCannonTechResearchCost,
        [kTechDataMaxHealth] = kUpgradedPrototypeLabHealth,
        [kTechDataMaxArmor] = kUpgradedPrototypeLabArmor,
        [kTechDataPointValue] = kUpgradedPrototypeLabPointValue,
        [kTechDataDisplayName] = "CANNON_PROTOTYPE_LAB",
        [kTechDataTooltipInfo] = "CANNON_PROTOTYPE_LAB_TOOLTIP",
        [kTechDataHint] = "CANNON_PROTOTYPE_LAB_HINT",
        [kTechDataObstacleRadius] = 0.65,
        [kTechDataUpgradeTech] = kTechId.PrototypeLab,
    } )

    table.insert(techData,{
        [kTechDataId] = kTechId.JetpackPrototypeLab,
        [kTechDataGhostModelClass] = "MarineGhostModel",
        [kTechDataRequiresPower] = true,
        [kTechDataNotOnInfestation] = kPreventMarineStructuresOnInfestation,
        [kTechDataMapName] = JetpackPrototypeLab.kMapName,
        [kTechDataCostKey] = kPrototypeLabCost + kJetpackTechResearchCost,
        [kTechDataMaxHealth] = kUpgradedPrototypeLabHealth,
        [kTechDataMaxArmor] = kUpgradedPrototypeLabArmor,
        [kTechDataPointValue] = kUpgradedPrototypeLabPointValue,
        [kTechDataDisplayName] = "JETPACK_PROTOTYPE_LAB",
        [kTechDataTooltipInfo] = "JETPACK_PROTOTYPE_LAB_TOOLTIP",
        [kTechDataHint] = "JETPACK_PROTOTYPE_LAB_HINT",
        [kTechDataObstacleRadius] = 0.65,
        [kTechDataUpgradeTech] = kTechId.PrototypeLab,
    } )

    table.insert(techData,{
        [kTechDataId] = kTechId.CannonTech,
        [kTechDataCostKey] = kCannonTechResearchCost,
        [kTechDataResearchTimeKey] = kCannonTechResearchTime,
        [kTechDataDisplayName] = "RESEARCH_CANNON",
        [kTechDataResearchName] = "RESEARCH_CANNON",
    } )


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
        [kTechDataId] = kTechId.DropCannon,
        [kTechDataMapName] = Cannon.kMapName,
        [kTechDataDisplayName] = "CANNON_DROP",
        [kTechDataTooltipInfo] = "CANNON_TOOLTIP",
        [kTechDataModel] = Cannon.kModelName,
        [kTechDataCostKey] = kCannonDropCost,
        [kStructureAttachId] = {kTechId.PrototypeLab,kTechId.CannonPrototypeLab,kTechId.JetpackPrototypeLab,kTechId.ExosuitPrototypeLab},
        [kStructureAttachRange] = kArmoryWeaponAttachRange,
        [kStructureAttachRequiresPower] = true,
    } )

    table.insert(techData, {
        [kTechDataId] = kTechId.DropDualMinigunExosuit,
        [kTechDataMapName] = Exosuit.kMapName,
        [kTechDataModel] = Exosuit.kModelName,
        [kTechDataDisplayName] = "DUAL_MINIGUN",
        [kTechDataTooltipInfo] = "DUAL_MINIGUN_TOOLTIP",
        [kTechDataLayoutKey] = "MinigunMinigun",
        [kTechDataCostKey] = kDualExosuitDropCost,
        [kStructureAttachId] = {kTechId.PrototypeLab,kTechId.CannonPrototypeLab,kTechId.JetpackPrototypeLab,kTechId.ExosuitPrototypeLab},
        [kStructureAttachRange] = kArmoryWeaponAttachRange,
        [kStructureAttachRequiresPower] = true,
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.DropDualRailgunExosuit,
        [kTechDataMapName] = Exosuit.kMapName,
        [kTechDataModel] = Exosuit.kModelName,
        [kTechDataDisplayName] = "DUAL_RAILGUN",
        [kTechDataTooltipInfo] = "DUAL_RAILGUN_TOOLTIP",
        [kTechDataLayoutKey] = "RailgunRailgun",
        [kTechDataCostKey] = kDualExosuitDropCost,
        [kStructureAttachId] = {kTechId.PrototypeLab,kTechId.CannonPrototypeLab,kTechId.JetpackPrototypeLab,kTechId.ExosuitPrototypeLab},
        [kStructureAttachRange] = kArmoryWeaponAttachRange,
        [kStructureAttachRequiresPower] = true,
    })


    table.insert(techData, {
        [kTechDataId] = kTechId.DropJetpack,
        [kTechDataMapName] = Jetpack.kMapName,
        [kTechDataDisplayName] = "JETPACK_DROP",
        [kTechIDShowEnables] = false,
        [kTechDataTooltipInfo] = "JETPACK_TOOLTIP",
        [kTechDataModel] = Jetpack.kModelName,
        [kTechDataCostKey] = kJetpackDropCost,
        [kStructureAttachId] = {kTechId.PrototypeLab,kTechId.CannonPrototypeLab,kTechId.JetpackPrototypeLab,kTechId.ExosuitPrototypeLab},
        [kStructureAttachRange] = kArmoryWeaponAttachRange,
        [kStructureAttachRequiresPower] = true,
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.Exosuit,
        [kTechDataDisplayName] = "EXOSUIT",
        [kTechDataMapName] = "exo",
        [kTechDataCostKey] = kExosuitCost,
        [kTechDataHotkey] = Move.E,
        [kTechDataTooltipInfo] = "EXOSUIT_TECH_TOOLTIP",
        [kTechDataSpawnHeightOffset] = kCommanderEquipmentDropSpawnHeight,
        [kTechDataPointValue] = kExosuitPointValue,
    })

    --table.insert(techData,  {
    --    [kTechDataId] = kTechId.Heavy,
    --    [kTechDataMapName] = Heavy.kMapName,
    --    [kTechDataDisplayName] = "HEAVY",
    --    [kTechDataModel] = Heavy.kModelName,
    --    [kTechDataCostKey] = kHeavyCost,
    --    [kTechDataSpawnHeightOffset] = kCommanderEquipmentDropSpawnHeight,
    --})
    --
    --table.insert(techData,  {
    --    [kTechDataId] = kTechId.HeavyMarine,
    --    [kTechDataDisplayName] = "HEAVYMARINE",
    --    [kTechDataMapName] = HeavyMarine.kMapName,
    --    [kTechDataModel] = MarineVariantMixin.kModelNames["male"]["green"],
    --    [kTechDataMaxHealth] = HeavyMarine.kHealth,
    --    [kTechDataEngagementDistance] = kPlayerEngagementDistance,
    --    [kTechDataPointValue] = kHeavyMarinePointValue,
    --})

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
        [kTechDataId] = kTechId.DropTeamStructureAbility,
        [kTechDataMapName] = DropTeamStructureAbility.kMapName,
        [kTechDataCategory] = kTechId.Gorge,
        [kTechDataDisplayName] = "DROP_TEAM_STRUCTURE",
        [kTechDataTooltipInfo] = "DROP_TEAM_STRUCTURE_TOOLTIP",
        [kTechDataResearchName] = "DROP_TEAM_STRUCTURE",
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.GorgeTunnel,
        [kTechDataDisplayName] = "TUNNEL_EXIT",
        [kTechDataHint] = "TUNNEL_ENTRANCE_HINT",
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
        [kTechDataPointValue] = kSporeMinePointValue,
        [kTechDataDisplayName] = "SPOREMINE",
        [kTechDataTooltipInfo] = "SPOREMINE_TOOLTIP",
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.BabblerEgg,
        --[kTechDataCategory] = kTechId.Gorge,
        [kTechDataAllowConsumeDrop] = true,
        [kTechDataMaxAmount] = kNumBabblerEggsPerGorge,
        [kTechDataCostKey] = kBabblerCost,
        [kTechDataBuildTime] = kBabblerEggBuildTime,
        [kTechDataMapName] = BabblerEgg.kMapName,
        [kTechDataDisplayName] = "BABBLER_MINE",
        [kTechDataModel] = BabblerEgg.kModelName,
        [kTechDataMaxHealth] = kBabblerEggHealth,
        [kTechDataMaxArmor] = kBabblerEggArmor,
        [kTechDataPointValue] = kBabblerEggPointValue,
        [kTechDataTooltipInfo] = "BABBLER_MINE_TOOLTIP",
        [kVisualRange] = kBabblerEggHatchRadius,
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.Web,
        [kTechDataMapName] = Web.kMapName,
        --[kTechDataCategory] = kTechId.Gorge,
        [kTechDataMaxHealth] = kWebHealth,
        [kTechDataModel] = Web.kRootModelName,
        [kTechDataSpecifyOrientation] = true,
        [kTechDataGhostModelClass] = "WebGhostModel",
        [kTechDataMaxAmount] = kNumWebsPerGorge,
        [kTechDataAllowConsumeDrop] = true,
        [kTechDataDisplayName] = "WEB",
        [kTechDataCostKey] = kWebBuildCost,
        [kTechDataTooltipInfo] = "WEB_TOOLTIP",
    })


    table.insert(techData,{
        [kTechDataId] = kTechId.CragHive,
        [kTechDataHint] = "CRAG_HIVE_HINT",
        [kTechDataMapName] = CragHive.kMapName,
        [kTechDataDisplayName] = "CRAG_HIVE",
        [kTechDataCostKey] = kHiveCost,
        [kTechDataResearchTimeKey] = kUpgradeHiveResearchTime,
        [kTechDataBuildTime] = kGorgeHiveBuildTime,
        [kTechDataModel] = Hive.kModelName,
        [kTechDataHotkey] = Move.V,
        [kTechDataMaxHealth] = kHiveHealth,
        [kTechDataMaxArmor] = kHiveArmor,
        [kStructureAttachClass] = "TechPoint",
        [kTechDataSpawnHeightOffset] = 2.494,
        [kTechDataInitialEnergy] = kHiveInitialEnergy,
        [kTechDataMaxEnergy] = kHiveMaxEnergy,
        [kTechDataPointValue] = kHivePointValue,
        [kTechDataTooltipInfo] = "CRAG_HIVE_TOOLTIP",
        [kTechDataObstacleRadius] = 2.35,
        [kTechDataAllowConsumeDrop] = true,
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.ShadeHive,
        [kTechDataHint] = "SHADE_HIVE_HINT",
        [kTechDataMapName] = ShadeHive.kMapName,
        [kTechDataDisplayName] = "SHADE_HIVE",
        [kTechDataCostKey] = kHiveCost,
        [kTechDataResearchTimeKey] = kUpgradeHiveResearchTime,
        [kTechDataBuildTime] = kGorgeHiveBuildTime,
        [kTechDataModel] = Hive.kModelName,
        [kTechDataHotkey] = Move.V,
        [kTechDataMaxHealth] = kHiveHealth,
        [kTechDataMaxArmor] = kHiveArmor,
        [kStructureAttachClass] = "TechPoint",
        [kTechDataSpawnHeightOffset] = 2.494,
        [kTechDataInitialEnergy] = kHiveInitialEnergy,
        [kTechDataMaxEnergy] = kHiveMaxEnergy,
        [kTechDataPointValue] = kHivePointValue,
        [kTechDataTooltipInfo] = "SHADE_HIVE_TOOLTIP",
        [kTechDataObstacleRadius] = 2.35,
        [kTechDataAllowConsumeDrop] = true,
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.ShiftHive,
        [kTechDataHint] = "SHIFT_HIVE_HINT",
        [kTechDataMapName] = ShiftHive.kMapName,
        [kTechDataDisplayName] = "SHIFT_HIVE",
        [kTechDataCostKey] = kHiveCost,
        [kTechDataResearchTimeKey] = kUpgradeHiveResearchTime,
        [kTechDataBuildTime] = kGorgeHiveBuildTime,
        [kTechDataModel] = Hive.kModelName,
        [kTechDataHotkey] = Move.V,
        [kTechDataMaxHealth] = kHiveHealth,
        [kTechDataMaxArmor] = kHiveArmor,
        [kStructureAttachClass] = "TechPoint",
        [kTechDataSpawnHeightOffset] = 2.494,
        [kTechDataInitialEnergy] = kHiveInitialEnergy,
        [kTechDataMaxEnergy] = kHiveMaxEnergy,
        [kTechDataPointValue] = kHivePointValue,
        [kTechDataTooltipInfo] = "SHIFT_HIVE_TOOLTIP",
        [kTechDataObstacleRadius] = 2.35,
        [kTechDataAllowConsumeDrop] = true,
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.Harvester,
        [kTechDataIgnorePathingMesh] = true,
        [kTechDataBioMass] = kHarvesterBiomass,
        [kTechDataSpawnBlock] = true,
        [kTechDataMaxExtents] = Vector(1, 1, 1),
        [kTechDataHint] = "HARVESTER_HINT",
        [kTechDataCollideWithWorldOnly] = true,
        [kTechDataAllowStacking] = true,
        [kTechDataGhostModelClass] = "AlienGhostModel",
        [kTechDataMapName] = Harvester.kMapName,
        [kTechDataDisplayName] = "HARVESTER",
        [kTechDataRequiresInfestation] = true,
        [kTechDataCostKey] = kHarvesterCost,
        [kTechDataBuildTime] = kHarvesterBuildTime,
        [kTechDataHotkey] = Move.H,
        [kTechDataMaxHealth] = kHarvesterHealth,
        [kTechDataMaxArmor] = kHarvesterArmor,
        [kTechDataModel] = Harvester.kModelName,
        [kStructureAttachClass] = "ResourcePoint",
        [kTechDataPointValue] = kHarvesterPointValue,
        [kTechDataTooltipInfo] = "HARVESTER_TOOLTIP",
        [kTechDataObstacleRadius] = 1.3,
        [kTechDataAllowConsumeDrop] = true,
    })
    
    --Skulk
    table.insert(techData, {
        [kTechDataId] = kTechId.XenocideFuel,
        [kTechDataCostKey] = kXenocideFuelCost,
        [kTechDataResearchTimeKey] = kXenocideFuelTime,
        [kTechDataDisplayName] = "XENOCIDE_FUEL",
        [kTechDataTooltipInfo] = "XENOCIDE_FUEL_TOOLTIP",
        [kTechDataResearchName] = "XENOCIDE_FUEL",
    })
    
    --Lerk

    table.insert(techData, {
        [kTechDataId] = kTechId.Spores,
        --[kTechDataCategory] = kTechId.Lerk,
        [kTechDataDisplayName] = "SPORES",
        [kTechDataMapName] = Spores.kMapName,
        [kTechDataCostKey] = kSporesResearchCost,
        [kTechDataResearchTimeKey] = kSporesResearchTime,
        [kTechDataMaxHealth] = kSporeCloudHealth,
        [kTechDataPointValue] = kSporeCloudPointValue,
        [kTechDataTooltipInfo] = "SPORES_TOOLTIP",
        [kTechDataResearchName] = "SPORES",
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
        [kTechDataDisplayName] = "ACIDSPRAY",
        [kTechDataCostKey] = kAcidSprayResearchCost,
        [kTechDataResearchTimeKey] = kAcidSprayResearchTime,
        [kTechDataTooltipInfo] = "ACIDSPRAY_TOOLTIP"
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
        [kTechDataMaxHealth] = Prowler.kHealth,
        [kTechDataMaxArmor] = Prowler.kArmor,
        [kTechDataRequiresMature] = true,
        [kTechDataDisplayName] = "HALLUCINATE_PROWLER",
        [kTechDataTooltipInfo] = "HALLUCINATE_PROWLER_TOOLTIP",
    })
    --Vokex
    table.insert(techData, {
        [kTechDataId] = kTechId.VokexMenu,
        [kTechDataDisplayName] = "UPGRADE_VOKEX",
        [kTechDataTooltipInfo] = "UPGRADE_VOKEX_TOOLTIP",
    })
    table.insert(techData,  {
        [kTechDataId] = kTechId.Vokex,
        [kTechDataUpgradeCost] = kVokexUpgradeCost,
        [kTechDataMapName] = Vokex.kMapName,
        [kTechDataGestateName] = Vokex.kMapName,
        [kTechDataGestateTime] = kVokexGestateTime,
        [kTechDataDisplayName] = "VOKEX",
        [kTechDataTooltipInfo] = "VOKEX_TOOLTIP",
        [kTechDataModel] = Vokex.kModelName,
        [kTechDataCostKey] = kVokexCost,
        [kTechDataMaxHealth] = Vokex.kHealth,
        [kTechDataMaxArmor] = Vokex.kArmor,
        [kTechDataMaxExtents] = Vector(Vokex.XZExtents, Vokex.YExtents, Vokex.XZExtents),
        [kTechDataPointValue] = kVokexPointValue,
        [kTechDataEngagementDistance] = kPlayerEngagementDistance,
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.ShadowStep,
        [kTechDataCategory] = kTechId.Vokex,
        [kTechDataCostKey] = kShadowStepResearchCost,
        [kTechDataResearchTimeKey] = kShadowStepResearchTime,
        [kTechDataDisplayName] = "SHADOWSTEP",
        [kTechDataTooltipInfo] = "SHADOWSTEP_TOOLTIP",
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.SwipeShadowStep,
        [kTechDataMapName] = SwipeShadowStep.kMapName,
        [kTechDataDamageType] = kSwipeDamageType,
        [kTechDataDisplayName] = "SWIPE_SHADOWSTEP",
        [kTechDataTooltipInfo] = "SWIPE_SHADOWSTEP_TOOLTIP",
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.MetabolizeShadowStep,
        [kTechDataMapName] = MetabolizeShadowStep.kMapName,
        [kTechDataDisplayName] = "METABOLIZE_SHADOWSTEP",
        [kTechDataTooltipInfo] = "METABOLIZE_SHADOWSTEP_TOOLTIP",
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.AcidRocket,
        [kTechDataCategory] = kTechId.Vokex,
        [kTechDataMapName] = AcidRocket.kMapName,
        [kTechDataCostKey] = kAcidRocketResearchCost,
        [kTechDataResearchTimeKey] = kAcidRocketResearchTime,
        [kTechDataDisplayName] = "ACIDROCKET",
        [kTechDataTooltipInfo] = "ACIDROCKET_TOOLTIP",
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.HallucinateVokex,
        [kTechDataMapName] = Fade.kMapName,
        [kTechDataModel] = Vokex.kModelName,
        [kTechDataCostKey] = kVokexCost,
        [kTechDataMaxHealth] = Vokex.kHealth,
        [kTechDataMaxArmor] = Vokex.kArmor,
        [kTechDataRequiresMature] = true,
        [kTechDataDisplayName] = "HALLUCINATE_VOKEX",
        [kTechDataTooltipInfo] = "HALLUCINATE_VOKEX_TOOLTIP",
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

    table.insert(techData, {
        [kTechDataId] = kTechId.OriginForm,
        [kTechDataCostKey] = kOriginFormResearchCost,
        [kTechDataResearchTimeKey] = kOriginFormResearchTime,
        [kTechDataDisplayName] = "ORIGIN_FORM",
        [kTechDataTooltipInfo] = "ORIGIN_FORM_TOOLTIP",
        [kTechDataResearchName] = "ORIGIN_FORM",
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.OriginFormPassive,
        [kTechDataDisplayName] = "ORIGIN_FORM_PASSIVE",
        [kTechDataTooltipInfo] = "ORIGIN_FORM_TOOLTIP_PASSIVE",
        [kTechDataResearchName] = "ORIGIN_FORM_PASSIVE",
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.OriginFormResourceFetch,
        [kTechDataCategory] = kTechId.OriginForm,
        [kTechDataDisplayName] = "ORIGIN_FORM_RESOURCE_FETCH",
        [kTechDataTooltipInfo] = "ORIGIN_FORM_RESOURCE_FETCH_TOOLTIP",
    })
    
    --Tunnels
    table.insert(techData, {
        [kTechDataId] = kTechId.ShiftTunnel,
        [kTechDataCostKey] = kShiftTunnelUpgradeCost,
        [kTechDataResearchTimeKey] = kTunnelUpgradeTime,
        [kTechDataDisplayName] = "SHIFT_TUNNEL",
        [kTechDataTooltipInfo] = "SHIFT_TUNNEL_TOOLTIP",
        [kTechDataResearchName] = "SHIFT_TUNNEL",
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.CragTunnel,
        [kTechDataCostKey] = kCragTunnelUpgradeCost,
        [kTechDataResearchTimeKey] = kTunnelUpgradeTime,
        [kTechDataDisplayName] = "CRAG_TUNNEL",
        [kTechDataTooltipInfo] = "CRAG_TUNNEL_TOOLTIP",
        [kTechDataResearchName] = "CRAG_TUNNEL",
    })
    
    table.insert(techData, {
        [kTechDataId] = kTechId.ShadeTunnel,
        [kTechDataCostKey] = kShadeTunnelUpgradeCost,
        [kTechDataResearchTimeKey] = kTunnelUpgradeTime,
        [kTechDataDisplayName] = "SHADE_TUNNEL",
        [kTechDataTooltipInfo] = "SHADE_TUNNEL_TOOLTIP",
        [kTechDataResearchName] = "SHADE_TUNNEL",
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.ShiftHiveBiomassPreserve,
        [kTechDataDisplayName] = "BIOMASS_PRESERVATION",
        [kTechDataTooltipInfo] = "BIOMASS_PRESERVATION_TOOLTIP",
        [kTechIDShowEnables] = false,
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.ShadeHiveBiomassPreserve,
        [kTechDataDisplayName] = "BIOMASS_PRESERVATION",
        [kTechDataTooltipInfo] = "BIOMASS_PRESERVATION_TOOLTIP",
        [kTechIDShowEnables] = false,
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.CragHiveBiomassPreserve,
        [kTechDataDisplayName] = "BIOMASS_PRESERVATION",
        [kTechDataTooltipInfo] = "BIOMASS_PRESERVATION_TOOLTIP",
        [kTechIDShowEnables] = false,
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.RecoverBiomassOne,
        [kTechDataCostKey] = kRecoverBioMassOneCost,
        [kTechDataResearchTimeKey] = kRecoverBioMassOneTime,
        [kTechDataDisplayName] = "BIOMASS_RECOVER",
        [kTechDataTooltipInfo] = "BIOMASS_RECOVER_TOOLTIP",
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.RecoverBiomassTwo,
        [kTechDataCostKey] = kRecoverBioMassTwoCost,
        [kTechDataResearchTimeKey] = kRecoverBioMassTwoTime,
        [kTechDataDisplayName] = "BIOMASS_RECOVER",
        [kTechDataTooltipInfo] = "BIOMASS_RECOVER_TOOLTIP",
    })
    table.insert(techData, {
        [kTechDataId] = kTechId.RecoverBiomassThree,
        [kTechDataCostKey] = kRecoverBioMassThreeCost,
        [kTechDataResearchTimeKey] = kRecoverBioMassThreeTime,
        [kTechDataDisplayName] = "BIOMASS_RECOVER",
        [kTechDataTooltipInfo] = "BIOMASS_RECOVER_TOOLTIP",
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

    table.insert(techData, {
        [kTechDataId] = kTechId.Tunnel,
        [kTechDataMaxExtents] = Vector(1.2, 1.2, 1.2),
        [kTechDataTooltipInfo] = "TUNNEL_TOOLTIP",
        [kTechDataGhostModelClass] = "AlienGhostModel",
        [kTechDataMapName] = TunnelEntrance.kMapName,
        [kTechDataDisplayName] = "TUNNEL_ENTRANCE",
        [kTechDataHint] = "TUNNEL_ENTRANCE_HINT",
        [kTechDataCostKey] = kTunnelEntranceCost,
        [kTechDataMaxHealth] = kTunnelEntranceHealth,
        [kTechDataMaxArmor] = kTunnelEntranceArmor,
        [kTechDataBuildTime] = kTunnelBuildTime,
        [kTechDataModel] = TunnelEntrance.kModelName,
        [kTechDataRequiresInfestation] = true,
        [kTechDataPointValue] = kTunnelEntrancePointValue,
        [kTechDataObstacleRadius] = 1.25,
        [kTechDataAllowConsumeDrop] = true,
    })
    
    table.insert(techData, {
        [kTechDataId] = kTechId.TunnelExit,
        [kTechDataMaxExtents] = Vector(1.1,1.4,1.1),
        [kTechDataTooltipInfo] = "TUNNEL_EXIT_TOOLTIP",
        [kTechDataGhostModelClass] = "AlienGhostModel",
        [kTechDataMapName] = TunnelEntrance.kMapName,
        [kTechDataDisplayName] = "TUNNEL_EXIT",
        [kTechDataHint] = "TUNNEL_EXIT_HINT",
        [kTechDataCostKey] = kTunnelExitCost,
        [kTechDataMaxHealth] = kTunnelEntranceHealth,
        [kTechDataMaxArmor] = kTunnelEntranceArmor,
        [kTechDataBuildTime] = kTunnelBuildTime,
        [kTechDataModel] = TunnelEntrance.kModelName,
        [kTechDataPointValue] = kTunnelEntrancePointValue,
        [kTechDataObstacleRadius] = 1.25,
        [kTechDataAllowConsumeDrop] = true,
        [kTechDataAllowConsumeDrop] = true,
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.TunnelRelocate,
        [kTechDataMaxExtents] = Vector(0.6,0.6,0.6),
        [kTechDataTooltipInfo] = "TUNNEL_RELOCATE_TOOLTIP",
        [kTechDataGhostModelClass] = "AlienGhostModel",
        [kTechDataMapName] = TunnelEntrance.kMapName,
        [kTechDataDisplayName] = "TUNNEL_ENTRANCE",
        [kTechDataHint] = "TUNNEL_ENTRANCE_HINT",
        [kTechDataCostKey] = kTunnelRelocateCost,
        [kTechDataMaxHealth] = kTunnelEntranceHealth,
        [kTechDataMaxArmor] = kTunnelEntranceArmor,
        [kTechDataBuildTime] = kTunnelBuildTime,
        [kTechDataModel] = TunnelEntrance.kModelName,
        [kTechDataPointValue] = kTunnelEntrancePointValue,
        [kTechDataAllowConsumeDrop] = true,
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.Cyst,
        [kTechDataSpawnBlock] = true,
        [kTechDataBuildMethodFailedMessage] = "COMMANDERERROR_NO_CYST_PARENT_FOUND",
        [kTechDataOverrideCoordsMethod] = AlignCyst,
        [kTechDataHint] = "CYST_HINT",
        [kTechDataCooldown] = kCystCooldown,
        [kTechDataGhostModelClass] = "CystGhostModel",
        [kTechDataMapName] = Cyst.kMapName,
        [kTechDataDisplayName] = "CYST",
        [kTechDataTooltipInfo] = "CYST_TOOLTIP",
        [kTechDataCostKey] = kCystCost,
        [kTechDataBuildTime] = kCystBuildTime,
        [kTechDataMaxHealth] = kCystHealth,
        [kTechDataMaxArmor] = kCystArmor,
        [kTechDataModel] = Cyst.kModelName,
        [kVisualRange] = kInfestationRadius,
        [kTechDataRequiresInfestation] = false,
        [kTechDataPointValue] = kCystPointValue,
        [kTechDataGrows] = false,
        [kTechDataBuildRequiresMethod] = GetCystParentAvailable,
        [kTechDataAllowStacking] = true,
    })
    
    table.insert(techData,{
        [kTechDataId] = kTechId.Egg,
        [kTechDataHint] = "EGG_HINT",
        [kTechDataMapName] = Egg.kMapName,
        [kTechDataDisplayName] = "EGG",
        [kTechDataTooltipInfo] = "EGG_DROP_TOOLTIP",
        [kTechDataMaxHealth] = Egg.kHealth,
        [kTechDataMaxArmor] = Egg.kArmor,
        [kTechDataModel] = Egg.kModelName,
        [kTechDataPointValue] = kEggPointValue,
        [kTechDataBuildTime] = 1,
        [kTechDataMaxExtents] = Vector(1.75/2, 1, 1.75/2),
        [kTechDataRequiresInfestation] = true,
        [kTechDataAllowConsumeDrop] = true,
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.Whip,
        [kTechDataBioMass] = kWhipBiomass,
        [kTechDataSupply] = kWhipSupply,
        [kTechDataHint] = "WHIP_HINT",
        [kTechDataGhostModelClass] = "AlienGhostModel",
        [kTechDataMapName] = Whip.kMapName,
        [kTechDataDisplayName] = "WHIP",
        [kTechDataCostKey] = kWhipCost,
        [kTechDataRequiresInfestation] = true,
        [kTechDataHotkey] = Move.W,
        [kTechDataBuildTime] = kWhipBuildTime,
        [kTechDataModel] = Whip.kModelName,
        [kTechDataMaxHealth] = kWhipHealth,
        [kTechDataMaxArmor] = kWhipArmor,
        [kTechDataDamageType] = kDamageType.Structural,
        [kTechDataInitialEnergy] = kWhipInitialEnergy,
        [kTechDataMaxEnergy] = kWhipMaxEnergy,
        [kVisualRange] = Whip.kRange,
        [kTechDataPointValue] = kWhipPointValue,
        [kTechDataTooltipInfo] = "WHIP_TOOLTIP",
        [kTechDataGrows] = true,
        [kTechDataObstacleRadius] = 0.85,
        [kTechDataAllowConsumeDrop] = true,
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.GorgeShiftGhostModelOverride,
        [kTechDataGhostModelClass] = "AlienGhostModel",
        [kTechDataMapName] = Shift.kMapName,
        [kTechDataModel] = Shift.kModelName,
    })
    table.insert(techData,{
        [kTechDataId] = kTechId.GorgeCystGhostModelOverride,
        [kTechDataGhostModelClass] = "AlienGhostModel",
        [kTechDataMapName] = Cyst.kMapName,
        [kTechDataModel] = Cyst.kModelName,
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.Shift,
        [kTechDataBioMass] = kShiftBiomass,
        [kTechDataSupply] = kShiftSupply,
        [kTechDataHint] = "SHIFT_HINT",
        [kTechDataGhostModelClass] = "ShiftGhostModel",
        [kTechDataMapName] = Shift.kMapName,
        [kTechDataDisplayName] = "SHIFT",
        [kTechDataRequiresInfestation] = true,
        [kTechDataCostKey] = kShiftCost,
        [kTechDataHotkey] = Move.S,
        [kTechDataBuildTime] = kShiftBuildTime,
        [kTechDataModel] = Shift.kModelName,
        [kTechDataMaxHealth] = kShiftHealth,
        [kTechDataMaxArmor] = kShiftArmor,
        [kTechDataInitialEnergy] = kShiftInitialEnergy,
        [kTechDataMaxEnergy] = kShiftMaxEnergy,
        [kTechDataPointValue] = kShiftPointValue,
        [kVisualRange] = {
        kEchoRange,
        kEnergizeRange
        },
        [kTechDataTooltipInfo] = "SHIFT_TOOLTIP",
        [kTechDataGrows] = true,
        [kTechDataObstacleRadius] = 1.3,
        [kTechDataAllowConsumeDrop] = true,
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.Shade,
        [kTechDataBioMass] = kShadeBiomass,
        [kTechDataSupply] = kShadeSupply,
        [kTechDataHint] = "SHADE_HINT",
        [kTechDataGhostModelClass] = "AlienGhostModel",
        [kTechDataMapName] = Shade.kMapName,
        [kTechDataDisplayName] = "SHADE",
        [kTechDataCostKey] = kShadeCost,
        [kTechDataRequiresInfestation] = true,
        [kTechDataBuildTime] = kShadeBuildTime,
        [kTechDataHotkey] = Move.D,
        [kTechDataModel] = Shade.kModelName,
        [kTechDataMaxHealth] = kShadeHealth,
        [kTechDataMaxArmor] = kShadeArmor,
        [kTechDataInitialEnergy] = kShadeInitialEnergy,
        [kTechDataMaxEnergy] = kShadeMaxEnergy,
        [kTechDataPointValue] = kShadePointValue,
        [kVisualRange] = Shade.kCloakRadius,
        [kTechDataMaxExtents] = Vector(.5, 1.3, .5),
        [kTechDataTooltipInfo] = "SHADE_TOOLTIP",
        [kTechDataGrows] = true,
        [kTechDataObstacleRadius] = 1.25,
        [kTechDataAllowConsumeDrop] = true,
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.Crag,
        [kTechDataBioMass] = kCragBiomass,
        [kTechDataSupply] = kCragSupply,
        [kTechDataHint] = "CRAG_HINT",
        [kTechDataGhostModelClass] = "AlienGhostModel",
        [kTechDataMapName] = Crag.kMapName,
        [kTechDataDisplayName] = "CRAG",
        [kTechDataCostKey] = kCragCost,
        [kTechDataRequiresInfestation] = true,
        [kTechDataHotkey] = Move.C,
        [kTechDataBuildTime] = kCragBuildTime,
        [kTechDataModel] = Crag.kModelName,
        [kTechDataMaxHealth] = kCragHealth,
        [kTechDataMaxArmor] = kCragArmor,
        [kTechDataInitialEnergy] = kCragInitialEnergy,
        [kTechDataMaxEnergy] = kCragMaxEnergy,
        [kTechDataPointValue] = kCragPointValue,
        [kVisualRange] = Crag.kHealRadius,
        [kTechDataTooltipInfo] = "CRAG_TOOLTIP",
        [kTechDataGrows] = true,
        [kTechDataObstacleRadius] = 1.15,
        [kTechDataAllowConsumeDrop] = true,
    })

    --Drifer abilities
    --table.insert(techData,{
    --    [kTechDataId] = kTechId.ShadeInk,
    --    [kTechDataCooldown] = kShadeInkCooldown,
    --    [kTechDataDisplayName] = "INK",
    --    [kTechDataHotkey] = Move.C,
    --    [kTechDataCostKey] = kShadeInkCost,
    --    [kTechDataTooltipInfo] = "SHADE_INK_TOOLTIP",
    --    --[kTechDataOneAtATime] = true,
    --    [kVisualRange] = ShadeInk.kShadeInkDisorientRadius,
    --    [kTechDataGhostModelClass] = "AlienGhostModel",
    --    [kTechDataIgnorePathingMesh] = true,
    --    [kTechDataAllowStacking] = true,
    --    [kTechDataModel] = BoneWall.kModelName,
    --    [kTechDataMapName] = ShadeInk.kMapName,
    --})
    
    --Marker
    table.insert(techData,{
        [kTechDataId] = kTechId.ExpandingMarker,
        [kTechDataImplemented] = true,
        [kTechDataDisplayName] = "EXPANDING_HERE",
        [kTechDataTooltipInfo] = "PHEROMONE_EXPANDING_TOOLTIP",
        [kTechDataCostKey] = kMarkerCost,
        [kTechDataCooldown] = kMarkerCooldown,
    })

    table.insert(techData,{
        [kTechDataId] = kTechId.ThreatMarker,
        [kTechDataImplemented] = true,
        [kTechDataDisplayName] = "MARK_THREAT",
        [kTechDataTooltipInfo] = "PHEROMONE_THREAT_TOOLTIP",
        [kVisualRange] = kRallyRadius,
        [kTechDataCostKey] = kRallyCost,
        [kTechDataCooldown] = kRallyCooldown,
    })

    return techData
end