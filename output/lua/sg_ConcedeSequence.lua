-- ======= Copyright (c) 2003-2016, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\ConcedeSequence.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--  An entity that is created when one team concedes which takes control of the clients cameras to show
--  the conceding teams units/structures getting wiped out.
--
-- ========= For more information, visit us at http:\\www.unknownworlds.com =====================

kConcedeTimeBeforeSequenceStart = 1.0
kConcedeTimeBeforeRoomKill = 1.0
kConcedeTimePerTechPoint = 2.0
kConcedeTimeAfterSequence = 4.0

-- Maximum amount of time we could possibly linger on a single tech point.
local kMaxTPTime = kConcedeTimePerTechPoint + kConcedeTimeAfterSequence

kConcedeNumAnglesToCheck = 64 -- adjust for performance
kConcedeIdealCameraSpeed = 1.0
kConcedeRelevancyDistance = 20 -- reduce relevancy distance for these sequences
local kConcedeRelevancyDistanceSq = kConcedeRelevancyDistance * kConcedeRelevancyDistance
kConcedeTPHeightOffset = 2.5 -- height above TP origin to focus.

kConcedeFOVAdjust = math.rad(20.0)

local kConcedeTPProximity = 1.0 -- distance threshold to relate a coarse location to a techpoint/command structure.
local kConcedeTPProximitySq = kConcedeTPProximity * kConcedeTPProximity

-- For performance, we pre-calculate the camera moves possible at each techpoint when the
-- map is done loading, rather than when they are needed.  This is only done on the client.
local tpCameraSettingsCache = {}

-- Store TP locations during mapload.
local tpLocations = {}

class 'ConcedeSequence' (Entity)
ConcedeSequence.kMapName = "concedesequence"
local netvars =
{
    -- we're only using position to identify which tech point we're using, so it can be super coarse.
    coarsePosition = "position (by 4 [], by 2000 [], by 4 [])",
}

-- Returns concede sequence singleton entity, if it exists, nil otherwise.
local gConcedeSeq
if Server then
    function GetConcedeSequence()
        return gConcedeSeq
    end

    function DoConcedeSequence(concedingTeamNum)
        assert(concedingTeamNum == kTeam1Index or concedingTeamNum == kTeam2Index)
        
        -- Ensure there is only ever one concede sequence at a time.  This really shouldn't ever happen, but
        -- just to be safe, we destroy any active sequences.
        if gConcedeSeq then
            DestroyEntity(gConcedeSeq)
            gConcedeSeq = nil
        end
        
        gConcedeSeq = CreateEntity(ConcedeSequence.kMapName)
        gConcedeSeq.concedingTeamNum = concedingTeamNum
        
        gConcedeSeq:BeginSequence()
        
    end
    
    local function KillAppropriately(ent)
        
        -- Don't kill things that are being recycled.
        if HasMixin(ent, "Recycle") and ent:GetIsRecycled() then
            return
        end
        
        -- Poof blueprints instead of killing them.
        if ent.GetIsGhostStructure and ent:GetIsGhostStructure() then
            -- make it poof!
            ent:SetHealth(0)
            ent:OnTakeDamage(0)
            return
        end
        
        ent:Kill()
    end
    
    function ConcedeSequence:KillRoom()
        -- Kill everything belonging to that team within kConcedeRelevancyDistance.
        local things = GetEntitiesWithMixinForTeam("Live", self.concedingTeamNum)
        for i=1, #things do
            if (things[i]:GetOrigin() - self.finePosition):GetLengthSquared() <= kConcedeRelevancyDistanceSq then
                KillAppropriately(things[i])
            end
        end
        
        -- Kill the power node too
        if GetGamerules():GetTeam(self.concedingTeamNum):GetTeamType() == kMarineTeamType then
            local powerNodes = GetEntitiesWithinRange("PowerPoint", self.finePosition, kConcedeRelevancyDistance)
            for i=1, #powerNodes do
                KillAppropriately(powerNodes[i])
            end
        end
        
        self:AddTimedCallback(ConcedeSequence.PickNextTP, kConcedeTimePerTechPoint - kConcedeTimeBeforeRoomKill)
    end
    
    function ConcedeSequence:PickNextTP()
        
        -- ensure all commanders are logged out
        local players = EntityListToTable(Shared.GetEntitiesWithClassname("Commander"))
        for i=1, #players do
            if players[i] and players[i].Logout then
                players[i]:Logout()
            end
        end
        
        local commandStructures = GetEntitiesForTeam("CommandStructure", self.concedingTeamNum)
        for i=1, #commandStructures do
            if commandStructures[i] and commandStructures[i]:GetIsAlive() then
                self.finePosition = commandStructures[i]:GetOrigin()
                self.coarsePosition = self.finePosition -- networked position
                self:AddTimedCallback(ConcedeSequence.KillRoom, kConcedeTimeBeforeRoomKill)
                return
            end
        end
        self:AddTimedCallback(ConcedeSequence.EndSequence, kConcedeTimeAfterSequence)
    end
    
    function ConcedeSequence:EndSequence()
        DestroyEntity(self)
        GetGamerules():UpdateToReadyRoom(true)
    end
    
    function ConcedeSequence:BeginSequence()
        self:AddTimedCallback(ConcedeSequence.PickNextTP, kConcedeTimeBeforeSequenceStart)
    end
    
    function ConcedeSequence:OnCreate()
        Entity.OnCreate(self)
        self:SetIsVisible(false)
        
        -- Ready room players do not observe the concede sequence.  Only team1, team2 (and spectators) see
        -- concede sequence.
        self:SetIncludeRelevancyMask(bit.bor(kRelevantToTeam1, kRelevantToTeam2))
        self:SetExcludeRelevancyMask(bit.bor(kRelevantToTeam1, kRelevantToTeam2))
        
        self.coarsePosition = Vector(0, -1000, 0)
    end
    
    function ConcedeSequence.ModifyRelevancy(player)
        if not gConcedeSeq then
            return
        end
        
        if not ConcedeSequence.GetIsPlayerObserving(player) then
            return
        end
        
        local self = gConcedeSeq
        if self.finePosition then
            player:ConfigureRelevancy(self.finePosition - player:GetOrigin(), kConcedeRelevancyDistance - kMaxRelevancyDistance)
            
        end
    end
