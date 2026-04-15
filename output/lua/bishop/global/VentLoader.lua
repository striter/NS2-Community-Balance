Script.Load("lua/Table.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

---Contains prepared vent data structures for the currently loaded map.
Bishop.global.vents.data = {}

local CreatePlane = Bishop.lib.math.CreatePlane
local ExpandVolume = Bishop.lib.math.ExpandVolume

---Returns the length of the given path.
---@param path Vector[]
---@return number
local function GetSegmentLength(path)
  local length = 0
  for i = 2, #path do
    length = length + path[i-1]:GetDistance(path[i])
  end

  return length
end

---Generates the segment data structure for the given raw segment data.
---@param segmentData RawVentSegment
---@return VentSegment
local function GenerateSegment(segmentData)
  ---@type VentSegment
  local segment = {
    bias = segmentData.bias,
    length = 0,
    lengthRev = 0,
    lock = 1,
    lockTime = 0,
    start = segmentData.start,
    finish = segmentData.finish,
    startPos = Vector(0, 0, 0),
    finishPos = Vector(0, 0, 0),
    volumes = segmentData.volumes,
    path = PointArray(),
    pathRev = PointArray(),
    plane = nil,
    debugEntryCount = 0,
    debugGenCount = 0,
  }

  local path = segmentData.path
  for i = 1, #path do
    Pathing.InsertPoint(segment.path, i, path[i])
  end

  path = segmentData.pathRev
  if path then
    segment.pathRev = PointArray()
    for i = 1, #path do
      Pathing.InsertPoint(segment.pathRev, i, path[i])
    end
  else
    segment.pathRev = segment.path
  end

  if segmentData.plane then
    segment.plane = CreatePlane(table.unpack(segmentData.plane))
  end

  segment.length = GetSegmentLength(segment.path)
  segment.lengthRev = GetSegmentLength(segment.pathRev)
  segment.startPos = segment.path[1]
  segment.finishPos = segment.path[#segment.path]
  segment.debugGenCount = 0
  segment.debugEntryCount = 0

  return segment
end

---Generates the vent data structure for this vent given its raw data.
---@param ventData RawVentSegment[]
---@return Vent
local function GenerateVent(ventData)
  ---@type Vent
  local vent = {
    length = 0,
    volume = {
      min = Vector(math.huge, math.huge, math.huge),
      max = Vector(-math.huge, -math.huge, -math.huge)
    },
    segments = {},
    debugEntryCount = 0,
    debugGenCount = 0
  }

  local totalLength = 0
  for i, segmentData in ipairs(ventData) do
    vent.segments[i] = GenerateSegment(segmentData)
    ExpandVolume(vent.volume, vent.segments[i].volumes)
    totalLength = totalLength + GetSegmentLength(vent.segments[i])
  end
  vent.length = totalLength / #vent.segments
  vent.debugGenCount = 0
  vent.debugEntryCount = 0

  return vent
end

---Generate all vent data for the currently loading map.
local function GenerateVentData()
  Bishop.debug.SystemLog("Generating vent data.")
  local mapName = Shared.GetMapName()
  if table.contains(kVentMaps, mapName) then
    local file = "lua/bishop/data/VentPaths_" .. mapName .. ".lua"
    Script.Load(file)
  end

  for i, ventData in ipairs(Bishop.global.vents.rawData) do
    Bishop.global.vents.data[i] = GenerateVent(ventData)
  end

  -- Throw away the raw data since it wont be used past this point.
  ---@diagnostic disable-next-line: assign-type-mismatch
  Bishop.global.vents.rawData = nil

  Bishop.debug.SystemLog("Generated vent data for %s vents.",
    #Bishop.global.vents.data)
end

Shine.Hook.Add("MapPostLoad", "BishopVentGen", GenerateVentData)

Bishop.debug.FileExit(debug.getinfo(1, "S"))
