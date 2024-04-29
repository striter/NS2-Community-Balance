-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\GUIMinimap.lua
--
-- Created by: Brian Cronin (brianc@unknownworlds.com)
--
-- Manages displaying the minimap and icons on the minimap.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIMinimapConnection.lua")
Script.Load("lua/MinimapMappableMixin.lua")

class 'GUIMinimap' (GUIScript)

-- activity is rechecked with this intervals, immobile blips will be updated at this interval too
local kActivityUpdateInterval = 0.5

-- how often we update for each activity level
local kBlipActivityUpdateInterval = {}
kBlipActivityUpdateInterval[kMinimapActivity.Static] = kActivityUpdateInterval
kBlipActivityUpdateInterval[kMinimapActivity.Low] = 0.2
kBlipActivityUpdateInterval[kMinimapActivity.Medium] = 0.05
kBlipActivityUpdateInterval[kMinimapActivity.High] = 0.001

-- allow update rate to be controlled by console (minimap_rate). 0 = full rate
GUIMinimap.kUpdateIntervalMultipler = 1
GUIMinimap.kToggleMap = GetAdvancedOption("minimaptoggle") == 1

-- the model that mappers use to configure minimap_extents has extents of +/- this number.
local kMinimapExtentsModelScaleFactor = 0.239246666431427;
local kMinimapShowPlayerNames = true
-- update the "other stuff" at 25Hz 
local kMiscUpdateInterval = 0.04

local kPlayerNameLayer = 7
local kPlayerNameFontSize = 8
local kPlayerNameFontName = Fonts.kAgencyFB_Tiny
local kPlayerNameOffset = Vector(11.5, -5, 0)
local kPlayerNameColorAlien = Color(1, 189/255, 111/255, 1)
local kPlayerNameColorMarine = Color(164/255, 241/255, 1, 1)

local kBlipSize = GUIScale(30)

local kWaypointColor = Color(1, 1, 1, 1)
local kEtherealGateColor = Color(0.8, 0.6, 1, 1)

-- colors are defined in the dds
local kTeamColors = { }
kTeamColors[kMinimapBlipTeam.Friendly] = Color(1, 1, 1, 1)
kTeamColors[kMinimapBlipTeam.Enemy] = Color(1, 0, 0, 1)
kTeamColors[kMinimapBlipTeam.Neutral] = Color(1, 1, 1, 1)
kTeamColors[kMinimapBlipTeam.Alien] = Color(1, 138/255, 0, 1)
kTeamColors[kMinimapBlipTeam.Marine] = Color(0, 216/255, 1, 1)
-- steam friend colors
kTeamColors[kMinimapBlipTeam.FriendAlien] = Color(1, 189/255, 111/255, 1)
kTeamColors[kMinimapBlipTeam.FriendMarine] = Color(164/255, 241/255, 1, 1)

kTeamColors[kMinimapBlipTeam.InactiveAlien] = Color(85/255, 46/255, 0, 1, 1)
kTeamColors[kMinimapBlipTeam.InactiveMarine] = Color(0, 72/255, 85/255, 1)

local kPowerNodeColor = Color(1, 1, 0.7, 1)
local kDestroyedPowerNodeColor = Color(0.5, 0.5, 0.35, 1)

local kDrifterColor = Color(1, 1, 0, 1)
local kMACColor = Color(0, 1, 0.2, 1)

local kScanColor = Color(0.2, 0.8, 1, 1)
local kScanAnimDuration = 2

local kFullColor = Color(1,1,1,1)

local kInfestationColor = { }
kInfestationColor[kMinimapBlipTeam.Friendly] = Color(1, 1, 0, .25)
kInfestationColor[kMinimapBlipTeam.Enemy] = Color(1, 0.67, 0.06, .25)
kInfestationColor[kMinimapBlipTeam.Neutral] = Color(0.2, 0.7, 0.2, .25)
kInfestationColor[kMinimapBlipTeam.Alien] = Color(0.2, 0.7, 0.2, .25)
kInfestationColor[kMinimapBlipTeam.Marine] = Color(0.2, 0.7, 0.2, .25)
kInfestationColor[kMinimapBlipTeam.InactiveAlien] = Color(0.2 /3, 0.7/3, 0.2/3, .25)
kInfestationColor[kMinimapBlipTeam.InactiveMarine] = Color(0.2/3, 0.7/3, 0.2/3, .25)

local kInfestationDyingColor = { }
kInfestationDyingColor[kMinimapBlipTeam.Friendly] = Color(1, 0.2, 0, .25)
kInfestationDyingColor[kMinimapBlipTeam.Enemy] = Color(1, 0.2, 0, .25)
kInfestationDyingColor[kMinimapBlipTeam.Neutral] =Color(1, 0.2, 0, .25)
kInfestationDyingColor[kMinimapBlipTeam.Alien] = Color(1, 0.2, 0, .25)
kInfestationDyingColor[kMinimapBlipTeam.Marine] = Color(1, 0.2, 0, .25)
kInfestationDyingColor[kMinimapBlipTeam.InactiveAlien] = Color(1/3, 0.2/3, 0, .25)
kInfestationDyingColor[kMinimapBlipTeam.InactiveMarine] = Color(1/3, 0.2/3, 0, .25)

local kShrinkingArrowInitSize

local kIconFileName = PrecacheAsset("ui/minimap_blip.dds")

local kLargePlayerArrowFileName = PrecacheAsset("ui/minimap_largeplayerarrow.dds")

local kCommanderPingMinimapSize

local kIconWidth = 32
local kIconHeight = 32

local kInfestationBlipsLayer = 0
local kBackgroundBlipsLayer = 1
local kStaticBlipsLayer = 2
local kDynamicBlipsLayer = 3
local kLocationNameLayer = 4
local kPingLayer = 5
local kPlayerIconLayer = 6
local kWaypointLayer = 7

local kBlipTexture = "ui/blip.dds"

local kBlipTextureCoordinates = { }
kBlipTextureCoordinates[kAlertType.Attack] = { X1 = 0, Y1 = 0, X2 = 64, Y2 = 64 }

local kAttackBlipMinSize
local kAttackBlipMaxSize
local kAttackBlipPulseSpeed = 6
local kAttackBlipTime = 5
local kAttackBlipFadeInTime = 4.5
local kAttackBlipFadeOutTime = 1

local kLocationFontName = Fonts.kAgencyFB_Smaller_Bordered

local kPlayerIconSize

local kBlipColorType = enum( { 'Team', 'Infestation', 'InfestationDying', 'Waypoint', 'PowerPoint', 'DestroyedPowerPoint', 'Scan', 'Drifter', 'MAC', 'EtherealGate', 'HighlightWorld', 'FullColor' } )
local kBlipSizeType = enum( { 'Normal', 'TechPoint', 'Infestation', 'Scan', 'Egg', 'Worker', 'EtherealGate', 'HighlightWorld', 'Waypoint', 'BoneWall', 'UnpoweredPowerPoint' } )

local kBlipInfo = {}
kBlipInfo[kMinimapBlipType.TechPoint] = { kBlipColorType.HighlightWorld, kBlipSizeType.TechPoint, kBackgroundBlipsLayer }
kBlipInfo[kMinimapBlipType.ResourcePoint] = { kBlipColorType.HighlightWorld, kBlipSizeType.Normal, kBackgroundBlipsLayer }
kBlipInfo[kMinimapBlipType.Scan] = { kBlipColorType.Scan, kBlipSizeType.Scan, kBackgroundBlipsLayer }
kBlipInfo[kMinimapBlipType.CommandStation] = { kBlipColorType.Team, kBlipSizeType.TechPoint, kStaticBlipsLayer }
kBlipInfo[kMinimapBlipType.Hive] = { kBlipColorType.Team, kBlipSizeType.TechPoint, kStaticBlipsLayer }
kBlipInfo[kMinimapBlipType.PowerPoint] = { kBlipColorType.PowerPoint, kBlipSizeType.Normal, kStaticBlipsLayer, "PowerPoint" }
kBlipInfo[kMinimapBlipType.DestroyedPowerPoint] = { kBlipColorType.DestroyedPowerPoint, kBlipSizeType.Normal, kStaticBlipsLayer, "PowerPoint" }
kBlipInfo[kMinimapBlipType.UnsocketedPowerPoint] = { kBlipColorType.FullColor, kBlipSizeType.UnpoweredPowerPoint, kStaticBlipsLayer, "UnsocketedPowerPoint" }
kBlipInfo[kMinimapBlipType.BlueprintPowerPoint] = { kBlipColorType.Team, kBlipSizeType.UnpoweredPowerPoint, kStaticBlipsLayer, "UnsocketedPowerPoint" }
kBlipInfo[kMinimapBlipType.Infestation] = { kBlipColorType.Infestation, kBlipSizeType.Infestation, kInfestationBlipsLayer, "Infestation" }
kBlipInfo[kMinimapBlipType.InfestationDying] = { kBlipColorType.InfestationDying, kBlipSizeType.Infestation, kInfestationBlipsLayer, "Infestation" }
kBlipInfo[kMinimapBlipType.MoveOrder] = { kBlipColorType.Waypoint, kBlipSizeType.Waypoint, kWaypointLayer }
kBlipInfo[kMinimapBlipType.AttackOrder] = { kBlipColorType.Waypoint, kBlipSizeType.Waypoint, kWaypointLayer }
kBlipInfo[kMinimapBlipType.BuildOrder] = { kBlipColorType.Waypoint, kBlipSizeType.Waypoint, kWaypointLayer }
kBlipInfo[kMinimapBlipType.Drifter] = { kBlipColorType.Drifter, kBlipSizeType.Worker, kStaticBlipsLayer }
kBlipInfo[kMinimapBlipType.MAC] = { kBlipColorType.MAC, kBlipSizeType.Worker, kStaticBlipsLayer }
kBlipInfo[kMinimapBlipType.EtherealGate] = { kBlipColorType.EtherealGate, kBlipSizeType.EtherealGate, kBackgroundBlipsLayer }
kBlipInfo[kMinimapBlipType.HighlightWorld] = { kBlipColorType.HighlightWorld, kBlipSizeType.HighlightWorld, kBackgroundBlipsLayer }
kBlipInfo[kMinimapBlipType.BoneWall] = { kBlipColorType.FullColor, kBlipSizeType.BoneWall, kBackgroundBlipsLayer }

