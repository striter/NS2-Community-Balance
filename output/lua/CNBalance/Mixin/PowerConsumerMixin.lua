PowerConsumerMixin.networkVars.localPower = "boolean"

function PowerConsumerMixin:GetIsPowered()
    return self.powered or self.powerSurge or self.localPower
end

if Server then

    function PowerConsumerMixin:SetLocalPower(state)
        state = state and true or false
        if self.localPower ~= state then
            local wasPowered = self:GetIsPowered()
            self.localPower = state
            local nowPowered = self:GetIsPowered()
            if nowPowered and not wasPowered then
                if self.OnPowerOn then
                    self:OnPowerOn()
                end
                if self.updateDeployOnPower then
                    self:TriggerEffects("deploy")
                    self.updateDeployOnPower = false
                end
            elseif wasPowered and not nowPowered then
                if self.OnPowerOff then
                    self:OnPowerOff()
                end
            end
        end
    end

end
