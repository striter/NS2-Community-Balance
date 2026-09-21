local kUmbraModifier = debug.getupvaluex(UmbraMixin.ModifyDamageTaken, "kUmbraModifier")
kUmbraModifier["Revolver"] = kUmbraBulletModifier
kUmbraModifier["LightMachineGun"] = kUmbraBulletModifier
kUmbraModifier["SubMachineGun"] = kUmbraBulletModifier
kUmbraModifier["Cannon"] = kUmbraBulletModifier
kUmbraModifier["MarineSentry"] = kUmbraBulletModifier

function UmbraMixin:ModifyDamageTaken(damageTable, attacker, doer, damageType)

    if self:GetHasUmbra() then

        local weaponModifier = doer and kUmbraModifier[doer:GetClassName()]

        if weaponModifier then
            local lifeformModifier = kUmbraLifeformModifier[self:GetClassName()]
            damageTable.damage = damageTable.damage * math.max(lifeformModifier or 0, weaponModifier)
        end

    end

end