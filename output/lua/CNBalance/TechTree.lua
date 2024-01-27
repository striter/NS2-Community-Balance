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
    
    function TechTree:AddActivation(techId, prereq1, prereq2,addOnTechId)

        local techNode = TechNode()

        techNode:Initialize(techId, kTechType.Activation, prereq1, prereq2)
        if addOnTechId ~= nil then
            techNode.addOnTechId = addOnTechId
        end

        self:AddNode(techNode)

    end
    
    function TechTree:AddUnlockActivation(techId, prereq1, prereq2,addOnTechId)

        local techNode = TechNode()

        techNode:Initialize(techId, kTechType.Activation, prereq1, prereq2)
        if addOnTechId ~= nil then
            techNode.addOnTechId = addOnTechId
        end
        techNode.unlock = true

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

    function TechTree:ComputeAvailability()

        for _, nodeTechId in ipairs(self.techIdList) do

            local node = self:GetTechNode(nodeTechId)
            assert(node)

            local newAvailableState = false

            -- Don't allow researching items that are currently being researched (unless multiples allowed)
            if (node:GetIsResearch() or node:GetIsPlasmaManufacture()) and (self:GetHasTech(node:GetPrereq1()) and self:GetHasTech(node:GetPrereq2())) then
                newAvailableState = node:GetCanResearch()
                -- Disable anything with this as a prereq if no longer available
            elseif self:GetHasTech(node:GetPrereq1()) and self:GetHasTech(node:GetPrereq2()) then
                newAvailableState = true
            end

            -- Check for "alltech" cheat
            if GetGamerules():GetAllTech() then
                newAvailableState = true
            end

            -- Don't allow use of stuff that's unavailable
            if LookupTechData(nodeTechId, kTechDataImplemented) == false and not Shared.GetDevMode() then
                newAvailableState = false
            end

            if node.available ~= newAvailableState then

                if node.unlock then
                    node.available = node.available or newAvailableState
                else
                    node.available = newAvailableState
                end

                -- Queue tech node update to clients
                self:SetTechNodeChanged(node, string.format("available = %s", ToString(newAvailableState)))

            end

        end

    end
    
end

local kInstancedTechIds
function GetTechIdIsInstanced(techId)

    if not kInstancedTechIds then

        kInstancedTechIds = set
        {
            kTechId.UpgradeToCragHive,
            kTechId.UpgradeToShadeHive,
            kTechId.UpgradeToShiftHive,

            kTechId.AdvancedArmoryUpgrade,
            kTechId.UpgradeRoboticsFactory,

            kTechId.StandardSupply,
            kTechId.ArmorSupply,
            kTechId.ElectronicSupply,
            kTechId.ExplosiveSupply,

            kTechId.JetpackTech,
            kTechId.ExosuitTech,
            kTechId.CannonTech,

        }

    end

    return kInstancedTechIds[techId]

end
