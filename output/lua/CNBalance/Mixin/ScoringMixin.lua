ScoringMixin.networkVars.bountyCurrentLife = "integer"

local baseInitMixin = ScoringMixin.__initmixin
function ScoringMixin:__initmixin()
    baseInitMixin(self)
    self.bountyCurrentLife = 0
end

local baseAddKill = ScoringMixin.AddKill
function ScoringMixin:AddKill()
    baseAddKill(self)
    if GetWarmupActive() then return end
    self.bountyCurrentLife = Clamp(self.bountyCurrentLife + kBountyScoreEachKill, 0, kMaxBountyScore)
end

local baseAddAssistKill = ScoringMixin.AddAssistKill
function ScoringMixin:AddAssistKill()
    baseAddAssistKill(self)
    if GetWarmupActive() then return end
    self.bountyCurrentLife = Clamp(self.bountyCurrentLife + kBountyScoreEachAssist, 0, kMaxBountyScore)
end

function ScoringMixin:ClaimBounty()
    local bounty = self:GetBountyCurrentLife()
    local claim = math.min(bounty, kBountyMaxClaim)
    self.bountyCurrentLife = self.bountyCurrentLife - claim
    return claim
end

function ScoringMixin:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint)
    local bountyScore = self:GetBountyCurrentLife()
    if bountyScore > 0 and damageTable.damage > 0 then
        local scalar = bountyScore * (math.floor(bountyScore / kBountyTargetDamageReceiveStep)+ 1) * kBountyDamageReceiveBaseEachStep
        damageTable.damage = damageTable.damage * (1 + scalar)      --Receive Additional Damage And Die Please
    end
end

if Server then
    local baseCopyPlayerDataFrom = ScoringMixin.CopyPlayerDataFrom
    function ScoringMixin:CopyPlayerDataFrom(player)
        baseCopyPlayerDataFrom(self,player)
        self.bountyCurrentLife = player.bountyCurrentLife
    end

    local baseResetScores = ScoringMixin.ResetScores
    function ScoringMixin:ResetScores()
        baseResetScores(self)
        self.bountyCurrentLife = 0
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
