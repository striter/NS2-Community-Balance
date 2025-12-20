
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

local function UpdatePlayerChanges(self)
    local teamPlayers = math.max(0,self:GetNumPlayers() - kMatchMinPlayers)
    local ents = GetEntitiesWithMixinForTeam("BiomassHealth",self:GetTeamType())
    for i = 1, #ents do
        local ent = ents[i]
        if (ent.GetExtraHealth)  then
            ent:UpdateHealthAmount(teamPlayers,0)
        end
    end
end

local baseResetTeam = PlayingTeam.ResetTeam
function PlayingTeam:ResetTeam()
    local _ = baseResetTeam(self)
    UpdatePlayerChanges(self)
    return _
end

function PlayingTeam:AddPlayer(player)
    local available = Team.AddPlayer(self,player)
    UpdatePlayerChanges(self)
    return available
end

function PlayingTeam:RemovePlayer(player)
    Team.RemovePlayer(self,player)
    UpdatePlayerChanges(self)
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

    if gameStarted then
        self:UpdateDeadlock()
    end
end

function PlayingTeam:OnTeamKill(techID, _fraction)
    self:OnDeadlockExtend(techID)
    local tResReward = kTechDataTeamResOnKill[techID]
    if tResReward then
        self:AddTeamResources(tResReward * _fraction,true)      --Treat this as income
    end
    return 0
end

function PlayingTeam:AddTeamResources(amount, isIncome)
    local teamResourceDelta = amount
    if amount > 0 then
        teamResourceDelta = teamResourceDelta + self.floatingResourceIncome
        self.floatingResourceIncome = teamResourceDelta % 1
        teamResourceDelta = teamResourceDelta - self.floatingResourceIncome
    end
        
    if teamResourceDelta > 0 and isIncome then
        self.totalTeamResourcesCollected = self.totalTeamResourcesCollected + teamResourceDelta
    end
    self:SetTeamResources(self.teamResources + teamResourceDelta)
end

local baseTriggerAlert = PlayingTeam.TriggerAlert
function PlayingTeam:TriggerAlert(techId, entity, force)

    if not GetGamerules():GetGameStarted() then return false end

    if self:ShouldHandleManualAlert() then 
        if entity.HandleManualAlert and entity:HandleManualAlert(techId) then
            return
        end
    end

    return baseTriggerAlert(self,techId,entity,force)
end

function PlayingTeam:ShouldHandleManualAlert()
    return true
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

        local finalResParam = rtActiveCount

        if NS2Gamerules.kBalanceConfig.resourceEfficiency then
            local rtAboveThreshold = math.max( rtActiveCount - kMaxEfficiencyTowers,0)
            local rtInsideThreshold = math.min(rtActiveCount,kMaxEfficiencyTowers)
            finalResParam = rtInsideThreshold * 1 + rtAboveThreshold * .5
        end

        if finalResParam <= 0 then
            finalResParam = kTeamResourceWithoutTower
        end

        local pResEachRT = kPlayerResEachTower - GetPlayersAboveLimit(self:GetTeamNumber()) * kPlayerResDeductionAboveLimit

        local pRes = finalResParam * pResEachRT
        local tRes = finalResParam * kTeamResourceEachTower
        self:CollectTeamResources(tRes, pRes,rtActiveCount)
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

local oldGetIsResearchRelevant = debug.getupvaluex(PlayingTeam.OnResearchComplete, "GetIsResearchRelevant")
local relevantResearchIds
local function extGetIsResearchRelevant(techId)

    if not relevantResearchIds then
        relevantResearchIds = {}

        --relevantResearchIds[kTechId.MilitaryProtocol] = 1
        --
        --relevantResearchIds[kTechId.StandardSupply] = 1
        --relevantResearchIds[kTechId.LightMachineGunUpgrade] = 1
        --relevantResearchIds[kTechId.DragonBreath] = 1
        --relevantResearchIds[kTechId.CannonTech] = 1

        --relevantResearchIds[kTechId.GrenadeLauncherUpgrade] = 2
        --relevantResearchIds[kTechId.ExplosiveSupply] = 1
        --relevantResearchIds[kTechId.GrenadeLauncherDetectionShot] = 2
        --relevantResearchIds[kTechId.GrenadeLauncherAllyBlast] = 2

        --relevantResearchIds[kTechId.ElectronicSupply] = 1
        --relevantResearchIds[kTechId.ElectronicStation] = 1
        --relevantResearchIds[kTechId.MACEMPBlast] = 1
        --relevantResearchIds[kTechId.PoweredExtractorTech] = 1
        --
        --relevantResearchIds[kTechId.ArmorSupply] = 1
        --relevantResearchIds[kTechId.MinesUpgrade] = 1
        --relevantResearchIds[kTechId.LifeSustain] = 1
        --relevantResearchIds[kTechId.ArmorRegen] = 1
        --relevantResearchIds[kTechId.CombatBuilderTech] = 1

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

function PlayingTeam:OnGameStateChanged(_state)
    if _state == kGameState.Started then
        self.deadlockTime = Shared.GetTime() + (NS2Gamerules.kBalanceConfig.deadlockInitialTime or 99999)
        self.deadlockDamageInterval = 0
        self.deadlockBroadcastInterval = 0
    end
end

function PlayingTeam:OnDeadlockExtend(techID)
    local gameStarted = GetGamerules():GetGameStarted()
    if not gameStarted then return end
    
    local extendTime = kDeadlockTimeExtend[techID]
    if not extendTime then return end

    local now = Shared.GetTime()
    if now + extendTime > self.deadlockTime then
        self.deadlockTime = self.deadlockTime + extendTime
    end
end

function PlayingTeam:UpdateDeadlock()
    local now = Shared.GetTime()
    if now > self.deadlockTime then
        local deadlockTimeElapsed = now - self.deadlockTime
        local multiplier = math.pow(2,math.floor(deadlockTimeElapsed / 60) )
        local kDamagePercentage = 0.005 * multiplier
        if now > self.deadlockDamageInterval then
            self.deadlockDamageInterval = now + 5
            for _, target in ipairs(GetEntitiesWithMixinForTeam("Construct", self:GetTeamNumber())) do
                if not target.kIgnoreDeadlock and target.TakeDamage then
                    if not target.CanTakeDamage or target:CanTakeDamage() then
                        local maxHealth = target:GetMaxHealth()
                        local maxArmor = target:GetMaxArmor()
                        local damage = (maxHealth + maxArmor * kHealthPointsPerArmor)
                        target:TakeDamage(damage, nil, nil, nil, nil, maxArmor * kDamagePercentage, maxHealth * kDamagePercentage, kDamageType.Normal, true)
                    end
                end
            end
        end

        if now > self.deadlockBroadcastInterval then
            self.deadlockBroadcastInterval = now + 60
            SendTeamMessage(self, kTeamMessageTypes.DeadlockActivated)
            self:PlayPrivateTeamSound(self.kDeadlockAlert)
        end
    end
end

debug.setupvaluex(PlayingTeam.OnResearchComplete, "GetIsResearchRelevant", extGetIsResearchRelevant)
