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
    self.bountyCurrentLife = 0
    return bounty
end

function ScoringMixin:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint)
    if not self.kReceiveBountyDamage then return end
    
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
    local team = self:GetTeamNumber()
    local minClaim = 0
    if team == kMarineTeamType then
        minClaim = kBountyClaimMinMarine
    elseif team == kAlienTeamType then
        minClaim = kPResPerBountyClaimAsAlien
    end
    
    return math.max(self.bountyCurrentLife - minClaim, 0)
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
