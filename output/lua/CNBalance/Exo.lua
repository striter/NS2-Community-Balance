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
    if Client and gHurtCinematic then
        Client.DestroyCinematic(gHurtCinematic)
        gHurtCinematic = nil
    end
    Player.OnDestroy(self)
end

if Server then

    local kDeploy2DSound = PrecacheAsset("sound/NS2.fev/marine/heavy/deploy_2D")
    local kClawLayoutModels = {
        ClawMinigun = {
            model = PrecacheAsset("models/marine/exosuit/exosuit_cm.model"),
            graph = PrecacheAsset("models/marine/exosuit/exosuit_cm.animation_graph"),
        },
        ClawRailgun = {
            model = PrecacheAsset("models/marine/exosuit/exosuit_cr.model"),
            graph = PrecacheAsset("models/marine/exosuit/exosuit_cr.animation_graph"),
        },
    }

    function Exo:GetCanVampirismBeUsedOn()
        return true
    end

    local baseInitExoModel = Exo.InitExoModel
    function Exo:InitExoModel()
        local clawModel = kClawLayoutModels[self.layout]
        if clawModel then
            self:SetModel(clawModel.model, clawModel.graph)
            self.lastExoLayout = self.layout
        else
            baseInitExoModel(self)
        end
    end

    -- Lazily built: the weapon classes do not exist yet when this post hook runs.
    local kLayoutWeapons
    local function GetLayoutWeapons()
        if not kLayoutWeapons then
            kLayoutWeapons = {
                MinigunMinigun  = { Minigun.kMapName, Minigun.kMapName },
                RailgunRailgun  = { Railgun.kMapName, Railgun.kMapName },
                ClawMinigun     = { Claw.kMapName, Minigun.kMapName },
                ClawRailgun     = { Claw.kMapName, Railgun.kMapName },
            }
        end
        return kLayoutWeapons
    end

    function Exo:InitWeapons()
        Player.InitWeapons(self)
        local weaponHolder = self:GetWeapon(ExoWeaponHolder.kMapName)
        if not weaponHolder then
            weaponHolder = self:GiveItem(ExoWeaponHolder.kMapName, false)
        end
        local weapons = GetLayoutWeapons()[self.layout]
        if weapons then
            weaponHolder:SetWeapons(weapons[1], weapons[2])
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
        local amount = kExoArmorPerSecond
        if nanoArmorResearched then
            amount = amount + kExoNanoArmorPerSecond
        end
        return amount
    end

    local kLayoutMapBlipTypes = {
        ClawMinigun = kMinimapBlipType.ClawMinigunExo,
        ClawRailgun = kMinimapBlipType.ClawRailgunExo,
        RailgunRailgun = kMinimapBlipType.DualRailgunExo,
    }

    function Exo:GetMapBlipType()
        return kLayoutMapBlipTypes[self.layout] or kMinimapBlipType.Exo
    end

    local kExoLayoutFromTechId = {
        [kTechId.DualMinigunExosuit] = "MinigunMinigun",
        [kTechId.DualRailgunExosuit] = "RailgunRailgun",
        [kTechId.ClawMinigunExosuit] = "ClawMinigun",
        [kTechId.ClawRailgunExosuit] = "ClawRailgun",
    }

    -- Only a claw suit can be upgraded, and only with a second copy of the weapon it already carries.
    local kExoLayoutUpgrades = {
        ClawMinigun = "MinigunMinigun",
        ClawRailgun = "RailgunRailgun",
    }

    local function BuyExoLayoutUpgrade(self, techId)
        local targetLayout = kExoLayoutUpgrades[self.layout]
        if not targetLayout or kExoLayoutFromTechId[techId] ~= targetLayout then return false end
        local cost = GetCostForTech(techId)
        if cost > 0 and self:GetResources() < cost then return false end
        local techNode = self:GetTeam():GetTechTree():GetTechNode(techId)
        if not techNode or not techNode:GetAvailable() then return false end
        local health = self:GetHealth()
        local armor = self:GetArmor()
        local maxArmor = self:GetMaxArmor()
        local origin = self:GetOrigin()
        self:AddResources(-cost)
        Shared.PlayPrivateSound(self, Marine.kSpendResourcesSoundName, nil, 1.0, origin)
        local newExo = self:Replace(Exo.kMapName, self:GetTeamNumber(), false, origin, { layout = targetLayout }, false)
        if newExo then
            newExo:SetHealth(health)
            newExo:SetMaxArmor(maxArmor)
            newExo:SetArmor(armor)
            newExo:TriggerEffects("spawn_exo")
        end
        -- The cost is already paid above, so report a failed buy to stop
        -- Player.ProcessBuyAction from charging it a second time.
        return false
    end

    local baseExoAttemptToBuy = Exo.AttemptToBuy
    function Exo:AttemptToBuy(techIds)
        local techId = techIds[1]
        if kExoLayoutFromTechId[techId] then
            return BuyExoLayoutUpgrade(self, techId)
        end
        if baseExoAttemptToBuy then
            return baseExoAttemptToBuy(self, techIds)
        end
        return false
    end
end

function Exo:GetExoVariantOverride(variant)
    if GetHasTech(self, kTechId.MilitaryProtocol) then
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
    return GetHasTech(self, kTechId.MilitaryProtocol)
        and (kExosuitMPArmor + armorLevels * kExosuitMPArmorPerUpgradeLevel)
        or (kExosuitArmor + armorLevels * kExosuitArmorPerUpgradeLevel)
end

function Exo:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint)
    local reduction = kExoDamageReduction[doer:GetClassName()]
    if reduction then
        damageTable.damage = damageTable.damage * reduction
        return
    end
end

local function IsSlotFiring(slotWeapon)
    return slotWeapon and (slotWeapon.shooting or slotWeapon.railgunAttacking) or false
end

local function GetFiringWeaponCount(exo)

    local weaponHolder = exo:GetWeapon(ExoWeaponHolder.kMapName)
    if not (weaponHolder and weaponHolder.GetLeftSlotWeapon) then
        return 0
    end

    local count = 0
    if IsSlotFiring(weaponHolder:GetLeftSlotWeapon()) then
        count = count + 1
    end
    if IsSlotFiring(weaponHolder:GetRightSlotWeapon()) then
        count = count + 1
    end
    return count

end

local baseExoGetMaxSpeed = Exo.GetMaxSpeed
function Exo:GetMaxSpeed(possible)

    local maxSpeed = baseExoGetMaxSpeed(self, possible)
    if possible then
        return maxSpeed
    end
    return maxSpeed * (1 - GetFiringWeaponCount(self) * (kExoFiringSpeedReduction or 0))

end