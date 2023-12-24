-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUIEggDisplay.lua
--
-- Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
--
-- Shows icons above eggs.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIEggDisplay' (GUIScript)

GUIEggDisplay.kVisionExtents = GUIScale( Vector(64, 64, 0) )
GUIEggDisplay.kVisionCommExtents = GUIScale( Vector(48, 48, 0) )

local eggTextures
local function GetTextureForTechId(techId)

    if not eggTextures then
    
        eggTextures = {}
        eggTextures[kTechId.Skulk] = "ui/Skulk.dds"
        eggTextures[kTechId.Gorge] = "ui/Gorge.dds"
        eggTextures[kTechId.Lerk] = "ui/Lerk.dds"
        eggTextures[kTechId.Fade] = "ui/Fade.dds"
        eggTextures[kTechId.Onos] = "ui/Onos.dds"
        eggTextures[kTechId.Prowler] = "ui/Prowler.dds"
        eggTextures[kTechId.Vokex] = "ui/Fade.dds"
    end
    
    if eggTextures[techId] then
        return eggTextures[techId]
    end

    return ""    

end

local function CreateVisionElement(_)

    local guiItem = GetGUIManager():CreateGraphicItem()
    
    if not PlayerUI_IsOverhead() then
        guiItem:SetBlendTechnique(GUIItem.Add)
    end
    
    return guiItem

end

function GUIEggDisplay:Initialize()

    self.updateInterval = 0

    self.background = GetGUIManager():CreateGraphicItem()
    self.background:SetColor(Color(0,0,0,0))
    self.activeVisions = { }
    
end

function GUIEggDisplay:Uninitialize()

    if self.background then
    
        GUI.DestroyItem(self.background)
        self.background = nil
        
    end

    self.activeVisions = { }
    
end

function GUIEggDisplay:SetIsVisible(isVisible)
    self.background:SetIsVisible(isVisible)
end

function GUIEggDisplay:Update(_)
                  
    PROFILE("GUIEggDisplay:Update")
    
    local unitVisions = PlayerUI_GetEggDisplayInfo()

    local numActiveVisions = #self.activeVisions
    local numCurrentVisions = #unitVisions
    
    -- local stencilUpdated = numActiveVisions ~= numCurrentVisions
    
    if numCurrentVisions > numActiveVisions then
    
        for i = 1, numCurrentVisions - numActiveVisions do
        
            local newElement = CreateVisionElement(self)
            self.background:AddChild(newElement)        
            table.insert(self.activeVisions, newElement)
            
        end
    
    elseif numActiveVisions > numCurrentVisions then
    
        for i = 1, numActiveVisions - numCurrentVisions do
        
            GUI.DestroyItem(self.activeVisions[#self.activeVisions])
            table.remove(self.activeVisions, #self.activeVisions)
            
        end
    
    end

    local size = ConditionalValue(PlayerUI_IsOverhead(), GUIEggDisplay.kVisionCommExtents, GUIEggDisplay.kVisionExtents)
    
    for index, currentVision in ipairs(unitVisions) do   
    
        local visionElement = self.activeVisions[index]        
        visionElement:SetPosition(currentVision.Position - size *.5)        
        visionElement:SetSize(size)
        visionElement:SetTexture( GetTextureForTechId(currentVision.TechId) )
        
    end

end