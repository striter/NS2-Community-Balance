
Script.Load("lua/Utility.lua")
Script.Load("lua/Alien.lua")
Script.Load("lua/Mixins/BaseMoveMixin.lua")
Script.Load("lua/Mixins/GroundMoveMixin.lua")
Script.Load("lua/Mixins/CrouchMoveMixin.lua")
Script.Load("lua/Mixins/JumpMoveMixin.lua")
Script.Load("lua/CelerityMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/WallMovementMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/BabblerClingMixin.lua")
Script.Load("lua/TunnelUserMixin.lua")
Script.Load("lua/RailgunTargetMixin.lua")

Script.Load("lua/Prowler/VolleyRappel.lua")
Script.Load("lua/Prowler/AcidSpray.lua")
Script.Load("lua/Prowler/ProwlerStructureAbility.lua")
Script.Load("lua/Prowler/ReadyRoomRappel.lua")
Script.Load("lua/Weapons/PredictedProjectile.lua")
Script.Load("lua/IdleMixin.lua")

class 'Prowler' (Alien)

Prowler.kMapName = "prowler"

Prowler.kMaxSpeed = 6.6 -- skulk is 7.25
Prowler.kMaxSneakySpeed = 4.6
Prowler.kReelingSpeed = 2.5
Prowler.kMaxRappelSpeed = 12.15

Prowler.kWalkBackwardSpeedScalar = 1.0 --0.9
Prowler.kRappelVerticalForce = 40 --13.5

Prowler.kHealth = kProwlerHealth
Prowler.kArmor  = kProwlerArmor
Prowler.kAdrenalineEnergyRecuperationRate = 18

Prowler.kRappelAddAcceleration = 3
Prowler.kRappelHorizontalAcceleration = 16.0
Prowler.RappelCelerityBonusSpeed = 2
Prowler.kMaxVerticalSpeed = 11.5 --8.5

local kProwlerScale = 1.50  -- unused
local kModelYScale = 1.10   -- unused
local kProwlerVertAdjust = 0.1 --* kProwlerScale -- unused
local kProwlerForwardAdjust = -0.15   -- unused
local kProwlerAttackVertAdjust = 0.25 -- unused
local kMass = 40
local kRappelDuration = 2.99 -- unused

Prowler.kModelName = PrecacheAsset("models/alien/prowler/prowler.model")
Prowler.kAnimationGraph = PrecacheAsset("models/alien/prowler/prowler.animation_graph")
local kViewModelName = PrecacheAsset("models/alien/prowler/prowler_view.model")
local kSkulkAnimationGraph = PrecacheAsset("models/alien/skulk/skulk.animation_graph")
local kStepSound = PrecacheAsset("sound/NS2.fev/alien/skulk/footstep_right")

Prowler.kXExtents = .4 -- * kProwlerScale
Prowler.kYExtents = .4 -- * kProwlerScale
Prowler.kZExtents = .4 -- * kProwlerScale
Prowler.kViewOffsetHeight = .6 -- * kProwlerScale


Prowler.kGlideEnergyCost = 15 -- not used

Prowler.kGravity = -20
Prowler.kRappelGravity = -10.0 -- -3.3

if Server then
    Script.Load("lua/Prowler/Prowler_Server.lua", true)
elseif Client then
    Script.Load("lua/Prowler/Prowler_Client.lua", true)
end

local networkVars =
{
    --timeOfLastHowl = "private compensated time",

    --gliding = "compensated boolean",
    rappelling = "compensated boolean",
    timeRappelStart = "private compensated time",
    wallWalking = "compensated boolean",
    timeLastWallWalkCheck = "private compensated time",
    rappelPoint = "vector",
    rappelFollow = "entityid"
}

