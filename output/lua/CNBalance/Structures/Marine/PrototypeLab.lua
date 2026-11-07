Script.Load("lua/SupplyUserMixin.lua")

local baseOnInitialized = PrototypeLab.OnInitialized
function PrototypeLab:OnInitialized()
    baseOnInitialized(self)
    if Server then
        InitMixin(self, SupplyUserMixin)
    end
end

PrototypeLab.kUpgradeToTargetType =
{
    [kTechId.JetpackProtoUpgrade] = kTechId.JetpackPrototypeLab,
    [kTechId.ExosuitProtoUpgrade] = kTechId.ExosuitPrototypeLab,
    [kTechId.CannonProtoUpgrade] = kTechId.CannonPrototypeLab,
}

local function GetResearchAllowed(self, techId)
    local stationTypeTechId = PrototypeLab.kUpgradeToTargetType[techId]
    local available = not GetHasTech(self, stationTypeTechId) and not GetIsTechResearching(self, techId)
    return available and techId or kTechId.None
end

local kStationResearchNodes = {
    [kTechId.ExosuitPrototypeLab] = kTechId.DualWeaponTech,
}

function PrototypeLab:GetTechButtons()

    local techId = self:GetTechId()
    local techButtons = { kTechId.None, kTechId.None, kTechId.None, kTechId.None,
                          kTechId.None, kTechId.None, kTechId.None, kTechId.None }
    if techId == kTechId.PrototypeLab then
        techButtons[1] = GetResearchAllowed(self,kTechId.JetpackProtoUpgrade)
        techButtons[2] = GetResearchAllowed(self,kTechId.ExosuitProtoUpgrade)
        techButtons[5] = GetResearchAllowed(self,kTechId.CannonProtoUpgrade)
    else
        techButtons[1] = kStationResearchNodes[techId] or kTechId.None
    end

    return techButtons
end

if Server then

    function PrototypeLab:UpdateResearch()

        local researchId = self:GetResearchingId()
        local stationTypeTechId = PrototypeLab.kUpgradeToTargetType[researchId]

        if stationTypeTechId then

            local techTree = self:GetTeam():GetTechTree()
            local researchNode = techTree:GetTechNode(stationTypeTechId)
            researchNode:SetResearchProgress(self.researchProgress)
            techTree:SetTechNodeChanged(researchNode, string.format("researchProgress = %.2f", self.researchProgress))

        end
    end

    function PrototypeLab:OnResearchCancel(researchId)

        local stationTypeTechId = PrototypeLab.kUpgradeToTargetType[researchId]
        if stationTypeTechId then

            local team = self:GetTeam()
            if team then
                local techTree = team:GetTechTree()
                local researchNode = techTree:GetTechNode(stationTypeTechId)
                if researchNode then
                    researchNode:ClearResearching()
                    techTree:SetTechNodeChanged(researchNode, string.format("researchProgress = %.2f", 0))
                end
            end
        end
    end

    function PrototypeLab:OnResearchComplete(researchId)
        local upgradeTech = PrototypeLab.kUpgradeToTargetType[researchId]
        if upgradeTech then
            self:UpgradeToTechId(upgradeTech)
        end
        local techTree = self:GetTeam():GetTechTree()
        local researchNode = techTree:GetTechNode(upgradeTech)

        if researchNode then
            researchNode:SetResearchProgress(1)
            techTree:SetTechNodeChanged(researchNode, string.format("researchProgress = %.2f", self.researchProgress))
            researchNode:SetResearched(true)
        end
    end

end

function PrototypeLab:GetItemList(forPlayer)

    if not forPlayer and Client then
        forPlayer = Client.GetLocalPlayer()
    end
    if forPlayer and forPlayer:isa("Exo") then
        local upgradeTechId = GetExoUpgradeTechId(forPlayer)
        return upgradeTechId and { upgradeTechId } or {}
    end
    return { kTechId.Jetpack, kTechId.ClawMinigunExosuit, kTechId.ClawRailgunExosuit, kTechId.Cannon }

end

local baseGetCanBeUsed = PrototypeLab.GetCanBeUsed
function PrototypeLab:GetCanBeUsed(player, useSuccessTable)
    baseGetCanBeUsed(self, player, useSuccessTable)
    if not useSuccessTable.useSuccess and player:isa("Exo")
        and not player:GetHasDualGuns()
        and player:GetTeamNumber() == self:GetTeamNumber()
        and self:GetIsBuilt() and self:GetIsPowered()
    then
        useSuccessTable.useSuccess = true
    end
end

class 'ExosuitPrototypeLab' (PrototypeLab)
ExosuitPrototypeLab.kMapName = "exosuit_prototypelab"

class 'JetpackPrototypeLab' (PrototypeLab)
JetpackPrototypeLab.kMapName = "jetpack_prototypelab"

class 'CannonPrototypeLab' (PrototypeLab)
CannonPrototypeLab.kMapName = "cannon_prototypelab"
