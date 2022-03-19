
-- lua\GUIProwlerRappelHelp.lua
--
-- Created by: twiliteblue


local kLeapTextureName = "ui/skulk_jump.dds"

local kIconWidth = 128
local kIconHeight = 128

class 'GUIProwlerRappelHelp' (GUIAnimatedScript)

function GUIProwlerRappelHelp:OnResolutionChanged(oldX, oldY, newX, newY)
    self:Uninitialize()
    self:Initialize()
end

local kFontName = Fonts.kAgencyFB_Small
function GUIProwlerRappelHelp:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.keyBackground = GUICreateButtonIcon("SecondaryAttack")
    self.keyBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    local size = self.keyBackground:GetSize()
    self.keyBackground:SetPosition(Vector(-size.x / 2, -size.y + GUIScale(kHelpBackgroundYOffset), 0))
    self.keyBackground:SetIsVisible(false)
    
    self.leapImage = self:CreateAnimatedGraphicItem()
    self.leapImage:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.leapImage:SetSize(Vector(kIconWidth, kIconHeight, 0))
    self.leapImage:SetPosition(Vector(-kIconWidth / 2, -kIconHeight, 0))
    self.leapImage:SetTexture(kLeapTextureName)
    self.leapImage:AddAsChildTo(self.keyBackground)
    
    self.scale = Client.GetScreenHeight() / 1200
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
    self.keyBackground:AddChild(self.description)
    
    self.description:SetText("Aim at a surface or object, hold Secondary Attack to Rappel")
end

function GUIProwlerRappelHelp:Update(dt)
    PROFILE("GUIProwlerRappelHelp:Update")
    GUIAnimatedScript.Update(self, dt)
    
    local player = Client.GetLocalPlayer()
    if player and player:isa("Prowler") then
    
        if not self.rappelled and player:GetIsRappelling() then
        
            self.rappelled = true
            HelpWidgetIncreaseUse(self, "GUIProwlerRappelHelp")
            
        end
        
        local activeWeapon = player:GetActiveWeapon()
        local displayRappel = not self.rappelled and activeWeapon and activeWeapon:GetHasSecondary(player)
        
        if not self.keyBackground:GetIsVisible() and displayRappel then
            HelpWidgetAnimateIn(self.leapImage)
        end
        
        self.keyBackground:SetIsVisible(displayRappel == true)
        
    end
    
end

function GUIProwlerRappelHelp:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)
    
    GUI.DestroyItem(self.keyBackground)
    self.keyBackground = nil
    
end