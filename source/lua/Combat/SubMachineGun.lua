Script.Load("lua/Weapons/Marine/ClipWeapon.lua")
Script.Load("lua/PickupableWeaponMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/Weapons/ClientWeaponEffectsMixin.lua")
Script.Load("lua/PointGiverMixin.lua")

class 'SubMachineGun' (ClipWeapon)

SubMachineGun.kMapName = "SubMachineGun"

SubMachineGun.kModelName = PrecacheAsset("models/marine/lmg/smg.model")
local kViewModelName = PrecacheAsset("models/marine/lmg/smg_view.model")
local kAnimationGraph = PrecacheAsset("models/marine/lmg/lmg_view.animation_graph")

SubMachineGun.kLaserSightWorldModelAttachPoint = "fxnode_riflemuzzle"
SubMachineGun.kLaserSightViewModelAttachPoint = "fxnode_riflemuzzle"

local kRange = 50
local kSpread = Math.Radians(6.5)

local kButtRange = 1.1

local kNumberOfVariants = 3

local kOneShotSoundName = PrecacheAsset("sound/ns2remake_combat.fev/combat/weapons/marine/lmg/lmg_fire_oneshot")
local kAttackSoundName = PrecacheAsset("sound/ns2remake_combat.fev/combat/weapons/marine/lmg/fire")
local kLocalAttackSoundName = PrecacheAsset("sound/ns2remake_combat.fev/combat/weapons/marine/lmg/fire_client")
local kEndSound = PrecacheAsset("sound/ns2remake_combat.fev/combat/weapons/marine/lmg/fire_dropoff")

local kLoopingShellCinematic = PrecacheAsset("cinematics/marine/rifle/shell_looping.cinematic")
local kLoopingShellCinematicFirstPerson = PrecacheAsset("cinematics/marine/rifle/shell_looping_1p.cinematic")
local kShellEjectAttachPoint = "fxnode_riflecasing"

local kMuzzleCinematics = {
    PrecacheAsset("cinematics/marine/rifle/muzzle_flash.cinematic"),
    PrecacheAsset("cinematics/marine/rifle/muzzle_flash2.cinematic"),
    PrecacheAsset("cinematics/marine/rifle/muzzle_flash3.cinematic"),
}

local networkVars =
{
    soundType = "integer (1 to 9)",
    shooting = "boolean"
}

AddMixinNetworkVars(LiveMixin, networkVars)
local kMuzzleEffect = PrecacheAsset("cinematics/marine/rifle/muzzle_flash.cinematic")
local kMuzzleAttachPoint = "fxnode_riflemuzzle"

local function DestroyMuzzleEffect(self)

    if self.muzzleCinematic then
        Client.DestroyCinematic(self.muzzleCinematic)            
    end
    
    self.muzzleCinematic = nil
    self.activeCinematicName = nil

end

local function DestroyShellEffect(self)

    if self.shellsCinematic then
        Client.DestroyCinematic(self.shellsCinematic)            
    end
    
    self.shellsCinematic = nil

end

local function CreateMuzzleEffect(self)

    local player = self:GetParent()

    if player then

        local cinematicName = kMuzzleCinematics[math.ceil(self.soundType / 3)]
        self.activeCinematicName = cinematicName
        self.muzzleCinematic = CreateMuzzleCinematic(self, cinematicName, cinematicName, kMuzzleAttachPoint, nil, Cinematic.Repeat_Endless)
        self.firstPersonLoaded = player:GetIsLocalPlayer() and player:GetIsFirstPerson()
    
    end

end

local function CreateShellCinematic(self)

    local parent = self:GetParent()

    if parent and Client.GetLocalPlayer() == parent then
        self.loadedFirstPersonShellEffect = true
    else
        self.loadedFirstPersonShellEffect = false
    end

    if self.loadedFirstPersonShellEffect then
        self.shellsCinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)        
        self.shellsCinematic:SetCinematic(kLoopingShellCinematicFirstPerson)
    else
        self.shellsCinematic = Client.CreateCinematic(RenderScene.Zone_Default)
        self.shellsCinematic:SetCinematic(kLoopingShellCinematic)
    end    
    
    self.shellsCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
    
    if self.loadedFirstPersonShellEffect then    
        self.shellsCinematic:SetParent(parent:GetViewModelEntity())
    else
        self.shellsCinematic:SetParent(self)
    end
    
    self.shellsCinematic:SetCoords(Coords.GetIdentity())
    
    if self.loadedFirstPersonShellEffect then  
        self.shellsCinematic:SetAttachPoint(parent:GetViewModelEntity():GetAttachPointIndex(kShellEjectAttachPoint))
    else    
        self.shellsCinematic:SetAttachPoint(self:GetAttachPointIndex(kShellEjectAttachPoint))
    end    

    self.shellsCinematic:SetIsActive(false)

