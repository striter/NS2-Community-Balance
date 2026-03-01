
local baseGetMaxSpeed = Lerk.GetMaxSpeed
function Lerk:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible) * GTinySpeedMultiplier(self)
end