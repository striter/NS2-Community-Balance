
-- function JetpackMarine:GetFuel()

--     local dt = Shared.GetTime() - self.timeJetpackingChanged

--     --more weight means the Jetpack has to provide more force to lift the marine and therefor consumes more fuel
--     local weightFactor = math.max( self:GetWeaponsWeight() / kJetpackWeightLiftForce, kMinWeightJetpackFuelFactor )
--     local useRate=kJetpackUseFuelRate
    
--     if GetHasTech(self,kTechId.JetpackFuelTech) then
--         useRate = kUpgradedJetpackUseFuelRate
--     end

--     local rate = -useRate * weightFactor
--     if not self.jetpacking then
--         rate = kJetpackReplenishFuelRate
--         dt = math.max(0, dt - JetpackMarine.kJetpackFuelReplenishDelay)
--     end
    
--     if self:GetDarwinMode() then
--         return 1
--     else
--         return Clamp(self.jetpackFuelOnChange + rate * dt, 0, 1)
--     end
    
-- end
