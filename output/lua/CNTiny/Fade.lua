
local baseGetMaxSpeed = Fade.GetMaxSpeed
function Fade:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible) * GTinySpeedMultiplier(self)
end

function Fade:GetCondenseScalePerLevel()
    return 0.07
end