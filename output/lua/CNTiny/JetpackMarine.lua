
local baseGetMaxSpeed = JetpackMarine.GetMaxSpeed
function JetpackMarine:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible) * self:ScaledBasedSpeedMultiplier()
end