AddMixinNetworkVars(BaseMoveMixin, networkVars)
AddMixinNetworkVars(GroundMoveMixin, networkVars)
AddMixinNetworkVars(JumpMoveMixin, networkVars)
AddMixinNetworkVars(CrouchMoveMixin, networkVars)
AddMixinNetworkVars(CelerityMixin, networkVars)
AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(WallMovementMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(BabblerClingMixin, networkVars)
AddMixinNetworkVars(TunnelUserMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)


function Prowler:OnCreate()


    InitMixin(self, BaseMoveMixin, { kGravity = Player.kGravity })
    InitMixin(self, GroundMoveMixin)
    InitMixin(self, JumpMoveMixin)
    InitMixin(self, CrouchMoveMixin)
    InitMixin(self, CelerityMixin)
    InitMixin(self, CameraHolderMixin, { kFov = kProwlerFov })
    InitMixin(self, WallMovementMixin)

    Alien.OnCreate(self)

    InitMixin(self, DissolveMixin)
    InitMixin(self, BabblerClingMixin)
    InitMixin(self, TunnelUserMixin)
    InitMixin(self, PredictedProjectileShooterMixin)

    if Client then
        InitMixin(self, RailgunTargetMixin)
        --self.timeDashChanged = 0
        self.runDist = 0
        self.step = 0
    end

    --self.timeOfLastHowl = 0
    --self.variant = kDefaultSkulkVariant

    --self.gliding = false
    self.rappelling = false
    self.wallWalking = false
    self.wallWalkingNormalGoal = Vector.yAxis
    self.timeRappelStart = 0
    self.timeLastReel = 0
    self.rappelFollow = Entity.invalidId
    self.rappelPoint = nil
    self.timeLastWallWalkCheck = 0
end

function Prowler:GetPlayInstantRagdoll()
    return true
end

function Prowler:GetMapBlipType()
    return kMinimapBlipType.Prowler
end

function Prowler:OnInitialized()

    Alien.OnInitialized(self)


    self:SetModel(Prowler.kModelName, Prowler.kAnimationGraph)

    if Client then

        self.currentCameraRoll = 0
        self.goalCameraRoll = 0

        self:AddHelpWidget("GUIEvolveHelp", 2)
        self:AddHelpWidget("GUIMapHelp", 1)
        self:AddHelpWidget("GUITunnelEntranceHelp", 1)
        --self:AddHelpWidget("GUIProwlerRappelHelp", 2)

    end
    self.currentWallWalkingAngles = Angles(0.0, 0.0, 0.0)

    InitMixin(self, IdleMixin)

end

function Prowler:GetViewModelName()
    return kViewModelName
end

-- these two are for third person mod
function Prowler:GetThirdPersonOffset()
    local z = -1.8 - self:GetVelocityLength() / self:GetMaxSpeed(true) * 0.4
    return Vector(0, 0.6, z)
end

function Prowler:GetHeartOffset()
    return Vector(0, 0.6, 0)
end

function Prowler:GetFirstPersonFov()
    return kProwlerFov
end

function Prowler:GetStepLength()
    return 0.8
end

function Prowler:GetAirControl()
    return self.rappelling and 6 or 20 -- skulk is 27
end

function Prowler:GetAirAcceleration()
    return 10 --self.rappelling and 9 or 12 -- skulk is 9
end

function Prowler:GetCollisionSlowdownFraction()
    return 0.15
end
function Prowler:GetGroundTransistionTime()
    return 0.15
end

function Prowler:GetAngleSmoothRate()
    return 6
end

function Prowler:GetCollisionSlowdownFraction()
    return 0.1
end

function Prowler:GetRollSmoothRate()
    return 4
end

function Prowler:GetPitchSmoothRate()
    return 4
end

function Prowler:GetIsSmallTarget()
    return true
end

function Prowler:GetAcceleration()
    return self.rappelling and 6 or 10
end

function Prowler:GetGroundFriction()
    return self.rappelling and 3 or 8.5
end

function Prowler:GetAirFriction()
    -- prowler is "in air" when wall gripping
    return self:GetIsWallWalking() and 8 or self.rappelling and 0.3 or 0.08 -- - (GetHasCelerityUpgrade(self) and GetSpurLevel(self:GetTeamNumber()) or 0) * 0.006
end

function Prowler:GetPlayFootsteps()
    return self:GetVelocityLength() > .75 and self:GetIsOnGround() and self:GetIsAlive() and not self.movementModiferState
end

local kProwlerEngageOffset = Vector(0, 0.4, 0)
function Prowler:GetEngagementPointOverride()
    return self:GetOrigin() + kProwlerEngageOffset
end

-- we, uh, don't have variants 
function Prowler:SetVariant()
end
function Prowler:GetVariant()
end
function Prowler:GetCrouchShrinkAmount()
    return 0
end
function Prowler:GetExtentsCrouchShrinkAmount()
    return 0
end
function Prowler:GetCrouchSpeedScalar()
    return 0
end

-- Tilt the camera based on the wall the Prowler is attached to.
function Prowler:PlayerCameraCoordsAdjustment(cameraCoords)

    local viewModelTiltAngles = Angles()
    viewModelTiltAngles:BuildFromCoords(Alien.PlayerCameraCoordsAdjustment(self, cameraCoords))

    if self.currentCameraRoll then
        viewModelTiltAngles.roll = viewModelTiltAngles.roll + self.currentCameraRoll
    end

    local viewModelTiltCoords = viewModelTiltAngles:GetCoords()
    viewModelTiltCoords.origin = cameraCoords.origin

    return viewModelTiltCoords

end

function Prowler:GetMaxBackwardSpeedScalar()
    return Prowler.kWalkBackwardSpeedScalar
end

--[[function Prowler:OnProcessMove(input)

    Alien.OnProcessMove(self, input)
    
    if self:GetPlayFootsteps() and Client then
        local delta = self:GetVelocityLength() * input.time
        self.runDist = self.runDist + delta
        local stepLength = self:GetStepLength()
        
        if self.runDist > stepLength then
            self.step = self.step + 1
            self.runDist = self.runDist - stepLength
            self:TriggerFootstep()            
        end
    end

end--]]

function Prowler:OnProcessMove(input)

    Alien.OnProcessMove(self, input)

    if Client and self:GetPlayFootsteps() then
        local delta = self:GetVelocity():GetLength() * input.time
        self.runDist = self.runDist + delta
        local stepsize = self:GetStepLength()
        --local i = 0
        --while self.runDist > stepsize and i < 2 do
        if self.runDist > stepsize then
            --i = i + 1
            --Print("%f.4", self.runDist)
            self.runDist = self.runDist - stepsize
            self:TriggerFootstep()
        end
    end

end

function Prowler:GetMaxViewOffsetHeight()
    return Prowler.kViewOffsetHeight
end

local kNormalWallWalkRange = 0.35
local kNormalWallWalkFeelerSize = 0.25

function Prowler:GetCanProwl()

    local wallWalkNormal = self:GetAverageWallWalkingNormal(kNormalWallWalkRange, kNormalWallWalkFeelerSize)
    if not wallWalkNormal then return false end

    return wallWalkNormal.y < 0.5,wallWalkNormal
end

function Prowler:ModifyJump(input, velocity, jumpVelocity)
    local notRecentlyLanded = self:GetTimeGroundTouched() + self:GetGroundTransistionTime() < Shared.GetTime()
    local canJump,wallWalkNormal  =  self:GetCanProwl()
    if canJump and notRecentlyLanded then
        local viewCoords = self:GetViewCoords()
        local wishDir = viewCoords.zAxis

        local bonusParam = Vector.DotProduct(wallWalkNormal,wishDir) *.5 + .5

        local currentSpeed = velocity:GetLength()
        local speed = math.max( Prowler.kMaxRappelSpeed,currentSpeed + (2 * bonusParam))
                + (GetHasCelerityUpgrade(self) and self:GetSpurLevel() * 0.42 or 0)

        velocity.x = wishDir.x
        velocity.y = wishDir.y
        velocity.z = wishDir.z
        velocity:Scale(speed)
        --DebugLine(viewCoords.origin, viewCoords.origin + velocity, .2, 1,0,0, 1)
        --jumpVelocity:Scale(bonusParam)
    end
    self.wallWalking = false
end

function Prowler:GetIsRappelling( )
    return self.rappelling
end

local kContinuousReelDamageInterval = 0.1
local kDisableVector = Vector(0,0,0)
function Prowler:ModifyVelocity(input, velocity, deltaTime)

    if not self:GetIsRappelling() then return end

    local now = Shared.GetTime()
    -- fly toward rappel anchor point/target
    local origin = self:GetModelOrigin()
    --local speed = velocity:GetLength()
    local followEntity = Shared.GetEntity(self.rappelFollow)
    local reelable = self:GetIsWallWalking() or self:GetIsOnGround()
    local ignoreRappel = reelable and (self:GetCrouching() or self.movementModiferState)
    if ignoreRappel then
        local hitTarget = followEntity      --Reel target
        if hitTarget then
            local targetIsPlayer = hitTarget:isa("Player")
            if targetIsPlayer then
                if now > (self.timeRappelStart + kRappelReelReactionTime) then
                    local viewCoords = self:GetViewCoords()
                    local reelDirection = (viewCoords.origin - followEntity:GetModelOrigin())
                    if Math.DotProduct(-viewCoords.zAxis,reelDirection) > 0.2 then
                        reelDirection = (viewCoords.origin + viewCoords.zAxis * 1) - hitTarget:GetOrigin()
                    end
                    reelDirection:Normalize()
                    
                    ApplyPushback(hitTarget,0.5, self:GetVelocity() * .2 + (reelDirection * kRappelReelContinuousSpeed))
                else
                    ApplyPushback(hitTarget,0.1, kDisableVector)
                end
                
                if velocity:GetLength() > Prowler.kReelingSpeed then
                    velocity:Normalize()
                    velocity:Scale(Prowler.kReelingSpeed)
                end
            end

            if GetAreEnemies(self,hitTarget) then
                local energyCost = deltaTime * kRappelReelEnergyCost
                self:DeductAbilityEnergy(energyCost)
                if now > (self.timeRappelStart + kContinuousReelDamageInterval) and now > (self.timeLastReel + kContinuousReelDamageInterval) then
                    self.timeLastReel = now

                    --local endPoint = hitTarget:GetOrigin()
                    --local volleyWeapon = self:GetWeapon(VolleyRappel.kMapName)
                    --if volleyWeapon and now > (self.timeRappelStart + kRappelReelReactionTime) then
                    --    local damage = targetIsPlayer and kRappelContinuousDamage or kRappelContinuousDamageAgainstStructure
                    --    volleyWeapon:DoDamage(damage * kContinuousReelDamageInterval, hitTarget, endPoint, self:GetViewCoords().zAxis, "organic", false)
                    --end

                    if HasMixin(hitTarget, "ParasiteAble" ) then
                        hitTarget:SetParasited( self, 3 )
                    end

                    if HasMixin(hitTarget, "Webable") then
                        hitTarget:SetWebbed(3, true)
                    end

                    if (hitTarget.SetCorroded) then
                        hitTarget:SetCorroded()
                    end
                end
            end
        end

        
        return
    end

    local tetherVector = self.rappelPoint - origin
    local YDiff = self.rappelPoint.y - origin.y
    local YDirection = (YDiff > -1) and 1 or -1
    --local distance = math.max(tetherVector:GetLength(), 0.01)
    --local xzDistance = tetherVector:GetLengthXZ()
    local tetherLength = tetherVector:GetLength()

    local isJumping = bit.band(input.commands, Move.Jump) ~= 0

    local wishDir = self:GetViewCoords():TransformVector(input.move)
    wishDir.y = self:GetCrouching() and -1  -- crouch to rappel down
            or YDiff < 0 and 0      -- can't grapple much higher than the grapple point
            or isJumping and 2  -- jump to pull up
            or 1.0 --wishDir.y * 0.9

    --local verticalForce = Clamp((22.5 + 66 / distance) * YDirection, -0.5 * Prowler.kRappelVerticalForce, Prowler.kRappelVerticalForce) --Clamp(YDirection * 20/(speed + 10), -0.5 * Prowler.kRappelVerticalForce, Prowler.kRappelVerticalForce)
    --local verticalForce = Clamp(20 * wishDir.y, -Prowler.kRappelVerticalForce, Prowler.kRappelVerticalForce)

    local verticalForce = Clamp(
            (YDirection * wishDir.y) * (-Prowler.kRappelGravity + 1) * Clamp(0.2 + math.max(YDiff, 0)/math.max(tetherLength * 0.7, 0.1), -1, 1.25),
            Prowler.kGravity, Prowler.kRappelVerticalForce)

    local celerityLevel = GetHasCelerityUpgrade(self) and self:GetSpurLevel() or 0
    local maxYSpeed = Prowler.kMaxVerticalSpeed + celerityLevel * 0.8

    --verticalForce = verticalForce + 30 * Clamp(self:GetViewAngles():GetCoords().zAxis.y * 2, -1, 1) - velocity.y * 3
    velocity.y = math.min(velocity.y + verticalForce * deltaTime, maxYSpeed)


    local pullDirection = Vector(self.rappelPoint.x - origin.x, 0, self.rappelPoint.z - origin.z) --self:GetViewCoords():TransformVector(input.move)
    pullDirection.y = 0
    pullDirection:Normalize()

    -- horizontal pull
    if tetherLength > 0.5 or isJumping then
        local xzPullStrength = (Prowler.kRappelHorizontalAcceleration * (isJumping and 1.25 or 1) + celerityLevel * 1.2) --* math.min(0.7 + tetherLength * 0.075, 1) 

        local maxSpeed = Prowler.kMaxRappelSpeed + (celerityLevel * 0.333) * Prowler.RappelCelerityBonusSpeed

        xzPullStrength = self:GetCrouching() and 0 or xzPullStrength

        velocity:Add(pullDirection * xzPullStrength * deltaTime)
        if velocity:GetLengthXZ() > maxSpeed then
            local yVel = velocity.y
            velocity.y = 0
            velocity:Normalize()
            velocity:Scale(maxSpeed)
            velocity.y = yVel
        end
    end

end


function Prowler:GetMaxSpeed(possible)

    if possible then
        return Prowler.kMaxRappelSpeed
    end

    local walking = self:GetIsOnGround() or self:GetIsWallWalking() or self:GetCrouching()
    if not walking and self:GetIsRappelling() then
        return Prowler.kMaxRappelSpeed
    end

    return self.movementModiferState and Prowler.kMaxSneakySpeed or Prowler.kMaxSpeed
end

function Prowler:OnUpdateAnimationInput(modelMixin)

    PROFILE("Prowler:OnUpdateAnimationInput")

    Alien.OnUpdateAnimationInput(self, modelMixin)
end

function Prowler:GetMass()
    return kMass
end

function Prowler:GetBaseHealth()
    return Prowler.kHealth
end

function Prowler:GetBaseArmor()
    return Prowler.kArmor
end

function Prowler:GetExtraHealth(techLevel,extraPlayers,recentWins)
    return kProwlerHealthPerBioMass * techLevel
            - recentWins * 2.5
end

function Prowler:ModifyGravityForce(gravityTable)

    local ignoreRappel = self:GetIsOnGround() or self:GetIsWallWalking() or self:GetCrouching()
    if not ignoreRappel and self:GetIsRappelling() then
        gravityTable.gravity = -9.8
    end

    if self:GetIsWallWalking() or self:GetIsOnGround() then
        gravityTable.gravity = 0
    end
end

function Prowler:OnJump( modifiedVelocity )

    local material = self:GetMaterialBelowPlayer()
    self:TriggerEffects("jump", {surface = material})
    self.wallWalking = false
end

function Prowler:OnRappel(impactPoint, hitEntity)

    --self:RappelMove()
    if not self.movementModiferState and not self:GetCrouching() then
        local velocity = self:GetVelocity()
        local viewCoords = self:GetViewCoords()
        local speed = velocity:GetLength()
        local wishDir = viewCoords.zAxis
        velocity.x = wishDir.x
        velocity.y = wishDir.y
        velocity.z = wishDir.z
        local accel = Prowler.kRappelAddAcceleration
        if GetHasCelerityUpgrade(self) then
            accel = accel + (self:GetSpurLevel() * 0.3 or 0)
        end
        velocity:Scale(speed)
        self:SetVelocity(velocity)
        self.jumping = true
        self:DisableGroundMove(0.1)
        self.wallWalking = false
    end

    self.rappelling = true
    self.rappelPoint = self.rappelling and impactPoint or nil
    self.rappelFollow = hitEntity and hitEntity:GetId() or Entity.invalidId
    self.timeRappelStart = Shared.GetTime()
    self.timeLastReel = Shared.GetTime()
end

function Prowler:RappelFilter()
    return function (_entity)
        return _entity == self
                or _entity:GetId() == self.rappelFollow
                or (HasMixin(_entity, "Team") and _entity:GetTeamNumber() == self:GetTeamNumber())
    end
end

local breakRappelTolerance = 0.2
function Prowler:PostUpdateMove(input)
    if not self.rappelling then return end
    local breakRappel = false

    local followEntity = Shared.GetEntity(self.rappelFollow)
    if self.rappelFollow ~= Entity.invalidId then
        if followEntity and followEntity.GetIsAlive and followEntity:GetIsAlive() then
            self.rappelPoint = followEntity:GetModelOrigin()
            if self:GetEnergy() < kRappelEnergyCost then
                breakRappel = true
            end
        else
            breakRappel = true
        end
    end

    local origin = self:GetModelOrigin()
    local trace = Shared.TraceRay(origin, self.rappelPoint,  CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, self:RappelFilter())
    --local trace = Shared.TraceRay(origin, self.rappelPoint, CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterOneAndIsa(self, "Babbler"))
    if (self:GetOrigin() - self.rappelPoint):GetLength() > kRappelRange
            or trace.fraction ~= 1
            or (trace.endPoint - self.rappelPoint):GetLength() > 0.5
    then
        self.rappelToleranceDuration = (self.rappelToleranceDuration or 0) + input.time
        breakRappel = breakRappel or self.rappelToleranceDuration > breakRappelTolerance
    else
        self.rappelToleranceDuration = 0
    end


    if not breakRappel then return end

    self.rappelling = false
    self.rappelPoint = nil
    self.rappelFollow = Entity.invalidId
end


function Prowler:GetBabblerShieldPercentage()
    return kProwlerBabblerShieldPercent
end

function Prowler:GetAdrenalineEnergyRechargeRate()
    return Prowler.kAdrenalineEnergyRecuperationRate
end

function Prowler:GetAnimateDeathCamera()
    return false
end

function Prowler:ModifyAttackSpeed(attackSpeedTable)

    local activeWeapon = self:GetActiveWeapon()

    if activeWeapon then
        local attackSpeedMod = activeWeapon:isa("VolleyRappel") and VolleyRappel.AttackSpeedMod or activeWeapon:isa("AcidSpray") and AcidSpray.AttackSpeedMod or 1.0

        attackSpeedTable.attackSpeed = attackSpeedTable.attackSpeed * attackSpeedMod

    end

end


function Prowler:GetBaseCarapaceArmorBuff()
    return kProwlerBaseCarapaceUpgradeAmount
end

function Prowler:GetCarapaceBonusPerBiomass()
    return kProwlerCarapaceArmorPerBiomass
end


function Prowler:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint) -- dud
    local reduction = kProwlerDamageReduction[doer:GetClassName()]
    if reduction then
        damageTable.damage = damageTable.damage * reduction
        return
    end
