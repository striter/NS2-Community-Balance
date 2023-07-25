debug.appendtoenum(kPlayerStatus, "Devoured")
debug.appendtoenum(kPlayerStatus, "Revolver")
debug.appendtoenum(kPlayerStatus, "SubMachineGun")
debug.appendtoenum(kPlayerStatus, "LightMachineGun")
debug.appendtoenum(kPlayerStatus, "Cannon")

debug.appendtoenum(kPlayerStatus, "Prowler")
debug.appendtoenum(kPlayerStatus, "ProwlerEgg")

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
debug.appendtoenum(kMinimapBlipType, "BabblerEgg")
debug.appendtoenum(kMinimapBlipType, "SporeMine")
debug.appendtoenum(kMinimapBlipType, "Pheromone_Defend")
debug.appendtoenum(kMinimapBlipType, "Pheromone_Threat")
debug.appendtoenum(kMinimapBlipType, "Pheromone_Expand")

function GetPlayersAboveLimit(team)
    local info = GetTeamInfoEntity(team)
    if not info then return 0 end
    return math.max(0,info.playerCount - kMatchMinPlayers)
end

local kEndGameBegin = 1200
local kEndGameTolerance = 1200

-- Fuck bie bie le
function GetRespawnTimeExtend(team,_gameLength)
    --_gameLength = _gameLength * 30
    local x = _gameLength

    local respawnParam =  math.Clamp(math.max(0,x - kEndGameBegin) / kEndGameTolerance,0,1)
    respawnParam = respawnParam * respawnParam
    local respawnExtension = Lerp(0,72,respawnParam)

    local teamExtension = math.max(GetPlayersAboveLimit(team) - 2,0) * 1
    return respawnExtension + teamExtension
end

function GetPassiveResourceEfficiency(_gameLength)
    local x = _gameLength
    
    local param =  math.Clamp(math.max(0,x - kEndGameBegin) / kEndGameTolerance,0,1)
    param = param* param
    return Lerp(1,0.25,param)
end

function GetTeamResourceRefundBase(team)
    local info = GetTeamInfoEntity(team)
    if not info then return 0 end
    return info.teamRefundResourcesBase
end