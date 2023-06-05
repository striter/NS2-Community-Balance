Script.Load("lua/Weapons/Marine/ClipWeapon.lua")
Script.Load("lua/PickupableWeaponMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/Weapons/ClientWeaponEffectsMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/Combat/CombatWeaponVariantMixin.lua")

class 'LightMachineGun' (ClipWeapon)

LightMachineGun.kMapName = "LightMachineGun"

LightMachineGun.kModelName = PrecacheAsset("models/marine/lmg/lmg.model")
local kViewModelName = PrecacheAsset("models/marine/lmg/lmg_view.model")
local kAnimationGraph = PrecacheAsset("models/marine/lmg/lmg_view.animation_graph")

LightMachineGun.kLaserSightWorldModelAttachPoint = "fxnode_riflemuzzle"
LightMachineGun.kLaserSightViewModelAttachPoint = "fxnode_riflemuzzle"

local kRange = 100
local kSpread = Math.Radians(2.4)

local kButtRange = 1.1

local kNumberOfVariants = 3

local kOneShotSoundName = PrecacheAsset("sound/ns2plus.fev/weapons/marine/lmg/fire_oneshot")
local kAttackSoundName = PrecacheAsset("sound/ns2plus.fev/weapons/marine/lmg/fire")
local kLocalAttackSoundName = PrecacheAsset("sound/ns2plus.fev/weapons/marine/lmg/fire")
local kEndSound = PrecacheAsset("sound/ns2plus.fev/weapons/marine/lmg/fire_dropoff")

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

AddMixinNetworkVars(CombatWeaponVariant,networkVars)
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

function LightMachineGun:OnCreate()

    ClipWeapon.OnCreate(self)

    InitMixin(self, CombatWeaponVariant)
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

function LightMachineGun:OnDestroy()

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

function LightMachineGun:OnPrimaryAttack(player)

    if not self:GetIsReloading() then
    
        if Server then
            UpdateSoundType(self, player)
        end
        
        ClipWeapon.OnPrimaryAttack(self, player)
        
    end    

end

function LightMachineGun:OnHolster(player)

    DestroyMuzzleEffect(self)
    DestroyShellEffect(self)
    ClipWeapon.OnHolster(self, player)
    
end

function LightMachineGun:OnHolsterClient()

    DestroyMuzzleEffect(self)
    DestroyShellEffect(self)
    ClipWeapon.OnHolsterClient(self)
    
end

function LightMachineGun:GetAnimationGraphName()
    return kAnimationGraph
end

function LightMachineGun:GetViewModelName()
    return kViewModelName
end

function LightMachineGun:GetDeathIconIndex()

    if self:GetSecondaryAttacking() then
        return kDeathMessageIcon.Knife
    end
    return kDeathMessageIcon.LightMachineGun
    
end

function LightMachineGun:GetHUDSlot()
    return kPrimaryWeaponSlot
end

function LightMachineGun:GetClipSize()
    return kLightMachineGunClipSize
end

function SubMachineGun:GetMaxClips()
    return kSubMachineGunClipNum
end

function SubMachineGun:GetMaxAmmo()
    return self:GetClipSize() * self:GetMaxClips()
end

function LightMachineGun:GetSpread()
    return kSpread
end

function LightMachineGun:GetBulletDamage(target, endPoint)
    return kLightMachineGunDamage
end

function LightMachineGun:GetRange()
    return kRange
end

function LightMachineGun:GetWeight()
    return kRifleWeight
end

function LightMachineGun:GetSecondaryCanInterruptReload()
    return true
end

function LightMachineGun:PerformMeleeAttack(player)

    player:TriggerEffects("rifle_alt_attack")

    local coords = player:GetViewAngles():GetCoords()
    local didHit, target = AttackMeleeCapsule(self, player, kKnifeDamage, kKnifeRange, nil, true)

    if not (didHit and target) and coords then -- Only for webs
        MarineMeleeBoxDamage(self,player,coords,kKnifeRange,kKnifeDamage)
    end
