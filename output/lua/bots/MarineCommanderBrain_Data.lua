Script.Load("lua/bots/CommonActions.lua")
Script.Load("lua/bots/BrainSenses.lua")
Script.Load("lua/OrderedIterableDict.lua")
Script.Load("lua/bots/MarineCommanerBrain_TechPath.lua")
Script.Load("lua/bots/MarineCommanderBrain_Senses.lua")
Script.Load("lua/bots/MarineCommanderBrain_Utility.lua")

local kMarineComBrainTypes = enum({

    "EveryoneIsDead_DoNothing", -- No ips or players :(

    -- Emergency
    "Beacon",
    "RecycleBlueprints_ZeroIPs", -- Recycle blueprints when we don't have enough tres for ips in an emergency
    "BuildInfantryPortal_Zero",
    "BuildExtractor_EarlyGame",
    "DropPacks_ZeroInfantryPortals",
    "BuildExtractor_Zero",

    -- Reactionary Emergency
    "PowerSurgePhaseGate",
    "Nanoshield_PhaseGate",

    -- Field Support (immediate)
    "SecondMedpack", -- Doing it too fast will cause player to not pick up
    "DropPacks", -- Medpack/Ammopack
    "CatPackOrNanoShield_Player",

    -- Base Structures
    "BuildArmsLab",
    "BuildArmory_NearStation",
    "BuildExtractor_RunningLow",
    "BuildInfantryPortal",
    "BuildObservatory",
    "BuildPrototypeLab",

    "BuildPhaseGate_NearControlledTechPoint", -- 3: Controlled TechPoint (Friendly players are near)
    "BuildCommandStation_NearControlledTechPoint",
    "ResearchUpgrades",

    "ObservatoryScan_BaseStructure",
    "ObservatoryScan_Extractor",

    "BuildExtractor",

    -- Embolden secondary bases
    "BuildPhaseGate_NearStation",
    "BuildObservatory_OtherCS",
    "BuildInfantryPortal_OtherCS",

    -- Embolden phase gate positions
    "BuildArmory_NearPhaseGate",
    "BuildObservatory_NearPG",
    "BuildCommandStation_NearPhaseGate",
    "BuildRoboticsFactory_NearPhaseGate",
    --"BuildPrototypeLab_NearPhaseGate",

    -- Extra $$$
    "DropWeapons",
    "DropJetpack",
    "BuildAndManageMACs",

    "Idle"
})

local kMarineComActionTypesOrderScale = 100
local function GetMarineComBaselineWeight( actionId )
    assert(kMarineComBrainTypes[kMarineComBrainTypes[actionId]], "Error: Invalid MarineComBrain action-id passed")

    local totalActions = #kMarineComBrainTypes
    local actionOrderId = kMarineComBrainTypes[kMarineComBrainTypes[actionId]] --numeric index, not string

    --invert numeric index value and scale, the results in lower value, the higher the index. Which means
    --the Enum of actions is shown and used in a natural order (i.e. order of enum value declaration IS the priority)
    local actionWeightOrder = totalActions - (actionOrderId - 1)

    --final action base-line weight value
    return actionWeightOrder * kMarineComActionTypesOrderScale
end

local GetMarineComNextTechStep = GetMarineComNextTechStep
local GetBaseUnitFromDoables = GetBaseUnitFromDoables
local GetEntityCanUseMedpack = GetEntityCanUseMedpack

local kStationBuildDist = 15.0      --BOT-FIXME Usge of this value needs to take into account specifics of X Location (its entrances), and NOT build near those
local kPhaseBuildDist = 15.0
local kBeaconNearbyDist = 20.0
local kBeaconNearbyFriendlyDist = 25.0
local kArmsLabBuildDist = 6 -- Distance from Command Station
local kObservatoryBuildDist = 8 -- Includes both PG and CStation
local kStationArmoryBuildDist = 12
kPoofRetryDelay = 8 -- How often to try to re-drop a structure that has been poofed (any structure, in a location with same name orginal = 10)

local kDroppedWeaponTechIds = set
{
    kTechId.Shotgun,
    kTechId.GrenadeLauncher,
    kTechId.Flamethrower,
    kTechId.HeavyMachineGun
}

local kWeaponToDropTechIds =
{
    [kTechId.Shotgun        ] = kTechId.DropShotgun,
    [kTechId.GrenadeLauncher] = kTechId.DropGrenadeLauncher,
    [kTechId.Flamethrower   ] = kTechId.DropFlamethrower,
    [kTechId.HeavyMachineGun] = kTechId.DropHeavyMachineGun
}

-- Ordering matters for this table, as this action only does one drop at a time!
local kDroppedWeaponDistributions =
{
    {techId = kTechId.HeavyMachineGun, distribution = 0.40}, -- Current pub strats like hmg more than sg /shrug
    {techId = kTechId.Shotgun        , distribution = 0.30},
    {techId = kTechId.GrenadeLauncher, distribution = 0.15},
    {techId = kTechId.Flamethrower   , distribution = 0.15},
}

local kBeaconBlipUrgencies =
{
    [kMinimapBlipType.Skulk] = 1,
    [kMinimapBlipType.SensorBlip] = 1,
    [kMinimapBlipType.Gorge] = 3,
    [kMinimapBlipType.Lerk] = 1,
    [kMinimapBlipType.Fade] = 0.5,
    [kMinimapBlipType.Onos] = 2,
    [kMinimapBlipType.Marine] = 1.5,
    [kMinimapBlipType.JetpackMarine] = 1,
    [kMinimapBlipType.Exo] = 3
}

local kScanReactWeight = {
    [kTechId.MarineAlertExtractorUnderAttack] = GetMarineComBaselineWeight(kMarineComBrainTypes.ObservatoryScan_Extractor),
    [kTechId.MarineAlertInfantryPortalUnderAttack] = GetMarineComBaselineWeight(kMarineComBrainTypes.ObservatoryScan_BaseStructure),
    [kTechId.MarineAlertCommandStationUnderAttack] = GetMarineComBaselineWeight(kMarineComBrainTypes.ObservatoryScan_BaseStructure),
    [kTechId.MarineAlertStructureUnderAttack] = GetMarineComBaselineWeight(kMarineComBrainTypes.ObservatoryScan_BaseStructure),
}

local kDroppackAlertToTechId =
{
    [kTechId.MarineAlertNeedAmmo] = kTechId.AmmoPack,
    [kTechId.MarineAlertNeedMedpack] = kTechId.MedPack
}

local kDroppackAlertCheckFunctions =
{
    [kTechId.MarineAlertNeedAmmo] = function(target)
        local weapon = target:GetActiveWeapon()

        local ammoPercentage = 1
        if weapon and weapon:isa("ClipWeapon") then
            local max = weapon:GetMaxAmmo()
            if max > 0 then
                ammoPercentage = weapon:GetAmmo() / max
            end
        end

        return ammoPercentage
    end,

    [kTechId.MarineAlertNeedMedpack] = function(target)
        return target:GetHealthFraction()
    end
}

local function GetIsWeldedByOtherMAC(self, target)

    if target then
    
        for _, mac in ipairs(GetEntitiesForTeam("MAC", self:GetTeamNumber())) do
        
            if self ~= mac then
            
                if mac.secondaryTargetId ~= nil and Shared.GetEntity(mac.secondaryTargetId) == target then
                    return true
                end
                
                local currentOrder = mac:GetCurrentOrder()
                local orderTarget
                if currentOrder and currentOrder:GetParam() ~= nil then
                    orderTarget = Shared.GetEntity(currentOrder:GetParam())
                end
                
                if currentOrder and orderTarget == target and (currentOrder:GetType() == kTechId.FollowAndWeld or currentOrder:GetType() == kTechId.Weld or currentOrder:GetType() == kTechId.AutoWeld) then
                    return true
                end
                
            end
            
        end
        
    end
    
    return false
    
end

kMarineComBrainActions =
{
    function(bot, brain)

        local name = kMarineComBrainTypes[kMarineComBrainTypes.EveryoneIsDead_DoNothing]
        local weight = 0

        local commanderPlayer = bot:GetPlayer()
        local commanderTeam = commanderPlayer:GetTeamNumber()

        local numFriendlyPlayers = 0
        local players = GetEntitiesForTeam("Player", commanderTeam)
        for _, player in ipairs(players) do
            local isAlive = HasMixin(player, "Live") and player:GetIsAlive()
            local isMarine = player:isa("Marine")
            local isSelf = player:GetId() == commanderPlayer:GetId()
            local isBot = player.GetClient and player:GetClient() and player:GetClient():GetIsVirtual()

            if isAlive and not isSelf and (isMarine or not isBot) then
                numFriendlyPlayers = numFriendlyPlayers + 1
            end
        end

        local numWorkingInfantryPortals = 0
        local friendlyInfantryPortals = GetEntitiesForTeam("InfantryPortal", commanderTeam)
        for _, ip in ipairs(friendlyInfantryPortals) do
            if ip:GetIsAlive() and ip:GetIsBuilt() then -- Ignore unpowered infantry portals, because we could power surge it
                numWorkingInfantryPortals = numWorkingInfantryPortals + 1
            end
        end

        -- Everyone is dead and impossible to respawn except for us :(
        if numFriendlyPlayers <= 0 and numWorkingInfantryPortals <= 0 then
            weight = GetMarineComBaselineWeight(kMarineComBrainTypes.EveryoneIsDead_DoNothing)
        end

        return
        {
            name = name,
            weight = weight,
            perform = function(move) end
        }
    end, -- Everyone is dead with no IPs, do nothing :(

--[[
    function(bot, brain)

        local name = "commandstation"
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0.0
        local targetTP
        local aboutToLose = false
        local now = Shared.GetTime()

        -- Find a cc slot
        targetTP = sdb:Get("techPointToTake")

        if targetTP and doables[kTechId.CommandStation] and (not bot.nextCCDrop or bot.nextCCDrop < now) then
            local ccs = GetEntitiesForTeam("CommandStation", com:GetTeamNumber())
            weight = EvalLPF( #ccs,
                {
                {1, 0.2},
                {2, 0.1},
                {3, 0.05},
                })
            if #ccs <= 1 then
                -- check if the health is super low
                if ccs[1]:GetHealthScalar() < 0.5 then
                    aboutToLose = true
                    weight = 5
                end
            end
        end
        
        if (sdb:Get("gameMinutes") < 4) then
            weight = 0
        end

        -- Poof delay
        if targetTP and not aboutToLose then
            local lastPoofTime = brain:GetLastPoofTime(targetTP:GetLocationName())
            if now < lastPoofTime + kPoofRetryDelay then
                weight = 0
            end
        end

        return { name = name, weight = weight,
            perform = function(move)
                if doables[kTechId.CommandStation] and targetTP then

                    local sucess = brain:ExecuteTechId( com, kTechId.CommandStation, targetTP:GetOrigin(), com )
                    if sucess then
                        bot.nextCCDrop = Shared.GetTime() + 5
                    end
                end
            end}
    end, -- New Command Station
--]]

    function(bot, brain, com)

        local name = kMarineComBrainTypes[kMarineComBrainTypes.RecycleBlueprints_ZeroIPs]
        local senses = brain:GetSenses()
        local comTeam = com:GetTeamNumber()
        local doables = senses:Get("doableTechIds")

        local weight = 0
        local buildPos
        local isZeroIPs = #senses:Get("infantryPortals") <= 0 -- Include unpowered IPs

        local ghostStructureToRecycle

        if not doables[kTechId.InfantryPortal] and isZeroIPs then

            local ghostStructures = senses:Get("ghostStructures")
            for _, ghostStruc in ipairs(ghostStructures) do
                ghostStructureToRecycle = ghostStruc
                break
            end

            if ghostStructureToRecycle then
                weight = GetMarineComBaselineWeight(kMarineComBrainTypes.RecycleBlueprints_ZeroIPs)
            end

        end

        return
        {
            name = name,
            weight = weight,
            perform = function(move, bot, brain, player, action)
                -- CommanderBrain:ExecuteTechId( commander, techId, position, hostEntity, targetId, trace)
                brain:ExecuteTechId(com, kTechId.Cancel, ghostStructureToRecycle:GetOrigin(), ghostStructureToRecycle)
            end
        }

    end, -- Recycle Blueprints (Zero Ips Emergency)

  function(bot, brain, com)

        local name = kMarineComBrainTypes[kMarineComBrainTypes.BuildCommandStation_NearControlledTechPoint]
        local senses = brain:GetSenses()
        local comTeam = com:GetTeamNumber()
        local doables = senses:Get("doableTechIds")


        local weight = 0
        local buildPos
        local isZeroIPs = #senses:Get("activeInfantryPortals") <= 0

        if doables[kTechId.CommandStation] and not isZeroIPs and senses:Get("mainPhaseGate") and #senses:Get("phaseGates") then

            local emptyTechPoints = senses:Get("safeTechPoints") -- Includes "Stations" and "Controlled Techpoint", nearby marines
            for _, techPoint in ipairs(emptyTechPoints) do

                local phaseGates = GetEntitiesForTeamByLocation("PhaseGate", comTeam, techPoint:GetLocationId())
                if #phaseGates <= 0 then
                    buildPos = GetRandomBuildPosition(kTechId.CommandStation, techPoint:GetOrigin(), kStationBuildDist)
                    if buildPos then
                        weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildCommandStation_NearControlledTechPoint)
                        break
                    end
                end
            end
        end

        return
        {
            name = name,
            weight = weight,
            perform = function(move, bot, brain, player, action)
                brain:ExecuteTechId(com, kTechId.CommandStation, buildPos, com)
            end
        }

    end, -- BuildCommandStation (Near Controlled TechPoint)

    function(bot, brain, com)

        local name = kMarineComBrainTypes[kMarineComBrainTypes.BuildPhaseGate_NearControlledTechPoint]
        local senses = brain:GetSenses()
        local comTeam = com:GetTeamNumber()
        local doables = senses:Get("doableTechIds")

        local kMaxPhaseGates = 5

        local weight = 0
        local buildPos
        local isZeroIPs = #senses:Get("activeInfantryPortals") <= 0

        if doables[kTechId.PhaseGate] and not isZeroIPs and senses:Get("mainPhaseGate") and #senses:Get("phaseGates") < kMaxPhaseGates then

            local emptyTechPoints = senses:Get("safeTechPoints") -- Includes "Stations" and "Controlled Techpoint", nearby marines
            for _, techPoint in ipairs(emptyTechPoints) do

                local phaseGates = GetEntitiesForTeamByLocation("PhaseGate", comTeam, techPoint:GetLocationId())
                if #phaseGates <= 0 then
                    buildPos = GetRandomBuildPosition(kTechId.PhaseGate, techPoint:GetOrigin(), kStationBuildDist)
                    if buildPos then
                        weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildPhaseGate_NearControlledTechPoint)
                        break
                    end
                end
            end
        end

        return
        {
            name = name,
            weight = weight,
            perform = function(move, bot, brain, player, action)
                brain:ExecuteTechId(com, kTechId.PhaseGate, buildPos, com)
            end
        }

    end, -- BuildPhaseGate (Near Controlled TechPoint)

    function(bot, brain, com)

        local name = kMarineComBrainTypes[kMarineComBrainTypes.BuildArmory_NearPhaseGate]
        local comTeam = com:GetTeamNumber()
        local senses = brain:GetSenses()
        local doables = senses:Get("doableTechIds")

        local weight = 0
        local buildPos

        local isZeroIPs = #senses:Get("activeInfantryPortals") <= 0
        if doables[kTechId.Armory] and not isZeroIPs and not brain:GetIsProcessingTechPathOverride() then

            local phaseGates = senses:Get("builtPhaseGates")
            for _, cs in ipairs(phaseGates) do

                local armories = GetEntitiesForTeamByLocation("Armory", comTeam, cs:GetLocationId())
                if #armories <= 0 then
                    buildPos = GetRandomBuildPosition(kTechId.Armory, cs:GetOrigin(), kPhaseBuildDist)
                    if buildPos and
                            brain:GetIsSafeToDropInLocation(cs:GetLocationName(), com:GetTeamNumber(), senses:Get("isEarlyGame")) and
                            #GetEntitiesAliveForTeamWithinRange("Marine", com:GetTeamNumber(), buildPos, kMarinesNearbyRange) > 0 then
                        weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildArmory_NearPhaseGate)
                        break
                    end
                end

            end

        end

        return
        {
            name = name,
            weight = weight,
            perform = function(move, bot, brain, com, action)
                brain:ExecuteTechId(com, kTechId.Armory, buildPos, com)
            end
        }

    end, -- Build Armory (Near PhaseGate)
    
        --[[function(bot, brain, com)

        local name = kMarineComBrainTypes[kMarineComBrainTypes.BuildPrototypeLab_NearPhaseGate]
        local comTeam = com:GetTeamNumber()
        local senses = brain:GetSenses()
        local doables = senses:Get("doableTechIds")

        local weight = 0
        local buildPos
        local hasMinimumTRes = com:GetTeamResources() >= 80

        local isZeroIPs = #senses:Get("activeInfantryPortals") <= 0
        if doables[kTechId.PrototypeLab] and hasMinimumTRes and not isZeroIPs and not brain:GetIsProcessingTechPathOverride() then

            local phaseGates = senses:Get("builtPhaseGates")
            for _, cs in ipairs(phaseGates) do

                local prototypeLabs = GetEntitiesForTeamByLocation("PrototypeLab", comTeam, cs:GetLocationId())
                if #prototypeLabs <= 0 then
                    buildPos = GetRandomBuildPosition(kTechId.PrototypeLab, cs:GetOrigin(), kPhaseBuildDist)
                    if buildPos and
                            brain:GetIsSafeToDropInLocation(cs:GetLocationName(), com:GetTeamNumber(), senses:Get("isEarlyGame")) and
                            #GetEntitiesAliveForTeamWithinRange("Marine", com:GetTeamNumber(), buildPos, kMarinesNearbyRange) > 0 then
                        weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildPrototypeLab_NearPhaseGate)
                        break
                    end
                end

            end

        end

        return
        {
            name = name,
            weight = weight,
            perform = function(move, bot, brain, com, action)
                brain:ExecuteTechId(com, kTechId.PrototypeLab, buildPos, com)
            end
        }

    end, -- Build PrototypeLab_NearPhasegate--]]
    
            function(bot, brain, com)

        local name = kMarineComBrainTypes[kMarineComBrainTypes.BuildCommandStation_NearPhaseGate]
        local comTeam = com:GetTeamNumber()
        local senses = brain:GetSenses()
        local doables = senses:Get("doableTechIds")

        local weight = 0
        local buildPos

        local isZeroIPs = #senses:Get("activeInfantryPortals") <= 0
        if doables[kTechId.CommandStation] and not isZeroIPs and not brain:GetIsProcessingTechPathOverride() then

            local phaseGates = senses:Get("builtPhaseGates")
            for _, cs in ipairs(phaseGates) do

                local commandstations = GetEntitiesForTeamByLocation("CommandStation", comTeam, cs:GetLocationId())
                if #commandstations <= 0 then
                    buildPos = GetRandomBuildPosition(kTechId.CommandStation, cs:GetOrigin(), kPhaseBuildDist)
                    if buildPos and
                            brain:GetIsSafeToDropInLocation(cs:GetLocationName(), com:GetTeamNumber(), senses:Get("isEarlyGame")) and
                            #GetEntitiesAliveForTeamWithinRange("Marine", com:GetTeamNumber(), buildPos, kMarinesNearbyRange) > 0 then
                        weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildCommandStation_NearPhaseGate)
                        break
                    end
                end

            end

        end

        return
        {
            name = name,
            weight = weight,
            perform = function(move, bot, brain, com, action)
                brain:ExecuteTechId(com, kTechId.CommandStation, buildPos, com)
            end
        }

    end, -- Build CommandStation (Near PhaseGate)
    
