
AutoWeldMixin = CreateMixin(AutoWeldMixin)
AutoWeldMixin.type = "AutoWeld"

AutoWeldMixin.kWeldArmorPerSecond = 8
AutoWeldMixin.kWeldInterval = 0.2 -- weld hits 5x per second.

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
    
        -- Don't auto weld if not enough time has passed yet.
        if now < self.timeNextWeld then
            return
        end
    
        -- Update the cooldown for the next weld.
        self.timeNextWeld = now + AutoWeldMixin.kWeldInterval
        
        -- Perform the welding.
        self:OnWeld(self, AutoWeldMixin.kWeldInterval, self, AutoWeldMixin.kWeldArmorPerSecond)
    
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