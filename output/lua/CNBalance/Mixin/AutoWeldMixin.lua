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

local function ResetTimer(self)
    local now = Shared.GetTime()
    self.timeNextWeld = now + AutoWeldMixin.kWeldInterval
    self.timeNextSustain =  now + AutoWeldMixin.kRegenInterval
end

function AutoWeldMixin:__initmixin()

    PROFILE("AutoWeldMixin:__initmixin")

    if Server then
        ResetTimer(self)
        self.armorRegenStack = 0

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

            local armorRegen = self:GetAutoWeldArmorPerSecond(GetHasTech(self, kTechId.ArmorRegen))

            if self.armorRegenStack > 0  then
                self.armorRegenStack = math.max(0, self.armorRegenStack - kMarineArmorDeductRegen * AutoWeldMixin.kWeldInterval)
                armorRegen = armorRegen + kMarineArmorDeductRegen
            end

            if armorRegen > 0 then
                self:OnWeld(self, AutoWeldMixin.kWeldInterval, self, armorRegen)
            end
        end


        if self.GetAutoHealPerSecond and now > self.timeNextSustain then
            self.timeNextSustain = now + AutoWeldMixin.kRegenInterval

            local lifeSustainResearched = GetHasTech(self, kTechId.LifeSustain)

            local healthCap = lifeSustainResearched and kLifeSustainMaxCap or kLifeRegenMaxCap

            local healthToRegen = self:GetMaxHealth() * healthCap - self:GetHealth()
            if healthToRegen > 0 then
                local regenPerSecond = self:GetAutoHealPerSecond(lifeSustainResearched)
                self:Heal( math.min(AutoWeldMixin.kRegenInterval * regenPerSecond,healthToRegen))
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

    function AutoWeldMixin:DeductArmorWithAutoWeld(amount)
        if self.armorRegenStack > 0 then return end     --Still Regenerating

        amount = math.min(self:GetArmor(),amount)

        ResetTimer(self)
        self.armorRegenStack = self.armorRegenStack + amount

        local engagePoint = HasMixin(self, "Target") and self:GetEngagementPoint() or self:GetOrigin()
        self:TakeDamage(amount, self, nil, engagePoint, nil, amount, 0, kDamageType.ArmorOnly, nil)

    end



end
