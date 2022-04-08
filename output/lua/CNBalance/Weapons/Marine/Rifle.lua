if Client then

    function Rifle:GetUIDisplaySettings()
        return { xSize = 256, ySize = 417, script = "lua/CNBalance/GUI/GUIRifleDisplay.lua", variant = self:GetRifleVariant() }
    end
    
end