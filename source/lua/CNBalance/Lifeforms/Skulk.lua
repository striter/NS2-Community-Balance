Skulk.kAdrenalineEnergyRecuperationRate = 30

local baseGetMaxSpeed = Skulk.GetMaxSpeed
function Skulk:GetMaxSpeed(possible)
    local maxSpeed = baseGetMaxSpeed(self,possible)
    if GetHasTech(self,kTechId.SkulkBoost) then
        maxSpeed = maxSpeed + kSkulkBoostMaxSpeed
    end
    return maxSpeed
end

local baseGetBaseHealth = Skulk.GetHealthPerBioMass
function Skulk:GetHealthPerBioMass()
    local baseHealth = baseGetBaseHealth(self)
    if GetHasTech(self,kTechId.SkulkBoost) then
        baseHealth = baseHealth+ kSkulkBoostHealthPerBiomass
    end
    return baseHealth
end


Skulk.kDamageReductionTable = {
    ["grenade"] = 0.8,
    ["pulsegrenade"] = 0.8,
    ["impactgrenade"] = 0.8,
    -- ["railgun"] = 0.7,
}

function Skulk:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint) -- dud

        local reduction = Skulk.kDamageReductionTable[string.lower(doer:GetClassName())]
        if reduction then
            damageTable.damage = damageTable.damage * reduction
            return
        end
end