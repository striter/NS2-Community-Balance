--[[
    lua/AlienTunnelManager.lua
]]
class 'AlienTunnelManager' (ScriptActor)

AlienTunnelManager.kMapName = "alientunnelmanager"

local networkVars = {
    entryOne = "entityid",
    entryTwo = "entityid",
    entryThree = "entityid",
    entryFour = "entityid",
    exitOne = "entityid",
    exitTwo = "entityid",
    exitThree = "entityid",
    exitFour = "entityid",
}

AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)

function AlienTunnelManager:OnCreate()
    ScriptActor.OnCreate(self)

    InitMixin(self, TeamMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, EntityChangeMixin)

    self.tunnelEntIdToIndex = {}
    self.numTunnels = 0
end

local buttonIndexToNetVarMap = {
    "entryOne",
    "entryTwo",
    "entryThree",
    "entryFour",
    "exitOne",
    "exitTwo",
    "exitThree",
    "exitFour",
}

function AlienTunnelManager:GetTechButtons()
    local techButtons = { kTechId.BuildTunnelEntryOne, kTechId.BuildTunnelEntryTwo, kTechId.BuildTunnelEntryThree, kTechId.BuildTunnelEntryFour,
                          kTechId.BuildTunnelExitOne, kTechId.BuildTunnelExitTwo, kTechId.BuildTunnelExitThree, kTechId.BuildTunnelExitFour }

    local selectButtons = { kTechId.SelectTunnelEntryOne, kTechId.SelectTunnelEntryTwo, kTechId.SelectTunnelEntryThree, kTechId.SelectTunnelEntryFour,
                            kTechId.SelectTunnelExitOne, kTechId.SelectTunnelExitTwo, kTechId.SelectTunnelExitThree, kTechId.SelectTunnelExitFour }

    self.numTunnels = 0
    for i = 1, #techButtons do
        if self[buttonIndexToNetVarMap[i]] ~= 0 then
            techButtons[i] = selectButtons[i]
            if i > 4 and techButtons[i-4] == selectButtons[i-4] then
                self.numTunnels = self.numTunnels + 1
            end
        end
    end

    return techButtons
end

function AlienTunnelManager:GetTechAllowed(techId)
    local techIndex = techId - kTechId.BuildTunnelEntryOne -- index from 0 to 7

    local allowed = true
    local canAfford = true

    if techIndex < 8 then
        local teamInfo = GetTeamInfoEntity(self:GetTeamNumber())
        local numHives = teamInfo:GetNumCapturedTechPoints()

        local otherIndex
        if techIndex < 4 then
            otherIndex = techIndex + 4
        else
            otherIndex = techIndex - 4
        end
        
        local maxTunnels=kMaxTunnelCount[numHives]
        if self[buttonIndexToNetVarMap[otherIndex + 1]] ~= 0 then -- map index from 1 to 8, so we have to shift by 1
            allowed = maxTunnels > self.numTunnels
        else
            allowed = maxTunnels > (techIndex % 4) and maxTunnels > self.numTunnels
        end

        canAfford = teamInfo:GetTeamResources() >= GetCostForTech(techId)
    end

    return allowed, canAfford
end

function AlienTunnelManager:CreateTunnelEntrance(position, techId, otherEntrance)
    if not techId and not otherEntrance then return end

    local techIndex
    if techId then
        techIndex = techId - kTechId.BuildTunnelEntryOne
        local otherIndex

        if techIndex > 7 then return end

        if techIndex < 4 then
            otherIndex = techIndex + 4
        else
            otherIndex = techIndex - 4
        end

        local otherEntranceId = self[buttonIndexToNetVarMap[otherIndex+1]]
        otherEntrance = otherEntranceId ~= 0 and Shared.GetEntity(otherEntranceId)
    else
        local otherId = otherEntrance:GetId()
        local otherIndex = self.tunnelEntIdToIndex[otherId] - 1

        if otherIndex < 4 then
            techIndex = otherIndex + 4
        else
            techIndex = otherIndex - 4
        end
    end

    local newTunnelEntrance = CreateEntity(TunnelEntrance.kMapName, position, self:GetTeamNumber())

    local id = newTunnelEntrance:GetId()
    self[buttonIndexToNetVarMap[techIndex + 1]] = id
    self.tunnelEntIdToIndex[id] = techIndex + 1

    if otherEntrance then
        if otherEntrance:GetTechId() == kTechId.InfestedTunnel then
            newTunnelEntrance:UpgradeToTechId(kTechId.InfestedTunnel)
        end

        newTunnelEntrance:SetOtherEntrance(otherEntrance)
    end

    return newTunnelEntrance
end

function AlienTunnelManager:GetTunnelEntrance(techId)

    local techIndex = techId - kTechId.SelectTunnelEntryOne + 1
    if techIndex > 8 then return end

    local entranceId = self[buttonIndexToNetVarMap[techIndex]]
    local entrance = entranceId ~= 0 and Shared.GetEntity(entranceId)

    return entrance
end

function AlienTunnelManager:GetIsMapEntity()
    return true
end

function AlienTunnelManager:OnEntityChange(oldId, newId)
    local index = self.tunnelEntIdToIndex[oldId]
    if index then
        self.tunnelEntIdToIndex[oldId] = nil
        if self[buttonIndexToNetVarMap[index]] == oldId then -- make sure we do not override a relocated entrance
            self[buttonIndexToNetVarMap[index]] = newId or 0
        end
    end
end

function AlienTunnelManager:GetTechId()
    return kTechId.BuildTunnelMenu
end

Shared.LinkClassToMap("AlienTunnelManager", AlienTunnelManager.kMapName, networkVars)
