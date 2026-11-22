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

local baseAlienProcessBuyAction = Alien.ProcessBuyAction
function Alien:ProcessBuyAction(techIds)

    local team = self:GetTeam()
    if techIds and team and team.GetBioMassLevel then

        local bioMassLevel = team:GetBioMassLevel()
        for _, techId in ipairs(techIds) do
            local requiredLevel = kEarlyLifeformMinBiomass[techId]
            if requiredLevel and bioMassLevel < requiredLevel then
                self:TriggerInvalidSound()
                return false
            end
        end

    end

    return baseAlienProcessBuyAction(self, techIds)

end