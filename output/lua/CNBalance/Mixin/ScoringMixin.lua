ScoringMixin.networkVars.bountyCurrentLife = "integer"

local kBountyCooldownTick = 2
local baseInitMixin = ScoringMixin.__initmixin
function ScoringMixin:__initmixin()
    baseInitMixin(self)
    self.bountyCurrentLife = 0
    if Server then
        self:AddTimedCallback( self.CheckBountyCooldown, kBountyCooldownTick )
    end
end

if Server then
    
    function ScoringMixin:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint)
        
        if  self.isHallucination
            or self:GetIsVirtual()
        then return end
    
        local gamerule =  GetGamerules()
        local nonRookieMode =  not gamerule or not gamerule.gameInfo or not gamerule.gameInfo:GetRookieMode()
        local rookieMode = not nonRookieMode
        --if rookieMode then return end  --Don't open without rookie mode
        
        if(damageTable.damage <= 0) then return end
    
        local damageScalar = 1
        
        local bountyScore = self:GetBountyCurrentLife()

        --Self Bounty Damage Taken Increase
        if bountyScore > 0 then   
            local scalar = bountyScore  * (0.1 / self.kBountyThreshold)
            if rookieMode then  --0-10%,20%-40%,60%-90% ...
                scalar = scalar * (math.floor(bountyScore / self.kBountyThreshold)+ 1)
            end
            damageScalar = damageScalar + scalar      --Receive Additional Damage And Die Please
        end

        --KDRatio adjustment
        if rookieMode
                and bountyScore <= 0
                and self.kKDRatioMaxDamageReduction
                and self:GetPlayerSkill() < kNoneRookieSkill
        then
            local kdRatioUnforeseen = math.floor( self.deaths - self.kills * kKDRatioClaimOnAddKill - self.assistkills * kKDRatioClaimOnAddAssist)
            if kdRatioUnforeseen > 0 then       --Low KD Player, reduce its damage taken
                local damageDecreaseParam = kdRatioUnforeseen - kKDRatioProtectionStep
                if damageDecreaseParam > 0 then
                    local scalar = math.min(damageDecreaseParam * kKDRatioProtectionEachValue,self.kKDRatioMaxDamageReduction)
                    damageScalar = damageScalar - scalar
                end
            else
                --if not self.kIgnoreKDDamageReceive then --High KD Player, increase its damage receive
                --    local damageIncreaseParam = -kdRatioUnforeseen - kKDRatioBoostStep
                --    if damageIncreaseParam > 0 then
                --        damageScalar = damageScalar + damageIncreaseParam * kKDRatioDamageIncreaseEachValue
                --    end
                --end
            end
        end

        --Bounty Damage Dealt Decrease
        if rookieMode
                and bountyScore <= 0
                and attacker.kBountyDamageDecrease 
        then
            local attackerBountyScore = attacker:GetBountyCurrentLife()
            if attackerBountyScore > 0 then   --0-5%,10%-20%,30%-45%,60%-80% ...
                local scalar = attackerBountyScore * (0.05 / attacker.kBountyThreshold)
                scalar = scalar * (math.floor(attackerBountyScore / attacker.kBountyThreshold)+ 1)
                damageScalar = damageScalar - scalar
            end
        end

        damageScalar = math.Clamp(damageScalar,0.2,5.0)        --Seems enough
        damageTable.damage = damageTable.damage * damageScalar
    end

    local baseResetScores = ScoringMixin.ResetScores
    function ScoringMixin:ResetScores()
        baseResetScores(self)
        self.bountyCurrentLife = 0
        self.bountyCooldown = 0
    end

    local baseCopyPlayerDataFrom = ScoringMixin.CopyPlayerDataFrom
    function ScoringMixin:CopyPlayerDataFrom(player)
        baseCopyPlayerDataFrom(self,player)
        self.bountyCurrentLife = player.bountyCurrentLife
        self.bountyCooldown = 0
    end

    local function AddBounty(self,value)
        --if GetWarmupActive() then return end
        local gamerule =  GetGamerules()
        if GetTeamResourceRefundBase(self:GetTeamNumber()) > kTeamResourceRefundBase then return end    --Don't increase bounty while in inferior position(?)

        self.bountyCurrentLife = Clamp(self.bountyCurrentLife + value, 0, kMaxBountyScore)
        self.bountyCooldown = 0
    end
    
    local baseAddKill = ScoringMixin.AddKill
    function ScoringMixin:AddKill()
        baseAddKill(self)
        AddBounty(self,kBountyScoreEachKill)
    end

    local baseAddAssistKill = ScoringMixin.AddAssistKill
    function ScoringMixin:AddAssistKill()
        baseAddAssistKill(self)
        AddBounty(self,kBountyScoreEachAssist)
    end
    
    function ScoringMixin:ClaimBounty()
        if self.bountyCurrentLife <= 0 then return 0 end
        
        local claim = math.min(self.bountyCurrentLife, math.floor(self.kBountyThreshold * kBountyClaimMultiplier))
        self.bountyCurrentLife = self.bountyCurrentLife - claim
        self.bountyCooldown = 0
        return math.max(claim - self.kBountyThreshold,0)
    end
    
    function ScoringMixin:CheckBountyCooldown()
        if self.bountyCurrentLife <= 0 then 
            return true
        end

        if self.GetIsInCombat and self:GetIsInCombat() then     --Reset it during combat
            self.bountyCooldown = 0
            return true
        end
        
        self.bountyCooldown = self.bountyCooldown + kBountyCooldownTick
        if self.bountyCooldown > kBountyCooldown then
            self.bountyCooldown = self.bountyCooldown - kBountyCooldown
            self.bountyCurrentLife = math.max(self.bountyCurrentLife - 1,0)
        end
        
        return true
    end

end

function ScoringMixin:GetBountyCurrentLife()
    assert(self.kBountyThreshold)
    return math.max(self.bountyCurrentLife - self.kBountyThreshold, 0)
end

function ScoringMixin:GetKDRatioUnforeseen()
    return math.max(
            - kKDRatioProtectionStep,0)
end

function ScoringMixin:AddContinuousScore(name, addAmount, amountNeededToScore, pointsGivenOnScore, resGivenOnScore )

    if Server then

        self.continuousScores[name] = self.continuousScores[name] or { amount = 0 }
        self.continuousScores[name].amount = self.continuousScores[name].amount + addAmount
        while self.continuousScores[name].amount >= amountNeededToScore do
            resGivenOnScore = resGivenOnScore or 0
            self:AddScore(pointsGivenOnScore, resGivenOnScore)
            self:AddResources(resGivenOnScore)
            self.continuousScores[name].amount = self.continuousScores[name].amount - amountNeededToScore

        end

    end

end
