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
    "PowerSurge",
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
    "BuildRoboticsFactory_NearMainCommandStation",

    "BuildPhaseGate_NearControlledTechPoint", -- 3: Controlled TechPoint (Friendly players are near)
    "BuildCommandStation_NearControlledTechPoint",
    "BuildPhaseGate_NearDoubleResPoints",
    "ResearchUpgrades",

    "ObservatoryScan_BaseStructure",
    "ObservatoryScan_Extractor",
    "ShadeScan",

    "BuildExtractor",

    -- Embolden secondary bases
    "BuildPhaseGate_NearStation",
    "BuildObservatory_OtherCS",
    "BuildInfantryPortal_OtherCS",

    -- Embolden phase gate positions
    "BuildArmory_NearPhaseGate",
    "BuildObservatory_NearPG",
    "BuildCommandStation_NearPhaseGate",
    --"BuildPrototypeLab_NearPhaseGate",

    -- Extra $$$
    "DropWeapons",
    "DropJetpack",
    "DropMines",
    "DropWelder",
    "BuildAndManageMACs",
    "BuildAndCommandARCs",
    "AttackOrder",
    "BuildOrder",
    "WeldOrder",
    "MoveOrderOnFreeTechpoints",
    "DefendARCs",

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
kPoofRetryDelay = 10 -- How often to try to re-drop a structure that has been poofed (any structure, in a location with same name orginal = 10)

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

    -- Standard: volle Ammo
    local ammoPercentage = 1

    -- Alle Waffen prüfen, nicht nur die aktive
    local weapons = target:GetWeapons()

    for i = 1, #weapons do
        local w = weapons[i]

        if w:isa("ClipWeapon") then
            local max = w:GetMaxAmmo()
            if max > 0 then
                local frac = w:GetAmmo() / max
                if frac < ammoPercentage then
                    ammoPercentage = frac
                end
            end
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

local function GetIsAssignedToOtherMarine(self, target)
    if target then
        for _, marine in ipairs(GetEntitiesForTeam("Marine", self:GetTeamNumber())) do
            if self ~= marine then

                -- Direkt zugewiesenes Ziel
                if marine.assignedTargetId ~= nil and Shared.GetEntity(marine.assignedTargetId) == target then
                    return true
                end

                -- Order-Ziel prüfen
                local currentOrder = marine:GetCurrentOrder()
                local orderTarget
                if currentOrder and currentOrder:GetParam() ~= nil then
                    orderTarget = Shared.GetEntity(currentOrder:GetParam())
                end

                -- HIER Attack hinzugefügt
                if currentOrder
                   and orderTarget == target
                   and (
                        currentOrder:GetType() == kTechId.Construct
                        or currentOrder:GetType() == kTechId.Move
                        or currentOrder:GetType() == kTechId.Defend
                        or currentOrder:GetType() == kTechId.Weld
                        or currentOrder:GetType() == kTechId.Attack   -- ? hinzugefügt
                   )
                then
                    return true
                end
            end
        end
    end
    return false
end


local function GetIsAssignedToOtherExo(self, target)
    if target then
        for _, exo in ipairs(GetEntitiesForTeam("Exo", self:GetTeamNumber())) do
            if self ~= exo then
                if exo.assignedTargetId ~= nil and Shared.GetEntity(exo.assignedTargetId) == target then
                    return true
                end
                local currentOrder = exo:GetCurrentOrder()
                local orderTarget
                if currentOrder and currentOrder:GetParam() ~= nil then
                    orderTarget = Shared.GetEntity(currentOrder:GetParam())
                end
                if currentOrder and orderTarget == target then
                    local orderType = currentOrder:GetType()
                    if orderType == kTechId.Move or orderType == kTechId.Attack or orderType == kTechId.Defend then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function GetIsAssignedToOtherARC(self, target)
    if target then
        for _, arc in ipairs(GetEntitiesForTeam("ARC", self:GetTeamNumber())) do
            if self ~= arc then
                if arc.assignedTargetId ~= nil and Shared.GetEntity(arc.assignedTargetId) == target then
                    return true
                end
                local currentOrder = arc:GetCurrentOrder()
                local orderTarget
                if currentOrder and currentOrder:GetParam() ~= nil then
                    orderTarget = Shared.GetEntity(currentOrder:GetParam())
                end
                if currentOrder and orderTarget == target and (currentOrder:GetType() == kTechId.Move or currentOrder:GetType() == kTechId.Attack or currentOrder:GetType() == kTechId.Stop) then
                    return true
                end
            end
        end
    end
    return false
end

function GetNearestHive(position)
    local hives = GetEntitiesWithinRange("Hive", position, 200, true)
    local nearestHive = nil
    local nearestDistance = math.huge
    for _, hive in ipairs(hives) do
        local distance = (hive:GetOrigin() - position):GetLength()
        if distance < nearestDistance then
            nearestDistance = distance
            nearestHive = hive
        end
    end
    return nearestHive
end

local function FindBuildPosition(techId, origin, initialDist, maxDist, increment)
    local buildPos = nil
    local angleIncrement = math.pi / 32 -- Noch kleinere Inkremente fï¿½r den Winkel

    while not buildPos do
        for radius = initialDist, maxDist, increment do
            for angle = 0, 2 * math.pi, angleIncrement do
                local xOffset = radius * math.cos(angle)
                local zOffset = radius * math.sin(angle)
                local tryPos = Vector(origin.x + xOffset, origin.y, origin.z + zOffset)

                buildPos = GetRandomBuildPosition(techId, tryPos, increment)
                if buildPos then
                    return buildPos
                end
            end
        end

    end

    return buildPos
end

local function HasCCInRoom(obs, team)
    local ccs = GetEntitiesAliveForTeam("CommandStation", team)
    for _, cc in ipairs(ccs) do
        if cc:GetLocationName() == obs:GetLocationName() then
            return true
        end
    end
    return false
end

-----------------------------------------
-- Shared helper functions for drops
-----------------------------------------

local lastMineDropTime = 0   -- GLOBAL / OUTSIDE FUNCTION!

local MAX_DROP_DISTANCE = 20

function IsNearMainBase(marine, mainCS)
    if not mainCS then return false end
    local d = (marine:GetOrigin() - mainCS:GetOrigin()):GetLength()
    return d <= MAX_DROP_DISTANCE
end

function IsAdvancedMarine(m)
    return m:GetWeapon(Shotgun.kMapName)
        or m:GetWeapon(Flamethrower.kMapName)
        or m:GetWeapon(HeavyMachineGun.kMapName)
        or m:GetWeapon(GrenadeLauncher.kMapName)
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

-- Build Command Station Near Controlled Tech Point
function(bot, brain, com)
    local name = kMarineComBrainTypes[kMarineComBrainTypes.BuildCommandStation_NearControlledTechPoint]
    local senses = brain:GetSenses()
    local comTeam = com:GetTeamNumber()
    local doables = senses:Get("doableTechIds")

    local weight = 0
    local buildPos
    local isZeroIPs = #senses:Get("activeInfantryPortals") <= 0

    if doables[kTechId.CommandStation] and not isZeroIPs and senses:Get("mainPhaseGate") and #senses:Get("phaseGates") then
        local emptyTechPoints = senses:Get("safeTechPoints")
        for _, techPoint in ipairs(emptyTechPoints) do
            local phaseGates = GetEntitiesForTeamByLocation("PhaseGate", comTeam, techPoint:GetLocationId())
            if #phaseGates <= 0 then
                buildPos = FindBuildPosition(kTechId.CommandStation, techPoint:GetOrigin(), 3, 20, 1)
                if buildPos then
                    weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildCommandStation_NearControlledTechPoint)
                    break
                end
            end
        end
    end

    return {
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

    local kMaxPhaseGates = 8

    local weight = 0
    local buildPos
    local isZeroIPs = #senses:Get("activeInfantryPortals") <= 0

    if doables[kTechId.PhaseGate] and not isZeroIPs and senses:Get("mainPhaseGate") and #senses:Get("phaseGates") < kMaxPhaseGates then
        local emptyTechPoints = senses:Get("safeTechPoints")
        for _, techPoint in ipairs(emptyTechPoints) do
            local phaseGates = GetEntitiesForTeamByLocation("PhaseGate", comTeam, techPoint:GetLocationId())
            if #phaseGates <= 0 then
                buildPos = FindBuildPosition(kTechId.PhaseGate, techPoint:GetOrigin(), 3, 20, 1)
                if buildPos then
                    weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildPhaseGate_NearControlledTechPoint)
                    break
                end
            end
        end
    end

    return {
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
    local name = kMarineComBrainTypes[kMarineComBrainTypes.BuildCommandStation_NearControlledTechPoint]
    local senses = brain:GetSenses()
    local comTeam = com:GetTeamNumber()
    local doables = senses:Get("doableTechIds")

    local weight = 0
    local buildPos
    local isZeroIPs = #senses:Get("activeInfantryPortals") <= 0

    if doables[kTechId.CommandStation] and not isZeroIPs and senses:Get("mainPhaseGate") and #senses:Get("phaseGates") then
        local emptyTechPoints = senses:Get("safeTechPoints")
        for _, techPoint in ipairs(emptyTechPoints) do
            local commandstations = GetEntitiesForTeamByLocation("CommandStation", comTeam, techPoint:GetLocationId())
            if #commandstations <= 0 then
                -- Position des TechPoints direkt verwenden
                buildPos = techPoint:GetOrigin()
                if buildPos then
                    weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildCommandStation_NearControlledTechPoint)
                    break
                end
            end
        end
    end

    return {
        name = name,
        weight = weight,
        perform = function(move, bot, brain, player, action)
            if buildPos then
                brain:ExecuteTechId(com, kTechId.CommandStation, buildPos, com)
            end
        end
    }
end, -- Build CommandStation (Near PhaseGate)
    
function(bot, brain, com)
    local name = kMarineComBrainTypes[kMarineComBrainTypes.BuildPhaseGate_NearDoubleResPoints]
    local senses = brain:GetSenses()
    local comTeam = com:GetTeamNumber()
    local doables = senses:Get("doableTechIds")
    local weight = 0
    local buildPos
    local buildRange = 5
    local extendedCheckRange = 30
    local isZeroIPs = #senses:Get("activeInfantryPortals") <= 0

    if doables[kTechId.PhaseGate] and not isZeroIPs then
        local doubleResPoints = senses:Get("doubleResPoints")

        for _, pair in ipairs(doubleResPoints) do
            -- Prï¿½fe den Midpoint
            local midPoint = (pair[1]:GetOrigin() + pair[2]:GetOrigin()) * 0.5
            local midOffsets = {Vector(0, 5, 0), Vector(5, 0, 5), Vector(-5, 0, -5)}
            for _, offset in ipairs(midOffsets) do
                local potentialBuildPos = midPoint + offset
                local existingPhaseGates = GetEntitiesForTeamWithinRange("PhaseGate", comTeam, potentialBuildPos, extendedCheckRange)
                local observatories = GetEntitiesForTeamWithinRange("Observatory", comTeam, potentialBuildPos, extendedCheckRange)
                local isSafe = brain:GetIsSafeToDropInLocation(pair[1]:GetLocationName(), comTeam, false) and
                               brain:GetIsSafeToDropInLocation(pair[2]:GetLocationName(), comTeam, false)

                if #existingPhaseGates == 0 and #observatories == 0 and isSafe then
                    local validBuildPos = GetRandomBuildPosition(kTechId.PhaseGate, potentialBuildPos, buildRange)
                    if validBuildPos then
                        buildPos = validBuildPos
                        weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildPhaseGate_NearDoubleResPoints)
                        break
                    end
                end
            end

            if buildPos then break end

            -- Prï¿½fe ResPoint 1
            local res1Offsets = {Vector(0, 5, 0), Vector(5, 0, 5), Vector(-5, 0, -5)}
            for _, offset in ipairs(res1Offsets) do
                local potentialBuildPos = pair[1]:GetOrigin() + offset
                local existingPhaseGates = GetEntitiesForTeamWithinRange("PhaseGate", comTeam, potentialBuildPos, extendedCheckRange)
                local observatories = GetEntitiesForTeamWithinRange("Observatory", comTeam, potentialBuildPos, extendedCheckRange)
                local isSafe = brain:GetIsSafeToDropInLocation(pair[1]:GetLocationName(), comTeam, false)

                if #existingPhaseGates == 0 and #observatories == 0 and isSafe then
                    local validBuildPos = GetRandomBuildPosition(kTechId.PhaseGate, potentialBuildPos, buildRange)
                    if validBuildPos then
                        buildPos = validBuildPos
                        weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildPhaseGate_NearDoubleResPoints)
                        break
                    end
                end
            end

            if buildPos then break end

            -- Prï¿½fe ResPoint 2
            local res2Offsets = {Vector(0, 5, 0), Vector(5, 0, 5), Vector(-5, 0, -5)}
            for _, offset in ipairs(res2Offsets) do
                local potentialBuildPos = pair[2]:GetOrigin() + offset
                local existingPhaseGates = GetEntitiesForTeamWithinRange("PhaseGate", comTeam, potentialBuildPos, extendedCheckRange)
                local observatories = GetEntitiesForTeamWithinRange("Observatory", comTeam, potentialBuildPos, extendedCheckRange)
                local isSafe = brain:GetIsSafeToDropInLocation(pair[2]:GetLocationName(), comTeam, false)

                if #existingPhaseGates == 0 and #observatories == 0 and isSafe then
                    local validBuildPos = GetRandomBuildPosition(kTechId.PhaseGate, potentialBuildPos, buildRange)
                    if validBuildPos then
                        buildPos = validBuildPos
                        weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildPhaseGate_NearDoubleResPoints)
                        break
                    end
                end
            end

            if buildPos then break end
        end
    end

    return {
        name = name,
        weight = weight,
        perform = function(move, bot, brain, player, action)
            if buildPos then
                brain:ExecuteTechId(com, kTechId.PhaseGate, buildPos, com)
            end
        end
    }
