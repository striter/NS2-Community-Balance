------------------------------------------
--
------------------------------------------

Script.Load("lua/bots/CommanderBrain.lua")
Script.Load("lua/bots/AlienCommanderBrain_Data.lua")
Script.Load("lua/bots/BotDebug.lua")
Script.Load("lua/IterableDict.lua")
Script.Load("lua/OrderedSet.lua")

local kStructureReDropDelay = 6

gBotDebug:AddBoolean("kham")

gAlienCommanderBrains = {}

------------------------------------------
--
------------------------------------------
class 'AlienCommanderBrain' (CommanderBrain)

AlienCommanderBrain.kTunnelDeathRedropDelay = 6 -- Seconds to wait before re-dropping a tunnel in a location
AlienCommanderBrain.kTunnelDropEvalInterval = 2 -- Seconds to wait before re-dropping a tunnel in a location

function AlienCommanderBrain:Initialize()

    CommanderBrain.Initialize(self)
    self.senses = CreateAlienComSenses()
    table.insert( gAlienCommanderBrains, self )

    self.structuresInDanger = OrderedSet()

    self.secondHiveShade = math.random() < 0.6

    self.timesLastTunnelDeathByLocation = {} --IterableDict()

    self.isDroppingHive = false
    self.timeDropHiveStart = 0
    self.dropHiveTechPointId = Entity.invalidId

    self.hasEnoughTechForHive = false

    self.bonewallDelay = math.random(0.5, 2)

    self.nextUpgradeStep = kTechId.None
    self.timeLastTunnelEval = 0

    self.droppedNaturalRts = false
    self.droppedUpgradeChamber = false

    -- Stored by classname : [Structure ClassName] -> Time
    -- Since it doesn't get classname itself, can cheese it
    -- and use more generic categories like "PVE" etc etc
    self.timeLastDroppedStructures = {}

    self.timesLastStructureDeathByLocation = {}

    self.currentTechpathOverride = kAlienTechPathOverrideType.None

end

function AlienCommanderBrain:GetDelayPassedForStructureRedrop(locationName)
    local timeLastStructureDeathInLocation = self.timesLastStructureDeathByLocation[locationName] or 0
    local timeSinceLastStructureDeathInLocation = Shared.GetTime() - timeLastStructureDeathInLocation
    local redropDelayPassed = timeSinceLastStructureDeathInLocation >= kStructureReDropDelay

    return redropDelayPassed
end

function AlienCommanderBrain:GetTimeSinceLastDroppedStructure(structureName)
    return Shared.GetTime() - self:GetTimeLastDroppedStructure(structureName)
end

function AlienCommanderBrain:GetTimeLastDroppedStructure(structureName)
    return self.timeLastDroppedStructures[structureName] or 0
end

function AlienCommanderBrain:SetTimeLastDroppedStructure(structureName)
    self.timeLastDroppedStructures[structureName] = Shared.GetTime()
end

function AlienCommanderBrain:SetTunnelDeathTime(tunnel)
    local tunnelLocationName = tunnel:GetLocationName()
    if tunnelLocationName and tunnelLocationName ~= "" then
        self.timesLastTunnelDeathByLocation[tunnelLocationName] = Shared.GetTime()
    end
end

function AlienCommanderBrain:GetLastTunnelDeathTime(tunnelLocationName)
    if not tunnelLocationName then return 0 end
    return self.timesLastTunnelDeathByLocation[tunnelLocationName] or 0
end

function AlienCommanderBrain:GetExpectedPlayerClass()
    return "AlienCommander"
end

function AlienCommanderBrain:GetExpectedTeamNumber()
    return kAlienTeamType
end

function AlienCommanderBrain:GetActions()
    return kAlienComBrainActions
end

function AlienCommanderBrain:GetSenses()
    return self.senses
end

