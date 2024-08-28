Script.Load("lua/Utility.lua")
Script.Load("lua/CNBalance/Weapons/Alien/SwipeShadowStep.lua")
Script.Load("lua/CNBalance/Weapons/Alien/ReadyRoomShadowStep.lua")
Script.Load("lua/CNBalance/Weapons/Alien/MetabolizeShadowStep.lua")
Script.Load("lua/CNBalance/Weapons/Alien/VortexShadowStep.lua")
Script.Load("lua/CNBalance/Weapons/Alien/AcidRocket.lua")
Script.Load("lua/Alien.lua")
Script.Load("lua/Mixins/BaseMoveMixin.lua")
Script.Load("lua/Mixins/GroundMoveMixin.lua")
Script.Load("lua/CelerityMixin.lua")
Script.Load("lua/Mixins/JumpMoveMixin.lua")
Script.Load("lua/Mixins/CrouchMoveMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/TunnelUserMixin.lua")
Script.Load("lua/BabblerClingMixin.lua")
Script.Load("lua/Weapons/PredictedProjectile.lua")
Script.Load("lua/IdleMixin.lua")
Script.Load("lua/FilteredCinematicMixin.lua")
Script.Load("lua/RailgunTargetMixin.lua")

class 'Vokex' (Alien)

Vokex.kMapName = "vokex"

Vokex.kModelName = PrecacheAsset("models/alien/fade/vokex.model")
local kVokexAnimationGraph = PrecacheAsset("models/alien/fade/fade.animation_graph")
local kViewModelName = PrecacheAsset("models/alien/fade/fade_albino_view.model")
local kViewAnimationGraphName = PrecacheAsset("models/alien/vokex/vokex_view.model")
Vokex.kBountyThreshold = kBountyClaimMinFade

PrecacheAsset("models/alien/fade/fade.surface_shader")

local kViewOffsetHeight = 1.7
Vokex.XZExtents = 0.4
Vokex.YExtents = 1.05
Vokex.kHealth = kVokexHealth
Vokex.kArmor = kVokexArmor
Vokex.kAdrenalineEnergyRecuperationRate = 15.0

Vokex.kShadowStepFriction = 0
Vokex.kGroundFrictionBase = 9
Vokex.kGroundFrictionPostBlink = 3
Vokex.kGroundFrictionPostBlinkDelay = 0.25


local kMetabolizeAnimationDelay = 0.65
-- ~350 pounds.
local kMass = 158
local kJumpHeight = 1.4

local kVokexScanDuration = 4

local kShadowStepSpeed = 25 --40
local kShadowStepSpeedBonusPerCelerity = 0.66
Vokex.kShadowStepDuration = 0.2
local kShadowStepCooldown = 0.4

local kMaxSpeed = 7.2

local kCelerityFrictionFactor = 0.04


local kVokexGravityMod = 1.5

if Server then
    Script.Load("lua/CNBalance/Lifeforms/Vokex_Server.lua")
elseif Client then    
    Script.Load("lua/CNBalance/Lifeforms/Vokex_Client.lua")
end

local networkVars =
{
    isScanned = "boolean",
    shadowStepping = "boolean",
    timeShadowStep = "private compensated time",
    shadowStepDirection = "private vector",
    shadowStepSpeed = "private compensated interpolated float",
    
    etherealStartTime = "private time",
    etherealEndTime = "private time",
    
    hasDoubleJumped = "private compensated boolean",
    
    -- // True when we're moving quickly "through the ether"
    ethereal = "boolean",
    
    timeMetabolize = "private compensated time",
    
    timeOfLastPhase = "time",
    hasEtherealGate = "boolean"
    
}

AddMixinNetworkVars(BaseMoveMixin, networkVars)
AddMixinNetworkVars(GroundMoveMixin, networkVars)
AddMixinNetworkVars(JumpMoveMixin, networkVars)
AddMixinNetworkVars(CrouchMoveMixin, networkVars)
AddMixinNetworkVars(CelerityMixin, networkVars)
AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(TunnelUserMixin, networkVars)
AddMixinNetworkVars(BabblerClingMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)

function Vokex:OnCreate()

    InitMixin(self, BaseMoveMixin, { kGravity = Player.kGravity * kVokexGravityMod })
    InitMixin(self, GroundMoveMixin)
    InitMixin(self, JumpMoveMixin)
    InitMixin(self, CrouchMoveMixin)
    InitMixin(self, CelerityMixin)
    InitMixin(self, CameraHolderMixin, { kFov = kFadeFov })
    
    Alien.OnCreate(self)
    
    InitMixin(self, DissolveMixin)
    InitMixin(self, TunnelUserMixin)
    InitMixin(self, BabblerClingMixin)
    
    InitMixin(self, PredictedProjectileShooterMixin)
    
    if Client then
        InitMixin(self, FilteredCinematicMixin)
    end
    
    self.shadowStepDirection = Vector()
    
    if Server then
    
        self.timeLastScan = 0
        self.timeShadowStep = 0
        self.shadowStepping = false
        
    end
    
    self.etherealStartTime = 0
    self.etherealEndTime = 0
    self.ethereal = false
    
