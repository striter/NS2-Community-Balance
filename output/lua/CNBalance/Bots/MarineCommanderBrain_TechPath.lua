-- ======= Copyright (c) 2003-2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/bots/MarineCommanerBrain_TechPath.lua
--
-- Created by: Darrell Gentry (darrell@unkownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/TechTreeConstants.lua")

kMarineTechPathOverrideType = enum(
{
    'None',
    'Shotguns'
})

local kMaxSimultaneousResearch = 2

local kBuildTechIdToSenseMap =
{
    [kTechId.ArmsLab]            = "mainArmsLab"           ,
    [kTechId.Armory]             = "mainArmory"            ,
    [kTechId.Observatory]        = "mainObservatory"       ,
    [kTechId.PhaseGate]          = "mainPhaseGate"         ,
    [kTechId.AdvancedArmory]     = "mainAdvancedArmory"    ,
    [kTechId.PrototypeLab]       = "mainPrototypeLab"      ,
    [kTechId.JetpackPrototypeLab]       = "mainJetpackLab"      ,
    [kTechId.ExosuitPrototypeLab]       = "mainExosuitLab"      ,
    [kTechId.StandardStation]       = "mainStandardStation"      ,
    --[kTechId.RoboticsFactory]    = "hasRoboticsFactoryInBase"   ,
    --[kTechId.ARCRoboticsFactory] = "hasARCRoboticsFactoryInBase",
}

-- Table of research order of Marine Commander Bot.
-- Marine research is done on different structures, unlike Alien research
-- which simply is done on the Hive, and only has biomass upgrades...
--
-- Therefore, we need to make sure that we have the structures available when upgrading
--
-- IMPORTANT: Make sure all the tech is properly supported all the way through! (Will not check prereqs, etc)
local kMarineCommanderTechPath =
{
    -- Tier 1 (Early Game)
    {
        kTechId.ArmsLab,
        kTechId.Armor1,
        kTechId.Weapons1,
        kTechId.Armory,
        kTechId.GrenadeTech,
    },

    -- Tier 2
    {
        -- Phase Tech
        kTechId.Observatory,
        kTechId.PhaseTech,

        kTechId.PhaseGate,
        kTechId.MinesTech,
        kTechId.Armor2,
    },

    -- Tier 3
    {
        -- Auxillary stuff
        kTechId.ShotgunTech,
        kTechId.Weapons2,
    },
    -- Tier 4
    {
        kTechId.AdvancedArmoryUpgrade, -- Flamethrower, GL, HMG all unlocked by this upgrade
        kTechId.PrototypeLab,
        kTechId.JetpackProtoUpgrade,
    },

    -- Tier 5
    {
        --kTechId.ExosuitTech,
        kTechId.Weapons3,
        kTechId.Armor3,
        
        -- Till comm could really research standard supply?
        --kTechId.StandardSupply,
        --kTechId.DragonBreath,
        --kTechId.MotionTrack,
    },
}

local kTechTestReroutes =
{
    [kTechId.AdvancedArmoryUpgrade] = kTechId.AdvancedArmory,
    [kTechId.JetpackProtoUpgrade] = kTechId.JetpackPrototypeLab,
    [kTechId.ExosuitProtoUpgrade] = kTechId.ExosuitPrototypeLab,
    [kTechId.StandardSupply] = kTechId.StandardStation,
}

local kMarineTechPathOverrides =
{
    {
        type = kMarineTechPathOverrideType.Shotguns,

        techPath =
        {
            -- Tier 1
            {
                kTechId.Armory,
                kTechId.ShotgunTech
            }
        },

        condition = function(sdb, com)

            local timePassed = sdb:Get("gameMinutes") >= 5

            local comTeam = com:GetTeamNumber()
            local techTree = GetTechTree(comTeam)
            assert(techTree)

            local techNode = techTree:GetTechNode(kTechId.ShotgunTech)
            assert(techNode)

            local hasTech = techNode:GetResearched() and techTree:GetHasTech(kTechId.ShotgunTech)
            local inProgress = techNode:GetResearching()

            return timePassed and not hasTech and not inProgress

        end,
    }
}

--[[
    NOTE(Salads): Why do all this?

    Ok, so the tech tree stuff is a bit jank.
    Especially for things like build node, progress variables will be set globally,
    even though multiple builds of the same structure can happen at the same time!

    So, for example, the "research progress" flag for build nodes will never use the "researched" flag,
    and instead globally (overwrites other instances) updates the research progress. So it's possible to have
    a completed structure somewhere, but the technode still returning data that suggests that it's in progress somewhere
    else. On the GUI side, it's just "available", so it lights up, which makes sense, but for other uses makes life a bit difficult :(
--]]

local function GetHasTechForMarineTechPath(brain, com, techId)
    PROFILE("GetHasTechForMarineTechPath")

    -- Seperates "tech id caused by button press", to actual techid we care about to detect tech done-ness
    local originalTechId = techId
    techId = kTechTestReroutes[techId] or techId

    local senses = brain:GetSenses()
    local comTeam = com:GetTeamNumber()
    local techTree = GetTechTree(comTeam)
    assert(techTree)

    local techNode = techTree:GetTechNode(originalTechId)
    assert(techNode)

    local result = kHasTechResult.NotStarted
    local techType = kTechType.Invalid
    if techNode:GetIsResearch() then

        techType = techNode:GetTechType()

        local hasTech = techNode:GetResearched() and techTree:GetHasTech(techId)
        if hasTech then
            result = kHasTechResult.HasTech
        elseif techNode:GetResearching() then
            result = kHasTechResult.InProgressOrUnbuilt
        end

    elseif techNode:GetIsBuild() then

        techType = techNode:GetTechType()

        -- Make sure that the structure is in the main base for the team
        -- We don't want to be researching advanced armory at some random far away location!
        local senseName = kBuildTechIdToSenseMap[techId]
        assert(senseName)

        local structureInBase = senses:Get(senseName)

        if structureInBase then
            if structureInBase:GetIsBuilt() then
                result = kHasTechResult.HasTech
            else
                result = kHasTechResult.InProgressOrUnbuilt
            end
        end

    elseif techNode:GetIsUpgrade() then

        techType = techNode:GetTechType()

        -- First, check if we have the fully upgraded structure in main base
        -- if not, then check for the non-upgraded version
        local upgradedSenseName = kBuildTechIdToSenseMap[techId]
        assert(upgradedSenseName)
        local upgradedStructure = senses:Get(upgradedSenseName)
        if upgradedStructure then
            result = kHasTechResult.HasTech
        else

            -- Now we check for the non-upgraded structure
            local baseStructureTechId = LookupTechData(techId, kTechDataUpgradeTech, kTechId.None)
            if baseStructureTechId ~= kTechId.None then

                local senseName = kBuildTechIdToSenseMap[baseStructureTechId]
                assert(senseName)

                local nonUpgradedStructure = senses:Get(senseName)
                if nonUpgradedStructure then

                    if nonUpgradedStructure:GetResearchingId() == originalTechId then
                        result = kHasTechResult.InProgressOrUnbuilt
                    end

                end
            end
        end
    end

    return result, techType

end

local function GetTechPath(brain, com)

    local techPathType = kMarineTechPathOverrideType.None
    local techPath = kMarineCommanderTechPath

    -- Check all override techpaths
    for _, techPathOverride in ipairs(kMarineTechPathOverrides) do
        if techPathOverride.condition(brain:GetSenses(), com) then
            techPathType = techPathOverride.type
            techPath = techPathOverride.techPath
            break
        end
    end

    return techPathType, techPath

end

-- Finds the first not-started upgrade (build or research)
-- If it steps onto a in-progress one, it keeps stepping until it finds a non-started one, up to kMaxSimultaneousResearch times
-- However, will only do this skipping behavior if the next upgrade tech ids are in the same tier.
function GetMarineComNextTechStep(bot, brain, com)
    PROFILE("GetMarineComTechPathProgress")

    local nextTechStep = kTechId.None
    local nextTechTier = 0
    local techType
    local eHasTechResult

    local techOverrideType, techPath = GetTechPath(brain, com)

    if techOverrideType ~= brain.currentTechpathOverride then
        brain.currentTechpathOverride = techOverrideType

        -- PlayerBot:SendTeamMessage(message, extraTime, needLocalization, ignoreSayDelay)
        if techOverrideType ~= kMarineTechPathOverrideType.None then
            local overrideName = EnumToString(kMarineTechPathOverrideType, techOverrideType)
            local message = string.format("I'm saving up for %s!", overrideName)
            bot:SendTeamMessage(message, 0, false, true)
        end

    end

    local nInCompleteUpgrades = 0 -- Includes both not started and in-progress tech
    for upgradeTier, techTierIds in ipairs(techPath) do

        local isUpgradeTierComplete = true
        for tierStep, techId in ipairs(techTierIds) do

            eHasTechResult, techType = GetHasTechForMarineTechPath(brain, com, techId)
            if eHasTechResult == kHasTechResult.HasTech then
                -- Keep going!
            elseif eHasTechResult == kHasTechResult.InProgressOrUnbuilt then -- Skip!
                nInCompleteUpgrades = nInCompleteUpgrades + 1
                isUpgradeTierComplete = false
            elseif eHasTechResult == kHasTechResult.NotStarted then -- We found it!
                nInCompleteUpgrades = nInCompleteUpgrades + 1
                isUpgradeTierComplete = false
                nextTechStep = techId
                nextTechTier = upgradeTier
                break
            end

        end

        if not isUpgradeTierComplete or nInCompleteUpgrades >= kMaxSimultaneousResearch then
            break
        end

    end

    return nextTechStep, techType, nextTechTier

end
