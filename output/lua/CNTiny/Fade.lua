
local baseGetMaxSpeed = Fade.GetMaxSpeed
function Fade:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible) * self:ScaledBasedSpeedMultiplier()
end

function Fade:GetCondenseScalePerLevel()
    return 0.06
end 