end

--Wallwakings
function Prowler:OnWorldCollision(normal, impactForce, newVelocity)

    PROFILE("Prowler:OnWorldCollision")

    self.wallWalking = self.wallWalking and not self:GetCrouching() and not self:GetRecentlyJumped()

    local coords = self:GetViewCoords()
    self.wallWalking = self.wallWalking or self.movementModiferState or Math.DotProduct(-coords.zAxis,normal) > .6

end

function Prowler:GetMoveSpeedIs2D()
    return not self:GetIsWallWalking()
            and not self:GetIsRappelling()
end

function Prowler:GetPerformsVerticalMove()
    return self:GetIsWallWalking()
            or self:GetIsRappelling()
end
function Prowler:OverrideUpdateOnGround(onGround)
    return onGround or self:GetIsWallWalking()
end

function Prowler:GetIsWallWalking()
    return self.wallWalking
end

function Prowler:GetIsUsingBodyYaw()
    return not self:GetIsWallWalking()
end

function Prowler:PreUpdateMove(input, runningPrediction)

    PROFILE("Prowler:PreUpdateMove")

    local activeWeapon = self:GetActiveWeapon()
    if activeWeapon and not HasMixin(activeWeapon,"Rappel") then
        self.rappelling = false
        self.rappelPoint = nil
    end

    self.movementModiferState = bit.band(input.commands, Move.MovementModifier) ~= 0

    if self:GetCrouching() then
        self.wallWalking = false
    end

    if self.wallWalking then

        -- Most of the time, it returns a fraction of 0, which means
        -- trace started outside the world (and no normal is returned)
        local goal = self:GetAverageWallWalkingNormal(kNormalWallWalkRange, kNormalWallWalkFeelerSize, PhysicsMask.AllButPCsAndWebs)
        if goal ~= nil then

            self.wallWalkingNormalGoal = goal
            self.wallWalking = true

        else
            self.wallWalking = false
        end

    end


    if not self:GetIsWallWalking() then
        -- When not wall walking, the goal is always directly up (running on ground).
        self.wallWalkingNormalGoal = Vector.yAxis
    end

    self.currentWallWalkingAngles = self:GetAnglesFromWallNormal(self.wallWalkingNormalGoal or Vector.yAxis) or self.currentWallWalkingAngles

