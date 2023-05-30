MarineStructureMixin = CreateMixin(MarineStructureMixin)
MarineStructureMixin.type = "MarineStructure"

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
    --local kSelfDamagePercentPerSecond = .05
    local kTickInterval = 1
    local kAutoBuildPerSecond = 0.75

    local function Tick(self)

        local player = nil
        --
        if self.ownerClientId then

            local client = Server.GetClientById(self.ownerClientId)

            if client then
                player = client:GetControllingPlayer()
            end

        end
        local valid = player ~= nil
        --if valid then
        --    valid = player.GetWeapon and player:GetWeapon(CombatBuilder.kMapName) ~= nil
        --end
        
        if valid then
            --if not self:GetIsBuilt() then
            --    self:Construct(kAutoBuildPerSecond * kTickInterval,self.owner)
            --end
        else
            if self:GetIsGhostStructure() then
                self:PerformAction(GetTechTree(self:GetTeamNumber()):GetTechNode(kTechId.Cancel))
            elseif self:GetCanDie() then
                --local deductHealth = kTickInterval *kSelfDamagePercentPerSecond*self:GetMaxHealth()
                --self.recycled=self:GetHealth() <= deductHealth
                --self:DeductHealth(deductHealth, nil, self , true)
                self:Kill()
            end
        end
        
        return true

    end

    function MarineStructureMixin:__initmixin()
        local owner = self:GetOwner()
        if owner then 
            self.ownerClientId = Server.GetOwner(owner):GetId()
            self:AddTimedCallback(Tick, kTickInterval)
        end
    end

    function MarineStructureMixin:GetCanAutoBuild()
        return true
    end
end