end

function Vokex:OnInitialized()

    Alien.OnInitialized(self)
    
    self:SetModel(Vokex.kModelName, kVokexAnimationGraph)
    
    if Client then
    
        self.blinkDissolve = 0
        
        self:AddHelpWidget("GUITunnelEntranceHelp", 1)

        InitMixin(self, RailgunTargetMixin)
    end
    
    InitMixin(self, IdleMixin)
    
end

function Vokex:GetShowElectrifyEffect()
    return self.hasEtherealGate or self.electrified
end

function Vokex:GetMapBlipType()
    return kMinimapBlipType.Vokex
end

function Vokex:ModifyJump(input, velocity, jumpVelocity)
    if not self.hasDoubleJumped then
        jumpVelocity:Scale(kVokexGravityMod)
    end
end

function Vokex:OnKill()
    self:TriggerEffects("metabolize_stop") --Might not be ideal

    Player.OnKill(self)
end

function Vokex:OnDestroy()

    Alien.OnDestroy(self)
    
    if Client then
        self:DestroyTrailCinematic()
    end
    
end

function Vokex:GetControllerPhysicsGroup()

    if self.isHallucination then
        return PhysicsGroup.SmallStructuresGroup
    end

    return PhysicsGroup.BigPlayerControllersGroup  
  
end

function Vokex:GetInfestationBonus()
    return kFadeInfestationSpeedBonus
end

function Vokex:GetCarapaceSpeedReduction()
    return kFadeCarapaceSpeedReduction
end

function Vokex:MovementModifierChanged(newMovementModifierState, input)

    if newMovementModifierState and self:GetActiveWeapon() ~= nil then
        local weaponMapName = self:GetActiveWeapon():GetMapName()
        local metabweapon = self:GetWeapon(MetabolizeShadowStep.kMapName)
        if metabweapon and not metabweapon:GetHasAttackDelay() and self:GetEnergy() >= metabweapon:GetEnergyCost() then
            self:SetActiveWeapon(MetabolizeShadowStep.kMapName)
            self:PrimaryAttack()
            if weaponMapName ~= MetabolizeShadowStep.kMapName then
                self.previousweapon = weaponMapName
            end
        end
    end
end

function Vokex:OnProcessMove(input)

    Alien.OnProcessMove(self,input)
end

function Vokex:OverrideInput(input)

    Alien.OverrideInput(self, input)
    
    if self:GetIsShadowStepping() then
        input.move = self.shadowStepDirection
    end
    return input
end

function Vokex:ModifyCrouchAnimation(crouchAmount)    
    return Clamp(crouchAmount * (1 - ( (self:GetVelocityLength() - kMaxSpeed) / (kMaxSpeed * 0.5))), 0, 1)
end

function Vokex:GetHeadAttachpointName()
    return "fade_tongue2"
end

-- // Prevents reseting of celerity.
function Vokex:OnSecondaryAttack()
end

function Vokex:GetBaseArmor()
    return Vokex.kArmor
end

function Vokex:GetBaseHealth()
    return Vokex.kHealth
end

function Vokex:GetHealthPerBioMass()
    return kVokexHealthPerBioMass
end

function Vokex:GetCarapaceBonusPerBiomass()
    return kVokexCarapaceArmorPerBiomass
end

function Vokex:GetMaxViewOffsetHeight()
    return kViewOffsetHeight
end

function Vokex:GetViewModelName()
    return kViewModelName
end

function Vokex:OnJump()

    if not self:GetIsOnGround() then
        self.hasDoubleJumped = true
        self:TriggerEffects("blink_out", {effecthostcoords = Coords.GetTranslation(self:GetOrigin())})
    end
end

function Vokex:GetHasDoubleJumped()
    return self.hasDoubleJumped
end

function Vokex:GetCanStep()
    return not self:GetIsShadowStepping()
end

function Vokex:ModifyGravityForce(gravityTable)

    if self:GetIsShadowStepping() or self:GetIsOnGround() then
        gravityTable.gravity = 0
    end

end

function Vokex:GetAcceleration()
    return 11
end

function Vokex:OverrideUpdateOnGround(onGround)
    if self:GetIsShadowStepping() then
        return false
    end
    return onGround
