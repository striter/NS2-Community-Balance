
local baseInitialized = PlayingTeam.Initialize
function PlayingTeam:Initialize(teamName, teamNumber)
    self.maxSupply = kStartSupply
    baseInitialized(self,teamName,teamNumber)
end

local baseOnInitialized = PlayingTeam.OnInitialized
function PlayingTeam:OnInitialized()
    self.maxSupply = kStartSupply
    self.floatingResourceIncome = 0
    baseOnInitialized(self)
end

function PlayingTeam:GetSupplyUsed()
    return Clamp(self.supplyUsed, 0, self:GetMaxSupply())
end

function PlayingTeam:GetMaxSupply()
    return self.maxSupply
end

function PlayingTeam:AddMaxSupply(supplyIncrease)
    self.maxSupply = self.maxSupply + supplyIncrease
end

function PlayingTeam:RemoveMaxSupply(supplyDecrease)
    self.maxSupply = self.maxSupply - supplyDecrease
end

function PlayingTeam:AddSupplyUsed(supplyUsed)
    self.supplyUsed = self.supplyUsed + supplyUsed
end

function PlayingTeam:RemoveSupplyUsed(supplyUsed)
    self.supplyUsed = self.supplyUsed - supplyUsed
end

function PlayingTeam:Update()

    PROFILE("PlayingTeam:Update")

    self:UpdateTechTree()

    self:UpdateVotes()

    local gameStarted = GetGamerules():GetGameStarted()
    local warmupActive = GetWarmupActive()
    if gameStarted or warmupActive then

        if gameStarted then
            self:UpdateResTick()
        else
            self:RespawnAllDeadPlayer()
        end

    end

end

function PlayingTeam:OnTeamKill(techID,bountyScore)
    local tResReward = kTechDataTeamResOnKill[techID]
    if tResReward then
        self:AddTeamResources(tResReward,true)      --Treat this as income
    end

    local refundBase = self:GetRefundBase() 
    if refundBase > kTeamResourceRefundBase then
        local percentage = kTechDataTeamResRefundPercentageOnKill[techID] or 0
        
        local refund = math.min(math.floor(refundBase * percentage), kTeamResourceMaxRefund)
        local pResPerRefund = self:GetResourcesPerRefund()
        self:CollectTeamResources(refund ,refund * pResPerRefund)  --Refund
    end

    local pResReward = 0
    if bountyScore > 0 then
        local pResClaimPerBounty = (self:GetTeamType() == kAlienTeamType and kPResPerBountyClaimAsAlien or kPResPerBountyClaimAsMarine)
        pResReward = bountyScore * pResClaimPerBounty
    end
    return pResReward
end

function PlayingTeam:GetResourcesPerRefund()
    assert(true,"Override this please")
end

function PlayingTeam:AddTeamResources(amount, isIncome)
    local teamResourceDelta = amount
    teamResourceDelta = teamResourceDelta + self.floatingResourceIncome
    self.floatingResourceIncome = teamResourceDelta % 1
    teamResourceDelta = teamResourceDelta - self.floatingResourceIncome

    if teamResourceDelta > 0 and isIncome then
        self.totalTeamResourcesCollected = self.totalTeamResourcesCollected + teamResourceDelta
    end
    self:SetTeamResources(self.teamResources + teamResourceDelta)
end

function PlayingTeam:UpdateResTick()

    local time = Shared.GetTime()
    if not self.lastTimeCollectResources then
        self.lastTimeCollectResources = time
    end
    
    if self.lastTimeCollectResources + kResourceTowerResourceInterval < Shared.GetTime() then
        self.lastTimeCollectResources = time

        local rtActiveCount = 0
        local rts = GetEntitiesForTeam("ResourceTower", self:GetTeamNumber())
        for _, rt in ipairs(rts) do
            if rt:GetIsAlive() and rt:GetIsCollecting() then
                rtActiveCount = rtActiveCount + 1
            end
        end

        local rtAboveThreshold = math.max( rtActiveCount - kMaxEfficiencyTowers,0)
        local rtInsideThreshold = math.min(rtActiveCount,kMaxEfficiencyTowers)
        local teamResourceToCollect = rtInsideThreshold * kTeamResourceEachTower + rtAboveThreshold * kTeamResourceEachTowerAboveThreshold
        local playerResourceToCollect = rtInsideThreshold * kPlayerResEachTower + rtAboveThreshold * kPlayerResEachTowerAboveThreshold
        if rtActiveCount <= 0 then
            teamResourceToCollect = kTeamResourceWithoutTower
        end
        self:CollectTeamResources(teamResourceToCollect,playerResourceToCollect)
    end
end

function PlayingTeam:CollectTeamResources(teamRes,playerRes)
    if teamRes > 0 then
        self:AddTeamResources(teamRes,true)
    end
    if playerRes > 0 then
        for _, player in ipairs(GetEntitiesForTeam("Player", self:GetTeamNumber())) do
            if not player:isa("Commander") then
                player:AddResources(playerRes)
            end
        end
    end
end

function PlayingTeam:GetRefundBase()
    local enemyTeam = GetGamerules():GetTeam(GetEnemyTeamNumber(self:GetTeamType()))
    if enemyTeam then
        return math.max((enemyTeam:GetTotalTeamResources() or 0) - (self:GetTotalTeamResources() or 0),0)
    end
    return 0
end

local oldGetIsResearchRelevant = debug.getupvaluex(PlayingTeam.OnResearchComplete, "GetIsResearchRelevant")
local relevantResearchIds
local function extGetIsResearchRelevant(techId)

    if not relevantResearchIds then
        relevantResearchIds = {}

        relevantResearchIds[kTechId.MilitaryProtocol] = 1
        
        relevantResearchIds[kTechId.StandardSupply] = 1
        relevantResearchIds[kTechId.LightMachineGunUpgrade] = 2
        relevantResearchIds[kTechId.DragonBreath] = 2
        relevantResearchIds[kTechId.CannonTech] = 2

        relevantResearchIds[kTechId.GrenadeLauncherUpgrade] = 2
        --relevantResearchIds[kTechId.ExplosiveSupply] = 1
        --relevantResearchIds[kTechId.GrenadeLauncherDetectionShot] = 2
        --relevantResearchIds[kTechId.GrenadeLauncherAllyBlast] = 2

        relevantResearchIds[kTechId.ElectronicSupply] = 1
        relevantResearchIds[kTechId.ElectronicStation] = 1
        relevantResearchIds[kTechId.MACEMPBlast] = 2
        relevantResearchIds[kTechId.PoweredExtractorTech] = 2

        relevantResearchIds[kTechId.ArmorSupply] = 1
        relevantResearchIds[kTechId.MinesUpgrade] = 2
        relevantResearchIds[kTechId.LifeSustain] = 2
        relevantResearchIds[kTechId.ArmorRegen] = 2
        relevantResearchIds[kTechId.CombatBuilderTech] = 2

        relevantResearchIds[kTechId.Devour] = 1
        relevantResearchIds[kTechId.XenocideFuel] = 1
        relevantResearchIds[kTechId.AcidSpray] = 1
        
        relevantResearchIds[kTechId.ShiftTunnel] = 1
        relevantResearchIds[kTechId.ShadeTunnel] = 1
        relevantResearchIds[kTechId.CragTunnel] = 1
    end

    local relevant = relevantResearchIds[techId]
    if relevant ~= nil then
        return relevant
    end

    return oldGetIsResearchRelevant(techId)
end
debug.setupvaluex(PlayingTeam.OnResearchComplete, "GetIsResearchRelevant", extGetIsResearchRelevant)
