Script.Load("lua/GUIScript.lua")
Script.Load("lua/Utility.lua")

weaponClip     = 0
weaponAmmo     = 0
weaponAuxClip  = 0
globalTime 		= 0
FontScaleVector = Vector(1, 1, 1) * 1.85
FontScaleReserveVector = Vector(1, 1, 1) * 0.95

bulletDisplay  = nil
grenadeDisplay = nil

class 'GUILightMachineGunDisplay' (GUIScript)

function GUILightMachineGunDisplay:Initialize()

    self.weaponClip     = 0
    self.weaponAmmo     = 0
    self.weaponClipSize = 50
	self.globalTime = 0
    self.lowAmmoWarning = true
    
    self.onDraw = 0
    self.onHolster = 0

    self.background = GUIManager:CreateGraphicItem()
    //self.background:SetSize( Vector(512, 512, 0) )
    self.background:SetSize( Vector(256, 420, 0) )
    self.background:SetPosition( Vector(0, 0, 0))    
    self.background:SetPosition( Vector(0, 0, 0))    
    self.background:SetTexture("ui/lmgdisplay.dds")
    self.background:SetIsVisible(true)
	
	self.lowAmmoOverlay = GUIManager:CreateGraphicItem()
    self.lowAmmoOverlay:SetSize( Vector(256, 420, 0) )
    self.lowAmmoOverlay:SetPosition( Vector(0, 0, 0))
	self.background:AddChild(self.lowAmmoOverlay)

    self.ammoTextBg = GUIManager:CreateTextItem()
    self.ammoTextBg:SetFontName("fonts/LMGFont.fnt")
    self.ammoTextBg:SetScale(FontScaleVector * 1.1)
    self.ammoTextBg:SetFontIsBold(true)
    self.ammoTextBg:SetTextAlignmentX(GUIItem.Align_Center)
    self.ammoTextBg:SetTextAlignmentY(GUIItem.Align_Center)
    self.ammoTextBg:SetPosition(Vector(125, 150, 0))
    self.ammoTextBg:SetColor(Color(0, 0, 1, 0.25))

    self.ammoText = GUIManager:CreateTextItem()
    //self.ammoText:SetFontName("fonts/MicrogrammaDMedExt_large.fnt")
    self.ammoText:SetFontName("fonts/LMGFont.fnt")
    self.ammoText:SetScale(FontScaleVector)
    self.ammoText:SetFontIsBold(true)
    self.ammoText:SetTextAlignmentX(GUIItem.Align_Center)
    self.ammoText:SetTextAlignmentY(GUIItem.Align_Center)
    self.ammoText:SetPosition(Vector(125, 150, 0))
    self.ammoText:SetColor(Color(1, 1, 1, 1))
    
    self.ammoTextReserveBg = GUIManager:CreateTextItem()
    self.ammoTextReserveBg:SetFontName("fonts/LMGFont.fnt")
	self.ammoTextReserveBg:SetScale(FontScaleReserveVector * 1.1)
    self.ammoTextReserveBg:SetTextAlignmentX(GUIItem.Align_Center)
    self.ammoTextReserveBg:SetTextAlignmentY(GUIItem.Align_Center)
    self.ammoTextReserveBg:SetPosition(Vector(120, 310, 0))
    self.ammoTextReserveBg:SetColor(Color(0, 0, 1, 0.25))

    self.ammoTextReserve = GUIManager:CreateTextItem()
    self.ammoTextReserve:SetFontName("fonts/LMGFont.fnt")
    self.ammoTextReserve:SetScale(FontScaleReserveVector)
    self.ammoTextReserve:SetTextAlignmentX(GUIItem.Align_Center)
    self.ammoTextReserve:SetTextAlignmentY(GUIItem.Align_Center)
    self.ammoTextReserve:SetPosition(Vector(120, 310, 0))
    self.ammoTextReserve:SetColor(Color(1, 1, 1, 1))
    
    self:Update(0)

end

function GUILightMachineGunDisplay:Update(deltaTime)

    PROFILE("GUILightMachineGunDisplay:Update")

    
    local ammoFormat = string.format("%02d", self.weaponClip) 
    self.ammoText:SetText( ammoFormat )
    self.ammoTextBg:SetText( ammoFormat )
    
    local reserveFormat = string.format("%02d", self.weaponAmmo) 
    self.ammoTextReserve:SetText( reserveFormat )
    self.ammoTextReserveBg:SetText( reserveFormat )
	
	local alpha = 0
    local pulseSpeed = 5
    
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

function GUILightMachineGunDisplay:SetClip(weaponClip)
    self.weaponClip = weaponClip
end

function GUILightMachineGunDisplay:SetClipSize(weaponClipSize)
    self.weaponClipSize = weaponClipSize
end

function GUILightMachineGunDisplay:SetAmmo(weaponAmmo)
    self.weaponAmmo = weaponAmmo
end

function GUILightMachineGunDisplay:SetGlobalTime(globalTime)
    self.globalTime = globalTime
end

function GUILightMachineGunDisplay:SetLowAmmoWarning(lowAmmoWarning)
    self.lowAmmoWarning = ConditionalValue(lowAmmoWarning == "true", true, false)
end

function GUILightMachineGunDisplay:SetClipFraction(clipIndex, fraction)

    local offset   = (1 - fraction) * self.clipHeight
    local position = Vector( self.clip[clipIndex]:GetPosition().x, self.clipTop + offset, 0 )
    local size     = self.clip[clipIndex]:GetSize()
    
    self.clip[clipIndex]:SetPosition( position )
    self.clip[clipIndex]:SetSize( Vector( size.x, fraction * self.clipHeight, 0 ) )
    self.clip[clipIndex]:SetTexturePixelCoordinates( position.x, position.y + 256, position.x + self.clipWidth, self.clipTop + self.clipHeight + 256 )

end

function Update(deltaTime)

    PROFILE("GUILightMachineGunDisplay:Update")

    bulletDisplay:SetClip(weaponClip)
    bulletDisplay:SetAmmo(weaponAmmo)
	bulletDisplay:SetGlobalTime(globalTime)
	bulletDisplay:SetLowAmmoWarning(lowAmmoWarning)
    bulletDisplay:Update(deltaTime)
    
end

function Initialize()

    GUI.SetSize(512, 512)

    bulletDisplay = GUILightMachineGunDisplay()
    bulletDisplay:Initialize()
	bulletDisplay:SetGlobalTime(globalTime)
    bulletDisplay:SetLowAmmoWarning(lowAmmoWarning)
    bulletDisplay:SetClipSize(50)

end

Initialize()