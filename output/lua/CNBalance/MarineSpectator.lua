

local function UpdateWaveTime(self)

    if self:GetIsDestroyed() then
        return false
    end

    local team = self:GetTeam()
    assert(team:GetIsMarineTeam(), team.teamName)

    local entryTime = self:GetRespawnQueueEntryTime() or 0
    self.timeWaveSpawnEnd = entryTime

    Server.SendNetworkMessage(Server.GetOwner(self), "SetTimeWaveSpawnEnds", { time = self.timeWaveSpawnEnd }, true)

    if not self.sentRespawnMessage then

        Server.SendNetworkMessage(Server.GetOwner(self), "SetIsRespawning", { isRespawning = true }, true)
        self.sentRespawnMessage = true

    end

    return true
end

local baseOnInitialized = MarineSpectator.OnInitialized
function MarineSpectator:OnInitialized()
    baseOnInitialized(self)
    if Server then
        self:AddTimedCallback(UpdateWaveTime, 0.1)
    end
end

if Server then
    function MarineSpectator:GetDesiredSpawnPoint()
        return self.desiredSpawnPoint
    end
    
    local onCopyPlayerDataFrom = MarineSpectator.CopyPlayerDataFrom
    function MarineSpectator:CopyPlayerDataFrom( player )
        onCopyPlayerDataFrom(self,player)
        self.primaryRespawn = player.primaryRespawn
        self.secondaryRespawn = player.secondaryRespawn
        self.meleeRespawn = player.meleeRespawn
    end


    function MarineSpectator:Replace(mapName, newTeamNumber, preserveWeapons, atOrigin, extraValues, _)

        Server.SendNetworkMessage(Server.GetOwner(self), "SetIsRespawning", { isRespawning = false }, true)
        return TeamSpectator.Replace(self, mapName, newTeamNumber, preserveWeapons, atOrigin, extraValues, _)

    end
end
