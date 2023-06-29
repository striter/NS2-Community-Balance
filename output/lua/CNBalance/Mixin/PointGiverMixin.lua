
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
            local bountyScore = self:GetBountyCurrentLife()  --Claim bounty
            if bountyScore > 0 then
                local presPerScore =  (self:GetTeamNumber() == kAlienTeamType and kPResPerBountyScoreAsAlien or kPResPerBountyScoreAsMarine)
                pResReward = pResReward + bountyScore * presPerScore
            end
        end

        -- award partial res and score to players who assisted
        for _, attackerId in ipairs(self.damagePoints.attackers) do

            local currentAttacker = Shared.GetEntity(attackerId)
            if currentAttacker and HasMixin(currentAttacker, "Scoring") then

                local damageDone = self.damagePoints[attackerId]
                local damageFraction = Clamp(damageDone / totalDamageDone, 0, 1)
                local scoreReward = points >= 1 and math.max(1, math.round(points * damageFraction)) or 0

                local resReward = pResReward * damageFraction

                if not currentAttacker:isa("Commander") then    --Don't collect pres for commander
                    local team = currentAttacker:GetTeam()
                    if team and team.CollectAggressivePlayerResources then
                        resReward = team:CollectAggressivePlayerResources(currentAttacker,resReward)
                    else
                        currentAttacker:AddResources(resReward)
                    end
                end
                
                if damageFraction > kAssistMinimumDamageFraction and selfIsPlayer and currentAttacker ~= attacker then
                    currentAttacker:AddAssistKill()
                end

                currentAttacker:AddScore(scoreReward, resReward, attacker == currentAttacker)
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