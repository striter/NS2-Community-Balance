Gorge.kAdrenalineEnergyRecuperationRate = 15.0  -- 17 -> 15
Gorge.kKDRatioMaxDamageReduction = 0.3

Script.Load("lua/CNBalance/Weapons/Alien/Gorge/DropTeamStructureAbility.lua")
Script.Load("lua/CNBalance/Mixin/RequestHandleMixin.lua")
local networkVars =
{
    bellyYaw = "private compensated float",
    timeSlideEnd = "private time",
    startedSliding = "private boolean",
    sliding = "compensated boolean",
    hasBellySlide = "private compensated boolean",
    timeOfLastPhase = "private time",
}

AddMixinNetworkVars(BaseMoveMixin, networkVars)
AddMixinNetworkVars(GroundMoveMixin, networkVars)
AddMixinNetworkVars(JumpMoveMixin, networkVars)
AddMixinNetworkVars(CrouchMoveMixin, networkVars)
AddMixinNetworkVars(CelerityMixin, networkVars)
AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(BabblerClingMixin, networkVars)
AddMixinNetworkVars(BabblerOwnerMixin, networkVars)
AddMixinNetworkVars(TunnelUserMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)
AddMixinNetworkVars(GorgeVariantMixin, networkVars)
AddMixinNetworkVars(RequestHandleMixin,networkVars)

local baseOnCreate = Gorge.OnCreate
function Gorge:OnCreate()
    baseOnCreate(self)
    InitMixin(self,RequestHandleMixin)

end

local baseOnInitialized = Gorge.OnInitialized
function Gorge:OnInitialized()
    baseOnInitialized(self)
end

if Server then
    
    function Gorge:InitWeapons()
        Alien.InitWeapons(self)

        self:GiveItem(SpitSpray.kMapName)
        self:GiveItem(DropStructureAbility.kMapName)
        self:GiveItem(DropTeamStructureAbility.kMapName)
        self:SetActiveWeapon(SpitSpray.kMapName)
    end

end

-- Handle transitions between starting-sliding, sliding, and ending-sliding
function Gorge:UpdateGorgeSliding(input)

    PROFILE("Gorge:UpdateGorgeSliding")

    local slidingDesired = self:GetIsSlidingDesired(input)
    if slidingDesired and not self.sliding and self.timeSlideEnd + Gorge.kSlideCoolDown < Shared.GetTime()
            and self:GetIsOnGround() and self:GetEnergy() >= kBellySlideCost then

        self.sliding = true
        self.startedSliding = true

        if Server then
            if (GetHasSilenceUpgrade(self) and self:GetSpurLevel() == 0) or not GetHasSilenceUpgrade(self) then
                self.slideLoopSound:Start()
            end
        end

        self:DeductAbilityEnergy(kBellySlideCost)
        self:PrimaryAttackEnd()
        self:SecondaryAttackEnd()

    end

    if not slidingDesired and self.sliding then

        self.sliding = false

        if Server then
            self.slideLoopSound:Stop()
        end

        self.timeSlideEnd = Shared.GetTime()

    end

    -- Have Gorge lean into turns depending on input. He leans more at higher rates of speed.
    if self:GetIsBellySliding() then

        local desiredBellyYaw = 2 * (-input.move.x / self.kSlidingMoveInputScalar) * (self:GetVelocity():GetLength() / self:GetMaxSpeed())
        self.bellyYaw = Slerp(self.bellyYaw, desiredBellyYaw, input.time * Gorge.kLeanSpeed)

    end

end


if Client then

    function Gorge:OverrideInput(input)

        -- Always let the DropStructureAbility override input, since it handles client-side-only build menu

        local ability = self:GetActiveWeapon()
        if ability then
            local mapName = ability:GetMapName()
            if mapName == DropStructureAbility.kMapName or mapName == DropTeamStructureAbility.kMapName then
                input = ability:OverrideInput(input)
            end
        end

        return Player.OverrideInput(self, input)

    end
end

