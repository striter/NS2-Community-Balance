
local baseGetMaxSpeed = Gorge.GetMaxSpeed
function Gorge:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible) * ScaledBasedSpeedMultiplier(self)
end