end

function LightMachineGun:OnTag(tagName)

    PROFILE("LightMachineGun:OnTag")

    ClipWeapon.OnTag(self, tagName)
    
    if tagName == "hit" then
    
        self.shooting = false
    
        local player = self:GetParent()
        if player then
            self:PerformMeleeAttack(player)
        end
        
    end

end

function LightMachineGun:SetGunLoopParam(viewModel, paramName, rateOfChange)

    local current = viewModel:GetPoseParam(paramName)
    local new = Clamp(current + rateOfChange, 0, 0.5)
    viewModel:SetPoseParam(paramName, new)
    
end

function LightMachineGun:UpdateViewModelPoseParameters(viewModel)

    viewModel:SetPoseParam("hide_gl", 1)
    viewModel:SetPoseParam("gl_empty", 1)
    
    local attacking = self:GetPrimaryAttacking()
    local sign = (attacking and 1) or 0
    
    self:SetGunLoopParam(viewModel, "arm_loop", sign)
    
end

function LightMachineGun:OnUpdateAnimationInput(modelMixin)

    PROFILE("LightMachineGun:OnUpdateAnimationInput")
    
    ClipWeapon.OnUpdateAnimationInput(self, modelMixin)
    
    modelMixin:SetAnimationInput("gl", false)

end

function LightMachineGun:GetAmmoPackMapName()
    return LightMachineGunAmmo.kMapName
end

function LightMachineGun:OverrideWeaponName()
    return "rifle"
end

if Client then

    function LightMachineGun:OnClientPrimaryAttackStart()
    
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
    
    function LightMachineGun:OnParentChanged(oldParent, newParent)
        
        ClipWeapon.OnParentChanged(self, oldParent, newParent)
        DestroyMuzzleEffect(self)
        DestroyShellEffect(self)
        
    end
    
    function LightMachineGun:OnClientPrimaryAttackEnd()
    
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
    
    function LightMachineGun:UpdateAttackEffects(deltaTime)

        if self.clientSoundTypePlaying and self.clientSoundTypePlaying ~= self.soundType then

            self.clientSoundTypePlaying = self.soundType
            
        end
        
    end
    
    function LightMachineGun:GetPrimaryEffectRate()
        return 0.08
    end
    
    function LightMachineGun:GetTriggerPrimaryEffects()
        return not self:GetIsReloading() and self.shooting
    end
    
    function LightMachineGun:GetBarrelPoint()
    
        local player = self:GetParent()
        if player then
        
            local origin = player:GetEyePos()
            local viewCoords= player:GetViewCoords()
            
            return origin + viewCoords.zAxis * 1.5 + viewCoords.xAxis * -0.15 + viewCoords.yAxis * -0.2
            
        end
        
        return self:GetOrigin()
        
    end
	
    function LightMachineGun:GetUIDisplaySettings()
        return { xSize = 256, ySize = 417,  script = "lua/Combat/GUILightMachineGunDisplay.lua"}
    end
    
end

function LightMachineGun:ModifyDamageTaken(damageTable, attacker, doer, damageType)

    if damageType ~= kDamageType.Corrode then
        damageTable.damage = 0
    end
    
end


function LightMachineGun:OnReload(player)
	
    if self:CanReload() then
		self.reloading = true
	
		if player and player:GetHasCatPackBoost()then
			self:TriggerEffects("reload_speed1")
		else
			self:TriggerEffects("reload_speed0")
		end
    end
end

function LightMachineGun:GetCanTakeDamageOverride()
    return self:GetParent() == nil
end

if Server then

    function LightMachineGun:GetDestroyOnKill()
        return true
    end
    
    function LightMachineGun:GetSendDeathMessageOverride()
        return false
    end 
    
end

function LightMachineGun:GetCatalystSpeedBase()
    return 1
end

Shared.LinkClassToMap("LightMachineGun", LightMachineGun.kMapName, networkVars)