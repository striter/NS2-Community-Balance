
local baseGetMaxSpeed = Onos.GetMaxSpeed
function Onos:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible) * ScaledBasedSpeedMultiplier(self)
end


function Onos:GetCrouchShrinkAmount()
    return 0.4 * self:GetPlayerScale()
end