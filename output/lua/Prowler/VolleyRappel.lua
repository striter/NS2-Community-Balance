 
Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Prowler/RappelMixin.lua")


class 'VolleyRappel' (Ability)
VolleyRappel.kMapName = "volley"
VolleyRappel.kStartOffset = -0.5
VolleyRappel.AttackSpeedMod = 0.58 --0.515

local kAnimationGraph = PrecacheAsset("models/alien/prowler/prowler_view.animation_graph") --PrecacheAsset("models/alien/skulk/skulk_view.animation_graph")
local kVolleyRappelTracer = PrecacheAsset("cinematics/prowler/1p_tracer_residue.cinematic")
local kAttackDuration = Shared.GetAnimationLength("models/alien/prowler/prowler_view.model", "bite_attack") -- 0.23333333432674 / 0.55555 = 0.42
local kAttackDuration2 = Shared.GetAnimationLength("models/alien/prowler/prowler_view.model", "bite_attack2") -- 0.38333332538605
local kAttackDuration3 = Shared.GetAnimationLength("models/alien/prowler/prowler_view.model", "bite_attack3") -- 1.8166667222977
local kAttackDuration4 = Shared.GetAnimationLength("models/alien/prowler/prowler_view.model", "bite_attack4") -- 0.36666667461395

-- higher numbers reduces the spread
local kSpreadDistance = 10.0
local kSpreadVertMult = 1.0 --0.66
VolleyRappel.kSpreadVectors =
{
    --[[GetNormalizedVector(Vector(0.0, 0.0, kSpreadDistance)),
    GetNormalizedVector(Vector(3.0, 0.0, kSpreadDistance)),
    GetNormalizedVector(Vector(-3.0, 0.0, kSpreadDistance)),
    GetNormalizedVector(Vector(0.0, 3.0, kSpreadDistance)),
    GetNormalizedVector(Vector(0.0, -3.0, kSpreadDistance)),--]]
    
    GetNormalizedVector(Vector(-0.44, 0.1, kSpreadDistance)),
    GetNormalizedVector(Vector( 0.44, 0.1, kSpreadDistance)),
    
    GetNormalizedVector(Vector(-0.88, -0.05, kSpreadDistance)),
    GetNormalizedVector(Vector( 0.88, -0.05, kSpreadDistance)),
    
    GetNormalizedVector(Vector(0.0, 0.08, kSpreadDistance)),
    GetNormalizedVector(Vector(0.0, -0.4, kSpreadDistance)),
    GetNormalizedVector(Vector(0.0, -0.08, kSpreadDistance)),

    GetNormalizedVector(Vector(-1.22, -0.05, kSpreadDistance)),
    GetNormalizedVector(Vector(1.22, -0.05, kSpreadDistance)),

    --GetNormalizedVector(Vector(-0.7, -0.7, kSpreadDistance)),
    --GetNormalizedVector(Vector( 0.7, -0.7, kSpreadDistance)),
    --GetNormalizedVector(Vector( 0.7,  0.7, kSpreadDistance)),
    --GetNormalizedVector(Vector(-0.7,  0.7, kSpreadDistance)),
    
    --GetNormalizedVector(Vector(-0.7, 0, kSpreadDistance)),
    --GetNormalizedVector(Vector(0.7, 0, kSpreadDistance)),
    --GetNormalizedVector(Vector(0, -0.7, kSpreadDistance)),
    --GetNormalizedVector(Vector(0, 0.7, kSpreadDistance)),
    
}

local spreadRadius = math.tan(kVolleySpread)

local networkVars =
{
}

AddMixinNetworkVars(RappelMixin, networkVars)

function VolleyRappel:OnCreate()

    Ability.OnCreate(self)
    InitMixin(self, RappelMixin)
    InitMixin(self, BulletsMixin)
    
    self.primaryAttacking = false
    
    --[[if Client then
        Print("AS: ")
        Print(ToString(kAttackDuration))
        Print(ToString(kAttackDuration2))
        Print(ToString(kAttackDuration3))
        Print(ToString(kAttackDuration4))
    end--]]
end
function VolleyRappel:GetAnimationGraphName()
    return kAnimationGraph
end
function VolleyRappel:GetVampiricLeechScalar()
    return kVolleyRappelVampirismScalar
end

function VolleyRappel:GetIsAffectedByFocus()
    return self.primaryAttacking
end

function VolleyRappel:GetMaxFocusBonusDamage()
    return kVolleyFocusDamageBonusAtMax
end

function VolleyRappel:GetFocusAttackCooldown()
    return kVolleyFocusAttackSlowAtMax
end

function VolleyRappel:GetAttackAnimationDuration()
    return kAttackDuration
end
function VolleyRappel:GetTracerEffectName()
    return kVolleyRappelTracer
end
function VolleyRappel:GetTracerResidueEffectName()
    return kVolleyRappelTracer
end

function VolleyRappel:GetBulletsPerShot()
    local player = self:GetParent()
    if player then
        local teamInfo = GetTeamInfoEntity(player:GetTeamNumber())
        local biomassLevel = (teamInfo and teamInfo.GetBioMassLevel) and teamInfo:GetBioMassLevel() or 0
        
        return 5 + biomassLevel / 5
    end
    
    return 6
end

function VolleyRappel:GetEnergyCost(player)
    return kVolleyEnergyCost
