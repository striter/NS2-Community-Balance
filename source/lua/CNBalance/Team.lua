local function GetExtendedTime()
    local gameRules = GetGamerules()
    local gameLength = Shared.GetTime() - gameRules:GetGameStartTime()
    local estimateLength = math.max(0,gameLength - 1200)   --activate since 20 min pow(max(x-1200,0)/450,2) * 2
    local parameter = estimateLength / 450
    local extendTime = parameter * parameter * 2
    return extendTime
end

function Team:PutPlayerInRespawnQueue(player)

    assert(player)
    
    -- don't add to respawn queue during concede sequence.
    if GetConcedeSequenceActive() then
        return
    end
    
    -- Place player in a "holding area" if auto-team balance is enabled.
    if self.autoTeamBalanceEnabled then
    
        -- Place this new player into the holding area.
        self.respawnQueueTeamBalance:Insert(player:GetId())
        
        player:SetWaitingForTeamBalance(true)

        self:UpdateRespawnQueueTeamBalance()
        
    else
    
        local extraTime = 0
        if player.spawnBlockTime then
            extraTime = math.max(0, player.spawnBlockTime - Shared.GetTime())
        end
        
        if player.spawnReductionTime then
            extraTime = extraTime - player.spawnReductionTime
            player.spawnReductionTime = nil
        end
    
    --////Extent the respawn time to prevent "bie bie le"
        extraTime = extraTime + GetExtendedTime()
    --///
        player:SetRespawnQueueEntryTime(Shared.GetTime() + extraTime)
        self.respawnQueue:Insert(player:GetId())
        
        if self.OnRespawnQueueChanged then
            self:OnRespawnQueueChanged()
        end
        
    end
    
end

--Since its only used by the infantry portal,make it 
function Team:GetOldestQueuedPlayer()

    local playerToSpawn
    local earliestTime = -1
    
    local curTime = Shared.GetTime()
    for i = 1, self.respawnQueue:GetCount() do

        local playerid = self.respawnQueue:GetValueAtIndex(i)
        local player = Shared.GetEntity(playerid)
        
        if player and player.GetRespawnQueueEntryTime then
        
            local currentPlayerTime = player:GetRespawnQueueEntryTime()
            
            -------------------------//////////////////////////// Ensure its awaited
            if currentPlayerTime and currentPlayerTime <= curTime and (earliestTime == -1 or currentPlayerTime < earliestTime) then
            
                playerToSpawn = player
                earliestTime = currentPlayerTime
                
            end
            
        end
        
    end
    
    if playerToSpawn and ( not playerToSpawn.spawnBlockTime or playerToSpawn.spawnBlockTime <= curTime ) then    
        return playerToSpawn
    end
    
end
