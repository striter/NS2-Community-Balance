Marine.kBountyThreshold = kBountyClaimMinMarine
--Marine.kBountyDamageDecrease = true
Marine.kKDRatioMaxDamageReduction = 0.33
Marine.kPickupDelay = kMedpackPickupDelay

Script.Load("lua/CNBalance/Mixin/RequestHandleMixin.lua")
Script.Load("lua/AutoWeldMixin.lua")

local networkVars =     --?
{
    flashlightOn = "boolean",

    timeOfLastDrop = "private time",
    timeOfLastPickUpWeapon = "private time",

    flashlightLastFrame = "private boolean",

    timeLastSpitHit = "private time",
    lastSpitDirection = "private vector",

    ruptured = "boolean",
    interruptAim = "private boolean",
    poisoned = "boolean",
    weaponUpgradeLevel = "integer (0 to 3)",

    unitStatusPercentage = "private integer (0 to 100)",

    strafeJumped = "private compensated boolean",

    timeLastBeacon = "private time",

    weaponBeforeUseId = "private compensated entityid"
}

AddMixinNetworkVars(OrdersMixin, networkVars)
AddMixinNetworkVars(BaseMoveMixin, networkVars)
AddMixinNetworkVars(GroundMoveMixin, networkVars)
AddMixinNetworkVars(JumpMoveMixin, networkVars)
AddMixinNetworkVars(CrouchMoveMixin, networkVars)
AddMixinNetworkVars(LadderMoveMixin, networkVars)
AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(StunMixin, networkVars)
AddMixinNetworkVars(NanoShieldMixin, networkVars)
AddMixinNetworkVars(FireMixin, networkVars)
AddMixinNetworkVars(CatPackMixin, networkVars)
AddMixinNetworkVars(SprintMixin, networkVars)
AddMixinNetworkVars(OrderSelfMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)
AddMixinNetworkVars(WebableMixin, networkVars)
AddMixinNetworkVars(CorrodeMixin, networkVars)
AddMixinNetworkVars(TunnelUserMixin, networkVars)
AddMixinNetworkVars(PhaseGateUserMixin, networkVars)
AddMixinNetworkVars(MarineVariantMixin, networkVars)
AddMixinNetworkVars(ScoringMixin, networkVars)
AddMixinNetworkVars(RegenerationMixin, networkVars)
AddMixinNetworkVars(GUINotificationMixin, networkVars)
AddMixinNetworkVars(PlayerStatusMixin, networkVars)
AddMixinNetworkVars(RequestHandleMixin,networkVars)

Shared.LinkClassToMap("Marine", Marine.kMapName, networkVars, true)

local baseOnCreate = Marine.OnCreate
function Marine:OnCreate()
    baseOnCreate(self)
    InitMixin(self,AutoWeldMixin)
    InitMixin(self,RequestHandleMixin)
end

if Server then
    -- Clear orders when Marine entity is destroyed (death or becoming commander)
    -- This prevents MoveOrder blips from persisting on minimap
    local baseOnDestroy = Marine.OnDestroy
    function Marine:OnDestroy()
        if self.ClearOrders then
            self:ClearOrders()
        end
        baseOnDestroy(self)
    end
end

--Weapons
if Server then
    local baseAttemptToBuy = Marine.AttemptToBuy
    function Marine:AttemptToBuy(techIds)
        local result = baseAttemptToBuy(self,techIds)
        if result then
            local techId = techIds[1]
            if techId == kTechId.Rifle then
                self.primaryRespawn = Rifle.kMapName
            elseif techId == kTechId.SubMachineGun then
                self.primaryRespawn = SubMachineGun.kMapName
            elseif techId == kTechId.LightMachineGunAcquire then
                self.primaryRespawn = LightMachineGun.kMapName
            end

            if techId == kTechId.Pistol then
                self.secondaryRespawn = Pistol.kMapName
            elseif techId == kTechId.Revolver then
                self.secondaryRespawn = Revolver.kMapName
            end

            if techId == kTechId.Axe then
                self.meleeRespawn = Axe.kMapName
            elseif techId == kTechId.Knife then
                self.meleeRespawn = Knife.kMapName
            end
        end
        
        return result
    end


    local function GetHostSupportsTechId(forPlayer, host, techId)

        if Shared.GetCheatsEnabled() then
            return true
        end

        local techFound = false

        if host.GetItemList then

            for _, supportedTechId in ipairs(host:GetItemList(forPlayer)) do

                if supportedTechId == techId then

                    techFound = true
                    break

                end

            end

        end

        return techFound

    end

    function GetHostStructureFor(entity, techId)

        local hostStructures = {}
        table.copy(GetEntitiesForTeamWithinRange("Armory", entity:GetTeamNumber(), entity:GetOrigin(), Armory.kResupplyUseRange), hostStructures, true)
        table.copy(GetEntitiesForTeamWithinRange("PrototypeLab", entity:GetTeamNumber(), entity:GetOrigin(), PrototypeLab.kResupplyUseRange), hostStructures, true)
        table.copy(GetEntitiesForTeamWithinRange("WeaponCache", entity:GetTeamNumber(), entity:GetOrigin(), WeaponCache.kResupplyUseRange), hostStructures, true)

        if table.icount(hostStructures) > 0 then

            for _, host in ipairs(hostStructures) do

                -- check at first if the structure is hostign the techId:
                if GetHostSupportsTechId(entity,host, techId) then
                    return host
                end

            end

        end

        return nil

    end

