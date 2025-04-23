
function TechMixin:UpgradeToTechId(newTechId)

    local elderTech = self:GetTechId()
    
    if self:GetTechId() ~= newTechId then
    
        if self.OnPreUpgradeToTechId then
            self:OnPreUpgradeToTechId(newTechId)
        end

        local healthScalar = 0
        local armorScalar = 0
        local isAlive = HasMixin(self, "Live")
        if isAlive then
            -- Preserve health and armor scalars but potentially change maxHealth and maxArmor.
            healthScalar = self:GetHealthScalar()
            armorScalar = self:GetArmorScalar()
        end
        
        self:SetTechId(newTechId)
        
        if isAlive then
        
            local baseMaxHealth =  self:GetMaxHealth()
            local newMaxHealth  = LookupTechData(newTechId, kTechDataMaxHealth ,baseMaxHealth)
            if self.GetAdditionalHealth then
                newMaxHealth = newMaxHealth +  self:GetAdditionalHealth()
                newMaxHealth = math.max(newMaxHealth,200)
            end
            
            self:SetMaxHealth(newMaxHealth)   --To Avoid problems
            self:SetMaxArmor(LookupTechData(newTechId, kTechDataMaxArmor, self:GetMaxArmor()))
            
            self:SetHealth(healthScalar * self:GetMaxHealth())
            self:SetArmor(armorScalar * self:GetMaxArmor())
            
        end
        
        if HasMixin(self, "Maturity") then
            self.maturityHealth = 0
            self.maturityArmor = 0

            self:UpdateMaturity(true)
        end
        
        return true
        
    end
    
    return false
    
end