end, --DOUBLE RESNODE PHASEGATE
    
function(bot, brain, com)
    local name = kMarineComBrainTypes[kMarineComBrainTypes.BuildRoboticsFactory_NearMainCommandStation]
    local comTeam = com:GetTeamNumber()
    local senses = brain:GetSenses()
    local doables = senses:Get("doableTechIds")
    local hasMinimumTRes = com:GetTeamResources() >= 35
    local kMaxRoboticsFactories = 1
    local weight = 0
    local buildPos
    local mainBaseLocationId = brain:GetStartingLocationId()

    -- ï¿½berprï¿½fen, ob aktive Infantry Portals vorhanden sind
    local isZeroIPs = #senses:Get("activeInfantryPortals") <= 0

    -- Fortfahren, wenn die Bedingungen erfï¿½llt sind
    if doables[kTechId.RoboticsFactory] and hasMinimumTRes and not isZeroIPs and not brain:GetIsProcessingTechPathOverride() and mainBaseLocationId ~= 0 then
        -- Vorhandene Robotics Factories in der Startbasis ï¿½berprï¿½fen
        local roboticsfactories = GetEntitiesForTeamByLocation("RoboticsFactory", comTeam, mainBaseLocationId)
        if #roboticsfactories < kMaxRoboticsFactories then
            -- Bauposition in der Nï¿½he der Command Station in der Startbasis erhalten
            local commandStations = GetEntitiesForTeamByLocation("CommandStation", comTeam, mainBaseLocationId)
            for _, cs in ipairs(commandStations) do
                if cs:GetLocationId() == mainBaseLocationId then
                    buildPos = GetRandomBuildPosition(kTechId.RoboticsFactory, cs:GetOrigin(), kPhaseBuildDist)
                    if buildPos and hasMinimumTRes and
                       brain:GetIsSafeToDropInLocation(cs:GetLocationName(), com:GetTeamNumber(), senses:Get("isEarlyGame")) and
                       #GetEntitiesAliveForTeamWithinRange("Marine", com:GetTeamNumber(), buildPos, kMarinesNearbyRange) > 0 then

                        -- Gewicht setzen, um die Robotics Factory zu bauen
                        weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildRoboticsFactory_NearMainCommandStation)
                        break
                    end
                end
            end
        end
    end

    return {
        name = name,
        weight = weight,
        perform = function(move)
            if buildPos then
                brain:ExecuteTechId(com, kTechId.RoboticsFactory, buildPos, com)
            end
        end
    }
