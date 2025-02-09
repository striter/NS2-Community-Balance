--
--	ns2siege+ Custom Game Mode
--	ZycaR (c) 2016
--

if Client then
    local function LoadGuiElement(luafile)
        local script = GetGUIManager():CreateGUIScriptSingle(luafile)
        if script and script.SetIsVisible then
            script:SetIsVisible(true)
        end
    end


    -- load and run custom gui elements as singletons
    LoadGuiElement("sg_gui/GUIDoorTimers")
end
