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
    local kSelfDamagePercentPerSecond = .05
    local kSelfDamageInterval = 2

    local function CheckShouldDestroy(self)

        local player = nil
        
        if self.ownerClientId then

            local client = Server.GetClientById(self.ownerClientId)
            
            if client then
                player = client:GetControllingPlayer()
            end
        
        end
        local valid = player ~= nil
        if valid then
            valid = player.GetWeapon and player:GetWeapon(CombatBuilder.kMapName) ~= nil
        end
        
        if not valid then
            if self:GetIsGhostStructure() then
                self:PerformAction(GetTechTree(self:GetTeamNumber()):GetTechNode(kTechId.Cancel))
            elseif self:GetCanDie() then
                local deductHealth = kSelfDamageInterval*kSelfDamagePercentPerSecond*self:GetMaxHealth()
                self.recycled=self:GetHealth() <= deductHealth
                self:DeductHealth(deductHealth, nil, self , true)
            end
        end
        
        return true

    end

    function MarineStructureMixin:__initmixin()
        local owner = self:GetOwner()
        if owner then 
            self.ownerClientId = Server.GetOwner(owner):GetId()
            self:AddTimedCallback(CheckShouldDestroy, kSelfDamageInterval)
        end
    end
end

