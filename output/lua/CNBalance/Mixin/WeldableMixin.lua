function WeldableMixin:GetCanBeWelded(doer)

    if doer == nil then
        return self:GetIsAlive() and self:GetWeldPercentage() < 1
    end

    if doer == self and not (self.GetCanSelfWeld and self:GetCanSelfWeld()) then
        return false
    end

    local canBeWelded = true
    if self.GetCanBeWeldedOverride then
        local overrideWelded, overrideDefault = self:GetCanBeWeldedOverride(doer)
        if overrideDefault then
            return overrideWelded
        end
        canBeWelded = overrideWelded
    end

    canBeWelded = canBeWelded and self:GetIsAlive() and doer:GetTeamNumber() == self:GetTeamNumber() and
                  self:GetWeldPercentage() < 1

    return canBeWelded

end

function WeldableMixin:OnWeld(doer, elapsedTime, player, weldPerSecOverride)

    if self:GetCanBeWelded(doer) then

        if doer == nil and weldPerSecOverride then
            self:AddHealth(weldPerSecOverride * elapsedTime)
        elseif self.OnWeldOverride then
            self:OnWeldOverride(doer, elapsedTime, weldPerSecOverride)
        elseif doer:isa("MAC") then
            self:AddHealth(MAC.kRepairHealthPerSecond * elapsedTime)
        elseif doer:isa("Welder") then
            self:AddHealth(doer:GetRepairRate(self) * elapsedTime)
        end

        if player and player ~= self and player.OnWeldTarget then
            player:OnWeldTarget(self)
        end

    end

end