end

function Vokex:GetGroundFriction()
    
    if self:GetIsShadowStepping() then
        return 0
    end

    local timeSinceLastEthereal = Shared.GetTime() - Vokex.kShadowStepDuration - self.timeShadowStep
    if timeSinceLastEthereal < Vokex.kGroundFrictionPostBlinkDelay then
        local frac = timeSinceLastEthereal / Vokex.kGroundFrictionPostBlinkDelay
        return Vokex.kGroundFrictionPostBlink + (Vokex.kGroundFrictionBase - Vokex.kGroundFrictionPostBlink) * frac
    end
    return Vokex.kGroundFrictionBase
end  

function Vokex:GetAirControl()
    return 40
end   

function Vokex:GetAirFriction()


    if self:GetIsShadowStepping() then
        return 0
    end

    local baseFriction = 0.17
    local timeSinceLastEthereal = Shared.GetTime() - Vokex.kShadowStepDuration - self.timeShadowStep
    if timeSinceLastEthereal < Vokex.kGroundFrictionPostBlinkDelay then
        local frac = timeSinceLastEthereal / Vokex.kGroundFrictionPostBlinkDelay
        return Vokex.kGroundFrictionPostBlink + (Vokex.kGroundFrictionBase - Vokex.kGroundFrictionPostBlink) * frac
    end
    
    return baseFriction
end

function Vokex:ModifyVelocity(input, velocity, deltaTime)

    if self:GetIsShadowStepping() then
        --velocity = self.shadowStepDirection
        velocity:Add(self.shadowStepDirection)
        velocity:Normalize()
        velocity:Scale(kShadowStepSpeed)
    else
        local viewCoords = self:GetViewCoords()
        local movementDirection = viewCoords:TransformVector( input.move)

        if movementDirection:GetLength() == 0 then
            movementDirection = viewCoords.zAxis
        end

        movementDirection.y = 0
        movementDirection:Normalize()
        movementDirection:Scale(kShadowStepSpeed)

        self.shadowStepDirection = movementDirection
    end

end

function Vokex:GetCanJump()
    return (Alien.GetCanJump(self) or not self.hasDoubleJumped) and not self:GetIsShadowStepping()
end

function Vokex:GetIsShadowStepping()
    return self.shadowStepping
end

function Vokex:GetMaxSpeed(possible)

    if possible then
        return kMaxSpeed
    end

    -- // Take into account crouching.
    return kMaxSpeed
    
end

function Vokex:GetMass()
    return kMass
end

function Vokex:GetJumpHeight()
    return kJumpHeight
end

function Vokex:GetHasShadowStepCooldown()
    return self.timeShadowStep + kShadowStepCooldown > Shared.GetTime()
end

function Vokex:GetMovementSpecialTechId()
    --if self:GetCanMetabolizeHealth() then
    --    return kTechId.MetabolizeHealth
    --else
        return kTechId.MetabolizeEnergy
    --end
end

function Vokex:GetHasMovementSpecial()
    return self:GetHasOneHive()
end

function Vokex:GetMovementSpecialEnergyCost()
    return kVokexShadowStepEnergyCost
end

function Vokex:GetCollisionSlowdownFraction()
    return 0.05
end

function Vokex:TriggerShadowStep()

    self.ethereal = true
    
    
    local weapon = self:GetActiveWeapon()
    local canShadowStep = not weapon or not weapon.GetCanShadowStep or weapon:GetCanShadowStep()
    
    if canShadowStep and not self:GetHasShadowStepCooldown() then

        --local velocity = self:GetVelocity()
        self.hasDoubleJumped = false
        self.timeShadowStep = Shared.GetTime()
        self.shadowStepping = true
        
        self:TriggerEffects("shadow_step", {effecthostcoords = Coords.GetLookIn(self:GetOrigin(), self.shadowStepDirection)})

        -- /*
        -- if Client and Client.GetLocalPlayer() == self then
        --     self:TriggerFirstPersonMiniBlinkEffect(direction)
        -- end
        -- */
        
        self:TriggerCloak()
    
    end
    
end

function Vokex:OnShadowStepEnd()
    self.ethereal = false
end

function Vokex:GetHasMetabolizeAnimationDelay()
    return self.timeMetabolize + kMetabolizeAnimationDelay > Shared.GetTime()
end

--function Vokex:GetCanMetabolizeHealth()
--    return GetHasTech(self,kTechId.MetabolizeHealth)
--end