function AlienCommanderBrain:GetPotentialTunnelBuildTechId( tunnelManager )     --McG: GOD this is jank...
--Utility func to manage to absurd TechID data structure of Tunnel Enterances/Exits
    assert(tunnelManager)

    if tunnelManager.entryOne == Entity.invalidId then
        return kTechId.BuildTunnelEntryOne
    elseif tunnelManager.exitOne == Entity.invalidId then
        return kTechId.BuildTunnelExitOne

    elseif tunnelManager.entryTwo == Entity.invalidId then
        return kTechId.BuildTunnelEntryTwo
    elseif tunnelManager.exitTwo == Entity.invalidId then
        return kTechId.BuildTunnelExitTwo

    elseif tunnelManager.entryThree == Entity.invalidId then
        return kTechId.BuildTunnelEntryThree
    elseif tunnelManager.exitThree == Entity.invalidId then
        return kTechId.BuildTunnelExitThree

    elseif tunnelManager.entryFour == Entity.invalidId then
        return kTechId.BuildTunnelEntryFour
    elseif tunnelManager.exitFour == Entity.invalidId then
        return kTechId.BuildTunnelExitFour
    end
    
    return kTechId.None
end


function AlienCommanderBrain:GetTunnelBuildTechTechIdForEmptyPair( tunnelManager, doables )
    --Log("\t\t\tGet Empty Pair Tunnel TechId")

    assert(tunnelManager)

--[[    Log("\t\t\t\tTunnel Entries")
    Log("\t\t\t\t\t1 - Exit: %s, Exit: %s, Doable: %s", tunnelManager.entryOne, tunnelManager.exitOne, doables[kTechId.BuildTunnelEntryOne])
    Log("\t\t\t\t\t2 - Exit: %s, Exit: %s, Doable: %s", tunnelManager.entryTwo, tunnelManager.exitTwo, doables[kTechId.BuildTunnelEntryTwo])
    Log("\t\t\t\t\t3 - Exit: %s, Exit: %s, Doable: %s", tunnelManager.entryThree, tunnelManager.exitThree, doables[kTechId.BuildTunnelEntryThree])
    Log("\t\t\t\t\t4 - Exit: %s, Exit: %s, Doable: %s", tunnelManager.entryFour, tunnelManager.exitFour, doables[kTechId.BuildTunnelEntryFour])]]

    if tunnelManager.entryOne == Entity.invalidId and tunnelManager.exitOne == Entity.invalidId and doables[kTechId.BuildTunnelEntryOne] then
        return kTechId.BuildTunnelEntryOne
    elseif tunnelManager.entryTwo == Entity.invalidId and tunnelManager.exitTwo == Entity.invalidId and doables[kTechId.BuildTunnelEntryTwo] then
        return kTechId.BuildTunnelEntryTwo
    elseif tunnelManager.entryThree == Entity.invalidId and tunnelManager.exitThree == Entity.invalidId and doables[kTechId.BuildTunnelEntryThree] then
        return kTechId.BuildTunnelEntryThree
    elseif tunnelManager.entryFour == Entity.invalidId and tunnelManager.exitFour == Entity.invalidId and doables[kTechId.BuildTunnelEntryFour] then
        return kTechId.BuildTunnelEntryFour
    end

    return kTechId.None
end

function AlienCommanderBrain:Update(bot, move)
    PROFILE("AlienCommanderBrain:Update")

    CommanderBrain.Update(self, bot, move)

    ------------------------------------------
    --  Do per-frame debugging here
    ------------------------------------------

    if gBotDebug:Get("kham") then

        local sdb = self:GetSenses()
        local rp = sdb:Get("resPointToInfest")
        local ofs = Vector(0,1,0)

        if rp ~= nil and sdb:Get("lastInfestorPos") ~= nil then
            DebugLine( rp:GetOrigin()+ofs, sdb:Get("lastInfestorPos")+ofs, 0.0,
                0,0,1,1,  true )
            if sdb:Get("bestCystPos") ~= nil then
                DebugLine( sdb:Get("bestCystPos")+ofs, sdb:Get("lastInfestorPos")+ofs, 0.0,
                   0,1,1,1,  true )
            end
        end

    end


end
