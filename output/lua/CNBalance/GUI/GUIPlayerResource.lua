local kBountyOffset = 28
GUIPlayerResource.kBountyIconPos = Vector(30,-4 + kBountyOffset,0)
GUIPlayerResource.kBountyTextPos = Vector(100,4 + kBountyOffset,0)
GUIPlayerResource.kBountyDescriptionPos = Vector(110,4 + kBountyOffset,0)

GUIPlayerResource.kBountyIcons = { alien = PrecacheAsset("ui/alien_HUD_bounty.dds"), marine = PrecacheAsset("ui/marine_HUD_bounty.dds") }
GUIPlayerResource.kPResDescription = {alien = "RESOURCES_ALIEN",marine = "RESOURCES_MARINE"}

local baseInitialize = GUIPlayerResource.Initialize
function GUIPlayerResource:Initialize(style, teamNumber)
    baseInitialize(self,style,teamNumber)
    self.pResDescription:SetText(Locale.ResolveString(GUIPlayerResource.kPResDescription[style.textureSet]))
    
    self.bountyIcon = self.script:CreateAnimatedGraphicItem()
    self.bountyIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.bountyIcon:SetTexture(GUIPlayerResource.kBountyIcons[style.textureSet])
    self.background:AddChild(self.bountyIcon)

    self.bountyText = self.script:CreateAnimatedTextItem()
    self.bountyText:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.bountyText:SetTextAlignmentX(GUIItem.Align_Max)
    self.bountyText:SetTextAlignmentY(GUIItem.Align_Center)
    self.bountyText:SetColor(style.textColor)
    self.bountyText:SetFontIsBold(true)
    self.bountyText:SetFontName(GUIPlayerResource.kTextFontName)
    self.bountyText:SetText("0")
    self.background:AddChild(self.bountyText)

    self.bountyDescription = self.script:CreateAnimatedTextItem()
    self.bountyDescription:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.bountyDescription:SetTextAlignmentX(GUIItem.Align_Min)
    self.bountyDescription:SetTextAlignmentY(GUIItem.Align_Center)
    self.bountyDescription:SetColor(style.textColor)
    self.bountyDescription:SetFontIsBold(true)
    self.bountyDescription:SetFontName(GUIPlayerResource.kTextFontName)
    self.bountyDescription:SetText(Locale.ResolveString("BOUNTY"))
    self.background:AddChild(self.bountyDescription)
    
    self.lastBounty = nil
end

local baseReset = GUIPlayerResource.Reset
function GUIPlayerResource:Reset(scale)

    baseReset(self,scale)
    self.bountyIcon:SetUniformScale(self.scale)
    self.bountyIcon:SetSize(Vector(GUIPlayerResource.kPersonalResourceIcon.Width, GUIPlayerResource.kPersonalResourceIcon.Height, 0))
    self.bountyIcon:SetPosition(GUIPlayerResource.kBountyIconPos)

    self.bountyText:SetScale(Vector(1,1,1) * self.scale * 1.2)
    self.bountyText:SetFontSize(GUIPlayerResource.kFontSizePersonal)
    self.bountyText:SetPosition(GUIPlayerResource.kBountyTextPos)
    self.bountyText:SetFontName(GUIPlayerResource.kTextFontName)
    GUIMakeFontScale(self.bountyText)

    self.bountyDescription:SetScale(Vector(1,1,1) * self.scale * 1.2)
    self.bountyDescription:SetFontSize(GUIPlayerResource.kFontSizePresDescription)
    self.bountyDescription:SetPosition(GUIPlayerResource.kBountyDescriptionPos)
    self.bountyDescription:SetFontName(GUIPlayerResource.kTextFontName)
    GUIMakeFontScale(self.bountyDescription)
end


local baseUpdate = GUIPlayerResource.Update
function GUIPlayerResource:Update(_, parameters)
    baseUpdate(self,_,parameters)

    local localPlayer = Client.GetLocalPlayer()
    local bounty = localPlayer:GetBountyCurrentLife()
    if self.lastBounty ~= bounty then
        self.lastBounty = bounty
        
        self.bountyText:SetText(tostring(self.lastBounty))

        local visible = self.lastBounty ~= 0
        self.bountyIcon:SetIsVisible(visible)
        self.bountyText:SetIsVisible(visible)
        self.bountyDescription:SetIsVisible(visible)
    end
end
