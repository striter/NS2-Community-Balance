JetpackMarine.kBountyThreshold = kBountyClaimMinJetpack
JetpackMarine.kKDRatioMaxDamageReduction = 0.2
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

    return hasMP and (kMPJetpackMarineArmor + armorLevels * kMPJetpackArmorPerUpgradeLevel  ) 
    or (kJetpackArmor + armorLevels *kJetpackArmorPerUpgradeLevel)

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

local kFlySpeed = 9
local kFlyAcceleration = 28
function JetpackMarine:ModifyVelocity(input, velocity, deltaTime)

    if self:GetIsJetpacking() then

        local verticalAccel = 22 

        if self:GetIsWebbed() then
            verticalAccel = 5
        elseif input.move:GetLength() == 0 then
            verticalAccel = 26
        end

        self.onGround = false
        local thrust = math.max(0, -velocity.y) / 6
        velocity.y = math.min(5, velocity.y + verticalAccel * deltaTime * (1 + thrust * 2.5))

    end

    if not self.onGround then

        -- do XZ acceleration
        local prevXZSpeed = velocity:GetLengthXZ()
        local maxSpeedTable = { maxSpeed = math.max(kFlySpeed - math.max(self:GetWeaponsWeight() - kRifleWeight , 0) * 33, prevXZSpeed) }       --multiplier per 0.01 weight above
        self:ModifyMaxSpeed(maxSpeedTable)
        local maxSpeed = maxSpeedTable.maxSpeed

        if not self:GetIsJetpacking() then
            maxSpeed = prevXZSpeed
        end

        local wishDir = self:GetViewCoords():TransformVector(input.move)
        local acceleration = 0
        wishDir.y = 0
        wishDir:Normalize()

        acceleration = kFlyAcceleration
        acceleration = acceleration

        velocity:Add(wishDir * acceleration * self:GetInventorySpeedScalar() * deltaTime)

        if velocity:GetLengthXZ() > maxSpeed then

            local yVel = velocity.y
            velocity.y = 0
            velocity:Normalize()
            velocity:Scale(maxSpeed)
            velocity.y = yVel

        end

        if self:GetIsJetpacking() then
            velocity:Add(wishDir * kJetpackingAccel * deltaTime)
        end

    end

end