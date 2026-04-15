-- NOTE: This file is loaded by BishopUtility.lua.
-- USAGE:
--   bishop_recordpath: Call once to activate (must be a Skulk) then call again
--     to dump the generated path to the log.
--   bishop_startvolume: Begin recording a new volume.
--   bishop_endvolume: End and dump volume to console.

if not Bishop.debug.devTools and Client then
  return
end

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local Error = Bishop.Error
local Log = Bishop.Log

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

local function IsLiveClient()
  if not Client or not Client.GetLocalPlayer() then
    if Client and not Client.GetLocalPlayer() then
      Bishop.Error("No local player.")
    end
    return false
  end
  return true
end

--------------------------------------------------------------------------------
-- Path recording.
--------------------------------------------------------------------------------
-- Command to start and end a path segment. The generated path will be dumped
-- to the console upon completion.

local recordActive = false
local recordPath = nil
local recordPointIndex = 1
local recordPointNextDraw = 0

local function RecordPathDraw()
  if Shared.GetTime() < recordPointNextDraw then
    return
  end

  local index = recordPointIndex
  while index > 1 do
    DebugLine(recordPath[index], recordPath[index - 1], 0.25, 1, 1, 1, 1)
    index = index - 1
  end
  recordPointNextDraw = Shared.GetTime() + 0.20
end

local function RecordPathUpdate()
  local player = Client.GetLocalPlayer()
  if not player or not player:GetIsAlive() then
    Error("Path invalidated - player entity has changed.")
    recordActive = false
    Shine.Hook.Remove("Think", "BishopRecordPath")
  end
  RecordPathDraw()
end

local function RecordPathBegin()
  if not IsLiveClient() then
    return
  end

  recordPath = PointArray()
  recordPointIndex = 0
  recordActive = true
  Shine.Hook.Add("Think", "BishopRecordPath", RecordPathUpdate)

  Log("Recording path.")
end

local function RecordPathEnd()
  local pointCount = #recordPath
  local i = 1

  Print("RECORDED PATH:")
  Print("{")
  while i <= pointCount do
    Print("  Vector(%s,%s,%s),",
      recordPath[i].x, recordPath[i].y, recordPath[i].z)
    i = i + 1
  end
  Print("}")

  recordActive = false
  Shine.Hook.Remove("Think", "BishopRecordPath")
  Log("Recording complete.")
end

local function RecordPath()
  if not IsLiveClient() then
    return
  end
  if recordActive then
    RecordPathEnd()
  else
    RecordPathBegin()
  end
end

local function RecordPathPoint()
  if not IsLiveClient() or not recordActive then
    return
  end
  local player = Client.GetLocalPlayer()
  if not player then
    return
  end
  recordPointIndex = recordPointIndex + 1
  Pathing.InsertPoint(recordPath, recordPointIndex, player:GetEyePos())
  Log("Recorded point %s.", recordPointIndex)
end

local function RecordPathRay()
  if not IsLiveClient() or not recordActive then
    return
  end
  local player = Client.GetLocalPlayer()
  if not player then
    return
  end
  local start = player:GetEyePos()
  local finish = start + player:GetViewCoords().zAxis * 10

  local trace = Shared.TraceRay(start, finish, CollisionRep.Damage,
    PhysicsMask.Bullets, EntityFilterAll())
  if not trace or trace.endPoint == 1 then
    return
  end
  recordPointIndex = recordPointIndex + 1
  Pathing.InsertPoint(recordPath, recordPointIndex, trace.endPoint)
  Log("Recorded point %s.", recordPointIndex)
end

Event.Hook("Console_bishop_recordpath", RecordPath)
Event.Hook("Console_bishop_recordpoint", RecordPathPoint)
Event.Hook("Console_bishop_recordray", RecordPathRay)

--------------------------------------------------------------------------------
-- Volume capture.
--------------------------------------------------------------------------------
-- Commands to start and finish new volumes, then dump those volumes to the log.

local volumeActive = false
local volumeBeginPoint = nil

local function TraceVolumePoint(player)
  local start = player:GetEyePos()
  local finish = start + player:GetViewCoords().zAxis * 10

  local trace = Shared.TraceRay(start, finish, CollisionRep.Damage,
    PhysicsMask.Bullets, EntityFilterAll())

  if not trace or trace.endPoint == 1 then
    return nil
  end
  return trace.endPoint
end

