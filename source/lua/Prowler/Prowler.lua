
Script.Load("lua/Utility.lua")
Script.Load("lua/Alien.lua")
Script.Load("lua/Mixins/BaseMoveMixin.lua")
Script.Load("lua/Mixins/GroundMoveMixin.lua")
Script.Load("lua/Mixins/CrouchMoveMixin.lua")
Script.Load("lua/Mixins/JumpMoveMixin.lua")
Script.Load("lua/CelerityMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
--Script.Load("lua/WallMovementMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/BabblerClingMixin.lua")
Script.Load("lua/TunnelUserMixin.lua")
--Script.Load("lua/RailgunTargetMixin.lua")

Script.Load("lua/Prowler/VolleyRappel.lua")
Script.Load("lua/Prowler/AcidSpray.lua")
Script.Load("lua/Prowler/ReadyRoomRappel.lua")
Script.Load("lua/Weapons/PredictedProjectile.lua")
Script.Load("lua/IdleMixin.lua")
--Script.Load("lua/SkulkVariantMixin.lua")

class 'Prowler' (Alien)

Prowler.kMapName = "prowler"

Prowler.kMaxSpeed = 6.6 -- skulk is 7.25
Prowler.kWalkBackwardSpeedScalar = 1.0 --0.9
Prowler.kHorizontalJumpForce = 1.4 --7.2
Prowler.kVerticalExtraJumpForce = 3.11 --2.92
Prowler.kSneakSpeedModifier = 0.606
Prowler.kMaxVerticalSpeed = 11.5 --8.5
Prowler.kRappelVerticalForce = 40 --13.5
Prowler.kSilentSneakSpeed = 6.0
Prowler.kAirAddAcceleration = 4.0
Prowler.kRappelHorizontalAcceleration = 16.0
Prowler.GlideAirSpeed = 8.0
Prowler.MaxAirSpeed = 12.15
Prowler.RappelCelerityBonusSpeed = 2
Prowler.kWalljumpForce = 8

Prowler.kHealth = kProwlerHealth
Prowler.kArmor  = kProwlerArmor
Prowler.kAdrenalineEnergyRecuperationRate = 14.5

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
Prowler.kGlideGravity = -8.0
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
    wallGripAllowed = "private compensated boolean",
    wallGripping = "private compensated boolean",
    timeLastWallWalkCheck = "private compensated time",
    rappelPoint = "private vector",
    rappelFollow = "private entityid"
}

AddMixinNetworkVars(BaseMoveMixin, networkVars)
AddMixinNetworkVars(GroundMoveMixin, networkVars)
AddMixinNetworkVars(JumpMoveMixin, networkVars)
AddMixinNetworkVars(CrouchMoveMixin, networkVars)
AddMixinNetworkVars(CelerityMixin, networkVars)
AddMixinNetworkVars(CameraHolderMixin, networkVars)
--AddMixinNetworkVars( WallMovementMixin, networkVars)
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
    --InitMixin(self, WallMovementMixin)

    Alien.OnCreate(self)

    InitMixin(self, DissolveMixin)
    InitMixin(self, BabblerClingMixin)
    InitMixin(self, TunnelUserMixin)
    InitMixin(self, PredictedProjectileShooterMixin)
    
    if Client then
        --InitMixin(self, RailgunTargetMixin)
        --self.timeDashChanged = 0
        self.runDist = 0
        self.step = 0
    end
    
    --self.timeOfLastHowl = 0
    --self.variant = kDefaultSkulkVariant
    
    --self.gliding = false
    self.rappelling = false
    self.timeRappelStart = 0
    self.wallGripAllowed = false
    self.wallGripping = false
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

function Prowler:GetCanJump()
    --local canWallJump = self.wallGripping and (self.timeOfLastJump == nil or self.timeOfLastJump + .19 < Shared.GetTime())
    --experimental simple wall jump
    local canWallJump = (self.wallGripping or Shared.GetTime() - self.timeLastWallWalkCheck < 0.09) and (self.timeOfLastJump == nil or self.timeOfLastJump + .19 < Shared.GetTime())
    return self:GetIsOnGround() or canWallJump
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
    return self.wallGripping and 8 or self.rappelling and 0.3 or 0.08 -- - (GetHasCelerityUpgrade(self) and GetSpurLevel(self:GetTeamNumber()) or 0) * 0.006
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

function Prowler:GetMaxSpeed(possible)

    if possible then
        return Prowler.GlideAirSpeed
    end
    
    local maxspeed = self:GetIsOnGround() and Prowler.kMaxSpeed or Prowler.GlideAirSpeed
    
    if self.movementModiferState then
        maxspeed = maxspeed * Prowler.kSneakSpeedModifier
    end
    
    return maxspeed
    
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

