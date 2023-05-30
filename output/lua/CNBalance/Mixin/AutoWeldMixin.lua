-- ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua\AutoWeldMixin.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Mixin for automatically welding armor when not in combat.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

AutoWeldMixin = CreateMixin(AutoWeldMixin)
AutoWeldMixin.type = "AutoWeld"

--AutoWeldMixin.kWeldArmorPerSecond = 8
AutoWeldMixin.kWeldInterval = 0.2 -- weld hits 5x per second.
AutoWeldMixin.kRegenInterval = 0.5

AutoWeldMixin.expectedMixins = 
{
    Weldable = "Required to weld self.",
}

AutoWeldMixin.networkVars =
{
}

local function GetIsInCombat_WithoutCombatMixin(self, time)
    local timeLastDamage = self:GetTimeOfLastDamage() or 0
    return time < timeLastDamage + kCombatTimeOut
end

function AutoWeldMixin:__initmixin()
    
    PROFILE("AutoWeldMixin:__initmixin")
    
    if Server then
        self.timeNextWeld = 0
        self.timeNextSustain = 0
        
        -- Use combat mixin if we can find it, otherwise just use LiveMixin's GetTimeOfLastDamage()
        -- method.
        -- NOTE: The InitMixin() call for AutoWeldMixin should come AFTER the InitMixin() for
        -- CombatMixin, otherwise it won't be able to use it.
        if HasMixin(self, "Combat") then
            self.__GetIsInCombatForAutoRepair = CombatMixin.GetIsInCombat
        else
            self.__GetIsInCombatForAutoRepair = GetIsInCombat_WithoutCombatMixin
        end
        
    end
    
end

if Server then
    
    local function SharedUpdate(self)
    
        -- Don't auto weld if in combat or took damage too recently.
        local now = Shared.GetTime()
        if self:__GetIsInCombatForAutoRepair(now) then
            return
        end
    
        if now > self.timeNextWeld then
            self.timeNextWeld = now + AutoWeldMixin.kWeldInterval


            local armorRegenPerSecond = self:GetAutoWeldArmorPerSecond(GetHasTech(self, kTechId.ArmorRegen))
            self:OnWeld(self, AutoWeldMixin.kWeldInterval, self, armorRegenPerSecond)
        end

        if self.GetAutoHealPerSecond and now > self.timeNextSustain then
            self.timeNextSustain = now + AutoWeldMixin.kRegenInterval
            
            local lifeSustainResearched = GetHasTech(self, kTechId.LifeSustain)
            
            local healthCap = lifeSustainResearched and kLifeSustainMaxCap or kLifeRegenMaxCap
            
            local healthToRegen = self:GetMaxHealth() * healthCap - self:GetHealth()
            if healthToRegen > 0 then
                local regenPerSecond = self:GetAutoHealPerSecond(lifeSustainResearched) 
                self:AddRegeneration( math.min(AutoWeldMixin.kRegenInterval * regenPerSecond,healthToRegen))
            end
        end
        
    end
    
    function AutoWeldMixin:OnProcessMove(input)
        SharedUpdate(self)
    end
    
    function AutoWeldMixin:OnUpdate(deltaTime)
        SharedUpdate(self)
    end
    
    function AutoWeldMixin:GetCanSelfWeld()
        return true
    end
    
end
