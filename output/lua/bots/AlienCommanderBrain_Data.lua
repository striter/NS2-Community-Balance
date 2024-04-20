Script.Load("lua/bots/CommonActions.lua")
Script.Load("lua/bots/CommonAlienActions.lua")
Script.Load("lua/bots/BrainSenses.lua")
Script.Load("lua/bots/AlienCommanderBrain_TechPathData.lua")
Script.Load("lua/bots/AlienCommanderBrain_Utility.lua")
Script.Load("lua/bots/AlienCommanderBrain_Senses.lua")

local kAlienComActionTypes = enum({

    "WaitForHiveDrop", -- Waiting for Hive drop after decision, for a warning period. -- TODO: This blocks all other actions, use a "tres deficit/save" mechanism instead
    "BuildEmergencyHive", -- Last Hive is low hp and in combat
    "BuildHarvester_Zero",
    "BuildHarvester_EarlyGame", -- Want to place 2 harvesters right away at the start of the game
    "ReCyst_Structure", -- Structure is suffocating
    "BuildCystForResNode_EarlyGame",-- Prepare next ResNode for harvester (only cyst)

    -- Reactionary Actions (Under attack, etc)
    "SpawnEggs", -- TODO: Needs review
    "BoneWall",
    "ShadeInk",
    "CystRupture",

    "BuildHive_TooMuchTRes",
    "BuildCystForResNode",-- Prepare next ResNode for harvester (only cyst)
    "BuildHarvester_RunningLow",
    "BuildDrifter",

    "CystNextTechPoint",
    "BuildUpgradeChamber", -- Shell, Spur, Veil

    -- "Upgrade Hive", want to do this sooner so we can get upgrade chambers built,
    -- but only after 3 chambers for any previous hive type is obtained
    "UpgradeHiveType", -- [Crag/Shift/Shade]Hive

    "NutrientMist_Player", -- Time left for evolve is > kGorgeGestateTime (7 seconds), lerk (next higher) is 14 seconds

    -- Make sure tunnels exist between all hive rooms ( can travel between hive rooms with only tunnels )
    -- Future, maybe place tunnel at "most valuable non-hive location", such as double RT in veil
    "BuildTunnelEntrance",

    "Contaminate",
    "BuildHive",


    "NutrientMist_Structure", -- A Cyst is close enough, but it's not built. (structure is suffocating)
    "BuildHarvester", -- We have enough RTs (BuildHarvester_RunningLow is much higher prio)

    "ResearchUpgrades", -- Takes care of all research upgrades and biomass (except hive types)

    -- Generic hive emboldenment, requires T1 research completion
    "BuildCrag",
    "BuildShade",
    "BuildWhip",

    "Idle",

})

local kAlienComBrainActionTypesOrderScale = 100
local function GetAlienComBaselineWeight( actionId )
    assert(kAlienComActionTypes[kAlienComActionTypes[actionId]], "Error: Invalid AlienCom action-id passed")

    local totalActions = #kAlienComActionTypes
    local actionOrderId = kAlienComActionTypes[kAlienComActionTypes[actionId]] --numeric index, not string

    --invert numeric index value and scale, the results in lower value, the higher the index. Which means
    --the Enum of actions is shown and used in a natural order (i.e. order of enum value declaration IS the priority)
    local actionWeightOrder = totalActions - (actionOrderId - 1)

    --final action base-line weight value
    return actionWeightOrder * kAlienComBrainActionTypesOrderScale
end

local kHiveSpawnDelay = 10
local kHiveBuildDist = 15.0     --BOT-FIXME This needs to take into account Location placing in (its entrances, etc.). Should augment location per build-id too
local kHiveSupportStructureBuildDist = 8
local kBioUpgradesPerHive = 2 -- Only applies up to tier 3 upgrades
local kBiomassMinForPvE = 4
local kPVEDropInterval = 10

local function GetAlertMistWeight(brain, friendTeamNum, alertType, target)

    if alertType == kTechId.AlienAlertNeedMist then

        local timeleftUntilEvolve = target and target.gestationTime or 0 --get evolve time

        if #GetEntitiesForTeamWithinRange("NutrientMist", friendTeamNum, target:GetOrigin(), NutrientMist.kSearchRange) > 0 then
            return 0
        end

        if timeleftUntilEvolve >= 4 then
            return GetAlienComBaselineWeight(kAlienComActionTypes.NutrientMist_Player)
        else
            return 0
        end

        return 0

    elseif alertType == kTechId.AlienAlertStructureUnderAttack or alertType == kTechId.AlienAlertHarvesterUnderAttack then

        local position = target:GetOrigin()
        if GetIsPointOnInfestation(position, friendTeamNum) then
            return 0.0
        end

        if target:GetClassName() ~= "Cyst" then -- Ignore cysts, so we don't try to infest where a cyst is (From Cyst Action)
            brain.structuresInDanger:Add(position)
        end

        return 0

    else
        return 0
    end

end
local GetTechPathProgressForAlien = GetTechPathProgressForAlien
local NearestFriendlyHiveTo = NearestFriendlyHiveTo
local WouldCystInfestPoint = WouldCystInfestPoint
local GetCystForPoint = GetCystForPoint
local GetIsTunnelEntranceValidForTravel = GetIsTunnelEntranceValidForTravel
local GetLocationHasTunnelEntrance = GetLocationHasTunnelEntrance
local CooldownPassedForTunnelDropInLocation = CooldownPassedForTunnelDropInLocation

local function RuptureEnemyFilter(memory)
    local ent = Shared.GetEntity(memory.entId)
    return ent and ent:isa("Player") and not ent:GetIsParasited()
end

--[[local function CreateBuildNearHiveAction( techId, className, numToBuild, weightIfNotEnough )

    return CreateBuildStructureAction(
            techId, className,
            {
            {-1.0, weightIfNotEnough},
            {numToBuild-1, weightIfNotEnough},
            {numToBuild, 0.0}
            },
            "Hive",
            kHiveBuildDist )
end

local function CreateBuildNearHiveActionWithReqHiveNum( techId, className, numToBuild, weightIfNotEnough, reqHiveNum )

    local createBuildStructure = CreateBuildStructureAction(
        techId, className,
        {
            {-1.0, weightIfNotEnough},
            {numToBuild-1, weightIfNotEnough},
            {numToBuild, 0.0}
        },
        "Hive",
        kHiveBuildDist )

    return function(bot, brain)
        local action = createBuildStructure(bot, brain)

        local sdb = brain:GetSenses()

        if GetNumHives() < reqHiveNum then
            action.weight = 0.0
        end

        return action
    end
end
]]

