
local baseGetMaxSpeed = Exo.GetMaxSpeed
function Exo:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible) * self:ScaledBasedSpeedMultiplier()
end