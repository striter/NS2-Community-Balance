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

function WeaponCache:ResupplyPlayer(player)
    if player.timeLastWeaponCacheResupply and player.timeLastWeaponCacheResupply + WeaponCache.kResupplyInterval > Shared.GetTime() then
        return false
    end

    local resuppliedPlayer = false
    local needsHealing = player:GetHealthScalar() < 1
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
        if not  player:GetIgnoreHealth() and player:GetHealthFraction() < 1 then
            player:AddHealth(self.kHealAmount, false, true)
        else
            player:AddArmor(self.kWeldAmount, false, true)
        end
        
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
    
    -- Set timestamp to prevent duplicate resupply from multiple WeaponCaches
    if resuppliedPlayer then
        player.timeLastWeaponCacheResupply = Shared.GetTime()
    end
    
    return resuppliedPlayer
end

function WeaponCache:ResupplyPlayers()
    local playersInRange = GetEntitiesForTeamWithinRange("Marine", self:GetTeamNumber(), self:GetOrigin(), WeaponCache.kResupplyUseRange)
    local resupply = false
    for _, player in ipairs(playersInRange) do
        resupply = self:ResupplyPlayer(player) or resupply
    end
    
    if resupply then
        self:TriggerEffects("armory_ammo", {effecthostcoords = Coords.GetTranslation(self:GetOrigin())})
    end
end

function WeaponCache:UpdateResearch()
    -- WeaponCache has no research capabilities
end
