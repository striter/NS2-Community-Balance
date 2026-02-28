local baseOnPostUpdateCamera = Marine.OnPostUpdateCamera
function Marine:OnPostUpdateCamera(deltaTime)
    baseOnPostUpdateCamera(self,deltaTime)
    Player.OnPostUpdateCamera(self,deltaTime)
end

local baseGetMaxSpeed = Marine.GetMaxSpeed
function Marine:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible) * ScaledBasedSpeedMultiplier(self)
end