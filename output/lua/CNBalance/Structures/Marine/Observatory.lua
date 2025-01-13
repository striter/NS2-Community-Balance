Script.Load("lua/BiomassHealthMixin.lua")

local baseOnCreate = Observatory.OnCreate
function Observatory:OnCreate()
    baseOnCreate(self)
    InitMixin(self, BiomassHealthMixin)
end

function Observatory:GetExtraHealth(techLevel,extraPlayers,recentWins)
    return kObservatoryHealthPerPlayerAdd * extraPlayers
end


function Observatory:GetTechButtons(techId)

    if techId == kTechId.RootMenu then
        return  { kTechId.Scan, kTechId.DistressBeacon, kTechId.None, kTechId.Detector,
                    kTechId.PhaseTech, kTechId.MotionTrack, kTechId.None, kTechId.None }
    end

    return nil

end

Observatory.kBeaconVO = PrecacheAsset("sound/ns2plus.fev/comm/beacon")
local baseTriggerDistressBeacon = Observatory.TriggerDistressBeacon
function Observatory:TriggerDistressBeacon()

    local success = baseTriggerDistressBeacon(self)
    if success then
        self:GetTeam():PlayPrivateTeamSound(Observatory.kBeaconVO)
    end
    return success, not success

end


-- Check if both origins are in the location (game wise, not mapping wise since a "location" is composed of several mapping "location" entities)
local function GetIsSameLocation(CC_orig, player_orig)
    local loc1 = GetLocationForPoint(CC_orig)
    local loc2 = GetLocationForPoint(player_orig)

    if loc1 and loc2 then
        local location1_id = Shared.GetStringIndex(loc1:GetName())
        local location2_id = Shared.GetStringIndex(loc2:GetName())

        -- Log("Locations1: %s %s/%s", loc1, loc1:GetName(), location1_id)
        -- Log("Locations2: %s %s/%s", loc2, loc2:GetName(), location2_id)
        -- Log("Distance: %s", CC_orig:GetDistanceTo(player_orig))
        if location1_id == location2_id then
            return true
        end
    end

    return false
end

function Observatory:GetPlayersToBeacon(toOrigin)

    local players = {}
    local playerIds = self:GetTeam():GetPlayerIds()
    for playerId in playerIds:Iterate() do
        local player = Shared.GetEntity(playerId)
        -- Only beacon Marines (no Exo, Commander or TeamSpectator (dead player))
        if player and player:isa("Marine") then

            -- Don't respawn players that are already nearby.
            -- Log("Player location id: %s", player:GetLocationId())
            local inTheSameLocation = GetIsSameLocation(toOrigin, player:GetOrigin())
            if not inTheSameLocation then
                table.insert(players, player)
                if player:GetIsParasited() then
                    player:RemoveParasite()
                end
            end
        end

    end

    return players

end