end

function SubMachineGun:OnCreate()

    ClipWeapon.OnCreate(self)
    
    InitMixin(self, PickupableWeaponMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LiveMixin)
	InitMixin(self, PointGiverMixin)

    if Client then
        InitMixin(self, ClientWeaponEffectsMixin)
    elseif Server then
        self.soundVariant = Shared.GetRandomInt(1, kNumberOfVariants)
        self.soundType = self.soundVariant
    end
    
end

function SubMachineGun:OnDestroy()

    ClipWeapon.OnDestroy(self)
    
    DestroyMuzzleEffect(self)
    DestroyShellEffect(self)
    
end

local function UpdateSoundType(self, player)

    local upgradeLevel = 0
    
    if player.GetWeaponUpgradeLevel then
        upgradeLevel = math.max(0, player:GetWeaponUpgradeLevel() - 1)
    end

    self.soundType = self.soundVariant + upgradeLevel * kNumberOfVariants

end

function SubMachineGun:OnPrimaryAttack(player)

    if not self:GetIsReloading() then
    
        if Server then
            UpdateSoundType(self, player)
        end
        
        ClipWeapon.OnPrimaryAttack(self, player)
        
    end    

end

function SubMachineGun:OnHolster(player)

    DestroyMuzzleEffect(self)
    DestroyShellEffect(self)
    ClipWeapon.OnHolster(self, player)
    
end

function SubMachineGun:OnHolsterClient()

    DestroyMuzzleEffect(self)
    DestroyShellEffect(self)
    ClipWeapon.OnHolsterClient(self)
    
end

function SubMachineGun:GetAnimationGraphName()
    return kAnimationGraph
end

function SubMachineGun:GetViewModelName()
    return kViewModelName
end

function SubMachineGun:GetDeathIconIndex()

    if self:GetSecondaryAttacking() then
        return kDeathMessageIcon.RifleButt
    end
    return kDeathMessageIcon.SubMachineGun
    
end

function SubMachineGun:GetHUDSlot()
    return kPrimaryWeaponSlot
end

function SubMachineGun:GetClipSize()
    return kSubMachineGunClipSize
end

function SubMachineGun:GetMaxClips()
    return kSubMachineGunClipNum
end

function SubMachineGun:GetMaxAmmo()
    return self:GetClipSize() * self:GetMaxClips()
end

function SubMachineGun:GetSpread()
    return kSpread
end

function SubMachineGun:GetBulletDamage(target, endPoint)
    return kSubMachineGunDamage
end

function SubMachineGun:GetRange()
    return kRange
end

function SubMachineGun:GetWeight()
    return kSubMachineGunWeight
end

function SubMachineGun:GetSecondaryCanInterruptReload()
    return true
end

function SubMachineGun:PerformMeleeAttack(player)

    player:TriggerEffects("rifle_alt_attack")
    
    AttackMeleeCapsule(self, player, kMachineGunMeleeDamage, kButtRange, nil, true)
    
end

function SubMachineGun:OnTag(tagName)

    PROFILE("SubMachineGun:OnTag")

    ClipWeapon.OnTag(self, tagName)
    
    if tagName == "hit" then
    
        self.shooting = false
    
        local player = self:GetParent()
        if player then
            self:PerformMeleeAttack(player)
        end
        
    end

end

function SubMachineGun:SetGunLoopParam(viewModel, paramName, rateOfChange)

    local current = viewModel:GetPoseParam(paramName)
    local new = Clamp(current + rateOfChange, 0, 0.5)
    viewModel:SetPoseParam(paramName, new)
    
end

function SubMachineGun:UpdateViewModelPoseParameters(viewModel)

    viewModel:SetPoseParam("hide_gl", 1)
    viewModel:SetPoseParam("gl_empty", 1)
    
    local attacking = self:GetPrimaryAttacking()
    local sign = (attacking and 1) or 0
    
    self:SetGunLoopParam(viewModel, "arm_loop", sign)
    
end

function SubMachineGun:OnUpdateAnimationInput(modelMixin)

    PROFILE("SubMachineGun:OnUpdateAnimationInput")
    
    ClipWeapon.OnUpdateAnimationInput(self, modelMixin)
    
    modelMixin:SetAnimationInput("gl", false)

