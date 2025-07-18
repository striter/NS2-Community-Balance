Script.Load("lua/CNBalance/Weapons/Alien/ShadowStep.lua")

class 'SwipeShadowStep' (ShadowStep)
SwipeShadowStep.kMapName = "swipeshadowstep"
SwipeShadowStep.kKeepCloakWhenSecondary = true

local networkVars =
{
}

-- Make sure to keep damage vs. structures less then Skulk
SwipeShadowStep.kSwipeEnergyCost = kSwipeEnergyCost
SwipeShadowStep.kDamage = kSwipeShadowStepDamage
SwipeShadowStep.kRange = 1.6

local kAnimationGraph = PrecacheAsset("models/alien/vokex/vokex_view.animation_graph")
local kAttackDuration = Shared.GetAnimationLength("models/alien/fade/fade_view.model", "swipe_attack")
local kAttackScalar = Shared.GetAnimationLength("models/alien/fade/fade_view.model", "swipe_attack3") / kAttackDuration

function SwipeShadowStep:OnCreate()

    ShadowStep.OnCreate(self)
    
    self.lastSwipedEntityId = Entity.invalidId
    self.primaryAttacking = false
    self.timeDrawCooldown = 0
end

function SwipeShadowStep:GetAnimationGraphName()
    return kAnimationGraph
end

function SwipeShadowStep:GetEnergyCost()
    return SwipeShadowStep.kSwipeEnergyCost
end

function SwipeShadowStep:GetHUDSlot()
    return 1
end

function SwipeShadowStep:GetPrimaryAttackRequiresPress()
    return false
end

function SwipeShadowStep:GetMeleeBase()
    -- Width of box, height of box
    return .7, 1.2
    
end

function SwipeShadowStep:GetDeathIconIndex()
    return kDeathMessageIcon.Swipe
end

function SwipeShadowStep:GetVampiricLeechScalar()
    return kSwipeShadowStepVampirismScalar
end

function SwipeShadowStep:GetSecondaryTechId()
    return kTechId.ShadowStep
end


function SwipeShadowStep:OnPrimaryAttack(player)
    local hasEnergy = player:GetEnergy() >= self:GetEnergyCost()
    local cooledDown = (not self.nextAttackTime) or (Shared.GetTime() >= self.nextAttackTime)
    local shadowStepping = false --player:GetIsShadowStepping()
    if not shadowStepping and hasEnergy and cooledDown then
        self.primaryAttacking = true
    else
        self.primaryAttacking = false
    end
end

function SwipeShadowStep:OnPrimaryAttackEnd()
    
    ShadowStep.OnPrimaryAttackEnd(self)
    
    self.primaryAttacking = false
    
end

function SwipeShadowStep:OnHolster(player)

    ShadowStep.OnHolster(self, player)
    
    self.primaryAttacking = false
    
end

function SwipeShadowStep:GetIsAffectedByFocus()
    return self.primaryAttacking
end

function SwipeShadowStep:GetAttackAnimationDuration()
    return kAttackDuration
end

function SwipeShadowStep:OnTag(tagName)

    PROFILE("SwipeShadowStep:OnTag")
    
    if tagName == "hit" then
    
         local stabWep = self:GetParent():GetWeapon(VortexShadowStep.kMapName)
         if stabWep and stabWep.stabbing then
             -- player is using stab and has switched to swipe really fast, but the attack the "hit"
             -- tag is from is still a stab, and thus should do stab damage.
             stabWep:DoAttack()
         else
            self:TriggerEffects("swipe_attack")    
            self:PerformMeleeAttack()
        
            local player = self:GetParent()
            if player then
            
                self:OnAttack(player)
            
            end
         end
    
    end

end

function SwipeShadowStep:OnDraw(player, previousWeaponMapName)
    Ability.OnDraw(self, player, previousWeaponMapName)
    if previousWeaponMapName == AcidRocket.kMapName then
        self.timeDrawCooldown = Shared.GetTime() + 0.3
    end
end

function SwipeShadowStep:ModifyAttackSpeedView(attackSpeedTable)
    attackSpeedTable.attackSpeed = attackSpeedTable.attackSpeed * kAttackScalar
end

function SwipeShadowStep:PerformMeleeAttack()

    local player = self:GetParent()
    if player then    
        AttackMeleeCapsule(self, player, SwipeShadowStep.kDamage, SwipeShadowStep.kRange, nil, false, EntityFilterOneAndIsa(player, "Babbler"))
    end
    
end

function SwipeShadowStep:OnUpdateAnimationInput(modelMixin)

    PROFILE("SwipeShadowStep:OnUpdateAnimationInput")

    ShadowStep.OnUpdateAnimationInput(self, modelMixin)
    
    modelMixin:SetAnimationInput("ability", "swipe")
    
    local activityString = (self.primaryAttacking and Shared.GetTime() > self.timeDrawCooldown) and "primary" or "none"
    modelMixin:SetAnimationInput("activity", activityString)
    
end

Shared.LinkClassToMap("SwipeShadowStep", SwipeShadowStep.kMapName, networkVars)