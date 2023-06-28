
if Server then

    function RifleVariantMixin:UpdateWeaponSkins(client)
        assert(client.variantData)
        
        if GetHasVariant(kRifleVariantsData, client.variantData.rifleVariant, client) or client:GetIsVirtual() then
            self.rifleVariant = self.GetVariantOverride and self:GetVariantOverride(client.variantData.rifleVariant) or client.variantData.rifleVariant            
        else
            Log("ERROR: Client tried to request Rifle variant they do not have yet")
        end
    end
    
end
