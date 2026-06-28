-- RallyMarker.lua
--
-- A persistent marker entity created by the Marine Commander's DeployOrder ability.
-- Lasts 30 seconds, visible on minimap, and gives move orders to all marine players.
-- Periodically checks if each player's current move order matches the target position;
-- re-issues the order if missing or pointing elsewhere. Dead players get the order upon respawn.

Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/TeamMixin.lua")

class 'RallyMarker' (Entity)

RallyMarker.kMapName = "rallymarker"

local kLifetime = 30
local kOrderTickInterval = 2
local kOrderMatchDistance = 15

local networkVars =
{
    untilTime = "time",
    position = "position",
}
AddMixinNetworkVars(TeamMixin, networkVars)

function RallyMarker:OnCreate()

    Entity.OnCreate(self)

    self:UpdateRelevancy()

    InitMixin(self, TeamMixin)
    self.untilTime = 0
    self.position = Vector(0, 0, 0)
    self.timeLastOrder = nil

    if Server then
        self:SetUpdates(true, kDefaultUpdateRate)
    end

end

function RallyMarker:Initialize(position, teamNumber)

    self:SetTeamNumber(teamNumber)
    self.position = position
    self:SetOrigin(position + Vector(0, 0.5, 0))
    self.untilTime = Shared.GetTime() + kLifetime

    if Server then
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
    end

end

function RallyMarker:GetMapBlipType()
    return kMinimapBlipType.DeployOrder
end

function RallyMarker:GetPosition()
    return self.position
end

function RallyMarker:GetUntilTime()
    return self.untilTime
end

function RallyMarker:GetAppearDistance()
    return kMaxRelevancyDistance
end

function RallyMarker:UpdateRelevancy()

    self:SetRelevancyDistance(kMaxRelevancyDistance)

    if self.teamNumber == 1 then
        self:SetIncludeRelevancyMask(kRelevantToTeam1)
    else
        self:SetIncludeRelevancyMask(kRelevantToTeam2)
    end

end

if Server then

    function RallyMarker:PlayerHasMatchingOrder(player)
        -- Player already at destination, no need to issue order
        if (player:GetOrigin() - self.position):GetLengthXZ() < kOrderMatchDistance then
            return true
        end
        if player.GetCurrentOrder then
            local order = player:GetCurrentOrder()
            if order and order:GetType() == kTechId.Move then
                local orderPos = order:GetLocation()
                if orderPos and (orderPos - self.position):GetLengthXZ() < kOrderMatchDistance then
                    return true
                end
            end
        end
        return false
    end

    function RallyMarker:GiveOrderToPlayer(player)
        if player:GetIsAlive() and not player:isa("Spectator") and not player:isa("Commander") then
            player:GiveOrder(kTechId.Move, nil, self.position, nil, true, true)
        end
    end

    -- Called by InfantryPortal when a player respawns
    function RallyMarker:OnPlayerRespawn(player)
        if self.untilTime > Shared.GetTime() then
            self:GiveOrderToPlayer(player)
        end
    end

    function RallyMarker:OnUpdate()

        -- Expire after lifetime
        if self.untilTime <= Shared.GetTime() then
            DestroyEntity(self)
            return
        end

        -- Periodically re-issue orders to players whose current move order doesn't match
        local now = Shared.GetTime()
        if not self.timeLastOrder or now - self.timeLastOrder > kOrderTickInterval then
            self.timeLastOrder = now

            local teamNumber = self:GetTeamNumber()
            local players = GetEntitiesForTeam("Player", teamNumber)
            for _, player in ipairs(players) do
                if not self:PlayerHasMatchingOrder(player) then
                    self:GiveOrderToPlayer(player)
                end
            end
        end

    end

end

Shared.LinkClassToMap("RallyMarker", RallyMarker.kMapName, networkVars)