end

function Prowler:GetDesiredAngles(deltaTime)

    if self:GetIsWallWalking() then
        return self:GetAnglesFromWallNormal( self.wallWalkingNormalGoal )
    end

    local desiredAngles = Angles()
    if self.onGround then
        desiredAngles.pitch = 0
    else
        desiredAngles.pitch = self:GetIsWallWalking() and 0.99 or self:GetIsJumping() and -0.4 or 0 --self:GetIsJumping() and -0.4 or self.wallWalking and 0.99 or 0
    end
    desiredAngles.roll = self.viewRoll
    desiredAngles.yaw = self.viewYaw

    return desiredAngles

end

local baseOnKill = Prowler.OnKill
function Prowler:OnKill(attacker,doer,point, direction)
    baseOnKill(self,attacker,doer,point, direction)
    self.rappelling = false
end

if Client then

    function Prowler:GetShowGhostModel()

        local weapon = self:GetActiveWeapon()
        if weapon and weapon:isa("DropStructureAbility") then
            return weapon:GetShowGhostModel()
        end

        return self.rappelling
    end

    function Prowler:GetGhostModelOverride()

        local weapon = self:GetActiveWeapon()
        if weapon and weapon:isa("DropStructureAbility") and weapon.GetGhostModelName then
            return weapon:GetGhostModelName(self)
        end
        return self.rappelling and Bomb.kModelName or nil
    end

    function Prowler:GetGhostModelTechId()

        local weapon = self:GetActiveWeapon()
        if weapon and weapon:isa("DropStructureAbility") then
            return weapon:GetGhostModelTechId()
        end
        return self.rappelling and kTechId.Umbra or nil
    end

    function Prowler:GetGhostModelCoords()

        local weapon = self:GetActiveWeapon()
        if weapon and weapon:isa("DropStructureAbility") then
            return weapon:GetGhostModelCoords()
        end

        if self.rappelPoint ~= nil then
            return Coords.GetLookIn( self.rappelPoint,(self.rappelPoint - self:GetOrigin()):GetUnit() )
        end
        return nil
    end

    function Prowler:GetLastClickedPosition()

        local weapon = self:GetActiveWeapon()
        if weapon and weapon:isa("DropStructureAbility") then
            return weapon.lastClickedPosition
        end

        return self.rappelPoint
    end

    function Prowler:GetIsPlacementValid()

        local weapon = self:GetActiveWeapon()
        if weapon and weapon:isa("DropStructureAbility") then
            return weapon:GetIsPlacementValid()
        end

        return self.rappelPoint ~= nil
    end

    function Prowler:GetIgnoreGhostHighlight()

        local weapon = self:GetActiveWeapon()
        if weapon and weapon:isa("DropStructureAbility") and weapon.GetIgnoreGhostHighlight then
            return weapon:GetIgnoreGhostHighlight()
        end

        return self.rappelPoint ~= nil
    end


    local kWebMaterial = PrecacheAsset("models/alien/gorge/web.material")
    local baseOnInitialized = Prowler.OnInitialized
    function Prowler:OnInitialized()
        baseOnInitialized(self)

        if not self.webRenderModel then
            self.webRenderModel = DynamicMesh_Create()
            self.webRenderModel:SetMaterial(kWebMaterial)
        end
    end

    local baseOnDestroy = Prowler.OnDestroy
    function Prowler:OnDestroy()

        baseOnDestroy(self)

        if self.webRenderModel then
            DynamicMesh_Destroy(self.webRenderModel)
            self.webRenderModel = nil
        end
    end

    function Prowler:OnUpdateRender()

        local isVisible = self:GetIsRappelling()

        if isVisible then
            local coords = self:GetViewCoords()
            local width = 0.1
            if self:GetIsLocalPlayer() and self:GetIsFirstPerson() then
                coords.origin = coords.origin + Vector(0,-0.2,0)
                width = 0.01
            end

            local targetPos = self.rappelPoint
            local length = (coords.origin - targetPos):GetLength()

            coords.zAxis = GetNormalizedVector(targetPos - coords.origin)
            coords.xAxis = coords.zAxis:GetPerpendicular()
            coords.yAxis = coords.zAxis:CrossProduct(coords.xAxis)

            DynamicMesh_SetTwoSidedLine(self.webRenderModel, coords, width, length, Color(1,1,1,1),Color(1,1,1,1))
        end

        self.webRenderModel:SetIsVisible(isVisible)
    end
end


Shared.LinkClassToMap("Prowler", Prowler.kMapName, networkVars, true)