kBlipInfo[kMinimapBlipType.Pheromone_Defend] = { kBlipColorType.Waypoint, kBlipSizeType.Waypoint, kWaypointLayer }
kBlipInfo[kMinimapBlipType.Pheromone_Expand] = { kBlipColorType.Waypoint, kBlipSizeType.Waypoint, kWaypointLayer }
kBlipInfo[kMinimapBlipType.Pheromone_Threat] = { kBlipColorType.Waypoint, kBlipSizeType.Waypoint, kWaypointLayer }

local kClassToGrid = BuildClassToGrid()

GUIMinimap.kBackgroundWidth = GUIScale(300)
GUIMinimap.kBackgroundHeight = GUIMinimap.kBackgroundWidth

function GUIMinimap:UpdateItemsGUIScale()
    kBlipSize = GUIScale(30)
    kShrinkingArrowInitSize = Vector(kBlipSize * 10, kBlipSize * 10, 0)
    kAttackBlipMinSize = Vector(GUIScale(25), GUIScale(25), 0)
    kAttackBlipMaxSize = Vector(GUIScale(100), GUIScale(100), 0)

    kCommanderPingMinimapSize = GUIScale(Vector(80, 80, 0))

    kPlayerIconSize = Vector(kBlipSize, kBlipSize, 0)
    self.playerIcon:SetSize(kPlayerIconSize)

    GUIMinimap.kBackgroundWidth = GUIScale(300)
    GUIMinimap.kBackgroundHeight = GUIMinimap.kBackgroundWidth
    self.background:SetSize(Vector(GUIMinimap.kBackgroundWidth, GUIMinimap.kBackgroundHeight, 0))

    local scale = self:GetScale()
    self:SetScale(scale)

    local size = Vector(GUIMinimap.kBackgroundWidth * scale, GUIMinimap.kBackgroundHeight * scale, 0)
    self.minimap:SetSize(size)
    self.minimap:SetPosition(size * -0.5)

    for _, nameTag in self.nameTagMap:Iterate() do
        GUI.DestroyItem(nameTag)
    end

    self.nameTagMap:Clear()
end

function GUIMinimap:PlotToMap(posX, posZ)

    if Client.legacyMinimap then
        -- This map's overview was generated with the pre-build-320 overview.exe, meaning we have to use
        -- old code for blips to continue to map correctly to the overview image.  If nil, it simply
        -- indicates it's an old version of the level that has not been saved with a >=320 editor setup.
        -- The author can also set this value to true if they wish to keep the old overview.
        -- When opening an old map, the value "useLegacyOverview" will default to false if it is not found.
        local plottedX = (posX + self.plotToMapConstX) * self.plotToMapLinX
        local plottedZ = (posZ + self.plotToMapConstY) * self.plotToMapLinY

        -- The world space is oriented differently from the GUI space, adjust for that here.
        -- Return 0 as the third parameter so the results can easily be added to a Vector.
        return plottedZ, -plottedX, 0
    end

    local plottedX = (posX + self.plotXOffset) * self.plotXFactor
    local plottedZ = (posZ + self.plotZOffset) * self.plotZFactor

    -- Return 0 as the third parameter so the results can easily be added to a Vector.
    return plottedZ, plottedX, 0

end

function GUIMinimap:OnResolutionChanged()
    self:UpdateItemsGUIScale()
end

function GUIMinimap:Initialize()

    -- we update the minimap at full rate, but internally we spread out the
    -- actual load of updating the map so we only do a little bit of work each frame
    self.updateInterval = kUpdateIntervalFull

    self.nextMiscUpdateInterval = 0
    self.nextActivityUpdateTime = 0

    self.staticBlipData = {}
    self.iconMap = unique_map()
    self.freeIcons = {}
    self.localBlipData = unique_map()

    self.setsPlayerMinimapVisible = true

    for k = 1, #kMinimapActivity do
        self.staticBlipData[k] = {
            blipIds = {},
            count = 0,
            workIndex = 1
        }
    end

    local player = Client.GetLocalPlayer()
    self.showPlayerNames = false
    self.spectating = false
    self.clientIndex = player:GetClientIndex()

    -- infinite radius; set to > 0 for marine HUD; stops processing blips at > radius
    self.updateRadius = 0
    self.updateRadiusSquared = 0
    -- individual update rate multiplier. Set to run at full rate (all intervals are multipled by zero). Set to 1 to run
    -- at CPU saving rate
    self.updateIntervalMultipler = 0.5
    self.nameTagMap = unique_map()
    self.unusedNameTags = {}

    -- the rest is untouched in rewrite
    self.locationItems = { }
    self.timeMapOpened = 0
    self.stencilFunc = GUIItem.Always
    self.iconFileName = kIconFileName
    self.reuseDynamicBlips = { }
    self.inuseDynamicBlips = unique_set()
    self.scanColor = Color(kScanColor.r, kScanColor.g, kScanColor.b, kScanColor.a)
    self.scanSize = Vector(0, 0, 0)
    self.highlightWorldColor = Color(0, 1, 0, 1)
    self.highlightWorldSize = Vector(0, 0, 0)
    self.etherealGateColor = Color(kEtherealGateColor.r, kEtherealGateColor.g, kEtherealGateColor.b, kEtherealGateColor.a)
    self.blipSizeTable = { }
    self.minimapConnections = { }
    self.unusedMinimapConnections = {}

    self:SetScale(1) -- Compute plot to map transformation
    self:SetBlipScale(1) -- Compute blipSizeTable
    self.blipSizeTable[kBlipSizeType.Scan] = self.scanSize
    self.blipSizeTable[kBlipSizeType.HighlightWorld] = self.highlightWorldSize

    -- Initialize blip info lookup table
    local blipInfoTable = {}
    for blipType = 1, #kMinimapBlipType do
        local blipInfo = kBlipInfo[blipType]
        local iconCol, iconRow = GetSpriteGridByClass((blipInfo and blipInfo[4]) or EnumToString(kMinimapBlipType, blipType), kClassToGrid)
        local texCoords = table.pack(GUIGetSprite(iconCol, iconRow, kIconWidth, kIconHeight))
        if blipInfo then
            blipInfoTable[blipType] = { texCoords, blipInfo[1], blipInfo[2], blipInfo[3] }
        else
            blipInfoTable[blipType] = { texCoords, kBlipColorType.Team, kBlipSizeType.Normal, kStaticBlipsLayer }
        end
    end
    self.blipInfoTable = blipInfoTable

    -- Generate blip color lookup table
    local blipColorTable = {}
    for blipTeam = 1, #kMinimapBlipTeam do
        local colorTable = {}
        colorTable[kBlipColorType.Team] = kTeamColors[blipTeam]
        colorTable[kBlipColorType.Infestation] = kInfestationColor[blipTeam]
        colorTable[kBlipColorType.InfestationDying] = kInfestationDyingColor[blipTeam]
        colorTable[kBlipColorType.Waypoint] = kWaypointColor
        colorTable[kBlipColorType.PowerPoint] = kPowerNodeColor
        colorTable[kBlipColorType.DestroyedPowerPoint] = kDestroyedPowerNodeColor
        colorTable[kBlipColorType.Scan] = self.scanColor
        colorTable[kBlipColorType.HighlightWorld] = self.highlightWorldColor
        colorTable[kBlipColorType.Drifter] = kDrifterColor
        colorTable[kBlipColorType.MAC] = kMACColor
        colorTable[kBlipColorType.EtherealGate] = self.etherealGateColor
        colorTable[kBlipColorType.FullColor] = kFullColor
        blipColorTable[blipTeam] = colorTable
    end
    self.blipColorTable = blipColorTable

    self:InitializeBackground()

    self.minimap = GUIManager:CreateGraphicItem()
    self.minimap:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.minimap:SetPosition(Vector(0, 0, 0))
    self.minimap:SetTexture("maps/overviews/" .. Shared.GetMapName() .. ".tga")
    self.minimap:SetColor(Color(1,1,1, GetAdvancedOption("minimapalpha")))
    self.background:AddChild(self.minimap)

    -- Used for commander / spectator.
    self:InitializeCameraLines()
    -- Used for normal players.
    self:InitializePlayerIcon()

    -- initialize commander ping
    self.commanderPing = GUICreateCommanderPing()
    self.commanderPing.Frame:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.commanderPing.Frame:SetLayer(kPingLayer)
    self.minimap:AddChild(self.commanderPing.Frame)

    self:UpdateItemsGUIScale()
