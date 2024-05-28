
class 'GUIRappelInfo' (GUIAnimatedScript)

GUIRappelInfo.kBaseYResolution = 1000
local kFontName = Fonts.kAgencyFB_Small
function GUIRappelInfo:Initialize()
    GUIAnimatedScript.Initialize(self)
    self.scale = Client.GetScreenHeight() / GUIRappelInfo.kBaseYResolution
    self.background = self:CreateAnimatedGraphicItem()
    self.background:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.background:SetColor(Color(0.1,0.1,0.1,0))    
    self:Reset()
end
function GUIRappelInfo:Uninitialize()
    
    GUIAnimatedScript.Uninitialize(self)

end
function GUIRappelInfo:GetIsVisible()
    return false
    --return self.background:GetIsVisible()
end
function GUIRappelInfo:SetIsVisible(isVisible)
    self.background:SetIsVisible(isVisible == true)
end
function GUIRappelInfo:OnResolutionChanged(oldX, oldY, newX, newY)

    self:Uninitialize()
    self:Initialize()

end

function GUIRappelInfo:UpdateDescription()
    self.description:SetText("牵引中")
end
function GUIRappelInfo:Reset()
    
    self.background:SetUniformScale(self.scale)
    self.description = self:CreateAnimatedTextItem()
    self.description:SetUniformScale(self.scale) 
    self.description:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.description:SetTextAlignmentX(GUIItem.Align_Center)
    self.description:SetTextAlignmentY(GUIItem.Align_Center)
    self.description:SetScale(GetScaledVector())
    self.description:SetFontName(kFontName)
    GUIMakeFontScale(self.description)
    self.description:SetPosition(Vector(0, 150, 0))
    self.description:SetFontIsBold(true)
    self.background:AddChild(self.description)
    
    
    self:UpdateDescription()
    
end