function Prowler:ModifyJump(input, velocity, jumpVelocity)
    -- add extra jump force when aiming upward
                                                          
    local wishDir

    if input.move:GetLength() > 0 then
        local notRecentlyLanded = self:GetTimeGroundTouched() + self:GetGroundTransistionTime() < Shared.GetTime()
        wishDir = self:GetViewCoords():TransformVector(input.move)
        local celerityBonus = GetHasCelerityUpgrade(self) and self:GetSpurLevel() * 0.42 or 0
        local verticalForce = Clamp(wishDir.y * 1.2, 0, 1) * (Prowler.kVerticalExtraJumpForce + celerityBonus)
        wishDir.y = 0
        --wishDir:Normalize()  -- jumping up reduces forward force to increase control
        
        -- jump with more force on the first jump and while not sneaking
        local jumpAddForce = notRecentlyLanded and not self.movementModiferState and (Prowler.kHorizontalJumpForce + celerityBonus) or 0.4
        local verticalModifier = self.rappelling and 0.5 or 1
        jumpVelocity.y = (jumpVelocity.y + verticalForce) * verticalModifier
        jumpVelocity:Add(wishDir * jumpAddForce)
        
    elseif self.wallGripping or (Shared.GetTime() - self.timeLastWallWalkCheck < 0.09) then
        local celerityBonus = GetHasCelerityUpgrade(self) and self:GetSpurLevel() * 0.44 or 0
        local jumpForce = Prowler.kWalljumpForce + celerityBonus
        jumpVelocity.y = 3.33
        jumpVelocity:Add(self:GetViewAngles():GetCoords().zAxis * jumpForce)
        jumpVelocity.y = Clamp(jumpVelocity.y, -Prowler.kMaxVerticalSpeed, Prowler.kMaxVerticalSpeed)
    end                                       
    self.wallGripping = false
    
end

function Prowler:OnJump( modifiedVelocity )

    local material = self:GetMaterialBelowPlayer()    
        
    self:TriggerEffects("jump_good", {surface = material})
    
end

function Prowler:GetIsRappelling( )
    return self.rappelling
end

function Prowler:ModifyCelerityBonus(celerityBonus)
    
    if self.movementModiferState then
        celerityBonus = celerityBonus * Prowler.kSneakSpeedModifier
    end
    
    return celerityBonus
    
end

function Prowler:ModifyGravityForce(gravityTable)
    if self:GetIsOnGround() or self.wallGripping then
        gravityTable.gravity = 0
    else
        
        gravityTable.gravity = self:GetCrouching() and Prowler.kGravity or 
                               self.rappelling and Prowler.kRappelGravity or 
                               --self.gliding and Prowler.kGlideGravity or 
                               Prowler.kGravity
    end
end

--[[function Prowler:OverrideUpdateOnGround(onGround)
    return onGround and not self.gliding
end--]]

--local oldOnAdjustModelCoords = Prowler.OnAdjustModelCoords
function Prowler:OnAdjustModelCoords(modelCoords)
    --modelCoords = oldOnAdjustModelCoords(self, modelCoords)
    --modelCoords.xAxis = modelCoords.xAxis * kProwlerScale
    --modelCoords.yAxis = modelCoords.yAxis * kModelYScale
    --modelCoords.zAxis = modelCoords.zAxis * kProwlerScale
    modelCoords.origin.y = modelCoords.origin.y + kProwlerVertAdjust
    --if self.primaryAttacking then
    --    modelCoords.origin.y = modelCoords.origin.y + kProwlerAttackVertAdjust
    --end
    return modelCoords
end

function Prowler:GetIsUsingBodyYaw()
    return not self.wallGripping
end

function Prowler:GetDesiredAngles(deltaTime)

    local desiredAngles = Angles()
    if self.onGround then
        desiredAngles.pitch = 0
    else
        desiredAngles.pitch = self.wallGripping and 0.99 or self:GetIsJumping() and -0.4 or 0 --self:GetIsJumping() and -0.4 or self.wallGripping and 0.99 or 0
    end
    desiredAngles.roll = self.viewRoll
    desiredAngles.yaw = self.viewYaw
    
    return desiredAngles

end

function Prowler:OnWorldCollision(normal)

    PROFILE("Prowler:OnWorldCollision")
    
    --self.rappelling = self.rappelling and normal.y < 0.7 --normal.y < 0.7
    
    if normal.y < 0.5 and not self:GetCrouching() then
        self.wallGripAllowed = Shared.GetTime() - self.timeOfLastJump > 0.19
        self.timeLastWallWalkCheck = Shared.GetTime()
    end
    
