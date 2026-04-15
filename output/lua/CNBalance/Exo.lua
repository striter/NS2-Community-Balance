Exo.kBountyThreshold = kBountyClaimMinExo
Exo.kMaxProtectionDamageReduction = 0


function Exo:OnDestroy()

    if self.flashlight ~= nil then
        Client.DestroyRenderLight(self.flashlight)
    end

    if self.thrusterLeftCinematic then

        Client.DestroyCinematic(self.thrusterLeftCinematic)
        self.thrusterLeftCinematic = nil

    end

    if self.thrusterRightCinematic then

        Client.DestroyCinematic(self.thrusterRightCinematic)
        self.thrusterRightCinematic = nil

    end

    if self.flares then

        Client.DestroyCinematic(self.flares)
        self.flares = nil

    end

    if self.armorDisplay then

        Client.DestroyGUIView(self.armorDisplay)
        self.armorDisplay = nil

    end

    if self.healthWarningSound ~= nil then
        self.healthWarningSound = nil
    end

    if self.healthCriticalSound ~= nil then
        self.healthCriticalSound = nil
    end

    if Client then
        if gHurtCinematic then

            Client.DestroyCinematic(gHurtCinematic)
            gHurtCinematic = nil

        end
    end
    
    Player.OnDestroy(self)
end

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



function Exo:GetArmorAmount(armorLevels)

    if not armorLevels then

        armorLevels = 0

        if GetHasTech(self, kTechId.Armor3, true) then
            armorLevels = 3
        elseif GetHasTech(self, kTechId.Armor2, true) then
            armorLevels = 2
        elseif GetHasTech(self, kTechId.Armor1, true) then
            armorLevels = 1
        end

    end

    local hasMP = GetHasTech(self,kTechId.MilitaryProtocol)
    return hasMP and (kExosuitMPArmor + armorLevels * kExosuitMPArmorPerUpgradeLevel  ) 
                 or (kExosuitArmor + armorLevels *kExosuitArmorPerUpgradeLevel)

end


function Exo:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint) -- dud
    local reduction = kExoDamageReduction[doer:GetClassName()]
    if reduction then
        damageTable.damage = damageTable.damage * reduction
        return
    end
end