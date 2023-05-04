
--Weapons
if Server then
    
    function Marine:InitWeapons()
    
        Player.InitWeapons(self)
        
        local primaryWeapon = GetHasTech(self,kTechId.LightMachineGunUpgrade) and LightMachineGun.kMapName or Rifle.kMapName
        local secondaryWeapon = Pistol.kMapName
        local meleeWeapon = Axe.kMapName
        self:GiveItem(primaryWeapon)
        self:GiveItem(secondaryWeapon)
        self:GiveItem(meleeWeapon)
        self:GiveItem(Builder.kMapName)
        
        self:SetQuickSwitchTarget(secondaryWeapon)
        self:SetActiveWeapon(primaryWeapon)
    end

    local baseOnKill = Marine.OnKill
    function Marine:OnKill(attacker, doer, point, direction)
        local primaryWeapon = self:GetWeaponInHUDSlot(kPrimaryWeaponSlot)
        if primaryWeapon then
            if primaryWeapon.kMapName == SubMachineGun.kMapName then
                self.primaryRespawn = primaryWeapon.kMapName
            end
        end

        local secondaryWeapon = self:GetWeaponInHUDSlot(kSecondaryWeaponSlot)
        if secondaryWeapon then
            if secondaryWeapon.kMapName == Revolver.kMapName then
                self.secondaryRespawn = secondaryWeapon.kMapName
            end
        end

        local meleeWeapon = self:GetWeaponInHUDSlot(kTertiaryWeaponSlot)
        if meleeWeapon then
            if meleeWeapon.kMapName == Knife.kMapName then
                self.meleeRespawn = meleeWeapon.kMapName
            end
        end
        
        baseOnKill(self,attacker,doer,point,direction)
    end
    
    local onCopyPlayerDataFrom = Marine.CopyPlayerDataFrom
    function Marine:CopyPlayerDataFrom(player)
        onCopyPlayerDataFrom(self,player)
        local playerInRR = player:GetTeamNumber() == kNeutralTeamType

        if not playerInRR and GetGamerules():GetGameStarted() then
            self.primaryRespawn = player.primaryRespawn
            self.secondaryRespawn = player.secondaryRespawn
            self.meleeRespawn = player.meleeRespawn
        end

    end
end
    

local baseOnInitialized = Marine.OnInitialized
function Marine:OnInitialized()
    baseOnInitialized(self)

    if Server then
        self.timeNextWeld = 0
        self.timeNextSustain = 0
        self.nanoArmorResearched = false
        self.lifeSustainResearched = false
        self:AddTimedCallback(function(self)
            self.nanoArmorResearched = GetHasTech(self,kTechId.ArmorRegen)
            self.lifeSustainResearched = GetHasTech(self,kTechId.LifeSustain)
            return true
        end, 1)
    end
end

function Marine:ShouldAutopickupWeapons()
	return self.autoPickup
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

    -- Auto heal/weld
    local function SharedUpdate(self)
    
        if self:GetIsInCombat() then
            return
        end

        local now = Shared.GetTime()
        if self.lifeSustainResearched and  now > self.timeNextSustain then
            self.timeNextSustain = now + kLifeSustainHealInterval
            self:AddRegeneration(kLifeSustainHealInterval * kLifeSustainHealPerSecond)
        end
        
        if self.nanoArmorResearched and now > self.timeNextWeld then 
            self.timeNextWeld = now + AutoWeldMixin.kWeldInterval
            self:OnWeld(self, AutoWeldMixin.kWeldInterval, self, kNanoArmorHealPerSecond)
        end
    end
    
    local baseOnProcessMove=Marine.OnProcessMove
    function Marine:OnProcessMove(input)
        baseOnProcessMove(self,input)
        SharedUpdate(self)
    end
    
    local baseOnUpdate = Marine.OnUpdate
    function Marine:OnUpdate(deltaTime)
        baseOnUpdate(self,deltaTime)
        SharedUpdate(self)
    end
    
    function Marine:GetCanSelfWeld()
        return true
    end
    --
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

local oldGetStatusDesc = Marine.GetPlayerStatusDesc
function Marine:GetPlayerStatusDesc()
		  
    local weapon = self:GetWeaponInHUDSlot(1)
	if (weapon) then
		if (weapon:isa("LightMachineGun")) then
			return kPlayerStatus.LightMachineGun
        elseif (weapon:isa("SubMachineGun")) then
            return kPlayerStatus.SubMachineGun
        elseif (weapon:isa("Cannon")) then
            return kPlayerStatus.Cannon
        end
	end
		
	return oldGetStatusDesc(self)
end

function Marine:OverrideInput(input)

	-- Always let the CombatBuilder override input, since it handles client-side-only build menu
	local activeWeapon = self:GetActiveWeapon()

	if activeWeapon and activeWeapon.OverrideInput then
		input = activeWeapon:OverrideInput(input)
	end
	
	return Player.OverrideInput(self, input)
        
end

if Client then
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


end
