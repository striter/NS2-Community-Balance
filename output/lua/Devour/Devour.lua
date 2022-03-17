Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/StompMixin.lua")

class 'Devour' (Ability)

Devour.kMapName = "devour"

local kAnimationGraph = PrecacheAsset("models/alien/onos/onos_view.animation_graph")

Devour.kAttackAnimationLength = 0.9 -- short cooldown
Devour.kEatCoolDown = 6.5           -- long cooldown
Devour.kInitialDamage = 50 --40
Devour.damage = 5 --33 --40 per second
Devour.energyRate = 0 --kEnergyUpdateRate * 14

local kAttackRadius = 0.8
local kAttackOriginDistance = 1.7
local kAttackRange = 1.7 --2
local kDevourUpdateRate = 0.183 --0.15
--local kMissedEnergyCost = 15

local networkVars =
{
    attackButtonPressed = "private compensated boolean",
    eatingPlayerId = "entityid",
    devouringScalar = "float (0 to 1 by .01)",
    timeDevourEnd = "private compensated time",
}

AddMixinNetworkVars(StompMixin, networkVars)

local function UpdateDevour(self)

    local onos = self:GetParent()    
    if onos and not onos:GetIsAlive() then
    
        self:ClearPlayer(true)
        return false
   
    else
        if self.eatingPlayerId ~= 0 then
            local player = Shared.GetEntity(self.eatingPlayerId)            
            if player then
                local timeNow = Shared.GetTime()
                local timeDevourRemaining = math.max(0, self.timeDevourEnd - timeNow)
                local coords = onos:GetCoords()
                player:SetCoords(coords)                
		
				if player:GetIsAlive() and player:isa("Marine") then
                    self.lastDevourTime = self.lastDevourTime or timeNow
                    local healRate = 0
                    local deltaTime = timeNow - self.lastDevourTime
                    local damage = Devour.damage * deltaTime
                    onos:AddEnergy(Devour.energyRate * deltaTime)

                    player:DeductHealth(damage, onos, self , true)

					self.devouringScalar = 1 - player:GetHealthFraction()
                    player.devouringScalar = self.devouringScalar  

                    self.lastDevourTime = timeNow
                else
                    self.devouringScalar = 0
                    self.eatingPlayerId = 0
                    self.lastDevourTime = nil
                end

            else
                self.devouringScalar = 0
                self.eatingPlayerId = 0
                self.lastDevourTime = nil
            end
        end 
    end   

    return true
    
end

local function DevourAttack(self, player, hitTarget, excludeTarget)
    local x, y = self:GetMeleeBase()
    local extents = Vector( x, y, 1)
    local trace = Shared.TraceBox(extents, player:GetEyePos(), player:GetEyePos() + player:GetViewCoords().zAxis * kAttackOriginDistance, CollisionRep.Damage, PhysicsMask.Melee, EntityFilterOneAndIsa(excludeTarget, "Babbler"))
                --Shared.TraceRay(player:GetEyePos(), player:GetEyePos() + player:GetViewCoords().zAxis * kAttackOriginDistance, CollisionRep.Damage, PhysicsMask.Melee, EntityFilterAll())
    local attackOrigin = trace.endPoint
    local didHit = false
    
    local targets = GetEntitiesWithMixinForTeamWithinRange ("Live", GetEnemyTeamNumber(player:GetTeamNumber()), attackOrigin, kAttackRadius)
    
    if hitTarget and HasMixin(hitTarget, "Live") and hitTarget:GetIsVisible() and hitTarget:GetCanTakeDamage() then
        table.insertunique(targets, hitTarget)
    end
   
    for index, target in ipairs(targets) do
        
        if target:isa("Player") and not target:isa("Exo") then
            if target:GetTeamNumber() ~= self:GetTeamNumber() then
                didHit = true
                self.eatingPlayerId = target:GetId()
                self.timeDevourEnd = Shared.GetTime() + Devour.kEatCoolDown
                if Server then
                    self:DevourPlayer(target)                  
                    self:AddTimedCallback(UpdateDevour, kDevourUpdateRate)
                end
                break
            end
        end
    
    end
    
    return didHit, attackOrigin
    
end

function Devour:OnCreate()

    Ability.OnCreate(self)
    
    self.devouringScalar = 0
    self.eatingPlayerId = 0
    self.timeDevourEnd = 0
    
	InitMixin(self, StompMixin)

    --[[if Server then
        self:AddTimedCallback(UpdateDevour, kDevourUpdateRate)
    end--]]
    
