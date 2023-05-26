Script.Load("lua/BiomassHealthMixin.lua")

local baseOnCreate = Whip.OnCreate
function Whip:OnCreate()
    baseOnCreate(self)
    InitMixin(self, BiomassHealthMixin)
end

function Whip:GetHealthPerBioMass()
    return kWhipHealthPerBioMass
end

if Server then
    
    function Whip:UpdateRootState()

        local infested = true --self:GetGameEffectMask(kGameEffect.OnInfestation)
        local moveOrdered = self:GetCurrentOrder() and self:GetCurrentOrder():GetType() == kTechId.Move
        -- unroot if we have a move order or infestation recedes
        if self.rooted and (moveOrdered or not infested) then
            self:Unroot()
        end

        -- root if on infestation and not moving/teleporting
        if not self.rooted and infested and not (moveOrdered or self:GetIsTeleporting()) then
            self:Root()
        end

    end

    local baseSlapTarget = Whip.SlapTarget
    function Whip:SlapTarget(target)
        baseSlapTarget(self,target)
        local infested = self:GetGameEffectMask(kGameEffect.OnInfestation)
        if not infested then
            self:DeductHealth(self:GetMaxHealth()*.2, target)
        end
        
    end


end 