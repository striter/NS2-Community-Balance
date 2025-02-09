--
--	ns2siege+ Custom Game Mode
--	ZycaR (c) 2016
--
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/Mixins/SignalEmitterMixin.lua")

class 'FuncDoor' (ScriptActor)
FuncDoor.kMapName = "ns2siege_funcdoor"
FuncDoor.kOpenDelta = 0.001

local kOpeningEffect = PrecacheAsset("cinematics/environment/steamjet_ceiling.cinematic")

local networkVars =
{
    scale = "vector",
    isOpened = "boolean",
    isMoving = "boolean",
    mapblip = "vector"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
--AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(ObstacleMixin, networkVars)

-- Entity defined properties:
--   type         (0-FrontDoor; 1-SiegeDoor; ...)
--   model        (models/props/eclipse/eclipse_wallmodse_02_door.model)
--   direction    (0-Up; 1-Down; 2-Left; 3-Right)
--   distance     (10)
--   speed        (0.25)

local backupModel = PrecacheAsset("models/props/eclipse/eclipse_wallmodsE_02_door.model")

-- is opened or is actually opening
function FuncDoor:GetIsOpened()     return self.isOpened or self.isMoving end

local function GetOpenTranslation(self)
    local offset = self.waypoint.close.rotation:GetCoords()

    if self.direction == 0 then       -- Up
        offset =   offset.yAxis
    elseif self.direction == 1 then   -- Down
        offset = - offset.yAxis
    elseif self.direction == 2 then   -- Left
        offset =   offset.xAxis
    elseif self.direction == 3 then   -- Right
        offset = - offset.xAxis
    elseif self.direction == 4 then   -- Front
        offset = - offset.zAxis
    elseif self.direction == 5 then   -- Back
        offset =   offset.zAxis
    end

    return GetNormalizedVector(offset) * self.distance
end

local function InitDoorWaypoints(self)
    self.waypoint = { }

    self.waypoint.close = {
        position = Vector(self:GetOrigin()),
        rotation = Angles(self:GetAngles())
    }

    local transform = GetOpenTranslation(self)
    self.waypoint.open = {
        position = self.waypoint.close.position + transform,
        rotation = self.waypoint.close.rotation
    }
    self.waypoint.momentum = GetNormalizedVector(transform) * self.speed

    -- set model to properly recalulate obstacle coordinates
    self:SetOrigin(self.waypoint.close.position)
    self:SetAngles(self.waypoint.close.rotation)
    self.waypoint.obstacle = {
        origin = Vector(self:GetModelOrigin()),
        radius = self:GetScaledModelExtents():GetLengthXZ()
    }
end

local function DrawDebugBox(self, lifetime)
    if Shared.GetCheatsEnabled() or Shared.GetDevMode() then
        local obstacle = self.waypoint.obstacle
        local size = obstacle.radius
        local min = obstacle.origin + Vector(-size,-size,-size)
        local max = obstacle.origin + Vector( size, size, size)
        DebugBox(min, max, Vector(0,0,0), lifetime, 1, 0, 0, 1)
    end
end

function FuncDoor:OnCreate()
    ScriptActor.OnCreate(self)
    self.mapblip = Vector(self:GetOrigin())

    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    --InitMixin(self, ModelMixin)
    InitMixin(self, ObstacleMixin)
    InitMixin(self, SignalEmitterMixin)

    self:SetLagCompensated(true)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)

    self.emitMessage = ""
end

function FuncDoor:OnInitialized()
    ScriptActor.OnInitialized(self)

    if Server then
        if self.model == nil or not GetFileExists(self.model) then
            self.model = backupModel
        end

        if self.model ~= nil and GetFileExists(self.model) then
            Shared.PrecacheModel(self.model)
            self:SetModel(self.model)

            self:SetLagCompensated(true)
            self:SetPhysicsType(PhysicsType.Kinematic)
            self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)

            -- This Mixin must be inited inside this OnInitialized() function.
            if not HasMixin(self, "MapBlip") then
                InitMixin(self, MapBlipMixin)
            end
        else
            Shared.Message("Missing or invalid func_door model")
        end

        -- init with closed door position
        InitDoorWaypoints(self)

        self:SetIsOpened(false)
        self.closeWhenGameStarts = false
        self.mapblip = Vector(self:GetModelOrigin())

    elseif Client then
        self.outline = false
    end
end

function FuncDoor:Reset()
    ScriptActor.Reset(self)

    if Server then
        self:SetIsOpened(true)
        self.closeWhenGameStarts = true

        --DrawDebugBox(self, 100)
    end

end

function FuncDoor:OnAdjustModelCoords(modelCoords)
    local coords = modelCoords
    if self.scale and self.scale:GetLength() ~= 0 and coords then
        coords.xAxis = coords.xAxis * self.scale.x
        coords.yAxis = coords.yAxis * self.scale.y
        coords.zAxis = coords.zAxis * self.scale.z
    end
    return coords
end

function FuncDoor:GetScaledModelExtents()
    local min, max = self:GetModelExtents()
    local extents = (max or min or Vector(1,1,1)) * 0.5

    if self.scale ~= nil and self.scale:GetLength() ~= 0 then
        extents.x = extents.x * self.scale.x
        extents.y = extents.y * self.scale.y
        extents.z = extents.z * self.scale.z
    end

    return extents
