if Server then

    local function GetMaturityHealth(self, fraction)

        local maxHealth = LookupTechData(self:GetTechId(), kTechDataMaxHealth, 100)
        -- use 1.5 times normal health as default
        local maturityHealth = maxHealth * 1.5

        if self.GetMatureMaxHealth then
            maturityHealth = self:GetMatureMaxHealth()
        end

        if self.GetAdditionalHealth then
            local additionalHealth = self:GetAdditionalHealth()
            maturityHealth = maturityHealth + additionalHealth
            maxHealth = maxHealth + additionalHealth
        end
        
        local newMatureHealth = (maturityHealth - maxHealth) * self:GetMaturityFraction()
        -- Health is a interger value so we have to make sure the delta is always an int as well to not loose data
        local healthDelta = math.floor(newMatureHealth - self.maturityHealth)

        self.maturityHealth = self.maturityHealth + healthDelta

        local newMaxHealth = self:GetMaxHealth() + healthDelta
        newMaxHealth = math.max(newMaxHealth,1)
        return newMaxHealth
    end

    local function GetMaturityArmor(self, fraction)

        local maxArmor = LookupTechData(self:GetTechId(), kTechDataMaxArmor, 0)
        -- use 1.5 times normal armor as default
        local maturityArmor = maxArmor * 1.5

        if self.GetMatureMaxArmor then
            maturityArmor = self:GetMatureMaxArmor()
        end

        local newMatureArmor = (maturityArmor - maxArmor) * fraction
        -- Armor is a interger value so we have to make sure the delta is always an int as well to not loose data
        local armorDelta = math.floor(newMatureArmor - self.maturityArmor)

        self.maturityArmor = self.maturityArmor + armorDelta
        return self:GetMaxArmor() + armorDelta

    end

    function MaturityMixin:UpdateMaturity(forceUpdate)

        local fraction = self._maturityFraction
        if not forceUpdate and self.maturityFraction == fraction then return end

        self.maturityFraction = fraction

        -- health/armor fractions are maintained by using "Adjust" functions
        local newMaxHealth = GetMaturityHealth(self, fraction)
        self:AdjustMaxHealth(newMaxHealth)

        local newMaxArmor = GetMaturityArmor(self, fraction)
        self:AdjustMaxArmor(newMaxArmor)

    end

    
end
