SupplyProviderMixin = CreateMixin( SupplyProviderMixin )
SupplyProviderMixin.type = "SupplyProvider"

SupplyProviderMixin.expectedMixins = {
    Construct = "Makes no sense to use this mixin for non constructable units.",
}

function SupplyProviderMixin:__initmixin()

    PROFILE("SupplyProviderMixin:__initmixin")
    assert(Server)
end

function SupplyProviderMixin:OnConstructionComplete()
    local team = self:GetTeam()
    if team and team.AddMaxSupply then
        team:AddMaxSupply(kSupplyEachTechPoint)
        self.supplyIncreased = true
    end
end

local function DecreaseSupply(self)

    if self.supplyIncreased then
        local team = self:GetTeam()
        if team and team.RemoveSupplyUsed then
            team:RemoveMaxSupply(kSupplyEachTechPoint)
            self.supplyIncreased = false
        end
    end

end

function SupplyProviderMixin:OnKill()
    DecreaseSupply(self)
end

function SupplyProviderMixin:OnDestroy()
    DecreaseSupply(self)
end
