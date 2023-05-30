Script.Load("lua/GUIScript.lua")
Script.Load("lua/Utility.lua")

weaponClip     = 0
weaponAmmo     = 0
weaponAuxClip  = 0
globalTime     = 0
bulletDisplay  = nil

FontScaleVector = Vector(1, 1.4, 1) * 2

class 'GUIRevolverDisplay'

function GUIRevolverDisplay:Initialize()

    self.weaponClip     = 0
    self.weaponAmmo     = 0
    self.weaponClipSize = 10
	self.globalTime = 0
    self.lowAmmoWarning = true
    
    self.flashInDelay = 1.2

    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize( Vector(512, 512, 0) )
    self.background:SetPosition( Vector(0, 0, 0))    
    self.background:SetTexture("ui/revolver_display.dds")
	
	self.lowAmmoOverlay = GUIManager:CreateGraphicItem()
    self.lowAmmoOverlay:SetSize( Vector(512, 512, 0) )
    self.lowAmmoOverlay:SetPosition( Vector(0, 0, 0))    
	self.background:AddChild(self.lowAmmoOverlay)
    
    self.clipText, self.clipTextBg = self:CreateItem(100, 150)
    self.ammoText, self.ammoTextBg = self:CreateItem(350, 350)
	
	local slash, slashBg = self:CreateItem(256, 256)
    slash:SetText("/")
	slash:SetFontSize(256)
    slashBg:SetText("/")
	slashBg:SetFontSize(256)
    
    self.flashInOverlay = GUIManager:CreateGraphicItem()
    self.flashInOverlay:SetSize( Vector(512, 512, 0) )
    self.flashInOverlay:SetPosition( Vector(0, 0, 0))    
    self.flashInOverlay:SetColor(Color(1,1,1,0.0))
    self.background:AddChild(self.flashInOverlay)
    
    self:Update(0)

end

function GUIRevolverDisplay:CreateItem(x, y)

    local textBg = GUIManager:CreateTextItem()
    textBg:SetFontName("fonts/LMGFont.fnt")
	textBg:SetScale(FontScaleVector)
    textBg:SetFontSize(200)
    textBg:SetTextAlignmentX(GUIItem.Align_Center)
    textBg:SetTextAlignmentY(GUIItem.Align_Center)
    textBg:SetPosition(Vector(x, y, 0))
    textBg:SetColor(Color(0.88, 0.98, 1, 0.25))

    local text = GUIManager:CreateTextItem()
    text:SetFontName("fonts/LMGFont.fnt")
    text:SetFontSize(200)
    text:SetScale(FontScaleVector)
    text:SetTextAlignmentX(GUIItem.Align_Center)
    text:SetTextAlignmentY(GUIItem.Align_Center)
    text:SetPosition(Vector(x, y, 0))
    text:SetColor(Color(0.88, 0.98, 1))
    
    return text, textBg
    
end

function GUIRevolverDisplay:Update(deltaTime)

    PROFILE("GUIRevolverDisplay:Update")
    
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

function GUIRevolverDisplay:SetClip(weaponClip)
    self.weaponClip = weaponClip
end

function GUIRevolverDisplay:SetClipSize(weaponClipSize)
    self.weaponClipSize = weaponClipSize
end

function GUIRevolverDisplay:SetAmmo(weaponAmmo)
    self.weaponAmmo = weaponAmmo
end

function GUIRevolverDisplay:SetGlobalTime(globalTime)
    self.globalTime = globalTime
end

function GUIRevolverDisplay:SetLowAmmoWarning(lowAmmoWarning)
    self.lowAmmoWarning = ConditionalValue(lowAmmoWarning == "true", true, false)
end

function Update(deltaTime)

    bulletDisplay:SetClip(weaponClip)
    bulletDisplay:SetAmmo(weaponAmmo)
	bulletDisplay:SetGlobalTime(globalTime)
	bulletDisplay:SetLowAmmoWarning(lowAmmoWarning)
    bulletDisplay:Update(deltaTime)
        
end

function Initialize()

    GUI.SetSize( 512, 512 )

    bulletDisplay = GUIRevolverDisplay()
    bulletDisplay:Initialize()
	bulletDisplay:SetGlobalTime(globalTime)
    bulletDisplay:SetLowAmmoWarning(lowAmmoWarning)
    bulletDisplay:SetClipSize(10)

end

Initialize()
