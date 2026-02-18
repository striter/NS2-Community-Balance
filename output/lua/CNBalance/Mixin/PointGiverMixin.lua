
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

        local _techID = self:GetTechId()
        local resRewardFraction = 1
        if selfIsPlayer and Shine then
            local npEnabled, np = Shine:IsExtensionEnabled( "newcomerprotection" )
            if npEnabled then
                resRewardFraction = 1 - np:GetRefundPercent(self)
            end
        end
        
        local pResReward = (kTechDataPersonalResOnKill[_techID] or 0)* resRewardFraction
        --Shared.Message(EnumToString(kTechId, _techID) .. " " .. tostring(pResReward))

        if attacker and GetAreEnemies(self, attacker) then -- pve kills count
            if selfIsPlayer and attacker:isa("Player") then
                attacker:AddKill()
            end

            local attackerTeam = attacker:GetTeam()
            if attackerTeam then
                if selfIsPlayer then
                    self:ClaimBounty()
                end
                pResReward = pResReward + attackerTeam:OnTeamKill(self,doer,_techID, resRewardFraction)
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
                local isKiller = attacker == currentAttacker
                if isKiller and team and team.CollectKillReward then
                    resReward = resReward + team:CollectKillReward(_techID,resRewardFraction)
                end
                
                resReward = currentAttacker:AddResources(resReward,true)
                
                if damageFraction > kAssistMinimumDamageFraction and selfIsPlayer and currentAttacker ~= attacker then
                    currentAttacker:AddAssistKill()
                end

                currentAttacker:AddScore(scoreReward, resReward, isKiller)
            end
        end
    end
end