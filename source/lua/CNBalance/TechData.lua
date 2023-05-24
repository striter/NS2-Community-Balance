
kTechDataPlayersRestrictionKey = "playersrestrictionkey"
kTechDataPersonalCostKey = "costpersonalkey"
kTechDataLayoutKey     = "layoutKey"
kTechDataPersonalResOnKillKey = "pResOnKillKey"
kTechDataTeamResOnKillKey = "tResOnKillKey"

local oldBuildTechData = BuildTechData
function BuildTechData()

    local techData = oldBuildTechData()

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
        [kTechDataMapName] = StandardStation.kMapName,
        [kTechDataModel] = CommandStation.kModelName,
        [kTechDataMaxHealth] = kCommandStationHealth,
        [kTechDataMaxArmor] = kCommandStationArmor,
        [kTechDataHint] = "STANDARD_STATION_HINT",
        [kTechDataDisplayName] = "STANDARD_STATION",
        [kTechDataTooltipInfo] = "STANDARD_STATION_TOOLTIP",
        [kStructureAttachClass] = "TechPoint",
        [kTechDataPersonalResOnKillKey] = kCommandStationPersonalResOnKill,
        [kTechDataTeamResOnKillKey] = kCommandStationTeamResOnKill,
        [kTechDataGhostModelClass] = "MarineGhostModel",
        [kTechDataCostKey] = kUpgradedCommandStationCost,
        [kTechDataEngagementDistance] = kCommandStationEngagementDistance,
        [kTechDataPointValue] = kCommandStationPointValue,
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
        [kTechDataMapName] = ArmorStation.kMapName,
        [kTechDataModel] = CommandStation.kModelName,
        [kTechDataMaxHealth] = kCommandStationHealth,
        [kTechDataMaxArmor] = kCommandStationArmor,
        [kTechDataHint] = "ARMOR_STATION_HINT",
        [kTechDataDisplayName] = "ARMOR_STATION",
        [kTechDataTooltipInfo] = "ARMOR_STATION_TOOLTIP",
        [kStructureAttachClass] = "TechPoint",
        [kTechDataPersonalResOnKillKey] = kCommandStationPersonalResOnKill,
        [kTechDataTeamResOnKillKey] = kCommandStationTeamResOnKill,
        [kTechDataGhostModelClass] = "MarineGhostModel",
        [kTechDataCostKey] = kUpgradedCommandStationCost,
        [kTechDataEngagementDistance] = kCommandStationEngagementDistance,
        [kTechDataPointValue] = kCommandStationPointValue,
    })

    table.insert(techData, {
        [kTechDataId] = kTechId.CombatBuilderTech,
        [kTechDataCostKey] = kCombatBuilderResearchCost,
        [kTechDataResearchTimeKey] = kCombatBuilderResearchTime,
        [kTechDataDisplayName] = "COMBATBUILDER",
        [kTechDataTooltipInfo] = "COMBATBUILDER_TOOLTIP",
        [kTechDataResearchName] = "COMBATBUILDER",
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
        [kTechDataMapName] = ExplosiveStation.kMapName,
        [kTechDataModel] = CommandStation.kModelName,
        [kTechDataMaxHealth] = kCommandStationHealth,
        [kTechDataMaxArmor] = kCommandStationArmor,
        [kTechDataHint] = "EXPLOSIVE_STATION_HINT",
        [kTechDataDisplayName] = "EXPLOSIVE_STATION",
        [kStructureAttachClass] = "TechPoint",
        [kTechDataPersonalResOnKillKey] = kCommandStationPersonalResOnKill,
        [kTechDataTeamResOnKillKey] = kCommandStationTeamResOnKill,
        [kTechDataGhostModelClass] = "MarineGhostModel",
        [kTechDataCostKey] = kUpgradedCommandStationCost,
        [kTechDataEngagementDistance] = kCommandStationEngagementDistance,
        [kTechDataPointValue] = kCommandStationPointValue,
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
        [kStructureAttachId] = {kTechId.CommandStation,kTechId.StandardStation,kTechId.ArmorStation,kTechId.ExplosiveStation},
        [kStructureAttachRange] = kInfantryPortalAttachRange,
        [kTechDataEngagementDistance] = kInfantryPortalEngagementDistance,
        [kTechDataHotkey] = Move.P,
        [kTechDataNotOnInfestation] = kPreventMarineStructuresOnInfestation,
        [kTechDataTooltipInfo] = "INFANTRY_PORTAL_TOOLTIP",
        [kTechDataObstacleRadius] = 1.125,
        [kTechDataPersonalResOnKillKey] = kInfantryPortalPersonalResOnKill,
        [kTechDataTeamResOnKillKey] = kInfantryPortalTeamResOnKill,
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
        [kTechDataMaxAmount] = kWeaponCachePersonalCarries,
        [kTechDataPersonalCostKey] = kWeaponCachePersonalCost,
        [kTechDataAllowConsumeDrop] = true,
        [kTechDataPersonalResOnKillKey] = kWeaponCachePersonalResOnKill,
        [kTechDataTeamResOnKillKey] = kWeaponCacheTeamResOnKill,
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
        [kTechDataPersonalResOnKillKey] = kSentryBatteryPersonalResOnKill,
        [kTechDataTeamResOnKillKey] = kSentryBatteryTeamResOnKill,
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
        [kTechDataMaxAmount] = kMarineSentryPersonalCarries,
        [kTechDataPersonalCostKey] = kMarineSentryPersonalCost,
        [kTechDataAllowConsumeDrop] = true,
        [kTechDataPersonalResOnKillKey] = kPortableSentryPersonalResOnKill,
        [kTechDataTeamResOnKillKey] = kPortableSentryTeamResOnKill,
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
        [kTechDataDisplayName] = "SPORE_MINE",
        [kTechDataHint] = "SPORE_MINE_TOOLTIP",
        [kTechDataTooltipInfo] = "SPORE_MINE_TOOLTIP",
    })

    --Skulk
    table.insert(techData, {
        [kTechDataId] = kTechId.SkulkBoost,
        [kTechDataCostKey] = kSkulkBoostCost,
        [kTechDataResearchTimeKey] = kSkulkBoostTime,
        [kTechDataDisplayName] = "SKULK_BOOST",
        [kTechDataTooltipInfo] = "SKULK_BOOST_TOOLTIP",
        [kTechDataResearchName] = "SKULK_BOOST",
    })

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
    
    --Resource On Kill
        --Marine
        table.insert(techData,{
            [kTechDataId] = kTechId.Extractor,
            [kTechDataIgnorePathingMesh] = true,
            [kTechDataSpawnBlock] = true,
            [kTechDataHint] = "EXTRACTOR_HINT",
            [kTechDataCollideWithWorldOnly] = true,
            [kTechDataAllowStacking] = true,
            [kTechDataGhostModelClass] = "MarineGhostModel",
            [kTechDataRequiresPower] = true,
            [kTechDataMapName] = Extractor.kMapName,
            [kTechDataDisplayName] = "EXTRACTOR",
            [kTechDataCostKey] = kExtractorCost,
            [kTechDataBuildTime] = kExtractorBuildTime,
            [kTechDataEngagementDistance] = kExtractorEngagementDistance,
            [kTechDataModel] = Extractor.kModelName,
            [kTechDataMaxHealth] = kExtractorHealth,
            [kTechDataMaxArmor] = kExtractorArmor,
            [kStructureAttachClass] = "ResourcePoint",
            [kTechDataPointValue] = kExtractorPointValue,
            [kTechDataHotkey] = Move.E,
            [kTechDataNotOnInfestation] = kPreventMarineStructuresOnInfestation,
            [kTechDataTooltipInfo] = "EXTRACTOR_TOOLTIP",
            [kTechDataObstacleRadius] = 1.35,
            [kTechDataPersonalResOnKillKey] = kExtractorPersonalResOnKill,
            [kTechDataTeamResOnKillKey] = kExtractorTeamResOnKill,
        })
    
        table.insert(techData,{
            [kTechDataId] = kTechId.ARC,
            [kTechDataSupply] = kARCSupply,
            [kTechDataHint] = "ARC_HINT",
            [kTechDataDisplayName] = "ARC",
            [kTechDataTooltipInfo] = Shared.GetThunderdomeEnabled() and "ARC_THUNDERDOME_TOOLTIP" or "ARC_TOOLTIP",
            [kTechDataMapName] = ARC.kMapName,
            [kTechDataCostKey] = kARCCost,
            [kTechDataDamageType] = kARCDamageType,
            [kTechDataResearchTimeKey] = kARCBuildTime,
            [kTechDataMaxHealth] = kARCHealth,
            [kTechDataEngagementDistance] = kARCEngagementDistance,
            [kVisualRange] = ARC.kFireRange,
            [kTechDataMaxArmor] = kARCArmor,
            [kTechDataModel] = ARC.kModelName,
            [kTechDataMaxHealth] = kARCHealth,
            [kTechDataPointValue] = kARCPointValue,
            [kTechDataHotkey] = Move.T,
            [kTechDataPersonalResOnKillKey] = kARCPersonalResOnKill,
            [kTechDataTeamResOnKillKey] = kARCTeamResOnKill,
        })
    
        table.insert(techData,{
            [kTechDataId] = kTechId.Observatory,
            [kTechDataSupply] = kObservatorySupply,
            [kTechDataHint] = "OBSERVATORY_HINT",
            [kTechDataGhostModelClass] = "MarineGhostModel",
            [kTechDataRequiresPower] = true,
            [kTechDataShowBeaconToLocation] = true,
            [kTechDataMapName] = Observatory.kMapName,
            [kTechDataDisplayName] = "OBSERVATORY",
            [kVisualRange] = Observatory.kDetectionRange,
            [kTechDataCostKey] = kObservatoryCost,
            [kTechDataModel] = Observatory.kModelName,
            [kTechDataBuildTime] = kObservatoryBuildTime,
            [kTechDataMaxHealth] = kObservatoryHealth,
            [kTechDataEngagementDistance] = kObservatoryEngagementDistance,
            [kTechDataMaxArmor] = kObservatoryArmor,
            [kTechDataInitialEnergy] = kObservatoryInitialEnergy,
            [kTechDataMaxEnergy] = kObservatoryMaxEnergy,
            [kTechDataPointValue] = kObservatoryPointValue,
            [kTechDataHotkey] = Move.O,
            [kTechDataNotOnInfestation] = kPreventMarineStructuresOnInfestation,
            [kTechDataTooltipInfo] = "OBSERVATORY_TOOLTIP",
            [kTechDataObstacleRadius] = 0.8,
            [kTechDataPersonalResOnKillKey] = kObservatoryPersonalResOnKill,
            [kTechDataTeamResOnKillKey] = kObservatoryTeamResOnKill,
        })

    table.insert(techData,{
            [kTechDataId] = kTechId.PhaseGate,
            [kTechDataHint] = "PHASE_GATE_HINT",
            [kTechDataGhostModelClass] = "MarineGhostModel",
            [kTechDataSupply] = kPhaseGateSupply,
            [kTechDataRequiresPower] = true,
            [kTechDataNotOnInfestation] = kPreventMarineStructuresOnInfestation,
            [kTechDataMapName] = PhaseGate.kMapName,
            [kTechDataDisplayName] = "PHASE_GATE",
            [kTechDataCostKey] = kPhaseGateCost,
            [kTechDataModel] = PhaseGate.kModelName,
            [kTechDataBuildTime] = kPhaseGateBuildTime,
            [kTechDataMaxHealth] = kPhaseGateHealth,
            [kTechDataEngagementDistance] = kPhaseGateEngagementDistance,
            [kTechDataMaxArmor] = kPhaseGateArmor,
            [kTechDataPointValue] = kPhaseGatePointValue,
            [kTechDataHotkey] = Move.P,
            [kTechDataSpecifyOrientation] = true,
            [kTechDataBuildRequiresMethod] = CheckSpaceForPhaseGate,
            [kTechDataTooltipInfo] = "PHASE_GATE_TOOLTIP",
            [kTechDataObstacleRadius] = 1.1,
            [kTechDataPersonalResOnKillKey] = kPhaseGatePersonalResOnKill,
            [kTechDataTeamResOnKillKey] = kPhaseGateTeamResOnKill,
        })
    
        table.insert(techData,{
            [kTechDataId] = kTechId.CommandStation,
            [kTechDataIgnorePathingMesh] = true,
            [kTechDataSpawnBlock] = true,
            [kTechDataMaxExtents] = Vector(1.5, 1, 0.4),
            [kTechDataHint] = "COMMAND_STATION_HINT",
            [kTechDataAllowStacking] = true,
            [kStructureAttachClass] = "TechPoint",
            [kTechDataAttachOptional] = false,
            [kTechDataOverrideCoordsMethod] = OptionalAttachToFreeTechPoint,
            [kTechDataGhostModelClass] = "MarineGhostModel",
            [kTechDataMapName] = CommandStation.kMapName,
            [kTechDataDisplayName] = "COMMAND_STATION",
            [kTechDataNotOnInfestation] = kPreventMarineStructuresOnInfestation,
            [kTechDataBuildTime] = kCommandStationBuildTime,
            [kTechDataCostKey] = kCommandStationCost,
            [kTechDataModel] = CommandStation.kModelName,
            [kTechDataMaxHealth] = kCommandStationHealth,
            [kTechDataMaxArmor] = kCommandStationArmor,
            [kTechDataSpawnHeightOffset] = 0,
            [kTechDataEngagementDistance] = kCommandStationEngagementDistance,
            [kTechDataInitialEnergy] = kCommandStationInitialEnergy,
            [kTechDataMaxEnergy] = kCommandStationMaxEnergy,
            [kTechDataPointValue] = kCommandStationPointValue,
            [kTechDataHotkey] = Move.C,
            [kTechDataTooltipInfo] = "COMMAND_STATION_TOOLTIP",
            [kTechDataObstacleRadius] = 2.3,
            [kTechDataPersonalResOnKillKey] = kCommandStationPersonalResOnKill,
            [kTechDataTeamResOnKillKey] = kCommandStationTeamResOnKill,
        })
    
        table.insert(techData,{
            [kTechDataId] = kTechId.PowerPoint,
            [kTechDataHint] = "POWERPOINT_HINT",
            [kTechDataMapName] = PowerPoint.kMapName,
            [kTechDataDisplayName] = "POWER_NODE",
            [kTechDataCostKey] = 0,
            [kTechDataMaxHealth] = kPowerPointHealth,
            [kTechDataMaxArmor] = kPowerPointArmor,
            [kTechDataBuildTime] = kPowerPointBuildTime,
            [kTechDataPointValue] = kPowerPointPointValue,
            [kTechDataTooltipInfo] = "POWERPOINT_TOOLTIP",
            [kTechDataPersonalResOnKillKey] = kPowerPointPersonalResOnKill,
            [kTechDataTeamResOnKillKey] = kPowerPointTeamResOnKill,
        })
    
        --Alien
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
            [kTechDataPersonalResOnKillKey] = kHarvesterPersonalResOnKill,
            [kTechDataTeamResOnKillKey] = kHarvesterTeamResOnKill,
        })
        
        table.insert(techData,{
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
            [kTechDataPersonalResOnKillKey] = kTunnelPersonalResOnKill,
            [kTechDataTeamResOnKillKey] = kTunnelTeamResOnKill,
        })
    
        table.insert(techData,{
            [kTechDataId] = kTechId.InfestedTunnel,
            [kTechDataMaxExtents] = Vector(1.2, 1.2, 1.2),
            [kTechDataTooltipInfo] = "INFESTED_TUNNEL_TOOLTIP",
            [kTechDataGhostModelClass] = "AlienGhostModel",
            [kTechDataMapName] = TunnelEntrance.kMapName,
            [kTechDataDisplayName] = "INFESTED_TUNNEL_ENTRANCE",
            [kTechDataHint] = "INFESTED_TUNNEL_ENTRANCE_HINT",
            [kTechDataCostKey] = kUpgradeInfestedTunnelEntranceCost,
            [kTechDataResearchTimeKey] = kUpgradeInfestedTunnelEntranceResearchTime,
            [kTechDataMaxHealth] = kInfestedTunnelEntranceHealth,
            [kTechDataMaxArmor] = kInfestedTunnelEntranceArmor,
            [kTechDataBuildTime] = kTunnelBuildTime,
            [kTechDataModel] = TunnelEntrance.kModelName,
            [kTechDataRequiresInfestation] = true,
            [kTechDataPointValue] = kTunnelEntrancePointValue,
            [kTechIDShowEnables] = false,
            [kTechDataObstacleRadius] = 1.25,
            [kTechDataPersonalResOnKillKey] = kTunnelPersonalResOnKill,
            [kTechDataTeamResOnKillKey] = kTunnelTeamResOnKill,
        })

    table.insert(techData,{
            [kTechDataId] = kTechId.Hive,
            [kTechDataIgnorePathingMesh] = true,
            [kTechDataBioMass] = kHiveBiomass,
            [kTechDataSpawnBlock] = true,
            [kTechDataMaxExtents] = Vector(2, 1, 2),
            [kTechDataHint] = "HIVE_HINT",
            [kTechDataAllowStacking] = true,
            [kTechDataGhostModelClass] = "AlienGhostModel",
            [kTechDataMapName] = Hive.kMapName,
            [kTechDataDisplayName] = "HIVE",
            [kTechDataCostKey] = kHiveCost,
            [kTechDataBuildTime] = kHiveBuildTime,
            [kTechDataModel] = Hive.kModelName,
            [kTechDataHotkey] = Move.V,
            [kTechDataMaxHealth] = kHiveHealth,
            [kTechDataMaxArmor] = kHiveArmor,
            [kStructureAttachClass] = "TechPoint",
            [kTechDataSpawnHeightOffset] = 2.494,
            [kTechDataInitialEnergy] = kHiveInitialEnergy,
            [kTechDataMaxEnergy] = kHiveMaxEnergy,
            [kTechDataPointValue] = kHivePointValue,
            [kTechDataTooltipInfo] = "HIVE_TOOLTIP",
            [kTechDataObstacleRadius] = 2.35,
            [kTechDataPersonalResOnKillKey] = kHivePersonalResOnKill,
            [kTechDataTeamResOnKillKey] = kHiveTeamResOnKill,
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
            [kTechDataPersonalResOnKillKey] = kCystPersonalResOnKill,
            [kTechDataTeamResOnKillKey] = kCystTeamResOnKill,
        })
    
        table.insert(techData,{
            [kTechDataId] = kTechId.CragHive,
            [kTechDataHint] = "CRAG_HIVE_HINT",
            [kTechDataMapName] = CragHive.kMapName,
            [kTechDataDisplayName] = "CRAG_HIVE",
            [kTechDataCostKey] = kUpgradeHiveCost,
            [kTechDataResearchTimeKey] = kUpgradeHiveResearchTime,
            [kTechDataBuildTime] = kUpgradeHiveResearchTime,
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
            [kTechDataPersonalResOnKillKey] = kHivePersonalResOnKill,
            [kTechDataTeamResOnKillKey] = kHiveTeamResOnKill,
        })
    
        table.insert(techData,{
            [kTechDataId] = kTechId.ShadeHive,
            [kTechDataHint] = "SHADE_HIVE_HINT",
            [kTechDataMapName] = ShadeHive.kMapName,
            [kTechDataDisplayName] = "SHADE_HIVE",
            [kTechDataCostKey] = kUpgradeHiveCost,
            [kTechDataResearchTimeKey] = kUpgradeHiveResearchTime,
            [kTechDataBuildTime] = kUpgradeHiveResearchTime,
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
            [kTechDataPersonalResOnKillKey] = kHivePersonalResOnKill,
            [kTechDataTeamResOnKillKey] = kHiveTeamResOnKill,
        })
    
        table.insert(techData,{
            [kTechDataId] = kTechId.ShiftHive,
            [kTechDataHint] = "SHIFT_HIVE_HINT",
            [kTechDataMapName] = ShiftHive.kMapName,
            [kTechDataDisplayName] = "SHIFT_HIVE",
            [kTechDataCostKey] = kUpgradeHiveCost,
            [kTechDataResearchTimeKey] = kUpgradeHiveResearchTime,
            [kTechDataBuildTime] = kUpgradeHiveResearchTime,
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
            [kTechDataPersonalResOnKillKey] = kHivePersonalResOnKill,
            [kTechDataTeamResOnKillKey] = kHiveTeamResOnKill,
        })


    table.insert(techData,{
            [kTechDataId] = kTechId.Veil,
            [kTechDataBioMass] = kVeilBiomass,
            [kTechDataHint] = "VEIL_HINT",
            [kTechDataGhostModelClass] = "AlienGhostModel",
            [kTechDataMapName] = Veil.kMapName,
            [kTechDataDisplayName] = "VEIL",
            [kTechDataCostKey] = kVeilCost,
            [kTechDataRequiresInfestation] = true,
            [kTechDataHotkey] = Move.C,
            [kTechDataBuildTime] = kVeilBuildTime,
            [kTechDataModel] = Veil.kModelName,
            [kTechDataMaxHealth] = kVeilHealth,
            [kTechDataMaxArmor] = kVeilArmor,
            [kTechDataPointValue] = kVeilPointValue,
            [kTechDataTooltipInfo] = "VEIL_TOOLTIP",
            [kTechDataGrows] = true,
            [kTechDataObstacleRadius] = 0.5,
            [kTechDataPersonalResOnKillKey] = kTraitPersonalResOnKill,
            [kTechDataTeamResOnKillKey] = kTraitTeamResOnKill,
        })

        table.insert(techData,{
            [kTechDataId] = kTechId.Shell,
            [kTechDataBioMass] = kShellBiomass,
            [kTechDataHint] = "SHELL_HINT",
            [kTechDataGhostModelClass] = "AlienGhostModel",
            [kTechDataMapName] = Shell.kMapName,
            [kTechDataDisplayName] = "SHELL",
            [kTechDataCostKey] = kShellCost,
            [kTechDataRequiresInfestation] = true,
            [kTechDataHotkey] = Move.C,
            [kTechDataBuildTime] = kShellBuildTime,
            [kTechDataModel] = Shell.kModelName,
            [kTechDataMaxHealth] = kShellHealth,
            [kTechDataMaxArmor] = kShellArmor,
            [kTechDataPointValue] = kShellPointValue,
            [kTechDataTooltipInfo] = "SHELL_TOOLTIP",
            [kTechDataGrows] = true,
            [kTechDataObstacleRadius] = 0.8,
            [kTechDataPersonalResOnKillKey] = kTraitPersonalResOnKill,
            [kTechDataTeamResOnKillKey] = kTraitTeamResOnKill,
        })
    
        table.insert(techData,{
            [kTechDataId] = kTechId.Spur,
            [kTechDataBioMass] = kSpurBiomass,
            [kTechDataHint] = "SPUR_HINT",
            [kTechDataGhostModelClass] = "AlienGhostModel",
            [kTechDataMapName] = Spur.kMapName,
            [kTechDataDisplayName] = "SPUR",
            [kTechDataCostKey] = kSpurCost,
            [kTechDataRequiresInfestation] = true,
            [kTechDataHotkey] = Move.C,
            [kTechDataBuildTime] = kSpurBuildTime,
            [kTechDataModel] = Spur.kModelName,
            [kTechDataMaxHealth] = kSpurHealth,
            [kTechDataMaxArmor] = kSpurArmor,
            [kTechDataPointValue] = kSpurPointValue,
            [kTechDataTooltipInfo] = "SPUR_TOOLTIP",
            [kTechDataGrows] = true,
            [kTechDataObstacleRadius] = 0.725,
            [kTechDataPersonalResOnKillKey] = kTraitPersonalResOnKill,
            [kTechDataTeamResOnKillKey] = kTraitTeamResOnKill,
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
            [kTechDataPersonalResOnKillKey] = kTowerPersonalResOnKill,
            [kTechDataTeamResOnKillKey] = kTowerTeamResOnKill,
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
        [kTechDataPersonalResOnKillKey] = kTowerPersonalResOnKill,
        [kTechDataTeamResOnKillKey] = kTowerTeamResOnKill,
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
        [kTechDataMaxExtents] = Vector(1, 1.3, .4),
        [kTechDataTooltipInfo] = "SHADE_TOOLTIP",
        [kTechDataGrows] = true,
        [kTechDataObstacleRadius] = 1.25,
        [kTechDataPersonalResOnKillKey] = kTowerPersonalResOnKill,
        [kTechDataTeamResOnKillKey] = kTowerTeamResOnKill,
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
        [kTechDataPersonalResOnKillKey] = kTowerPersonalResOnKill,
        [kTechDataTeamResOnKillKey] = kTowerTeamResOnKill,
    })
    return techData
end