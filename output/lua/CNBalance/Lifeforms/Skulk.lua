Skulk.kBountyThreshold = kBountyClaimMinSkulk
Skulk.kAdrenalineEnergyRecuperationRate = 30
function Skulk:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint) -- dud
    local reduction = kSkulkDamageReduction[doer:GetClassName()]
    if reduction then
        damageTable.damage = damageTable.damage * reduction
        return
    end
end


function Skulk:GetHealthPerTeamExceed()
    return kSkulkHealthPerPlayerAboveLimit
end


local baseOnKill = Skulk.OnKill
function Skulk:OnKill(attacker,doer,point, direction)
    baseOnKill(self,attacker,doer,point, direction)
    
    if not attacker or not attacker:isa("Player") then return end
    if not HasMixin(attacker, "ParasiteAble") then return end

    local dist = (self:GetOrigin() - attacker:GetOrigin()):GetLength()
    if dist > 5 then return end
    attacker:SetParasited(self)
end