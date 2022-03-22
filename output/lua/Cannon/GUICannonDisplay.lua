//________________________________
//
//  NS2: Combat
//    Copyright 2014 Faultline Games Ltd.
//  and Unknown Worlds Entertainment Inc.
//
//_______________________________

Script.Load("lua/GUIScript.lua")
Script.Load("lua/Utility.lua")

// Global state that can be externally set to adjust the display.
weaponClip     = 0
weaponAmmo     = 0
weaponAuxClip  = 0
globalTime     = 0

bulletDisplay  = nil

FontScaleVector = Vector(1, 1.4, 1) * 0.9

class 'GUICannonDisplay'

function GUICannonDisplay:Initialize()

    self.weaponClip     = 0
    self.weaponAmmo     = 0
    self.weaponClipSize = 10
	self.globalTime = 0
    self.lowAmmoWarning = true
    
    self.flashInDelay = 1.2

    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize( Vector(256, 256, 0) )
    self.background:SetPosition( Vector(0, 0, 0))    
    self.background:SetTexture("ui/cannon_display.dds")
	
	self.lowAmmoOverlay = GUIManager:CreateGraphicItem()
    self.lowAmmoOverlay:SetSize( Vector(256, 256, 0) )
    self.lowAmmoOverlay:SetPosition( Vector(0, 0, 0))    
	self.background:AddChild(self.lowAmmoOverlay)
    
    self.clipText, self.clipTextBg = self:CreateItem(45, 134)
    self.ammoText, self.ammoTextBg = self:CreateItem(177, 134)
    
    local slash, slashBg = self:CreateItem(110, 134)
    slash:SetFontName(Fonts.kAgencyFB_Large_Bold)
    slash:SetText("/")
    slashBg:SetFontName(Fonts.kAgencyFB_Large_Bold)
    slashBg:SetText("/")
    
    self.flashInOverlay = GUIManager:CreateGraphicItem()
    self.flashInOverlay:SetSize( Vector(256, 256, 0) )
    self.flashInOverlay:SetPosition( Vector(0, 0, 0))    
    self.flashInOverlay:SetColor(Color(1,1,1,0.0))
    self.background:AddChild(self.flashInOverlay)
    
    // Force an update so our initial state is correct.
    self:Update(0)

end

function GUICannonDisplay:CreateItem(x, y)

    local textBg = GUIManager:CreateTextItem()
    textBg:SetFontName("fonts/LMGFont.fnt")
	textBg:SetScale(FontScaleVector)
    textBg:SetFontSize(55)
    textBg:SetTextAlignmentX(GUIItem.Align_Center)
    textBg:SetTextAlignmentY(GUIItem.Align_Center)
    textBg:SetPosition(Vector(x, y, 0))
    textBg:SetColor(Color(0.88, 0.98, 1, 0.25))

    // Text displaying the amount of reserve ammo
    local text = GUIManager:CreateTextItem()
    text:SetFontName("fonts/LMGFont.fnt")
    text:SetFontSize(45)
    text:SetScale(FontScaleVector)
    text:SetTextAlignmentX(GUIItem.Align_Center)
    text:SetTextAlignmentY(GUIItem.Align_Center)
    text:SetPosition(Vector(x, y, 0))
    text:SetColor(Color(0.88, 0.98, 1))
    
    return text, textBg
    
end

function GUICannonDisplay:Update(deltaTime)

    PROFILE("GUICannonDisplay:Update")
    
    // Update the ammo counter.
    
    local clipFormat = string.format("%d", self.weaponClip) 
    local ammoFormat = string.format("%02d", self.weaponAmmo) 
    
    self.clipText:SetText( clipFormat )
    self.clipTextBg:SetText( clipFormat )
    
    self.ammoText:SetText( ammoFormat )
    self.ammoTextBg:SetText( ammoFormat )
    
    if self.flashInDelay > 0 then
    
        self.flashInDelay = Clamp(self.flashInDelay - deltaTime, 0, 5)
        
        if self.flashInDelay == 0 then
            self.flashInOverlay:SetColor(Color(1,1,1,0.7))
        end
    
    else
    
        local flashInAlpha = self.flashInOverlay:GetColor().a    
        if flashInAlpha > 0 then
        
            local alphaPerSecond = .5        
            flashInAlpha = Clamp(flashInAlpha - alphaPerSecond * deltaTime, 0, 1)
            self.flashInOverlay:SetColor(Color(1, 1, 1, flashInAlpha))
            
        end
    
    end
	
	local alpha = 0
    local pulseSpeed = 5
    
    if self.weaponClip <= 2 then
        
        if self.weaponClip == 1 then
            pulseSpeed = 10
        elseif fraction == 0 then
            pulseSpeed = 25
        end
        
        alpha = (math.sin(self.globalTime * pulseSpeed) + 1) / 2
    end
    
    if not self.lowAmmoWarning then alpha = 0 end
    
    self.lowAmmoOverlay:SetColor(Color(1, 0, 0, alpha * 0.5))
    
end

function GUICannonDisplay:SetClip(weaponClip)
    self.weaponClip = weaponClip
end

function GUICannonDisplay:SetClipSize(weaponClipSize)
    self.weaponClipSize = weaponClipSize
end

function GUICannonDisplay:SetAmmo(weaponAmmo)
    self.weaponAmmo = weaponAmmo
end

function GUICannonDisplay:SetGlobalTime(globalTime)
    self.globalTime = globalTime
end

function GUICannonDisplay:SetLowAmmoWarning(lowAmmoWarning)
    self.lowAmmoWarning = ConditionalValue(lowAmmoWarning == "true", true, false)
end

/**
 * Called by the player to update the components.
 */
function Update(deltaTime)

    bulletDisplay:SetClip(weaponClip)
    bulletDisplay:SetAmmo(weaponAmmo)
	bulletDisplay:SetGlobalTime(globalTime)
	bulletDisplay:SetLowAmmoWarning(lowAmmoWarning)
    bulletDisplay:Update(deltaTime)
        
end

/**
 * Initializes the player components.
 */
function Initialize()

    GUI.SetSize( 256, 256 )

    bulletDisplay = GUICannonDisplay()
    bulletDisplay:Initialize()
	bulletDisplay:SetGlobalTime(globalTime)
    bulletDisplay:SetLowAmmoWarning(lowAmmoWarning)
    bulletDisplay:SetClipSize(10)

end

Initialize()