function(bot, brain, com)

        local name = kMarineComBrainTypes[kMarineComBrainTypes.BuildRoboticsFactory_NearPhaseGate]
        local comTeam = com:GetTeamNumber()
        local senses = brain:GetSenses()
        local doables = senses:Get("doableTechIds")
        local hasMinimumTRes = com:GetTeamResources() >= 45
        
        local kMaxRoboticsFactories = 1

        local weight = 0
        local buildPos

        local isZeroIPs = #senses:Get("activeInfantryPortals") <= 0
        if doables[kTechId.RoboticsFactory] and hasMinimumTRes and not isZeroIPs and not brain:GetIsProcessingTechPathOverride() then

            local phaseGates = senses:Get("builtPhaseGates")
            for _, cs in ipairs(phaseGates) do

                local roboticsfactories = GetEntitiesForTeamByLocation("RoboticsFactory", comTeam, cs:GetLocationId())
                if #roboticsfactories <= 0 then
                    buildPos = GetRandomBuildPosition(kTechId.RoboticsFactory, cs:GetOrigin(), kPhaseBuildDist)
                    if buildPos and
                            brain:GetIsSafeToDropInLocation(cs:GetLocationName(), com:GetTeamNumber(), senses:Get("isEarlyGame")) and
                            #GetEntitiesAliveForTeamWithinRange("Marine", com:GetTeamNumber(), buildPos, kMarinesNearbyRange) > 0 then
                        -- Hier �berpr�fe ich, ob die Anzahl der Roboterfabriken im Team kleiner als kMaxRoboticsFactories ist, indem ich die Funktion GetEntitiesForTeam aufrufe
                        local allRoboticsFactories = GetEntitiesForTeam("RoboticsFactory", comTeam)
                        if #allRoboticsFactories < kMaxRoboticsFactories then
                            -- Wenn ja, dann setze ich das Gewicht auf den normalen Wert, um den Bot eine Roboterfabrik bauen zu lassen
                            weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildRoboticsFactory_NearPhaseGate)
                        else
                            -- Wenn nein, dann setze ich das Gewicht auf 0, um zu verhindern, dass der Bot eine weitere Roboterfabrik baut
                            weight = 0
                        end
                        break
                    end
                end

            end

        end

        return
        {
            name = name,
            weight = weight,
            perform = function(move, bot, brain, com, action)
                brain:ExecuteTechId(com, kTechId.RoboticsFactory, buildPos, com)
            end
        }

    end,  --Build RoboticsFactory (Near PhaseGate) --]]

    
    function(bot, brain, com)
        PROFILE("MarineComBrain:BuildObservatory")

        local name = kMarineComBrainTypes[kMarineComBrainTypes.BuildObservatory]
        local comTeam = com:GetTeamNumber()
        local senses = brain:GetSenses()
        local doables = senses:Get("doableTechIds")

        local weight = 0

        local kMaxForwardObservatories = 3 -- Not including main base observatory

        local buildPos

        local forwardObs = senses:Get("forwardObservatories")
        local canPlaceMoreForwardObs = #forwardObs < kMaxForwardObservatories
        local mainBaseLocationId = brain:GetStartingLocationId()
        local isZeroIPs = #senses:Get("activeInfantryPortals") <= 0

        if doables[kTechId.Observatory] and not isZeroIPs and not brain:GetIsProcessingTechPathOverride() and canPlaceMoreForwardObs and mainBaseLocationId ~= 0 and not senses:Get("isEarlyGame") then

            local phaseGates = senses:Get("builtPhaseGates")
            for _, pg in ipairs(phaseGates) do
                local pgLocationId = pg:GetLocationId()
                if pgLocationId ~= 0 and pgLocationId ~= mainBaseLocationId and
                        #GetEntitiesForTeamByLocation("Armory", comTeam, pgLocationId) > 0 and
                        #GetEntitiesForTeamByLocation("Observatory", comTeam, pgLocationId) <= 0 then

                    buildPos = GetRandomBuildPosition(kTechId.Observatory, pg:GetOrigin(), kObservatoryBuildDist)
                    if buildPos then
                        weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildObservatory_NearPG)
                    end

                    break
                end
            end

        end

        return
        {
            name = name,
            weight = weight,
            perform = function(move, bot, brain, com, action)
                brain:ExecuteTechId(com, kTechId.Observatory, buildPos, com)
            end
        }

    end, -- Build Observatory (Near PhaseGate)

    function(bot, brain, com)

        local name = kMarineComBrainTypes[kMarineComBrainTypes.BuildInfantryPortal]
        local senses = brain:GetSenses()
        local doables = senses:Get("doableTechIds")

        local weight = 0

        local buildPos

        if doables[kTechId.InfantryPortal] then

            local ips = senses:Get("infantryPortals")
            local commandStations = senses:Get("builtCommandStations")

            if #ips <= 0 then

                -- Find first not-in-combat command station
                local commandStation
                for _, cs in ipairs(commandStations) do
                    if not cs:GetIsInCombat() then
                        commandStation = cs
                        break
                    end
                end

                -- If we don't have any "safe" command stations, just keep trying the other one
                if not commandStation then
                    commandStation = commandStations[1]
                end

                if commandStation then

                    buildPos = GetRandomBuildPosition(kTechId.InfantryPortal, commandStation:GetOrigin(), kInfantryPortalAttachRange)
                    if buildPos and brain:GetIsSafeToDropInLocation(commandStation:GetLocationName(), com:GetTeamNumber(), senses:Get("isEarlyGame")) then
                        weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildInfantryPortal_Zero)
                    end

                end
            else

                local isFirst = false
                local commandStation
                for i, cs in ipairs(commandStations) do
                    local nIps = #GetEntitiesForTeamWithinRange("InfantryPortal",
                            com:GetTeamNumber(),
                            cs:GetOrigin(),
                            kInfantryPortalAttachRange)

                    if nIps < senses:Get("maxInfantryPortals") then
                        commandStation = cs
                        isFirst = i == 1
                        break
                    end
                end

                if commandStation then
                    if brain:GetIsSafeToDropInLocation(commandStation:GetLocationName(), bot:GetTeamNumber(), senses:Get("isEarlyGame")) then

                        buildPos = GetRandomBuildPosition(kTechId.InfantryPortal, commandStation:GetOrigin(), kInfantryPortalAttachRange)
                        if buildPos and brain:GetIsSafeToDropInLocation(commandStation:GetLocationName(), com:GetTeamNumber(), senses:Get("isEarlyGame")) then
                            if isFirst then
                                weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildInfantryPortal)
                            else
                                weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildInfantryPortal_OtherCS)
                            end
                        end
                    end
                end
            end
        end

        return
        {
            name = name,
            weight = weight,
            perform = function(move, bot, brain, com, action)
                brain:ExecuteTechId(com, kTechId.InfantryPortal, buildPos, com)
            end
        }

    end, -- Build Infantry Portals

    function(bot, brain, com)

        local name = kMarineComBrainTypes[kMarineComBrainTypes.ResearchUpgrades]
        local senses = brain:GetSenses()
        local doables = senses:Get("doableTechIds")

        local weight = 0

        local nextTechStep, techType, techTier = GetMarineComNextTechStep(bot, brain, com)
        local buildPos
        local techStepUnit = com

        local isZeroIPs = #senses:Get("activeInfantryPortals") <= 0
        if Shared.GetTime() > brain.timeNextUpgradeAction and not isZeroIPs then

            if nextTechStep and nextTechStep ~= kTechId.None and doables[nextTechStep] then

                local isTechForEarlyGame = techTier == 1
                local isUpgradeAllowed = false

                -- Wait until we drop the natural RTs before trying to upgrade stuff
                if senses:Get("isEarlyGame") then
                    if isTechForEarlyGame and brain.hasDroppedNaturalRTs then
                        isUpgradeAllowed = true
                    end
                else
                    isUpgradeAllowed = true
                end

                if isUpgradeAllowed then

                    brain.nextTechStepId = nextTechStep or kTechId.None

                    if techType == kTechType.Research or techType == kTechType.Upgrade then

                        local doableUnits = doables[nextTechStep]
                        techStepUnit = GetBaseUnitFromDoables(senses, brain, doableUnits)
                        buildPos = Vector(0,0,0)
                        if techStepUnit then
                            weight = GetMarineComBaselineWeight(kMarineComBrainTypes.ResearchUpgrades)
                        end

                    elseif techType == kTechType.Build then

                        local mainCommandStation = senses:Get("mainCommandStation")
                        if mainCommandStation then

                            techStepUnit = com
                            buildPos = GetRandomBuildPosition(nextTechStep, mainCommandStation:GetOrigin(), kStationBuildDist)
                            if buildPos and brain:GetIsSafeToDropInLocation(mainCommandStation:GetLocationName(), com:GetTeamNumber(), senses:Get("isEarlyGame")) then
                                weight = GetMarineComBaselineWeight(kMarineComBrainTypes.ResearchUpgrades)
                            end

                        end
                    end

                end
            end

        end

        return
        {
            name = name,
            weight = weight,
            perform = function(move, bot, brain, com, action)
                brain.timeNextUpgradeAction = Shared.GetTime() + brain.kUpgradeActionDelay
                brain:ExecuteTechId( com, nextTechStep, buildPos, techStepUnit )
            end
        }

    end, -- Research Upgrades
    
    function(bot, brain, com)

        local name = kMarineComBrainTypes[kMarineComBrainTypes.Beacon]
        local senses = brain:GetSenses()
        local doables = senses:Get("doableTechIds")

        local weight = 0
        local obsToUse

        if doables[kTechId.DistressBeacon] and (not brain.nextBeaconTime or brain.nextBeaconTime < Shared.GetTime()) then

            local currentUrgency = 0
            local ccs = senses:Get("builtCommandStations")
            local memories = GetTeamMemories( com:GetTeamNumber() )
            for _, cc in ipairs(ccs) do

                local bestBeaconUrgency = 0
                local enemyWeight = 0
                local friendlyWeight = #GetEntitiesForTeamWithinRange("Player",
                        com:GetTeamNumber(),
                        cc:GetOrigin(),
                        kBeaconNearbyFriendlyDist)

                for _,mem in ipairs(memories) do
                    local target = Shared.GetEntity(mem.entId)
                    if HasMixin(target, "Live") and target:GetIsAlive() and com:GetTeamNumber() ~= target:GetTeamNumber() then
                        local dist = cc:GetOrigin():GetDistance( mem.lastSeenPos )
                        if dist < kBeaconNearbyDist and kBeaconBlipUrgencies[mem.btype] ~= nil then
                            enemyWeight = enemyWeight + kBeaconBlipUrgencies[mem.btype]
                        end
                    end
                end

                if #ccs == 1 then
                    -- increase the threat level if we only have 1 CC and it has low health
                    enemyWeight = enemyWeight + enemyWeight * (1 - cc:GetHealthFraction()) * 4.0
                end

                currentUrgency = EvalLPF( enemyWeight/(friendlyWeight+1),
                        {
                            {0, 0.0},
                            {1, 0.0},
                            {2, 10.0},
                        })

                if currentUrgency > bestBeaconUrgency then

                    bestBeaconUrgency = currentUrgency

                    local observatories = GetEntitiesAliveForTeam("Observatory", com:GetTeamNumber())
                    Shared.SortEntitiesByDistance(com:GetOrigin(), observatories)

                    for _, obs in ipairs(observatories) do

                        if GetIsUnitActive(obs) then
                            local nearest = GetNearest(obs:GetOrigin(), "CommandStation", com:GetTeamNumber(), function(ent) return ent:GetIsBuilt() and ent:GetIsAlive() end)
                            if nearest == cc then
                                obsToUse = obs
                                weight = GetMarineComBaselineWeight(kMarineComBrainTypes.Beacon)
                                break
                            end
                        end
                    end
                end

            end
        end

        return { name = name,
                 weight = weight,
                 perform = function(move)
                     local success = brain:ExecuteTechId( com, kTechId.DistressBeacon, Vector(0,0,0), obsToUse )
                     if success then
                         brain.nextBeaconTime = Shared.GetTime() + 20
                     end
            end}
    end, -- Beacon (Mass Recall)
    
    function(bot, brain, com)

        local name = kMarineComBrainTypes[kMarineComBrainTypes.DropJetpack]
        local senses = brain:GetSenses()
        local comTeam = com:GetTeamNumber()
        local doables = senses:Get("doableTechIds")
        local tooMuchRes = com:GetTeamResources() >= 200

        local weight = 0
        local protoToDropNear

        local isZeroIPs = #senses:Get("activeInfantryPortals") <= 0
        local prototypeLabs = senses:Get("builtPrototypeLabs")
        if doables[kTechId.DropJetpack] and #prototypeLabs > 0 and not isZeroIPs and not brain:GetIsProcessingTechPathOverride() then

            local jetpacks = GetEntitiesForTeam("Jetpack", comTeam)
            local maxJetpacks = 5
            if #jetpacks < maxJetpacks and tooMuchRes then
                weight = GetMarineComBaselineWeight(kMarineComBrainTypes.DropJetpack)
                protoToDropNear = prototypeLabs[math.random(#prototypeLabs)]
            end

        end
        
        return { name = name, weight = weight,
            perform = function(move)

                local aroundPos = protoToDropNear:GetOrigin()
                local targetPos = GetRandomSpawnForCapsule(0.4,
                        0.4,
                        aroundPos,
                        0.01,
                        kArmoryWeaponAttachRange * 0.65,
                        EntityFilterAll(), nil)
                        
                        if targetPos then
                        brain:ExecuteTechId(com, kTechId.DropJetpack, targetPos, com, protoToDropNear:GetId())
                        end
                        
                local aroundPosJP2 = protoToDropNear:GetOrigin()
                local targetPosJP2 = GetRandomSpawnForCapsule(0.7,
                        0.7,
                        aroundPosJP2,
                        0.01,
                        kArmoryWeaponAttachRange * 0.65,
                        EntityFilterAll(), nil)
                        
                        if targetPos then
                        brain:ExecuteTechId(com, kTechId.DropJetpack, targetPosJP2, com, protoToDropNear:GetId())
                        end
                local aroundPosJP3 = protoToDropNear:GetOrigin()
                local targetPosJP3 = GetRandomSpawnForCapsule(0.8,
                        0.8,
                        aroundPosJP3,
                        0.01,
                        kArmoryWeaponAttachRange * 0.65,
                        EntityFilterAll(), nil)
                        
                        if targetPos then
                        brain:ExecuteTechId(com, kTechId.DropJetpack, targetPosJP3, com, protoToDropNear:GetId())
                        end
                local aroundPosJP4 = protoToDropNear:GetOrigin()
                local targetPosJP4 = GetRandomSpawnForCapsule(0.6,
                        0.6,
                        aroundPosJP4,
                        0.01,
                        kArmoryWeaponAttachRange * 0.65,
                        EntityFilterAll(), nil)
                        
                        if targetPos then
                        brain:ExecuteTechId(com, kTechId.DropJetpack, targetPosJP4, com, protoToDropNear:GetId())
                        end
                local aroundPosJP5 = protoToDropNear:GetOrigin()
                local targetPosJP5 = GetRandomSpawnForCapsule(0.6,
                        0.6,
                        aroundPosJP5,
                        0.01,
                        kArmoryWeaponAttachRange * 0.65,
                        EntityFilterAll(), nil)
                        
                        if targetPos then
                        brain:ExecuteTechId(com, kTechId.DropJetpack, targetPosJP5, com, protoToDropNear:GetId())
                        end
                local aroundPosSG = protoToDropNear:GetOrigin()
                local targetPosSG = GetRandomSpawnForCapsule(0.2,
                        0.2,
                        aroundPosSG,
                        0.01,
                        kArmoryWeaponAttachRange * 0.75,
                        EntityFilterAll(), nil)
                        
                 if targetPosSG then
                    brain:ExecuteTechId(com, kTechId.DropShotgun, targetPosSG, com, protoToDropNear:GetId())
                   end
               local aroundPosSG2 = protoToDropNear:GetOrigin()
               local targetPosSG2 = GetRandomSpawnForCapsule(0.1,
                        0.1,
                        aroundPosSG2,
                        0.01,
                        kArmoryWeaponAttachRange * 0.75,
                        EntityFilterAll(), nil)
                        
                 if targetPosSG then
                    brain:ExecuteTechId(com, kTechId.DropShotgun, targetPosSG2, com, protoToDropNear:GetId())
                   end
              
                local aroundPosFT = protoToDropNear:GetOrigin()
                local targetPosFT = GetRandomSpawnForCapsule(0.3,
                        0.3,
                        aroundPosFT,
                        0.01,
                        kArmoryWeaponAttachRange * 0.75,
                        EntityFilterAll(), nil)
                        
                    if targetPosFT then
                    brain:ExecuteTechId(com, kTechId.DropFlamethrower, targetPosFT, com, protoToDropNear:GetId())
                   end
                   
                local aroundPosFT2 = protoToDropNear:GetOrigin()
                local targetPosFT2 = GetRandomSpawnForCapsule(0.3,
                        0.3,
                        aroundPosFT2,
                        0.01,
                        kArmoryWeaponAttachRange * 0.75,
                        EntityFilterAll(), nil)
                        
                    if targetPosFT then
                    brain:ExecuteTechId(com, kTechId.DropFlamethrower, targetPosFT2, com, protoToDropNear:GetId())
                   end  
                   
               local aroundPosHMG = protoToDropNear:GetOrigin()                     
               local targetPosHMG = GetRandomSpawnForCapsule(0.5,
                        0.5,
                        aroundPosHMG,
                        0.01,
                        kArmoryWeaponAttachRange * 0.75,
                        EntityFilterAll(), nil)
                        
                        if targetPosHMG then
                        brain:ExecuteTechId(com, kTechId.DropHeavyMachineGun, targetPosHMG, com, protoToDropNear:GetId())
                        end
                        
               local aroundPosGL = protoToDropNear:GetOrigin()                     
               local targetPosGL = GetRandomSpawnForCapsule(0.9,
                        0.9,
                        aroundPosGL,
                        0.01,
                        kArmoryWeaponAttachRange * 0.75,
                        EntityFilterAll(), nil)
                        
                        if targetPosGL then
                        brain:ExecuteTechId(com, kTechId.DropGrenadeLauncher, targetPosGL, com, protoToDropNear:GetId())
           
                                                                                                             -- zus�tzlicher Befehl     --orginal nur kTechId.DropJetpack
                end
            local message = string.format("I dropped supplies in our starting base!", overrideName)
            bot:SendTeamMessage(message, 10, false, true)

            end}

    end, -- Drop Jetpack und/oder Waffen

 function(bot, brain, com)

        local name = kMarineComBrainTypes[kMarineComBrainTypes.DropWeapons]
        local comTeam = com:GetTeamNumber()
        local senses = brain:GetSenses()
        local doables = senses:Get("doableTechIds")

        local weight = 0

        local armoryToDropWeaponAt
        local techIdForWeapon
        local dropPos

        local isZeroIPs = #senses:Get("activeInfantryPortals") <= 0
        local armories = senses:Get("builtArmories")
        if #armories > 0 and not isZeroIPs and not brain:GetIsProcessingTechPathOverride() then

            local bestArmoryData = senses:Get("bestArmoryForWeaponDrop")
            local isAdvanced = bestArmoryData.isAdvanced
            armoryToDropWeaponAt = bestArmoryData.armory

            if armoryToDropWeaponAt then

                local allMarines = senses:Get("marines")
                if #allMarines > 0 then

                    local weaponsTotal = 0

                    local weaponCountData = senses:Get("weaponCounts")
                    local numUpgradeableMarines = weaponCountData.numUpgradeableMarines
                    local weaponCounts = weaponCountData.counts

                    if numUpgradeableMarines > 0 then

                        local doableTechIdsForTargetArmory = {}
                        doableTechIdsForTargetArmory[kTechId.DropShotgun]         = doables[kTechId.DropShotgun]
                        doableTechIdsForTargetArmory[kTechId.DropHeavyMachineGun] = isAdvanced and doables[kTechId.DropHeavyMachineGun] ~= nil
                        doableTechIdsForTargetArmory[kTechId.DropGrenadeLauncher] = isAdvanced and doables[kTechId.DropGrenadeLauncher] ~= nil
                        doableTechIdsForTargetArmory[kTechId.DropFlamethrower]    = isAdvanced and doables[kTechId.DropFlamethrower] ~= nil

                        -- Go through and find the first valid weapon drop type
                        for _, tbl in ipairs(kDroppedWeaponDistributions) do
                            local techId = tbl.techId
                            local distMul = tbl.distribution

                            local dropTechId = kWeaponToDropTechIds[techId]

                            if doableTechIdsForTargetArmory[dropTechId] then

                                local expectedNumWeapons = math.floor(#allMarines * distMul)
                                local numMissingWeapons = expectedNumWeapons - (weaponCounts[techId] or 0)
                                local desiredDrops = math.max(0, numMissingWeapons)

                                if desiredDrops > 0 then
                                    techIdForWeapon = dropTechId

                                    local aroundPos = armoryToDropWeaponAt:GetOrigin()
                                    dropPos = GetRandomSpawnForCapsule(0.4,
                                            0.4,
                                            aroundPos,
                                            0.01,
                                            kArmoryWeaponAttachRange * 0.75,
                                            EntityFilterAll(),
                                            nil)
                                    if dropPos then
                                        weight = GetMarineComBaselineWeight(kMarineComBrainTypes.DropWeapons)
                                    end

                                    break
                                end
                            end
                        end
                    end
                end
            end
        end

        return { name = name, weight = weight,
                 perform = function(move)
                     brain:ExecuteTechId(com, techIdForWeapon, dropPos, com, armoryToDropWeaponAt:GetId())
                 end}
    end, -- Drop Weapons


    function(bot, brain, com)

        local name = "extractor"
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local isEarlyGame = sdb:Get("isEarlyGame")
        local isRPSafe = false

        local weight = 0

        local targetRP

        if not brain.hasDroppedNaturalRTs then
            brain.hasDroppedNaturalRTs = #sdb:Get("extractors") >= 3
        end

        local isZeroIPs = #sdb:Get("activeInfantryPortals") <= 0

        if doables[kTechId.Extractor] and not isZeroIPs then

            -- Auto-drop Extractors without marine presence for the first
            -- minute of a round, regardless if we've dropped natural RTs before or not
            local isEarlyGameDrop = sdb:Get("gameMinutes") <= 1

            targetRP = isEarlyGameDrop and sdb:Get("resPointToTake") or sdb:Get("resPointWithNearbyMarines")

            if targetRP then

                local enemyTeam = GetEnemyTeamNumber(com:GetTeamNumber())
                local enemyTechpoint = GetTeamBrain(enemyTeam).initialTechPointLoc
                local rpLocationName = targetRP:GetLocationName()
                local enemyNaturals = GetLocationGraph():GetNaturalRtsForTechpoint(enemyTechpoint)

                -- Avoid placing harvesters at enemy "naturals" until a certain time has passed
                local isEnemyNaturalLocation =
                rpLocationName and rpLocationName ~= "" and
                        enemyNaturals and
                        enemyNaturals:Contains(rpLocationName) and
                        sdb:Get("gameMinutes") < 5

                if not isEnemyNaturalLocation then

                    local tNow = Shared.GetTime()
                    local lastPoofTime = brain.structurePoofTimes[targetRP:GetLocationName()] or 0
                    local poofRetryDelayPassed = tNow > lastPoofTime + kPoofRetryDelay
                    local timeNextExtractorDropPassed = tNow > brain.timeNextExtractorDrop

                    if poofRetryDelayPassed and timeNextExtractorDropPassed then

                        isRPSafe = brain:GetIsSafeToDropInLocation(targetRP:GetLocationName(), bot:GetTeamNumber(), isEarlyGameDrop)
                        local extractorInfo = sdb:Get("extractorDecisionInfo")
                        local isZeroRts = extractorInfo.numExtractors <= 0
                        -- Some custom maps have 1 "natural" rt shared between two hives
                        local isRunningLowOnRts =
                        extractorInfo.numExtractors < (extractorInfo.numTPRoomsWithRts * 2) and
                                sdb:Get("numResourcePoints") * 0.5 > extractorInfo.numExtractors

                        local naturals
                        local mainLocation = brain:GetStartingTechPoint()
                        if mainLocation then
                            naturals = GetLocationGraph():GetNaturalRtsForTechpoint(mainLocation)
                        end

                        local earlyGameShouldDrop
                        if naturals then
                            earlyGameShouldDrop = naturals:Contains(targetRP:GetLocationName())
                        else
                            earlyGameShouldDrop = extractorInfo.numExtractors < 3
                        end

                        if isEarlyGameDrop then

                            if earlyGameShouldDrop then
                                -- Place two naturals when in early game, ignoring closeness of marines
                                weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildExtractor_EarlyGame)
                            end

                        elseif isRPSafe and #sdb:Get("extractors") < sdb:Get("numExtractorsForRoundTime") then

                            if isZeroRts then
                                weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildExtractor_Zero)
                            elseif isRunningLowOnRts then
                                weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildExtractor_RunningLow)
                            else
                                weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildExtractor)
                            end

                        end
                    end

                end

            end
        end

        return
        {
            name = name,
            weight = weight,
            perform = function(move)

                local success = brain:ExecuteTechId( com, kTechId.Extractor, targetRP:GetOrigin(), com )
                if success and (not isEarlyGame or not isRPSafe) then
                    brain.timeNextExtractorDrop = Shared.GetTime() + 5
                end

            end
        }
    end, -- New Extractor (Resource Tower)

    function(bot, brain, com)

        local name = "Observatory Scan"
        local scanTarget
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local time = Shared.GetTime()

        local weight = 0

        local isZeroIPs = #sdb:Get("activeInfantryPortals") <= 0
        
        if doables[kTechId.Scan] and brain.timeNextScan > time and not isZeroIPs and not brain:GetIsProcessingTechPathOverride() then
        
            local alertqueue = com:GetAlertQueue()
            
            for i, alert in ipairs(alertqueue) do
                local aTechId = alert.techId
                local targetWeight = kScanReactWeight[aTechId]
                local target
                if targetWeight and targetWeight > weight and time - alert.time < 5 and alert.entityId ~= Entity.InvalidId then
                    table.remove(alertqueue, i)
                    target = Shared.GetEntity(alert.entityId)
					if target then
						if target.GetHealthScalar then
							targetWeight = targetWeight + targetWeight * (1 - target:GetHealthScalar())
						end
						local scans = #GetEntitiesWithMixinForTeamWithinXZRange("Scan", com:GetTeamNumber(), target:GetOrigin(), Scan.kScanDistance)
						if scans <= 0 then
							local nearbyFriendlies = #GetEntitiesForTeamWithinRange("Player", com:GetTeamNumber(), target:GetOrigin(), Scan.kScanDistance*0.4)
							if nearbyFriendlies <= 0 then
								weight = targetWeight
								scanTarget = target
							end
						end
					end
                elseif time - alert.time > 5 then
                    table.remove(alertqueue, i)
                end
            end
            
            com:SetAlertQueue(alertqueue)
        end

        return
        {
            name = name,
            weight = weight,
            perform = function(move, bot, brain, com, action)
                local origin = scanTarget:GetOrigin()
                local groundTrace = Shared.TraceRay(origin + Vector(0, 10, 0),
                        origin + Vector(0, -15, 0),
                        CollisionRep.Default, PhysicsMask.CystBuild,
                        EntityFilterAllButIsa("TechPoint"))
                local sucess = brain:ExecuteTechId( com, kTechId.Scan, origin, com, scanTarget:GetId(), groundTrace)
                if sucess then
                    brain.timeNextScan = Shared.GetTime() + 15
                end
            end
        }
    end, -- Scan (Observatory)

    function(bot, brain, com)

        local name = kMarineComBrainTypes[kMarineComBrainTypes.PowerSurgePhaseGate]
        local comTeam = com:GetTeamNumber()
        local senses = brain:GetSenses()
        local doables = senses:Get("doableTechIds")

        local weight = 0

        local target
        local targetScore

        if doables[kTechId.PowerSurge] then

            local phaseGates = senses:Get("builtPhaseGates")
            for _, phaseGate in ipairs(phaseGates) do

                -- Sanity Checks
                if not HasMixin(phaseGate, "PowerConsumer") then goto continue end
                if phaseGate:GetIsPowered() then goto continue end

                local phaseGateLocation = phaseGate:GetLocationName()
                if not phaseGateLocation or phaseGateLocation == "" then goto continue end

                -- Determine the probable best target for a power surge
                local locationGroup = GetLocationContention():GetLocationGroup(phaseGateLocation)
                local numThings = locationGroup:GetNumMarines()

                if numThings > 1 and (not target or numThings > targetScore) then
                    target = phaseGate
                    targetScore = numThings
                end

                ::continue::
            end

        end

        if target then
            weight = GetMarineComBaselineWeight(kMarineComBrainTypes.PowerSurgePhaseGate)
        end

        return
        {
            name = name,
            weight = weight,
            perform =
            function(move, bot, brain, com, action)
                local targetId = target:GetId()
                brain:ExecuteTechId( com, kTechId.PowerSurge, target:GetOrigin(), com, targetId )
            end
        }

    end, -- Power surge

    function(bot, brain, com)

        local name = kMarineComBrainTypes[kMarineComBrainTypes.CatPackOrNanoShield_Player]
        local senses = brain:GetSenses()
        local comTeam = com:GetTeamNumber()
        local doables = senses:Get("doableTechIds")

        local weight = 0

        local kMinResForSupportPack = 10 -- Require tres to give catpack or nano, should be bigger than bot catpack and nano cost
        local kPerTargetSupportPackInterval = 7 -- Seconds between giving the same target another support pack
        local kPlayerSupportHealthMax = 0.6
        local kPlayerNanoTimeSinceLastHurt = 1

        local now = Shared.GetTime()
        local target
        local targetCatpack = true

        if doables[kTechId.CatPack] and not brain:GetIsProcessingTechPathOverride() then

            local catpackTargets = GetEntitiesWithMixinForTeam("CatPack", comTeam)
            for i, catPackTarget in ipairs(catpackTargets) do

                local timeLastServed = brain:GetLastSupportPackTime(catPackTarget:GetId())
                if now - timeLastServed <= kPerTargetSupportPackInterval then goto continue end
                if not catPackTarget:GetCanUseCatPack() then goto continue end
                if not HasMixin(catPackTarget, "Combat") then goto continue end
                if not HasMixin(catPackTarget, "WeaponOwner") then goto continue end
                if not HasMixin(catPackTarget, "Live") then goto continue end
                if not HasMixin(catPackTarget, "Tech") then goto continue end

                local primaryWeapon = catPackTarget:GetWeaponInHUDSlot(1)
                if primaryWeapon then

                    local mainWeaponTechId = primaryWeapon:GetTechId()
                    local lastTarget = catPackTarget:GetLastTarget()

                    if catPackTarget:GetHealthScalar() < kPlayerSupportHealthMax and
                            mainWeaponTechId and
                            kDroppedWeaponTechIds[mainWeaponTechId] and -- Must be clip weapons (for clip functions)
                            lastTarget and lastTarget:isa("Player") and
                            primaryWeapon:GetClipFraction() <= 0.15 and
                            catPackTarget:GetIsInCombat() then
                        target = catPackTarget
                        targetCatpack = true
                        break
                    end

                end

                ::continue::
            end

        end

        if doables[kTechId.NanoShield] and not target and not brain:GetIsProcessingTechPathOverride() then

            local nanoShieldTargets = GetEntitiesWithMixinForTeam("NanoShieldAble", comTeam)
            for i, nanoShieldTarget in ipairs(nanoShieldTargets) do

                local isPhaseGate = nanoShieldTarget:isa("PhaseGate")
                if not nanoShieldTarget:isa("Player") and not isPhaseGate then goto continue end
                local timeLastServed = brain:GetLastSupportPackTime(nanoShieldTarget:GetId())
                if not nanoShieldTarget:GetCanBeNanoShielded() then goto continue end
                if now - timeLastServed <= kPerTargetSupportPackInterval then goto continue end
                if not HasMixin(nanoShieldTarget, "Combat") then goto continue end
                if not HasMixin(nanoShieldTarget, "Live") then goto continue end

                local locationGroup = GetLocationContention():GetLocationGroup(nanoShieldTarget:GetLocationName())
                if not locationGroup then goto continue end

                local playerNanoCondition = not isPhaseGate
                        and nanoShieldTarget:GetHealthScalar() < kPlayerSupportHealthMax and
                        locationGroup:GetNumMarineStructures() > 0 and
                        locationGroup:GetNumMarinePlayers() > 0 and
                        nanoShieldTarget:GetIsUnderFire() and
                        nanoShieldTarget:GetLastAttacker() and nanoShieldTarget:GetLastAttacker():GetId() ~= nanoShieldTarget:GetId() and
                        nanoShieldTarget:GetLastAttacker():GetClassName() ~= "DeathTrigger" and
                        Shared.GetTime() - nanoShieldTarget:GetTimeLastDamageTaken() < kPlayerNanoTimeSinceLastHurt

                local phaseGateNanoCondition = isPhaseGate and nanoShieldTarget:GetHealthScalar() < 0.3

                if (playerNanoCondition or phaseGateNanoCondition) and nanoShieldTarget:GetIsUnderFire() then
                    target = nanoShieldTarget
                    targetCatpack = false
                    break
                end

                ::continue::
            end

        end

        if target then
            if target:isa("PhaseGate") then
                weight = GetMarineComBaselineWeight(kMarineComBrainTypes.Nanoshield_PhaseGate)
            else
                weight = GetMarineComBaselineWeight(kMarineComBrainTypes.CatPackOrNanoShield_Player)
            end
        end

        return
        {
            name = name,
            weight = weight,
            perform = function(move, bot, brain, com, action)
                local targetId = target:GetId()
                local actionTechId = targetCatpack and kTechId.CatPack or kTechId.NanoShield
                local success = brain:ExecuteTechId( com, actionTechId, target:GetOrigin(), com, targetId )
                if success then
                    brain:SetLastSupportPackTime(targetId)
                end
            end}

    end, -- Catpack or nanoshield
    
    function(bot, brain, com)

        local name = kMarineComBrainTypes[kMarineComBrainTypes.DropPacks]
        local senses = brain:GetSenses()
        local alertqueue = com:GetAlertQueue()
        local doables = senses:Get("doableTechIds")
        local hasMinimumTRes = com:GetTeamResources() >= 12

        local kAlertLifetime = 15 -- Seconds until alert is considered too old
        local kDropTrackLifetime = 5
        local kDropPackInterval = 3 -- seconds between each drop (each type seperate)

        local weight = 0

        local targetPos, targetId
        local techId
        local actualTarget

        local time = Shared.GetTime()
        local bestAlertUrgency = 0

        for i, alert in ipairs(alertqueue) do

            local alertTechId = alert.techId
            local targetTechId = kDroppackAlertToTechId[alertTechId]
            local target
            if targetTechId and time - alert.time < kAlertLifetime and doables[targetTechId] and hasMinimumTRes then

                table.remove(alertqueue, i)
                target = Shared.GetEntity(alert.entityId)

                local lastServed = brain:GetLastServedDroppackData(alert.entityId, targetTechId)
                local servedTime = lastServed.time
                local servedCount = lastServed.count
                local timeSinceLastDrop = time - servedTime

                --reset count if last served drop pack is more than x secs ago
                if servedCount > 0 and timeSinceLastDrop > kDropTrackLifetime then
                    brain:ClearLastServedDroppackData(alert.entityId, targetTechId)
                    servedCount = 0
                    servedTime = 0
                end

                if target and servedCount < 3 then
                    local alertUrgency = EvalLPF( kDroppackAlertCheckFunctions[alertTechId](target),
                            {
                                {0, 6.0},
                                {0.5, 4.0},
                                {1, 0.0},
                            })

                    if alertUrgency == 0 then
                        target = nil
                    elseif alertUrgency > bestAlertUrgency then
                        techId = targetTechId
                        bestAlertUrgency = alertUrgency
                        targetPos = target:GetOrigin() + Vector(math.random() - 0.5, 0, math.random() -0.5)
                        targetId = target:GetId()
                        actualTarget = target
                    end
                end
            end
        end

        com:SetAlertQueue(alertqueue)

        if actualTarget then

            if not brain:GetIsProcessingTechPathOverride() then
                weight = GetMarineComBaselineWeight(kMarineComBrainTypes.DropPacks)
            elseif Shared.GetTime() - brain.timeLastSavingMessage > 8 then

                local overrideName = EnumToString(kMarineTechPathOverrideType, brain.currentTechpathOverride)
                local message = string.format("I'm saving up for %s! No Meds or Ammo!", overrideName)
                bot:SendTeamMessage(message, 0, false, true)

                brain.timeLastSavingMessage = Shared.GetTime()

            end

        end

        return
        {
            name = name,
            weight = weight,
            perform = function(move, bot, brain, com, action)

                local isMedpack = techId == kTechId.MedPack
                local needsSecondMedpack = false

                -- We want to try and heal the marine to full health if possible
                if isMedpack then

                    -- includes OVER TIME heal, which might not be useful in an emergency, but 1 second is pretty quick
                    local healPerMedpack = (kMedpackHeal + kMarineRegenerationHeal)
                    local missingHP = actualTarget:GetMaxHealth() - actualTarget:GetHealth()
                    needsSecondMedpack = math.ceil(missingHP / healPerMedpack) > 1

                end

                local success = brain:ExecuteTechId( com, techId, targetPos, com, targetId )

                -- Save for later since there's a medpack pickup delay
                if needsSecondMedpack then
                    brain.secondMedpackTargets[targetId] = Shared.GetTime()
                end

                if success then
                    brain:IncrementLastServedDroppackData(targetId, techId)
                end

            end
        }
    end, -- Ammopack or Medpack

    function (bot, brain, com)

        local name = kMarineComBrainTypes[kMarineComBrainTypes.SecondMedpack]
        local senses = brain:GetSenses()
        local doables = senses:Get("doableTechIds")

        local weight = 0

        local targetToMedpack
        local targetPos

        if doables[kTechId.MedPack] and not brain:GetIsProcessingTechPathOverride() then

            local entsToRemove = {}

            for entId, timeLastServed in pairs(brain.secondMedpackTargets) do

                local ent = Shared.GetEntity(entId)
                if ent then

                    local canUseMedpack, isCooldown = GetEntityCanUseMedpack(ent)
                    local shouldRemoveEnt = canUseMedpack or (not canUseMedpack and not isCooldown)

                    if shouldRemoveEnt then
                        table.insert(entsToRemove, entId)
                    end

                    if canUseMedpack then
                        targetToMedpack = entId
                        targetPos = ent:GetOrigin() + Vector(math.random() - 0.5, 0, math.random() -0.5)
                        weight = GetMarineComBaselineWeight(kMarineComBrainTypes.SecondMedpack)
                        break
                    end

                end

            end

            -- Cleanup
            for _, entId in ipairs(entsToRemove) do
                brain.secondMedpackTargets[entId] = nil
            end

        end

        return
        {
            name = name,
            weight = weight,
            perform = function(move, bot, brain, com, action)
                brain:ExecuteTechId( com, kTechId.MedPack, targetPos, com, targetToMedpack )
            end
        }

    end, -- Second Medpack

    function(bot, brain, com)
        local name = kMarineComBrainTypes[kMarineComBrainTypes.BuildAndManageMACs]
        local comTeam = com:GetTeamNumber()
        local senses = brain:GetSenses()
        local doables = senses:Get("doableTechIds")
        local macs = senses:Get("macs")
        local structures = doables[kTechId.MAC]
        local hasMinimumTRes = com:GetTeamResources() >= 35

        local kMaxMacs = 4
        local kMacManageInterval = 5

        local weight = 0
        local macBuildStructure

        -- Manage MACs (Regardless of weight)
        if Shared.GetTime() - brain.timeLastMACManage > kMacManageInterval then
            brain.timeLastMACManage = Shared.GetTime()
        
            for _, mac in ipairs(macs) do
                if not mac:GetHasOrder() then
                    local marines = GetEntitiesForTeamWithinRange("Player", comTeam, mac:GetOrigin(), MAC.kOrderScanRadius * 1.5)
                    for _, marine in ipairs(marines) do
                        if not GetIsWeldedByOtherMAC(mac, marine) then
                            mac:GiveOrder(kTechId.FollowAndWeld, marine:GetId(), marine:GetOrigin(), nil, true, true)
                        end
                    end
                end
            end
        end

        if structures and #macs < kMaxMacs and hasMinimumTRes and not brain:GetIsProcessingTechPathOverride() then
            macBuildStructure = structures[ math.random(#structures) ]
            weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildAndManageMACs)
        end

        return { name = name, weight = weight,
            perform = function(move)
                brain:ExecuteTechId( com, kTechId.MAC, Vector(0,0,0), macBuildStructure )
            end}
    end, -- MACs (Assign to Weld Player or build them)

    --[[
    function(bot, brain)

        local name = "handle_arcing"
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0.0
        local coms = doables[techId]
        local marines = sdb:Get("marines")
        local team = bot:GetPlayer():GetTeam()
        local targetCommand
        
        if doables[kTechId.PhaseGate] then
            
            -- find enemy command structures (kinda cheaty but human players know where structures are...)
            local enemyCommmands = sdb:Get("enemyCommandWithNearbyMarines")
            
            local command = data.command
            
            local dist = data.dist
            if command ~= nil and dist and dist < kARCRange + 10 then
                targetCommand = command
                weight = EvalLPF(dist,
                    {
                        {0, 0.0},
                        {18, 0.0},
                        {20, 4.0}, -- arc range is 26
                        })
            end
            
        end
        if weight > 0 then
            
            
        end
        
        return { name = name, weight = weight,
            perform = function(move)

                if mainHost then
                    local pos = GetRandomBuildPosition( techId, mainHost:GetOrigin(), techpointDist )
                    if pos ~= nil then
                        brain:ExecuteTechId( com, techId, pos, com )
                    end
                end

            end }
    end,
]] -- ARC

    function(bot, brain)

        return
        {
            name = kMarineComBrainTypes[kMarineComBrainTypes.Idle],
            weight = GetMarineComBaselineWeight(kMarineComBrainTypes.Idle),
            perform = function(move, bot, brain, com, action)
                if brain.debug then
                    DebugPrint("idling..")
                end 
            end
        }
    end -- Idle
}