end

function Devour:OnDestroy()
    self:ClearPlayer(true)
end

local function ClearPlayerNow(player)

	if player.Replace and player:GetIsAlive() then
		local oldHealth = player:GetHealth()
		local oldArmor = player:GetArmor()
        local newvelocity = player:GetVelocity()
        local playerExtents = player:GetExtents()
        local trace = Shared.TraceCapsule(player:GetOrigin(),
            player:GetOrigin() + GetNormalizedVector(newvelocity),
            math.max(playerExtents.x, playerExtents.z), playerExtents.y,
            CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterAll())
            
		newPlayer = player:Replace(player.previousMapName, player:GetTeamNumber(), false, trace.endPoint )
		newPlayer:DevourEscape()
		newPlayer:SetHealth(oldHealth)
		newPlayer:SetArmor(oldArmor)
        newPlayer:SetVelocity(newvelocity)

        newPlayer:DisableGroundMove(0.15)
		
		local oldWeapon1 = newPlayer:GetWeaponInHUDSlot(1)
		if oldWeapon1 then
			oldWeapon1:SetAmmoPercent(player.devouredPlayerPrimaryClipPercent, player.devouredPlayerPrimaryAmmoPercent)
		end
		local oldWeapon2 = newPlayer:GetWeaponInHUDSlot(2)
		if oldWeapon2 then
			oldWeapon2:SetAmmoPercent(player.devouredPlayerSecondaryClipPercent, player.devouredPlayerSecondaryAmmoPercent)
		end
		newPlayer:TriggerEffects("combat_devour_escape", {effecthostcoords = newPlayer:GetCoords()})
		newPlayer:SetCorroded()
	end
	return false
	
end

function Devour:ClearPlayer(isOnosDying)
    local onos = self:GetParent()
    local onosDied = isOnosDying or false
    if onos and self.eatingPlayerId ~= 0 then
        local devouredplayer = Shared.GetEntity(self.eatingPlayerId)
        if devouredplayer then
            local onosHorizontalFacing = GetNormalizedVectorXZ(onos:GetViewCoords().zAxis)
            local exitVelocity = onos:GetVelocity() + onosHorizontalFacing * 6
            exitVelocity.y = 0
            
            devouredplayer:SetOrigin(onos:GetOrigin() + Vector(onosHorizontalFacing.x * 0.25, Onos.YExtents, onosHorizontalFacing.z * 0.25))
            
            local playerVelocity = onosDied and Vector(0, 0, 0) or exitVelocity
			devouredplayer:SetIsOnosDying(true)
			devouredplayer:SetDevouringOnosId(0)
            devouredplayer:SetVelocity(playerVelocity)
            devouredplayer:AddTimedCallback(ClearPlayerNow, 0.01)
        end 
    end
	self:TriggerEffects("combat_stop_effects")
    self.devouringScalar = 0
    self.eatingPlayerId = 0
    self.lastDevourTime = nil
	
end

function Devour:GetDeathIconIndex()
    return kDeathMessageIcon.Devour
end

function Devour:GetAnimationGraphName()
    return kAnimationGraph
end

function Devour:GetEnergyCost()
	return self:GetCanDevour() and kDevourEnergyCost or 200
end

function Devour:GetHUDSlot()
    return 3
end

function Devour:OnHolster(player)

    Ability.OnHolster(self, player)    
    self:OnAttackEnd()
    
end

function Devour:GetMeleeBase()
    return 1, 1.4
end

function Devour:GetDevourScalar()
    return self.devouringScalar
end

function Devour:Attack(player)

    local didHit = false
    local impactPoint = nil
    local target = nil
    
    if self.eatingPlayerId == 0 then     
        
        didHit, target, impactPoint = AttackMeleeCapsule(self, player, Devour.kInitialDamage, kAttackRange, nil, false, EntityFilterOneAndIsa(player, "Babbler")) -- AttackMeleeCapsule(self, player, 0, kAttackRange)
        local energyCost = kDevourEnergyCost --self:GetEnergyCost() --kMissedEnergyCost
        
        self.timeDevourEnd = Shared.GetTime() + Devour.kAttackAnimationLength
        
        if target and HasMixin(target, "Live") and target:GetIsAlive() then            
            didHit, impactPoint = DevourAttack(self, player, target)
            energyCost = kDevourEnergyCost --self:GetEnergyCost()
        end        
        player:DeductAbilityEnergy(energyCost)        
        
    end
    
