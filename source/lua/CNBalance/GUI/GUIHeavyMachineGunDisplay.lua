
-- Global state that can be externally set to adjust the display.
weaponClip     = 0
weaponAmmo     = 0
weaponVariant  = 1
globalTime     = 0
lowAmmoWarning = "true"

local prevWeaponVariant = 1

local magCount = kHeavyMachineGunClipSize
local magMax = kHeavyMachineGunClipSize
local backgroundSize = Vector(256, 160, 0)
local textYOffset = 58

local magLeft = 30
local magWidth = 220 - 31
local magTopY = 174
local magHeight = 30
local magYOffset = 68

local textScale = 1.061

--kHMGVariants = enum({ "normal", "kodiak", "tundra", "forge", "sandstorm", "chroma" })

local kTextures =
{
    "ui/hmgdisplay0.dds", -- normal
    "ui/hmgdisplay4.dds", -- kodiak
    "ui/hmgdisplay2.dds", -- tundra
    "ui/hmgdisplay3.dds", -- forge
    "ui/hmgdisplay1.dds", -- sandstorm
    "ui/hmgdisplay5.dds", -- chroma
}

local self = {} -- provide some encapsulation

function Update(deltaTime)

    PROFILE("GUIHeavyMachineGunDisplay:Update")

    -- Update ammo counter.
    local ammoString = string.format("%03d", weaponClip)
    self.ammoText:SetText(ammoString)

    -- Update mags fractions.
    local ammoToDistribute = weaponAmmo
    for i=1, magCount do
        local ammoThisMag = math.min(ammoToDistribute, magMax)
        ammoToDistribute = ammoToDistribute - ammoThisMag
        local magFrac = ammoThisMag / magMax

        -- Update the magazine gui items with this fraction info.
        local mag = self.mags[i]

        if magFrac == 0.0 then
            mag:SetIsVisible(false)
        else
            mag:SetIsVisible(true)

            local magUIScale = 1.0/magCount;
            local magHorizontalwidth = magWidth * magUIScale
            local magLeftX = magLeft + magHorizontalwidth * (i-1)
            local magRightX = magLeftX + magHorizontalwidth * magFrac
            local magPosY = magTopY
            local magBottomY = magTopY + magHeight

            mag:SetPosition(Vector(magLeftX, magPosY - magYOffset, 0))
            mag:SetSize(Vector(magRightX - magLeftX, magBottomY - magPosY, 0))
            mag:SetTexturePixelCoordinates(magLeftX, magPosY, magRightX, magBottomY)

        end

    end

    -- Update low ammo warning.
    if lowAmmoWarning == "true" then
        self.lowAmmoOverlay:SetIsVisible(true)
        local fraction = weaponClip / magMax
        local alpha = 0
        local pulseSpeed = 5
        if fraction <= 0.4 then
            if fraction == 0 then
                pulseSpeed = 25
            elseif fraction < 0.25 then
                pulseSpeed = 10
            end

            alpha = math.sin(globalTime * pulseSpeed) * 0.5 + 0.5
        end
        self.lowAmmoOverlay:SetColor(Color(1, 0, 0, alpha * 0.25))
    else
        self.lowAmmoOverlay:SetIsVisible(false)
    end

    -- Update weapon variant
    if weaponVariant ~= prevWeaponVariant then
        prevWeaponVariant = weaponVariant

        local texName = kTextures[weaponVariant]
        self.background:SetTexture(texName)
        for i=1, magCount do
            self.mags[i]:SetTexture(texName)
        end
    end

end

function Initialize()

    GUI.SetSize(backgroundSize.x, backgroundSize.y)

    local texName = "ui/hmgdisplay" .. weaponVariant - 1 .. ".dds"

    self.background = GUI.CreateItem()
    self.background:SetSize(backgroundSize)
    self.background:SetTexture(texName)
    self.background:SetTexturePixelCoordinates(0, 0, backgroundSize.x, backgroundSize.y)

    self.lowAmmoOverlay = GUI.CreateItem()
    self.lowAmmoOverlay:SetSize(backgroundSize)
    self.lowAmmoOverlay:SetIsVisible(false)

    self.ammoText = GUI.CreateItem()
    self.ammoText:SetOptionFlag(GUIItem.ManageRender)
    self.ammoText:SetFontName("fonts/AgencyFB_huge.fnt")
    self.ammoText:SetTextAlignmentX(GUIItem.Align_Center)
    self.ammoText:SetTextAlignmentY(GUIItem.Align_Center)
    self.ammoText:SetPosition(Vector(backgroundSize.x * 0.5, textYOffset, 0))
    self.ammoText:SetScale(Vector(textScale, textScale, 0))

    -- Magazines split into 3 sections: top, middle, and bottom.  Middle scales with ammo fraction.
    -- Top and bottom do not scale.  Bottom does not move.  Middle moves down as it scales down with
    -- ammo fraction.  Top moves down to stay on top of middle.
    self.mags = {}
    local magUIScale = 1.0 / magCount
    for i=1, magCount do
        local newMag = GUI.CreateItem()
        newMag:SetTexture(texName)
        newMag:SetLayer(1)
        newMag:SetSize(Vector(magLeft + magWidth * magUIScale, magHeight, 0))
        local magLeftX = magLeft + magWidth * magUIScale * (i-1)
        local magRightX = magLeft + magWidth * magUIScale * i
        newMag:SetTexturePixelCoordinates(magLeftX, magTopY, magRightX, magTopY + magHeight)
        newMag:SetPosition(Vector(magLeftX, magTopY - magYOffset, 0))
        newMag:SetBlendTechnique(GUIItem.Add)

        self.mags[i] = newMag
    end

end

Initialize()
