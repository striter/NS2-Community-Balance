
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