end

function SubMachineGun:GetAmmoPackMapName()
    return SubMachineGunAmmo.kMapName
end

function SubMachineGun:OverrideWeaponName()
    return "rifle"
end

if Client then

    function SubMachineGun:OnClientPrimaryAttackStart()

        local player = self:GetParent()
		
		StartSoundEffectAtOrigin(kOneShotSoundName, self:GetOrigin())
		if player and player:GetIsLocalPlayer() then
			Shared.PlaySound(self, kLocalAttackSoundName)
		else
			Shared.PlaySound(self, kAttackSoundName)
		end
        
        
        if not self.muzzleCinematic then            
            CreateMuzzleEffect(self)                
        elseif player then
        
            local cinematicName = kMuzzleCinematics[math.ceil(self.soundType / 3)]
            local useFirstPerson = player:GetIsLocalPlayer() and player:GetIsFirstPerson()
            
            if cinematicName ~= self.activeCinematicName or self.firstPersonLoaded ~= useFirstPerson then
            
                DestroyMuzzleEffect(self)
                CreateMuzzleEffect(self)
                
            end
            
        end
            
        if self.muzzleCinematic then
            self.muzzleCinematic:SetIsVisible(true)
        end
        
        if player then
        
            local useFirstPerson = player == Client.GetLocalPlayer()
            
            if useFirstPerson ~= self.loadedFirstPersonShellEffect then
                DestroyShellEffect(self)
            end
        
            if not self.shellsCinematic then
                CreateShellCinematic(self)
            end
        
            self.shellsCinematic:SetIsActive(true)

        end
        
    end
    
    function SubMachineGun:OnParentChanged(oldParent, newParent)
        
        ClipWeapon.OnParentChanged(self, oldParent, newParent)
        DestroyMuzzleEffect(self)
        DestroyShellEffect(self)
        
    end
    
    function SubMachineGun:OnClientPrimaryAttackEnd()

		Shared.StopSound(self, kAttackSoundName)
		local player = self:GetParent()
		if player and player:GetIsLocalPlayer() then
			Shared.StopSound(self, kLocalAttackSoundName)
		end
        Shared.PlaySound(self, kEndSound)
        
        if self.muzzleCinematic and self.muzzleCinematic ~= Entity.invalidId then
            self.muzzleCinematic:SetIsVisible(false)
        end
        
        if self.shellsCinematic and self.shellsCinematic ~= Entity.invalidId then
            self.shellsCinematic:SetIsActive(false)
        end
        
    end
    
    function SubMachineGun:UpdateAttackEffects(deltaTime)

        if self.clientSoundTypePlaying and self.clientSoundTypePlaying ~= self.soundType then

            self.clientSoundTypePlaying = self.soundType
            
        end
        
    end
    
    function SubMachineGun:GetPrimaryEffectRate()
        return 0.08
    end
    
    function SubMachineGun:GetTriggerPrimaryEffects()
        return not self:GetIsReloading() and self.shooting
    end
    
    function SubMachineGun:GetBarrelPoint()
    
        local player = self:GetParent()
        if player then
        
            local origin = player:GetEyePos()
            local viewCoords= player:GetViewCoords()
            
            return origin + viewCoords.zAxis * 1.2 + viewCoords.xAxis * -0.15 + viewCoords.yAxis * -0.22
            
        end
        
        return self:GetOrigin()
        
    end
	
    function SubMachineGun:GetUIDisplaySettings()
        return { xSize = 256, ySize = 417,  script = "lua/Combat/GUISubMachineGunDisplay.lua"}
    end
end

function SubMachineGun:ModifyDamageTaken(damageTable, attacker, doer, damageType)

    if damageType ~= kDamageType.Corrode then
        damageTable.damage = 0
    end
    
end

function SubMachineGun:OnReload(player)
	
    if self:CanReload() then
		self.reloading = true
	
		if player and player:GetHasCatPackBoost()then
			self:TriggerEffects("reload_speed1")
		else
			self:TriggerEffects("reload_speed0")
		end
    end
end

function SubMachineGun:GetCanTakeDamageOverride()
    return self:GetParent() == nil
end

if Server then

    function SubMachineGun:OnKill()
        DestroyEntity(self)
    end
    
    function SubMachineGun:GetSendDeathMessageOverride()
        return false
    end 
    
end


function SubMachineGun:GetCatalystSpeedBase()
    return 1
end

Shared.LinkClassToMap("SubMachineGun", SubMachineGun.kMapName, networkVars)