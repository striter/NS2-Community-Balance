
local baseGetMaxSpeed = Skulk.GetMaxSpeed
function Skulk:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible) * ScaledBasedSpeedMultiplier(self)
end


local baseGetMaxWallJumpSpeed = Skulk.GetMaxWallJumpSpeed
function Skulk:GetMaxWallJumpSpeed()
    return baseGetMaxWallJumpSpeed(self) * ScaledBasedSpeedMultiplier(self)
end

local baseGetMaxBunnyHopSpeed = Skulk.GetMaxBunnyHopSpeed
function Skulk:GetMaxBunnyHopSpeed()
    return baseGetMaxBunnyHopSpeed(self) * ScaledBasedSpeedMultiplier(self)
end