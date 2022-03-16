Shared.RegisterNetworkMessage("DevourEscape", {})

function OnCommandScores(scoreTable)

    local status = kPlayerStatus[scoreTable.status]
    if scoreTable.status == kPlayerStatus.Hidden then
        status = "-"
    elseif scoreTable.status == kPlayerStatus.Dead then
        status = Locale.ResolveString("STATUS_DEAD")
    elseif scoreTable.status == kPlayerStatus.Evolving then
        status = Locale.ResolveString("STATUS_EVOLVING")
    elseif scoreTable.status == kPlayerStatus.Embryo then
        status = Locale.ResolveString("STATUS_EMBRYO")
    elseif scoreTable.status == kPlayerStatus.Commander then
        status = Locale.ResolveString("STATUS_COMMANDER")
    elseif scoreTable.status == kPlayerStatus.Exo then
        status = Locale.ResolveString("STATUS_EXO")
    elseif scoreTable.status == kPlayerStatus.GrenadeLauncher then
        status = Locale.ResolveString("STATUS_GRENADE_LAUNCHER")
    elseif scoreTable.status == kPlayerStatus.Rifle then
        status = Locale.ResolveString("STATUS_RIFLE")
    elseif scoreTable.status == kPlayerStatus.HeavyMachineGun then
        status = Locale.ResolveString("STATUS_HMG")
    elseif scoreTable.status == kPlayerStatus.Shotgun then
        status = Locale.ResolveString("STATUS_SHOTGUN")
    elseif scoreTable.status == kPlayerStatus.Flamethrower then
        status = Locale.ResolveString("STATUS_FLAMETHROWER")
    elseif scoreTable.status == kPlayerStatus.Void then
        status = Locale.ResolveString("STATUS_VOID")
    elseif scoreTable.status == kPlayerStatus.Spectator then
        status = Locale.ResolveString("STATUS_SPECTATOR")
    elseif scoreTable.status == kPlayerStatus.Skulk then
        status = Locale.ResolveString("STATUS_SKULK")
    elseif scoreTable.status == kPlayerStatus.Gorge then
        status = Locale.ResolveString("STATUS_GORGE")
    elseif scoreTable.status == kPlayerStatus.Lerk then
        status = Locale.ResolveString("STATUS_LERK")
    elseif scoreTable.status == kPlayerStatus.Fade then
        status = Locale.ResolveString("STATUS_FADE")
    elseif scoreTable.status == kPlayerStatus.Onos then
        status = Locale.ResolveString("STATUS_ONOS")
    elseif scoreTable.status == kPlayerStatus.SkulkEgg then
        status = Locale.ResolveString("SKULK_EGG")
    elseif scoreTable.status == kPlayerStatus.GorgeEgg then
        status = Locale.ResolveString("GORGE_EGG")
    elseif scoreTable.status == kPlayerStatus.LerkEgg then
        status = Locale.ResolveString("LERK_EGG")
    elseif scoreTable.status == kPlayerStatus.FadeEgg then
        status = Locale.ResolveString("FADE_EGG")
    elseif scoreTable.status == kPlayerStatus.OnosEgg then
        status = Locale.ResolveString("ONOS_EGG")
    elseif scoreTable.status == kPlayerStatus.Devoured then
        status = Locale.ResolveString("STATUS_DEVOURED")
    end

    Scoreboard_SetPlayerData(scoreTable.clientId, scoreTable.entityId, scoreTable.playerName, scoreTable.teamNumber, scoreTable.score,
            scoreTable.kills, scoreTable.deaths, math.floor(scoreTable.resources), scoreTable.isCommander, scoreTable.isRookie,
            status, scoreTable.isSpectator, scoreTable.assists, scoreTable.clientIndex)

end