end

function Prowler:PreUpdateMove(input, runningPrediction)

    PROFILE("Prowler:PreUpdateMove")

    --local notRecentlyJumped = Shared.GetTime() - self.timeOfLastJump > 0.09
    --local glideDesired = bit.band(input.commands, Move.Jump) ~= 0 and self.rappelling --notRecentlyJumped and not self:GetIsOnGround()

    --self.gliding = glideDesired

    
    --[[if self.timeRappelStart + kRappelDuration < Shared.GetTime() then
        self.rappelling = false
    end--]]
    local wallChecked = (Shared.GetTime() - self.timeLastWallWalkCheck < 0.09)
    self.wallGripAllowed = wallChecked and (Shared.GetTime() - self.timeOfLastJump > 0.19)
    
    local wallGripPressed = bit.band(input.commands, Move.MovementModifier) ~= 0 -- and bit.band(input.commands, Move.Jump) == 0
    local breakWallGrip = --[[bit.band(input.commands, Move.Jump) ~= 0 or--]] input.move:GetLength() > 0 and not self.wallGripAllowed or self:GetCrouching()
    -- we always abandon wall gripping if we crouch, or try to move without holding sneak key
                              
    if breakWallGrip then
    
            --self.wallGripNormal = nil
            self.wallGripping = false
            self.wallGripAllowed = false
            
    elseif not self.wallGripping and self.wallGripAllowed and wallGripPressed then

        self:SetVelocity(Vector(0,0,0))
        self.wallGripping = true
        self.jumping = false
        --self.rappelling = false
    end
        
end

local kRappelFollowDistance = 1.5

function Prowler:ModifyVelocity(input, velocity, deltaTime)

    if self.rappelling and self.rappelPoint ~= nil and not self.wallGripping then
        -- fly toward rappel anchor point/target
        local origin = self:GetModelOrigin()
        --local speed = velocity:GetLength()
        local followEntity = Shared.GetEntity(self.rappelFollow)
        local isTether = false
        
        if followEntity and followEntity ~= Entity.invalidId and followEntity.GetModelOrigin then

            local followOrigin = followEntity:GetModelOrigin() or nil
            
            self.rappelPoint = followOrigin
            isTether = true
        else
            self.rappelFollow = Entity.invalidId
        end
        
        -- rappel movement
       
        local tetherVector = self.rappelPoint - origin
        local YDiff = self.rappelPoint.y - origin.y
        local YDirection = (YDiff > -1) and 1 or -1
        --local distance = math.max(tetherVector:GetLength(), 0.01)
        --local xzDistance = tetherVector:GetLengthXZ()
        local tetherLength = tetherVector:GetLength()
        local followDistance = isTether and kRappelFollowDistance or 0.5
                                                                     
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
        
        local maxSpeedTable = { maxSpeed = Prowler.MaxAirSpeed }
        self:ModifyMaxSpeed(maxSpeedTable, input)
        
        local pullDirection = Vector(self.rappelPoint.x - origin.x, 0, self.rappelPoint.z - origin.z) --self:GetViewCoords():TransformVector(input.move)
        pullDirection.y = 0
        pullDirection:Normalize()
                
        -- horizontal pull
        if tetherLength > followDistance or isJumping then
            local xzPullStrength = (Prowler.kRappelHorizontalAcceleration * (isJumping and 1.25 or 1) + celerityLevel * 1.2) --* math.min(0.7 + tetherLength * 0.075, 1) 
            
            local maxSpeed = Prowler.MaxAirSpeed + (celerityLevel * 0.333) * Prowler.RappelCelerityBonusSpeed
            
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
    
end

function Prowler:OnUpdateAnimationInput(modelMixin)

    PROFILE("Prowler:OnUpdateAnimationInput")
    
    Alien.OnUpdateAnimationInput(self, modelMixin)
end

function Prowler:GetPlayFootsteps()
    return self:GetVelocityLength() > Prowler.kSilentSneakSpeed and self:GetIsOnGround() and self:GetIsAlive()
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

function Prowler:GetHealthPerBioMass()
    return kProwlerHealthPerBioMass
end


function Prowler:SpawnCloud(techId)

    local position = self:GetOrigin() + self:GetViewCoords().zAxis * 5
    
    local mapName = LookupTechData(techId, kTechDataMapName)
    if mapName and Server then
    
        local cloudEntity = CreateEntity(mapName, position, self:GetTeamNumber())
        
    end