end

if Server then
    
    function Marine:GiveItem(itemMapName,setActive, suppressError)

        local newItem
    
        if setActive == nil then
            setActive = true
        end
        
        if itemMapName then
            
            local continue = true
            
            if itemMapName == LayMines.kMapName then
            
                local mineWeapon = self:GetWeapon(LayMines.kMapName)
                
                if mineWeapon then
                    mineWeapon:Refill(kNumMines)
                    continue = false
                    setActive = false
                end
                
            elseif itemMapName == Welder.kMapName  then
                -- since axe cannot be dropped we need to delete it before adding the welder (shared hud slot)

                local meleeWeapon = self:GetWeapon(Axe.kMapName) or self:GetWeapon(Knife.kMapName)
                if meleeWeapon then
                    self:RemoveWeapon(meleeWeapon)
                    DestroyEntity(meleeWeapon)
                    continue = true
                else
                    continue = false -- don't give a second welder
                end
                
            elseif itemMapName == Axe.kMapName or itemMapName == Knife.kMapName then

                local meleeWeapon = self:GetWeapon(Axe.kMapName) or self:GetWeapon(Knife.kMapName)
                if meleeWeapon then
                    self:RemoveWeapon(meleeWeapon)
                    DestroyEntity(meleeWeapon)
                end
                
            end            
            if continue == true then
                return Player.GiveItem(self, itemMapName, setActive, suppressError)
            end
            
        end
        
        return newItem
        
    end

    local function PickupWeapon(self, weapon, wasAutoPickup)
    
        -- some weapons completely replace other weapons (welder > axe).
        local obsoleteSlot
        local activeWeapon = self:GetActiveWeapon()
        local activeSlot = activeWeapon and activeWeapon:GetHUDSlot()
        local delayPassed = (Shared.GetTime() - self.timeOfLastPickUpWeapon > Marine.kMarineBuyAutopickupDelayTime)
    
        -- find the weapon that is about to be dropped to make room for this one
        local slot = weapon:GetHUDSlot()
        local oldWep = self:GetWeaponInHUDSlot(slot)
    
        -- Delay autopickup if we're replacing/upgrading a weapon (Autopickup Better Weapon).
        -- This way it won't immediately pick up your old weapon when you buy a lower priority one. (Having a shotgun then buying a grenade launcher, for example)
        if wasAutoPickup and oldWep and not delayPassed then
            return
        end
    
        local replacement = weapon.GetReplacementWeaponMapName and weapon:GetReplacementWeaponMapName()
        if replacement then
            
            local obseleteName1,obseleteName2 = weapon:GetObseleteWeaponNames()

            local obsoleteWep = self:GetWeapon(obseleteName1) or self:GetWeapon(obseleteName2) -- Player walked over weapon with higher priority. Handled by weapon pickupable getter func.
            if obsoleteWep then
                -- If we are "using", and the weapon we will switch back to when we're done "using"
                -- is the weapon we're replacing, make sure we also replace this reference.
                local obsoleteWepId = obsoleteWep:GetId()
                if obsoleteWepId == self.weaponBeforeUseId then
                    self.weaponBeforeUseId = weapon:GetId()
                end
                
                obsoleteSlot = obsoleteWep:GetHUDSlot()
                self:RemoveWeapon(obsoleteWep)
                DestroyEntity(obsoleteWep)
            end
        end
        
        -- perform the actual weapon pickup (also drops weapon in the slot)
        self:AddWeapon(weapon, not wasAutoPickup or slot == 1)
    
        self:TriggerEffects("marine_weapon_pickup", { effecthostcoords = self:GetCoords() })
        
        -- switch to the picked up weapon if the player deliberately (non-automatically) picked up the weapon,
        -- or if the weapon they were picking up automatically replaced a weapon they already had, and they
        -- currently have no weapons (this avoids the ghost-axe problem).
        if not wasAutoPickup or
            (replacement and (self:GetActiveWeapon() == nil or obsoleteSlot == activeSlot)) then
            self:SetHUDSlotActive(weapon:GetHUDSlot())
        end
    
        if HasMixin(weapon, "Live") then
            weapon:SetHealth(weapon:GetMaxHealth())
        end
        
        self.timeOfLastPickUpWeapon = Shared.GetTime()
        if oldWep then -- Ensure the last weapon in that slot actually existed and was dropped so you don't override a valid last weapon
            self.lastDroppedWeapon = oldWep
        end
        
    end
    
    function Marine:HandleButtons(input)
    
        PROFILE("Marine:HandleButtons")
        
        Player.HandleButtons(self, input)
        
        if self:GetCanControl() then
        
            -- Update sprinting state
            self:UpdateSprintingState(input)
            
            local flashlightPressed = bit.band(input.commands, Move.ToggleFlashlight) ~= 0
            if not self.flashlightLastFrame and flashlightPressed then
            
                self:SetFlashlightOn(not self:GetFlashlightOn())
                StartSoundEffectOnEntity(Marine.kFlashlightSoundName, self, 1, self)
                
            end
            self.flashlightLastFrame = flashlightPressed
            
            local dropPressed = bit.band(input.commands, Move.Drop) ~= 0
            local usePressed = bit.band(input.commands, Move.Use) ~= 0
    
            if Server then
                
                -- search for weapons to auto-pickup nearby.
                if self.ShouldAutopickupWeapons and self:ShouldAutopickupWeapons() then
    
                    local autopickupWeapon = self:FindNearbyAutoPickupWeapon()
                    if autopickupWeapon then
                        PickupWeapon(self, autopickupWeapon, true)
                    end
                    
                end
                
                -- search for weapons to manually pickup nearby.
                if dropPressed then
    
                    -- drop the active weapon.
                    local activeWeapon = self:GetActiveWeapon()
                    if self:Drop() then
    
                        self.lastDroppedWeapon = activeWeapon
                        self.timeOfLastPickUpWeapon = Shared.GetTime()
                    end
                end
    
                if usePressed then
    
                    local pickupWeapon = self:GetNearbyPickupableWeapon()
                    -- see if we have a weapon nearby to pickup.
                    if pickupWeapon then
                        self.timeOfLastPickUpWeapon = Shared.GetTime()
                        PickupWeapon(self, pickupWeapon, false)
                    end
                end
            end
        end
    end
