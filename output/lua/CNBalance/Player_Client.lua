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


function PlayerUI_GetDeadlockTimeLeft()

    local gameInfo = GetGameInfoEntity()
    if not gameInfo then return 99999 end
    local teamNumber = PlayerUI_GetTeamNumber()
    if teamNumber ~= kTeam1Index and teamNumber ~= kTeam2Index then return 99999 end

    local state = gameInfo:GetState()
    if state ~= kGameState.PreGame and state ~= kGameState.Countdown then
        if state ~= kGameState.Started then
            return 99999
        else
            local teamInfo = GetTeamInfoEntity(teamNumber )
            if teamInfo then
                return math.floor(teamInfo.deadlockTime - Shared.GetTime())
            end
        end
    end

    return 99999

end