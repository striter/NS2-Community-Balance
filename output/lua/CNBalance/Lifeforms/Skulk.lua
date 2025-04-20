Skulk.kBountyThreshold = kBountyClaimMinSkulk
Skulk.kKDRatioMaxDamageReduction = 0.66

Skulk.kAdrenalineEnergyRecuperationRate = 30

function Skulk:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint) -- dud
    local reduction = kSkulkDamageReduction[doer:GetClassName()]
    if reduction then
        damageTable.damage = damageTable.damage * reduction
        return
    end
end

function Skulk:GetExtraHealth(techLevel,extraPlayers,recentWins)
    return techLevel * kSkulkHealthPerBioMass 
            + Clamp((extraPlayers - recentWins * 2) * 1.5,-5,25)
end

local baseOnKill = Skulk.OnKill
function Skulk:OnKill(attacker,doer,point, direction)
    baseOnKill(self,attacker,doer,point, direction)

    local xenocide = GetIsTechUnlocked(self,kTechId.Xenocide)
    if xenocide then
        CreateEntity(EnzymeCloud.kMapName, self:GetOrigin(), self:GetTeamNumber())
    end
    
    --if not attacker or not attacker:isa("Player") then return end
    --if not HasMixin(attacker, "ParasiteAble") then return end
    --
    --local dist = (self:GetOrigin() - attacker:GetOrigin()):GetLength()
    --if dist > 5 then return end
    --attacker:SetParasited(self)
end