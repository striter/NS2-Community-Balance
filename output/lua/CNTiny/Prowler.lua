local baseGetMaxSpeed = Prowler.GetMaxSpeed
function Prowler:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible) * GTinySpeedMultiplier(self)
end