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
    
end 