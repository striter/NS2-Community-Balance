if Server then
    local onCopyPlayerDataFrom = MarineSpectator.CopyPlayerDataFrom
    function MarineSpectator:CopyPlayerDataFrom( player )
        onCopyPlayerDataFrom(self,player)
        self.primaryRespawn = player.primaryRespawn
        self.secondaryRespawn = player.secondaryRespawn
        self.meleeRespawn = player.meleeRespawn
    end
end
