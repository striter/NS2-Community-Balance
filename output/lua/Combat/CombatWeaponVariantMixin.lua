-- ======= Copyright (c) 2018, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\BuilderVariantMixin.lua
--
-- ==============================================================================================

Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")

CombatWeaponVariant = CreateMixin(CombatWeaponVariant)
CombatWeaponVariant.type = "CombatWeaponVariant"

CombatWeaponVariant.networkVars =
{
}

--Note: this only pertains to the World model a marine carries
function CombatWeaponVariant:__initmixin()

    PROFILE("BuilderVariantMixin:__initmixin")

    --if Client then
    --    self.dirtySkinState = true
    --end
end

if Client then

    --CombatWeaponVariant.kHandMaterialViewIndexes = --Zero-based indices (shared view model for all bmacs)
    --{
    --    ["Knife"] = 0,
    --    ["LightMachineGun"] = 0,
    --    ["SubMachineGun"] = 0,
    --    ["Revolver"] = 0,
    --    ["Cannon"] = 0,
    --}
    --CombatWeaponVariant.kMarineHandMaterials = 
    --{
    --    [kMarineVariants.green] = PrecacheAsset("models/marine/hands/hands.material"),
    --    [kMarineVariants.special] = PrecacheAsset("models/marine/hands/hands_black.material"),
    --    [kMarineVariants.deluxe] = PrecacheAsset("models/marine/hands/hands_special.material"),
    --    [kMarineVariants.assault] = PrecacheAsset("models/marine/hands/hands_assault.material"),
    --    [kMarineVariants.eliteassault] = PrecacheAsset("models/marine/hands/hands_eliteassault.material"),
    --    [kMarineVariants.kodiak] = PrecacheAsset("models/marine/hands/hands_kodiak.material"),
    --    [kMarineVariants.tundra] = PrecacheAsset("models/marine/hands/hands_tundra.material"),
    --    [kMarineVariants.anniv] = PrecacheAsset("models/marine/hands/hands_anniv.material"),
    --    [kMarineVariants.sandstorm] = PrecacheAsset("models/marine/hands/hands_sandstorm.material"),
    --    [kMarineVariants.chroma] = PrecacheAsset("models/marine/hands/hands_chroma.material"),
    --}
    --
    --function CombatWeaponVariant:SetSkinStateDirty()
    --    self.dirtySkinState = true
    --    return true
    --end
    --
    --function CombatWeaponVariant:OnUpdateRender()
    --    PROFILE("BuilderVariantMixin:OnUpdateRender")
    --
    --    if self.dirtySkinState then
    --
    --        local player = self:GetParent()
    --        if player and player:GetIsLocalPlayer() and player:GetActiveWeapon() == self then
    --            local viewModelEnt = player:GetViewModelEntity()
    --            if viewModelEnt then
    --                local viewModel = viewModelEnt:GetRenderModel()
    --                if viewModel and viewModel:GetReadyForOverrideMaterials() then
    --                    local viewMatIndex = CombatWeaponVariant.kHandMaterialViewIndexes[self:GetClassName()]
    --                    assert(viewMatIndex)
    --                    local viewMat = CombatWeaponVariant.kMarineHandMaterials[player.clientVariant]
    --                    if viewMat then
    --                        viewModel:SetOverrideMaterial( viewMatIndex, viewMat )
    --                    end
    --                else
    --                    return false
    --                end
    --
    --                viewModelEnt:SetHighlightNeedsUpdate()
    --            end
    --
    --        end
    --
    --        self.dirtySkinState = false
    --    end
    --
    --end

end