end,  --Build RoboticsFactory (Near Main CommandStation) --]]
    
 function(bot, brain, com)
    PROFILE("MarineComBrain:BuildObservatory")
    local name = kMarineComBrainTypes[kMarineComBrainTypes.BuildObservatory]
    local comTeam = com:GetTeamNumber()
    local senses = brain:GetSenses()
    local doables = senses:Get("doableTechIds")
    local weight = 0
    local kMaxForwardObservatories = 2 -- Not including main base observatory
    local buildPos
    local forwardObs = senses:Get("forwardObservatories")
    local canPlaceMoreForwardObs = #forwardObs < kMaxForwardObservatories
    local mainBaseLocationId = brain:GetStartingLocationId()
    local isZeroIPs = #senses:Get("activeInfantryPortals") <= 0
    local distanceThreshold = 15  -- Definieren der Distanzschwelle

    if doables[kTechId.Observatory] and not isZeroIPs and not brain:GetIsProcessingTechPathOverride() and canPlaceMoreForwardObs and mainBaseLocationId ~= 0 and not senses:Get("isEarlyGame") then
        local phaseGates = senses:Get("builtPhaseGates")
        local doubleResPoints = senses:Get("doubleResPoints")

        for _, pg in ipairs(phaseGates) do
            local pgLocationId = pg:GetLocationId()
            local isDoubleResNode = false

            -- ï¿½berprï¿½fen, ob das PhaseGate in der Nï¿½he von Double ResPoints liegt
            for _, pair in ipairs(doubleResPoints) do
                local midPoint = (pair[1]:GetOrigin() + pair[2]:GetOrigin()) * 0.5
                local distanceToMidPoint = (pg:GetOrigin() - midPoint):GetLength()
                if distanceToMidPoint <= distanceThreshold then
                    isDoubleResNode = true
                    break
                end
            end

            if pgLocationId ~= 0 and pgLocationId ~= mainBaseLocationId and not isDoubleResNode and
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

    return {
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

    local doables       = senses:Get("doableTechIds") or {}
    local ccs           = senses:Get("builtCommandStations") or {}
    local observatories = senses:Get("Observatorys") or {}
    local memories      = GetTeamMemories(com:GetTeamNumber()) or {}
    local phaseGates    = GetEntitiesAliveForTeam("PhaseGate", com:GetTeamNumber()) or {}
    local powerPoints   = GetEntitiesAliveForTeam("PowerPoint", com:GetTeamNumber()) or {}

    local weight = 0
    local obsToUse

    -------------------------------------------------------------------------
    -- HP-REGELN
    -------------------------------------------------------------------------
    local hpBeaconRules = {
        {
            name = "Observatory",
            entities = function() return observatories end,
            hpThreshold = 0.60,
            marineRange = 25,
            enemyRange = 20,
        },
        {
            name = "PowerPoint",
            entities = function() return powerPoints end,
            hpThreshold = 0.50,
            marineRange = 35,
            enemyRange = 50,
        },
        {
            name = "PhaseGate",
            entities = function() return phaseGates end,
            hpThreshold = 0.40,
            marineRange = 25,
            enemyRange = 20,
        },
        {
            name = "ArmsLab",
            entities = function() return GetEntitiesAliveForTeam("ArmsLab", com:GetTeamNumber()) end,
            hpThreshold = 0.50,
            marineRange = 25,
            enemyRange = 20,
        },
        {
            name = "InfantryPortal",
            entities = function() return GetEntitiesAliveForTeam("InfantryPortal", com:GetTeamNumber()) end,
            hpThreshold = 0.50,
            marineRange = 25,
            enemyRange = 20,
        },
        {
            name = "PrototypeLab",
            entities = function() return GetEntitiesAliveForTeam("PrototypeLab", com:GetTeamNumber()) end,
            hpThreshold = 0.40,
            marineRange = 25,
            enemyRange = 20,
        },
        {
            name = "Armory",
            entities = function() return GetEntitiesAliveForTeam("Armory", com:GetTeamNumber()) end,
            hpThreshold = 0.40,
            marineRange = 25,
            enemyRange = 20,
        },
        {
            name = "AdvancedArmory",
            entities = function()
                local list = GetEntitiesAliveForTeam("Armory", com:GetTeamNumber())
                local result = {}
                for _, ent in ipairs(list) do
                    if ent:GetTechId() == kTechId.AdvancedArmory then
                        table.insert(result, ent)
                    end
                end
                return result
            end,
            hpThreshold = 0.50,
            marineRange = 25,
            enemyRange = 20,
        },
        {
            name = "RoboticsFactory",
            entities = function()
                local list = GetEntitiesAliveForTeam("RoboticsFactory", com:GetTeamNumber())
                local result = {}
                for _, ent in ipairs(list) do
                    local techId = ent:GetTechId()
                    if techId == kTechId.RoboticsFactory or techId == kTechId.ARCRoboticsFactory then
                        table.insert(result, ent)
                    end
                end
                return result
            end,
            hpThreshold = 0.50,
            marineRange = 25,
            enemyRange = 20,
        }
    }

    -------------------------------------------------------------------------
    -- BEACON LOGIK START
    -------------------------------------------------------------------------
    if doables[kTechId.DistressBeacon] and (not brain.nextBeaconTime or brain.nextBeaconTime < Shared.GetTime()) then

        ---------------------------------------------------------------------
        -- CC-HP-BEACON
        ---------------------------------------------------------------------
        for _, cc in ipairs(ccs) do

            if cc:GetHealthFraction() < 0.45 then

                -- Marines + Exos berücksichtigen
                local marinesNearCC = GetEntitiesForTeamWithinRange("Marine", com:GetTeamNumber(), cc:GetOrigin(), 20)
                local exosNearCC    = GetEntitiesForTeamWithinRange("Exo", com:GetTeamNumber(), cc:GetOrigin(), 20)

                local friendlyNearCC = {}
                for _, m in ipairs(marinesNearCC) do table.insert(friendlyNearCC, m) end
                for _, e in ipairs(exosNearCC) do table.insert(friendlyNearCC, e) end

                local enemiesNearCC = 0

                for _, mem in ipairs(memories) do
                    local target = Shared.GetEntity(mem.entId)
                    if target and HasMixin(target, "Live") and target:GetIsAlive() and target:GetTeamNumber() ~= com:GetTeamNumber() then
                        local dist = cc:GetOrigin():GetDistance(mem.lastSeenPos)
                        if dist < 20 then
                            enemiesNearCC = enemiesNearCC + 1
                        end
                    end
                end

                if #friendlyNearCC == 0 and enemiesNearCC > 0 then

                    Shared.SortEntitiesByDistance(cc:GetOrigin(), observatories)

                    for _, obs in ipairs(observatories) do
                        if GetIsUnitActive(obs) and obs:GetIsPowered() then

                            local nearest = GetNearest(obs:GetOrigin(), "CommandStation", com:GetTeamNumber(),
                                function(ent) return ent:GetIsBuilt() and ent:GetIsAlive() end)

                            if nearest == cc then

                                if HasCCInRoom(obs, com:GetTeamNumber())
                                and cc:GetLocationName() == obs:GetLocationName() then

                                    bot:SendTeamMessage(string.format("Command Station in trouble at %s! Beacon imminent!", cc:GetLocationName()), 10, false, true)

                                    obsToUse = obs
                                    weight = GetMarineComBaselineWeight(kMarineComBrainTypes.Beacon)
                                end

                                break
                            end
                        end
                    end
                end
            end
        end

        ---------------------------------------------------------------------
        -- GENERISCHER HP-CHECK FÜR ALLE STRUKTUREN (MIT RAUM-FIX)
        ---------------------------------------------------------------------
        for _, rule in ipairs(hpBeaconRules) do
            local ents = rule.entities() or {}

            for _, ent in ipairs(ents) do

                if ent:GetIsAlive() and ent:GetHealthFraction() < rule.hpThreshold then

                    -- Marines + Exos berücksichtigen
                    local marines = GetEntitiesForTeamWithinRange("Marine", com:GetTeamNumber(), ent:GetOrigin(), rule.marineRange)
                    local exos    = GetEntitiesForTeamWithinRange("Exo", com:GetTeamNumber(), ent:GetOrigin(), rule.marineRange)

                    local friendly = {}
                    for _, m in ipairs(marines) do table.insert(friendly, m) end
                    for _, e in ipairs(exos) do table.insert(friendly, e) end

                    local enemies = 0
                    for _, mem in ipairs(memories) do
                        local target = Shared.GetEntity(mem.entId)
                        if target and HasMixin(target, "Live") and target:GetIsAlive()
                           and target:GetTeamNumber() ~= com:GetTeamNumber() then

                            local dist = ent:GetOrigin():GetDistance(mem.lastSeenPos)
                            if dist < rule.enemyRange then
                                enemies = enemies + 1
                            end
                        end
                    end

                    if #friendly == 0 and enemies > 0 then

                        for _, obs in ipairs(observatories) do

                            if GetIsUnitActive(obs) and obs:GetIsPowered() then

                                if HasCCInRoom(obs, com:GetTeamNumber()) then

                                    if ent:GetLocationName() == obs:GetLocationName() then

                                        local loc = ent:GetLocationName()

                                        bot:SendTeamMessage(string.format("Base in trouble at %s, I trigger the beacon!", loc), 10, false, true)

                                        obsToUse = obs
                                        weight = GetMarineComBaselineWeight(kMarineComBrainTypes.Beacon)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -------------------------------------------------------------------------
    -- GLOBALER FIX: OBS MUSS powered sein
    -------------------------------------------------------------------------
    if not obsToUse or not obsToUse:GetIsPowered() then
        weight = 0
    end

    return {
        name = name,
        weight = weight,
        perform = function(move)
            if obsToUse then
                local success = brain:ExecuteTechId(com, kTechId.DistressBeacon, Vector(0, 0, 0), obsToUse)
                if success then
                    brain.nextBeaconTime = Shared.GetTime() + 20
                end
            end
        end
    }
end, -- Beacon (Mass Recall)

function(bot, brain, com)
    local name   = kMarineComBrainTypes[kMarineComBrainTypes.DropJetpack]
    local senses = brain:GetSenses()
    local comTeam = com:GetTeamNumber()
    local res     = com:GetTeamResources()

    local doables   = senses:Get("doableTechIds")
    local prototypeLabs = senses:Get("builtPrototypeLabs")
    local isZeroIPs = #senses:Get("activeInfantryPortals") <= 0
    local hasArcFactory = senses:Get("hasUpgradedRoboticsFactory")
    local mainCS = senses:Get("mainCommandStation")

    if #prototypeLabs == 0 or isZeroIPs or brain:GetIsProcessingTechPathOverride() then
        return { name = name, weight = 0, perform = function() end }
    end

    local numExtractors = #senses:Get("extractors")
    if numExtractors < 4 then
        return { name = name, weight = 0, perform = function() end }
    end

    local advCandidates, rifleCandidates = {}, {}
    for _, m in ipairs(senses:Get("nonJPMarines")) do
        local hasAdvanced =
            m:GetWeapon(Shotgun.kMapName) or
            m:GetWeapon(GrenadeLauncher.kMapName) or
            m:GetWeapon(HeavyMachineGun.kMapName) or
            m:GetWeapon(Flamethrower.kMapName)

        if hasAdvanced and IsNearMainBase(m, mainCS) then
            table.insert(advCandidates, m)
        elseif m:GetWeapon(Rifle.kMapName) and IsNearMainBase(m, mainCS) then
            table.insert(rifleCandidates, m)
        end
    end

    local finalCandidates = {}
    if hasArcFactory ~= nil then
        if res >= 51 then
            for _, m in ipairs(advCandidates) do table.insert(finalCandidates, m) end
        end
        if res >= 55 and numExtractors >= 7   then
            for _, m in ipairs(rifleCandidates) do table.insert(finalCandidates, m) end
        end
    else
        if res >= 41 then
            for _, m in ipairs(advCandidates) do table.insert(finalCandidates, m) end
        end
        if res >= 45 then
            for _, m in ipairs(rifleCandidates) do table.insert(finalCandidates, m) end
        end
    end

    if #finalCandidates == 0 then
        return { name = name, weight = 0, perform = function() end }
    end

    local protoToDropNear = prototypeLabs[math.random(#prototypeLabs)]
    local weight = GetMarineComBaselineWeight(kMarineComBrainTypes.DropJetpack)

    return {
        name = name,
        weight = weight,
        perform = function(move)
            local actualDrops = 0

            -- Begrenzung: maximal 4 Jetpacks insgesamt
            local jetpacks = GetEntitiesForTeam("Jetpack", comTeam)
            local availableSlots = 1 - #jetpacks
            if availableSlots <= 0 then
                return
            end

            -- pro Entscheidung maximal 2
            local plannedDrops = math.min(#finalCandidates, 2, availableSlots)

            for i = 1, plannedDrops do
                local target = finalCandidates[i]
                if target and target:GetIsAlive() then
                    local aroundPos = protoToDropNear:GetOrigin()
                    local dropPos = GetRandomSpawnForCapsule(
                        0.6, 0.6, aroundPos, 0.5, 2.5, EntityFilterAll(), nil
                    )
                    if dropPos then
                        brain:ExecuteTechId(com, kTechId.DropJetpack, dropPos, com, protoToDropNear:GetId())
                        actualDrops = actualDrops + 1
                    end
                end
            end
                local loc = protoToDropNear:GetLocationName()

                if actualDrops > 0 then
                    bot:SendTeamMessage(string.format("Dropped %d Jetpack(s) at %s!", actualDrops, loc), 10, false, true)
                end

        end
    }
end, -- Drop Jetpack

--Waffendrop funktioniert nun. Meine Version ist besser! ;-)

function(bot, brain, com)
    local name   = kMarineComBrainTypes[kMarineComBrainTypes.DropWeapons]
    local senses = brain:GetSenses()
    local comTeam = com:GetTeamNumber()
    local res     = com:GetTeamResources()

    local doables   = senses:Get("doableTechIds")
    local armories  = senses:Get("builtArmories")
    local isZeroIPs = #senses:Get("activeInfantryPortals") <= 0

    if #armories == 0 or isZeroIPs or brain:GetIsProcessingTechPathOverride() then
        return { name = name, weight = 0, perform = function() end }
    end

    local numExtractors = #senses:Get("extractors")
    if numExtractors < 4 then
        return { name = name, weight = 0, perform = function() end }
    end
    
    ----------------------------------------------------------------------
    -- LIMITER: Nur 1 Waffe gleichzeitig am Boden
    ----------------------------------------------------------------------
local groundWeapons = senses:Get("groundWeapons")

if #groundWeapons > 0 then
    return { name = name, weight = 0, perform = function() end }
end

    -- Robotics Factory entfernt; nur ARC Factory abgefragt
    local upgradedFactory = senses:Get("hasUpgradedRoboticsFactory")
    local mainCS = senses:Get("mainCommandStation")

    -- Prüfen, ob überhaupt eine erlaubte Waffe gedropped werden darf
    local hasAdvanced = senses:Get("hasAdvancedArmory") == true
    local anyAllowed = false

    for techId, dropTechId in pairs(kWeaponToDropTechIds) do
        -- Shotgun darf immer, wenn doable
        if dropTechId == kTechId.DropShotgun and doables[dropTechId] then
            anyAllowed = true
            break
        end

        -- GL / FT / HMG nur mit Advanced Armory
        if hasAdvanced and doables[dropTechId] then
            anyAllowed = true
            break
        end
    end

    -- Kandidaten sammeln
    local jpRifleCandidates, rifleOnlyCandidates = {}, {}
    for _, m in ipairs(GetEntitiesForTeam("Player", comTeam)) do
        if m:isa("JetpackMarine") and m:GetWeapon(Rifle.kMapName)
            and IsNearMainBase(m, mainCS) then
            table.insert(jpRifleCandidates, m)
        end
    end
    for _, m in ipairs(senses:Get("nonJPMarines")) do
        if m:GetWeapon(Rifle.kMapName)
            and IsNearMainBase(m, mainCS) then
            table.insert(rifleOnlyCandidates, m)
        end
    end

    local finalCandidates = {}
    if upgradedFactory ~= nil then
        if res >= 51 then
            for _, m in ipairs(jpRifleCandidates) do table.insert(finalCandidates, m) end
        end
        if res >= 57 and numExtractors >= 7 then
            for _, m in ipairs(rifleOnlyCandidates) do table.insert(finalCandidates, m) end
        end
    else
        -- Kein ARC Factory: 42-Res-Drop weiterhin erlaubt
        if res >= 42 then
            for _, m in ipairs(jpRifleCandidates) do table.insert(finalCandidates, m) end
            for _, m in ipairs(rifleOnlyCandidates) do table.insert(finalCandidates, m) end
        end
    end

    -- WICHTIG: erst jetzt prüfen, ob überhaupt Waffen erlaubt UND Kandidaten vorhanden sind
    if not anyAllowed or #finalCandidates == 0 then
        return { name = name, weight = 0, perform = function() end }
    end

    local armoryToDropNear = (senses:Get("bestArmoryForWeaponDrop") or {}).armoryEnt or armories[1]
    local weight = GetMarineComBaselineWeight(kMarineComBrainTypes.DropWeapons)

    return {
        name = name,
        weight = weight,
        perform = function(move)
            local weaponCounts = (senses:Get("weaponCounts") or {}).counts or {}
            local weaponChoice, minCount = nil, math.huge

            -- Waffe mit geringster Anzahl auswählen (unter Berücksichtigung der Regeln)
            for techId, dropTechId in pairs(kWeaponToDropTechIds) do

                -- Shotgun immer erlaubt, wenn doable
                if dropTechId == kTechId.DropShotgun and doables[dropTechId] then
                    local count = weaponCounts[techId] or 0
                    if count < minCount then
                        minCount = count
                        weaponChoice = dropTechId
                    end
                end

                -- GL / FT / HMG nur mit Advanced Armory
                if hasAdvanced and doables[dropTechId] then
                    local count = weaponCounts[techId] or 0
                    if count < minCount then
                        minCount = count
                        weaponChoice = dropTechId
                    end
                end
            end

            if not weaponChoice then
                weaponChoice = kTechId.DropShotgun
            end

            local cost = LookupTechData(weaponChoice, kTechDataCostKey, 0)
            local minResThreshold = upgradedFactory ~= nil and 51 or 42

            if res < minResThreshold or res < cost then
                return
            end

            local actualWeaponDrops = 0
            local target = finalCandidates[1]
            if target and target:GetIsAlive() then
                local aroundPos = armoryToDropNear:GetOrigin()
                local dropPos = GetRandomSpawnForCapsule(
                    0.4, 0.4, aroundPos, 0.01,
                    kArmoryWeaponAttachRange * 0.75, EntityFilterAll(), nil
                )
                if dropPos then
                    brain:ExecuteTechId(com, weaponChoice, dropPos, com, armoryToDropNear:GetId())
                    actualWeaponDrops = actualWeaponDrops + 1
                end
            end

            if actualWeaponDrops > 0 then
            local loc = armoryToDropNear:GetLocationName()
            local weaponName = LookupTechData(weaponChoice, kTechDataDisplayName, "Weapon")

            bot:SendTeamMessage(string.format("Dropped %d %s at %s!", actualWeaponDrops, weaponName, loc), 10, false, true)

            end
        end
    }
end, -- Drop Weapons

function(bot, brain, com)
    local name   = kMarineComBrainTypes[kMarineComBrainTypes.DropMines]
    local senses = brain:GetSenses()
    local comTeam = com:GetTeamNumber()
    local res     = com:GetTeamResources()

    local armories  = senses:Get("builtArmories")
    local mainCS    = senses:Get("mainCommandStation")

    if #armories == 0 or not mainCS then
        return { name = name, weight = 0, perform = function() end }
    end

    ----------------------------------------------------------------------
    -- Economy: mindestens 4 Extractors + 25 Res
    ----------------------------------------------------------------------
    local numExtractors = #senses:Get("extractors")
    if numExtractors < 4 or res < 25 then
        return { name = name, weight = 0, perform = function() end }
    end

    ----------------------------------------------------------------------
    -- COOLDOWN: 10 Sekunden
    ----------------------------------------------------------------------
    if Shared.GetTime() - lastMineDropTime < 10 then
        return { name = name, weight = 0, perform = function() end }
    end

----------------------------------------------------------------------
-- Mine liegt am Boden ODER bereits platziert ? kein Drop
----------------------------------------------------------------------
local minePickups = #GetEntitiesForTeam("LayMines", comTeam)
local placedMines = #GetEntitiesForTeam("Mine", comTeam)

-- Wenn eine Mine rumliegt ? kein Drop
if minePickups > 0 then
    return { name = name, weight = 0, perform = function() end }
end

-- Wenn 4 Minen platziert wurden ? kein Drop
if placedMines >= 8 then
    return { name = name, weight = 0, perform = function() end }
end


    ----------------------------------------------------------------------
    -- Prüfen ob ein Marine eine Mine trägt
    ----------------------------------------------------------------------
    local marineHasMine = false
    for _, m in ipairs(GetEntitiesForTeam("Player", comTeam)) do
        if m:GetWeapon(LayMines.kMapName) then
            marineHasMine = true
            break
        end
    end

    if marineHasMine then
        return { name = name, weight = 0, perform = function() end }
    end

    ----------------------------------------------------------------------
    -- Marine im HQ-Radius finden
    ----------------------------------------------------------------------
    local HQpos    = mainCS:GetOrigin()
    local HQradius = 20
    local marineInHQ = nil

    for _, m in ipairs(GetEntitiesForTeam("Player", comTeam)) do
        if m:GetIsAlive() and m:GetOrigin():GetDistance(HQpos) <= HQradius then
            marineInHQ = m
            break
        end
    end

    if not marineInHQ then
        return { name = name, weight = 0, perform = function() end }
    end

    local armoryToDropNear = armories[1]
    local weight = GetMarineComBaselineWeight(kMarineComBrainTypes.DropMines)
    
        -- Prüfen ob Mine-Forschung abgeschlossen ist
    local techTree = com:GetTeam():GetTechTree()
    local mineResearchNode = techTree:GetTechNode(kTechId.MinesTech)

    if not mineResearchNode or not mineResearchNode:GetResearched() then
        return { name = name, weight = 0, perform = function() end }
    end

    return {
        name = name,
        weight = weight,

        perform = function(move)
            local dropTechId = kTechId.DropMines
            local cost = LookupTechData(dropTechId, kTechDataCostKey, 0)

            if com:GetTeamResources() < cost then
                return
            end

            local aroundPos = armoryToDropNear:GetOrigin()
            local dropPos = GetRandomSpawnForCapsule(
                0.4, 0.4, aroundPos, 0.01,
                kArmoryWeaponAttachRange * 0.75, EntityFilterAll(), nil
            )

            if dropPos then
                brain:ExecuteTechId(com, dropTechId, dropPos, com, armoryToDropNear:GetId())
                lastMineDropTime = Shared.GetTime()

                local loc = armoryToDropNear:GetLocationName()
                local count = 1

                bot:SendTeamMessage(string.format("Dropped %d mine(s) at %s!", count, loc), 10, false, true )
                end

        end
    }
end, -- Drop Mines

function(bot, brain, com)
    local name   = kMarineComBrainTypes[kMarineComBrainTypes.DropWelder]
    local senses = brain:GetSenses()
    local comTeam = com:GetTeamNumber()
    local res     = com:GetTeamResources()

    local armories  = senses:Get("builtArmories")
    local mainCS    = senses:Get("mainCommandStation")

    if #armories == 0 or not mainCS then
        return { name = name, weight = 0, perform = function() end }
    end

    ----------------------------------------------------------------------
    -- Economy: mindestens 3 Extractors + 15 Res
    ----------------------------------------------------------------------
    local numExtractors = #senses:Get("extractors")
    if numExtractors < 3 or res < 15 then
        return { name = name, weight = 0, perform = function() end }
    end

    ----------------------------------------------------------------------
    -- Welder am Boden? Maximal 1 erlaubt
    ----------------------------------------------------------------------
    local welderPickups = 0
    for _, w in ipairs(GetEntitiesForTeam("Welder", comTeam)) do
        if w:GetParent() == nil then
            welderPickups = welderPickups + 1
        end
    end

    if welderPickups >= 1 then
        return { name = name, weight = 0, perform = function() end }
    end

    ----------------------------------------------------------------------
    -- Marines mit Welder zählen
    ----------------------------------------------------------------------
    local marines = GetEntitiesForTeam("Player", comTeam)
    local marineCount = #marines
    local welderCount = 0

    for _, m in ipairs(marines) do
        if m:GetWeapon("welder") ~= nil then
            welderCount = welderCount + 1
        end
    end

    ----------------------------------------------------------------------
    -- 33% Minimum, 50% Maximum (immer mindestens 1 Welder erlaubt)
    ----------------------------------------------------------------------
   -- local targetMin = math.max(1, math.floor(marineCount * 0.33))
    local targetMax = math.max(1, math.floor(marineCount * 0.50))

    -- Wenn wir 50% erreicht haben ? kein Drop
    if welderCount >= targetMax then
        return { name = name, weight = 0, perform = function() end }
    end

    --[[ Wenn wir 33% erreicht haben ? kein Drop
    if welderCount >= targetMin then
        return { name = name, weight = 0, perform = function() end }
    end--]]

    ----------------------------------------------------------------------
    -- Marine im HQ-Radius finden
    ----------------------------------------------------------------------
    local HQpos    = mainCS:GetOrigin()
    local HQradius = 20
    local marineInHQ = nil

    for _, m in ipairs(marines) do
        if m:GetIsAlive() and m:GetOrigin():GetDistance(HQpos) <= HQradius then
            marineInHQ = m
            break
        end
    end

    if not marineInHQ then
        return { name = name, weight = 0, perform = function() end }
    end

    ----------------------------------------------------------------------
    -- Drop-Setup
    ----------------------------------------------------------------------
    local armoryToDropNear = armories[1]
    local weight = GetMarineComBaselineWeight(kMarineComBrainTypes.DropMines)

    return {
        name = name,
        weight = weight,

        perform = function(move)
            local dropTechId = kTechId.DropWelder
            local cost = LookupTechData(dropTechId, kTechDataCostKey, 0)

            if com:GetTeamResources() < cost then
                return
            end

            local aroundPos = armoryToDropNear:GetOrigin()
            local dropPos = GetRandomSpawnForCapsule(
                0.4, 0.4, aroundPos, 0.01,
                kArmoryWeaponAttachRange * 0.75, EntityFilterAll(), nil
            )

                if dropPos then
                    brain:ExecuteTechId(com, dropTechId, dropPos, com, armoryToDropNear:GetId())

                    local loc = armoryToDropNear:GetLocationName()
                    local count = 1

                    bot:SendTeamMessage(string.format("Dropped %d welder(s) at %s!", count, loc), 10, false, true )
                end

        end
    }
end, -- Drop Welder

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
    local tooMuchRes = com:GetTeamResources() >= 25
    local weight = 0
    local isZeroIPs = #sdb:Get("activeInfantryPortals") <= 0

    -- Alle Observatories holen
    local observatories = GetEntitiesAliveForTeam("Observatory", com:GetTeamNumber())

    -- Funktion: Prüfen, ob ein aktives Observatory in der Nähe ist
    local function HasPoweredObservatoryNear(pos)
        for _, obs in ipairs(observatories) do
            if obs:GetIsAlive() and obs:GetIsPowered() then
                if obs:GetOrigin():GetDistance(pos) <= 25 then
                    return true
                end
            end
        end
        return false
    end

    if doables[kTechId.Scan] 
       and brain.timeNextScan < time 
       and not isZeroIPs 
       and not brain:GetIsProcessingTechPathOverride() 
       and tooMuchRes then

        local alertqueue = com:GetAlertQueue()

        for i, alert in ipairs(alertqueue) do
            local aTechId = alert.techId
            local targetWeight = kScanReactWeight[aTechId]
            local target

            if targetWeight 
               and targetWeight > weight 
               and time - alert.time < 5 
               and alert.entityId ~= Entity.InvalidId then

                table.remove(alertqueue, i)
                target = Shared.GetEntity(alert.entityId)

                if target then

                    -- Kein Scan, wenn Observatory in der Nähe
                    if HasPoweredObservatoryNear(target:GetOrigin()) then
                        goto continue
                    end

                    if target.GetHealthScalar then
                        targetWeight = targetWeight + targetWeight * (1 - target:GetHealthScalar())
                    end

                    local scans = #GetEntitiesWithMixinForTeamWithinXZRange(
                        "Scan", 
                        com:GetTeamNumber(), 
                        target:GetOrigin(), 
                        Scan.kScanDistance
                    )

                    if scans <= 0 then
                        local nearbyFriendlies = #GetEntitiesForTeamWithinRange(
                            "Player", 
                            com:GetTeamNumber(), 
                            target:GetOrigin(), 
                            Scan.kScanDistance * 0.4
                        )

                        if nearbyFriendlies <= 0 then
                            weight = targetWeight
                            scanTarget = target
                        end
                    end
                end

            elseif time - alert.time > 5 then
                table.remove(alertqueue, i)
            end

            ::continue::
        end

        com:SetAlertQueue(alertqueue)
    end

    return {
        name = name,
        weight = weight,
        perform = function(move, bot, brain, com, action)
            if scanTarget then
                local origin = scanTarget:GetOrigin()
                local groundTrace = Shared.TraceRay(
                    origin + Vector(0, 10, 0),
                    origin + Vector(0, -15, 0),
                    CollisionRep.Default,
                    PhysicsMask.CystBuild,
                    EntityFilterAllButIsa("TechPoint")
                )

                local success = brain:ExecuteTechId(
                    com, 
                    kTechId.Scan, 
                    origin, 
                    com, 
                    scanTarget:GetId(), 
                    groundTrace
                )

                if success then
                    brain.timeNextScan = Shared.GetTime() + 15

                    local loc = scanTarget:GetLocationName() or "unknown location"
                    local buildingName = LookupTechData(
                        scanTarget:GetTechId(), 
                        kTechDataDisplayName, 
                        scanTarget:GetClassName()
                    )

                    bot:SendTeamMessage(
                        string.format("I'm scanning %s at %s due to structural damage!", buildingName, loc),
                        10,
                        false,
                        true
                    )
                end
            end
        end
    }
end, -- Scan (Observatory)

function(bot, brain, com)

    local name = kMarineComBrainTypes[kMarineComBrainTypes.ShadeScan]
    local senses = brain:GetSenses()
    local doables = senses:Get("doableTechIds")
    local comTeam = com:GetTeamNumber()
    local time = Shared.GetTime()

    local weight = 0
    local scanOrigin
    local scanTarget   -- <--- NEU: Speichert, wen wir scannen

    -- Scan verfügbar?
    if doables[kTechId.Scan] then

        -- Observatory nötig
        local observatories = senses:Get("Observatorys")
        if observatories and #observatories > 0 then

            -- Cooldown initialisieren
            if not brain.shadeScanTime then
                brain.shadeScanTime = 0
            end

            -- Cooldown abgelaufen?
            if time >= brain.shadeScanTime then

                ----------------------------------------------------
                -- Marines + Exos holen
                ----------------------------------------------------
                local marines = GetEntitiesForTeam("Marine", comTeam)
                local exos    = GetEntitiesForTeam("Exo", comTeam)

                ----------------------------------------------------
                -- Gemeinsame Liste erzeugen
                ----------------------------------------------------
                local units = {}

                for _, m in ipairs(marines) do
                    table.insert(units, m)
                end
                for _, e in ipairs(exos) do
                    table.insert(units, e)
                end

                ----------------------------------------------------
                -- Shades in der Nähe eines Marines oder Exos prüfen
                ----------------------------------------------------
                for _, unit in ipairs(units) do
                    local uOrigin = unit:GetOrigin()
                    local shades = GetEntitiesWithinRange("Shade", uOrigin, 10)

                    if #shades > 0 then
                        scanOrigin = uOrigin
                        scanTarget = unit   -- <--- Ziel speichern
                        break
                    end
                end
            end
        end
    end

    -- Gewicht setzen, wenn ein Scan ausgeführt werden soll
    if scanOrigin then
        weight = GetMarineComBaselineWeight(kMarineComBrainTypes.ShadeScan)
    end

    return
    {
        name = name,
        weight = weight,

        perform = function(move, bot, brain, com, action)

            if not scanOrigin or not scanTarget then return end

            -- Boden-Trace
            local trace = Shared.TraceRay(
                scanOrigin + Vector(0, 10, 0),
                scanOrigin + Vector(0, -15, 0),
                CollisionRep.Default,
                PhysicsMask.CystBuild
            )

            local success = brain:ExecuteTechId(com, kTechId.Scan, scanOrigin, com, nil, trace)

            if success then
                brain.shadeScanTime = Shared.GetTime() + 15

                -- NEU: Ziel + Location bestimmen
                local playerName = scanTarget:GetName() or "unknown soldier"
                local loc = scanTarget:GetLocationName() or "unknown location"
                
                bot:SendTeamMessage(string.format("I'm scanning %s at %s due to Shade interference!", playerName, loc), 10, false, true)

            end
        end
    }

end, -- ShadeScan

function(bot, brain, com)

    local name = kMarineComBrainTypes[kMarineComBrainTypes.PowerSurge]
    local comTeam = com:GetTeamNumber()
    local senses = brain:GetSenses()
    local doables = senses:Get("doableTechIds")

    local weight = 0
    local target
    local targetScore = 0

    local commandStationAlive = #GetEntitiesAliveForTeam("CommandStation", comTeam) > 0

    ----------------------------------------------------
    -- Gebäudeliste für Observatory-Surge
    ----------------------------------------------------
    local powerSurgeRelevantBuildings = {
        "ArmsLab",
        "InfantryPortal",
        "PrototypeLab",
        "Armory",
        "PhaseGate",
        "RoboticsFactory",
        "Observatory",
        "CommandStation",
    }

    local function GetNearbyRelevantBuildings(origin, teamNumber, range)
        local result = {}

        for _, className in ipairs(powerSurgeRelevantBuildings) do
            local ents = GetEntitiesWithinRange(className, origin, range)
            for _, ent in ipairs(ents) do
                if ent:GetTeamNumber() == teamNumber then
                    table.insert(result, ent)
                end
            end
        end

        return result
    end

local function IsAnyBuildingUnderAttack(buildings)
    for _, b in ipairs(buildings) do
        if b:GetIsAlive() then

            -- 1) UnderFire (falls vorhanden)
            if b.GetIsUnderFire and b:GetIsUnderFire() then
                return true
            end

            -- 2) Health-Drop erkennen
            local hp = b:GetHealth()
            if b.lastHP and hp < b.lastHP then
                b.lastHP = hp
                return true
            end
            b.lastHP = hp

            -- 3) Gegner in der Nähe (ohne Team-Filter)
            local nearby = GetEntitiesWithinRange("Live", b:GetOrigin(), 12)
            for _, ent in ipairs(nearby) do
                if ent ~= b and ent:GetIsAlive() then
                    if ent:GetTeamNumber() ~= b:GetTeamNumber() then
                        return true
                    end
                end
            end
        end
    end

    return false
