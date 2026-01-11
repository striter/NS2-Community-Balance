local baseOnAdjustModelCoords = Prowler.OnAdjustModelCoords
function Prowler:OnAdjustModelCoords(modelCoords)
    local coords = Player.OnAdjustModelCoords(self,modelCoords) 
    return baseOnAdjustModelCoords(self,modelCoords)
end


local baseGetMaxSpeed = Prowler.GetMaxSpeed
function Prowler:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible) * GTinySpeedMultiplier(self)
end