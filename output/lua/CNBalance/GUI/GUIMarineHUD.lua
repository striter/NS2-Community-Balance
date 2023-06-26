local baseInitialize = GUIMarineHUD.Initialize
function GUIMarineHUD:Initialize()
    self.militaryProtocol = GetGUIManager():CreateGraphicItem()
    self.militaryProtocol:SetTexture(GUIMarineHUD.kUpgradesTexture)
    self.militaryProtocol:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.militaryProtocol:SetIsVisible(false)
    self.militaryProtocol:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(kTechId.MilitaryProtocol)))
    self.militaryProtocol:SetColor(kIconColors[kMarineTeamType])
    self.lastMilitaryProtocol = false
    baseInitialize(self)

    self.background:AddChild(self.militaryProtocol)
end


local baseReset = GUIMarineHUD.Reset
function GUIMarineHUD:Reset()
    baseReset(self)
    self.militaryProtocol:SetPosition(Vector(GUIMarineHUD.kUpgradePos.x, GUIMarineHUD.kUpgradePos.y - GUIMarineHUD.kUpgradeSize.y - 8, 0) * self.scale)
    self.militaryProtocol:SetSize(GUIMarineHUD.kUpgradeSize * self.scale)
    self.militaryProtocol:SetIsVisible(false)
    
    local marineHudBars = GetAdvancedOption("hudbars_m")
    if marineHudBars > 0 then
        if marineHudBars == 2 then
            local pos = self.militaryProtocol:GetPosition()
            self.militaryProtocol:SetPosition(Vector(pos.x, pos.y-100, 0))
        end
    end

end

local baseUpdate = GUIMarineHUD.Update
function GUIMarineHUD:Update(deltaTime)
    baseUpdate(self,deltaTime)
    local hasMilitaryProtocol = GetHasTech(Client.GetLocalPlayer(),kTechId.MilitaryProtocol)
    if hasMilitaryProtocol ~= self.lastMilitaryProtocol then
        self.lastMilitaryProtocol = hasMilitaryProtocol
        self.militaryProtocol:SetIsVisible(self.lastMilitaryProtocol)
    end
end