end

    ----------------------------------------------------
    -- NEU: Prüfen, ob CC im selben Raum wie Observatory
    ----------------------------------------------------
    local function HasCCInSameRoom(obs, teamNumber)
        local ccs = GetEntitiesAliveForTeam("CommandStation", teamNumber)
        local obsRoom = obs:GetLocationName()

        for _, cc in ipairs(ccs) do
            if cc:GetLocationName() == obsRoom then
                return true
            end
        end

        return false
    end

    ----------------------------------------------------
    -- PHASEGATE POWER SURGE
    ----------------------------------------------------
    if doables[kTechId.PowerSurge] then

        local phaseGates = senses:Get("builtPhaseGates")

        for _, pg in ipairs(phaseGates) do

            if not HasMixin(pg, "PowerConsumer") then goto continue_pg end
            if pg:GetIsPowered() then goto continue_pg end

            local loc = pg:GetLocationName()
            if not loc or loc == "" then goto continue_pg end

            local group = GetLocationContention():GetLocationGroup(loc)
            local numMarines = group:GetNumMarines()

            if numMarines >= 0 and (not target or numMarines > targetScore) then
                target = pg
                targetScore = numMarines
            end

            ::continue_pg::
        end
    end

    ----------------------------------------------------
    -- OBSERVATORY POWER SURGE (Beacon-Logik)
    ----------------------------------------------------
    if doables[kTechId.PowerSurge] then

        local observatories = GetEntitiesAliveForTeam("Observatory", comTeam)

        for _, obs in ipairs(observatories) do

            if not HasMixin(obs, "PowerConsumer") then goto continue_obs end
            if obs:GetIsPowered() then goto continue_obs end

            -- NEU: Observatory nur surgen, wenn CC im selben Raum steht
            if not HasCCInSameRoom(obs, comTeam) then goto continue_obs end

            local loc = obs:GetLocationName()
            if not loc or loc == "" then goto continue_obs end

            local group = GetLocationContention():GetLocationGroup(loc)

            local buildings = GetNearbyRelevantBuildings(obs:GetOrigin(), comTeam, 25)

            if not IsAnyBuildingUnderAttack(buildings) then goto continue_obs end

            local marinesNear = group:GetNumMarinePlayers()
            local aliensNear = group:GetNumAlienPlayers()

            local beaconLikely = (marinesNear == 0 and aliensNear > 0)

            if not beaconLikely then goto continue_obs end

            local numMarines = group:GetNumMarines()
            if not target or numMarines > targetScore then
                target = obs
                targetScore = numMarines
            end

            ::continue_obs::
        end
    end

    ----------------------------------------------------
    -- INFANTRY PORTAL POWER SURGE
    ----------------------------------------------------
    if doables[kTechId.PowerSurge] then

        local activeIPs = senses:Get("activeInfantryPortals")
        local noActiveIP = (#activeIPs == 0)

        -- Nur surgen, wenn tote Marines existieren
        local numDead = senses:Get("numDeadPlayers")
        if numDead == 0 then
            -- Keine toten Spieler ? kein Bedarf für IP-Surge
            goto skip_ip_surge
        end

        if noActiveIP then
            local allIPs = GetEntitiesAliveForTeam("InfantryPortal", comTeam)

            for _, ip in ipairs(allIPs) do

                if not HasMixin(ip, "PowerConsumer") then goto continue_ip end
                if ip:GetIsPowered() then goto continue_ip end
                if not ip:GetIsBuilt() then goto continue_ip end

                local score = 9999

                if not target or score > targetScore then
                    target = ip
                    targetScore = score
                end

                ::continue_ip::
            end
        end

        ::skip_ip_surge::
    end


    ----------------------------------------------------
    -- Gewicht
    ----------------------------------------------------
    if target then
        weight = GetMarineComBaselineWeight(kMarineComBrainTypes.PowerSurge)
    end

    ----------------------------------------------------
    -- PERFORM
    ----------------------------------------------------
    return {
        name = name,
        weight = weight,
        perform = function(move, bot, brain, com, action)
            if target then
                brain:ExecuteTechId(com, kTechId.PowerSurge, target:GetOrigin(), com, target:GetId())
            end
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
        
        ----------------------------------------------------
-- EXTRA NANOSHIELD LOGIK:
-- 1) Observatory unter 0.6 HP und unter Beschuss
-- 2) Letztes aktives Infantry Portal unter Beschuss
----------------------------------------------------
if doables[kTechId.NanoShield] and not target and not brain:GetIsProcessingTechPathOverride() then

    ----------------------------------------------------
    -- 1) Observatory NanoShield
    ----------------------------------------------------
    local observatories = GetEntitiesAliveForTeam("Observatory", comTeam)
    for _, obs in ipairs(observatories) do

        if HasMixin(obs, "Live")
            and obs:GetHealthScalar() < 0.6
            and obs:GetIsUnderFire()
            and obs:GetCanBeNanoShielded()
        then
            target = obs
            targetCatpack = false
            break
        end
    end

    ----------------------------------------------------
    -- 2) Letztes aktives Infantry Portal NanoShield
    ----------------------------------------------------
    if not target then
        local activeIPs = senses:Get("activeInfantryPortals")

        if #activeIPs == 1 then
            local ip = activeIPs[1]

            if ip:GetIsUnderFire()
                and ip:GetCanBeNanoShielded()
                and HasMixin(ip, "Live")
            then
                target = ip
                targetCatpack = false
            end
        end
    end
