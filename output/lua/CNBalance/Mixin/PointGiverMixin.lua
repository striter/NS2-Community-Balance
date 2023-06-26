
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

        local techID = self:GetTechId()
        local pResReward = kTechDataPersonalResOnKill[techID] or 0
        local tResRefundPercentage = kTechDataTeamResRefundPercentageOnKill[techID] or 0

        if selfIsPlayer then
            local bountyKills = math.max(self:GetKillsCurrentLife() - kBountyMinKills,0)
            if bountyKills > 0 then --Claim bounty
                local presPerBountyKill =  (self:GetTeamNumber() == kAlienTeamType and kPResPerBountyKillsAsAlien or kPResPerBountyKillsAsMarine)
                pResReward = pResReward + bountyKills * presPerBountyKill
                tResRefundPercentage = tResRefundPercentage + bountyKills * kTeamResourceRefundPerBountyKills
            end
        end

        -- award partial res and score to players who assisted
        for _, attackerId in ipairs(self.damagePoints.attackers) do

            local currentAttacker = Shared.GetEntity(attackerId)
            if currentAttacker and HasMixin(currentAttacker, "Scoring") then
                if selfIsPlayer and currentAttacker ~= attacker then
                    currentAttacker:AddAssistKill()
                end

                local damageDone = self.damagePoints[attackerId]
                local damageFraction = Clamp(damageDone / totalDamageDone, 0, 1)
                local scoreReward = points >= 1 and math.max(1, math.round(points * damageFraction)) or 0

                local resReward = pResReward * damageFraction
                currentAttacker:AddScore(scoreReward, resReward, attacker == currentAttacker)
                local team = currentAttacker:GetTeam()
                if team then
                    team:AddPlayerResources(currentAttacker,resReward)
                end
            end
        end

        if attacker and GetAreEnemies(self, attacker) then -- pve kills count
            if selfIsPlayer and attacker:isa("Player") then
                attacker:AddKill()
            end
            
            local team = attacker:GetTeam()
            if team.OnTeamKill then
                team:OnTeamKill(techID)
            end
            
            if tResRefundPercentage > 0 then
                team:AddTeamRefund(tResRefundPercentage)
            end
        end
    end
end