----------    

    
    --AutoHeal NanoArmor
    function Marine:GetAutoHealPerSecond(lifeSustainResearched)
        return lifeSustainResearched and kLifeSustainHPS or kLifeRegenHPS
    end
    
    function Marine:GetAutoWeldArmorPerSecond(nanoArmorResearched)
        local aps = self:GetIsBMAC() and kBMACAutoWeldPerSecond or 0
        if nanoArmorResearched then
            aps = aps + kMarineNanoArmorPerSecond
        end
        return aps
    end

end


Script.Load("lua/Combat/DevouredPlayer.lua")

Marine.kDevourEscapeScreenEffectDuration = 4

local oldOnCreate = Marine.OnCreate
function Marine:OnCreate()
	oldOnCreate(self)
	self.clientTimeDevourEscaped = -20
end

function Marine:DevourEscape()
	if Server then
		Server.SendNetworkMessage(self, "DevourEscape", {  }, true)
	elseif Client then
		local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
		cinematic:SetCinematic(kTunnelUseScreenCinematic)
		cinematic:SetRepeatStyle(Cinematic.Repeat_None)
		
		self.clientTimeDevourEscaped = Shared.GetTime()
	end
end

local kWeaponToStatusDesc = {
    ["Rifle"] = kPlayerStatus.Rifle,
    ["LightMachineGun"] = kPlayerStatus.LightMachineGun,
    ["SubMachineGun"] = kPlayerStatus.SubMachineGun,
    ["HeavyMachineGun"] = kPlayerStatus.HeavyMachineGun,
    ["Flamethrower"] = kPlayerStatus.Flamethrower,
    ["Shotgun"] = kPlayerStatus.Shotgun,
    ["GrenadeLauncher"] = kPlayerStatus.GrenadeLauncher,
    ["Cannon"] = kPlayerStatus.Cannon,
    ["Pistol"] = kPlayerStatus.Pistol,
    ["Revolver"] = kPlayerStatus.Revolver,
    ["Axe"] = kPlayerStatus.Axe,
    ["Knife"] = kPlayerStatus.Knife,
    ["Welder"] = kPlayerStatus.Welder,
}

