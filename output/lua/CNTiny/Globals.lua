--debug.appendtoenum(kSpectatorMode,"Tinyman")

function ScaledBasedSpeedMultiplier(player)
    return 0.8  + player:GetPlayerScale() * 0.2
end