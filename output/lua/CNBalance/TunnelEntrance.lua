-- local oldInitialized = TunnelEntrance.OnInitialized
-- function TunnelEntrance:OnInitialized()
--     oldInitialized(self)
--     self:SetDesiredInfestationRadius(0)
-- end

local oldConstructionComplete=TunnelEntrance.OnConstructionComplete
local kBeginInfestationRadius=2
function TunnelEntrance:OnConstructionComplete()
    oldConstructionComplete(self)
    self:SetDesiredInfestationRadius(self:GetInfestationMaxRadius())
end

function TunnelEntrance:GetInfestationMaxRadius()
    if self:GetIsInfested() then
        return TunnelEntrance.kTunnelInfestationRadius
    end

    return kBeginInfestationRadius
end


function TunnelEntrance:GetTechButtons()

    local buttons = { kTechId.None, kTechId.None, kTechId.None, kTechId.None,
                      kTechId.None, kTechId.None, kTechId.None, kTechId.None }

    if self:GetCanBuildOtherEnd() then
        buttons[1] = kTechId.TunnelExit
    end

    if self:GetCanTriggerCollapse() then
        buttons[8] = kTechId.TunnelCollapse
    end

    if self:GetCanRelocate() then
        buttons[2] = kTechId.TunnelRelocate
    end

    -- if self:GetCanUpgradeToInfestedTunnel() then
    --    buttons[3] = kTechId.UpgradeToInfestedTunnel
    -- end

    return buttons
end

function TunnelEntrance:OnMaturityComplete()
    self:UpgradeToTechId(kTechId.InfestedTunnel)
    self:SetDesiredInfestationRadius(self:GetInfestationMaxRadius())
end

function TunnelEntrance:OnResearchComplete(techId)

    local success = false

    if techId == kTechId.UpgradeToInfestedTunnel then
        self:UpgradeToTechId(kTechId.InfestedTunnel)
        self:SetDesiredInfestationRadius(self:GetInfestationMaxRadius())
    end

    return success

end

function TunnelEntrance:GetCystParentRange()
    return kHiveCystParentRange
end

if Server then
    --Function to treat as hive
    function TunnelEntrance:GetDistanceToHive()
        return 0
    end

    function TunnelEntrance:AddChildCyst(child)
        
    end

    function TunnelEntrance:GetIsActuallyConnected()
        return true
    end
end