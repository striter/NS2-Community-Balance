
local baseGetMaxSpeed = JetpackMarine.GetMaxSpeed
function JetpackMarine:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible) * GTinySpeedMultiplier(self)
end