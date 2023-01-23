if Server then
    local onCopyPlayerDataFrom = MarineSpectator.CopyPlayerDataFrom
    function MarineSpectator:CopyPlayerDataFrom( player )
        onCopyPlayerDataFrom(self,player)
        self.primaryRespawn = player.primaryRespawn
        self.secondaryRespawn = player.secondaryRespawn
    end
end
