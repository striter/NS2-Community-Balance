
local baseGetMaxSpeed = Onos.GetMaxSpeed
function Onos:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible) * self:ScaledBasedSpeedMultiplier()
end


function Onos:GetCrouchShrinkAmount()
    return 0.4 * self:GetPlayerScale()
end