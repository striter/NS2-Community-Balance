
function AlienUpgradeManager:GetCostForUpgrade(upgradeId)

    if self.initialUpgrades:Contains(upgradeId) and self.initialLifeFormTechId == self.lifeFormTechId then
        cost = 0
    elseif upgradeId == kTechId.OriginFormResourceFetch then
        cost = 0
    else
        cost = LookupTechData(self.lifeFormTechId, kTechDataUpgradeCost, 0)
    end

    return cost

end