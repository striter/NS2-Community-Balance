local baseOnInitialized = Rifle.OnInitialized
function Rifle:OnInitialized()
    baseOnInitialized(self)
    self.ammo = self:GetMaxClips() * self:GetClipSize()
    self.clip = self:GetClipSize()
end

function Rifle:GetClipSize()
    return GetHasTech(self,kTechId.MilitaryProtocol) and kMPRifleClipSize[NS2Gamerules_GetPlayerWeaponUpgradeIndex(self)] or kRifleClipSize
end

if Client then
    function Rifle:GetUIDisplaySettings()
        return { xSize = 256, ySize = 417, script = "lua/CNBalance/GUI/GUIRifleDisplay.lua", variant = self:GetRifleVariant() }
    end
end

if Server then
    function Rifle:GetVariantOverride(variant)
        if GetHasTech(self,kTechId.MilitaryProtocol) then
            return kRifleVariants.chroma
        end
        return variant
    end
end 