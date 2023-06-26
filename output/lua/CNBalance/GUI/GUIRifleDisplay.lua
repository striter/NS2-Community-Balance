
Script.Load("lua/GUIBulletDisplay.lua")
Script.Load("lua/GUIGrenadeDisplay.lua")

-- Global state that can be externally set to adjust the display.
weaponClip     = 0
weaponClipSize = 0
weaponAmmo     = 0
weaponAuxClip  = 0
weaponVariant  = 1
pulsateAlpha   = 0
globalTime     = 0
lowAmmoWarning = true

bulletDisplay  = nil
grenadeDisplay = nil

--
-- Called by the player to update the components.
--
function Update(deltaTime)

    PROFILE("GUIRifleDisplay:Update")

    bulletDisplay:SetClip(weaponClip)
    bulletDisplay:SetClipSize(weaponClipSize)
    bulletDisplay:SetAmmo(weaponAmmo)
    bulletDisplay:SetWeaponVariant(weaponVariant)
    bulletDisplay:SetGlobalTime(globalTime)
    bulletDisplay:SetLowAmmoWarning(lowAmmoWarning)
    bulletDisplay:Update(deltaTime)
    
    grenadeDisplay:SetNumGrenades(weaponAuxClip)
    grenadeDisplay:Update(deltaTime)
    
end

--
-- Initializes the player components.
--
function Initialize()

    GUI.SetSize(256, 417)

    bulletDisplay = GUIBulletDisplay()
    bulletDisplay:Initialize()
    bulletDisplay:SetClipSize(50)
    bulletDisplay:SetGlobalTime(globalTime)
    bulletDisplay:SetLowAmmoWarning(lowAmmoWarning)

    grenadeDisplay = GUIGrenadeDisplay()
    grenadeDisplay:Initialize()

end

Initialize()