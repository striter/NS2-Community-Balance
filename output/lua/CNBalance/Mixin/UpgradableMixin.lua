
local baseGiveUpgrade = UpgradableMixin.GiveUpgrade
function UpgradableMixin:GiveUpgrade(techId)

    if techId == kTechId.OriginFormResourceFetch then
        self:GetTeam():OnOriginFormResourceFetch(self)
        return false
    end
    
    return baseGiveUpgrade(self,techId)
end
