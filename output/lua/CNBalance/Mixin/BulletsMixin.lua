
local onPreApplyBulletGameplayEffects = BulletsMixin.ApplyBulletGameplayEffects
function BulletsMixin:ApplyBulletGameplayEffects(player, target, endPoint, direction, damage, surface, showTracer, weaponAccuracyGroupOverride)
    onPreApplyBulletGameplayEffects(self,player, target, endPoint, direction, damage, surface, showTracer, weaponAccuracyGroupOverride)

    local blockedByUmbra = GetBlockedByUmbra(target)
    if not blockedByUmbra and target and GetHasTech(player,kTechId.DragonBreath) then
        if HasMixin(target, "Fire") and not target.GetReceivesStructuralDamage and GetAreEnemies(player,target) then
            target:SetOnFire(player,self)
        end
    end
end