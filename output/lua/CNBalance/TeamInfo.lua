-- ======= Copyright (c) 2003-2016, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/TeamInfo.lua
--
-- TeamInfo is used to sync information about a team to clients.
-- A client on team 1 or 2 will only receive team info regarding their
-- own team while a client on the kSpectatorIndex team will receive both
-- teams info.
--
-- Created by Brian Cronin (brianc@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/TeamMixin.lua")

class 'TeamInfo' (Entity)

TeamInfo.kMapName = "TeamInfo"

TeamInfo.kTechTreeUpdateInterval = 1

-- max 100 tres/min, max 1000 minute game; should be enough 
kMaxTotalTeamResources = 100000
kMaxTotalPersonalResources = 100000
local networkVars =
{
    teamResources =  "float (0 to " .. kMaxTeamResources .. " by 0.1 [ 4 ])",
    totalTeamResources = "float (0 to " .. kMaxTotalTeamResources .. " by 1 [ 1 ])",
    teamRefundResourcesBase = "float (0 to " .. kMaxTotalTeamResources .. " by 1 [ 1 ])",
    personalResources = "float (0 to " .. kMaxTotalPersonalResources .. " by 0.1) [ 4 ]",
    numResourceTowers = "integer (0 to 99)",
    numCapturedResPoints = "integer (0 to 99)",
    latestResearchId = "integer",
    numCapturedTechPoint = "integer (0 to 99)",
    lastCommPingTime = "time",
    lastCommPingPosition = "vector",
    lastCommIsBot = "boolean",
    techActiveMask = "integer",
    techOwnedMask = "integer",
    playerCount = "integer (0 to " .. kMaxPlayers - 1 .. ")",
    spawnQueueTotal = "integer (0 to 64)",  --max val should be ref'd from somewhere
    supplyUsed = "integer (0 to " ..kStartSupply + 10 * kSupplyEachTechPoint .. ")",
    maxSupply = "integer (0 to " .. kStartSupply + 10 * kSupplyEachTechPoint .. ")",
    kills = "integer (0 to 9999)"
}

AddMixinNetworkVars(TeamMixin, networkVars)

-- Relevant techs must be ordered with children techs coming after their parents


TeamInfo.kRelevantTechIdsMarine =
{
    kTechId.MilitaryProtocol,
    kTechId.ShotgunTech,
    kTechId.MinesTech,
    kTechId.GrenadeTech,

    kTechId.AdvancedArmoryUpgrade,

    kTechId.Weapons1,
    kTechId.Weapons2,
    kTechId.Weapons3,
    kTechId.Armor1,
    kTechId.Armor2,
    kTechId.Armor3,

    kTechId.PrototypeLab,
    kTechId.JetpackTech,
    kTechId.ExosuitTech,

    kTechId.UpgradeRoboticsFactory,

    kTechId.PhaseTech,

    kTechId.StandardSupply,
    kTechId.LightMachineGunUpgrade,
    kTechId.DragonBreath,
    kTechId.Cannon,

    kTechId.ExplosiveSupply,
    --kTechId.GrenadeLauncherDetectionShot,
    --kTechId.GrenadeLauncherAllyBlast,
    
    kTechId.ElectronicSupply,
    kTechId.GrenadeLauncherUpgrade,
    kTechId.MACEMPBlast,
    kTechId.PoweredExtractorTech,
    kTechId.PoweredExtractorUpgrade,

    kTechId.ArmorSupply,
    kTechId.ArmorRegen,
    kTechId.LifeSustain,
}

TeamInfo.kRelevantTechIdsAlien =
{
    kTechId.CragHive,
    kTechId.UpgradeToCragHive,
    kTechId.Shell,
    kTechId.TwoShells,
    kTechId.ThreeShells,

    kTechId.ShadeHive,
    kTechId.UpgradeToShadeHive,
    kTechId.Veil,
    kTechId.TwoVeils,
    kTechId.ThreeVeils,

    kTechId.ShiftHive,
    kTechId.UpgradeToShiftHive,
    kTechId.Spur,
    kTechId.TwoSpurs,
    kTechId.ThreeSpurs,

    kTechId.ResearchBioMassOne,
    kTechId.ResearchBioMassTwo,
    kTechId.ResearchBioMassThree,

    kTechId.ShiftTunnel,
    kTechId.CragTunnel,
    kTechId.ShadeTunnel,

    --kTechId.Leap,
    --kTechId.Xenocide,
    --kTechId.XenocideFuel,
    --
    --kTechId.BileBomb,
    --kTechId.Rappel,
    --kTechId.AcidSpray,
    --
    --kTechId.Umbra,
    --kTechId.Spores,
    --
    --kTechId.MetabolizeEnergy,
    --kTechId.MetabolizeHealth,
    --kTechId.Stab,
    --
    --kTechId.Charge,
    --kTechId.BoneShield,
    --kTechId.Devour,
    --kTechId.Stomp,
}

local function CreateRelevantIdMaskMarine()

    local t = {}

    for i, techId in ipairs(TeamInfo.kRelevantTechIdsMarine) do

        local s = EnumToString(kTechId, techId)
        t[i] = s

    end


    TeamInfo.kRelevantIdMaskMarine = CreateBitMask(t)

end

local function CreateRelevantIdMaskAlien()

    local t = {}

    for i,techId in ipairs(TeamInfo.kRelevantTechIdsAlien) do

        local s = EnumToString(kTechId, techId)
        t[i] = s

    end


    TeamInfo.kRelevantIdMaskAlien = CreateBitMask(t)

end

function TeamInfo:OnCreate()

    Entity.OnCreate(self)

    CreateRelevantIdMaskMarine()
    CreateRelevantIdMaskAlien()

    if Server then

        self:SetUpdates(true, kRealTimeUpdateRate)

        self:Reset()

    end

    InitMixin(self, TeamMixin)

end

if Server then

    function TeamInfo:Reset()

        self.teamResources = 0
        self.personalResources = 0
        self.numResourceTowers = 0
        self.latestResearchId = 0
        self.researchDisplayTime = 0
        self.lastTechPriority = 0
        self.lastCommPingTime = 0
        self.lastCommPingPosition = Vector(0,0,0)
        self.lastCommIsBot = false
        self.lastCommLoginTime = 0
        self.totalTeamResources = 0
        self.teamRefundResourcesBase = 0
        self.techActiveMask = 0
        self.techOwnedMask = 0
        self.playerCount = 0
        self.spawnQueueTotal = 0
        self.workerCount = 0
        self.kills = 0
        self.supplyUsed = 0
        self.maxSupply = 0
        self.userTrackersDirty = true

    end

end

if Client then

    function TeamInfo:OnInitialized()

        Entity.OnInitialized(self)

        -- Hook up some callbacks for the GUI system.
        -- (These respect relevancy because they will only receive updates for TeamInfo that are
        -- relevant to the current player, eg both if player is spectating.)

        -- Notify GUI system when a team's resources change.
        self:AddFieldWatcher("teamResources",
                function(self2)
                    local teamNumber = self2:GetTeamNumber()
                    local eventName = string.format("OnTeam%dResourcesChanged", teamNumber)
                    GetGlobalEventDispatcher():FireEvent(eventName, self2.teamResources)
                    return true -- preserve field watcher
                end)

        -- Notify GUI system when a team's RT-count changes.
        self:AddFieldWatcher("numResourceTowers",
                function(self2)
                    local teamNumber = self2:GetTeamNumber()
                    local eventName = string.format("OnTeam%dResourceTowerCountChanged", teamNumber)
                    GetGlobalEventDispatcher():FireEvent(eventName, self2.numResourceTowers)
                    return true -- preserve field watcher
                end)

        -- Notify GUI system when a team's consumed supply changes.
        self:AddFieldWatcher("supplyUsed",
                function(self2)
                    local teamNumber = self2:GetTeamNumber()
                    local eventName = string.format("OnTeam%dSupplyUsedChanged", teamNumber)
                    GetGlobalEventDispatcher():FireEvent(eventName, self2.supplyUsed)
                    return true -- preserve field watcher
                end)

        self:AddFieldWatcher("maxSupply",
                function(self2)
                    local teamNumber = self2:GetTeamNumber()
                    local eventName = string.format("OnTeam%dSupplyMaxChanged", teamNumber)
                    GetGlobalEventDispatcher():FireEvent(eventName, self2.maxSupply)
                    return true -- preserve field watcher
                end)
        
        -- Notify GUI system when a team's count of respawning players changes.
        self:AddFieldWatcher("spawnQueueTotal",
                function(self2)
                    local teamNumber = self2:GetTeamNumber()
                    local eventName = string.format("OnTeam%dSpawnQueueTotalChanged", teamNumber)
                    GetGlobalEventDispatcher():FireEvent(eventName, self2.spawnQueueTotal)
                    return true -- preserve field watcher
                end)

        -- Fire an event signifying that a new TeamInfo has just been initialized.
        GetGlobalEventDispatcher():FireEvent("OnTeamInfoInitialized", self)

    end

end

function TeamInfo:GetSpawnQueueTotal()
    return self.spawnQueueTotal
end

function TeamInfo:UpdateInfo()

    if self.team then

        self:SetTeamNumber(self.team:GetTeamNumber())
        self.teamResources = self.team:GetTeamResources()
        self.playerCount = Clamp(self.team:GetNumPlayers(), 0, 31)
        self.totalTeamResources = self.team:GetTotalTeamResources()
        self.teamRefundResourcesBase = self.team:GetRefundBase()
        self.personalResources = 0
        for index, player in ipairs(self.team:GetPlayers()) do
            self.personalResources = self.personalResources + player:GetResources()
        end

        local rtCount = 0
        local rtActiveCount = 0
        local rts = GetEntitiesForTeam("ResourceTower", self:GetTeamNumber())
        for index, rt in ipairs(rts) do

            if rt:GetIsAlive() then
                rtCount = rtCount + 1
                if rt:GetIsCollecting() then
                    rtActiveCount = rtActiveCount + 1
                end
            end

        end

        self.numCapturedResPoints = rtCount
        self.numResourceTowers = rtActiveCount
        self.kills = self.team:GetKills()

        if Server then

            if self.lastTechTreeUpdate == nil or (Shared.GetTime() > (self.lastTechTreeUpdate + TeamInfo.kTechTreeUpdateInterval)) then
                if not GetGamerules():GetGameStarted() then
                    self.techActiveMask = 0
                    self.techOwnedMask = 0
                else
                    self:UpdateTechTreeInfo(self.team:GetTechTree())
                end
            end

            if self.latestResearchId ~= 0 and self.researchDisplayTime < Shared.GetTime() then

                self.latestResearchId = 0
                self.researchDisplayTime = 0
                self.lastTechPriority = 0

            end

            local team = self:GetTeam()
            self.numCapturedTechPoint = team:GetNumCapturedTechPoints()

            self.lastCommPingTime = team:GetCommanderPingTime()
            self.lastCommPingPosition = team:GetCommanderPingPosition() or Vector(0,0,0)

            self.supplyUsed = team:GetSupplyUsed()
            self.maxSupply = team:GetMaxSupply()

            self.spawnQueueTotal = team:GetTotalInRespawnQueue()

            if self.userTrackersDirty then
                self:UpdateUserTrackers()
                self.userTrackersDirty = false
            end

        end

    end

end

function TeamInfo:SetUserTrackersDirty()
    self.userTrackersDirty = true
end

function TeamInfo:UpdateUserTrackers()
    -- for others to override.
end

function TeamInfo:GetRelevantTech()
    if self:GetTeamType() == kMarineTeamType then
        return TeamInfo.kRelevantIdMaskMarine, TeamInfo.kRelevantTechIdsMarine
    else
        return TeamInfo.kRelevantIdMaskAlien, TeamInfo.kRelevantTechIdsAlien
    end
end

function TeamInfo:GetSupplyUsed()
    return self.supplyUsed
end
function TeamInfo:GetMaxSupply()
    return self.maxSupply
end

function TeamInfo:GetNumWorkers()
    return self.workerCount
end

function TeamInfo:GetPingTime()
    return self.lastCommPingTime
end

function TeamInfo:GetPingPosition()
    return self.lastCommPingPosition
end

function TeamInfo:GetLastCommIsBot()
    return self.lastCommIsBot
end

function TeamInfo:SetWatchTeam(team)

    self.team = team
    self:SetTeamNumber(team:GetTeamNumber())
    self:UpdateInfo()
    self:UpdateRelevancy()

end

function TeamInfo:GetNumCapturedResPoints()
    return self.numCapturedResPoints
end

function TeamInfo:OnCommanderLogin( commanderPlayer, forced )

    self.lastCommIsBot = commanderPlayer:GetIsVirtual()
    if forced or GetGamerules():GetGameState() > kGameState.PreGame then
        if self.lastCommLoginTime == 0 then
            commanderPlayer:SetResources(0)
        end
        self.lastCommLoginTime = Shared.GetTime()
    end
end

function TeamInfo:GetTeamResources()
    return self.teamResources
end

function TeamInfo:GetPersonalResources()
    return self.personalResources
end

function TeamInfo:GetNumResourceTowers()
    return self.numResourceTowers
end

function TeamInfo:GetKills()
    return self.kills
end

function TeamInfo:UpdateRelevancy()

    self:SetRelevancyDistance(Math.infinity)

    local mask = 0

    if self:GetTeamNumber() == kTeam1Index then
        mask = kRelevantToTeam1
    elseif self:GetTeamNumber() == kTeam2Index then
        mask = kRelevantToTeam2
    end

    self:SetExcludeRelevancyMask(mask)

end

function TeamInfo:OnUpdate(deltaTime)
    self:UpdateInfo()
end

function TeamInfo:SetLatestResearchedTech(researchId, displayTime, techPriority)

    if techPriority >= self.lastTechPriority then

        self.latestResearchId = researchId
        self.researchDisplayTime = displayTime
        self.lastTechPriority = techPriority

    end

end

function TeamInfo:UpdateTechTreeInfo(techTree)

    if not techTree then return end

    local relevantIdMask, relevantTechIds = self:GetRelevantTech()
    for i,techId in ipairs(relevantTechIds) do

        local techNode = techTree:GetTechNode(techId)

        if techNode and relevantIdMask then

            self:UpdateBitmasks(techId, techNode)

        end

    end

    self.lastTechTreeUpdate = Shared.GetTime()

end

function TeamInfo:GetNumCapturedTechPoints()
    return self.numCapturedTechPoint
end

function TeamInfo:GetLatestResearchedTech()
    return self.latestResearchId
end

function TeamInfo:GetTotalTeamResources()
    return self.totalTeamResources
end

function TeamInfo:GetTeamTechTreeInfo()
    return self.techActiveMask, self.techOwnedMask
end

--[[
A - Active
O - Owned
-----
A O |
-----
0 0 | None
1 0 | Researching
0 1 | Lost
1 1 | Researched
-----]]

function TeamInfo:UpdateBitmasks(techId, techNode)

    local relevantIdMask, relevantTechIds = self:GetRelevantTech()

    local techIdString = EnumToString(kTechId, techId)
    local mask = relevantIdMask[techIdString]

    -- Tech researching or researched
    if (techNode:GetResearching() and not techNode:GetResearched()) or techNode:GetHasTech() then
        self.techActiveMask = bit.bor(self.techActiveMask, mask)
    else
        self.techActiveMask = bit.band(self.techActiveMask, bit.bnot(mask))
    end

    -- Tech has been owned at some point
    if techNode:GetHasTech() then
        self.techOwnedMask = bit.bor(self.techOwnedMask, mask)
    end

    -- Hide prerequisite techs when this tech has been researched
    if techNode:GetResearched() or (techNode:GetIsSpecial() and techNode:GetHasTech()) then
        local preq1 = techNode:GetPrereq1()
        local preq2 = techNode:GetPrereq2()
        if preq1 ~= nil then
            local msk = relevantIdMask[EnumToString(kTechId, preq1)]
            if msk then
                self.techActiveMask = bit.band(self.techActiveMask, bit.bnot(msk))
                self.techOwnedMask = bit.band(self.techOwnedMask, bit.bnot(msk))
            end
        end
        if preq2 ~= nil then
            local msk = relevantIdMask[EnumToString(kTechId, preq2)]
            if msk then
                self.techActiveMask = bit.band(self.techActiveMask, bit.bnot(msk))
                self.techOwnedMask = bit.band(self.techOwnedMask, bit.bnot(msk))
            end
        end
    end

end

function TeamInfo:GetPlayerCount()
    return self.playerCount
end

Shared.LinkClassToMap("TeamInfo", TeamInfo.kMapName, networkVars)

function TeamInfo_GetUserTrackerNetvarName(weaponMapName)
    local id = string.gsub(weaponMapName, "+", "plus")
    return string.format("num%sUsers", id)
end

function TeamInfo_SetUserTrackersDirty(teamIndex)

    if not Server then return end

    assert(teamIndex)

    -- kTeam1Index
    -- kTeam2Index
    local teamInfoEnt = GetTeamInfoEntity(teamIndex)
    if teamInfoEnt then
        teamInfoEnt:SetUserTrackersDirty()
    end

end

