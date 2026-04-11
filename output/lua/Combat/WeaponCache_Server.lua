local function OnDeploy(self)
    self.deployed = true
    self.showAura = true
    self:TriggerEffects("weaponcache_deploy")
    return false
end

local kDeployTime = 3

function WeaponCache:OnConstructionComplete()
    self:AddTimedCallback(OnDeploy, kDeployTime)
end

function WeaponCache:OnDestroy()
    self.showAura = false
end

function WeaponCache:GetTimeToResupplyPlayer(player)
    assert(player ~= nil)
    
    local timeResupplied = self.resuppliedPlayers[player:GetId()]
    
    if timeResupplied ~= nil then
        -- Make sure we haven't done this recently    
        if Shared.GetTime() < (timeResupplied + WeaponCache.kResupplyInterval) then
            return false
        end
    end
    
    return true
end

function WeaponCache:GetShouldResupplyPlayer(player)
    if not player:GetIsAlive() then
        return false
    end
    
    local stunned = HasMixin(player, "Stun") and player:GetIsStunned()
    if stunned then
        return false
    end
    
    -- Check if player needs healing or ammo - no facing check, just range
    if player:GetHealth() < player:GetMaxHealth() then
        return self:GetTimeToResupplyPlayer(player)
    end
    
    -- Check if weapons need ammo
    for i = 1, player:GetNumChildren() do
        local child = player:GetChildAtIndex(i - 1)
        if child:isa("ClipWeapon") and child:GetNeedsAmmo(false) then
            return self:GetTimeToResupplyPlayer(player)
        end
    end
    
    return false
end

function WeaponCache:ResupplyPlayer(player)
    local resuppliedPlayer = false
    local needsHealing = player:GetHealth() < player:GetMaxHealth()
    local needsAmmo = false
    
    -- Check if weapons need ammo
    for i = 1, player:GetNumChildren() do
        local child = player:GetChildAtIndex(i - 1)
        if child:isa("ClipWeapon") and child:GetNeedsAmmo(false) then
            needsAmmo = true
            break
        end
    end
    
    -- Heal player first
    if needsHealing then
        -- third param true = ignore armor
        player:AddHealth(WeaponCache.kHealAmount, false, true)
        
        -- Play heal sound effect
        self:TriggerEffects("armory_health", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})
        
        resuppliedPlayer = true
        
        -- Clear poison
        if player:isa("Marine") and player.poisoned then
            player.poisoned = false
        end
    end

    -- Give ammo to all their weapons, one clip at a time, starting from primary
    if needsAmmo then
        local weapons = player:GetHUDOrderedWeaponList()
        
        for _, weapon in ipairs(weapons) do
            if weapon:isa("ClipWeapon") then
                if weapon:GiveAmmo(WeaponCache.kRefillAmount, false) then
                    self:TriggerEffects("armory_ammo", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})
                    resuppliedPlayer = true
                    break
                end 
            end
        end
    end
        
    if resuppliedPlayer then
        -- Insert/update entry in table
        self.resuppliedPlayers[player:GetId()] = Shared.GetTime()
    end
end

function WeaponCache:ResupplyPlayers()
    local playersInRange = GetEntitiesForTeamWithinRange("Marine", self:GetTeamNumber(), self:GetOrigin(), WeaponCache.kResupplyUseRange)
    for _, player in ipairs(playersInRange) do
        if self:GetShouldResupplyPlayer(player) then
            self:ResupplyPlayer(player)
        end
    end
end

function WeaponCache:UpdateResearch()
    -- WeaponCache has no research capabilities
end
