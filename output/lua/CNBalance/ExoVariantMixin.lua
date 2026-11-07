
function ExoVariantMixin:SetExoVariant(variant)
    self.exoVariant = self.GetExoVariantOverride and self:GetExoVariantOverride(variant) or variant
end

if Server then
    function ExoVariantMixin:OnClientUpdated(client, isPickup)
        Player.OnClientUpdated(self, client, isPickup)

        local data = client.variantData
        if data == nil or isPickup then
            return
        end

        if GetHasVariant(kExoVariantsData, data.exoVariant, client) or client:GetIsVirtual() then
            self.exoVariant = self.GetExoVariantOverride and self:GetExoVariantOverride(data.exoVariant) or data.exoVariant
            self.lastExoVariant = self.exoVariant
        else
            Log("ERROR: Client tried to request Exo variant they do not have yet")
        end
    end
end

if Client then

    -- The claw suits reuse the minigun and railgun skins, but their materials sit in different
    -- slots: exosuit_cm.model is suit/claw/gun, exosuit_cr.model is claw/railgun/suit, and only
    -- the minigun view model puts a claw material in front of the gun. Register the claw layouts
    -- as their own cosmetic classes with the slots renumbered, so vanilla keeps using its own
    -- index handling. Reporting the claw classes also keeps the left arm unskinned, which the
    -- vanilla classes would have painted with a gun skin.
    local kClawLoadouts = {
        ClawMinigun = { source = "Minigun", worldIndices = { 0, 2 }, viewIndices = { 1 } },
        ClawRailgun = { source = "Railgun", worldIndices = { 1, 2 }, viewIndices = { 0, 1 } },
    }

    for loadout, claw in pairs(kClawLoadouts) do
        local variants = {}
        for variant, variantData in ipairs(kExoVariantsData) do
            local entry = {}
            if variantData.worldMaterials then
                local worldMats = {}
                for i, worldMat in ipairs(variantData.worldMaterials[claw.source]) do
                    table.insert(worldMats, { idx = claw.worldIndices[i], mat = worldMat.mat })
                end
                entry.worldMaterials = { [loadout] = worldMats }
            end
            if variantData.viewMaterials then
                entry.viewMaterials = { [loadout] = variantData.viewMaterials[claw.source] }
            end
            variants[variant] = entry
        end
        PrecacheCosmeticMaterials(loadout, variants)
    end

    local kClawLoadoutByWeapon = {
        Minigun = "ClawMinigun",
        Railgun = "ClawRailgun",
    }

    local kClawLoadoutByModelSuffix = {
        ["_cm.model"] = "ClawMinigun",
        ["_cr.model"] = "ClawRailgun",
    }

    local baseGetWeaponLoadoutClass = ExoVariantMixin.GetWeaponLoadoutClass
    function ExoVariantMixin:GetWeaponLoadoutClass()
        local weaponClass = baseGetWeaponLoadoutClass(self)
        if weaponClass == "Claw" then
            local wep = self:GetActiveWeapon()
            local rightWeapon = wep and wep:GetRightSlotWeapon()
            return rightWeapon and kClawLoadoutByWeapon[rightWeapon:GetClassName()]
        end
        if not weaponClass and (self:isa("Exosuit") or self:isa("ReadyRoomExo")) then
            local modelName = self:GetModelName()
            for suffix, loadout in pairs(kClawLoadoutByModelSuffix) do
                if StringEndsWith(modelName, suffix) then
                    return loadout
                end
            end
        end
        return weaponClass
    end

    -- The view model swap is keyed on the vanilla class names, so the claw slots are filled here.
    local baseOnUpdateRender = ExoVariantMixin.OnUpdateRender
    function ExoVariantMixin:OnUpdateRender()
        local wasDirty = self.dirtySkinState
        baseOnUpdateRender(self)
        if not wasDirty or not self:isa("Exo") or not self:GetIsLocalPlayer() then
            return
        end
        local weaponClass = self:GetWeaponLoadoutClass()
        local claw = kClawLoadouts[weaponClass]
        if not claw then
            return
        end
        local viewModelEnt = self:GetViewModelEntity()
        local viewModel = viewModelEnt and viewModelEnt:GetRenderModel()
        if not viewModel or not viewModel:GetReadyForOverrideMaterials() then
            self.dirtySkinState = true
            return
        end
        if self.exoVariant == kDefaultExoVariant then
            return
        end
        local viewMats = GetPrecachedCosmeticMaterial(weaponClass, self.exoVariant, true)
        for i, slot in ipairs(claw.viewIndices) do
            viewModel:SetOverrideMaterial(slot, viewMats[i])
        end
        viewModelEnt:SetHighlightNeedsUpdate()
    end

end