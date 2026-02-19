
local baseGetMaxSpeed = Fade.GetMaxSpeed
function Fade:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible) * GTinySpeedMultiplier(self)
end