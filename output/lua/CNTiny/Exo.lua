
local baseGetMaxSpeed = Exo.GetMaxSpeed
function Exo:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible) * GTinySpeedMultiplier(self)
end