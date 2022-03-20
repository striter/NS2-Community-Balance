local oldAlienCopyPlayerDataForReadyRoomFrom = Alien.CopyPlayerDataForReadyRoomFrom
function Alien:CopyPlayerDataForReadyRoomFrom(player)

    oldAlienCopyPlayerDataForReadyRoomFrom(self, player)
    
    local respawnMapName = ReadyRoomTeam.GetRespawnMapName(nil,player)
    local gestationMapName = respawnMapName == ReadyRoomEmbryo.kMapName and player.gestationClass or nil
    local isProwler = respawnMapName == Prowler.kMapName or gestationMapName == Prowler.kMapName
    local rappel = isProwler and 
                   ( player.twoHives or GetIsTechUnlocked( player, kTechId.Rappel ) )   

    self.twoHives = self.twoHives or rappel
    self.gestationClass = isProwler and gestationMapName or self.gestationClass
    
end