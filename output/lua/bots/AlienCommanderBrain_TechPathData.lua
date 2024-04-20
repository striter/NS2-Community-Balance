-- ======= Copyright (c) 2003-2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/bots/AlienCommanderBrain_TechPathData.lua
--
-- Created by: Darrell Gentry (darrell@unkownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/TechTreeConstants.lua")

kAlienTechPathOverrideType = enum(
        {
            'None',
            'BileBomb'
        })

local kMaxConcurrentTechSteps = 2
-- Table of research order of Alien Commander Bot.
-- Each group of things in a "tier" can be randomized to provide variance,
-- but they're already ordered in terms of biomass requirements
local kAlienCommanderTechPath =
{

    -- Tier 1
    {
        kTechId.Leap, -- Bio 4
        kTechId.MetabolizeEnergy, -- Bio 3
        kTechId.BileBomb, -- Bio 2
        kTechId.Spores, -- Bio 4
        kTechId.Devour,
    },

    -- Tier 2
    {
        kTechId.Umbra, -- Bio 6
        kTechId.MetabolizeHealth, -- Bio 5
        kTechId.ShiftTunnel, --Bio 5
        kTechId.BoneShield, -- Bio 6
    },

    -- Tier 3
    {
        kTechId.AcidSpray,
        kTechId.Stomp,
        kTechId.Stab,
        kTechId.Xenocide,
    },

    -- Tier 4
    {
        kTechId.Contamination,
        kTechId.XenocideFuel,
    }

}

local kAlienTechPathOverrides =
{
    {
        type = kAlienTechPathOverrideType.BileBomb,

        techPath =
        {
            -- Tier 1
            {
                kTechId.BileBomb,
            }
        },

        condition = function(sdb, com)

            local timePassed = sdb:Get("gameMinutes") >= 5

            local comTeam = com:GetTeamNumber()
            local techTree = GetTechTree(comTeam)
            assert(techTree)

            local techNode = techTree:GetTechNode(kTechId.BileBomb)
            assert(techNode)

            local hasTech = techNode:GetResearched() and techTree:GetHasTech(kTechId.BileBomb)
            local inProgress = techNode:GetResearching()

            return timePassed and not hasTech and not inProgress

        end,
    }
}

local function GetTechPath(brain, com)

    local techPathType = kAlienTechPathOverrideType.None
    local techPath = kAlienCommanderTechPath

    -- Check all override techpaths
    for _, techPathOverride in ipairs(kAlienTechPathOverrides) do
        if techPathOverride.condition(brain:GetSenses(), com) then
            techPathType = techPathOverride.type
            techPath = techPathOverride.techPath
            break
        end
    end

    return techPathType, techPath

end

-- Pass in non-Biomass Tech only!
function GetHasTechForTechPathForAliens(brain, com, techId)

    local senses = brain:GetSenses()
    local comTeam = com:GetTeamNumber()
    local techTree = GetTechTree(comTeam)
    assert(techTree)

    local techNode = techTree:GetTechNode(techId)
    assert(techNode)

    -- If we don't have it, and prereqs are in progress, then

    local result = kHasTechResult.NotStarted
    local techType = techNode:GetTechType()

    if techType == kTechType.Research then

        if techNode:GetResearched() then
            result = kHasTechResult.HasTech
        elseif techNode:GetResearching() then
            result = kHasTechResult.InProgressOrUnbuilt
        end

    elseif techType == kTechType.Build then

        -- AlienTeamInfo:GetBioMassLevel
        -- AlienTeamInfo:GetInProgressBiomassLevel

        if techNode:GetHasTech() then
            result = kHasTechResult.HasTech
        else -- For build nodes, they will automatically unlock when their pre-reqs are done (all biomass atm)

            local preTechIds = {}
            local preTechResults = {}

            table.insert(preTechIds, techNode:GetPrereq1())
            table.insert(preTechIds, techNode:GetPrereq2())

            -- Check pre-reqs, assuming all research upgrades (biomass)
            for _, preTechId in ipairs(preTechIds) do

                if kBioMassTechIdsSet[preTechId] then

                    local result = kHasTechResult.HasTech
                    local preReq1TechNode = techTree:GetTechNode(preTechId)
                    if preReq1TechNode then
                        if preReq1TechNode:GetResearched() then
                            result = kHasTechResult.HasTech
                        elseif preReq1TechNode:GetResearching() then
                            result = kHasTechResult.InProgressOrUnbuilt
                        else
                            result = kHasTechResult.NotStarted
                        end
                    end

                    table.insert(preTechResults, result)

                end
            end

            -- Now parse the results
            if preTechResults[1] == kHasTechResult.HasTech and preTechResults[2] == kHasTechResult.HasTech then
                result = kHasTechResult.HasTech
            elseif preTechResults[1] == kHasTechResult.InProgressOrUnbuilt or preTechResults[2] == kHasTechResult.InProgressOrUnbuilt then
                result = kHasTechResult.InProgressOrUnbuilt
            else
                result = kHasTechResult.NotStarted
            end

        end

    end -- END build node

    return result

end

function GetTechPathProgressForAlien(brain, com)
    PROFILE("GetTechPathProgressForAlien")

    local senses = brain:GetSenses()
    local doables = senses:Get("doableTechIds")
    local comTeam = com:GetTeamNumber()
    local techTree = GetTechTree(comTeam)
    if not techTree then return end

    local techOverrideType, techPath = GetTechPath(brain, com)
    if techOverrideType ~= brain.currentTechpathOverride then
        brain.currentTechpathOverride = techOverrideType

        -- PlayerBot:SendTeamMessage(message, extraTime, needLocalization, ignoreSayDelay)
        --if techOverrideType ~= kAlienTechPathOverrideType.None then
        --    local overrideName = EnumToString(kAlienTechPathOverrideType, techOverrideType)
        --    local message = string.format("I'm saving up for %s!", overrideName)
        --    bot:SendTeamMessage(message, 0, false, true)
        --end

    end

    local resultTier = 0
    local resultTech = kTechId.None
    local eResultTech = kHasTechResult.None

    local firstNotStartedTech = kTechId.None
    local eFirstNotStartedTech = kHasTechResult.None

    local maxTier = #GetEntitiesAliveForTeam("Hive", comTeam)
    for iTier, tierTechIds in ipairs(techPath) do
        if iTier > maxTier then
            resultTech = kTechId.Hive
            break
        end

        local foundNextTech = false
        local lastTierStepNum = #tierTechIds

        resultTier = iTier
        local isUpgradeTierComplete = true
        for i, tierTechId in ipairs(tierTechIds) do

            local hasTech = false
            local techNode = techTree:GetTechNode(tierTechId)
            local eHasTechResult = GetHasTechForTechPathForAliens(brain, com, tierTechId)
            if eHasTechResult == kHasTechResult.HasTech then
                -- Keep going!
            elseif eHasTechResult == kHasTechResult.InProgressOrUnbuilt then -- Skip!
                isUpgradeTierComplete = false

                if i == lastTierStepNum then -- Last step in tier, consider a hive drop
                    resultTech = kTechId.Hive
                    break
                end

            elseif eHasTechResult == kHasTechResult.NotStarted then -- We found it! (Skip if can't do yet)
                isUpgradeTierComplete = false

                if firstNotStartedTech == kTechId.None then
                    firstNotStartedTech = tierTechId
                    eFirstNotStartedTech = eHasTechResult
                end

                if doables[tierTechId] then
                    resultTech = tierTechId
                    eResultTech = eHasTechResult
                end

                break
            end

        end

        if not isUpgradeTierComplete then
            break
        end

    end

    local finalTech = firstNotStartedTech
    local eFinalTech = eFirstNotStartedTech
    if resultTech ~= kTechId.None then
        finalTech = resultTech
        eFinalTech = eResultTech
    end

    return resultTier, finalTech, eFinalTech

end
