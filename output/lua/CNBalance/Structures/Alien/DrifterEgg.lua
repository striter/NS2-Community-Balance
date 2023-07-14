
if Server then
    
    function DrifterEgg:Hatch()
        
        local drifter = CreateEntity(Drifter.kMapName, self:GetOrigin() + Vector(0, Drifter.kHoverHeight, 0), self:GetTeamNumber())
        drifter:ProcessRallyOrder(self)
        drifter:SetHealth(self:GetHealth())
        drifter:SetArmor(self:GetArmor())
        
        -- inherit selection
        drifter.selectionMask = self.selectionMask
        drifter.hotGroupNumber = self.hotGroupNumber

        if self.hatchCallBack ~= nil then
            self.hatchCallBack(drifter)
            self.hatchCallBack = nil
        end
        self:TriggerEffects("death")
        
        local techTree = self:GetTeam():GetTechTree()    
        local researchNode = techTree:GetTechNode(kTechId.Drifter)    
        researchNode:SetResearchProgress(1)
        techTree:SetTechNodeChanged(researchNode, string.format("researchProgress = %.2f", 1))

        -- Handle Stats (Must be Server only)
        StatsUI_AddBuildingStat(self:GetTeamNumber(), kTechId.Drifter, false)
        -- Drifter hatched
        StatsUI_AddExportBuilding(self:GetTeamNumber(),
            kTechId.Drifter,
            drifter:GetId(),
            self:GetOrigin(),
            StatsUI_kLifecycle.Built,
            true)
        
        DestroyEntity(self)
    end
    
    local baseOnDestroy = DrifterEgg.OnDestroy
    function DrifterEgg:OnDestroy()
        baseOnDestroy(self)
        self.hatchCallBack = nil
    end
end   
