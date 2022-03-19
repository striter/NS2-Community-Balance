
-- check for umbra and play local hit effects (bullets only)
function BulletsMixin:ApplyBulletGameplayEffects(player, target, endPoint, direction, damage, surface, showTracer)
    -- Handle Stats
    if Server then

        local parent = self and self.GetParent and self:GetParent()
        if parent and self.GetTechId then

            -- Drifters, buildings and teammates don't count towards accuracy as hits or misses
            if (target and target:isa("Player") and GetAreEnemies(parent, target)) or target == nil then

                local steamId = parent:GetSteamId()
                if steamId then
                    StatsUI_AddAccuracyStat(steamId, self:GetTechId(), target ~= nil, target and target:isa("Onos"), parent:GetTeamNumber())
                end
            end
        end
    end

    local blockedByUmbra = GetBlockedByUmbra(target)
    
    if blockedByUmbra then
        surface = "umbra"
    end
       
    -- deals damage or plays surface hit effects
    self:DoDamage(damage, target, endPoint, direction, surface, false, showTracer)
    
    if not blockedByUmbra and target and GetHasTech(player,kTechId.DragonBreath) then
        if HasMixin(target, "Fire") and not target.GetReceivesStructuralDamage and GetAreEnemies(player,target) then
            target:SetOnFire(player,self)
        end
    end
end