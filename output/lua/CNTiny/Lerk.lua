
local baseGetMaxSpeed = Lerk.GetMaxSpeed
function Lerk:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible) * ScaledBasedSpeedMultiplier(self)
end