
function ConstructMixin:OnHealSpray(gorge)

    if not gorge:isa("Gorge") then
        return
    end

    if GetIsAlienUnit(self) and GetAreFriends(self, gorge) and not self:GetIsBuilt() then

        if self.GetHealSprayBuildAllowed and not self:GetHealSprayBuildAllowed() then
            return
        end

        local currentTime = Shared.GetTime()
        
        -- Multiple Gorges scale non-linearly 
        local timePassed = Clamp((currentTime - self.timeOfLastHealSpray), 0, kMaxBuildTimePerHealSpray)
        local constructTimeForSpray = math.min(kMinBuildTimePerHealSpray + timePassed, kMaxBuildTimePerHealSpray)

        if self.ConstructionTimeBonus then
            constructTimeForSpray = constructTimeForSpray * self:ConstructionTimeBonus()
        end
        
        self:Construct(constructTimeForSpray, gorge)
        
        self.timeOfLastHealSpray = currentTime
        
    end

end
