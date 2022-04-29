-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\Weapons\Alien\Blink.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com)
--
-- Blink - Attacking many times in a row will create a cool visual "chain" of attacks,
-- showing the more flavorful animations in sequence. Base class for swipe and vortex,
-- available at tier 2.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Ability.lua")

class 'ShadowStep' (Ability)

ShadowStep.kMapName = "shadowstep"

-- Boost added when player blinks again in the same direction. The added benefit exact.
local kEtherealBoost = 0.833
local kEtherealVerticalForce = 2

local networkVars =
{
}

function ShadowStep:OnInitialized()

    Ability.OnInitialized(self)
    
    self.secondaryAttacking = false
    self.timeBlinkStarted = 0
    
end

function ShadowStep:OnHolster(player)

    Ability.OnHolster(self, player)
    
    self:SetEthereal(player, false)
    
end

function ShadowStep:GetHasSecondary(player)
    return true
end

function ShadowStep:GetSecondaryAttackRequiresPress()
    return false
end

local function TriggerBlinkOutEffects(self, player)

    -- Play particle effect at vanishing position.
    if not Shared.GetIsRunningPrediction() then
    
        player:TriggerEffects("blink_out", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})
        
        if Client and player:GetIsLocalPlayer() and not player:GetIsThirdPerson() then
            player:TriggerEffects("blink_out_local", { effecthostcoords = Coords.GetTranslation(player:GetOrigin()) })
        end
        
    end
    
end

local function TriggerBlinkInEffects(self, player)

    if not Shared.GetIsRunningPrediction() then
        player:TriggerEffects("blink_in", { effecthostcoords = Coords.GetTranslation(player:GetOrigin()) })
    end
    
end

function ShadowStep:GetIsShadowStepping()

    local player = self:GetParent()
    
    if player then
        return player:GetIsShadowStepping() or player.ethereal
    end
    
    return false
    
end

-- Cannot attack while shadowStepping.
function ShadowStep:GetPrimaryAttackAllowed()
    return not self:GetIsShadowStepping()
end

function ShadowStep:GetSecondaryEnergyCost()
    return kVokexShadowStepCost
end

function ShadowStep:OnSecondaryAttack(player)

    local minTimePassed = not player:GetRecentlyBlinked()
    local hasEnoughEnergy = player:GetEnergy() > kVokexShadowStepCost
    if not player.etherealStartTime or minTimePassed and hasEnoughEnergy and player:GetShadowStepAllowed() then
    
        -- Enter "ether" fast movement mode, but don't keep going ethereal when button still held down after
        -- running out of energy.
        if not self.secondaryAttacking then
        
            self:SetEthereal(player, true)
            
            self.timeBlinkStarted = Shared.GetTime()
            
            self.secondaryAttacking = true
            
        end
        
    end
    
    Ability.OnSecondaryAttack(self, player)
    
end

function ShadowStep:OnSecondaryAttackEnd(player)

    if player.ethereal then
    
        self:SetEthereal(player, false)

    end
    
    Ability.OnSecondaryAttackEnd(self, player)
    
    self.secondaryAttacking = false
    
end

function ShadowStep:SetEthereal(player, state)

    -- Enter or leave ethereal mode.
    if player.ethereal ~= state then
    
        if state then

            TriggerBlinkOutEffects(self, player)

            player.onGround = false
            player.jumping = true
            
        else
        
            TriggerBlinkInEffects(self, player)
            player.etherealEndTime = Shared.GetTime()
            
        end

        player.ethereal = state

        -- Give player initial velocity in direction we're pressing, or forward if not pressing anything.
        if player.ethereal then
        
            -- Deduct blink start energy amount.
            player:DeductAbilityEnergy(kVokexShadowStepStartCost)
            player:TriggerShadowStep()
            
        -- A case where OnBlinkEnd() does not exist is when a Fade becomes Commanders and
        -- then a new ability becomes available through research which calls AddWeapon()
        -- which calls OnHolster() which calls this function. The Commander doesn't have
        -- a OnBlinkEnd() function but the new ability is still added to the Commander for
        -- when they log out and become a Fade again.
        elseif player.OnShadowStepEnd then
            player:OnShadowStepEnd()
        end

    end
    
end

function ShadowStep:ProcessMoveOnWeapon(player, input)
 
    if self:GetIsActive() and player.ethereal then
    
        -- Decrease energy while in blink mode.
        -- Don't deduct energy for blink for a short time to make sure that when we blink,
        -- we always get at least a short blink out of it.
        if Shared.GetTime() > (self.timeBlinkStarted + 0.08) then
        
            local energyCost = input.time * kVokexShadowStepCost
            player:DeductAbilityEnergy(energyCost)
            
        end
        
    end
    
    -- End blink mode if out of energy or when dead
    if (player:GetEnergy() == 0 or not player:GetIsAlive()) and player.ethereal then
    
        self:SetEthereal(player, false)

    end
    
end

function ShadowStep:OnUpdateAnimationInput(modelMixin)

    local player = self:GetParent()
    if self:GetIsShadowStepping() and (not self.GetHasMetabolizeAnimationDelay or not self:GetHasMetabolizeAnimationDelay()) then
        modelMixin:SetAnimationInput("move", "blink")
    end
    
end

Shared.LinkClassToMap("ShadowStep", ShadowStep.kMapName, networkVars)
