
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

        if attacker and GetAreEnemies(self, attacker) then -- pve kills count
            if selfIsPlayer and attacker:isa("Player") then
                attacker:AddKill()
            end

            local team = attacker:GetTeam()
            if team then
                pResReward = pResReward + team:OnTeamKill(techID,selfIsPlayer and self:ClaimBounty() or 0,true)
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
                if currentAttacker:isa("Commander") then    --Don't collect pres for commander
                    resReward = 0
                end
                
                local team = currentAttacker:GetTeam()
                if team and team.CollectAggressivePlayerResources then
                    resReward = team:CollectAggressivePlayerResources(currentAttacker,resReward)
                else
                    currentAttacker:AddResources(resReward)
                end
                
                if damageFraction > kAssistMinimumDamageFraction and selfIsPlayer and currentAttacker ~= attacker then
                    currentAttacker:AddAssistKill()
                end

                currentAttacker:AddScore(scoreReward, resReward, attacker == currentAttacker)
            end
        end
    end
end