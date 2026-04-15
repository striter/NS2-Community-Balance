
Script.Load("lua/bots/CommanderBrain.lua")
Script.Load("lua/bots/MarineCommanderBrain_Data.lua")
Script.Load("lua/bots/BotDebug.lua")
Script.Load("lua/IterableDict.lua")
Script.Load("lua/OrderedIterableDict.lua")
Script.Load("lua/OrderedSet.lua")

gBotDebug:AddBoolean("mcom")

gMarineCommanderBrains = {}

------------------------------------------
--
------------------------------------------
class 'MarineCommanderBrain' (CommanderBrain)

MarineCommanderBrain.kUpgradeActionDelay = 1.5

function MarineCommanderBrain:Initialize()

    CommanderBrain.Initialize(self)
    self.senses = CreateMarineComSenses()
    table.insert( gMarineCommanderBrains, self )

    -- Location Name -> Last Poof Time
    -- Updated in GhostStructureMixin
    self.structurePoofTimes = IterableDict()

    -- Keeps track of times we either gave a player
    -- a catpack or nanoshield
    self.lastServedSupportPack = IterableDict()

    self.timeLastMACManage = 0

    self.nextTechStepId = kTechId.None

    self.nextBeaconTime = 0
    self.timeNextScan = 0

    -- Player Ent Id -> Droppack TechId (Medpack/AmmoPack) = LastServedData: Table [time, count]
    self.lastDropPack = {}

    self.timeNextExtractorDrop = 0
    self.hasDroppedNaturalRTs = false

    self.secondMedpackTargets = OrderedIterableDict()
    self.timeNextUpgradeAction = 0

    self.currentTechpathOverride = kMarineTechPathOverrideType.None -- TODO(Salads): Bots - Use this to stop certain actions? (kMarineTechPathOverride.Shotguns)
    self.timeLastSavingMessage = 0 -- Used for medpacks/ammopacks

end

function MarineCommanderBrain:GetIsProcessingTechPathOverride()
    return self.currentTechpathOverride ~= kMarineTechPathOverrideType.None
end

function MarineCommanderBrain:OnEntityChange(oldId, newId)

    if oldId then
        self:ClearLastServedDroppackData(oldId, kTechId.MedPack)
        self:ClearLastServedDroppackData(oldId, kTechId.AmmoPack)
        self.lastServedSupportPack[oldId] = nil
        self.secondMedpackTargets[oldId] = nil
    end

end

function MarineCommanderBrain:GetLastServedDroppackData(playerEntId, droppackTechId)
    if not self.lastDropPack[playerEntId] then
        self.lastDropPack[playerEntId] = {}
    end

    if not self.lastDropPack[playerEntId][droppackTechId] then
        self.lastDropPack[playerEntId][droppackTechId] =
        {
            time = 0,
            count = 0,
        }
    end

    return self.lastDropPack[playerEntId][droppackTechId]
end

function MarineCommanderBrain:IncrementLastServedDroppackData(playerEntId, droppackTechId)
    if not self.lastDropPack[playerEntId] then
        self.lastDropPack[playerEntId] = {}
    end

    if not self.lastDropPack[playerEntId][droppackTechId] then
        self.lastDropPack[playerEntId][droppackTechId] =
        {
            time = 0,
            count = 0,
        }
    end

    local lastServedTable = self.lastDropPack[playerEntId][droppackTechId]

    lastServedTable.time = Shared.GetTime()
    lastServedTable.count = lastServedTable.count + 1

end

function MarineCommanderBrain:ClearLastServedDroppackData(playerEntId, droppackTechId)

    if not self.lastDropPack[playerEntId] then
        return
    end

    if not self.lastDropPack[playerEntId][droppackTechId] then
        return
    end

    local lastServedTable = self.lastDropPack[playerEntId][droppackTechId]

    lastServedTable.time = 0
    lastServedTable.count = 0

end

function MarineCommanderBrain:GetLastSupportPackTime(targetEntId)
    return self.lastServedSupportPack[targetEntId] or 0
end

function MarineCommanderBrain:SetLastSupportPackTime(targetEntId)
    self.lastServedSupportPack[targetEntId] = Shared.GetTime()
end

function MarineCommanderBrain:GetLastPoofTime(locationName)
    return self.structurePoofTimes[locationName] or 0
end

function MarineCommanderBrain:SetLastPoofTime(locationName)
    self.structurePoofTimes[locationName] = Shared.GetTime()
end

function MarineCommanderBrain:GetExpectedPlayerClass()
    return "MarineCommander"
end

function MarineCommanderBrain:GetExpectedTeamNumber()
    return kMarineTeamType
end

function MarineCommanderBrain:GetActions()
    return kMarineComBrainActions
end

function MarineCommanderBrain:GetSenses()
    return self.senses
end
