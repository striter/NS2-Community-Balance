JetpackMarine.kBountyThreshold = kBountyClaimMinJetpack
JetpackMarine.kContinuousDeathMaxDamageReduction = 0.2
-- function JetpackMarine:GetFuel()

--     local dt = Shared.GetTime() - self.timeJetpackingChanged

--     --more weight means the Jetpack has to provide more force to lift the marine and therefor consumes more fuel
--     local weightFactor = math.max( self:GetWeaponsWeight() / kJetpackWeightLiftForce, kMinWeightJetpackFuelFactor )
--     local useRate=kJetpackUseFuelRate
    
--     if GetHasTech(self,kTechId.JetpackFuelTech) then
--         useRate = kUpgradedJetpackUseFuelRate
--     end

--     local rate = -useRate * weightFactor
--     if not self.jetpacking then
--         rate = kJetpackReplenishFuelRate
--         dt = math.max(0, dt - JetpackMarine.kJetpackFuelReplenishDelay)
--     end
    
--     if self:GetDarwinMode() then
--         return 1
--     else
--         return Clamp(self.jetpackFuelOnChange + rate * dt, 0, 1)
--     end
    
-- end
JetpackMarine.kHealth = kJetpackHealth

function JetpackMarine:GetArmorAmount(armorLevels)

    local hasMP = GetHasTech(self,kTechId.MilitaryProtocol)
    if not armorLevels then

        armorLevels = 0

        if GetHasTech(self, kTechId.Armor3, true) then
            armorLevels = 3
        elseif GetHasTech(self, kTechId.Armor2, true) then
            armorLevels = 2
        elseif GetHasTech(self, kTechId.Armor1, true) then
            armorLevels = 1
        end

    end

    return hasMP and (kMPJetpackMarineArmor + armorLevels * kMPJetpackArmorPerUpgradeLevel  ) or (kJetpackArmor + armorLevels *kJetpackArmorPerUpgradeLevel)

end

--function JetpackMarine:GetIsStunAllowed()
--    return false
--end

if Server then
    function JetpackMarine:GetAutoHealPerSecond(lifeSustainResearched)
        return lifeSustainResearched and kJetpackLifeSustainHPS or kJetpackLifeRegenHPS
    end
    
    function JetpackMarine:GetAutoWeldArmorPerSecond(nanoArmorResearched)
        return nanoArmorResearched and kJetpackMarineNanoArmorPerSecond or kJetpackMarineArmorPerSecond
    end
end

function JetpackMarine:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint) -- dud
    local reduction = kJetpackDamageReduction[doer:GetClassName()]
    if reduction then
        damageTable.damage = damageTable.damage * reduction
        return
    end
end
--function JetpackMarine:OnWebbed()   --突然离世
--    if not self:GetIsOnGround() then
--        self:SetStun(kDisruptMarineTime)
--    end
--end