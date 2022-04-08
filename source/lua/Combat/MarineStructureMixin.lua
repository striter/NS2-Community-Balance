MarineStructureMixin = CreateMixin(MarineStructureMixin)
MarineStructureMixin.type = "MarineStructureMixin"

MarineStructureMixin.networkVars =
{
}

MarineStructureMixin.expectedMixins =
{
}

MarineStructureMixin.expectedCallbacks =
{
}

if Server then
    local kSelfDamagePercentPerSecond = .1
    local kSelfDamageInterval = 2

    local function CheckShouldDestroy(self)

        local player = nil
        
        if self.ownerClientId then

            local client = Server.GetClientById(self.ownerClientId)
            
            if client then
                player = client:GetControllingPlayer()
            end
        
        end
        
        
        if not player or not ( player.GetWeapon and player:GetWeapon(CombatBuilder.kMapName)) then
            if self:GetCanDie() then
                self:DeductHealth(kSelfDamageInterval*kSelfDamagePercentPerSecond*self.GetMaxHealth(), nil, self , true)()
            end
        end
        
        return true

    end

    function MarineStructureMixin:__initmixin()
            local owner = self:GetOwner()
            if owner then
                self:SetClientId(owner)
                self:AddTimedCallback(CheckShouldDestroy, kSelfDamageInterval)
            end
    end


    function MarineStructureMixin:GetOwnerClientId()
        return self.ownerClientId
    end

    --save the client, not the playerID, the playerId changes after every death etc
    function MarineStructureMixin:SetClientId(player)
        local clientId = Server.GetOwner(player):GetId()
        self.ownerClientId = clientId
    end

    
end