end

--[[function Prowler:RappelMove()

    self.rappelDirection = self:GetViewCoords().zAxis
    self.rappelPoint = impactPoint
    
    local velocity = self:GetVelocity()
    local forwardVec = self.rappelDirection
    local verticalVector = math.min(forwardVec.y + 0.2, 1)
    forwardVec.y = 0
    local newVelocity = velocity * 0.3 + forwardVec * 10.3
    
    -- Add in vertical component.
    newVelocity.y = math.min(Prowler.kMaxVerticalSpeed, math.max(-Prowler.kMaxVerticalSpeed, velocity.y * 0.5) + Prowler.kRappelVerticalForce * verticalVector)
    
    self:SetVelocity(newVelocity)
    
    self.jumping = true
    self.rappelling = newVelocity.y >= 0 --true  -- rappel downward uses normal physics
    self:DisableGroundMove(0.2)
    self.timeRappelStart = Shared.GetTime()
    self.wallGripping = false
    self.wallGripAllowed = false
    
    return false
end--]]

function Prowler:OnRappel(impactPoint, hitEntity)

    --self:RappelMove()
    
    self.rappelDirection = self:GetViewCoords().zAxis
    
    local velocity = self:GetVelocity()
    local forwardVec = self.rappelDirection
    local verticalVector = math.min(forwardVec.y + 0.2, 1)  -- always aim slightly higher upward
    forwardVec.y = 0
    local celerityBonus = GetHasCelerityUpgrade(self) and self:GetSpurLevel() * 0.5 or 0
    local newVelocity = velocity * 0.66 + forwardVec * (4 + celerityBonus)  --velocity * 0.2 + forwardVec * 11.5 --10.3
    
    -- Add in vertical component.
    newVelocity.y = math.min(Prowler.kMaxVerticalSpeed, math.max(Prowler.kGravity, velocity.y * 0.5 + (6.8 + celerityBonus) * verticalVector))
    
    self:SetVelocity(newVelocity)
    
    self.jumping = true
    self.rappelling = true
    self.rappelPoint = self.rappelling and impactPoint or nil
    self.rappelFollow = hitEntity and hitEntity:GetId() or Entity.invalidId
    self:DisableGroundMove(0.15)
    self.timeRappelStart = Shared.GetTime()
    self.wallGripping = false
    self.wallGripAllowed = false
    
    --[[if Server then
        self.rappelDirection = self:GetViewCoords().zAxis
        self:AddTimedCallback(self.RappelMove, 0.2)
    end--]]
    
end

--[[function Prowler:OnHowl()

    local shotWeb = false
    
    if GetHasTech(self, kTechId.ShiftHive, true) then
        self:SpawnCloud(kTechId.EnzymeCloud)
        shotWeb = true
    end
    if GetHasTech(self, kTechId.ShadeHive, true) then
        if Server then
            local newAlienExtents = LookupTechData(self:GetTechId(), kTechDataMaxExtents)
            local capsuleHeight, capsuleRadius = GetTraceCapsuleFromExtents(newAlienExtents) 
            
            local spawnPoint = GetRandomSpawnForCapsule(newAlienExtents.y, capsuleRadius, self:GetModelOrigin(), 0.5, 5)
            
            if spawnPoint then

                local hallucinatedPlayer = CreateEntity(Skulk.kMapName, spawnPoint, self:GetTeamNumber())
                
                hallucinatedPlayer:SetVariant(kSkulkVariant.normal)
                hallucinatedPlayer.isHallucination = true
                InitMixin(hallucinatedPlayer, PlayerHallucinationMixin)                
                InitMixin(hallucinatedPlayer, SoftTargetMixin)                
                InitMixin(hallucinatedPlayer, OrdersMixin, { kMoveOrderCompleteDistance = kPlayerMoveOrderCompleteDistance }) 

                hallucinatedPlayer:SetName(self:GetName())
                hallucinatedPlayer:SetHallucinatedClientIndex(self:GetClientIndex())
            
            end 
        end
        shotWeb = true
    end
    if GetHasTech(self, kTechId.CragHive, true) then
        self:SpawnCloud(kTechId.MucousMembrane)
        shotWeb = true
    end
    
    if shotWeb and Server then
        --self:TriggerEffects("drifter_shoot_enzyme", {effecthostcoords = self:GetCoords() } )
        self:TriggerEffects("drifter_shoot_enzyme", {effecthostcoords = Coords.GetLookIn(self:GetEyePos(), GetNormalizedVectorXZ(self:GetViewAngles():GetCoords().zAxis * 5 )) } )
    end
    
end--]]


