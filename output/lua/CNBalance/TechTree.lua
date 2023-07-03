if Server then

    function TechTree:AddTargetedActivation(techId, prereq1, prereq2,addOnTechId)

        local techNode = TechNode()

        techNode:Initialize(techId, kTechType.Activation, prereq1, prereq2)
        if addOnTechId ~= nil then
            techNode.addOnTechId = addOnTechId
        end
        techNode.requiresTarget = true

        self:AddNode(techNode)

    end

    local baseGetSpecialTechSupported = TechTree.GetSpecialTechSupported
    function TechTree:GetSpecialTechSupported(techId, structureTechIdList, techIdCount)

        if techId == kTechId.ShiftHiveBiomassPreserve then
            local alienTeam = GetGamerules():GetTeam(kTeam2Index)
            if alienTeam and alienTeam.GetBioMassPreserve then
                return techIdCount[kTechId.ShiftHive] and alienTeam:GetBioMassPreserve(kTechId.ShiftHive) > 1
            end
       elseif techId == kTechId.ShadeHiveBiomassPreserve then
            local alienTeam = GetGamerules():GetTeam(kTeam2Index)
            if alienTeam and alienTeam.GetBioMassPreserve then
                return techIdCount[kTechId.ShadeHive] and alienTeam:GetBioMassPreserve(kTechId.ShadeHive) > 1
            end
        elseif techId == kTechId.CragHiveBiomassPreserve then
            local alienTeam = GetGamerules():GetTeam(kTeam2Index)
            if alienTeam and alienTeam.GetBioMassPreserve then
                return techIdCount[kTechId.CragHive] and alienTeam:GetBioMassPreserve(kTechId.CragHive) > 1
            end    
        else
            return baseGetSpecialTechSupported(self,techId,structureTechIdList,techIdCount)
        end

    end

end 