end

    ----------------------------------------------------
    -- 3) Basis-PowerPoint NanoShield
    -- Nur PowerPoints, die im selben Raum wie eine CC stehen
    ----------------------------------------------------
    if not target then
        local powerPoints = GetEntitiesAliveForTeam("PowerPoint", comTeam)
        local commandStations = GetEntitiesAliveForTeam("CommandStation", comTeam)

        for _, pp in ipairs(powerPoints) do

            if HasMixin(pp, "Live")
                and doables[kTechId.NanoShield]
                and pp:GetHealthScalar() < 0.6
                and pp:GetIsUnderFire()
                and pp:GetCanBeNanoShielded()
            then
                local ppRoom = pp:GetLocationName()
                local hasCCInSameRoom = false

                for _, cc in ipairs(commandStations) do
                    if cc:GetLocationName() == ppRoom then
                        hasCCInSameRoom = true
                        break
                    end
                end

                if hasCCInSameRoom then
                    target = pp
                    targetCatpack = false
                    break
                end
            end
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

        local kMaxMacs = 1
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

function(bot, brain, com)
    local name = kMarineComBrainTypes[kMarineComBrainTypes.BuildAndCommandARCs]
    local comTeam = com:GetTeamNumber()
    local senses = brain:GetSenses()
    local doables = senses:Get("doableTechIds")
    local arcs = senses:Get("arcs")
    local marines = senses:Get("marines")
    local exos = senses:Get("exos")
    local structures = doables and doables[kTechId.ARC] or nil
    local hasMinimumTRes = com:GetTeamResources() >= 50

    -- Konfiguration
    local kMaxARCs = 4
    local kDeployRange = 20
    local kFireRange = 25
    local kScanRange = 25
    local kArcManageInterval = 5
    local kScanInterval = 9
    local kMoveRepeatInterval = 4
    local kWaitAfterHiveDestruction = 60
    local minStartGroup = 3

    local weight = 0
    local arcBuildStructure

    -- Zeitmarker initialisieren
    brain.timeLastARCManage = brain.timeLastARCManage or 0
    brain.timeHiveDestroyed = brain.timeHiveDestroyed or 0
    brain.timeNextMove = brain.timeNextMove or 0
    brain.messageSent = brain.messageSent or false
    brain.groupStarted = brain.groupStarted or false

    -- ARC-eigene Marker
    if arcs ~= nil then
        for _, arc in ipairs(arcs) do
            arc.timeLastMove = arc.timeLastMove or 0
            arc.originalPosition = arc.originalPosition or arc:GetOrigin()
            arc.groupStarted = arc.groupStarted or false
            arc.timeNextScan = arc.timeNextScan or 0
            arc.hasDeployed = arc.hasDeployed or false
            arc.waitingForInk = arc.waitingForInk or false
        end
    end

    -- Reset-Logik
    local function AnyARCActive(arcsList)
        for _, a in ipairs(arcsList or {}) do
            if a.groupStarted or a.hasDeployed or (a:GetHasOrder() and a:GetCurrentOrder():GetType() ~= kTechId.None) then
                return true
            end
        end
        return false
    end

    if arcs == nil or #arcs == 0 then
        brain.groupStarted = false
    elseif not AnyARCActive(arcs) then
        brain.groupStarted = false
    end

    -- Startphase
    if arcs ~= nil and #arcs >= minStartGroup and not brain.groupStarted then
        local nearestHive = GetNearestHive(arcs[1]:GetOrigin())
        if nearestHive then
            for _, arc in ipairs(arcs) do
                arc:GiveOrder(kTechId.Move, nil, nearestHive:GetOrigin(), arc:GetId(), true, true)
                arc.timeLastMove = Shared.GetTime()
                arc.groupStarted = true
            end
            brain.groupStarted = true
            local loc = nearestHive:GetLocationName() or "unknown location"
            bot:SendTeamMessage(string.format("ARCs group moving out toward %s!", loc), 20, false, true)
        end
    end

    -------------------------------------------------------------------------
    -- Front-ARC bestimmen und Reinforcements blockieren, wenn < 50% HP
    -------------------------------------------------------------------------
    local blockReinforcements = false
    if arcs ~= nil and #arcs > 0 then
        local nearestHive = GetNearestHive(arcs[1]:GetOrigin())
        if nearestHive then
            local frontARC
            local bestDist = math.huge

            for _, a in ipairs(arcs) do
                local d = (a:GetOrigin() - nearestHive:GetOrigin()):GetLength()
                if d < bestDist then
                    bestDist = d
                    frontARC = a
                end
            end

            if frontARC and frontARC:GetMaxHealth() > 0 then
                local hpFrac = frontARC:GetHealth() / frontARC:GetMaxHealth()
                if hpFrac < 0.5 then
                    blockReinforcements = true
                end
            end
        end
    end

    -- Nachrückphase
    if arcs ~= nil then
        for _, arc in ipairs(arcs) do

            -- Keine Nachrücker, wenn Front-ARC < 50% HP
            if blockReinforcements then
                break
            end

            if not arc.groupStarted and brain.groupStarted then
                local nearestHive = GetNearestHive(arc:GetOrigin())
                if nearestHive then
                    arc:GiveOrder(kTechId.Move, nil, nearestHive:GetOrigin(), arc:GetId(), true, true)
                    arc.timeLastMove = Shared.GetTime()
                    arc.groupStarted = true
                    local loc = nearestHive:GetLocationName() or "unknown location"
                    bot:SendTeamMessage(string.format("New ARC reinforcing group toward %s!", loc),20, false, true)
                end
            end
        end
    end

    -- Operationsphase
    if arcs ~= nil and Shared.GetTime() - brain.timeLastARCManage > kArcManageInterval then
        brain.timeLastARCManage = Shared.GetTime()
        for _, arc in ipairs(arcs) do
            if arc.groupStarted then
                local nearestHive = GetNearestHive(arc:GetOrigin())
                if nearestHive then
                    local dist = (nearestHive:GetOrigin() - arc:GetOrigin()):GetLength()
                    if not arc:GetHasOrder() or Shared.GetTime() - arc.timeLastMove > kMoveRepeatInterval then
                        if dist > kFireRange then
                            arc:GiveOrder(kTechId.Move, nil, nearestHive:GetOrigin(), arc:GetId(), true, true)
                            arc.timeLastMove = Shared.GetTime()
                        elseif dist <= kFireRange and dist > kDeployRange then
                            local offset = Vector(math.random(-3,3), 0, math.random(-3,3))
                            local deployPoint = nearestHive:GetOrigin() + (arc:GetOrigin() - nearestHive:GetOrigin()):GetUnit() * kDeployRange + offset
                            arc:GiveOrder(kTechId.Move, nil, deployPoint, arc:GetId(), true, true)
                            arc.timeLastMove = Shared.GetTime()
                        elseif dist <= kDeployRange then
                            brain:ExecuteTechId(com, kTechId.ARCDeploy, arc:GetOrigin(), arc)
                            arc.hasDeployed = true
                            arc:GiveOrder(kTechId.Attack, nearestHive:GetId(), nearestHive:GetOrigin(), arc:GetId(), true, true)
                        end
                    end
                end

                -- Scan-Logik
                local observatories = senses:Get("Observatorys")
                local hasObservatory = observatories and #observatories > 0
                if hasObservatory and Shared.GetTime() > arc.timeNextScan then
                    local hivesInRange = GetEntitiesWithinRange("Hive", arc:GetOrigin(), kScanRange, true)
                    if #hivesInRange > 0 then
                        for _, hive in ipairs(hivesInRange) do
                            local origin = hive:GetOrigin()
                            brain:ExecuteTechId(com, kTechId.Scan, origin, com, hive:GetId(),
                                Shared.TraceRay(origin + Vector(0,10,0), origin + Vector(0,-15,0),
                                CollisionRep.Default, PhysicsMask.CystBuild, EntityFilterAllButIsa("TechPoint")))
                            local loc = hive:GetLocationName() or "unknown location"
                            bot:SendTeamMessage(
                            string.format("I'm scanning the enemy base at %s!", loc), 20, false, true)
                        end
                        arc.timeNextScan = Shared.GetTime() + kScanInterval
                    end
                end

                -- Shade-Ink-Handling
                local inkClouds = GetEntitiesForTeamWithinRange("ShadeInk", GetEnemyTeamNumber(comTeam), arc:GetOrigin(), ShadeInk.kShadeInkDisorientRadius)
                if #inkClouds > 0 then
                    if not arc.waitingForInk then
                        arc:GiveOrder(kTechId.HoldPosition, nil, arc:GetOrigin(), arc:GetId(), true, true)
                        arc.waitingForInk = true
                    end
                else
                    if arc.waitingForInk then
                        arc.waitingForInk = false
                        local nearestHive = GetNearestHive(arc:GetOrigin())
                        if nearestHive then
                            arc:GiveOrder(kTechId.Attack, nearestHive:GetId(), nearestHive:GetOrigin(), arc:GetId(), true, true)
                        end
                    end
                end

                -- Verteidiger-Logik
                if arc:GetHasOrder() and arc:GetCurrentOrder():GetType() == kTechId.Move and not arc.hasDeployed then
                    local nearestMarine, nearestExo
                    local nearestMarineDist, nearestExoDist = math.huge, math.huge

                    for _, marine in ipairs(marines or {}) do
                        local d = (marine:GetOrigin() - arc:GetOrigin()):GetLength()
                        if d < nearestMarineDist then
                            nearestMarineDist, nearestMarine = d, marine
                        end
                    end

                    for _, exo in ipairs(exos or {}) do
                        local d = (exo:GetOrigin() - arc:GetOrigin()):GetLength()
                        if d < nearestExoDist then
                            nearestExoDist, nearestExo = d, exo
                        end
                    end

                    local function giveDefendOrder(unit)
                        if unit then
                            local isBot = unit.GetClient and unit:GetClient() and unit:GetClient():GetIsVirtual()
                            local cooldown = isBot and 10 or 30
                            if not unit.lastDefendOrder or Shared.GetTime() - unit.lastDefendOrder > cooldown then
                                unit:GiveOrder(kTechId.Defend, arc:GetId(), arc:GetOrigin(), unit:GetId(), true, true)
                                unit.lastDefendOrder = Shared.GetTime()
                            end
                        end
                    end

                    giveDefendOrder(nearestMarine)
                    giveDefendOrder(nearestExo)
                end

                -- Hive-Zerstörungs-Trigger
                if arc.hasDeployed and not GetEntitiesWithinRange("Hive", arc:GetOrigin(), kFireRange, true)[1] then
                    if brain.timeHiveDestroyed == 0 then
                        brain.timeHiveDestroyed = Shared.GetTime()
                        local loc = arc:GetLocationName() or "unknown location"
                        bot:SendTeamMessage(string.format("Hive destroyed at %s, ARCs waiting timer started!", loc),10, false, true)
                    end
                end
            end
        end
    end

    -- Globaler Timer nach Hive-Zerstörung
    if brain.timeHiveDestroyed > 0 then
        if Shared.GetTime() - brain.timeHiveDestroyed >= kWaitAfterHiveDestruction then
            local enemyHives = GetEntitiesForTeam("Hive", GetEnemyTeamNumber(comTeam))
            if #enemyHives == 0 then
                if arcs ~= nil then
                    for _, arc in ipairs(arcs) do
                        if arc.hasDeployed then
                            brain:ExecuteTechId(com, kTechId.ARCUndeploy, arc:GetOrigin(), arc)
                            arc.hasDeployed = false
                        end
                        arc:GiveOrder(kTechId.None, nil, arc:GetOrigin(), arc:GetId(), true, true)
                    end
                end
                bot:SendTeamMessage("All Hives destroyed, ARCs undeploy and stand down.", 40, false, true)
            else
                if arcs ~= nil and #arcs > 0 then
                    local nextHive = GetNearestHive(arcs[1]:GetOrigin())
                    if nextHive then
                        local movePoint = nextHive:GetOrigin() + (arcs[1]:GetOrigin() - nextHive:GetOrigin()):GetUnit() * kDeployRange
                        for _, arc in ipairs(arcs) do
                            if arc.hasDeployed then
                                brain:ExecuteTechId(com, kTechId.ARCUndeploy, arc:GetOrigin(), arc)
                                arc.hasDeployed = false
                            end
                            arc:GiveOrder(kTechId.Move, nil, movePoint, arc:GetId(), true, true)
                            arc.timeLastMove = Shared.GetTime()
                        end
                        local loc = nextHive:GetLocationName() or "unknown location"
                        bot:SendTeamMessage(string.format("ARCs moving to next Hive at %s!", loc),20, false, true)
                    end
                else
                    bot:SendTeamMessage("ARC group destroyed, no units left to move.", 20, false, true)
                end
            end
            brain.timeHiveDestroyed = 0
        end
    end

    -- Bau-Routine
    if structures and arcs ~= nil and #arcs < kMaxARCs and hasMinimumTRes and not brain:GetIsProcessingTechPathOverride() then
        arcBuildStructure = structures[math.random(#structures)]
        weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildAndCommandARCs)
    end

    return {
        name = name,
        weight = weight,
        perform = function(move)
            if arcBuildStructure and com:GetTeamResources() >= 50 then
                local buildPos = arcBuildStructure:GetOrigin()
                brain:ExecuteTechId(com, kTechId.ARC, buildPos, arcBuildStructure)
                local loc = arcBuildStructure:GetLocationName() or "unknown location"
                bot:SendTeamMessage( string.format("ARC being built at %s!", loc),10, false, true)
            end
        end
    }
end, -- ARCING WITH SCAN AND MARINE/EXO DEFEND COMMAND

function(bot, brain, com)
    local name = kMarineComBrainTypes[kMarineComBrainTypes.BuildOrder]
    local senses = brain:GetSenses()
    local weight = 0.0
    local targetStructures = senses:Get("incompleteStructures")
    local marines = senses:Get("marines")
    local commandStation = senses:Get("mainCommandStation")
    local distanceThreshold = 20
    local orderCooldown = 45
    brain.lastOrderTimes = brain.lastOrderTimes or {}

    -- Gewichtung der Strukturen nach Prioritï¿½t
    local structurePriority = {
        ["CommandStation"] = 1,
        ["ArmsLab"] = 2,
        ["InfantryPortal"] = 3,
        ["PhaseGate"] = 4,  -- PhaseGate vor der Armory
        ["Armory"] = 5,
        ["Observatory"] = 6,
        ["PrototypeLab"] = 7,
        ["RoboticsFactory"] = 8,
        ["Extractor"] = 9,
        ["Other"] = 10
    }

    -- Funktion zum Berechnen der Prioritï¿½t einer Struktur
    local function GetStructurePriority(structure)
        if structure:isa("CommandStation") then
            return structurePriority["CommandStation"]
        elseif structure:isa("ArmsLab") then
            return structurePriority["ArmsLab"]
        elseif structure:isa("InfantryPortal") then
            return structurePriority["InfantryPortal"]
        elseif structure:isa("PhaseGate") then
            return structurePriority["PhaseGate"]
        elseif structure:isa("Armory") then
            return structurePriority["Armory"]
        elseif structure:isa("Observatory") then
            return structurePriority["Observatory"]
        elseif structure:isa("PrototypeLab") then
            return structurePriority["PrototypeLab"]
        elseif structure:isa("RoboticsFactory") then
            return structurePriority["RoboticsFactory"]
        elseif structure:isa("Extractor") then
            return structurePriority["Extractor"]
        else
            return structurePriority["Other"]
        end
    end

    -- Filter out PowerPoints
    local filteredTargetStructures = {}
    for _, structure in ipairs(targetStructures) do
        if not structure:isa("PowerPoint") then
            table.insert(filteredTargetStructures, structure)
        end
    end

    -- Strukturen nach Prioritï¿½t und Entfernung zur Kommandozentrale sortieren
    table.sort(filteredTargetStructures, function(a, b)
        local priorityA = GetStructurePriority(a)
        local priorityB = GetStructurePriority(b)
        if priorityA == priorityB then
            local distA = (a:GetOrigin() - commandStation:GetOrigin()):GetLength()
            local distB = (b:GetOrigin() - commandStation:GetOrigin()):GetLength()
            return distA < distB
        else
            return priorityA < priorityB
        end
    end)

    if #filteredTargetStructures > 0 then
        weight = GetMarineComBaselineWeight(kMarineComBrainTypes.BuildOrder)
    end

    return {
        name = name,
        weight = weight,
        perform = function(move)
            local marinesAssignedToTarget = {}
            local currentTime = Shared.GetTime()

            for _, targetStructure in ipairs(filteredTargetStructures) do
                local nearestMarine = nil
                local nearestDistance = math.huge

                for _, marine in ipairs(marines) do
                    local distanceToTarget = (marine:GetOrigin() - targetStructure:GetOrigin()):GetLength()
                    local currentOrder = marine:GetCurrentOrder()
                    local lastOrderTime = brain.lastOrderTimes[marine:GetId()] or 0

                    if distanceToTarget < nearestDistance and not GetIsAssignedToOtherMarine(marine, targetStructure) and 
                       (not currentOrder or currentOrder:GetType() ~= kTechId.Construct) and (currentTime - lastOrderTime >= orderCooldown) then
                        nearestDistance = distanceToTarget
                        nearestMarine = marine
                    end
                end

                if nearestMarine then
                    -- Order wird nur einmal gegeben und die Position liegt 2 Meter neben der Zielstruktur
                    local orderPosition = targetStructure:GetOrigin() + Vector(1, 0, 0)
                    local success = nearestMarine:GiveOrder(kTechId.Move, nil, orderPosition, nearestMarine:GetId(), true, true)
                    if success then
                        nearestMarine.assignedTargetId = targetStructure:GetId()
                        brain.lastOrderTimes[nearestMarine:GetId()] = Shared.GetTime()  -- Setze die Zeit der letzten Order
                        marinesAssignedToTarget[nearestMarine:GetId()] = true
                        -- Beenden der Schleife, nachdem der Befehl einmal gegeben wurde
                        break
                    end
                end
            end


            -- Ausgabe der Anzahl der zugewiesenen Marines
            local assignedCount = 0
            for _, _ in pairs(marinesAssignedToTarget) do
                assignedCount = assignedCount + 1
            end
            -- Print("Total Marines Assigned to Construct: " .. tostring(assignedCount))
        end
    }
end, --BUILD ORDER]]

