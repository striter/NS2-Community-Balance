
if Server then
    local kNoConstructPoints = debug.getupvaluex(PointGiverMixin.OnConstruct, "kNoConstructPoints")
    table.insert(kNoConstructPoints, "Sentry")
    table.insert(kNoConstructPoints, "Hydra")

    function PointGiverMixin:PreOnKill(attacker, doer, point, direction)

        if self.isHallucination then
            return
        end

        local totalDamageDone = self:GetMaxHealth() + self:GetMaxArmor() * 2
        local points = self:GetPointValue()

        local selfIsPlayer = self:isa("Player")
        local attackerIsPlayer = attacker and attacker:isa("Player")
        local selfIsExtractor = self:isa("Extractor") or self:isa("ResourceTower")

        local pResReward = 0
        local tResReward = 0
        if selfIsExtractor then
            local attackerIsMarineTeam = attacker:GetTeamNumber() == kMarineTeamType
            pResReward = attackerIsMarineTeam and kMarinePresPerResKill or kAlienPresPerResKill
            tResReward = attackerIsMarineTeam and kMarineTresPerResKill or kAlienTresPerResKill
        end

        -- award partial res and score to players who assisted
        for _, attackerId in ipairs(self.damagePoints.attackers) do

            local currentAttacker = Shared.GetEntity(attackerId)
            if currentAttacker and HasMixin(currentAttacker, "Scoring") then

                local damageDone = self.damagePoints[attackerId]
                local damageFraction = Clamp(damageDone / totalDamageDone, 0, 1)
                local scoreReward = points >= 1 and math.max(1, math.round(points * damageFraction)) or 0

                local resReward = pResReward * damageFraction
                currentAttacker:AddScore(scoreReward, resReward, attacker == currentAttacker)
                currentAttacker:AddResources(resReward)

                if selfIsPlayer and currentAttacker ~= attacker then
                    currentAttacker:AddAssistKill()
                end

            end

        end

        if selfIsPlayer and attacker and GetAreEnemies(self, attacker) then

            if attackerIsPlayer then
                attacker:AddKill()
            end

            attacker:GetTeam():AddTeamResources(tResReward,true) -- pve kills count
        end

    end
end