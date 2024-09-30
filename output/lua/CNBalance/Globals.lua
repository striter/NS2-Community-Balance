kSuicideDelay = 10

kNS2PlusPlayTestItemId = 9002

debug.appendtoenum(kPlayerStatus, "Devoured")
debug.appendtoenum(kPlayerStatus, "Axe")
debug.appendtoenum(kPlayerStatus, "Knife")
debug.appendtoenum(kPlayerStatus, "Welder")

debug.appendtoenum(kPlayerStatus, "Pistol")
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
debug.appendtoenum(kDeathMessageIcon, "TeamBuildAbility")
debug.appendtoenum(kDeathMessageIcon, "AcidRocket")
debug.appendtoenum(kDeathMessageIcon, "ShadowStep")

debug.appendtoenum(kMinimapBlipType, "HeavyMarine")
debug.appendtoenum(kMinimapBlipType, "DevouredPlayer")
debug.appendtoenum(kMinimapBlipType, "BioformSuppressor")

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
local kEndGameTolerance = 900

function GetRespawnTimeExtend(player,teamIndex, _gameLength)
    --_gameLength = _gameLength * 60
    local x = _gameLength
    --
    local respawnParam =  math.Clamp(math.max(0,x - kEndGameBegin) / kEndGameTolerance,0,1)
    respawnParam = respawnParam * respawnParam
    local respawnExtension =  Lerp(0,20,respawnParam)

    local teamExtension = math.max(GetPlayersAboveLimit(teamIndex) - 2,0) * 1
    for k,v in pairs(kTechRespawnTimeExtension) do
        if GetHasTech(player,k) then
            teamExtension = teamExtension + v
        end
    end
    
    return respawnExtension + teamExtension
end
