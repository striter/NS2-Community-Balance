 
local onPreApplyBulletGameplayEffects = BulletsMixin.ApplyBulletGameplayEffects
function BulletsMixin:ApplyBulletGameplayEffects(player, target, endPoint, direction, damage, surface, showTracer, weaponAccuracyGroupOverride)
    onPreApplyBulletGameplayEffects(self,player, target, endPoint, direction, damage, surface, showTracer, weaponAccuracyGroupOverride)

    local blockedByUmbra = GetBlockedByUmbra(target)
    if not blockedByUmbra and target and GetHasTech(player,kTechId.DragonBreath) then
        if HasMixin(target, "Fire") and GetAreEnemies(player,target) then
            target:SetOnFire(player,self,true)
        end
    end
end