end

function GUIMinimap:SetIsVisible(state)

    self.visible = state
    self:Update(0)

    self.minimap:SetIsVisible(state)

    local modeIsMini = self.comMode == GUIMinimapFrame.kModeMini
    local modeIsZoom = self.comMode == GUIMinimapFrame.kModeZoom
    for i = 1, #self.locationItems do
        self.locationItems[i].text:SetIsVisible(state and not modeIsMini and not modeIsZoom)
    end

end

function GUIMinimap:GetIsVisible()

    return self.visible

end

function GUIMinimap:InitializeBackground()

    self.background = GUIManager:CreateGraphicItem()
    self.background:SetPosition(Vector(0, 0, 0))
    self.background:SetColor(Color(1, 1, 1, 0))
    self.background:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.background:SetLayer(kGUILayerMinimap)

    -- Non-commander players assume the map isn't visible by default.
    if not PlayerUI_IsACommander() then
        self.background:SetIsVisible(false)
    end

end

function GUIMinimap:InitializeCameraLines()

    self.cameraLines = GUIManager:CreateLinesItem()
    self.cameraLines:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.cameraLines:SetLayer(kPlayerIconLayer)
    self.minimap:AddChild(self.cameraLines)

end

function GUIMinimap:InitializePlayerIcon()
    -- TODO(Salads): Improve minimap arrow graphic.
    self.playerIcon = GUIManager:CreateGraphicItem()
    self.playerIcon:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.playerIcon:SetTexture(self.iconFileName)
    local iconCol, iconRow = GetSpriteGridByClass(PlayerUI_GetPlayerClass(), kClassToGrid)
    self.playerIcon:SetTexturePixelCoordinates(GUIGetSprite(iconCol, iconRow, kIconWidth, kIconHeight))
    self.playerIcon:SetIsVisible(false)
    self.playerIcon:SetLayer(kPlayerIconLayer)
    self.minimap:AddChild(self.playerIcon)

    self.playerShrinkingArrow = GUIManager:CreateGraphicItem()
    self.playerShrinkingArrow:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.playerShrinkingArrow:SetTexture(kLargePlayerArrowFileName)
    self.playerShrinkingArrow:SetLayer(kPlayerIconLayer)
    self.playerIcon:AddChild(self.playerShrinkingArrow)

end

local function SetupLocationTextItem(item)

    item:SetScale(GetScaledVector())
    item:SetFontIsBold(false)
    item:SetFontName(kLocationFontName)
    item:SetAnchor(GUIItem.Middle, GUIItem.Center)
    item:SetTextAlignmentX(GUIItem.Align_Center)
    item:SetTextAlignmentY(GUIItem.Align_Center)
    item:SetLayer(kLocationNameLayer)

end

local function SetLocationTextPosition( item, mapPos )

    item.text:SetPosition( Vector(mapPos.x, mapPos.y, 0) )

end

function OnCommandSetMapLocationColor(r, g, b, a)

    local minimap = ClientUI.GetScript("GUIMinimapFrame")
    if minimap then
        for i = 1, #minimap.locationItems do
            minimap.locationItems[i].text:SetColor( Color(tonumber(r)/255, tonumber(g)/255, tonumber(b)/255, tonumber(a)/255) )
        end
    end

end

