

function ResearchMixin:UpdateResearch(deltaTime)

    local team = self:GetTeam()
    local researchNode = team:GetTechTree():GetTechNode(self.researchingId)
    if researchNode then
    
        local researchDuration = LookupTechData(researchNode:GetTechId(), kTechDataResearchTimeKey, 0.01)
        if team.GetResearchTimeFactor then
            researchDuration = researchDuration * team:GetResearchTimeFactor()
        end
        
        if GetGamerules():GetAutobuild() then
            researchDuration = math.min(0.5, researchDuration)
        end
        
        researchDuration = researchDuration * kResearchMod
        
        -- avoid division with 0
        researchDuration = math.max(researchDuration, 0.01)
        
        local progress = self.researchProgress + deltaTime / researchDuration
        progress = math.min(progress, 1)

        if progress ~= self.researchProgress then
        
            self.researchProgress = progress

            researchNode:SetResearchProgress(self.researchProgress, self:GetId())
            
            local techTree = self:GetTeam():GetTechTree()
            techTree:SetTechNodeChanged(researchNode, string.format("researchProgress = %.2f", self.researchProgress))
            
            -- Update research progress
            if self.researchProgress == 1 then

                -- Mark this tech node as researched
                researchNode:SetResearched(true)
                
                techTree:QueueOnResearchComplete(self.researchingId, self)
                
            end
        
        end
        
    end 

end