function(bot, brain, com)

    local name = kMarineComBrainTypes[kMarineComBrainTypes.AttackOrder]
    local senses = brain:GetSenses()
    local weight = 0.0

    local marines = senses:Get("marines")
    local exos = senses:Get("exos")
    local freeTechPoints = senses:Get("availTechPoints")

    local attackRadius = 25
    local orderCooldown = 2

    brain.lastAttackOrderTimes = brain.lastAttackOrderTimes or {}

    ----------------------------------------------------------------------
    -- ALIEN-STRUKTUREN
    ----------------------------------------------------------------------
    local alienStructureClasses = {
        "Cyst", "Whip", "Hydra", "Crag", "Shade", "Shift", "TunnelEntrance"
    }

    ----------------------------------------------------------------------
    -- ALIENS IM RADIUS FINDEN (Spieler + Strukturen)
    ----------------------------------------------------------------------
    local function GetAliensNear(origin)
        local result = {}

        -- Spieler-Aliens (Skulk, Gorge, Lerk, Fade, Onos)
        for _, alien in ipairs(GetEntitiesForTeam("Player", kAlienTeamType)) do
            if alien:GetIsAlive() then
                if (alien:GetOrigin() - origin):GetLength() <= attackRadius then
                    table.insert(result, alien)
                end
            end
        end

        -- Strukturen
        for _, className in ipairs(alienStructureClasses) do
            for _, ent in ipairs(GetEntities(className)) do
                if ent:GetIsAlive() then
                    if (ent:GetOrigin() - origin):GetLength() <= attackRadius then
                        table.insert(result, ent)
                    end
                end
            end
        end

        return result
    end

    ----------------------------------------------------------------------
    -- MARINE HAT BEREITS ATTACK-ORDER?
    ----------------------------------------------------------------------
    local function AlreadyAttacking(unit, target)
        local order = unit:GetCurrentOrder()
        if not order then return false end
        if order:GetType() ~= kTechId.Attack then return false end
        local orderTarget = Shared.GetEntity(order:GetParam())
        return orderTarget == target
    end

    ----------------------------------------------------------------------
    -- ZIELPRIORITÄT
    ----------------------------------------------------------------------