function Gorge:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint) -- dud
    local reduction = kGorgeDamageReduction[doer:GetClassName()]
    if reduction then
        damageTable.damage = damageTable.damage * reduction
    end
end

function Gorge:GetExtraHealth(techLevel,extraPlayers,recentWins)
    return techLevel * kGorgeHealthPerBioMass 
            + recentWins * -5
end

if Server then
    local basePreUpdateMove = Gorge.PreUpdateMove
    function Gorge:PreUpdateMove(input, runningPrediction)
        basePreUpdateMove(self,input,runningPrediction)

        self:Stampede()
    end

    function Gorge:OnJump()
        self.timeValidImpact = Shared.GetTime() + 0.5
    end

    Gorge.kChargeExtents = Vector(.7, .7, 1)
    Gorge.kStampedeCheckRadius = 2
    function Gorge:Stampede()
        if not self.timeValidImpact 
                or Shared.GetTime() > self.timeValidImpact 
                or self:GetIsOnGround() 
        then
            return
        end

        local velocity = self:GetVelocity()
        local velocityLength = velocity:GetLengthXZ()
        local comparison = 9
        if velocityLength < comparison then return end

        local direction = velocity
        direction.y = 0
        direction:Normalize()
        local chargeExtends = Gorge.kChargeExtents

        
        local hitOrigin = self:GetOrigin() + (direction * chargeExtends.z) + Vector(0,0.3,0)
        local teamNumber = self:GetTeamNumber()
        local stampedables = teamNumber == kTeamReadyRoom and GetEntitiesWithinRange("Player", hitOrigin, Gorge.kStampedeCheckRadius)
                            or GetEntitiesForTeamWithinRange("Player",GetEnemyTeamNumber(teamNumber), hitOrigin, Gorge.kStampedeCheckRadius)

        --DebugLine(self:GetOrigin(),hitOrigin,.1,1,1,1,1)
        --Shared.Message(tostring(#stampedables))
        
        if #stampedables < 1 then return end

        local hitboxCoords = Coords.GetLookIn(hitOrigin, direction, Vector(0, 1, 0))
        local invHitboxCoords = hitboxCoords:GetInverse() -- could possibly optimize with Transpose() instead?
        for i = 1, #stampedables do
            local player = stampedables[i]
            local mass = player:GetMass()
            if player ~= self 
                and mass < 158
                and player:GetIsAlive()
            then
                local localSpacePosition = invHitboxCoords:TransformPoint(player:GetEngagementPoint())
                local extents = player:GetExtents()
                
                -- If entity is touching box, impact it.
                if math.abs(localSpacePosition.x) <= chargeExtends.x + extents.x and
                        math.abs(localSpacePosition.y) <= chargeExtends.y + extents.y and
                        math.abs(localSpacePosition.z) <= chargeExtends.z + extents.z then
                    self.timeValidImpact = nil
                    self:Impact(player)
                    break
                end
            end
        end
    end
    

    -- Stampede Charge Impact
    function Gorge:Impact(target)
        
        local targetPoint = target:GetEngagementPoint()
        local attackOrigin = self:GetOrigin()

        local hitDirection = targetPoint - attackOrigin
        hitDirection:Normalize()

        local velocity = self:GetVelocity()
        local speed = velocity:GetLength()
        local extraSpeedBonus = math.max(speed - 11,0)

        self:TriggerEffects("onos_charge_hit_marine")
        
        local impactDirection = velocity
        impactDirection.y = 0
        impactDirection:Normalize()
        local impactSpeed = impactDirection * speed * 0.5
        local upVel = Vector(0, 2 + extraSpeedBonus * 0.5, 0)

        ApplyPushback(target,0.2, impactSpeed + upVel)
        ApplyPushback(self,0.2,-impactSpeed + upVel)
        if target.SetStun then
            local stunduration = Clamp(extraSpeedBonus + 1.25,1.25,3.5)
            target:SetStun(stunduration)
        end
        self:DeductAbilityEnergy(kBellySlideImpactCost)
    end
end

Shared.LinkClassToMap("Gorge", Gorge.kMapName, networkVars, true)
