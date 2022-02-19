
local function CheckNanoArmor(self)
    self.nanoArmorResearched = GetHasTech(self,kTechId.NanoArmor)
    return true
end


local baseOnInitialized = Marine.OnInitialized
function Marine:OnInitialized()
    baseOnInitialized(self)

    if Server then
        self.timeNextWeld = 0
        self:AddTimedCallback(CheckNanoArmor, 1)
    end
end

if Server then
    
    local function SharedUpdate(self)
    
        if not self.nanoArmorResearched then 
            return
        end
        -- Don't auto weld if in combat or took damage too recently.
        if self:GetIsInCombat() then
            return
        end
        local now = Shared.GetTime()
        -- Don't auto weld if not enough time has passed yet.
        if now < self.timeNextWeld then
            return
        end
    
        -- Update the cooldown for the next weld.
        self.timeNextWeld = now + AutoWeldMixin.kWeldInterval
        
        -- Perform the welding.
        self:OnWeld(self, AutoWeldMixin.kWeldInterval, self, kNanoArmorHealPerSecond)
    
    end
    
    local baseOnProcessMove=Marine.OnProcessMove
    function Marine:OnProcessMove(input)
        baseOnProcessMove(self,input)
        SharedUpdate(self)
    end
    
    local baseOnUpdate = Marine.OnUpdate
    function Marine:OnUpdate(deltaTime)
        baseOnUpdate(self,deltaTime)
        SharedUpdate(self)
    end
    
    function Marine:GetCanSelfWeld()
        return true
    end
end