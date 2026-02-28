
local baseGetMaxSpeed = JetpackMarine.GetMaxSpeed
function JetpackMarine:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible) * ScaledBasedSpeedMultiplier(self)
end