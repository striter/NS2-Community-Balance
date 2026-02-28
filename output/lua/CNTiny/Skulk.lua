
local baseGetMaxSpeed = Skulk.GetMaxSpeed
function Skulk:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible) * self:ScaledBasedSpeedMultiplier()
end


local baseGetMaxWallJumpSpeed = Skulk.GetMaxWallJumpSpeed
function Skulk:GetMaxWallJumpSpeed()
    return baseGetMaxWallJumpSpeed(self) * self:ScaledBasedSpeedMultiplier()
end

local baseGetMaxBunnyHopSpeed = Skulk.GetMaxBunnyHopSpeed
function Skulk:GetMaxBunnyHopSpeed()
    return baseGetMaxBunnyHopSpeed(self) * self:ScaledBasedSpeedMultiplier()
end