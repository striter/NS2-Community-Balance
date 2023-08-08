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

function ScoringMixin:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint)

    if(damageTable.damage <= 0) then return end
    
    if self.kBountyDamageReceive then
        local bountyScore = self:GetBountyCurrentLife()
        if bountyScore > 0 then
            local scalar = bountyScore * (math.floor(bountyScore / kBountyTargetDamageReceiveStep)+ 1) * kBountyDamageReceiveBaseEachScore
            damageTable.damage = damageTable.damage * (1 + scalar)      --Receive Additional Damage And Die Please
        end
    end

    if attacker.kBountyDamageDecrease then
        local attackerBounty = attacker:GetBountyCurrentLife()
        if attackerBounty > 0 then
            local scalar = attackerBounty * (math.floor(attackerBounty / kBountyTargetDamageDealtStep)+ 1) * kBountyDamageDealtBaseEachScore
            damageTable.damage = damageTable.damage * math.max(1 - scalar,0)      --Receive Additional Damage And Die Please
        end
    end
end

if Server then
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
        if GetWarmupActive() then return end
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