function Marine:GetPlayerStatusDesc()
    if (self:GetIsAlive() == false) then
        return kPlayerStatus.Dead
    end

    for i = 1,3 do
        local weapon = self:GetWeaponInHUDSlot(i)
        if weapon then
            local returnVal = kWeaponToStatusDesc[weapon:GetClassName()]
            if not returnVal then
                Shared.Message(weapon:GetClassName() .. " Not A Valid Status Desc")
            end
            return returnVal
        end
    end
		
	return kPlayerStatus.Void
end

function Marine:OverrideInput(input)

	-- Always let the CombatBuilder override input, since it handles client-side-only build menu
	local activeWeapon = self:GetActiveWeapon()

	if activeWeapon and activeWeapon.OverrideInput then
		input = activeWeapon:OverrideInput(input)
	end
	
	return Player.OverrideInput(self, input)
end

function Marine:GetIsBMAC()
    return self.marineType == kMarineVariantsBaseType.bigmac
end

function Marine:UpdateArmorAmount(armorLevel)

    -- note: some player may have maxArmor == 0
    local armorPercent = self.maxArmor > 0 and self.armor/self.maxArmor or 0
    local isBMAC = self:GetIsBMAC()
    local newMaxArmor = self:GetArmorAmount(armorLevel,isBMAC)
    
    self:SetIgnoreHealth(isBMAC)
    
    if newMaxArmor ~= self.maxArmor then

        self.maxArmor = newMaxArmor
        self:SetArmor(self.maxArmor * armorPercent, true)

    end

end


function Marine:GetArmorAmount(armorLevels,isBMAC)

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

    local armorAmount = isBMAC and kMarineArmorBMAC + armorLevels * kArmorPerUpgradeLevelBMAC
                                or Marine.kBaseArmor + armorLevels * Marine.kArmorPerUpgradeLevel

    if GetHasTech(self,kTechId.ArmorRegen) then
        armorAmount = armorAmount + kNanoMarineArmor
    end
    
    return armorAmount
end

if Client then

    function Marine:GetIsHighlightEnabled()
        return self:GetIsBMAC() and 0.92 or 1
    end
    
    function Marine:UpdateGhostModel()

        self.currentTechId = nil
        self.ghostStructureCoords = nil
        self.ghostStructureValid = false
        self.showGhostModel = false
        
        local weapon = self:GetActiveWeapon()
        
        if weapon then
            if weapon:isa("CombatBuilder") then
            
                self.currentTechId = weapon:GetGhostModelTechId()
                self.ghostStructureCoords = weapon:GetGhostModelCoords()
                self.ghostStructureValid = weapon:GetIsPlacementValid()
                self.showGhostModel = weapon:GetShowGhostModel()
                
            elseif weapon:isa("LayMines") then
        
                self.currentTechId = kTechId.Mine
                self.ghostStructureCoords = weapon:GetGhostModelCoords()
                self.ghostStructureValid = weapon:GetIsPlacementValid()
                self.showGhostModel = weapon:GetShowGhostModel()
        
            end	
        end

    end
end