local kExecAlienCommanderResearchUpgrade = function(move, bot, brain, com, action)
    PROFILE("AlienCommanderBrain_Data:research_upgrade - PERFORM")

    -- researchTechId
    -- researchUnit -- Which structure to start the research at

    if action.researchTechId and action.researchUnit then
        local success = brain:ExecuteTechId(com, action.researchTechId, Vector(0,0,0), action.researchUnit)
        if success then
            SendResearchingChatMessage(bot, com, action.researchTechId)
        end
    end

end

local kExecAlienCommanderShadeInk = function(move, bot, brain, com, action)
    PROFILE("AlienCommanderBrain_Data:shade_ink - PERFORM")

    local shade = action.shade
    if shade then
        -- ( commander, techId, position, hostEntity, targetId, trace)
        brain:ExecuteTechId( com, kTechId.ShadeInk, shade:GetOrigin(), shade )
    end

end

local kExecUpgradeHiveType = function(move, bot, brain, com, action)
    -- upgradeTechId
    -- hiveToUpgrade
    if action.upgradeTechId and action.hiveToUpgrade then
        brain:ExecuteTechId(com, action.upgradeTechId, Vector(0,0,0), action.hiveToUpgrade)
    end
end

local kExecBuildUpgradeChamber = function(move, bot, brain, com, action)

    --hiveUnitToDropNear
    --chamberDropTechId

    local pos = GetRandomBuildPosition( action.chamberDropTechId, action.hiveUnitToDropNear:GetOrigin(), kHiveBuildDist )
    if pos ~= nil and brain:ExecuteTechId( com, action.chamberDropTechId, pos, com ) then
        brain.droppedUpgradeChamber = true
    end

end

local kPVEStructureTechIds = set
{
    kTechId.Crag,
    kTechId.Shade,
    kTechId.Whip,
}
local kExecTechId = function(move, bot, brain, com, action)
    if action.targetPos and (action.techId and action.techId ~= kTechId.None) and action.unit then
        if brain:ExecuteTechId( com, action.techId, action.targetPos, action.unit ) then
            if kPVEStructureTechIds[action.techId] then
                brain:SetTimeLastDroppedStructure("PVE")
            end
        end
    end
end

local kExecBonewall = function(move, bot, brain, com, action)
    if action.bonewallTarget then

        local friendlyOrigin = action.bonewallTarget:GetOrigin()
        local attackerOrigin = action.bonewallTarget:GetLastTakenDamageOrigin() -- "bonewallTarget" guarantees CombatMixin
        local offsetDir = (attackerOrigin - friendlyOrigin):GetUnit()
        local bonewallPos = Pathing.GetClosestPoint(friendlyOrigin + offsetDir)

        brain:ExecuteTechId( com, kTechId.BoneWall, bonewallPos, com )
        brain.bonewallDelay = math.random(0.5, 2)
    end
end

local kExecDropHive = function(move, bot, brain, com, action)

    if action.targetTP then

        local isFirstPerform = not brain.isDroppingHive

        -- Update "Hold" data
        brain.isDroppingHive = true

        if isFirstPerform then
            brain.timeDropHiveStart = Shared.GetTime()
            brain.dropHiveTechPointId = action.targetTP:GetId()
        end

        local timeSinceStartOfHiveDecision = Shared.GetTime() - brain.timeDropHiveStart
        local delayPassed = timeSinceStartOfHiveDecision >= kHiveSpawnDelay

        if not action.isEmergency and not delayPassed then

            if isFirstPerform then

                local techPointLocationName = action.targetTP:GetLocationName()
                techPointLocationName = (techPointLocationName and techPointLocationName ~= "" and techPointLocationName) or "no name"
                local message = string.format("I want to drop a Hive in %s in %s seconds!",
                        techPointLocationName,
                        kHiveSpawnDelay)
                bot:SendTeamMessage(message, 0, false, true)

                -- Create a warning pheromone where we want to spawn the Hive.
                CreatePheromone(kTechId.ExpandingMarker, action.targetTP:GetOrigin(), com:GetTeamNumber())

            end

        else

            local success = brain:ExecuteTechId( com, kTechId.Hive, action.targetTP:GetOrigin(), com )
            if success then

                local emergencyStr = action.isEmergency and "emergency" or ""

                local techPointLocationName = action.targetTP:GetLocationName()
                techPointLocationName = (techPointLocationName and techPointLocationName ~= "" and techPointLocationName) or "no name"
                local message = string.format("I %s dropped a Hive in %s!", emergencyStr, techPointLocationName)

                bot:SendTeamMessage(message, 0, false, true)
                brain.isDroppingHive = false
            end

        end
    end

end

local kChamberTechToChamberSense =
{
    { kTechId.Shell, "numShells" },
    { kTechId.Spur , "numSpurs"  },
    { kTechId.Veil , "numVeils"  },
}

