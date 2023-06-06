Script.Load("lua/Weapons/Marine/ClipWeapon.lua")
Script.Load("lua/PickupableWeaponMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/Weapons/Marine/Pistol.lua")
Script.Load("lua/Combat/CombatWeaponVariantMixin.lua")

class 'Revolver' (ClipWeapon)

Revolver.kMapName = "revolver"

Revolver.kModelName = PrecacheAsset("models/marine/revolver/revolver_world.model")
local kViewModelName = PrecacheAsset("models/marine/revolver/revolver_view.model")
local kAnimationGraph = PrecacheAsset("models/marine/revolver/revolver_view.animation_graph")

local kRange = 200
local kSpread = Math.Radians(0.4)
local kAltSpread = ClipWeapon.kCone0Degrees

local networkVars =
{
    emptyPoseParam = "private float (0 to 1 by 0.01)",
    queuedShots = "private compensated integer (0 to 10)",
}

AddMixinNetworkVars(CombatWeaponVariant,networkVars)
AddMixinNetworkVars(PickupableWeaponMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)

function Revolver:OnCreate()

    ClipWeapon.OnCreate(self)

    InitMixin(self, CombatWeaponVariant)
    InitMixin(self, PickupableWeaponMixin)
    InitMixin(self, LiveMixin)
    
    self.emptyPoseParam = 0

end

if Client then

    function Revolver:GetBarrelPoint()

        local player = self:GetParent()
        if player then
        
            local origin = player:GetEyePos()
            local viewCoords= player:GetViewCoords()
        
            return origin + viewCoords.zAxis * 0.4 + viewCoords.xAxis * -0.1 + viewCoords.yAxis * -0.2
        end
        
        return self:GetOrigin()
        
    end
    
   
    function Revolver:OverrideStartColor()
    
        local parent = self:GetParent()
        
        if parent and parent == Client.GetLocalPlayer() and not parent:GetIsThirdPerson() then
            return Color(1, 0, 0, 0.35)
        end

        return Color(1, 0, 0, 0.7)
        
    end
    
    function Revolver:OverrideEndColor()
    
        local parent = self:GetParent()
        
        if parent and parent == Client.GetLocalPlayer() and not parent:GetIsThirdPerson() then
            return Color(1, 0, 0, 0)
        end

        return Color(1, 0, 0, 0.07)
        
    end

    
    function Revolver:GetUIDisplaySettings()
        return { xSize = 512, ySize = 512, script = "lua/Combat/GUIRevolverDisplay.lua" }
    end
    
end

function Revolver:OnMaxFireRateExceeded()
    self.queuedShots = Clamp(self.queuedShots + 1, 0, 10)
end

function Revolver:OnReload(player)

    if self:CanReload() then
		self.reloading = true
	
		--if player and player:GetHasCatPackBoost()then
		--	self:TriggerEffects("reload_speed1")
		--else
			self:TriggerEffects("reload_speed0")
		--end
    end
    self.queuedShots = 0

end


function Revolver:GetPickupOrigin()
    return self:GetCoords():TransformPoint(Vector(0.04978440701961517, 0.0, -0.037144746631383896))
end

function Revolver:GetAnimationGraphName()
    return kAnimationGraph
end

function Revolver:GetViewModelName(sex, variant)
    return kViewModelName
end

function Revolver:OverrideWeaponName()
    return "pistol"
end

function Revolver:GetHasSecondary(player)
    return false
end

function Revolver:GetDeathIconIndex()
    return kDeathMessageIcon.Revolver
end

function Revolver:GetPrimaryMinFireDelay()
    return kRevolverRateOfFire    
end

function Revolver:GetPrimaryAttackRequiresPress()
    return true
end

function Revolver:GetInaccuracyScalar(player)
    return ClipWeapon.GetInaccuracyScalar(self, player)
end


function Revolver:GetWeight()
    return kRevolverWeight
end

function Revolver:GetClipSize()
    return kRevolverClipSize
end

function Revolver:GetMaxClips()
    return kRevolverNumClips
end

function Revolver:GetMaxAmmo()
    return kRevolverNumClips * self:GetClipSize()
end

function Revolver:GetSpread()
    return kSpread
end

function Revolver:GetBulletDamage(target, endPoint)
    return kRevolverDamage
end


function Revolver:GetHUDSlot()
	return kSecondaryWeaponSlot
end

function Revolver:GetIdleAnimations(index)
    local animations = {"idle", "idle_spin", "idle_gangster"}
    return animations[index]
end


function Revolver:GetSpread()
    return kSpread
end

function Revolver:UpdateViewModelPoseParameters(viewModel)
    viewModel:SetPoseParam("empty", self.emptyPoseParam)
end

function Revolver:OnTag(tagName)


    ClipWeapon.OnTag(self, tagName)
    
    if tagName == "idle_spin_start" then
        self:TriggerEffects("pistol_idle_spin")
    elseif tagName == "idle_gangster_start" then
        self:TriggerEffects("pistol_idle_gangster")
    end
    
end

function Revolver:OnUpdateAnimationInput(modelMixin)

    ClipWeapon.OnUpdateAnimationInput(self, modelMixin)
    
end

function Revolver:FirePrimary(player)

    ClipWeapon.FirePrimary(self, player)
    self:TriggerEffects("revolver_attack")
    
end


function Revolver:ModifyDamageTaken(damageTable, attacker, doer, damageType)
    if damageType ~= kDamageType.Corrode then
        damageTable.damage = 0
    end
end

function Revolver:GetCanTakeDamageOverride()
    return self:GetParent() == nil
end

if Server then

    function Revolver:GetDestroyOnKill()
        return true
    end
    
    function Revolver:GetSendDeathMessageOverride()
        return false
    end 
    
end

function Revolver:OnDraw(player, previousWeaponMapName)

    ClipWeapon.OnDraw(self, player, previousWeaponMapName)

    self.queuedShots = 0
    
end


function Revolver:OnSecondaryAttack(player)

    --ClipWeapon.OnSecondaryAttack(self, player)

    --player.slowTimeStart = Shared.GetTime()
    --player.slowTimeEnd = Shared.GetTime() + 1
    --player.slowTimeOffset = 0
    --player.slowTimeFactor = 0.67
    --player.slowTimeRecoveryFactor = 1.33
    
end

function Revolver:OnProcessMove(input)

    ClipWeapon.OnProcessMove(self, input)
    if self.queuedShots > 0 then
    
        self.queuedShots = math.max(0, self.queuedShots - 1)
        self:OnPrimaryAttack(self:GetParent())
    
    end

    if self.clip ~= 0 then
        self.emptyPoseParam = 0
    else
        self.emptyPoseParam = Clamp(Slerp(self.emptyPoseParam, 1, input.time * 5), 0, 1)
    end

end

function Revolver:UseLandIntensity()
    return true
end


function Revolver:GetCatalystSpeedBase()
    return self.primaryAttacking and 5 or 1
end

Shared.LinkClassToMap("Revolver", Revolver.kMapName, networkVars)