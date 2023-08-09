Exo.kBountyThreshold = kBountyClaimMinExo
Exo.kBountyDamageReceive = true

if Server then

    local kDeploy2DSound = PrecacheAsset("sound/NS2.fev/marine/heavy/deploy_2D")
    function Exo:GetCanVampirismBeUsedOn()
        return true
    end

    function Exo:InitWeapons()

        Player.InitWeapons(self)

        local weaponHolder = self:GetWeapon(ExoWeaponHolder.kMapName)

        if not weaponHolder then
            weaponHolder = self:GiveItem(ExoWeaponHolder.kMapName, false)
        end

        if self.layout == "MinigunMinigun" then
            weaponHolder:SetWeapons(Minigun.kMapName, Minigun.kMapName)
        elseif self.layout == "RailgunRailgun" then
            weaponHolder:SetWeapons(Railgun.kMapName, Railgun.kMapName)
        --elseif self.layout == "ClawRailgun" then
        --    weaponHolder:SetWeapons(Claw.kMapName, Railgun.kMapName)
        --elseif self.layout == "ClawMinigun" then
        --    weaponHolder:SetWeapons(Claw.kMapName, Minigun.kMapName)
        else
            Log("Warning: incorrect layout set for exosuit")
            weaponHolder:SetWeapons(Minigun.kMapName, Minigun.kMapName)
        end

        weaponHolder:TriggerEffects("exo_login")
        self.inventoryWeight = weaponHolder:GetInventoryWeight(self)
        self:SetActiveWeapon(ExoWeaponHolder.kMapName)
        StartSoundEffectForPlayer(kDeploy2DSound, self)

    end

    function Exo:GetAutoWeldArmorPerSecond(nanoArmorResearched)
        return nanoArmorResearched and kExoNanoArmorPerSecond or kExoArmorPerSecond
    end
end

function Exo:GetExoVariantOverride(variant)
    if GetHasTech(self,kTechId.MilitaryProtocol) then
        return kExoVariants.chroma
    end
    return variant
end

function Exo:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint) -- dud
    local reduction = kExoDamageReduction[doer:GetClassName()]
    if reduction then
        damageTable.damage = damageTable.damage * reduction
        return
    end
end