local function AlienPriority(ent)
    local techId = ent.GetTechId and ent:GetTechId() or nil

    -- Spieler-Aliens
    if techId == kTechId.Onos then return 1 end
    if techId == kTechId.Fade then return 2 end
    if techId == kTechId.Lerk then return 3 end
    if techId == kTechId.Skulk then return 4 end
    if techId == kTechId.Gorge then return 5 end

    -- Strukturen
    local mapName = ent:GetMapName()

    if mapName == Whip.kMapName then return 6 end
    if mapName == Hydra.kMapName then return 7 end
    if mapName == TunnelEntrance.kMapName then return 8 end
    if mapName == Crag.kMapName then return 9 end
    if mapName == Shade.kMapName then return 10 end
    if mapName == Shift.kMapName then return 11 end
    if mapName == Cyst.kMapName then return 12 end

    -- Falls irgendwas nicht erkannt wird
    return 99
end


    ----------------------------------------------------------------------
    -- ATTACK-PAIRS SAMMELN (pro TP nur einmal Aliens suchen)
    ----------------------------------------------------------------------
    local attackPairs = {}

    for _, tp in ipairs(freeTechPoints) do
        local tpOrigin = tp:GetOrigin()

        -- Aliens nur EINMAL suchen
        local aliens = GetAliensNear(tpOrigin)
        if #aliens == 0 then
            goto continue
        end

        -- Marines
        for _, unit in ipairs(marines) do
            if (unit:GetOrigin() - tpOrigin):GetLength() <= attackRadius then
                table.insert(attackPairs, { marine = unit, tp = tp, aliens = aliens })
            end
        end

        -- Exos
        for _, unit in ipairs(exos) do
            if (unit:GetOrigin() - tpOrigin):GetLength() <= attackRadius then
                table.insert(attackPairs, { marine = unit, tp = tp, aliens = aliens })
            end
        end

        ::continue::
    end

    ----------------------------------------------------------------------
    -- GEWICHT: Node aktiv, wenn Marines + Aliens am freien TP
    ----------------------------------------------------------------------
    if #attackPairs > 0 then
        weight = GetMarineComBaselineWeight(kMarineComBrainTypes.AttackOrder)
    end

    ----------------------------------------------------------------------
    -- PERFORM
    ----------------------------------------------------------------------
    return {
        name = name,
        weight = weight,

        perform = function(move)

            local now = Shared.GetTime()

            for _, pair in ipairs(attackPairs) do
                local unit = pair.marine
                local tp = pair.tp
                local aliens = pair.aliens

                -- Marine hat TP verlassen?
                if (unit:GetOrigin() - tp:GetOrigin()):GetLength() > attackRadius then
                    goto continue
                end

                -- Ziel nach Priorität sortieren
                table.sort(aliens, function(a, b)
                    return AlienPriority(a) < AlienPriority(b)
                end)

                local target = aliens[1]
                local id = unit:GetId()
                local last = brain.lastAttackOrderTimes[id] or 0

                -- Bereits am Angreifen?
                if AlreadyAttacking(unit, target) then
                    goto continue
                end

                -- Cooldown
                if now - last < orderCooldown then
                    goto continue
                end

                -- Order geben
                local success = unit:GiveOrder(
                    kTechId.Attack,
                    target:GetId(),
                    target:GetOrigin(),
                    id,
                    true,
                    true
                )

                if success then
                    brain.lastAttackOrderTimes[id] = now
                    break -- nur EIN Order pro Tick
                end

                ::continue::
            end
        end
    }
end, -- ATTACK ORDER]]