local function RecordVolumeUpdate()
  if not Client then
    return
  end
  local player = Client.GetLocalPlayer()
  if not player or not player:GetIsAlive() then
    Error("Volume invalidated - player entity has changed.")
    volumeActive = false
    Shine.Hook.Remove("Think", "BishopRecordVolume")
  end

  local zeroExtents = Vector(0, 0, 0)
  local tracePoint = TraceVolumePoint(player)
  if tracePoint then
    local start = Vector(
      math.min(volumeBeginPoint.x, tracePoint.x),
      math.min(volumeBeginPoint.y, tracePoint.y),
      math.min(volumeBeginPoint.z, tracePoint.z))
    local finish = Vector(
      math.max(volumeBeginPoint.x, tracePoint.x),
      math.max(volumeBeginPoint.y, tracePoint.y),
      math.max(volumeBeginPoint.z, tracePoint.z))
    DebugBox(start, finish, zeroExtents, 0.20, 1, 1, 1, 1)
  end
end

local function StartVolume()
  if not IsLiveClient() then
    return
  end
  local player = Client.GetLocalPlayer()

  if volumeActive then
    Log("Resetting active volume.")
  end

  local tracePoint = TraceVolumePoint(player)
  if not tracePoint then
    return
  end

  volumeBeginPoint = tracePoint
  if not volumeActive then
    volumeActive = true
    Shine.Hook.Add("Think", "BishopRecordVolume", RecordVolumeUpdate)
  end
end

local function EndVolume()
  if not IsLiveClient() then
    return
  end
  local player = Client.GetLocalPlayer()
  if not volumeActive then
    Bishop.Error("No volume to end.")
    return
  end

  local tracePoint = TraceVolumePoint(player)
  if not tracePoint then
    Error("Not close enough to wall.")
    return
  end

  Print("{")
  Print("  min = Vector(%s,%s,%s),",
    math.min(volumeBeginPoint.x, tracePoint.x),
    math.min(volumeBeginPoint.y, tracePoint.y),
    math.min(volumeBeginPoint.z, tracePoint.z))
  Print("  max = Vector(%s,%s,%s)",
    math.max(volumeBeginPoint.x, tracePoint.x),
    math.max(volumeBeginPoint.y, tracePoint.y),
    math.max(volumeBeginPoint.z, tracePoint.z))
  Print("},")

  volumeActive = false
  Shine.Hook.Remove("Think", "BishopRecordVolume")
end

Event.Hook("Console_bishop_startvolume", StartVolume)
Event.Hook("Console_bishop_endvolume", EndVolume)

--------------------------------------------------------------------------------
-- Vent stat output.
--------------------------------------------------------------------------------

local function VentStats()
  if not Bishop.debug.vents then
    Log("Vent debugging is not enabled.")
    return
  end
  if not Server then
    Log("Vent data output to server log.")
    return
  end
  Log("Vent stats (entries / generated)")
  for i, vent in ipairs(Bishop.global.vents.data) do
    Log("Vent #%s: (%s / %s)", i, vent.debugEntryCount, vent.debugGenCount)
    for j, segment in ipairs(vent.segments) do
      if table.contains(segment.start, 0)
          or table.contains(segment.finish, 0) then
        Log("  Segment #%s: (%s / %s)", j, segment.debugEntryCount,
          segment.debugGenCount)
      end
    end
  end
end

Event.Hook("Console_bishop_ventstats", VentStats)

--------------------------------------------------------------------------------
-- Vent weight modifier.
--------------------------------------------------------------------------------

local function VentWeight(client, vent, segment, weight)
  if not Bishop.debug.vents then
    Log("Vent debugging is not enabled.")
    return
  end
  if not Server then
    return
  end
  vent = tonumber(vent)
  segment = tonumber(segment)
  weight = tonumber(weight)
  if type(vent) ~= "number" or vent % 1 ~= 0
      or type(segment) ~= "number" or segment % 1 ~= 0
      or type(weight) ~= "number"
      or #Bishop.global.vents.data < vent
      or #Bishop.global.vents.data[vent].segments < segment then
    Log("Invalid arguments.")
    return
  end

  Bishop.global.vents.data[vent].segments[segment].bias = weight
  Log("Vent %s segment %s set to weight %s.", vent, segment, weight)
end

Event.Hook("Console_bishop_ventweight", VentWeight)

Bishop.debug.FileExit(debug.getinfo(1, "S"))
