
local baseGetMaxSpeed = Skulk.GetMaxSpeed
function Skulk:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible) * GTinySpeedMultiplier(self)
end


local baseGetMaxWallJumpSpeed = Skulk.GetMaxWallJumpSpeed
function Skulk:GetMaxWallJumpSpeed()
    return baseGetMaxWallJumpSpeed(self) * GTinySpeedMultiplier(self)
end

local baseGetMaxBunnyHopSpeed = Skulk.GetMaxBunnyHopSpeed
function Skulk:GetMaxBunnyHopSpeed()
    return baseGetMaxBunnyHopSpeed(self) * GTinySpeedMultiplier(self)
end