end

function FuncDoor:SyncPhysicsModel()
    local physModel = self:GetPhysicsModel()
    if physModel then
        local coords = self:OnAdjustModelCoords(self:GetCoords())
        coords.origin = self:GetOrigin()
        physModel:SetCoords(coords)
        physModel:SetBoneCoords(coords, CoordsArray())
    end
end

function FuncDoor:GetObstaclePathingInfo()
    if Server then
        local centerpoint = self.waypoint.obstacle.origin + Vector(0, -3, 0)
        local radius = Clamp(self.waypoint.obstacle.radius, 1.5, 24.0)
        return centerpoint, radius, 5
    else
        local centerpoint = self:GetModelOrigin() + Vector(0, -3, 0)
        local radius = Clamp(self:GetScaledModelExtents():GetLengthXZ(), 1.5, 24.0)
        return centerpoint, radius, 5
    end
end

-- add or remove from pathing mesh
function FuncDoor:SyncToObstacleMesh()
	if not self:GetIsOpened() and self.obstacleId == -1 then
        self:AddToMesh()
    end

    if self:GetIsOpened() and self.obstacleId ~= -1 then
        self:RemoveFromMesh()
    end
end

function FuncDoor:OnUpdate(deltaTime)
    ScriptActor.OnUpdate(self, deltaTime)
    if Server then
        self:OnUpdatePosition(deltaTime)
        self:SyncToObstacleMesh()
    elseif Client then
        self:OnUpdateOutline()
    end
end

if Server then

    function FuncDoor:SetIsOpened(state)
        local open = ( state ~= false )
        if self.isOpened ~= open then
            --Shared.Message("FuncDoor .. " ..  ConditionalValue(open, "opened", "closed") )

            self.isOpened = open
            self.isMoving = false

            -- force translate door model to source or destination position
            local waypoint = ConditionalValue(self.isOpened, self.waypoint.open, self.waypoint.close)
            self:SetAngles(waypoint.rotation)
            self:SetOrigin(waypoint.position)
            self:SyncPhysicsModel()

            -- remove from pathing mesh
            self:SyncToObstacleMesh()
        end
    end

    function FuncDoor:BeginOpenDoor(doorType)
        if self.type == doorType and not self.isOpened then
            self.isMoving = true

            if self.emitMessage ~= "" then
                self:SetSignalRange(1000)
                self:EmitSignal(0, self.emitMessage)
            end
        end
    end

    -- func_doors counts the 'Countdown', 'Draw' and both 'Win' states as running game
    local function GetGameStartedForFuncDoor()
        local state = GetGamerules():GetGameState()
        return state > kGameState.PreGame
    end

    function FuncDoor:OnUpdatePosition(deltaTime)
        -- don't update position until game is not started
        if not GetGameStartedForFuncDoor() then
            return
        end

        -- close door after game started
        if self.closeWhenGameStarts then
            -- Shared.Message("FuncDoor .. closing!")
            self:SetIsOpened(false)
            self.closeWhenGameStarts = false
            return
        end

        if not self.isOpened and self.isMoving then
            -- UpdatePosition by delta time
            local startPoint = Vector(self:GetOrigin())
            local endPoint = self.waypoint.open.position
            local distance = (endPoint - startPoint):GetLength()
            local delta = deltaTime * self.waypoint.momentum

            -- check, whether doors are already opened
            if distance <= FuncDoor.kOpenDelta then
                self.isOpened = true
                self.isMoving = false
                return
            end

            local position = ConditionalValue(distance > delta:GetLength(), startPoint + delta, endPoint)
            self:SetOrigin(position)

            self:RemoveFromMesh()
            self:SyncPhysicsModel()
        end
    end
end

if Client then

    function FuncDoor:OnDestroy()
        if self.outline then
            local model = self:GetRenderModel()
            if model ~= nil then
                EquipmentOutline_RemoveModel(model)
                HiveVision_RemoveModel( model )
            end
        end
    end

    function FuncDoor:OnModelChanged()
        self.outline = false
    end

    function FuncDoor:OnUpdateOutline()
        local model = self:GetRenderModel()

        -- draw outline for closed door or when game is not started
        local outline = not self:GetIsOpened() or (GetGameInfoEntity():GetState() <= kGameState.PreGame)

        if model ~= nil and outline ~= self.outline then
            self.outline = outline

            EquipmentOutline_RemoveModel( model )
            HiveVision_RemoveModel( model )

            if outline then
                EquipmentOutline_AddModel( model, kEquipmentOutlineColor.Fuchsia )
                HiveVision_AddModel( model )
            end

        end
    end

end

function FuncDoor:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end

-- minimap support
function FuncDoor:OnGetMapBlipInfo()
    local success = true
    local blipType = kMinimapBlipType.EtherealGate
    local blipTeam = -1
    local isAttacked = false
    local isParasited = false

    return success, blipType, blipTeam, isAttacked, isParasited
end

function FuncDoor:GetPositionForMinimap()
    return self.mapblip
end

Shared.LinkClassToMap("FuncDoor", FuncDoor.kMapName, networkVars, true)
