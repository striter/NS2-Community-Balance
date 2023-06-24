
kTechDataPlayersRestrictionKey = "playersrestrictionkey"
kTechDataPersonalCostKey = "costpersonalkey"
kTechDataLayoutKey     = "layoutKey"
kTechDataPersonalResOnKillKey = "pResOnKillKey"
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
        [kTechDataTooltipInfo] = "STANDARD_STATION_TOOLTIP",
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
        [kTechDataTooltipInfo] = "ARMOR_STATION_TOOLTIP",
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
        [kStructureAttachClass] = "TechPoint",
        [kTechDataGhostModelClass] = "MarineGhostModel",
        [kTechDataCostKey] = kUpgradedCommandStationCost,
        [kTechDataEngagementDistance] = kCommandStationEngagementDistance,
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
        [kTechDataTooltipInfo] = "RESEARCH_CANNON_TOOLTIP",
        [kTechDataResearchName] = "RESEARCH_CANNON",
    } )

    table.insert(techData,{
        [kTechDataId] = kTechId.DropCannon,
        [kTechDataMapName] = Cannon.kMapName,
        [kTechDataDisplayName] = "CANNON_DROP",
        [kTechDataTooltipInfo] = "CANNON_TOOLTIP",
        [kTechDataModel] = Cannon.kModelName,
        [kTechDataCostKey] = kCannonDropCost,
        [kStructureAttachId] = { kTechId.AdvancedArmory },
        [kStructureAttachRange] = kArmoryWeaponAttachRange,
        [kStructureAttachRequiresPower] = true,
    } )

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
        [kTechDataId] = kTechId.ProtosMenu,
        [kTechDataDisplayName] = "PROTOS_MENU",
        [kTechDataTooltipInfo] = "PROTOS_MENU_TOOLTIP",
    })

    table.insert(techData,
    {
        [kTechDataId] = kTechId.DropDualMinigunExosuit,
        [kTechDataMapName] = Exosuit.kMapName,
        [kTechDataModel] = Exosuit.kModelName,
        [kTechDataDisplayName] = "DUAL_MINIGUN",
        [kTechDataTooltipInfo] = "DUAL_MINIGUN_TOOLTIP",
        [kTechDataLayoutKey] = "MinigunMinigun",
        [kTechDataCostKey] = kDualExosuitDropCost,
        [kStructureAttachId] = kTechId.PrototypeLab,
        [kStructureAttachRange] = kArmoryWeaponAttachRange,
        [kStructureAttachRequiresPower] = true,
    })

    table.insert(techData,
    {
        [kTechDataId] = kTechId.DropDualRailgunExosuit,
        [kTechDataMapName] = Exosuit.kMapName,
        [kTechDataModel] = Exosuit.kModelName,
        [kTechDataDisplayName] = "DUAL_RAILGUN",
        [kTechDataTooltipInfo] = "DUAL_RAILGUN_TOOLTIP",
        [kTechDataLayoutKey] = "RailgunRailgun",
        [kTechDataCostKey] = kDualExosuitDropCost,
        [kStructureAttachId] = kTechId.PrototypeLab,
        [kStructureAttachRange] = kArmoryWeaponAttachRange,
        [kStructureAttachRequiresPower] = true,
    })

    table.insert(techData,  {
        [kTechDataId] = kTechId.Heavy,
        [kTechDataMapName] = Heavy.kMapName,
        [kTechDataDisplayName] = "HEAVY",
        [kTechDataModel] = Heavy.kModelName,
        [kTechDataCostKey] = kHeavyCost,
        [kTechDataSpawnHeightOffset] = kCommanderEquipmentDropSpawnHeight,
    })

    table.insert(techData,  {
        [kTechDataId] = kTechId.HeavyMarine,
        [kTechDataDisplayName] = "HEAVYMARINE",
        [kTechDataMapName] = HeavyMarine.kMapName,
        [kTechDataModel] = MarineVariantMixin.kModelNames["male"]["green"],
        [kTechDataMaxHealth] = HeavyMarine.kHealth,
        [kTechDataEngagementDistance] = kPlayerEngagementDistance,
        [kTechDataPointValue] = kHeavyMarinePointValue,
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
    --Skulk
    table.insert(techData, {
        [kTechDataId] = kTechId.XenocideFuel,
        [kTechDataCostKey] = kXenocideFuelCost,
        [kTechDataResearchTimeKey] = kXenocideFuelTime,
        [kTechDataDisplayName] = "XENOCIDE_FUEL",
        [kTechDataTooltipInfo] = "XENOCIDE_FUEL_TOOLTIP",
        [kTechDataResearchName] = "XENOCIDE_FUEL",
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
        [kTechDataId] = kTechId.MetabolizeShadowStep,
        [kTechDataCategory] = kTechId.Vokex,
        [kTechDataMapName] = MetabolizeShadowStep.kMapName,
        [kTechDataCostKey] = kMetabolizeEnergyResearchCost,
        [kTechDataResearchTimeKey] = kMetabolizeEnergyResearchTime,
        [kTechDataDisplayName] = "METABOLIZE",
        [kTechDataTooltipInfo] = "METABOLIZE_TOOLTIP",
        [kTechDataResearchName] = "METABOLIZE",
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


    --Tunnels
    table.insert(techData, {
        [kTechDataId] = kTechId.ShiftTunnel,
        [kTechDataCostKey] = kTunnelUpgradeCost,
        [kTechDataResearchTimeKey] = kTunnelUpgradeTime,
        [kTechDataDisplayName] = "SHIFT_TUNNEL",
        [kTechDataTooltipInfo] = "SHIFT_TUNNEL_TOOLTIP",
        [kTechDataResearchName] = "SHIFT_TUNNEL",
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.CragTunnel,
        [kTechDataCostKey] = kTunnelUpgradeCost,
        [kTechDataResearchTimeKey] = kTunnelUpgradeTime,
        [kTechDataDisplayName] = "CRAG_TUNNEL",
        [kTechDataTooltipInfo] = "CRAG_TUNNEL_TOOLTIP",
        [kTechDataResearchName] = "CRAG_TUNNEL",
    })
    
    table.insert(techData, {
        [kTechDataId] = kTechId.ShadeTunnel,
        [kTechDataCostKey] = kTunnelUpgradeCost,
        [kTechDataResearchTimeKey] = kTunnelUpgradeTime,
        [kTechDataDisplayName] = "SHADE_TUNNEL",
        [kTechDataTooltipInfo] = "SHADE_TUNNEL_TOOLTIP",
        [kTechDataResearchName] = "SHADE_TUNNEL",
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
        [kTechDataId] = kTechId.TunnelExit,
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
        [kTechDataObstacleRadius] = 1.25,
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
        [kTechDataTooltipInfo] = "POWERED_EXTRACTOR_TOOLTIP",
        [kTechDataHint] = "POWERED_EXTRACTOR_HINT",
        [kTechDataObstacleRadius] = 1.35,
        [kTechDataMaxHealth] = kPoweredExtractorHealth,
        [kTechDataMaxArmor] = kPoweredExtractorArmor,
        [kTechDataPointValue] = kPoweredExtractorPointValue,
        [kTechDataCostKey] = kPoweredExtractorCost,
    })

    return techData
end