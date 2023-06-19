debug.appendtoenum(kPlayerStatus, "Devoured")
debug.appendtoenum(kPlayerStatus, "Prowler")
debug.appendtoenum(kPlayerStatus, "ProwlerEgg")
debug.appendtoenum(kPlayerStatus, "Revolver")
debug.appendtoenum(kPlayerStatus, "SubMachineGun")
debug.appendtoenum(kPlayerStatus, "LightMachineGun")
debug.appendtoenum(kPlayerStatus, "Cannon")

debug.appendtoenum(kPlayerStatus, "Vokex")
debug.appendtoenum(kPlayerStatus, "VokexEgg")

debug.appendtoenum(kDeathMessageIcon, "Devour")
debug.appendtoenum(kDeathMessageIcon, "Volley")
debug.appendtoenum(kDeathMessageIcon, "Rappel")
debug.appendtoenum(kDeathMessageIcon, "AcidSpray")
debug.appendtoenum(kDeathMessageIcon, "Revolver")
debug.appendtoenum(kDeathMessageIcon, "SubMachineGun")
debug.appendtoenum(kDeathMessageIcon, "Cannon")
debug.appendtoenum(kDeathMessageIcon, "LightMachineGun")
debug.appendtoenum(kDeathMessageIcon, "Knife")
debug.appendtoenum(kDeathMessageIcon, "CombatBuilder")
debug.appendtoenum(kDeathMessageIcon, "SporeMine")
debug.appendtoenum(kDeathMessageIcon, "AcidRocket")

debug.appendtoenum(kMinimapBlipType, "HeavyMarine")
debug.appendtoenum(kMinimapBlipType, "DevouredPlayer")
debug.appendtoenum(kMinimapBlipType, "Prowler")
debug.appendtoenum(kMinimapBlipType, "Vokex")
debug.appendtoenum(kMinimapBlipType, "WeaponCache")
debug.appendtoenum(kMinimapBlipType, "MarineSentry")

-- Fuck bie bie le
--zoneA:  min(max(0,x-900)/420 * 5 , 5)
--zoneB:  pow(max(0,(x-1320) / 400),2) * 3.3

function GetPlayersAboveLimit(team)
    local info = GetTeamInfoEntity(team)
    if not info then return 0 end
    return math.max(0,info.playerCount - kMatchMinPlayers)
end

function GetRespawnTimeExtend(team,_gameLength)
    --_gameLength = _gameLength * 30
    local x = _gameLength

    local respawnTA = math.max(0,x-900)/420
    respawnTA = math.min(respawnTA * 5 , 5)

    local respawnTB = math.max(0,x-1320)/ 400
    respawnTB = respawnTB * respawnTB
    respawnTB = respawnTB * 3.3

    local respawnTP = GetPlayersAboveLimit(team) * kRespawnTimeExtendPerPlayer

    return math.min(respawnTA + respawnTB , 72 ) + respawnTP
end

function GetTeamResourceRefundBase(team)
    local info = GetTeamInfoEntity(team)
    if not info then return 0 end
    return info.teamRefundResourcesBase
end