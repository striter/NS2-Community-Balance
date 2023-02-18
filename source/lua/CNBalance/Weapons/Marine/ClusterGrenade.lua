
local kGrenadeCameraShakeDistance = 15
local kGrenadeMinShakeIntensity = 0.01
local kGrenadeMaxShakeIntensity = 0.12

function ClusterGrenade:Detonate(targetHit)
    ----
        if GetHasTech(self,kTechId.GrenadeTech) then
            self:CreateFragments()
        end
    -----
    local hitEntities = GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), kClusterGrenadeDamageRadius)
    table.removevalue(hitEntities, self)

    if targetHit then
        table.removevalue(hitEntities, targetHit)
        self:DoDamage(kClusterGrenadeDamage, targetHit, targetHit:GetOrigin(), GetNormalizedVector(targetHit:GetOrigin() - self:GetOrigin()), "none")
    end

    RadiusDamage(hitEntities, self:GetOrigin(), kClusterGrenadeDamageRadius, kClusterGrenadeDamage, self)

    local surface = GetSurfaceFromEntity(targetHit)

    local params = { surface = surface }
    if not targetHit then
        params[kEffectHostCoords] = Coords.GetLookIn( self:GetOrigin(), self:GetCoords().zAxis)
    end

    if GetDebugGrenadeDamage() then
        DebugWireSphere( self:GetOrigin(), kClusterGrenadeDamageRadius, 0.5, 1, 1, 0, 1 )
    end

    self:TriggerEffects("cluster_grenade_explode", params)
    CreateExplosionDecals(self)
    TriggerCameraShake(self, kGrenadeMinShakeIntensity, kGrenadeMaxShakeIntensity, kGrenadeCameraShakeDistance)

    DestroyEntity(self)

end
