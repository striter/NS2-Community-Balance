
local baseGetMaxSpeed = Onos.GetMaxSpeed
function Onos:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible) * GTinySpeedMultiplier(self)
end


function Onos:GetCrouchShrinkAmount()
    return 0.4 * self.scale
end

function Onos:GetExtentsCrouchShrinkAmount()
    return 0.4 * self.scale
end