if Server then

    local kBMAPToMPUniform =
    {
        --[kMarineVariants.green] = kMarineVariants.chroma,
        --[kMarineVariants.special] = kMarineVariants.chroma,
        --[kMarineVariants.deluxe] = kMarineVariants.chroma,
        --[kMarineVariants.assault] = kMarineVariants.chroma,
        --[kMarineVariants.eliteassault] = kMarineVariants.chroma,
        --[kMarineVariants.kodiak] = kMarineVariants.chroma,
        --[kMarineVariants.tundra] = kMarineVariants.chroma,
        --[kMarineVariants.anniv] = kMarineVariants.chroma,
        --[kMarineVariants.sandstorm] = kMarineVariants.chroma,
        --[kMarineVariants.chroma] = kMarineVariants.chroma,

        [kMarineVariants.bigmac] = kMarineVariants.chromabmac,
        [kMarineVariants.bigmac02] = kMarineVariants.chromabmac,
        [kMarineVariants.bigmac03] = kMarineVariants.chromabmac,
        [kMarineVariants.bigmac04] = kMarineVariants.chromabmac,
        [kMarineVariants.bigmac05] = kMarineVariants.chromabmac,
        [kMarineVariants.bigmac06] = kMarineVariants.chromabmac,
        [kMarineVariants.chromabmac] = kMarineVariants.chromabmac,

        [kMarineVariants.militarymac] = kMarineVariants.chromamilbmac,
        [kMarineVariants.militarymac02] = kMarineVariants.chromamilbmac,
        [kMarineVariants.militarymac03] = kMarineVariants.chromamilbmac,
        [kMarineVariants.militarymac04] = kMarineVariants.chromamilbmac,
        [kMarineVariants.militarymac05] = kMarineVariants.chromamilbmac,
        [kMarineVariants.militarymac06] = kMarineVariants.chromamilbmac,
        [kMarineVariants.chromamilbmac] = kMarineVariants.chromamilbmac,
    }
    
    function Marine:GetVariantOverride(variant)
        if GetHasTech(self,kTechId.MilitaryProtocol) then
            return kBMAPToMPUniform[variant] or kMarineVariants.chroma
        end
        return variant
    end
    
    -- Clear orders on death to prevent MoveOrder blips from persisting on minimap
    local baseOnKill = Marine.OnKill
    function Marine:OnKill(killer, doer, point, direction)
        -- Clear all orders to remove MoveOrder blips from minimap
        if self.ClearOrders then
            self:ClearOrders()
        end
        baseOnKill(self, killer, doer, point, direction)
    end
    
    function Marine:GiveHeavy()

        local activeWeapon = self:GetActiveWeapon()
        local activeWeaponMapName
        local health = self:GetHealth()
        
        if activeWeapon ~= nil then
            activeWeaponMapName = activeWeapon:GetMapName()
        end
        
        local heavyMarine = self:Replace(HeavyMarine.kMapName, self:GetTeamNumber(), true, Vector(self:GetOrigin()))
        
        heavyMarine:SetActiveWeapon(activeWeaponMapName)
        heavyMarine:SetHealth(health)
    end

    -- Infestation armor debuff: movement-based armor drain
    local kInfestationCheckInterval = 0.5
    local baseOnProcessMove= Marine.OnProcessMove
    function Marine:OnProcessMove(input)
        baseOnProcessMove(self, input)

        if not self:GetIsAlive() then
            return
        end
        
        local now = Shared.GetTime()
        if self.timeLastInfestationTick and now < self.timeLastInfestationTick + kInfestationCheckInterval then
            return
        end
        self.timeLastInfestationTick = now
        
        local deltaTime = kInfestationCheckInterval
        if self:GetGameEffectMask(kGameEffect.OnInfestation) then

            local infestationDPS = 0
            if  self:GetCrouching() or self:GetVelocity():GetLength() <= 0.1 then
                infestationDPS = 0
            else
                infestationDPS = self:GetIsSprinting() and kInfestationArmorDPSSprinting or kInfestationArmorDPSWalking
            end
            
            self:DeductArmorWithAutoWeld(deltaTime * infestationDPS,true)
        end
    end

end

function Marine:GetMass()
    return self:GetIsBMAC() and 101.2 or Player.kMass
end


function Marine:GetMaxSpeed(possible)

    if possible then
        return Marine.kRunMaxSpeed
    end

    local sprintingScalar = self:GetSprintingScalar()
    local maxSprintSpeed = Marine.kWalkMaxSpeed + ( Marine.kRunMaxSpeed - Marine.kWalkMaxSpeed ) * sprintingScalar
    local maxSpeed = ConditionalValue( self:GetIsSprinting(), maxSprintSpeed, Marine.kWalkMaxSpeed )

    -- Take into account our weapon inventory and current weapon. Assumes a vanilla marine has a scalar of around .8.
    local inventorySpeedScalar = self:GetInventorySpeedScalar() + .17
    local useModifier = 1

    local activeWeapon = self:GetActiveWeapon()
    if activeWeapon and self.isUsing and activeWeapon:GetMapName() == Builder.kMapName then
        useModifier = 0.5
    end

    if self:GetHasCatPackBoost() then
        maxSpeed = maxSpeed + kCatPackMoveAddSpeed
    end
    
    if self:GetIsBMAC() then
        maxSpeed = maxSpeed - kBMACMoveSpeedReduce
    end

    if self:GetGameEffectMask(kGameEffect.OnInfestation) then
        maxSpeed = maxSpeed * kInfestationArmorSpeedModifier
    end

    return maxSpeed * self:GetSlowSpeedModifier() * inventorySpeedScalar  * useModifier

end