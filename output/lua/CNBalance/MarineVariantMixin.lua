if Client then
    kBmacMaterialViewIndices["CombatBuilder"] = 2
    kBmacMaterialViewIndices["Knife"] = 0
    kBmacMaterialViewIndices["LightMachineGun"] = 0
    kBmacMaterialViewIndices["SubMachineGun"] = 0
    kBmacMaterialViewIndices["Revolver"] = 0
    kBmacMaterialViewIndices["Cannon"] = 0
end


if Server then
    function MarineVariantMixin:CopyPlayerDataFrom(player)
        --Handle copy to JetPack and/or Exos
        if player.variant then
            self.variant = self.GetVariantOverride and self:GetVariantOverride(player.variant) or player.variant
        end
    end

    -- Usually because the client connected or changed their options.
    function MarineVariantMixin:OnClientUpdated(client, isPickup)

        if not Shared.GetIsRunningPrediction() then
            Player.OnClientUpdated(self, client, isPickup)

            local data = client.variantData
            if data == nil then
                return
            end

            if table.icontains( kRoboticMarineVariantIds, data.marineVariant ) then
                self.marineType = kMarineVariantsBaseType.bigmac
            else
                self.marineType = data.isMale and kMarineVariantsBaseType.male or kMarineVariantsBaseType.female
            end

            self.shoulderPadIndex = 0

            local selectedIndex = client.variantData.shoulderPadIndex

            if GetHasShoulderPad(selectedIndex, client) then
                self.shoulderPadIndex = selectedIndex
            end

            -- Some entities using MarineVariantMixin don't care about model changes.
            if self.GetIgnoreVariantModels and self:GetIgnoreVariantModels() then
                return
            end

            if GetHasVariant(kMarineVariantsData, data.marineVariant, client) or client:GetIsVirtual() then
                assert(self.variant > 0)
                self.variant = self.GetVariantOverride and self:GetVariantOverride(data.marineVariant) or data.marineVariant -- data.marineVariant
                local modelName = self:GetVariantModel()
                assert(modelName ~= "")
                self:SetModel(modelName, MarineVariantMixin.kMarineAnimationGraph)
            else
                Print("ERROR: Client tried to request marine variant they do not have yet")
            end

            -- Trigger a weapon skin update, to update the view model
            self:UpdateWeaponSkin(client)
        end

    end

end