
local baseGetMaxSpeed = Exo.GetMaxSpeed
function Exo:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible) * ScaledBasedSpeedMultiplier(self)
end