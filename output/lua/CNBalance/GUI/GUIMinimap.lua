local kBlipColorType = debug.getupvaluex(GUIMinimap.Initialize ,"kBlipColorType")
local kBlipSizeType = debug.getupvaluex(GUIMinimap.Initialize ,"kBlipSizeType")
local kClassToGrid = debug.getupvaluex(GUIMinimap.Initialize,"kClassToGrid")

local kInfestationBlipsLayer = 0
local kBackgroundBlipsLayer = 1
local kStaticBlipsLayer = 2
local kDynamicBlipsLayer = 3
local kLocationNameLayer = 4 
local kPingLayer = 5    local kWaypointLayer = 7
local kPlayerIconLayer = 6

local kBlipInfo = {}
kBlipInfo[kMinimapBlipType.MoveOrder] = { kBlipColorType.Waypoint, kBlipSizeType.Waypoint, kWaypointLayer }
kBlipInfo[kMinimapBlipType.AttackOrder] = { kBlipColorType.Waypoint, kBlipSizeType.Waypoint, kWaypointLayer }
kBlipInfo[kMinimapBlipType.BuildOrder] = { kBlipColorType.Waypoint, kBlipSizeType.Waypoint, kWaypointLayer }
kBlipInfo[kMinimapBlipType.Pheromone_Defend] = { kBlipColorType.Waypoint, kBlipSizeType.Waypoint, kWaypointLayer }
kBlipInfo[kMinimapBlipType.Pheromone_Expand] = { kBlipColorType.Waypoint, kBlipSizeType.Waypoint, kWaypointLayer }
kBlipInfo[kMinimapBlipType.Pheromone_Threat] = { kBlipColorType.Waypoint, kBlipSizeType.Waypoint, kWaypointLayer }

local kIconWidth = 32
local kIconHeight = 32

local baseInitialize = GUIMinimap.Initialize
function GUIMinimap:Initialize()
    -- Initialize blip info lookup table
    baseInitialize(self)
    for blipType = 1, #kMinimapBlipType do
        local blipInfo = kBlipInfo[blipType]
        if blipInfo then
            local iconCol, iconRow = GetSpriteGridByClass((blipInfo and blipInfo[4]) or EnumToString(kMinimapBlipType, blipType), kClassToGrid)
            local texCoords = table.pack(GUIGetSprite(iconCol, iconRow, kIconWidth, kIconHeight))
            self.blipInfoTable[blipType] = { texCoords, blipInfo[1], blipInfo[2], blipInfo[3] }
        end
        
        --for blipTeam = 1, #kMinimapBlipTeam do
        --    self.blipColorTable[blipTeam][kBlipColorType.Waypoint] = Color(252.0/255.0, 243/255.0, 207/255.0, 1)
        --    self.blipColorTable[blipTeam][kBlipColorType.Drifter] = Color(229.0/255.0, 152/255.0, 102/255.0, 1)
        --end
    end
end