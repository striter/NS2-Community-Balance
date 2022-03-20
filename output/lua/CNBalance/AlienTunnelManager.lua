

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

function AlienTunnelManager:GetTechAllowed(techId)
    local techIndex = techId - kTechId.BuildTunnelEntryOne -- index from 0 to 7

    local allowed = true
    local canAfford = true

    if techIndex < 8 then
        local teamInfo = GetTeamInfoEntity(self:GetTeamNumber())
        local numHives = teamInfo:GetNumCapturedTechPoints()

        if numHives == 0 then
            return true,true
        end
        
        local otherIndex
        if techIndex < 4 then
            otherIndex = techIndex + 4
        else
            otherIndex = techIndex - 4
        end
        -----------
        local maxTunnels=kMaxTunnelCount[numHives]
        if self[buttonIndexToNetVarMap[otherIndex + 1]] ~= 0 then -- map index from 1 to 8, so we have to shift by 1
            allowed = maxTunnels > self.numTunnels
        else
            allowed = maxTunnels > (techIndex % 4) and maxTunnels > self.numTunnels
        end
        --------
        canAfford = teamInfo:GetTeamResources() >= GetCostForTech(techId)
    end

    return allowed, canAfford
end
