local kUnrootPlayerSelfDamage = .25
local kUnrootDefaultSelfDamage = .07
Script.Load("lua/BiomassHealthMixin.lua")

local baseOnCreate = Whip.OnCreate
function Whip:OnCreate()
    baseOnCreate(self)
    InitMixin(self, BiomassHealthMixin)
end

function Whip:GetExtraHealth(techLevel,extraPlayers,recentWins)
    return kWhipHealthPerBioMass * techLevel
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
        
        local team = self:GetTeam()
        local targetIsPlayer = target:isa("Player")

        if targetIsPlayer then
            local direction = target:GetOrigin() - self:GetOrigin()
            direction.y = 0
            direction:Normalize()
            ApplyPushback(target,0.2,direction * 4.5)
        end
        
        local infested = self:GetGameEffectMask(kGameEffect.OnInfestation)
        if not infested then
            local attacker 
            local selfDamage = kUnrootDefaultSelfDamage
            if targetIsPlayer then
                selfDamage = kUnrootPlayerSelfDamage
                attacker = target
            end

            self:DeductHealth(self:GetMaxHealth()* selfDamage, attacker)
        end
    end


end
-- CQ: EyePos seems to be somewhat hackish; used in several places but not owned anywhere... predates Mixins
function Whip:GetEyePos()
    return self:GetOrigin() + self:GetCoords().yAxis * 1.7
end