-- Todo: Optimize, lowest piority
function GUIMinimap:InitializeLocationNames()

    self:UninitializeLocationNames()
    local locationData = PlayerUI_GetLocationData()

    -- Average the position of same named locations so they don't display
    -- multiple times.
    local multipleLocationsData = { }
    for _, location in ipairs(locationData) do

        -- Filter out the ready room.
        if location.Name ~= "Ready Room" then

            local locationTable = multipleLocationsData[location.Name]
            if locationTable == nil then

                locationTable = {}
                table.insert(multipleLocationsData, location.Name)
                multipleLocationsData[location.Name] = locationTable

            end
            table.insert(locationTable, location.Origin)

        end

    end

    local uniqueLocationsData = { }
    for _, name in ipairs(multipleLocationsData) do

        local origins = multipleLocationsData[name]
        local averageOrigin = Vector(0, 0, 0)
        table.foreachfunctor(origins, function (origin) averageOrigin = averageOrigin + origin end)
        table.insert(uniqueLocationsData, { Name = name, Origin = averageOrigin / #origins })

    end

    for _, location in ipairs(uniqueLocationsData) do

        local posX, posY = self:PlotToMap(location.Origin.x, location.Origin.z)

        -- Locations only supported on the big mode.
        local locationText = GUIManager:CreateTextItem()
        SetupLocationTextItem(locationText)
        locationText:SetColor(Color(1.0, 1.0, 1.0, 0.65))
        locationText:SetText(location.Name)
        locationText:SetPosition( Vector(posX, posY, 0) )

        self.minimap:AddChild(locationText)

        local locationItem = {text = locationText, origin = location.Origin}
        locationItem.text:SetColor( Color(1, 1, 1, GetAdvancedOption("locationalpha")))
        table.insert(self.locationItems, locationItem)

    end

end

function GUIMinimap:UninitializeLocationNames()

    for _, locationItem in ipairs(self.locationItems) do
        GUI.DestroyItem(locationItem.text)
    end

    self.locationItems = {}

end

function GUIMinimap:Uninitialize()

    for i = 1, #self.unusedMinimapConnections do
        local minimapConnection = self.unusedMinimapConnections[i]
        minimapConnection:Uninitialize()
    end

    if self.background then
        GUI.DestroyItem(self.background)
        self.background = nil
    end
end

function GUIMinimap:UpdatePlayerIcon()

    PROFILE("GUIMinimap:UpdatePlayerIcon")

    if PlayerUI_IsOverhead() and not PlayerUI_IsCameraAnimated() then -- Handle overhead viewplane points

        self.playerIcon:SetIsVisible(false)
        self.cameraLines:SetIsVisible(self.visible)

        local topLeftPoint, topRightPoint, bottomLeftPoint, bottomRightPoint = OverheadUI_ViewFarPlanePoints()
        if topLeftPoint == nil then
            return
        end

        topLeftPoint = Vector(self:PlotToMap(topLeftPoint.x, topLeftPoint.z))
        topRightPoint = Vector(self:PlotToMap(topRightPoint.x, topRightPoint.z))
        bottomLeftPoint = Vector(self:PlotToMap(bottomLeftPoint.x, bottomLeftPoint.z))
        bottomRightPoint = Vector(self:PlotToMap(bottomRightPoint.x, bottomRightPoint.z))

        self.cameraLines:ClearLines()
        local lineColor = Color(1, 1, 1, 1)
        self.cameraLines:AddLine(topLeftPoint, topRightPoint, lineColor)
        self.cameraLines:AddLine(topRightPoint, bottomRightPoint, lineColor)
        self.cameraLines:AddLine(bottomRightPoint, bottomLeftPoint, lineColor)
        self.cameraLines:AddLine(bottomLeftPoint, topLeftPoint, lineColor)

    elseif PlayerUI_IsAReadyRoomPlayer() then

        -- No icons for ready room players.
        self.cameraLines:SetIsVisible(false)
        self.playerIcon:SetIsVisible(false)

    else

        -- Draw a player icon representing this player's position.
        local playerOrigin = PlayerUI_GetPositionOnMinimap()
        local playerRotation = PlayerUI_GetMinimapPlayerDirection()

        local posX, posY = self:PlotToMap(playerOrigin.x, playerOrigin.z)

        self.cameraLines:SetIsVisible(false)
        self.playerIcon:SetIsVisible(self.visible)

        local playerIconColor = self.playerIconColor
        if playerIconColor ~= nil then
            playerIconColor = Color(playerIconColor.r, playerIconColor.g, playerIconColor.b, playerIconColor.a)
        elseif PlayerUI_IsOnMarineTeam() then
            playerIconColor = Color(kMarineTeamColorFloat)
        elseif PlayerUI_IsOnAlienTeam() then
            playerIconColor = Color(kAlienTeamColorFloat)
        else
            playerIconColor = Color(1, 1, 1, 1)
        end

        local animFraction = 1 - Clamp((Shared.GetTime() - self.timeMapOpened) / 0.5, 0, 1)
        playerIconColor.r = playerIconColor.r + animFraction
        playerIconColor.g = playerIconColor.g + animFraction
        playerIconColor.b = playerIconColor.b + animFraction
        playerIconColor.a = playerIconColor.a + animFraction

        local blipScale = self.blipScale
        local overLaySize = kShrinkingArrowInitSize * (animFraction * blipScale)
        local playerIconSize = Vector(kBlipSize * blipScale, kBlipSize * blipScale, 0)

        self.playerShrinkingArrow:SetSize(overLaySize)
        self.playerShrinkingArrow:SetPosition(-overLaySize * 0.5)
        local shrinkerColor = Color(playerIconColor.r, playerIconColor.g, playerIconColor.b, 0.35)
        self.playerShrinkingArrow:SetColor(shrinkerColor)

        self.playerIcon:SetSize(playerIconSize)
        self.playerIcon:SetColor(playerIconColor)

        -- move the background instead of the playericon in zoomed mode
        if self.moveBackgroundMode then
            local size = self.minimap:GetSize()
            local pos = Vector(-posX + size.x * -0.5, -posY + size.y * -0.5, 0)
            self.background:SetPosition(pos)
        end

        posX = posX - playerIconSize.x * 0.5
        posY = posY - playerIconSize.y * 0.5

        self.playerIcon:SetPosition(Vector(posX, posY, 0))

        local rotation = Vector(0, 0, playerRotation)

        self.playerIcon:SetRotation(rotation)
        self.playerShrinkingArrow:SetRotation(rotation)

        local playerClass = PlayerUI_GetPlayerClass()
        if self.playerClass ~= playerClass then

            local iconCol, iconRow = GetSpriteGridByClass(playerClass, kClassToGrid)
            self.playerIcon:SetTexturePixelCoordinates(GUIGetSprite(iconCol, iconRow, kIconWidth, kIconHeight))
            self.playerClass = playerClass

        end

    end

end

function GUIMinimap:LargeMapIsVisible()
    return self.background:GetIsVisible() and self.comMode == GUIMinimapFrame.kModeBig
end



local function CreateNewNameTag(self)
    local nameTag = GUIManager:CreateTextItem()

    nameTag:SetFontSize(kPlayerNameFontSize)
    nameTag:SetFontIsBold(false)
    nameTag:SetFontName(kPlayerNameFontName)
    nameTag:SetInheritsParentScaling(false)
    nameTag:SetScale(GetScaledVector())
    GUIMakeFontScale(nameTag)
    nameTag:SetAnchor(GUIItem.Middle, GUIItem.Center)
    nameTag:SetTextAlignmentX(GUIItem.Align_Center)
    nameTag:SetTextAlignmentY(GUIItem.Align_Center)
    nameTag:SetLayer(kPlayerNameLayer)
    nameTag:SetIsVisible(false)
    nameTag.lastUsed = Shared.GetTime()

    self.minimap:AddChild(nameTag)

    return nameTag
end

-- reuse nametags if they have not been used lately
local kNameTagReuseTimeout = 0.2
local function GetFreeNameTag(self, clientIndex)
    -- Try to reuse an old existing nametag
    local freeNameTag = table.remove(self.unusedNameTags)

    -- create a new nametag if there is not one to reuse, expensive & blocking !!!
    if freeNameTag == nil then
        freeNameTag = CreateNewNameTag(self)
    end

    freeNameTag.clientIndex = clientIndex
    self.nameTagMap:Insert(clientIndex, freeNameTag)

    return freeNameTag
end

function GUIMinimap:HideUnusedNameTags()
    PROFILE("GUIMinimap:HideUnusedNameTags")

    local now = Shared.GetTime()
    for clientIndex, nameTag in self.nameTagMap:Iterate() do
        if now - nameTag.lastUsed > kNameTagReuseTimeout then
            nameTag:SetIsVisible(false)
            table.insert(self.unusedNameTags, nameTag)
            self.nameTagMap:Remove(clientIndex)
        end
    end

end

-- Get the nameTag guiItem for the client
local function GetNameTag(self, clientIndex)
    local nameTag = self.nameTagMap:Get(clientIndex)
    if not nameTag then
        nameTag = GetFreeNameTag(self, clientIndex)
    end

    return nameTag

end

function GUIMinimap:DrawMinimapName(item, blipTeam, clientIndex, isParasited)
    PROFILE("GUIMinimap:DrawMinimapName")

    if self.showPlayerNames and clientIndex > 0 then

        local record = Scoreboard_GetPlayerRecord( clientIndex )

        if record and record.Name then

            local nameTag = GetNameTag(self, clientIndex)

            nameTag:SetIsVisible(self.visible)
            nameTag:SetText(record.Name)
            nameTag.lastUsed = Shared.GetTime()

            local nameColor = Color(1, 1, 1)
            if isParasited then
                nameColor.b = 0
            elseif self.spectating then
                if MinimapMappableMixin.OnSameMinimapBlipTeam(kMinimapBlipTeam.Marine, blipTeam) then
                    nameColor = kPlayerNameColorMarine
                else
                    nameColor = kPlayerNameColorAlien
                end
            end

            nameTag:SetColor(nameColor)

            local namePos = item:GetPosition() + GUIScale(kPlayerNameOffset)
            nameTag:SetPosition(namePos)

        end

    end

end


local function CreateIcon(self)

    local icon = table.remove(self.freeIcons)

    -- Expensive!!! Avoid at any cost
    if not icon then
        icon = GUIManager:CreateGraphicItem()
        icon:SetAnchor(GUIItem.Middle, GUIItem.Center)
        icon:SetIsVisible(false)
        self.minimap:AddChild(icon)
    end

    -- will cause it to initialize on next call to update.
    icon.resetMinimapItem = true
    return icon

end

local function CreateIconForEntity(self)
    local icon = CreateIcon(self)

    icon.version = 0 -- track last update time
    return icon
end

local function CreateIconForKey(self, key)
    local icon = CreateIcon(self)
    icon.key = key
    return icon
end

local function FreeIcon(self, icon)
    icon:SetIsVisible(false)
    table.insert(self.freeIcons, icon)
end

function GUIMinimap:RemoveEntityIcon(entityId)
    local icon = self.iconMap:Get(entityId)
    if icon then
        FreeIcon(self, icon)
        self.iconMap:Remove(entityId)
    end
end

GUIMinimap.kXZVector = Vector(1,0,1)
function GUIMinimap:UpdateBlipActivity()
    PROFILE("GUIMinimap:UpdateBlipActivity")

    -- used to get a unique number to check if icons are in use
    local now = Shared.GetTime()
    local invalidId = Entity.invalidId

    for k = 1, #kMinimapActivity do
        self.staticBlipData[k].blipIds = {}
        self.staticBlipData[k].count = 0
        self.staticBlipData[k].workIndex = 1
    end

    for _, entity in ientitylist(Shared.GetEntitiesWithTag("MinimapMappable")) do
        local id = entity:GetId()
        local addBlip = id ~= invalidId -- don't add/update blips for invalid ids

        -- don't add/update blips outside the update radius; saves CPU for marine HUD
        if addBlip and self.updateRadius > 0 then
            local diff = (self.playerOrigin - entity:GetMapBlipOrigin()) * self.kXZVector
            addBlip = diff:GetLengthSquared() < self.updateRadiusSquared
        end

        if addBlip then
            local icon = self.iconMap:Get(id)
            if not icon then
                icon = CreateIconForEntity(self)
                self.iconMap:Insert(id, icon)
            end

            local activity = entity:UpdateMinimapActivity(self, icon)
            if activity then
                local data = self.staticBlipData[activity]
                table.insert(data.blipIds, id)
                data.count = data.count + 1
                icon.version = now
            end
        end
    end

    -- clear out any icons no longer in use
    for id, icon in self.iconMap:IterateBackwards() do
        if icon.version < now then
            self:RemoveEntityIcon(id)
        end
    end

    -- Log("ActivityUpdate, data %s, numIcons %s, numFreeIcons %s", self.staticBlipData, table.countkeys(self.iconMap), #self.freeIcons)
end

function GUIMinimap:UpdateStaticIcon(entityId)
    PROFILE("GUIMinimap:UpdateStaticIcon")

    local icon = entityId and self.iconMap:Get(entityId)
    if icon then
        local entity = Shared.GetEntity(entityId)
        if not entity then
            icon:SetIsVisible(false)
        else
            entity:UpdateMinimapItem(self, icon)
        end
    end
end

function GUIMinimap:UpdateActivityBlips(deltaTime, activity)
    local data = self.staticBlipData[activity]
    if data.workIndex > data.count then
        data.workIndex = 1
    end

    local updateInterval = kBlipActivityUpdateInterval[activity] * GUIMinimap.kUpdateIntervalMultipler * self.updateIntervalMultipler
    local numBlipsToUpdateThisTime = 0
    if updateInterval > deltaTime then
        -- partial update
        numBlipsToUpdateThisTime = 1 + math.floor(deltaTime * data.count / updateInterval )
    else
        -- full update; reset workIndex
        numBlipsToUpdateThisTime = data.count
        data.workIndex = 1
    end

    local startIndex = data.workIndex
    local endIndex = math.min(data.count, data.workIndex + numBlipsToUpdateThisTime)

    if self.resetAll then
        startIndex = 1
        endIndex = data.count
    end
    -- Log("Update %s %s-%s (%s), ui %s", EnumToString(kMinimapActivity, activity), startIndex, endIndex, data.count, updateInterval)

    for i = 1, endIndex do
        local blipId = data.blipIds[i]
        self:UpdateStaticIcon(blipId)
    end

    data.workIndex = data.workIndex + numBlipsToUpdateThisTime
end

function GUIMinimap:UpdateStatic(deltaTime)
    PROFILE("GUIMinimap:UpdateStaticBlips:Static")
    self:UpdateActivityBlips(deltaTime, kMinimapActivity.Static)
end

function GUIMinimap:UpdateLow(deltaTime)
    PROFILE("GUIMinimap:UpdateStaticBlips:Low")
    self:UpdateActivityBlips(deltaTime, kMinimapActivity.Low)
end

function GUIMinimap:UpdateMedium(deltaTime)
    PROFILE("GUIMinimap:UpdateStaticBlips:Medium")
    self:UpdateActivityBlips(deltaTime, kMinimapActivity.Medium)
end

function GUIMinimap:UpdateHigh(deltaTime)
    PROFILE("GUIMinimap:UpdateStaticBlips:High")
    self:UpdateActivityBlips(deltaTime, kMinimapActivity.High)
end


function GUIMinimap:UpdateStaticBlips(deltaTime)
    PROFILE("GUIMinimap:UpdateStaticBlips")

    -- do like this just to get profiling
    self:UpdateStatic(deltaTime)
    self:UpdateLow(deltaTime)
    self:UpdateMedium(deltaTime)
    self:UpdateHigh(deltaTime)

end

local function UpdateScansAndHighlight(self)
    local blipSize = self.blipSizeTable[kBlipSizeType.Normal]
    local now = Shared.GetTime()

    -- Update scan blip size and color.
    do
        local scanAnimFraction = (now % kScanAnimDuration) / kScanAnimDuration
        local scanBlipScale = 1.0 + scanAnimFraction * 9.0 -- size goes from 1.0 to 10.0
        local scanAnimAlpha = 1 - scanAnimFraction
        scanAnimAlpha = scanAnimAlpha * scanAnimAlpha

        self.scanColor.a = scanAnimAlpha
        self.scanSize.x = blipSize.x * scanBlipScale -- do not change blipSizeTable reference
        self.scanSize.y = blipSize.y * scanBlipScale -- do not change blipSizeTable reference
    end

    local _, highlightTime = GetHighlightPosition()
    if highlightTime then

        local createAnimFraction = 1 - Clamp((now - highlightTime) / 1.5, 0, 1)
        local sizeAnim = (1 + math.sin(now * 6)) * 0.25 + 2

        local blipScale = createAnimFraction * 15 + sizeAnim

        self.highlightWorldSize.x = blipSize.x * blipScale
        self.highlightWorldSize.y = blipSize.y * blipScale

        self.highlightWorldColor.a = 0.7 + 0.2 * math.sin(now * 5) + createAnimFraction

    end

    local etherealGateAnimFraction = 0.25 + (1 + math.sin(now * 10)) * 0.5 * 0.75
    self.etherealGateColor.a = etherealGateAnimFraction

    self.blipSizeTable[kBlipSizeType.Scan] = self.scanSize
    self.blipSizeTable[kBlipSizeType.HighlightWorld] = self.highlightWorldSize

end

local function GetFreeDynamicBlip(self, xPos, yPos, blipType)

    local returnBlip = table.remove(self.reuseDynamicBlips)

    -- Create a new blip object when neccesary; Expansive & blocking !
    if not returnBlip then
        local returnBlipItem = GUIManager:CreateGraphicItem()
        returnBlipItem:SetLayer(kDynamicBlipsLayer) -- Make sure these draw a layer above the minimap so they are on top.
        returnBlipItem:SetTexture(kBlipTexture)
        returnBlipItem:SetBlendTechnique(GUIItem.Add)
        returnBlipItem:SetAnchor(GUIItem.Middle, GUIItem.Center)
        self.minimap:AddChild(returnBlipItem)

        returnBlip = { Item = returnBlipItem }
    end

    returnBlip.X = xPos
    returnBlip.Y = yPos
    returnBlip.Type = blipType

    local returnBlipItem = returnBlip.Item
    returnBlipItem:SetIsVisible(self.visible)
    returnBlipItem:SetColor(Color(1, 1, 1, 1))
    returnBlipItem:SetPosition(Vector(self:PlotToMap(xPos, yPos)))
    GUISetTextureCoordinatesTable(returnBlipItem, kBlipTextureCoordinates[blipType])
    returnBlipItem:SetStencilFunc(self.stencilFunc)

    self.inuseDynamicBlips:Insert(returnBlip)

    return returnBlip

end

local function AddDynamicBlip(self, xPos, yPos, blipType)

    --
    -- Blip types - kAlertType
    --
    -- 0 - Attack
    -- Attention-getting spinning squares that start outside the minimap and spin down to converge to point
    -- on map, continuing to draw at point for a few seconds).
    --
    -- 1 - Info
    -- Research complete, area blocked, structure couldn't be built, etc. White effect, not as important to
    -- grab your attention right away).
    --
    -- 2 - Request
    -- Soldier needs ammo, asking for order, etc. Should be yellow or green effect that isn't as
    -- attention-getting as the under attack. Should draw for a couple seconds.)
    --

    if blipType == kAlertType.Attack then

        local addedBlip = GetFreeDynamicBlip(self, xPos, yPos, blipType)
        addedBlip.Item:SetSize(Vector(0, 0, 0))
        addedBlip.Time = Shared.GetTime() + kAttackBlipTime

    end

