

PrototypeLab.kPrototypeResearchType =
{
    [kTechId.JetpackTech] = kTechId.JetpackPrototypeLab,
    [kTechId.CannonTech] = kTechId.CannonPrototypeLab,
    [kTechId.ExosuitTech] = kTechId.ExosuitPrototypeLab,
}

local function GetResearchAllowed(self, techId)
    local stationTypeTechId = PrototypeLab.kPrototypeResearchType[techId]
    local available = not GetHasTech(self, stationTypeTechId) and not GetIsTechResearching(self, techId)
    return available and techId or kTechId.None
end

function PrototypeLab:GetTechButtons()

    local techId = self:GetTechId()
    local techButtons = { kTechId.None, kTechId.None, kTechId.None, kTechId.None,
                          kTechId.None, kTechId.None, kTechId.None, kTechId.None }
    if techId == kTechId.PrototypeLab then
        techButtons[1] = GetResearchAllowed(self,kTechId.JetpackTech)
        techButtons[2] = GetResearchAllowed(self,kTechId.ExosuitTech)
        techButtons[5] = GetResearchAllowed(self,kTechId.CannonTech)
    end

    return techButtons
end


function PrototypeLab:OnResearchComplete(researchId)
    local upgradeTech = PrototypeLab.kPrototypeResearchType[researchId]
    if upgradeTech then
        self:UpgradeToTechId(upgradeTech)
    end
end

function PrototypeLab:GetItemList(forPlayer)
    return { kTechId.Jetpack, kTechId.DualMinigunExosuit, kTechId.DualRailgunExosuit, kTechId.Cannon}
end


class 'ExosuitPrototypeLab' (PrototypeLab)
ExosuitPrototypeLab.kMapName = "exosuit_prototypelab"

class 'JetpackPrototypeLab' (PrototypeLab)
JetpackPrototypeLab.kMapName = "jetpack_prototypelab"

class 'CannonPrototypeLab' (PrototypeLab)
CannonPrototypeLab.kMapName = "cannon_prototypelab"

--local baseGetCanBeUsed = PrototypeLab.GetCanBeUsed
--function PrototypeLab:GetCanBeUsed(player, useSuccessTable)
--
--    baseGetCanBeUsed(self,player,useSuccessTable)
--    if GetHasTech(self,kTechId.MilitaryProtocol) then
--        useSuccessTable.useSuccess = false
--    end
--
--end