--[[if Server then
    function Prowler:OnKill(attacker, doer, point, direction)
    
        Alien.OnKill(self, attacker, doer, point, direction)
        --self:TriggerEffects("death", { classname = "Skulk", effecthostcoords = Coords.GetTranslation(self:GetOrigin()), doer = "Railgun"})
        
        local useModelName = self:GetModelName()
        local useGraphName = self:GetGraphName()
        
        local ragdoll = CreateEntity(Ragdoll.kMapName, self:GetOrigin())
        ragdoll:SetCoords(self:GetCoords())
        ragdoll:SetModel(useModelName, useGraphName)
        ragdoll:SetPhysicsType(PhysicsType.Dynamic)
        ragdoll:SetPhysicsGroup(PhysicsGroup.RagdollGroup)
        
        self:SetModel(nil)
    end
end--]]

local kRappelBreakDistance = 10
function Prowler:PostUpdateMove(input)
    if self.rappelPoint then
        local origin = self:GetModelOrigin()
        local trace = Shared.TraceRay(origin, self.rappelPoint, CollisionRep.Move, PhysicsMask.Bullets, EntityFilterTwoAndIsa(self, followEntity, "Babbler"))
        --local trace = Shared.TraceRay(origin, self.rappelPoint, CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterOneAndIsa(self, "Babbler"))
        
        if self.rappelBreak and trace.fraction < 0.99 then
            local armVector = self.newRappelPoint - origin
            VectorSetLength(armVector, 0.4)
            local newTrace = Shared.TraceRay(origin + armVector, self.newRappelPoint, CollisionRep.Move, PhysicsMask.Bullets, EntityFilterTwoAndIsa(self, followEntity, "Babbler"))
             
            -- if new anchor point is too far from old anchor, break the tether
            if (newTrace.endPoint - self.rappelPoint):GetLength() > kRappelBreakDistance then
                -- even the new rappel point is out of LoS, break the rappel
                self.rappelling = false
                self.rappelPoint = nil
                self.rappelFollow = Entity.invalidId
                --Print("Break")
                self.rappelBreak = false
                return
            --else
                -- use the new rappel point
            --    self.rappelPoint = self.newRappelPoint
            --    self.rappelFollow = Entity.invalidId
            --    self.rappelBreak = false
                --Print("NewRappel")
            end--]]
            
            -- use the new rappel point
            self.rappelPoint = self.newRappelPoint
            self.rappelFollow = Entity.invalidId
            self.rappelBreak = false
            --Print("NewRappel")
            
        elseif trace.fraction < 0.99 then
            -- trace toward the obstacle which broke the rappel link and remember it
            self.rappelBreak = true
            self.newRappelPoint = trace.endPoint
            --Print("Uhoh")
        end   
    end
end

--[[function Prowler:GetArmorFullyUpgradedAmount()
    return kProwlerArmorFullyUpgradedAmount
end--]]

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

if Client then

    function Prowler:GetShowGhostModel()
            
        return self.rappelling
        
    end
    
    function Prowler:GetGhostModelOverride()
        return self.rappelling and Bomb.kModelName or nil
    end

    function Prowler:GetGhostModelTechId()
    
        return self.rappelling and kTechId.Umbra or nil
        
    end
    
    function Prowler:GetGhostModelCoords()
        if self.rappelPoint ~= nil then
            return Coords.GetLookIn( self.rappelPoint,(self.rappelPoint - self:GetOrigin()):GetUnit() )
        end
        return nil
    end
    
    function Prowler:GetLastClickedPosition()
    
        return self.rappelPoint
        
    end
    
    function Prowler:GetIsPlacementValid()
        return self.rappelPoint ~= nil
    end
end

-- new uwe balance mod stuff
function Prowler:GetArmorFullyUpgradedAmount()

    --local teamEnt = GetGamerules():GetTeam(kTeam2Index)
    if self:GetTeamNumber() ~= kNeutralTeamType then -- teamEnt then

        -- TODO(Salads): There really should be a constant global for "12"...
        return self:GetBaseArmor() + self:GetBaseCarapaceArmorBuff() + (self:GetCarapaceBonusPerBiomass() * 12)

    end

    return 0

end

function Prowler:GetBaseCarapaceArmorBuff()
    return kProwlerBaseCarapaceUpgradeAmount
end

function Prowler:GetCarapaceBonusPerBiomass()
    return kProwlerCarapaceArmorPerBiomass
end


Shared.LinkClassToMap("Prowler", Prowler.kMapName, networkVars, true)