kAlienComBrainActions =     --BOT-TODO ALL below actions need to be reviewed and modified, so when applicable, they take Location-Hostility and RoundTime into account
{
    function(bot, brain, com)

        local name = kAlienComActionTypes[kAlienComActionTypes.BuildCrag]
        local comTeamNum = com:GetTeamNumber()
        local senses = brain:GetSenses()
        local doables = senses:Get("doableTechIds")
        local weight = 0

        local buildPos

        local canDo = doables[kTechId.Crag] and com:GetTeamResources() >= kCragCost
        if canDo and #senses:Get("builtHives") >= 1 and --senses:Get("biomassLevel") >= kBiomassMinForPvE and
            brain:GetTimeSinceLastDroppedStructure("PVE") > kPVEDropInterval then

            local locationsWithHive = senses:Get("hivesAndLocations")
            for i = 1, #locationsWithHive do
                local hive = locationsWithHive[i][1]
                local locationId = locationsWithHive[i][2]
                local cragsInlocation = GetEntitiesForTeamByLocation("Crag", comTeamNum, locationId)
                local locationName = Shared.GetString(locationId)
                if #cragsInlocation <= 0 and
                        brain:GetDelayPassedForStructureRedrop(locationName) and
                        brain:GetIsSafeToDropInLocation(locationName, com:GetTeamNumber(), senses:Get("isEarlyGame")) then

                    buildPos = GetRandomBuildPosition( kTechId.Crag, hive:GetOrigin(), kHiveSupportStructureBuildDist )
                    if buildPos then
                        weight = GetAlienComBaselineWeight(kAlienComActionTypes.BuildCrag)
                        break
                    end

                end

            end

        end

        return
        {
            name = name,
            weight = weight,
            targetPos = buildPos,
            techId = kTechId.Crag,
            unit = com,
            perform = kExecTechId,
        }

    end, -- Build Crag

    function(bot, brain, com)

        local name = kAlienComActionTypes[kAlienComActionTypes.BuildShade]
        local comTeamNum = com:GetTeamNumber()
        local senses = brain:GetSenses()
        local doables = senses:Get("doableTechIds")
        local weight = 0

        local buildPos

        local canDo = doables[kTechId.Shade] and com:GetTeamResources() >= kShadeCost
        if canDo and #senses:Get("builtHives") >= 1 and senses:Get("biomassLevel") >= kBiomassMinForPvE and
            brain:GetTimeSinceLastDroppedStructure("PVE") > kPVEDropInterval then

            local locationsWithHive = senses:Get("hivesAndLocations")
            for i = 1, #locationsWithHive do
                local hive = locationsWithHive[i][1]
                local locationId = locationsWithHive[i][2]
                local locationName = Shared.GetString(locationId)
                local shadesInLocation = GetEntitiesForTeamByLocation("Shade", comTeamNum, locationId)
                if #shadesInLocation <= 0 and
                        brain:GetDelayPassedForStructureRedrop(locationName) and
                        brain:GetIsSafeToDropInLocation(locationName, com:GetTeamNumber(), senses:Get("isEarlyGame"))then

                    buildPos = GetRandomBuildPosition( kTechId.Shade, hive:GetOrigin(), kHiveSupportStructureBuildDist )
                    if buildPos then
                        weight = GetAlienComBaselineWeight(kAlienComActionTypes.BuildShade)
                        break
                    end

                end

            end

        end

        return
        {
            name = name,
            weight = weight,
            targetPos = buildPos,
            techId = kTechId.Shade,
            unit = com,
            perform = kExecTechId,
        }

    end, -- Build Shade

    function(bot, brain, com)

        local name = kAlienComActionTypes[kAlienComActionTypes.BuildWhip]
        local comTeamNum = com:GetTeamNumber()
        local senses = brain:GetSenses()
        local doables = senses:Get("doableTechIds")
        local weight = 0

        local isEarlyGame = senses:Get("isEarlyGame")

        local buildPos
        local kMaxWhips = 1 -- Anywhere
        local kMinHivesForWhips = 2

        if doables[kTechId.Whip] and not isEarlyGame and
                #senses:Get("hives") >= kMinHivesForWhips and
                #senses:Get("whips") < kMaxWhips and
                senses:Get("biomassLevel") >= kBiomassMinForPvE and
                brain:GetTimeSinceLastDroppedStructure("PVE") > kPVEDropInterval then

            local locationsWithHive = senses:Get("hivesAndLocations")
            for i = 1, #locationsWithHive do
                local hive = locationsWithHive[i][1]
                local locationId = locationsWithHive[i][2]
                local locationName = Shared.GetString(locationId)
                local whipsInLocation = GetEntitiesAliveForTeamByLocation("Whip", comTeamNum, locationId)
                if #whipsInLocation <= 0 and
                        brain:GetDelayPassedForStructureRedrop(locationName) and
                        brain:GetIsSafeToDropInLocation(locationName, com:GetTeamNumber(), senses:Get("isEarlyGame"))then

                    buildPos = GetRandomBuildPosition( kTechId.Whip, hive:GetOrigin(), kHiveBuildDist )
                    if buildPos then
                        weight = GetAlienComBaselineWeight(kAlienComActionTypes.BuildWhip)
                        break
                    end

                end

            end

        end

        return
        {
            name = name,
            weight = weight,
            targetPos = buildPos,
            techId = kTechId.Whip,
            unit = com,
            perform = kExecTechId,
        }

    end, -- Build Whip

    function(bot, brain, com)

        local name = kAlienComActionTypes[kAlienComActionTypes.BuildUpgradeChamber]
        local senses = brain:GetSenses()
        local doables = senses:Get("doableTechIds")
        local weight = 0

        local hiveUnitToDropNear
        local chamberDropTechId

        local isWaitingForEarlyRTDrops = senses:Get("isEarlyGame") and #senses:Get("harvesters") < 3

        if not isWaitingForEarlyRTDrops then

            local firstSafeHive = senses:Get("firstBuiltAndSafeHive")
            local chamberTechId = kTechId.None

            -- Get first missing chamber upgrade structure
            if firstSafeHive and brain:GetDelayPassedForStructureRedrop(firstSafeHive:GetLocationName()) then

                for _, info in ipairs(kChamberTechToChamberSense) do

                    local chamberTechId = info[1]
                    local chamberSense = info[2]

                    if doables[chamberTechId] then

                        local numChambers = senses:Get(chamberSense)

                        local harvesters = senses:Get("harvesters")
                        local maxChambers = 1

                        -- Limit to 1 chamber per hive type until later in the game
                        if senses:Get("gameMinutes") >= 2 or #senses:Get("harvesters") >= 4 then
                            maxChambers = 3
                        end

                        if numChambers < maxChambers then

                            hiveUnitToDropNear = firstSafeHive
                            chamberDropTechId = chamberTechId
                            weight = GetAlienComBaselineWeight(kAlienComActionTypes.BuildUpgradeChamber)
                            break

                        end
                    end
                end
            end
        end

        return
        {
            name = name,
            weight = weight,
            hiveUnitToDropNear = hiveUnitToDropNear,
            chamberDropTechId = chamberDropTechId,
            perform = kExecBuildUpgradeChamber
        }

    end, -- Build Chamber Upgrade (Shell, Spur, Veil)

    function(bot, brain, com)

        local name = kAlienComActionTypes[kAlienComActionTypes.UpgradeHiveType]
        local senses = brain:GetSenses()
        local doables = senses:Get("doableTechIds")
        local weight = 0

        local hiveTally = senses:Get("hiveTypes")
        local normalHives = hiveTally.normalHives
        local numNormalHives = hiveTally.numNormalHives
        local numCragHives = hiveTally.numCragHives
        local numShadeHives = hiveTally.numShadeHives
        local numShiftHives = hiveTally.numShiftHives

        local canAfford = com:GetTeamResources() > kUpgradeHiveCost
        local upgradeTechId = kTechId.UpgradeToCragHive

        if numCragHives <= 0 then
        elseif brain.secondHiveShade then
            if numShadeHives <= 0 then
                upgradeTechId = kTechId.UpgradeToShadeHive
            elseif numShiftHives <= 0 then
                upgradeTechId = kTechId.UpgradeToShiftHive
            end
        else
            if numShiftHives <= 0 then
                upgradeTechId = kTechId.UpgradeToShiftHive
            elseif numShadeHives <= 0 then
                upgradeTechId = kTechId.UpgradeToShadeHive
            end
        end

        local waitingForEarlyGameDrops = senses:Get("isEarlyGame") and #senses:Get("harvesters") < 3
        local hiveToUpgrade
        if not waitingForEarlyGameDrops and doables[upgradeTechId] then

            if numNormalHives > 0 then
                hiveToUpgrade = normalHives[1]
                weight = GetAlienComBaselineWeight(kAlienComActionTypes.UpgradeHiveType)
            end

        end

        return
        {
            name = name,
            weight = weight,
            upgradeTechId = upgradeTechId,
            hiveToUpgrade = hiveToUpgrade,
            perform = kExecUpgradeHiveType
        }

    end, -- Hive Type Upgrade (Crag/Shift/Shade)

    function(bot, brain, com)
        PROFILE("AlienCommanderBrain_Data:research_upgrades")

        local name = kAlienComActionTypes[kAlienComActionTypes.ResearchUpgrades]
        local comTeamNumber = com:GetTeamNumber()
        local senses = brain:GetSenses()
        local doables = senses:Get("doableTechIds")
        local evoChamber = senses:Get("researchEvolutionChamber")
        local weight = 0
        local researchTechId = kTechId.None
        local hiveToResearchAt

        local hasMinimumTRes = com:GetTeamResources() >= 20
        local waitingForEarlyGameDrops = senses:Get("isEarlyGame") and #senses:Get("harvesters") < 3

        if not brain.droppedUpgradeChamber then
            -- reset dropped upgrade chambers in case the khamm has joined the team late
            brain.droppedUpgradeChamber =
                #GetEntitiesAliveForTeam("Shell", comTeamNumber) > 0 or
                #GetEntitiesAliveForTeam("Veil", comTeamNumber) > 0 or
                #GetEntitiesAliveForTeam("Spur", comTeamNumber) > 0
        end

        if not waitingForEarlyGameDrops and brain.droppedUpgradeChamber and hasMinimumTRes then

            -- GetResearchingBiomassLevel (includes currently researching biomass)
            local techTier, nextTechId, eTechResult = GetTechPathProgressForAlien(brain, com)
            local isBiomassUpgrade = kBioMassTechIdsSet[nextTechId]
            local isHiveDrop = nextTechId == kTechId.Hive

            brain.nextUpgradeStep = nextTechId

            -- (tier finished) or (last tech in tier in progress)
            brain.hasEnoughTechForHive = isHiveDrop or eTechResult == kHasTechResult.InProgressOrUnbuilt

            local techTree = GetTechTree(comTeamNumber)
            local techNode = techTree and techTree:GetTechNode(nextTechId)
            if nextTechId ~= kTechId.None and not isHiveDrop then

                -- Since there are no biomass upgrades in the alien com tech path, if we can't do the research
                -- then we just research biomass. We don't care which biomass, just the cheapest one, untill we
                -- have enough to purchase the next tech
                
                if doables[nextTechId] then -- Can afford, and do (has pre-reqs)

                    if evoChamber then

                        weight = GetAlienComBaselineWeight(kAlienComActionTypes.ResearchUpgrades)
                        researchTechId = nextTechId
                        hiveToResearchAt = evoChamber

                    end

                elseif not GetHasPrereqs(com:GetTeamNumber(), nextTechId) then -- We don't have enough biomass

                    -- Get highest pre-req biomass upgrade between the pre-reqs
                    local preReq1TechId = techNode:GetPrereq1()
                    local preReq2TechId = techNode:GetPrereq2()

                    -- Get the 1-12 biomass level tech id
                    local highestBiomassPrereqLevel
                    if preReq1TechId ~= kTechId.None and preReq2TechId ~= kTechId.None then
                        highestBiomassPrereqLevel = math.max(kTechToBiomassLevel[preReq1TechId], kTechToBiomassLevel[preReq2TechId])
                    elseif preReq1TechId ~= kTechId.None then
                        highestBiomassPrereqLevel = kTechToBiomassLevel[preReq1TechId]
                    elseif preReq2TechId ~= kTechId.None then
                        highestBiomassPrereqLevel = kTechToBiomassLevel[preReq2TechId]
                    end

                    assert(highestBiomassPrereqLevel, "Prerequisite for research tech was not a biomass!")

                    local inProgressBiomassLevel = com:GetTeam():GetInProgressBiomassLevel()
                    if inProgressBiomassLevel < highestBiomassPrereqLevel then

                        local cheapestBioTable = senses:Get("cheapestBiomassUnit")
                        if cheapestBioTable.isValid then

                            hiveToResearchAt = cheapestBioTable.hiveEnt
                            researchTechId = cheapestBioTable.techId
                            weight = GetAlienComBaselineWeight(kAlienComActionTypes.ResearchUpgrades)

                        end

                    end
                end
            end
        end

        return
        {
            name = name,
            weight = weight,
            researchTechId = researchTechId,
            researchUnit = hiveToResearchAt, -- Which structure to start the research at
            perform = kExecAlienCommanderResearchUpgrade
        }

    end, -- Research Upgrades and Biomass

    function(bot, brain, com)
        PROFILE("AlienCommanderBrain_Data:harvester")
        
        local name = "harvester"
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")

        local kHarvesterTooMany = 3
        local kEarlyGameHarvesterMax = 3

        local weight = 0.0
        local targetRP

        if not brain.droppedNaturalRts then
            brain.droppedNaturalRts = #sdb:Get("harvesters") >= 3
        end

        if doables[kTechId.Harvester] then

            targetRP = sdb:Get("resPointToTake")

            if targetRP and GetIsPointOnInfestation(targetRP:GetOrigin()) and brain:GetDelayPassedForStructureRedrop(targetRP:GetLocationName()) then

                local isEarlyGame = sdb:Get("isEarlyGame")
                local harvesters = sdb:Get("harvesters")
                local maxHarvesters = sdb:Get("numHarvestersForRoundTime")

                local emptyHiveResPoint = sdb:Get("availableSafeHiveResNode")
                local emptyTunnelResPoint = sdb:Get("availableSafeTunnelResNode")
                local emptyTechResPoint = emptyHiveResPoint or emptyTunnelResPoint

                if #harvesters < maxHarvesters or emptyTechResPoint then

                    if isEarlyGame then
                        weight = GetAlienComBaselineWeight(kAlienComActionTypes.BuildHarvester_EarlyGame)
                    else

                        local harvesterInfo = sdb:Get("harvesterDecisionInfo")
                        --numHarvesters
                        --numEmptyResPoints
                        --numTPRoomsWithRts: hive rooms with rts

                        local isZeroRts = harvesterInfo.numHarvesters <= 0

                        -- Some custom maps have 1 "natural" rt shared between two hives
                        local isRunningLowOnRts =
                        harvesterInfo.numHarvesters < (harvesterInfo.numTPRoomsWithRts * 2) and
                                sdb:Get("numResourcePoints") * 0.5 > harvesterInfo.numHarvesters

                        if isZeroRts then
                            weight = GetAlienComBaselineWeight(kAlienComActionTypes.BuildHarvester_Zero)
                        elseif isRunningLowOnRts then
                            weight = GetAlienComBaselineWeight(kAlienComActionTypes.BuildHarvester_RunningLow)
                        else
                            weight = GetAlienComBaselineWeight(kAlienComActionTypes.BuildHarvester)
                        end

                    end

                end

            end

        end

        return 
        { 
            name = name, 
            weight = weight,
            targetPos = targetRP and targetRP:GetOrigin(),
            techId = kTechId.Harvester,
            unit = com,
            perform = kExecTechId
        }
    end, -- Spawn Harvester (RT)

    function(bot, brain, com)
        PROFILE("AlienCommanderBrain:bonewall")

        local name = "bonewall"
        local kBonewallTechId = kTechId.BoneWall
        local teamnumber = com:GetTeamNumber()
        local senses = brain:GetSenses()
        local doableTechIds = senses:Get("doableTechIds")
        local weight = 0

        local bonewallTarget

        local canBoneshield = doableTechIds[kBonewallTechId]
        local hasEnoughTres = com:GetTeamResources() > kBoneWallCost

        if canBoneshield and hasEnoughTres then
            bonewallTarget = senses:Get("bonewallTarget")
            if bonewallTarget then
                weight = GetAlienComBaselineWeight(kAlienComActionTypes.BoneWall)
            end
        end

        return
        {
            name = name,
            weight = weight,
            bonewallTarget = bonewallTarget,
            perform = kExecBonewall
        }

    end, -- Bone Wall

    function(bot, brain, com)
        PROFILE("AlienCommanderBrain_Data:shade_ink")

        local name = "shade_ink"
        local com = bot:GetPlayer()
        local comTeamNumber = com:GetTeamNumber()
        local senses = brain:GetSenses()
        local doables = senses:Get("doableTechIds") -- Also checks cost
        local teamBrain = brain.teamBrain
        local weight = 0

        local shadeToUse
        if doables[kTechId.ShadeInk] then

            local hives = GetEntitiesAliveForTeam("Hive", comTeamNumber)
            local hivesWithShade = {}
            for _, hive in ipairs(hives) do

                -- Cooldown is 16 seconds for shade ink as of writing, this should be fine
                local kMinTimeAfterARCToShadeInk = 2.5
                local kMaxTimeAfterARCToShadeInk = 4

                local timeSinceLastARCDamage = Shared.GetTime() - hive:GetTimeLastARCDamageReceived()
                local isTimeForInk =
                    timeSinceLastARCDamage >= kMinTimeAfterARCToShadeInk and
                    timeSinceLastARCDamage < kMaxTimeAfterARCToShadeInk

                if hive:GetIsInCombat() and isTimeForInk then

                    if #GetEntitiesForTeamWithinRange("ShadeInk", comTeamNumber, hive:GetOrigin(), ShadeInk.kShadeInkDisorientRadius) <= 0 then
                        local shades = GetEntitiesForTeamWithinRange("Shade", comTeamNumber, hive:GetOrigin(), ShadeInk.kShadeInkDisorientRadius)
                        if #shades > 0 then
                            shadeToUse = shades[1]
                            weight = GetAlienComBaselineWeight(kAlienComActionTypes.ShadeInk)
                            break
                        end
                    end

                end

            end

        end

        return
        {
            name = name,
            weight = weight,
            shade = shadeToUse,
            perform = kExecAlienCommanderShadeInk
        }

    end, -- Shade Ink

    function(bot, brain, com)
        PROFILE("AlienCommanderBrain_Data:rupture")

        local name = "rupture"
        local com = bot:GetPlayer()
        local comTeamNumber = com:GetTeamNumber()
        local senses = brain:GetSenses()
        local doables = senses:Get("doableTechIds")
        local teamBrain = brain.teamBrain
        local weight = 0

        local cystToRupture

        local isRuptureUnlocked = doables[kTechId.Rupture] -- Biomass two, currently
        local hasEnoughTres = com:GetTeamResources() > kRuptureCost

        local cysts = GetEntitiesForTeam("Cyst", comTeamNumber)
        if isRuptureUnlocked and hasEnoughTres and #cysts > 0 then

            for _, cyst in ipairs(cysts) do

                local cystCurrentAttacker = cyst:GetCurrentAttacker()
                local cystCurrentAttackerValid =
                    cystCurrentAttacker and
                    cyst:GetLastAttackerDoerClassName() ~= "ARC" and
                    not cystCurrentAttacker:isa("ARC") and
                    GetAreEnemies(cyst, cystCurrentAttacker)

                if cyst:GetIsInCombat() and cystCurrentAttackerValid then

                    local ruptureRangeSq = kRuptureEffectRadius*kRuptureEffectRadius
                    local nearbyEnemies = teamBrain:FilterNearbyMemories(cyst:GetLocationName(), GetEnemyTeamNumber(comTeamNumber), RuptureEnemyFilter)
                    local filteredEnts = FilterTable(nearbyEnemies, function(ent)
                        return cyst:GetOrigin():GetDistanceSquared(ent:GetOrigin()) < ruptureRangeSq
                    end)

                    if #filteredEnts > 0 then -- Essentially this is just boils down to "Parasite nearby enemies"
                        cystToRupture = cyst
                        weight = GetAlienComBaselineWeight(kAlienComActionTypes.CystRupture)
                        break
                    end

                end
            end

        end

        return
        {
            name = name,
            weight = weight,
            targetPos = cystToRupture and cystToRupture:GetOrigin(),
            techId = kTechId.Rupture,
            unit = com,
            perform = kExecTechId
        }

    end, -- Rupture

    function(bot, brain, com)
        PROFILE("AlienCommanderBrain_Data:mist")

        local name = "mist"
        local com = bot:GetPlayer()
        local teamnumber = com:GetTeamNumber()
        local alertqueue = com:GetAlertQueue()

        local reactTechIds = {
            [kTechId.AlienAlertNeedMist] = kTechId.NutrientMist,
            [kTechId.AlienAlertStructureUnderAttack] = kTechId.NutrientMist,
            [kTechId.AlienAlertHarvesterUnderAttack] = kTechId.NutrientMist,
        }

        local weight = 0.0
        local targetPos, targetId
        local techId

        local time = Shared.GetTime()

        for i, alert in ipairs(alertqueue) do
            local aTechId = alert.techId
            local targetTechId = reactTechIds[aTechId]
            local target
            if time - alert.time < 3 and targetTechId then
                target = Shared.GetEntity(alert.entityId)
                if target then
                    local alertPiority = GetAlertMistWeight(brain, teamnumber, aTechId, target)
                    if alertPiority == 0 then
                        target = nil
                    elseif alertPiority > weight then
                        techId = targetTechId
                        weight = alertPiority
                        targetPos = target:GetOrigin() --Todo Add jitter to position
                        targetId = target:GetId()
                    end
                end
            end

            if not target then
                table.remove(alertqueue, i)
            end
        end

        com:SetAlertQueue(alertqueue)

        return 
        { 
            name = name, 
            weight = weight,
            targetPos = targetPos,
            techId = techId,
            unit = com,
            perform = kExecTechId,
        }
    end, -- Mist
    
    function(bot, brain, com)
        PROFILE("AlienCommanderBrain_Data:contamination")

        local name = "contamination"
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0
        local targetTP = sdb:Get("techPointToContaminate")
        local cystPos
        local tooMuchRes = com:GetTeamResources() >= 199
        
        if doables[kTechId.Contamination] and targetTP and tooMuchRes then

            local position = targetTP:GetOrigin()

            local extents = GetExtents(kTechId.Crag)
            cystPos = GetRandomSpawnForCapsule(
                    extents.y, extents.x,
                    position + Vector(0
                    ,1,0), 1, 4,
                    EntityFilterAll(), GetIsPointOffInfestation)
            if cystPos then
                weight = GetAlienComBaselineWeight(kAlienComActionTypes.Contaminate)
            end

        end

        return 
        { 
            name = name, 
            weight = weight,
            targetPos = cystPos,
            techId = kTechId.Contamination,
            unit = com,
            perform = kExecTechId,
        }
    end, -- Contaminate
    
    function(bot, brain, com)

        PROFILE("AlienCommanderBrain_Data:cyst")

        local name = "cyst"
        local sdb = brain:GetSenses()
        local weight = 0.0

        local isCystForNewHive = false
        local isCystForNewTunnel = false
        local isReCystSuffocatingStucture = false
        local isEarlyGame = sdb:Get("isEarlyGame")

        local emptyHiveResPoint = sdb:Get("availableSafeHiveResNode")
        local emptyTunnelResPoint = sdb:Get("availableSafeTunnelResNode")

        local nextHiveTechPoint = sdb:Get("techPointToTakeInfest") -- Different from techPointToTake by not requiring friendly presence (for cyst)
        local resPoint = sdb:Get("resPointToTake")
        local rtPosition = resPoint and resPoint:GetOrigin()
        local cystPos

        -- Check if a structure needs to be re-cysted (most important override)
        if #brain.structuresInDanger > 0 then -- TODO: Pass in location name to avoid GetLocationForPoint
            rtPosition = brain.structuresInDanger[1]
            brain.structuresInDanger:RemoveIndex(1)
            resPoint = nil
            isReCystSuffocatingStucture = true
            isCystForNewHive = false
        elseif brain.nextUpgradeStep == kTechId.Hive and nextHiveTechPoint and not GetCystForPoint(sdb, nextHiveTechPoint:GetOrigin()) then
            isCystForNewHive = true
            resPoint = nextHiveTechPoint
            rtPosition = resPoint:GetOrigin()
        elseif brain.droppedNaturalRts and sdb:Get("safeTechPointNoTunnel") and not GetCystForPoint(sdb, sdb:Get("safeTechPointNoTunnel"):GetOrigin()) then
            isCystForNewTunnel = true
            resPoint = sdb:Get("safeTechPointNoTunnel")
            rtPosition = resPoint:GetOrigin()
        end

        local numCystedButEmptyResNodes = #sdb:Get("cystedAvailResPoints")
        local hasTooMuchCyst =
                not isReCystSuffocatingStucture and not isCystForNewHive and
                (
                    ((isCystForNewTunnel or isCystForNewHive) and #sdb:Get("cystedAvailTechPoints") >= 1) or
                    (isEarlyGame and (#sdb:Get("harvesters") >= 3 or numCystedButEmptyResNodes >= 2)) or
                    (not isEarlyGame and numCystedButEmptyResNodes >= 1)
                )

        local emptyTechResPoint = emptyHiveResPoint or emptyTunnelResPoint
        if not rtPosition then
            rtPosition = emptyTechResPoint
        end

        -- If we don't have a cyst that would infest the res node...
        if rtPosition and not GetCystForPoint(sdb, rtPosition) and not GetIsPointOnInfestation(rtPosition) and (emptyTechResPoint or not hasTooMuchCyst) then

            local location = resPoint and resPoint:GetLocationEntity() or GetLocationForPoint(rtPosition) -- Emergency ReCyst will always use GetLocationForPoint (slow)
            if location and brain:GetIsSafeToDropInLocation(location:GetName(), kAlienTeamType, isEarlyGame) then

                local extents = GetExtents(kTechId.Cyst)
                cystPos = GetCystBuildPos(rtPosition)

                if cystPos then

                    local cystPoints = GetCystPoints(cystPos, com:GetTeamNumber())
                    if cystPoints then

                        local cost = math.max(0, (#cystPoints - 1) * kCystCost)
                        if com:GetTeamResources() >= cost then -- Cover ALL cysts cost

                            if isReCystSuffocatingStucture then
                                weight = GetAlienComBaselineWeight(kAlienComActionTypes.ReCyst_Structure)
                            elseif isCystForNewHive or isCystForNewTunnel then
                                weight = GetAlienComBaselineWeight(kAlienComActionTypes.CystNextTechPoint)
                            elseif isEarlyGame then
                                weight = GetAlienComBaselineWeight(kAlienComActionTypes.BuildCystForResNode_EarlyGame)
                            else
                                weight = GetAlienComBaselineWeight(kAlienComActionTypes.BuildCystForResNode)
                            end

                        end

                    end

                end

            else
                weight = 0
            end

        end

        return 
        { 
            name = name, 
            weight = weight,
            targetPos = cystPos,
            techId = kTechId.Cyst,
            unit = com,
            perform = kExecTechId,
        }

    end, -- Cyst

    function(bot, brain, com)
        return 
        { 
            name = "idle", 
            weight = GetAlienComBaselineWeight(kAlienComActionTypes.Idle),
            perform = 
                function(move)
                    if brain.debug then
                        DebugPrint("idling..")
                    end
                end
        }
    end, -- Idle

    function(bot, brain, com)
        local name = "eggs"
        local team = com:GetTeam()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")    --???? Why is this not polled, PER Update instead of PER-FREAK'n-ACTION?! ...it's not cheap to fetch
        local weight = 0.0

        local canAfford = com:GetTeamResources() >= kShiftHatchCost

        if canAfford and doables[kTechId.ShiftHatch] and team:GetEggCount() == 0 and GetGameMinutesPassed() > 2 then
            weight = GetAlienComBaselineWeight(kAlienComActionTypes.SpawnEggs)
        end

        return 
        { 
            name = name, 
            weight = weight,
            targetPos = Vector(1,0,0),
            techId = kTechId.ShiftHatch,
            unit = sdb:Get("hives")[1],
            perform = kExecTechId,
        }
    end, -- Spawn Eggs

    function(bot, brain, com)
        local name = "drifters"
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")    --???? Why is this not polled, PER Update instead of PER-FREAK'n-ACTION?! ...it's not cheap to fetch
        local weight = 0.0
        local drifters = sdb:Get("drifters")

        local drifterBuildPos

        local canAfford = com:GetTeamResources() >= kDrifterCost
        if canAfford and doables[kTechId.DrifterEgg] and sdb:Get("numDrifters") < GetNumHives() then

            drifterBuildPos = GetRandomBuildPosition(
                    kTechId.DrifterEgg,
                    com:GetTeam():GetInitialTechPoint():GetOrigin(),
                    10)

            if drifterBuildPos then
                weight = GetAlienComBaselineWeight(kAlienComActionTypes.BuildDrifter)
            end

        end

        local function IsBeingGrown(self, target)

            if target.hasDrifterEnzyme then
                return true
            end

            for _, drifter in ipairs(drifters) do

                if self ~= drifter then

                    local order = drifter:GetCurrentOrder()
                    if order and order:GetType() == kTechId.Grow then

                        local growTarget = Shared.GetEntity(order:GetParam())
                        if growTarget == target then
                            return true
                        end

                    end

                end

            end

            return false

        end

        for _, drifter in ipairs(sdb:Get("drifters")) do
            if not drifter:GetHasOrder() then
                -- find ungrown structures
                for _, structure in ipairs(GetEntitiesWithMixinForTeam("Construct", drifter:GetTeamNumber() )) do
                    if not structure:GetIsBuilt() and not IsBeingGrown(drifter, structure) and (not structure.GetCanAutoBuild or structure:GetCanAutoBuild()) then
                        drifter:GiveOrder(kTechId.Grow, structure:GetId(), structure:GetOrigin(), nil, false, false)
                    end
                end
                
                --[[
                McG: Remove this because it should only be based on memories, not straight search. Also, should NOT be done at ALL
                for lower-skill servers.

                for _,rp in ientitylist(Shared.GetEntitiesWithClassname("ResourcePoint")) do

                    local attached = rp:GetAttached()
                    if attached and attached:isa("Extractor") and attached:GetIsGhostStructure() and GetIsPointOnInfestation(rp:GetOrigin(), drifter:GetTeamNumber()) then
                        drifter:GiveOrder(kTechId.Move, nil, attached:GetOrigin(), nil, true, true)
                    end

                end
                --]]
            end
            
            -- run away!
            if drifter:GetIsInCombat() and (not drifter:GetCurrentOrder() or drifter:GetCurrentOrder():GetType() ~= kTechId.Move) then
                local hiveData = NearestFriendlyHiveTo(drifter:GetOrigin(), drifter:GetTeamNumber())
                if hiveData and hiveData.entity then
                    drifter:GiveOrder(kTechId.Move, nil, hiveData.entity:GetOrigin(), nil, true, true)
                end
            end
        end

        return 
        { 
            name = name, 
            weight = weight,
            targetPos = drifterBuildPos,
            techId = kTechId.DrifterEgg,
            unit = com,
            perform = kExecTechId,
        }
    end, -- Drifters

    function(bot, brain, com)

        PROFILE("AlienCommanderBrain_Data:hive")

        -- Three "phases": Decision -> Hold -> Perform
        -- This way we can warn (via team chat) that we want to drop a hive.
        
        local name = "hive"
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")        --???? Why is this not polled, PER Update instead of PER-FREAK'n-ACTION?! ...it's not cheap to fetch
        local weight = 0.0

        local targetTP
        local isEmergency = false
        local tooMuchRes = com:GetTeamResources() >= 61

        local hives = sdb:Get("hives")
        isEmergency = #hives == 1 and hives[1]:GetIsInCombat() and hives[1]:GetHealthFraction() < 0.65

        if brain.isDroppingHive then -- "Hold"
            targetTP = Shared.GetEntity(brain.dropHiveTechPointId)

            local safeTP = sdb:Get("techPointToTake")
            local tooMuchResTP = sdb:Get("techPointToTakeInfest")
            local emergencyTP = sdb:Get("techPointToTakeEmergency")

            local techPointValid =
                targetTP and
                not targetTP:GetAttached() and
                (safeTP and safeTP:GetId() == brain.dropHiveTechPointId) or
                (emergencyTP and emergencyTP:GetId() == brain.dropHiveTechPointId) or
                (tooMuchResTP and tooMuchResTP:GetId() == brain.dropHiveTechPointId)

            if not techPointValid then -- Now invalid, say a "cancel" message

                local techPointLocationName = targetTP:GetLocationName()
                techPointLocationName = (techPointLocationName and techPointLocationName ~= "" and techPointLocationName) or "no name"
                local message = string.format("I can't drop a Hive in %s anymore! Something is there...", techPointLocationName)

                bot:SendTeamMessage(message, 0, false, true)
                brain.isDroppingHive = false

            else -- Do nothing else until we drop that hive, this way we guarantee we have enough res while avoiding cancellactions, etc
                weight = GetAlienComBaselineWeight(kAlienComActionTypes.WaitForHiveDrop)
            end

        elseif doables[kTechId.Hive] and
                (
                    isEmergency or
                    brain.hasEnoughTechForHive or
                    tooMuchRes
                ) then

            -- Find a hive slot!
            targetTP = sdb:Get("techPointToTake") -- Also checks if techpoint is "safe"
            if not targetTP then

                if isEmergency then
                    targetTP = sdb:Get("techPointToTakeEmergency")
                elseif tooMuchRes then
                    targetTP = sdb:Get("techPointToTakeInfest") -- Does not require friendly presence
                end

            end

            if targetTP and (isEmergency or tooMuchRes or brain:GetDelayPassedForStructureRedrop(targetTP:GetLocationName())) then

                local isSoleUnbuiltHive = sdb:Get("numUnbuiltHives") <= 0
                local targetTPLocGroup = GetLocationContention():GetLocationGroup(targetTP:GetLocationName())
                local tpHasActiveMarineStructures = false
                if targetTPLocGroup then
                    tpHasActiveMarineStructures = targetTPLocGroup:GetHasActiveStructuresForTeam(GetEnemyTeamNumber(com:GetTeamNumber()))
                end

                if isEmergency or (isSoleUnbuiltHive and (not tpHasActiveMarineStructures or tooMuchRes)) then
                    if isEmergency then
                        weight = GetAlienComBaselineWeight(kAlienComActionTypes.BuildEmergencyHive)
                    else

                        if tooMuchRes then
                            weight = GetAlienComBaselineWeight(kAlienComActionTypes.BuildHive_TooMuchTRes)
                        else
                            weight = GetAlienComBaselineWeight(kAlienComActionTypes.BuildHive)
                        end

                    end
                end
            end
        end

        return 
        { 
            name = name,
            weight = weight,
            targetTP = targetTP,
            isEmergency = isEmergency,
            tooMuchRes = tooMuchRes,
            perform = kExecDropHive,
        }
    end, -- Spawn Hive

--[[
FIXME
 - This does not take into account MOVING of tunnels, thus the placement TechID SEEMS to _always_ be valid...the fuck?
 - This is failing to actually account for existings Tunnels
--]]
    function(bot, brain, com)
        PROFILE("AlienCommanderBrain_Data:TunnelMouthPlacement")

        local kMinRoundTimeForTunnels = 1.25    --TODO Use this when/if we allow for Tunnels palces _without_ Hives (e.g. Crossroads)

        local name = kAlienComActionTypes[kAlienComActionTypes.BuildTunnelEntrance]
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local roundTime = sdb:Get("gameMinutes")
        local tunnelEntrances = sdb:Get("allTunnelEntrances")

        local weight = 0

        local buildPos
        local tunnelTechId = kTechId.None

        local timeSinceLastTunnelEval = Shared.GetTime() - brain.timeLastTunnelEval
        if timeSinceLastTunnelEval >= brain.kTunnelDropEvalInterval and #tunnelEntrances < 8 and brain.droppedNaturalRts then

            local teamInfo = GetTeamInfoEntity(com:GetTeamNumber())
            local tunnelManager = teamInfo:GetTunnelManager()

            --Welp... this is fucking stupid. we _HAVE_ to call this in order for the goddamned manager to update...utter garbage
            tunnelManager:GetTechButtons()

            local hives = sdb:Get("hives")
            local maxTunnelEntrances = #hives * 2


            if #tunnelEntrances < maxTunnelEntrances then

                -- Find first tunnel entrance that is not connected
                local unConnectedTunnelEntrance = sdb:Get("unConnectedTunnelEntrance")

                if unConnectedTunnelEntrance then -- We found a unconnected tunnel
                    if unConnectedTunnelEntrance:GetLocationId() == brain:GetStartingLocationId() then -- It's at main base, find somewhere to put it
                        local expandTP = sdb:Get("safeTechPointNoTunnel") -- Find the closest safe TP with no tunnel, excluding main base
                        if expandTP and CooldownPassedForTunnelDropInLocation(brain, expandTP:GetLocationName()) then
                            -- We found our forward location, go ahead and try to place
                            tunnelTechId = tunnelManager:GetComplimentaryBuildTechIdForTunnelEntrance(unConnectedTunnelEntrance:GetId())
                            if doables[tunnelTechId] then
                                buildPos = GetRandomBuildPosition( tunnelTechId, expandTP:GetOrigin(), kHiveBuildDist)
                                if buildPos then
                                    weight = GetAlienComBaselineWeight(kAlienComActionTypes.BuildTunnelEntrance)
                                end
                            end
                        end

                    else -- We lost a tunnel at main base, so we should just try to place it there.
                        local mainHive = sdb:Get("mainHive")
                        if mainHive and
                                CooldownPassedForTunnelDropInLocation(brain, mainHive:GetLocationName()) and
                                brain:GetIsSafeToDropInLocation(mainHive:GetLocationName(), com:GetTeamNumber(), sdb:Get("isEarlyGame")) then
                            tunnelTechId = tunnelManager:GetComplimentaryBuildTechIdForTunnelEntrance(unConnectedTunnelEntrance:GetId())
                            if doables[tunnelTechId] then
                                buildPos = GetRandomBuildPosition( tunnelTechId, mainHive:GetOrigin(), kHiveBuildDist)
                                if buildPos then
                                    weight = GetAlienComBaselineWeight(kAlienComActionTypes.BuildTunnelEntrance)
                                end
                            end
                        end
                    end
                else -- All tunnels are connected, but we need a new pair for an expansion (or one hive)

                    -- Just place a new tunnel in main base, and let the "unconnected tunnel" part handle the rest
                    local mainHive = sdb:Get("mainHive")
                    if mainHive then

                        local coolDownPassed = CooldownPassedForTunnelDropInLocation(brain, mainHive:GetLocationName())
                        local locationSafe = brain:GetIsSafeToDropInLocation(mainHive:GetLocationName(), com:GetTeamNumber(), sdb:Get("isEarlyGame"))

                        if coolDownPassed and locationSafe then
                            tunnelTechId = brain:GetTunnelBuildTechTechIdForEmptyPair( tunnelManager, doables )
                            if doables[tunnelTechId] then
                                buildPos = GetRandomBuildPosition( tunnelTechId, mainHive:GetOrigin(), kHiveBuildDist)
                                if buildPos then
                                    weight = GetAlienComBaselineWeight(kAlienComActionTypes.BuildTunnelEntrance)
                                end
                            end
                        end

                    end

                end
            end

            brain.timeLastTunnelEval = Shared.GetTime() + brain.kTunnelDropEvalInterval

        end

        return
        {
            name = name,
            weight = weight,
            targetPos = buildPos,
            techId = tunnelTechId,
            unit = com,
            perform = kExecTechId,
        }

    end, -- Tunnel Entrance Placement

    --TODO Add Tunnel Upgrading tests

}

