function GhostStructureMixin:PerformAction(techNode, _)

    if techNode.techId == kTechId.Cancel and self:GetIsGhostStructure() then

        -- give back only 75% of resources to avoid abusing the mechanic
        self:TriggerEffects("ghoststructure_destroy")
        local cost = math.round(LookupTechData(self:GetTechId(), kTechDataCostKey, 0))      --? * kRecyclePaybackScalar
        self:GetTeam():AddTeamResources(cost)
        self:GetTeam():PrintWorldTextForTeamInRange(kWorldTextMessageType.Resources, cost, self:GetOrigin() + kWorldMessageResourceOffset, kResourceMessageRange)
        DestroyEntity(self)

    end

end