end

function Devour:OnTag(tagName)

	PROFILE("Devour:OnTag") 						
    local player = self:GetParent()    
    
    if self.attackButtonPressed and player:GetEnergy() >= self:GetEnergyCost() then    

        self:TriggerEffects("gore_attack")  
        self:Attack(player)        

    else
        self:OnAttackEnd()
    end
    
end

function Devour:OnPrimaryAttack(player)

    if self:GetCanDevour() then
        if player:GetEnergy() >= self:GetEnergyCost() then
            self.attackButtonPressed = true
        else
            self:OnAttackEnd()
        end
    else
        self:OnAttackEnd()
        
        --[[if player then
            player:SwitchWeapon(1)
        end--]]
    end
    
end

function Devour:GetCanDevour()
    return self.eatingPlayerId == 0 and ( Shared.GetTime() >= self.timeDevourEnd )
end

function Devour:OnPrimaryAttackEnd(player)
    
    Ability.OnPrimaryAttackEnd(self, player)
    self:OnAttackEnd()
    
end

function Devour:OnAttackEnd()
    self.attackButtonPressed = false    
end

function Devour:OnUpdateAnimationInput(modelMixin)

    local activityString = "none"
    local abilityString = "boneshield"
    
    if self.timeDevourEnd > Shared.GetTime() then
        activityString = "primary"
    elseif self.attackButtonPressed then
        activityString = "primary" --"taunt"        
        abilityString = "gore"
    end
    
    modelMixin:SetAnimationInput("ability", abilityString)
    modelMixin:SetAnimationInput("activity", activityString)
    
end

function Devour:DevourPlayer(targetPlayer)

	-- Look up and remember old values
    local oldHealth = targetPlayer:GetHealth()
    local oldArmor = targetPlayer:GetArmor()
	local devouredPlayerPrimaryClipPercent 				= 100.0
	local devouredPlayerPrimaryAmmoPercent 				= 100.0
	local devouredPlayerSecondaryClipPercent			= 100.0
	local devouredPlayerSecondaryAmmoPercent			= 100.0
	local oldWeapon1 = targetPlayer:GetWeaponInHUDSlot(1)
	if oldWeapon1 then
		local oldClip, oldAmmo = oldWeapon1:GetAmmoPercent()
		devouredPlayerPrimaryClipPercent = oldClip
		devouredPlayerPrimaryAmmoPercent = oldAmmo
	end
	local oldWeapon2 = targetPlayer:GetWeaponInHUDSlot(2)
	if oldWeapon2 then
		local oldClip, oldAmmo = oldWeapon2:GetAmmoPercent()
		devouredPlayerSecondaryClipPercent = oldClip
		devouredPlayerSecondaryAmmoPercent = oldAmmo
	end
	
    local devourCoords = targetPlayer:GetCoords()
    local vHeightOffset = Vector(0, Onos.YExtents, 0)
    devourCoords.origin = devourCoords.origin + vHeightOffset
    local devouredPlayer = targetPlayer:Replace(DevouredPlayer.kMapName , targetPlayer:GetTeamNumber(), false, Vector(targetPlayer:GetOrigin()))
    devouredPlayer:SetHealth(oldHealth)
    devouredPlayer:SetArmor(oldArmor)
    devouredPlayer.previousMapName = targetPlayer:GetMapName()
	devouredPlayer.devouredPlayerPrimaryClipPercent = devouredPlayerPrimaryClipPercent
	devouredPlayer.devouredPlayerPrimaryAmmoPercent = devouredPlayerPrimaryAmmoPercent
	devouredPlayer.devouredPlayerSecondaryClipPercent = devouredPlayerSecondaryClipPercent
	devouredPlayer.devouredPlayerSecondaryAmmoPercent = devouredPlayerSecondaryAmmoPercent
	local onos = self:GetParent()
	local onosId = onos:GetId()
	devouredPlayer:SetDevouringOnosId(onosId)
	
	self.eatingPlayerId = devouredPlayer:GetId() 

	onos:TriggerEffects("combat_devour_eat", {effecthostcoords = devourCoords})
	
	-- Switch to the Gore weapon if successful.
	local owner = self:GetParent()
	if owner then
		owner:SwitchWeapon(1)
	end
    
end


Shared.LinkClassToMap("Devour", Devour.kMapName, networkVars)