end

-- Initialize a minimap item (icon) from a blipType
function GUIMinimap:InitMinimapIcon(item, blipType, blipTeam)

    local blipInfo = self.blipInfoTable[blipType]
    local texCoords, colorType, sizeType, layer = blipInfo[1], blipInfo[2], blipInfo[3], blipInfo[4]

    item.blipType = blipType
    item.blipSizeType = sizeType
    item.blipSize = self.blipSizeTable[item.blipSizeType]
    item.blipTeam = blipTeam
    item.blipColor = self.blipColorTable[item.blipTeam][colorType]

    item:SetLayer(layer)
    item:SetTexturePixelCoordinates(GUIUnpackCoords(texCoords))
    item:SetSize(item.blipSize)
    item:SetColor(item.blipColor)
    item:SetStencilFunc(self.stencilFunc)
    item:SetTexture(self.iconFileName)
    item:SetIsVisible(self.visible)

    item.resetMinimapItem = false

    return item
end

local _blipPos = Vector(0,0,0) -- avoid GC
function GUIMinimap:UpdateBlipPosition(item, origin)
    if origin ~= item.prevBlipOrigin then
        item.prevBlipOrigin = origin
        local xPos, yPos = self:PlotToMap(origin.x, origin.z)
        _blipPos.x = xPos - item.blipSize.x * 0.5
        _blipPos.y = yPos - item.blipSize.y * 0.5
        item:SetPosition(_blipPos)
    end
end


local function AddLocalBlip(self, key, position, blipType, blipTeam)

    local blip = {}
    blip.key = key
    blip.position = position
    blip.blipType = blipType
    blip.blipTeam = blipTeam
    blip.icon = CreateIconForKey(self, key)

    self.localBlipData:Insert(key, blip)

    return blip

end

local function RemoveLocalBlip(self, key)
    local blip = self.localBlipData:Remove(key)
    if blip then
        local icon = blip.icon
        if icon then
            FreeIcon(self, icon)
        end
    end
end

local function DrawLocalBlip(self, blipData)

    local icon = blipData.icon
    if icon.resetMinimapItem then
        self:InitMinimapIcon(icon, blipData.blipType, blipData.blipTeam)
    end

    self:UpdateBlipPosition(icon, blipData.position)

end

function GUIMinimap:DrawLocalBlips()
    PROFILE("GUIMinimap:DrawLocalBlips")

    for _, blipData in self.localBlipData:Iterate() do
        DrawLocalBlip(self, blipData)
    end

