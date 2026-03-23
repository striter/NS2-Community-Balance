Embryo.kScaleDeltaPerSecond = 1

function Embryo:OnAdjustModelCoords(coords)
    coords = Player.OnAdjustModelCoords(self,coords)
    coords.origin = coords.origin - Embryo.kSkinOffset
    return coords
end

function Embryo:OnPostUpdateCamera(deltaTime)
    self:SetCameraDistance(kGestateCameraDistance * self.scale)
    self:SetViewOffsetHeight(self:GetMaxViewOffsetHeight() * self.scale)
end

local kGestationScale = {
    [kTechId.Skulk] = 1,
    [kTechId.Prowler] = 1.25,
    [kTechId.Lerk] = 1.25,
    [kTechId.Gorge] = 1.5,
    [kTechId.Fade] = 1.75,
    [kTechId.Vokex] = 1.75,
    [kTechId.Onos] = 2.25,
    
}

function Embryo:GetPlayerScale(deltaTime)
    local targetScale = kGestationScale[self.gestationTypeTechId] or 1
    local gestationScale = Lerp(1,targetScale ,self.evolvePercentage / 100.0)
    return Player.GetPlayerScale(self,deltaTime) * self.condenseScale * gestationScale
end