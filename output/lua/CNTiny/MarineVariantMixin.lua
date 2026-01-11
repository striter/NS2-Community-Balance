
if Server then

    local baseOnClientUpdated = MarineVariantMixin.OnClientUpdated
    -- Usually because the client connected or changed their options.
    function MarineVariantMixin:OnClientUpdated(client, isPickup)
        if self.specMode == kSpectatorMode.Tinyman then return end
        baseOnClientUpdated(self,client,isPickup)
    end

end
