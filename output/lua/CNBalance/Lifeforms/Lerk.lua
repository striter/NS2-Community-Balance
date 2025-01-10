Lerk.kAdrenalineEnergyRecuperationRate = 18.0
Script.Load("lua/RailgunTargetMixin.lua")
local baseOnInitialized = Lerk.OnInitialized
function Lerk:OnInitialized()
    baseOnInitialized(self)
    if Client then
        InitMixin(self, RailgunTargetMixin)
    end
end

function Lerk:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint) -- dud
        local reduction = kLerkDamageReduction[doer:GetClassName()]
        if reduction then
            damageTable.damage = damageTable.damage * reduction
        end
end

function Lerk:GetExtraHealth(techLevel,extraPlayers,recentWins)
    return techLevel * kLerkHealthPerBioMass 
            + extraPlayers * (1.5 - recentWins * .25) 
            - recentWins * 3
end

if Server then
    function Lerk:GetTierTwoTechId()
        return kTechId.Spores
    end

    function Lerk:GetTierThreeTechId()
        return kTechId.Umbra
    end
end