end


-- update the list of non-entity related mapblips
local function UpdateLocalBlips(self)

    local key = "spawn"
    local blip = self.localBlipData:Get(key)
    local active = false
    if GetPlayerIsSpawning() then
        local spawnPosition = GetDesiredSpawnPosition()
        if spawnPosition then
            if not blip then
                blip = AddLocalBlip(self, key, spawnPosition, kMinimapBlipType.MoveOrder, kMinimapBlipTeam.Friendly)
            end
            active = true
            blip.position = spawnPosition
        end
    end
    if not active and blip then
        RemoveLocalBlip(self, key)
    end

    key = "highlight"
    blip = self.localBlipData:Get(key)
    active = false
    local highlightPos = GetHighlightPosition()
    if highlightPos then
        if not blip then
            blip = AddLocalBlip(self, key, highlightPos, kMinimapBlipType.HighlightWorld, kMinimapBlipTeam.Friendly)
        end
    end
    if not active and blip then
        RemoveLocalBlip(self, key)
    end

end

local function RemoveDynamicBlip(self, blip)

    blip.Item:SetIsVisible(false)
    table.insert(self.reuseDynamicBlips, blip)
    self.inuseDynamicBlips:Remove(blip)

end

-- Returns true when the attack blip did run out of "life time"
local function UpdateAttackBlip(self, blip)
    local blipLifeRemaining = blip.Time - Shared.GetTime()
    local blipItem = blip.Item
    -- Fade in.
    if blipLifeRemaining >= kAttackBlipFadeInTime then

        local fadeInAmount = ((kAttackBlipTime - blipLifeRemaining) / (kAttackBlipTime - kAttackBlipFadeInTime))
        blipItem:SetColor(Color(1, 1, 1, fadeInAmount))

    else
        blipItem:SetColor(Color(1, 1, 1, 1))
    end

    -- Fade out.
    if blipLifeRemaining <= kAttackBlipFadeOutTime then

        if blipLifeRemaining <= 0 then
            return true
        end
        blipItem:SetColor(Color(1, 1, 1, blipLifeRemaining / kAttackBlipFadeOutTime))

    end

    local pulseAmount = (math.sin(blipLifeRemaining * kAttackBlipPulseSpeed) + 1) / 2
    local blipSize = LerpGeneric(kAttackBlipMinSize, kAttackBlipMaxSize / 2, pulseAmount)

    blipItem:SetSize(blipSize)
    -- Make sure it is always centered.
    local sizeDifference = kAttackBlipMaxSize - blipSize
    local xOffset = (sizeDifference.x / 2) - kAttackBlipMaxSize.x / 2
    local yOffset = (sizeDifference.y / 2) - kAttackBlipMaxSize.y / 2
    local plotX, plotY = self:PlotToMap(blip.X, blip.Y)
    blipItem:SetPosition(Vector(plotX + xOffset, plotY + yOffset, 0))

    -- Not done yet.
    return false

end

local function UpdateDynamicBlips(self)
    PROFILE("GUIMinimap:UpdateDynamicBlips")

    local newDynamicBlips = CommanderUI_GetDynamicMapBlips()
    for i = 1, #newDynamicBlips - 2, 3 do

        local blipType = newDynamicBlips[i + 2]
        AddDynamicBlip(self, newDynamicBlips[i], newDynamicBlips[i + 1], blipType)

    end

    for blip in self.inuseDynamicBlips:Iterate() do

        if blip.Type == kAlertType.Attack then

            if UpdateAttackBlip(self, blip) then
                RemoveDynamicBlip(self, blip)
            end

        end
    end

end

function GUIMinimap:UpdateMapClick()

    PROFILE("GUIMinimap:UpdateMapClick")

    if PlayerUI_IsOverhead() then

        -- Don't teleport if the command is dragging a selection or pinging.
        if PlayerUI_IsACommander() and (not CommanderUI_GetUIClickable() or GetCommanderPingEnabled()) then
            return
        end

        local mouseX, mouseY = Client.GetCursorPosScreen()
        if self.mouseButton0Down and not (self.comMode == GUIMinimapFrame.kModeMini and gBotDebugWindow ~= nil) then

            local containsPoint = GUIItemContainsPoint(self.minimap, mouseX, mouseY)
            if containsPoint then

                local minimapSize = self:GetMinimapSize()
                local backgroundScreenPosition = self.minimap:GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())

                local cameraPosition = Vector(mouseX, mouseY, 0)

                cameraPosition.x = cameraPosition.x - backgroundScreenPosition.x
                cameraPosition.y = cameraPosition.y - backgroundScreenPosition.y

                local horizontalScale = OverheadUI_MapLayoutHorizontalScale()
                local verticalScale = OverheadUI_MapLayoutVerticalScale()

                local moveX = (cameraPosition.x / minimapSize.x) * horizontalScale
                local moveY = (cameraPosition.y / minimapSize.y) * verticalScale

                OverheadUI_MapMoveView(moveX, moveY)

            end

        end

    end

end

local function GetFreeMinimapConnection(self)
    -- first try to reuse an unused minimap connection
    local minimapConnection = table.remove(self.unusedMinimapConnections)

    -- otherwise create a new one
    if minimapConnection == nil then
        minimapConnection = GUIMinimapConnection() --expensive
    end

    minimapConnection:SetStencilFunc(self.stencilFunc)

    return minimapConnection
end

local function RemoveMinimapConnection(self, index)
    local minimapConnection = self.minimapConnections[index]
    if not minimapConnection then return end

    minimapConnection:SetIsVisible(false)
    table.insert(self.unusedMinimapConnections, minimapConnection)
    self.minimapConnections[index] = nil
end

local tunnelColorTable = {
    Color(247/255.0, 220/255.0, 111/255.0,1), Color(248/255.0, 196/255.0, 113/255.0,1), Color(240/255.0, 178/255.0, 122/255.0,1), Color(229/255.0, 152/255.0, 102/255.0,1),
    Color(244/255.0, 208/255.0, 63/255.0,1), Color(245/255.0, 176/255.0, 65/255.0,1), Color(235/255.0, 152/255.0, 78/255.0,1), Color(220/255.0, 118/255.0, 51/255.0,1),
    Color(241/255.0, 196/255.0, 15/255.0,1), Color(243/255.0, 156/255.0, 18/255.0,1), Color(230/255.0, 126/255.0, 34/255.0,1), Color(221/255.0, 84/255.0, 0/255.0,1),
}

