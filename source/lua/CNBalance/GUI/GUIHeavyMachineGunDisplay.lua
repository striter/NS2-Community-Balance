
-- Global state that can be externally set to adjust the display.
weaponClip     = 0
weaponAmmo     = 0
weaponVariant  = 1
globalTime     = 0
lowAmmoWarning = "true"

local prevWeaponVariant = 1

local magCount = 2
local magMax = 200

local magLeft = 30
local magWidth = 220 - 31
local magTopY = 174
local magHeight = 30
local magYOffset = 68

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