function(bot, brain, com)
    local name = kMarineComBrainTypes[kMarineComBrainTypes.MoveOrderOnFreeTechpoints]
    local comTeam = com:GetTeamNumber()
    local senses = brain:GetSenses()
    local weight = 0.0
    local techPointToTake = senses:Get("techPointToTake")
    local targetStructures = senses:Get("incompleteStructures")
    local marines = senses:Get("marines")
    local exos = senses:Get("exos")
    local maxUnitsAssignedPerTarget = 1
    local distanceThreshold = 25
    local scanInterval = 25  -- Set the scan interval to 15 seconds
    local tooMuchRes = com:GetTeamResources() >= 25
    local lastScanTimeTechPoint = brain.timeNextScanTechPoint or 0  -- Use a separate variable for TechPoint scan time

  -- Debugging: Ausgabe der Initialisierungswerte
  --Print("Initializing MoveOrderOnFreeTechpoints:")
  --Print("TechPointToTake: " .. (techPointToTake and techPointToTake:GetLocationName() or "nil"))
  --Print("TargetStructures Count: " .. tostring(#targetStructures))
  --Print("Marines Count: " .. tostring(#marines))
  --Print("Exos Count: " .. tostring(#exos))
  --Print("LastScanTimeTechPoint: " .. tostring(lastScanTimeTechPoint))

    -- Filter out PowerPoints
    local filteredTargetStructures = {}
    for _, structure in ipairs(targetStructures) do
        if not structure:isa("PowerPoint") then
            table.insert(filteredTargetStructures, structure)
        end
    end

    if #filteredTargetStructures > 0 or techPointToTake then
        weight = GetMarineComBaselineWeight(kMarineComBrainTypes.MoveOrderOnFreeTechpoints)
    end

    return {
        name = name,
        weight = weight,
        perform = function(move)
            local unitsAssignedToTarget = {}
            local assignedCount = 0
            local currentTime = Shared.GetTime()

            -- Debugging: Ausgabe der zu nehmenden TechPoints
            if techPointToTake then
              --Print("TechPoint to Take: " .. techPointToTake:GetLocationName() .. ", Position: " .. tostring(techPointToTake:GetOrigin()))
            end

            -- Zuweisung von Move-Orders an den nï¿½chsten neutralen TechPoint
            if techPointToTake and assignedCount < 1 then
                local nearestUnit = nil
                local nearestDistance = math.huge
                local movePosition = techPointToTake:GetOrigin()

                for _, marine in ipairs(marines) do
                    local distanceToTarget = (marine:GetOrigin() - movePosition):GetLength()
                    local currentOrder = marine:GetCurrentOrder()

                    if distanceToTarget < nearestDistance and not GetIsAssignedToOtherMarine(marine, techPointToTake) and (not currentOrder or (currentOrder:GetType() ~= kTechId.Move and currentOrder:GetType() ~= kTechId.Defend)) then
                        nearestDistance = distanceToTarget
                        nearestUnit = marine
                    end
                end

                for _, exo in ipairs(exos) do
                    local distanceToTarget = (exo:GetOrigin() - movePosition):GetLength()
                    local currentOrder = exo:GetCurrentOrder()

                    if distanceToTarget < nearestDistance and not GetIsAssignedToOtherExo(exo, techPointToTake) and (not currentOrder or (currentOrder:GetType() ~= kTechId.Move and currentOrder:GetType() ~= kTechId.Defend)) then
                        nearestDistance = distanceToTarget
                        nearestUnit = exo
                    end
                end

                if nearestUnit and nearestDistance > distanceThreshold then
                    local success = nearestUnit:GiveOrder(kTechId.Move, nil, movePosition, nearestUnit:GetId(), true, true)
                    if success then
                        nearestUnit.assignedTargetId = techPointToTake:GetId()
                        unitsAssignedToTarget[nearestUnit:GetId()] = true
                        assignedCount = assignedCount + 1
                      --Print("Assigned nearest Unit " .. nearestUnit:GetId() .. " to move to TechPoint at " .. tostring(movePosition))
                    else
                      --Print("Failed to assign Unit " .. nearestUnit:GetId() .. " to move to TechPoint at " .. tostring(movePosition))
                    end
                end
            end

            -- Zuweisung von Construct-Orders an unvollstï¿½ndige Strukturen
            for _, targetStructure in ipairs(filteredTargetStructures) do
                local nearestMarine = nil
                local nearestDistance = math.huge

                for _, marine in ipairs(marines) do
                    local distanceToTarget = (marine:GetOrigin() - targetStructure:GetOrigin()):GetLength()
                    local currentOrder = marine:GetCurrentOrder()

                    if distanceToTarget < nearestDistance and not GetIsAssignedToOtherMarine(marine, targetStructure) and (not currentOrder or currentOrder:GetType() ~= kTechId.Construct) then
                        nearestDistance = distanceToTarget
                        nearestMarine = marine
                    end
                end

                if nearestMarine and nearestDistance > distanceThreshold then
                    local success = nearestMarine:GiveOrder(kTechId.Construct, targetStructure:GetId(), targetStructure:GetOrigin(), nearestMarine:GetId(), true, true)
                    if success then
                        nearestMarine.assignedTargetId = targetStructure:GetId()
                        unitsAssignedToTarget[nearestMarine:GetId()] = true
                      --Print("Assigned nearest Marine " .. nearestMarine:GetId() .. " to construct structure " .. targetStructure:GetId())
                    else
                      --Print("Failed to assign Marine " .. nearestMarine:GetId() .. " to construct structure " .. targetStructure:GetId())
                    end
                end
            end
            
            -- ï¿½berprï¿½fung, ob ein Observatorium vorhanden ist
            local observatories = senses:Get("Observatorys")
            local hasObservatory = observatories and #observatories > 0

            -- Durchfï¿½hrung des Scans, wenn der Bot nï¿½her als 15 Einheiten am Tech Point ist, seit dem letzten Scan mehr als 15 Sekunden vergangen sind, und ein Observatorium vorhanden ist
            if techPointToTake and currentTime > lastScanTimeTechPoint and hasObservatory then
                for _, marine in ipairs(marines) do
                    local distanceToTechPoint = (marine:GetOrigin() - techPointToTake:GetOrigin()):GetLength()
                    if distanceToTechPoint <= 15 then
                        local origin = techPointToTake:GetOrigin()
                        local groundTrace = Shared.TraceRay(
                            origin + Vector(0, 10, 0),
                            origin + Vector(0, -15, 0),
                            CollisionRep.Default,
                            PhysicsMask.CystBuild,
                            EntityFilterAllButIsa("TechPoint")
                        )
                        local success = brain:ExecuteTechId(com, kTechId.Scan, origin, com, techPointToTake:GetId(), groundTrace)
                        if success then
                            brain.timeNextScanTechPoint = Shared.GetTime() + scanInterval
                            lastScanTimeTechPoint = brain.timeNextScanTechPoint
                            local loc = techPointToTake:GetLocationName() or "unknown location"
                            bot:SendTeamMessage(string.format("I scan the neutral Techpoint at %s for safety check!", loc),10, false, true)
                          --Print("Executed scan at TechPoint " .. techPointToTake:GetLocationName())
                        end
                        break
                    end
                end
            end

            -- Ausgabe der Anzahl der zugewiesenen Einheiten
          --Print("Total Units Assigned: " .. tostring(assignedCount))
        end
    }
end, --MOVE ORDER TO NEUTRAL TECHPOINTS]]

function(bot, brain, com)
    local name = kMarineComBrainTypes[kMarineComBrainTypes.WeldOrder]
    local comTeam = com:GetTeamNumber()
    local senses = brain:GetSenses()
    local weight = 0.0
    local marines = senses:Get("marines")
    local techPoints = GetEntities("TechPoint")
    local extractors = senses:Get("extractors")
    local commandStations = GetEntitiesForTeam("CommandStation", comTeam)
    local distanceThreshold = 20
    local weldDistanceThreshold = 50

    -- Funktion, um zu ï¿½berprï¿½fen, ob eine Command Station auf dem TechPoint vorhanden ist
    local function IsTechPointOccupiedByCommandStation(techPoint)
        for _, commandStation in ipairs(commandStations) do
            if (techPoint:GetOrigin() - commandStation:GetOrigin()):GetLength() < distanceThreshold then
                return true
            end
        end
        return false
    end

    -- Funktion, um zu ï¿½berprï¿½fen, ob ein Resource Point besetzt ist
    local function IsResourcePointOccupiedByExtractor(resPoint)
        for _, extractor in ipairs(extractors) do
            if (resPoint:GetOrigin() - extractor:GetOrigin()):GetLength() < distanceThreshold then
                return true
            end
        end
        return false
    end

    -- Filter damaged structures to include only PowerPoints near occupied TechPoints or Resource Points
    local damagedStructures = {}
    for _, structure in ipairs(senses:Get("damagedStructures")) do
        if structure:isa("PowerPoint") then
            for _, techPoint in ipairs(techPoints) do
                if IsTechPointOccupiedByCommandStation(techPoint) and (structure:GetOrigin() - techPoint:GetOrigin()):GetLength() < distanceThreshold then
                    table.insert(damagedStructures, structure)
                    break
                end
            end
            for _, extractor in ipairs(extractors) do
                if IsResourcePointOccupiedByExtractor(extractor) and (structure:GetOrigin() - extractor:GetOrigin()):GetLength() < distanceThreshold then
                    table.insert(damagedStructures, structure)
                    break
                end
            end
        elseif structure:isa("CommandStation") or structure:isa("ArmsLab") or structure:isa("InfantryPortal") or structure:isa("PhaseGate") or structure:isa("Armory") or structure:isa("Observatory") or structure:isa("PrototypeLab") or structure:isa("RoboticsFactory") or structure:isa("Extractor") then
            table.insert(damagedStructures, structure)
        end
    end

    -- Gewichtung der Strukturen nach Prioritï¿½t
    local structurePriority = {
        ["PowerPoint"] = 1,
        ["CommandStation"] = 2,
        ["ArmsLab"] = 3,
        ["InfantryPortal"] = 4,
        ["PhaseGate"] = 5,
        ["Armory"] = 6,
        ["Observatory"] = 7,
        ["PrototypeLab"] = 8,
        ["RoboticsFactory"] = 9,
        ["Extractor"] = 10,
        ["Other"] = 11
    }

    -- Funktion zum Berechnen der Prioritï¿½t einer Struktur
    local function GetStructurePriority(structure)
        if structure:isa("PowerPoint") then
            for _, techPoint in ipairs(techPoints) do
                if IsTechPointOccupiedByCommandStation(techPoint) and (structure:GetOrigin() - techPoint:GetOrigin()):GetLength() < distanceThreshold then
                    return structurePriority["PowerPoint"]
                end
            end
            for _, extractor in ipairs(extractors) do
                if IsResourcePointOccupiedByExtractor(extractor) and (structure:GetOrigin() - extractor:GetOrigin()):GetLength() < distanceThreshold then
                    return structurePriority["PowerPoint"]
                end
            end
            return structurePriority["Other"]
        elseif structure:isa("CommandStation") then
            return structurePriority["CommandStation"]
        elseif structure:isa("ArmsLab") then
            return structurePriority["ArmsLab"]
        elseif structure:isa("InfantryPortal") then
            return structurePriority["InfantryPortal"]
        elseif structure:isa("PhaseGate") then
            return structurePriority["PhaseGate"]
        elseif structure:isa("Armory") then
            return structurePriority["Armory"]
        elseif structure:isa("Observatory") then
            return structurePriority["Observatory"]
        elseif structure:isa("PrototypeLab") then
            return structurePriority["PrototypeLab"]
        elseif structure:isa("RoboticsFactory") then
            return structurePriority["RoboticsFactory"]
        elseif structure:isa("Extractor") then
            return structurePriority["Extractor"]
        else
            return structurePriority["Other"]
        end
    end

    -- Sicherstellen, dass eine Command Station existiert
    if #commandStations == 0 then
        return {
            name = name,
            weight = 0,
            perform = function(move)
                -- Keine Aktion, wenn keine Command Stations existieren
            end
        }
    end

    -- Strukturen nach Prioritï¿½t und Entfernung zur nï¿½chstgelegenen Kommandozentrale sortieren
    table.sort(damagedStructures, function(a, b)
        local priorityA = GetStructurePriority(a)
        local priorityB = GetStructurePriority(b)
        if priorityA == priorityB then
            local nearestCommandStationA = GetNearest(a:GetOrigin(), "CommandStation", comTeam, function(ent) return ent:GetIsBuilt() and ent:GetIsAlive() end)
            local nearestCommandStationB = GetNearest(b:GetOrigin(), "CommandStation", comTeam, function(ent) return ent:GetIsBuilt() and ent:GetIsAlive() end)
            local distA = (a:GetOrigin() - nearestCommandStationA:GetOrigin()):GetLength()
            local distB = (b:GetOrigin() - nearestCommandStationB:GetOrigin()):GetLength()
            return distA < distB
        else
            return priorityA < priorityB
        end
    end)

    -- Gewichtungslogik fï¿½r die Weld Order
    if #damagedStructures > 0 then
        weight = GetMarineComBaselineWeight(kMarineComBrainTypes.WeldOrder)
    end

    return {
        name = name,
        weight = weight,
        perform = function(move)
            local marinesAssignedToTarget = {}

            -- Zuweisung von Weld-Orders an beschï¿½digte Strukturen
            for _, damagedStructure in ipairs(damagedStructures) do
                if damagedStructure:GetHealth() < damagedStructure:GetMaxHealth() then
                    local nearestMarine = nil
                    local nearestDistance = math.huge
                    for _, marine in ipairs(marines) do
                        local distanceToTarget = (marine:GetOrigin() - damagedStructure:GetOrigin()):GetLength()
                        local currentOrder = marine:GetCurrentOrder()
                        local hasWelder = senses:Get("hasWelder")(marine) -- ï¿½berprï¿½fen, ob der Marine einen Welder hat

                        if distanceToTarget < nearestDistance and distanceToTarget <= weldDistanceThreshold and hasWelder and not GetIsAssignedToOtherMarine(marine, damagedStructure) and (not currentOrder or currentOrder:GetType() ~= kTechId.Weld) then
                            nearestDistance = distanceToTarget
                            nearestMarine = marine
                        end
                    end
                    if nearestMarine then -- Sicherstellen, dass nur Marines den Befehl erhalten
                        local success = nearestMarine:GiveOrder(kTechId.Weld, damagedStructure:GetId(), damagedStructure:GetOrigin(), nearestMarine:GetId(), true, true)
                        if success then
                            nearestMarine.assignedTargetId = damagedStructure:GetId()
                            marinesAssignedToTarget[nearestMarine:GetId()] = true
                        end
                    end
                end
            end

            -- Ausgabe der Anzahl der zugewiesenen Marines
            local assignedCount = 0
            for _, _ in pairs(marinesAssignedToTarget) do
                assignedCount = assignedCount + 1
            end
            --Print("Total Marines Assigned: " .. tostring(assignedCount))
        end
    }
end, --WELD ORDER


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
