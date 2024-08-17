Script.Load("lua/CNBalance/Weapons/Alien/ShadowStep.lua")
Script.Load("lua/CNBalance/Weapons/Alien/Vortex.lua")

class 'VortexShadowStep' (ShadowStep)
VortexShadowStep.kMapName = "VortexShadowStep"
VortexShadowStep.kKeepCloakWhenSecondary = true

local networkVars =
{
    stabbing = "compensated boolean"
}

local kAnimationGraph = PrecacheAsset("models/alien/vokex/vokex_view.animation_graph")
local kAttackAnimationLength = Shared.GetAnimationLength("models/alien/fade/fade_view.model", "stab")

function VortexShadowStep:OnCreate()

    ShadowStep.OnCreate(self)
    
    self.primaryAttacking = false

end

function VortexShadowStep:GetAnimationGraphName()
    return kAnimationGraph
end

function VortexShadowStep:GetEnergyCost()
    return kVortexEnergyCost
end

function VortexShadowStep:GetHUDSlot()
    return 4
end

function VortexShadowStep:GetPrimaryAttackRequiresPress()
    return false
end

function VortexShadowStep:GetDeathIconIndex()
    return kDeathMessageIcon.Vortex
end

function VortexShadowStep:GetSecondaryTechId()
    return kTechId.ShadowStep
end


function VortexShadowStep:OnDraw(player,previousWeaponMapName)

    ShadowStep.OnDraw(self, player, previousWeaponMapName)
    self.primaryAttacking = false
end

function VortexShadowStep:OnHolster(player)
    ShadowStep.OnHolster(self, player)
    self.primaryAttacking = false
end


function VortexShadowStep:OnPrimaryAttack(player)
    local hasEnergy = player:GetEnergy() >= self:GetEnergyCost()
    local cooledDown = (not self.nextAttackTime) or (Shared.GetTime() >= self.nextAttackTime)
    if hasEnergy and cooledDown then
        self.primaryAttacking = true
    else
        self.primaryAttacking = false
    end
    
end

function VortexShadowStep:OnPrimaryAttackEnd()
    
    ShadowStep.OnPrimaryAttackEnd(self)
    
    self.primaryAttacking = false
    
end

function VortexShadowStep:GetIsStabbing()
    return self.stabbing == true
end

function VortexShadowStep:GetIsAffectedByFocus()
    return false
end

function VortexShadowStep:GetAttackAnimationDuration()
    return kAttackAnimationLength
end

local function CreateVortex(self, player)

    local viewAngles = player:GetViewAngles()
    local viewCoords = viewAngles:GetCoords()
    local startPoint = player:GetEyePos() + viewCoords.zAxis * 2.5
    local vortex = CreateEntity( Vortex.kMapName, startPoint, player:GetTeamNumber() )
    vortex:SetOwner(player)
    return vortex

end


function VortexShadowStep:DoAttack()
    self:TriggerEffects("stab_hit")
    self.stabbing = false

    local player = self:GetParent()
    if player then
        if Server then

            if player:GetEnergy() >= self:GetEnergyCost() then
                CreateVortex(self,  player)
                player:DeductAbilityEnergy(self:GetEnergyCost())
            end

        end
    end
end

function VortexShadowStep:OnTag(tagName)

    PROFILE("SwipeBlink:OnTag")

    if tagName == "stab_start" then

        self:TriggerEffects("stab_attack")
        self.stabbing = true

    elseif tagName == "hit" and self.stabbing then

        self:DoAttack()

    end

end


--function VortexShadowStep:ModifyAttackSpeedView(attackSpeedTable)
--    attackSpeedTable.attackSpeed = attackSpeedTable.attackSpeed * kAttackScalar
--end

function VortexShadowStep:OnUpdateAnimationInput(modelMixin)

    PROFILE("VortexShadowStep:OnUpdateAnimationInput")

    ShadowStep.OnUpdateAnimationInput(self, modelMixin)
    
    modelMixin:SetAnimationInput("ability", "stab")
    
    local activityString = (self.primaryAttacking and "primary") or "none"
    modelMixin:SetAnimationInput("activity", activityString)

end

Shared.LinkClassToMap("VortexShadowStep", VortexShadowStep.kMapName, networkVars)