local function getLineColor(tunnelIndex)
    local colorIndex = (tunnelIndex % #tunnelColorTable) + 1
    return tunnelColorTable[colorIndex]
end

local function UpdateConnections(self)
    local mapConnectors = Shared.GetEntitiesWithClassname("MapConnector")
    local numConnectors = 0
    local tunnelEntranceIndex = 0
    for _, connector in ientitylist(mapConnectors) do
        -- using numConnectors as index for minimapConnections as the mapConnectors list may contain invalid ents
        numConnectors = numConnectors + 1

        local minimapConnection = self.minimapConnections[numConnectors]
        if not minimapConnection then
            minimapConnection = GetFreeMinimapConnection(self)
        end

        local origin = connector:GetOrigin()
        local cEndPoint = connector:GetEndPoint()
        local startPoint = Vector(self:PlotToMap(origin.x, origin.z))
        local endPoint = Vector(self:PlotToMap(cEndPoint.x, cEndPoint.z))

        minimapConnection:Setup(startPoint, endPoint, self.minimap)
        if(connector:GetTeamNumber() == kTeam2Index) then
            minimapConnection:UpdateAnimation_Alien(self.comMode == GUIMinimapFrame.kModeMini, getLineColor(tunnelEntranceIndex))
            tunnelEntranceIndex = tunnelEntranceIndex + 1
        else
            minimapConnection:UpdateAnimation(connector:GetTeamNumber(), self.comMode == GUIMinimapFrame.kModeMini)
        end

        self.minimapConnections[numConnectors] = minimapConnection
    end

    local numMinimapConnections = #self.minimapConnections
    for i = numMinimapConnections, numConnectors + 1, -1 do
        RemoveMinimapConnection(self, i)
    end

    --Print("num minimap connections %s", ToString(#self.minimapConnections))
end

local function UpdateCommanderPing(self)
    -- update commander ping
    if self.commanderPing then

        for _, entity in ientitylist(Shared.GetEntitiesWithClassname("TeamInfo")) do

            local pingTime = entity:GetPingTime()

            if pingTime ~= self.commanderPing.expiredPingTime then

                local player = Client.GetLocalPlayer()
                local timeSincePing, position = PlayerUI_GetPingInfo(player, entity, true)
                local posX, posY = self:PlotToMap(position.x, position.z)
                self.commanderPing.Frame:SetPosition(Vector(posX, posY, 0))
                self.commanderPing.Frame:SetIsVisible(timeSincePing <= kCommanderPingDuration and self.visible)

                local expired = GUIAnimateCommanderPing(self.commanderPing.Mark, self.commanderPing.Border, self.commanderPing.Location, kCommanderPingMinimapSize, timeSincePing, Color(1, 0, 0, 1), Color(1, 1, 1, 1))
                if expired then
                    -- block ping animation now that it has expired
                    self.commanderPing.expiredPingTime = pingTime
                end

            end
            -- only do it for the first found TeamInfo - should be only one?
            break
        end
    end
end

-- once we hit the misc update time, we step through each function and do them one per frame... spreads the load a bit
local kMiscUpdateStepFunctions = {
    UpdateDynamicBlips,
    UpdateConnections,
    UpdateScansAndHighlight,
    UpdateCommanderPing,
    UpdateLocalBlips,
}

function GUIMinimap:CheckMinimapConnectionTextures()

    for _, connectionLine in ipairs(self.minimapConnections) do
        connectionLine:CheckLineTexture()
    end
end

function GUIMinimap:Update(deltaTime)

    if self.background:GetIsVisible() then

        PROFILE("GUIMinimap:Update")

        local now = Shared.GetTime()
        local player = Client.GetLocalPlayer()

        -- need to recalc the player team because it may have changed
        -- maybe smarter to rebuild gui scripts on team change...
        local playerTeam = player:GetTeamNumber()
        if playerTeam == kMarineTeamType then
            playerTeam = kMinimapBlipTeam.Marine
        elseif playerTeam == kAlienTeamType then
            playerTeam = kMinimapBlipTeam.Alien
        end
        self.playerTeam = playerTeam

        self.playerOrigin = player:GetOrigin()

        if now > self.nextMiscUpdateInterval and not self.miscUpdateStep then

            self.nextMiscUpdateInterval = now + kMiscUpdateInterval * GUIMinimap.kUpdateIntervalMultipler * self.updateIntervalMultipler
            self.miscUpdateStep = 1

        end

        if self.miscUpdateStep then

            kMiscUpdateStepFunctions[self.miscUpdateStep](self)
            self.miscUpdateStep = self.miscUpdateStep + 1
            if self.miscUpdateStep > #kMiscUpdateStepFunctions then
                self.miscUpdateStep = nil
            end

        end


        self:UpdatePlayerIcon()
        self:UpdateMapClick()


        self:UpdateStaticBlips(deltaTime)
        self:DrawLocalBlips()

        if now > self.nextActivityUpdateTime then
            self.nextActivityUpdateTime = now + kActivityUpdateInterval * GUIMinimap.kUpdateIntervalMultipler * self.updateIntervalMultipler
            self:UpdateBlipActivity()
            -- do other things we only need to do very rarely..
            self:HideUnusedNameTags()
            self.showPlayerNames = kMinimapShowPlayerNames == true and self:LargeMapIsVisible()
            self.spectating = player:GetTeamType() == kNeutralTeamType
            self.clientIndex = player:GetClientIndex()
            local r = self.updateRadius / self.scale
            self.updateRadiusSquared = r * r
        end

        self.resetAll = false

    end

end

function GUIMinimap:GetMinimapSize()
    return Vector(GUIMinimap.kBackgroundWidth * self.scale, GUIMinimap.kBackgroundHeight * self.scale, 0)
end

-- Shows or hides the big map.
function GUIMinimap:ShowMap(showMap)

    if self.background:GetIsVisible() ~= showMap then

        self.background:SetIsVisible(showMap and self.visible)
        if showMap then

            self.timeMapOpened = Shared.GetTime()
            self:Update(0)

        end

        self:UpdatePlayerMinimapVisible()

    end

end


function GUIMinimap:UpdatePlayerMinimapVisible()
    if not self.setsPlayerMinimapVisible then return end
    Client.GetLocalPlayer():SetIsMinimapVisible(self.comMode == GUIMinimapFrame.kModeBig and self.background:GetIsVisible())
end

function GUIMinimap:SetPlayerMapVisibleCheckingEnabled(enable)
    self.setsPlayerMinimapVisible = enable
end

function GUIMinimap:OnLocalPlayerChanged()
    self:ShowMap(false)
end

function GUIMinimap:ContainsPoint(pointX, pointY)
    return GUIItemContainsPoint(self.background, pointX, pointY) or GUIItemContainsPoint(self.minimap, pointX, pointY)
end

function GUIMinimap:GetBackground()
    return self.background
end

function GUIMinimap:GetMinimapItem()
    return self.minimap
end

function GUIMinimap:SetButtonsScript(setButtonsScript)
    self.buttonsScript = setButtonsScript
end

function GUIMinimap:SetLocationNamesEnabled(enabled)
    for _, locationItem in ipairs(self.locationItems) do
        locationItem.text:SetIsVisible(enabled and self.visible)
    end
end

-- set the resetAll flag; next Update() all blips will be fully updated (avoids uglyness when zooming)
function GUIMinimap:ResetAll()
    self.resetAll = true
    for _, icon in self.iconMap:Iterate() do
        icon.resetMinimapItem = true
    end
end

function GUIMinimap:SetScale(scale)
    if scale ~= self.scale then
        self.scale = scale
        self:ResetAll()

        if Client.legacyMinimap then
            -- This map's overview was generated with the pre-build-320 overview.exe, meaning we have to use
            -- old code for blips to continue to map correctly to the overview image.  If nil, it simply
            -- indicates it's an old version of the level that has not been saved with a >=320 editor setup.
            -- The author can also set this value to true if they wish to keep the old overview.
            -- When opening an old map, the value "useLegacyOverview" will default to false if it is not found.

            -- compute map to minimap transformation matrix
            local xFactor = 2 * self.scale
            local mapRatio = ConditionalValue(Client.minimapExtentScale.z > Client.minimapExtentScale.x, Client.minimapExtentScale.z / Client.minimapExtentScale.x, Client.minimapExtentScale.x / Client.minimapExtentScale.z)
            local zFactor = xFactor / mapRatio
            self.plotToMapConstX = -Client.minimapExtentOrigin.x
            self.plotToMapConstY = -Client.minimapExtentOrigin.z
            self.plotToMapLinX = GUIMinimap.kBackgroundHeight / (Client.minimapExtentScale.x / xFactor)
            self.plotToMapLinY = GUIMinimap.kBackgroundWidth / (Client.minimapExtentScale.z / zFactor)

        else

            -- compute map to minimap transformation
            self.plotXOffset = -Client.minimapExtentOrigin.x
            self.plotZOffset = -Client.minimapExtentOrigin.z

            -- Flip x axis for conversion from world space to gui-space coords.
            local worldXHalfExtents = Client.minimapExtentScale.x * kMinimapExtentsModelScaleFactor
            local worldZHalfExtents = Client.minimapExtentScale.z * kMinimapExtentsModelScaleFactor

            local worldHalfExtents = math.max(worldXHalfExtents, worldZHalfExtents)

            local minimapXHalfExtents = GUIMinimap.kBackgroundHeight * 0.5
            local minimapZHalfExtents = GUIMinimap.kBackgroundWidth * 0.5
            self.plotXFactor = (minimapXHalfExtents * scale) / -worldHalfExtents
            self.plotZFactor = (minimapZHalfExtents * scale) / worldHalfExtents

        end

        -- update overview size
        if self.minimap then
            local size = Vector(GUIMinimap.kBackgroundWidth * scale, GUIMinimap.kBackgroundHeight * scale, 0)
            self.minimap:SetSize(size)
        end

        -- reposition location names
        if self.locationItems then
            for _, locationItem in ipairs(self.locationItems) do
                local mapPos = Vector(self:PlotToMap(locationItem.origin.x, locationItem.origin.z ))
                SetLocationTextPosition( locationItem, mapPos )
            end
        end


    end
end

function GUIMinimap:GetScale()
    return self.scale
end

function GUIMinimap:SetBlipScale(blipScale)

    if blipScale ~= self.blipScale then

        self.blipScale = blipScale
        self:ResetAll()

        local blipSizeTable = self.blipSizeTable
        local blipSize = Vector(kBlipSize, kBlipSize, 0)
        blipSizeTable[kBlipSizeType.Normal] = blipSize * (0.7 * blipScale)
        blipSizeTable[kBlipSizeType.TechPoint] = blipSize * blipScale
        blipSizeTable[kBlipSizeType.Infestation] = blipSize * (2 * blipScale)
        blipSizeTable[kBlipSizeType.Egg] = blipSize * (0.7 * 0.5 * blipScale)
        blipSizeTable[kBlipSizeType.Worker] = blipSize * (blipScale)
        blipSizeTable[kBlipSizeType.EtherealGate] = blipSize * (1.5 * blipScale)
        blipSizeTable[kBlipSizeType.Waypoint] = blipSize * (1.5 * blipScale)
        blipSizeTable[kBlipSizeType.BoneWall] = blipSize * (1.5 * blipScale)
        blipSizeTable[kBlipSizeType.UnpoweredPowerPoint] = blipSize * (0.45 * blipScale)

    end

end

function GUIMinimap:GetBlipScale()
    return self.blipScale
end

function GUIMinimap:SetMoveBackgroundEnabled(enabled)
    self.moveBackgroundMode = enabled
end

function GUIMinimap:SetStencilFunc(stencilFunc)

    self.stencilFunc = stencilFunc

    self.minimap:SetStencilFunc(stencilFunc)
    self.commanderPing.Mark:SetStencilFunc(stencilFunc)
    self.commanderPing.Border:SetStencilFunc(stencilFunc)

    for blip in self.inuseDynamicBlips:Iterate() do
        blip.Item:SetStencilFunc(stencilFunc)
    end

    for _, icon in self.iconMap:Iterate() do
        icon:SetStencilFunc(stencilFunc)
    end

    for _, connectionLine in ipairs(self.minimapConnections) do
        connectionLine:SetStencilFunc(stencilFunc)
    end

end

function GUIMinimap:SetPlayerIconColor(color)
    self.playerIconColor = color
end

function GUIMinimap:SetIconFileName(fileName)
    local iconFileName = ConditionalValue(fileName, fileName, kIconFileName)
    self.iconFileName = iconFileName

    self.playerIcon:SetTexture(iconFileName)
    for _, icon in self.iconMap:Iterate() do
        icon:SetTexture(iconFileName)
    end
end

function OnToggleMinimapNames()
    if kMinimapShowPlayerNames == true then
        kMinimapShowPlayerNames = false
        Shared.Message("Minimap Names is now set to OFF")
    else
        kMinimapShowPlayerNames = true
        Shared.Message("Minimap Names is now set to ON")
    end
end

function OnChangeMinimapUpdateRate(mul)
    if Client then
        if mul then
            GUIMinimap.kUpdateIntervalMultipler = Clamp(tonumber(mul), 0, 5)
        end
        Log("Minimap update interval multipler: %s", GUIMinimap.kUpdateIntervalMultipler)
    end
end

Event.Hook("Console_minimap_rate", OnChangeMinimapUpdateRate)
Event.Hook("Console_minimapnames", OnToggleMinimapNames)
Event.Hook("Console_setmaplocationcolor", OnCommandSetMapLocationColor)

Event.Hook("Console_td_dump_minimap_data", function(method)

    local player = Client.GetLocalPlayer()
    assert(player, "Error: no local player entity found")
    assert(player:isa("Spectator"), "Error: Command can only be run as a Spectator")

    --local util to convert entity origin to uniform 0-1 scale coords
    local ConvertCoords = function( x, y, map )
        local scaled = { x = 0, y = 0 }

        local pScale = map.scale    --cache to bypass client settings
        map.scale = 1.0
        local coords = Vector( map:PlotToMap( x, y ) )

        --normalize
        scaled.x = coords.x / map.kBackgroundWidth
        scaled.y = coords.y / map.kBackgroundHeight

        map.scale = pScale  --restore

        return scaled
    end

    local writeMethod = ( method ~= nil and method ~= "" and method == "lua" ) and "lua" or "json"
    local dumpLua = writeMethod == "lua"
    local luaOut = ""
    local luaLocationsOut = ""
    local luaTechpointsOut = ""
    local luaResourcepointsOut = ""
    local luaPowerpointsOut = ""

    local miniMapData =
    {
        ["Locations"] = {},
        ["TechPoints"] = {},
        ["ResourcePoints"] = {},
        ["PowerPoints"] = {}
    }

    local map = ClientUI.GetScript("GUIMinimapFrame")
    assert(map, "Failed to fetch GUIMinimap script object")

    Log("Parsing Locations data...")

    local locations = map.locationItems
    assert(locations and #locations > 0, "Failed to fetch Locations data")

    for i = 1, #locations do
        local location = locations[i]
        assert(location.text and location.origin)
        if location.text:GetText() ~= "Ready Room" then
            local coords = ConvertCoords( location.origin.x, location.origin.z, map )
            table.insert(miniMapData["Locations"], { Name = location.text:GetText(), x = coords.x, y = coords.y } )
            if dumpLua then
                luaLocationsOut = luaLocationsOut .. "    { name = \"" .. location.text:GetText() .. "\", x = " .. coords.x .. ", y = " .. coords.y .. " },\n"
            end
        end
    end
    Log("\t Parsed - %s Locations", #miniMapData["Locations"])

    Log("Parsing minimap icon data...")

    local staticBlips = map.staticBlipData[kMinimapActivity.Static]
    local sData = staticBlips.blipIds
    assert(sData)

    for i = 1, #sData do
        local blipEnt = Shared.GetEntity( sData[i] )
        assert(blipEnt, "Error: no entity found for map-blip ID: %s", sData[i])
        local blipType = blipEnt:GetMapBlipType()
        local blipOrg = blipEnt:GetOrigin()
        local coords = ConvertCoords( blipOrg.x, blipOrg.z, map )
        local angles = blipEnt:GetAngles()

        if blipType == kMinimapBlipType.TechPoint then

            -- Tech point _spawn_ team number
            local tpTeamNumber = 0
            local entID = blipEnt:GetOwnerEntityId()
            local techpointEnt = Shared.GetEntity(entID)
            if techpointEnt then
                tpTeamNumber = techpointEnt.allowedTeamNumber
            else
                Log("WARNING: Could not get owner entity for minimap techpoint blip!")
            end

            table.insert( miniMapData["TechPoints"], { x = coords.x, y = coords.y, angle = math.deg(angles.yaw), team = tpTeamNumber } )
            if dumpLua then
                luaTechpointsOut = luaTechpointsOut .. "    { x = " .. coords.x .. ", y = " .. coords.y .. ", angle = " .. math.deg(angles.yaw) .. ", team = " .. tpTeamNumber .. " },\n"
            end

        elseif blipType == kMinimapBlipType.ResourcePoint then
            table.insert( miniMapData["ResourcePoints"], { x = coords.x, y = coords.y, angle = math.deg(angles.yaw) } )
            if dumpLua then
                luaResourcepointsOut = luaResourcepointsOut .. "    { x = " .. coords.x .. ", y = " .. coords.y .. ", angle = " .. math.deg(angles.yaw) .. " },\n"
            end

        elseif blipType == kMinimapBlipType.PowerPoint or blipType == kMinimapBlipType.UnsocketedPowerPoint or blipType == kMinimapBlipType.DestroyedPowerPoint or blipType == kMinimapBlipType.BlueprintPowerPoint then
            table.insert( miniMapData["PowerPoints"], { x = coords.x, y = coords.y, angle = math.deg(angles.yaw) } )
            if dumpLua then
                luaPowerpointsOut = luaPowerpointsOut .. "    { x = " .. coords.x .. ", y = " .. coords.y .. ", angle = " .. math.deg(angles.yaw) .. " },\n"
            end

        end
    end

    assert(#miniMapData["TechPoints"] > 0, "Error: No TechPoints found in minimap data")
    assert(#miniMapData["ResourcePoints"] > 0, "Error: No ResourcePoints found in minimap data")
    assert(#miniMapData["PowerPoints"] > 0, "Error: No PowerPoints found in minimap data")
    Log("\t Parsed - %s TechPoints, %s ResourcePoints, and %s PowerPoints", #miniMapData["TechPoints"], #miniMapData["ResourcePoints"], #miniMapData["PowerPoints"])

    if writeMethod == "json" then
        local fileName = Shared.GetMapName() .. "_minimap_data.json"
        Log("Writing minimap data to: config://%s", fileName)

        local jsonFile = io.open("config://" .. fileName, "w+")
        if jsonFile == nil then
            Log("ERROR: Failed to create/read minimap json data file")
            return
        end

        jsonFile:write(json.encode(miniMapData, { indent = true }))
        io.close(jsonFile)

    elseif writeMethod == "lua" then
        --dump the cumulative lua-table-format string to log, use \n to make copy pasta easy

        luaOut = "[kThunderdomeMaps." .. Shared.GetMapName() .. "] = \n{\n" .. "--Locations\n{\n" .. luaLocationsOut .. "},\n\n"
                .. "--TechPoints\n{\n" .. luaTechpointsOut .. "},\n\n" .. "--ResourcePoints\n{\n" .. luaResourcepointsOut .. "},\n\n"
                .. "--PowerPoints\n{\n" .. luaPowerpointsOut .. "},\n\n"
                .. "}\n\n"

        local fileName = Shared.GetMapName() .. "_minimap_data.lua"
        Log("Writing minimap data to: config://%s", fileName)

        local luaFile = io.open("config://" .. fileName, "w+")
        if luaFile == nil then
            Log("ERROR: Failed to create/read minimap json data file")
            return
        end

        luaFile:write( luaOut )
        io.close(luaFile)
    end

    Log("DONE")

end)