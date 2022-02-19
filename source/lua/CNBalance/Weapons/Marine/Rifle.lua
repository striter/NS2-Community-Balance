if Client then

    function Rifle:GetUIDisplaySettings()
        return { xSize = 256, ySize = 417, script = "lua/CNBalance/GUI/GUIRifleDisplay.lua", variant = self:GetRifleVariant() }
    end
    
end

function Rifle:GetClipSize()
    local clipSize=kRifleClipSize
    
    if GetHasTech(self, kTechId.RifleUpgrade) then
        clipSize = clipSize+5
    end

    return clipSize
end
