-- ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
--
-- lua/GameInfo.lua
--
-- GameInfo is used to sync information about the game state to clients.
--
-- Created by Brian Cronin (brianc@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Globals.lua")


class 'GameInfo' (Entity)

GameInfo.kMapName = "gameinfo"

local networkVars =
{
    state = "enum kGameState",
    startTime = "time",
    averagePlayerSkill = "integer",
    rookieMode = "boolean",
    numClientsTotal = "integer",
    numPlayers = "integer",
    numBots = "integer",
	isDedicated = "boolean",
    serverIp = "string (16)",
    serverPort = "string (16)",

    marineDeadlockTime = "time",
    alienDeadlockTime = "time",

    --Skins are in this class instead of TeamInfo so it's propagated to all clients since
    --the Team entities are only propagated to their respective team's clients.
    team1Cosmetic1 = "integer (1 to 10)",
    team1Cosmetic2 = "integer (1 to 10)",
    team1Cosmetic3 = "integer (1 to 10)",
    team1Cosmetic4 = "integer (1 to 10)",
    team1Cosmetic5 = "integer (1 to 10)",

    team2Cosmetic1 = "integer (1 to 10)",
    team2Cosmetic2 = "integer (1 to 10)",
    team2Cosmetic3 = "integer (1 to 10)",
    team2Cosmetic4 = "integer (1 to 10)",
    team2Cosmetic5 = "integer (1 to 10)",
    team2Cosmetic6 = "integer (1 to 10)",

    -- Network variables for visibility of end-of-round stats UI. (It's a server disable-able option)
    showEndStatsAuto = "boolean",
    showEndStatsTeamBreakdown = "boolean",
}

function GameInfo:OnCreate()

    Entity.OnCreate(self)
    
    if Server then
    
        self:SetPropagate(Entity.Propagate_Always)
        self:SetUpdates(false)
        
        self:SetState(kGameState.NotStarted)

        self.startTime = 0
        self.marineDeadlockTime = 0
        self.alienDeadlockTime = 0
        self.averagePlayerSkill = 0
        self.numClientsTotal = 0
        self.numPlayers = 0
        self.numBots = 0
        self.isDedicated = Server.IsDedicated()
        self.serverIp = Server.GetIpAddress()
        self.serverPort = Server.GetPort()

    end

    --Default values to all possible "Normal" skins
    self.team1Cosmetic1 = 1
    self.team1Cosmetic2 = 1
    self.team1Cosmetic3 = 1
    self.team1Cosmetic4 = 1
    self.team1Cosmetic5 = 1

    self.team2Cosmetic1 = 1
    self.team2Cosmetic2 = 1
    self.team2Cosmetic3 = 1
    self.team2Cosmetic4 = 1
    self.team2Cosmetic5 = 1
    self.team2Cosmetic6 = 1

    -- Initialize GameInfo vars for the end of round stats UI.
    if Server then
        self.showEndStatsAuto = AdvancedServerOptions["autodisplayendstats"].currentValue == true
        self.showEndStatsTeamBreakdown = AdvancedServerOptions["endstatsteambreakdown"].currentValue == true
    end

    if Client then
        self.prevWinner = nil
        self.prevTimeLength = nil
        self.prevTeamsSkills = nil
    end
    
end

function GameInfo:GetIsDedicated()
    return self.isDedicated
end

function GameInfo:GetStartTime()
    return self.startTime
end

function GameInfo:GetMarineDeadlockTime()
    return self.marineDeadlockTime
end

function GameInfo:IsAlienDeadlocking()
    return self.alienDeadlockTime < Shared.GetTime()
end

function GameInfo:GetAlienDeadlockTime()
    return self.alienDeadlockTime
end

function GameInfo:GetGameEnded()
    return self.state > kGameState.Started
end

function GameInfo:GetGameStarted()
    return self.state == kGameState.Started
end

function GameInfo:GetCountdownActive()
    return self.state == kGameState.Countdown
end

function GameInfo:GetWarmUpActive()
    return self.state == kGameState.WarmUp
end

function GameInfo:GetState()
    return self.state
end

function GameInfo:GetTeam1CostmeticSlot(slotNum)
    assert(slotNum >= 1 and slotNum <= 5)

    if slotNum == 1 then    --McG: bleh...damn I wish Lua had 'switch'
        return self.team1Cosmetic1
    elseif slotNum == 2 then
        return self.team1Cosmetic2
    elseif slotNum == 3 then
        return self.team1Cosmetic3
    elseif slotNum == 4 then
        return self.team1Cosmetic4
    elseif slotNum == 5 then
        return self.team1Cosmetic5
    end
end

function GameInfo:GetTeam2CostmeticSlot(slotNum)
    assert(slotNum >= 1 and slotNum <= 6)

    if slotNum == 1 then 
        return self.team2Cosmetic1
    elseif slotNum == 2 then
        return self.team2Cosmetic2
    elseif slotNum == 3 then
        return self.team2Cosmetic3
    elseif slotNum == 4 then
        return self.team2Cosmetic4
    elseif slotNum == 5 then
        return self.team2Cosmetic5
    elseif slotNum == 6 then
        return self.team2Cosmetic6
    end
end

function GameInfo:GetTeamCosmeticSlot(teamNum, cosmeticSlot)
    assert(cosmeticSlot >= kTeamCosmeticSlot1 and cosmeticSlot <= kTeamCosmeticSlot6)
    assert(teamNum == kTeam1Index or teamNum == kTeam2Index)

    if teamNum == kTeam1Index then
        return self:GetTeam1CostmeticSlot(cosmeticSlot)
    elseif teamNum == kTeam2Index then
        return self:GetTeam2CostmeticSlot(cosmeticSlot)
    end
end

if Server then

    function GameInfo:SetTeam1CosmeticSlot( cosmeticSlot, cosmetic )
        assert(cosmeticSlot >= kTeamCosmeticSlot1 and cosmeticSlot <= kTeamCosmeticSlot5)
        if cosmeticSlot == kTeamCosmeticSlot1 then
            self.team1Cosmetic1 = cosmetic
        elseif cosmeticSlot == kTeamCosmeticSlot2 then
            self.team1Cosmetic2 = cosmetic
        elseif cosmeticSlot == kTeamCosmeticSlot3 then
            self.team1Cosmetic3 = cosmetic
        elseif cosmeticSlot == kTeamCosmeticSlot4 then
            self.team1Cosmetic4 = cosmetic
        elseif cosmeticSlot == kTeamCosmeticSlot5 then
            self.team1Cosmetic5 = cosmetic
        end
    end

    function GameInfo:SetTeam2CosmeticSlot( cosmeticSlot, cosmetic )
        assert(cosmeticSlot >= kTeamCosmeticSlot1 and cosmeticSlot <= kTeamCosmeticSlot6)
        if cosmeticSlot == kTeamCosmeticSlot1 then
            self.team2Cosmetic1 = cosmetic
        elseif cosmeticSlot == kTeamCosmeticSlot2 then
            self.team2Cosmetic2 = cosmetic
        elseif cosmeticSlot == kTeamCosmeticSlot3 then
            self.team2Cosmetic3 = cosmetic
        elseif cosmeticSlot == kTeamCosmeticSlot4 then
            self.team2Cosmetic4 = cosmetic
        elseif cosmeticSlot == kTeamCosmeticSlot5 then
            self.team2Cosmetic5 = cosmetic
        elseif cosmeticSlot == kTeamCosmeticSlot6 then
            self.team2Cosmetic6 = cosmetic
        end
    end

    function GameInfo:SetTeamCosmeticSlot( teamNum, cosmeticSlot, cosmeticId )
        assert(teamNum == kTeam1Index or teamNum == kTeam2Index)
        assert(cosmeticSlot >= kTeamCosmeticSlot1 and cosmeticSlot <= kTeamCosmeticSlot6)
        assert(cosmeticId)

        if teamNum == kTeam1Index then
            self:SetTeam1CosmeticSlot(cosmeticSlot, cosmeticId)
        elseif teamNum == kTeam2Index then
            self:SetTeam2CosmeticSlot(cosmeticSlot, cosmeticId)
        end

    end

end --End-Server


function GameInfo:GetAveragePlayerSkill()
    return self.averagePlayerSkill
end

function GameInfo:GetNumClientsTotal()
    return self.numClientsTotal
end

function GameInfo:GetNumPlayers()
    return self.numPlayers
end

function GameInfo:GetNumBots()
    return self.numBots
end

function GameInfo:GetRookieMode()
    return self.rookieMode
end

if Client then
    --Reset game end stats caches
    function GameInfo:OnResetGame()
        self.prevWinner = nil
        self.prevTimeLength = nil
        self.prevTeamsSkills = nil
    end

    function GameInfo:OnGameStateChange()
        SetWarmupActive(self.state == kGameState.WarmUp)
        return true -- continue watching the network field
    end
    
    function GameInfo:GetRoundCompleted()
        return self.prevWinner and self.prevTeamsSkills and self.prevTimeLength
    end

    function GameInfo:OnInitialized()
        Entity.OnInitialized(self)

        self.state = kGameState.NotStarted
        self:AddFieldWatcher("state", GameInfo.OnGameStateChange)
    end
end

if Server then

    function GameInfo:SetStartTime(startTime)
        self.startTime = startTime
    end

    function GameInfo:SetMarineDeadlockTime(time)
        self.marineDeadlockTime = time
    end
    
    function GameInfo:SetAlienDeadlockTime(time)
        self.alienDeadlockTime = time
    end
    
    function GameInfo:SetState(state)
        self.state = state

        SetWarmupActive(state == kGameState.WarmUp)
    end
    
    function GameInfo:SetAveragePlayerSkill(skill)
        self.averagePlayerSkill = skill
    end
    
    function GameInfo:SetNumClientsTotal( numClientsTotal )
        self.numClientsTotal = numClientsTotal
    end

    function GameInfo:SetNumPlayers( numPlayers )
        self.numPlayers = numPlayers
    end

    function GameInfo:SetNumBots( numBots )
        self.numBots = numBots
    end

    function GameInfo:SetRookieMode(mode)
        self.rookieMode = mode
    end

end

Shared.LinkClassToMap("GameInfo", GameInfo.kMapName, networkVars)