end
function VolleyRappel:GetHUDSlot()
    return 1
end
function VolleyRappel:GetTechId()
    return kTechId.Volley
end
function VolleyRappel:GetRange()
    return 40
end
function VolleyRappel:GetBulletDamage()
    return kProwlerDamagePerPellet
end

function VolleyRappel:GetBarrelPoint()
    local player = self:GetParent()
    return player:GetEyePos() + Vector(0, -0.25, 0)
end

function VolleyRappel:GetDeathIconIndex()
    if self.primaryAttacking then
        return kDeathMessageIcon.Volley
    else
        return RappelMixin:GetDeathIconIndex()
    end
end

function VolleyRappel:GetDamageType()
    return kVolleyRappelDamageType
end

function VolleyRappel:OnPrimaryAttack(player)
    local hasEnergy = player:GetEnergy() >= self:GetEnergyCost()
    local cooledDown = (not self.nextAttackTime) or (Shared.GetTime() >= self.nextAttackTime)
    if hasEnergy and cooledDown then
        self.primaryAttacking = true
    else
        self.primaryAttacking = false
    end
    
end
function VolleyRappel:OnPrimaryAttackEnd()
    
    Ability.OnPrimaryAttackEnd(self)
    
    self.primaryAttacking = false
    
end
function VolleyRappel:OnUpdateAnimationInput(modelMixin)

    PROFILE("VolleyRappel:OnUpdateAnimationInput")
    
    modelMixin:SetAnimationInput("ability", "bite")
    
    local activityString = (self.primaryAttacking and "primary") or "none"
    modelMixin:SetAnimationInput("activity", activityString)    
    
end

function VolleyRappel:OnTag(tagName)
    PROFILE("VolleyRappel:OnTag")

    if tagName == "hit" then
        local player = self:GetParent()
        
        if player then
            local viewAngles = player:GetViewAngles()
            --local roll = NetworkRandom() * math.pi * 2
            --local rollAngles = Angles(0,0,roll):GetCoords()

            local shootCoords = viewAngles:GetCoords()
            --shootCoords.yAxis = shootCoords.yAxis * kSpreadVertMult

            -- Filter ourself out of the trace so that we don't hit ourselves.
            local filter = EntityFilterTwo(player, self)
            local range = self:GetRange()
            
            local numberBullets = self:GetBulletsPerShot()
            local startPoint = player:GetEyePos()
            local viewCoords = player:GetViewCoords()
            
            for bullet = 1, math.min(numberBullets, #self.kSpreadVectors) do
            
                if not self.kSpreadVectors[bullet] then
                    break
                end
                
                local spreadVector = Vector(self.kSpreadVectors[bullet])
                --spreadVector = rollAngles:TransformVector(spreadVector)
            
                -- add random spread
                local randomAngle = NetworkRandom() * math.pi * 2
                local randomRadius = (0.5 - NetworkRandom()) * spreadRadius --* math.tan(spreadAngle)
                
                local spreadX = math.cos(randomAngle) * randomRadius
                local spreadY = math.sin(randomAngle) * randomRadius
                spreadVector.x = spreadVector.x + spreadX
                spreadVector.y = spreadVector.y + spreadY
                                
                local spreadDirection = shootCoords:TransformVector(spreadVector) --CalculateSpread(shootCoords, kVolleySpread, NetworkRandom) 

                local endPoint = startPoint + spreadDirection * range
                startPoint = player:GetEyePos() + shootCoords.xAxis * spreadVector.x * self.kStartOffset + shootCoords.yAxis * spreadVector.y * self.kStartOffset
                
                local targets, trace, hitPoints = GetBulletTargets(startPoint, endPoint, spreadDirection, 0.1, filter)
                
                local damage = self:GetBulletDamage()

                HandleHitregAnalysis(player, startPoint, endPoint, trace)        
                    
                local direction = (trace.endPoint - startPoint):GetUnit()
                local hitOffset = direction * kHitEffectOffset
                local impactPoint = trace.endPoint - hitOffset
                local showTracer = true
                
                local numTargets = #targets
                
                if numTargets == 0 then
                    self:ApplyBulletGameplayEffects(player, nil, impactPoint, direction, 0, "rock", showTracer)
                end
                
                if Client and showTracer then
                    TriggerFirstPersonTracer(self, impactPoint)
                end
                
                for i = 1, numTargets do

                    local target = targets[i]
                    local hitPoint = hitPoints[i]

                    self:ApplyBulletGameplayEffects(player, target, hitPoint - hitOffset, direction, damage, "rock", showTracer and i == numTargets)

                    if HasMixin(target, "Webable") then
                        if target.GetIsOnGround and not target:GetIsOnGround() then
                            target:SetWebbed(kVolleyWebTime, true)
                        end
                    end
                    
                    local client = Server and player:GetClient() or Client
                    if not Shared.GetIsRunningPrediction() and client and client.hitRegEnabled then
                        RegisterHitEvent(player, bullet, startPoint, trace, damage)
                    end
                
                end
                
            end
                        
            if Server then
                --self:TriggerEffects("drifter_parasite_hit")
               self:TriggerEffects("volley_attack")
            end
                        
            self:OnAttack(player)
            
        end
    end

end

function VolleyRappel:GetSecondaryTechId()
    return kTechId.Rappel
end

Shared.LinkClassToMap("VolleyRappel", VolleyRappel.kMapName, networkVars)