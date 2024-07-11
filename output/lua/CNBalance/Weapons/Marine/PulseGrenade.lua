--
local kGrenadeCameraShakeDistance = 15
local kGrenadeMinShakeIntensity = 0.01
local kGrenadeMaxShakeIntensity = 0.14


if Server then

    function PulseGrenade:Detonate(targetHit)

        local function NoFalloff() return 0 end
        local hitEntitiesDamage = GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), kPulseGrenadeDamageRadius)
        RadiusDamage(hitEntitiesDamage,self:GetOrigin(),kPulseGrenadeDamageRadius,kPulseGrenadeDamage,self,false ,NoFalloff,false)

        local hitEntitiesEnergy = GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), kPulseGrenadeEnergyDamageRadius)
        table.removevalue(hitEntitiesEnergy, self)
        if targetHit then
            table.removevalue(hitEntitiesEnergy, targetHit)
            if targetHit.SetElectrified then
                targetHit:SetElectrified(kElectrifiedDuration)
            end
        end

        -- Handle electrify.
        for _, entity in ipairs(hitEntitiesEnergy) do

            if entity.SetElectrified then
                entity:SetElectrified(kElectrifiedDuration)
            end

        end

        local surface = GetSurfaceFromEntity(targetHit)

        local params = { surface = surface }
        if not targetHit then
            params[kEffectHostCoords] = Coords.GetLookIn( self:GetOrigin(), self:GetCoords().zAxis)
        end

        if GetDebugGrenadeDamage() then
            DebugWireSphere( self:GetOrigin(), kPulseGrenadeEnergyDamageRadius, 0.75, 0, 1, 1, 1 )
            DebugWireSphere( self:GetOrigin(), kPulseGrenadeDamageRadius, 0.75, 1, 0, 0, 1 )
        end

        self:TriggerEffects("pulse_grenade_explode", params)
        CreateExplosionDecals(self)
        TriggerCameraShake(self, kGrenadeMinShakeIntensity, kGrenadeMaxShakeIntensity, kGrenadeCameraShakeDistance)

        DestroyEntity(self)

    end

end
