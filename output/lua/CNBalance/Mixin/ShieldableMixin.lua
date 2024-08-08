function ShieldableMixin:GetMaxOverShieldAmount()

    if not kShieldClassNameScalars then
        kShieldClassNameScalars = {
            [Skulk.kMapName] = kBiteLeapVampirismScalar,
            [Gorge.kMapName] = kSpitVampirismScalar,
            [Lerk.kMapName] = kLerkBiteVampirismScalar,
            [Fade.kMapName] = kSwipeVampirismScalar,
            [Onos.kMapName] = kGoreVampirismScalar,
--------------
            [Prowler.kMapName] = kVolleyRappelVampirismScalar,
            [Vokex.kMapName] = kSwipeShadowStepVampirismScalar
---------------
        }
    end
    
    local maxRatio = kOverShieldMaxCapRatio
    local maxHealth = self:GetMaxHealth()
    local className = self:GetMapName()
    local scalar = kShieldClassNameScalars[className] * 3 or 0 -- * 3 to get scalar for 3 shells

    return maxRatio * maxHealth * scalar
end