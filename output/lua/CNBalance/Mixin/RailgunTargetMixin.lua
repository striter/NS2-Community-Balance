-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\CloakableMixin.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
--    Outlines targets blue when SetRailgunTarget() is called for kRailgunTargetDuration seconds.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

RailgunTargetMixin = CreateMixin( RailgunTargetMixin )
RailgunTargetMixin.type = "RailgunTarget"

PrecacheAsset("cinematics/vfx_materials/highlightmodel.surface_shader")

local kRailgunTargetDuration = 0.3
local kHighlightmodel_Material = PrecacheAsset("cinematics/vfx_materials/highlightmodel.material")

RailgunTargetMixin.expectedMixins =
{
    Model = "Required to add to shader mask."
}

function RailgunTargetMixin:__initmixin()
    
    PROFILE("RailgunTargetMixin:__initmixin")
    
    assert(Client)
    self.isRailgunTarget = false
    self.timeRailgunTargeted = -1
end

function RailgunTargetMixin:SetRailgunTarget()
    self.timeRailgunTargeted = Shared.GetTime()
end




local function GetTargetOutline(weaponClass)
    if not RailgunTargetMixin.kRailgunTargetLookup then
        RailgunTargetMixin.kRailgunTargetLookup = {
            ["Onos"] = kEquipmentOutlineColor.Red,
            ["Fade"] = kEquipmentOutlineColor.Red,
            ["Vokex"] = kEquipmentOutlineColor.Red,
            ["Lerk"] = kEquipmentOutlineColor.Yellow,
            ["Skulk"] = kEquipmentOutlineColor.Yellow,
            ["Prowler"] = kEquipmentOutlineColor.Yellow,
            ["Gorge"] = kEquipmentOutlineColor.Fuchsia,
        }
    end
    
    return RailgunTargetMixin.kRailgunTargetLookup[weaponClass]
end

function RailgunTargetMixin:OnUpdate(deltaTime)
    PROFILE("RailgunTargetMixin:OnUpdate")
    local isTarget = self.timeRailgunTargeted + kRailgunTargetDuration > Shared.GetTime()
    local model = self:GetRenderModel()

    local highlight = self:GetIsAlive() and HasMixin(self, "LOS") and self:GetIsSighted() and GetIsTargetDetected(self)
    isTarget = isTarget or highlight
    if self.isRailgunTarget ~= isTarget and model then
    
        if isTarget then
            EquipmentOutline_AddModel(model,GetTargetOutline(self:GetClassName()) or kEquipmentOutlineColor.TSFBlue)
        else
            EquipmentOutline_RemoveModel(model)
        end
        
        self.isRailgunTarget = isTarget
    end

end

-- disabled since it doesnt look very good and distracts too much
--function RailgunTargetMixin:OnUpdateRender()
--
--    local model = self:GetRenderModel()
--
--    if model then
--    
--        local intensity = 1 - Clamp( (Shared.GetTime() - self.timeRailgunTargeted) / 0.3, 0, 1 )
--        local showMaterial = intensity ~= 0
--    
--        if not self.railgunHighlightMaterial and showMaterial then
--            self.railgunHighlightMaterial = AddMaterial(model, kHighlightmodel_Material)
--        elseif not showMaterial and self.railgunHighlightMaterial then
--            RemoveMaterial(model, self.railgunHighlightMaterial)
--            self.railgunHighlightMaterial = nil
--        end
--
--        if self.railgunHighlightMaterial then
--            self.railgunHighlightMaterial:SetParameter("intensity", intensity * 0.5)
--        end
--    
--    end
--
--end
