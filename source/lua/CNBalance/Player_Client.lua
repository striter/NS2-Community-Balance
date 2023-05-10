function Player:GetWeaponClipSize()
    local weapon = self:GetActiveWeapon()

    if weapon then
        if weapon:isa("ClipWeapon") then
            return weapon:GetClipSize()
        end
    end

    return 0
end


function PlayerUI_GetTeamRespawnInfo()
    local teamType = PlayerUI_GetTeamType()
    local respawnCount = 0

    local teamInfo = GetTeamInfoEntity(teamType)
    if teamInfo then
        if teamType == kTeam2Index then
            respawnCount = teamInfo:GetEggCount()
        elseif teamType == kTeam1Index then
            respawnCount = teamInfo.numInfantryPortals
        end
    end

    return teamType, respawnCount

end