function Vokex:OnProcessMove(input)

    Alien.OnProcessMove(self, input)
    
    if Server then
    
        if self.isScanned and self.timeLastScan + kVokexScanDuration < Shared.GetTime() then
            self.isScanned = false
        end

    end
    
    if not self:GetHasMetabolizeAnimationDelay() and self.previousweapon ~= nil then

        if self:GetActiveWeapon():GetMapName() == MetabolizeShadowStep.kMapName then
            self:SetActiveWeapon(self.previousweapon)
        end

        self.previousweapon = nil
    end
end

function Vokex:GetShadowStepAllowed()
    return not self:GetHasShadowStepCooldown()
end

function Vokex:GetStepHeight()

    if self:GetIsShadowStepping() then
        return 2
    end
    
    return Player.GetStepHeight(self)
    
end

function Vokex:OnScan()

    if Server then
    
        self.timeLastScan = Shared.GetTime()
        self.isScanned = true
        
    end
    
end

function Vokex:SetDetected(state)

    if Server then
    
        if state then
        
            self.timeLastScan = Shared.GetTime()
            self.isScanned = true
            
        else
            self.isScanned = false
        end
        
    end
    
end

function Vokex:GetIsStabbing()
    local stabWeapon = self:GetWeapon(VortexShadowStep.kMapName)
    return stabWeapon and stabWeapon:GetIsStabbing()
end

function Vokex:OnUpdateAnimationInput(modelMixin)

    if not self:GetHasMetabolizeAnimationDelay() then
        Alien.OnUpdateAnimationInput(self, modelMixin)

        if self.timeOfLastPhase + 0.5 > Shared.GetTime() then
            modelMixin:SetAnimationInput("move", "teleport")
        end
    else
        local weapon = self:GetActiveWeapon()
        if weapon ~= nil and weapon.OnUpdateAnimationInput and weapon:GetMapName() == MetabolizeShadowStep.kMapName then
            weapon:OnUpdateAnimationInput(modelMixin)
        end
    end
    return
end

function Vokex:PreUpdateMove(input, runningPrediction)
    self.shadowStepping = self.timeShadowStep + Vokex.kShadowStepDuration > Shared.GetTime()
end


function Vokex:GetEngagementPointOverride()
    return self:GetOrigin() + Vector(0, 0.8, 0)
end


function Vokex:OverrideVelocityGoal(velocityGoal)
    
    if not self:GetIsOnGround() and self:GetCrouching() then
        velocityGoal:Scale(0)
    end
    
end

function Vokex:OnGroundChanged(onGround, impactForce, normal, velocity)

    Alien.OnGroundChanged(self, onGround, impactForce, normal, velocity)

    if onGround then
        self.hasDoubleJumped = false
    end
    
end

function Vokex:GetMovementSpecialCooldown()
    local cooldown = 0
    local timeLeft = (Shared.GetTime() - self.timeMetabolize)
    
    local metabolizeWeapon = self:GetWeapon(MetabolizeShadowStep.kMapName)
    local metaDelay = metabolizeWeapon and metabolizeWeapon:GetAttackDelay() or 0
    if timeLeft < metaDelay then
        return Clamp(timeLeft / metaDelay, 0, 1)
    end
    
    return cooldown
end

function Vokex:GetAdrenalineEnergyRechargeRate()
    return Vokex.kAdrenalineEnergyRecuperationRate
end

function Vokex:GetBaseCarapaceArmorBuff()
    return kVokexBaseCarapaceUpgradeAmount
end

function Vokex:GetCarapaceBonusPerBiomass()
    return kVokexCarapaceArmorPerBiomass
end

local kDefaultAttackSpeed = 1
function Vokex:OnUpdateAnimationInput(modelMixin)

    Player.OnUpdateAnimationInput(self, modelMixin)

    local attackSpeed = self:GetIsEnzymed() and kEnzymeAttackSpeed or kDefaultAttackSpeed
    attackSpeed = attackSpeed * ( self.electrified and kElectrifiedAttackSpeed or 1 )
    if self.ModifyAttackSpeed then

        local attackSpeedTable = { attackSpeed = attackSpeed }
        self:ModifyAttackSpeed(attackSpeedTable)
        attackSpeed = attackSpeedTable.attackSpeed

    end

    modelMixin:SetAnimationInput("attack_speed", attackSpeed)

    local activeWeapon = self:GetActiveWeapon()
    if activeWeapon and activeWeapon.ModifyAttackSpeedView then
        local attackSpeedTable = { attackSpeed = attackSpeed }
        activeWeapon:ModifyAttackSpeedView(attackSpeedTable)
        attackSpeed = attackSpeedTable.attackSpeed
    end
    modelMixin:SetAnimationInput("attack_speed_view", attackSpeed)

end

Shared.LinkClassToMap("Vokex", Vokex.kMapName, networkVars, true)