end

function GetConcedeSequenceActive()
    return gConcedeSeq ~= nil
end

if Predict then
    function ConcedeSequence:OnInitialized()
        Entity.OnInitialized(self)
        gConcedeSeq = self
    end
end

if Client then
    
    local function CSFilterAll() return true end
    local function Polar2Cartesian(origin, distance, height, theta)
        return Vector(distance * math.sin(theta), height, distance * math.cos(theta)) + origin
    end
    
    -- Called from ConcedeSequence.RateCameraMovement().  Evaluates the area around the position
    -- for camera-orbitable area.  The score assigned is based on the maximum consecutive number
    -- of valid camera positions divided by the number of camera positions.
    function ConcedeSequence.RateCameraMovement_orbit(position, setting)
        assert(setting.movement == "orbit")
        assert(type(setting.distance) == "number")
        assert(type(setting.height) == "number")
        
        if setting._score then
            return -- score has already been calculated.
        end
        
        local radPerIndex = (math.pi * 2) / kConcedeNumAnglesToCheck
        setting._cacheResults = {}
        
        -- Build a cache of trace results.  Cache is just a big list of true/false values.
        for i=1, kConcedeNumAnglesToCheck do
            local theta = (i-1) * radPerIndex
            local camOrigin = Polar2Cartesian(position, setting.distance, setting.height, theta)
            local trace = Shared.TraceRay(position, camOrigin, CollisionRep.Default, PhysicsMask.All, EntityFilterAll())
            if trace.fraction == 1 then
                setting._cacheResults[i] = true
            else
                setting._cacheResults[i] = false
            end
        end
        
        -- Find the largest slice of consecutive true/false values.
        -- Since we can have several slices as the maximum (same length), start the search at a
        -- random index, to ensure that we don't always get the same results for each map location.
        local startIndex = math.random(1, kConcedeNumAnglesToCheck)
        local longestIndex
        local longestLen = 0
        local currentLen = 0
        local currentIndex = startIndex
        for i=0, kConcedeNumAnglesToCheck-1 do
            local index = ((startIndex + i - 1) % kConcedeNumAnglesToCheck) + 1
            if setting._cacheResults[index] then
                currentLen = currentLen + 1
                if currentLen > longestLen then
                    longestLen = currentLen
                    longestIndex = currentIndex
                end
            else
                currentLen = 0
                currentIndex = (index % kConcedeNumAnglesToCheck) + 1 -- increment and wrap
            end
        end
        
        -- default to 1 if nil.  This can only happen if none of the camera positions were valid.
        longestIndex = longestIndex or 1
        setting._score = longestLen / kConcedeNumAnglesToCheck
        setting._orbitLen = longestLen
        setting._orbitIndex = longestIndex
        
    end
    
    -- Takes a position (tech point position), and the desired camera movement setup (setting),
    -- and attempts to find a movement for the camera that isn't obstructed by the terrain.
    -- A "score" for the movement is inserted into the "setting" table.  Score is a value from 0
    -- to 1, with 0 being terrible (ie no suitable camera positions found), and 1 being perfect
    -- (all camera positions tested were suitable).
    function ConcedeSequence.RateCameraMovement(position, setting)
        local movementFunction = ConcedeSequence[string.format("RateCameraMovement_%s", setting.movement)]
        if movementFunction then
            movementFunction(position, setting)
        end
    end
    
    -- Returns a list of settings, in descending order of priority, to use when searching for a
    -- camera movement for concede sequence.  Mods can override/extend this if they want to create
    -- more imaginative camera movements. :)
    function ConcedeSequence.GetSettingsList(settingsList)
        -- For now, the only camera movement implemented in vanilla is a simple orbit camera movement.
        -- This could be modified/extended with mods though.
        settingsList[#settingsList+1] =
        {
            movement = "orbit",
            distance = 6.5,
            height = 2.5,
        }
        
        settingsList[#settingsList+1] =
        {
            movement = "orbit",
            distance = 6.5,
            height = 2.0,
        }
        
        settingsList[#settingsList+1] =
        {
            movement = "orbit",
            distance = 4.5,
            height = 1.5,
        }
    end
    
    local function GetSettingsForTPLocation(position)
        for i=1, #tpCameraSettingsCache do
            if ((position - tpCameraSettingsCache[i]._position) * Vector(1, 0.05, 1)):GetLengthSquared() < kConcedeTPProximitySq then
                return tpCameraSettingsCache[i]
            end
        end
        
        return nil
    end
    
    -- Calculates the concede sequence camera movement for this location, and caches it.
    function ConcedeSequence.CalculateTechpointCameraMoves(position)
        assert(GetSettingsForTPLocation(position) == nil) -- shouldn't have already cached this.
        
        local pos = position + Vector(0, kConcedeTPHeightOffset, 0) -- pos = position to focus camera on.
        local candidateSettings = {}
        ConcedeSequence.GetSettingsList(candidateSettings)
        
        -- Rate each of the settings, and pick the highest rated one.
        local bestScore = -1
        local bestSettings
        for i=1, #candidateSettings do
            local setting = candidateSettings[i]
            ConcedeSequence.RateCameraMovement(pos, setting)
            if setting._score > bestScore then
                bestScore = setting._score
                bestSettings = setting
            end
        end
        
        if not bestSettings then
            -- There were no valid camera settings.  Just put something down... this should never
            -- happen, but I suppose it could happen given the right circumstances in a bizarre
            -- custom map.
            bestSettings =
            {
                movement = "orbit",
                distance = 4.0,
                height = 1.0,
                _orbitLen = 1,
                _orbitIndex = 1,
                _score = 0,
            }
        end
        
        bestSettings._position = pos
        tpCameraSettingsCache[#tpCameraSettingsCache+1] = bestSettings
        
    end
    
    function ConcedeSequence.CalculateAllTechpointCameraMoves()
        for i=1, #tpLocations do
            ConcedeSequence.CalculateTechpointCameraMoves(tpLocations[i])
        end
    end
    
    -- Returns coords calculated from the given camera move inputs
    function ConcedeSequence:GetCameraCoords_orbit(input)
        local t = Shared.GetTime()
        local theta = input.startTheta + input.angularVelocity * (t - input.startTime)
        local camPos = Polar2Cartesian(input.targetPos, input.distance, input.yOffset, theta)
        return Coords.GetLookAt(camPos, input.targetPos, Vector(0,1,0))
    end
    
    -- Called from the update render function.  Returns the coords the render camera should have.
    -- Returns nil if it cannot calculate them, for whatever reason.
    function ConcedeSequence:GetCameraCoords()
        if self.cameraMoveData and self.cameraMoveData.coordsFunc then
            return self.cameraMoveData.coordsFunc(self, self.cameraMoveData)
        end
        return nil
    end
    
    -- Sets the camera settings for the concede sequence (everything except coords).
    function ConcedeSequence.SetupCameraForConcedeSequence(coords)
        gRenderCamera:SetCoords(coords)
        local fov = GetScreenAdjustedFov(math.rad(kDefaultFov), 4/3) + kConcedeFOVAdjust
        gRenderCamera:SetFov(fov)
        gRenderCamera:SetFarPlane(1000)
        gRenderCamera:SetNearPlane(0.03)
        gRenderCamera:SetCullingMode(RenderCamera.CullingMode_Occlusion)
        Client.SetRenderCamera(gRenderCamera)
        
        HiveVision_SetEnabled(false)
        EquipmentOutline_SetEnabled(false)
        
        local viewAngles = Angles()
        viewAngles:BuildFromCoords(coords)
        Client.ConfigurePhysicsCuller(coords.origin, viewAngles, Math.Degrees(fov), Player.kPhysicsCullMin, Player.kPhysicsCullMax)
    end
    
    function ConcedeSequence.UpdateRenderOverride()
        
        if not gConcedeSeq then
            return false
        end
        
        -- Animate the camera according to the current location's precomputed camera settings.
        local coords = gConcedeSeq:GetCameraCoords()
        if not coords then
            return false
        end
        
        -- Setup camera fov, near/far plane, culling modes, etc.
        ConcedeSequence.SetupCameraForConcedeSequence(coords)
        
        -- Hide view models.
        local player = Client.GetLocalPlayer()
        if player then
            player:SetCameraDistance(0.01)
        end
        
        return true
        
    end
    
    -- The settings passed are essentially a super-set of all the possible movements.  We need to
    -- boil this down to something usable.  Returns a table of camera movement inputs that will be
    -- used for calculating the coords of the camera.
    function ConcedeSequence:CalculateCameraMovement_orbit(settings)
        local circumference = settings.distance * math.pi * 2.0
        
        if settings._score == 1 then
            -- special case: if score is 1, we are guaranteed to have every angle usable.
            local camMove = {}
            camMove.startTheta = math.random() * math.pi * 2
            camMove.angularVelocity = (kConcedeIdealCameraSpeed / circumference) * math.pi * 2 * (math.random() > 0.5 and -1 or 1)
            camMove.distance = settings.distance
            camMove.targetPos = settings._position
            camMove.yOffset = settings.height
            camMove.startTime = Shared.GetTime()
            camMove.coordsFunc = ConcedeSequence.GetCameraCoords_orbit
            return camMove
        end
        
        local arcLength = ((settings._orbitLen - 1) / kConcedeNumAnglesToCheck) * circumference
        local camSpeed = kConcedeIdealCameraSpeed
        local lengthNeeded = kMaxTPTime * camSpeed
        local lengthActual = math.min(lengthNeeded, arcLength)
        local wiggleRoom = arcLength - lengthActual
        local camSpeed = lengthActual / kMaxTPTime
        
        local lengthInRads = lengthActual / settings.distance
        local speedInRads = camSpeed / settings.distance
        local wiggleInRads = wiggleRoom / settings.distance
        
        local startTheta = ((settings._orbitIndex - 1) / kConcedeNumAnglesToCheck) * math.pi * 2
        startTheta = startTheta + math.random() * wiggleInRads
        
        if (math.random() > 0.5) then
            -- sometimes orbit the opposite direction
            startTheta = (startTheta + lengthInRads) % (math.pi * 2)
            speedInRads = -speedInRads
        end
        
        local camMove = {}
        camMove.startTheta = startTheta
        camMove.angularVelocity = speedInRads
        camMove.distance = settings.distance
        camMove.targetPos = settings._position
        camMove.yOffset = settings.height
        camMove.startTime = Shared.GetTime()
        camMove.coordsFunc = ConcedeSequence.GetCameraCoords_orbit
        return camMove
    end
    
    function ConcedeSequence:OnCoarsePositionChange()
        local settings = GetSettingsForTPLocation(self.coarsePosition)
        if settings then
            local func = ConcedeSequence[string.format("CalculateCameraMovement_%s", settings.movement)]
            if func then
                self.cameraMoveData = func(self, settings)
            end
            
            -- Configure the player's view for the concede sequence.  This includes enabling commander-invisible
            -- props and geometry, removing old screen effects (eg blood), and enabling sound geometry.
            if not gConcedeSeq.concedeSeqViewSetup then
                Player.OnInitLocalClient(Client.GetLocalPlayer())
                gConcedeSeq.concedeSeqViewSetup = true
            end
            
        end
        
        return true -- keep watching this field
    end
    
    function ConcedeSequence:OnInitialized()
        
        Entity.OnInitialized(self)
        
        self.cameraMoveData = {}
        self:AddFieldWatcher("coarsePosition", ConcedeSequence.OnCoarsePositionChange)
        
        gConcedeSeq = self
        
        self.concedeSeqViewSetup = false
        
    end
    
    function ConcedeSequence.AddTPLocation(position)
        tpLocations[#tpLocations+1] = position
    end
    
end

-- Returns true if the player is observing the concede sequence (so both teams, and the spectators,
-- but not the ready room players).
function ConcedeSequence.GetIsPlayerObserving(player)
    if not GetConcedeSequenceActive() then
        return false
    end
    
    -- Don't inhibit ready room players from moving
    local teamNum = player and player.GetTeamNumber and player:GetTeamNumber()
    if teamNum == nil or teamNum == kTeamReadyRoom then
        assert(player)
        return false
    end
    
    return true
end

-- Modifies the player's move as appropriate for the concede sequence.  If it isn't running, or
-- if the player isn't observing the sequence, no changes are made.
function ConcedeSequence.ModifyPlayerMove(player, input)
    
    if not ConcedeSequence.GetIsPlayerObserving(player) then
        return
    end
    
    input.move:Scale(0)
    input.commands = 0
end

function ConcedeSequence:OnDestroy()
    gConcedeSeq = nil
end

Shared.LinkClassToMap("ConcedeSequence", ConcedeSequence.kMapName, netvars)

-----------
-- DEBUG --
-----------

-- Put command on client so they can see console feedback.
Shared.RegisterNetworkMessage("DebugConcede", { teamNum = "integer (1 to 2)" })
if Client then
    Event.Hook("Console_debugconcede",
    function(teamNumber)
        if not Shared.GetTestsEnabled() and not Shared.GetCheatsEnabled() then
            Log("Cheats or tests must be enabled to use the 'debugconcede' command.")
            return
        end
        
        local teamNum = tonumber(teamNumber)
        if teamNum ~= kTeam1Index and teamNum ~= kTeam2Index then
            Log("Usage: debugconcede <teamNum>")
            Log("    teamNum: number of conceding team (1 for marines, 2 for aliens).")
            return
        end
        
        Client.SendNetworkMessage("DebugConcede", {teamNum = teamNum}, true)
        
    end)
end
if Server then
    Server.HookNetworkMessage("DebugConcede",
    function(client, message)
        if not Shared.GetTestsEnabled() and not Shared.GetCheatsEnabled() then
            return
        end
        
        local teamNum = message.teamNum
        if teamNum ~= kTeam1Index and teamNum ~= kTeam2Index then
            return
        end
        
        GetGamerules():GetTeam(teamNum).conceded = true
        GetGamerules():EndGame(GetGamerules():GetTeam(teamNum == kTeam1Index and kTeam2Index or kTeam1Index))
    end)
end


