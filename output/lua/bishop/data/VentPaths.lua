Bishop.debug.FileEntry(debug.getinfo(1, "S"))

---@class RawVentSegment
---@field bias number Path weight multiplier to encourage or discourage use.
---@field start integer[] Segment start connections, or 0 for entrance.
---@field finish integer[] Segment end connections, or 0 for entrance.
---@field plane Vector[]? Clip all volumes using an optional plane of 3 points.
---@field volumes Volume[] Volumes that fully enclose this segment.
---@field path Vector[] Start to finish path.
---@field pathRev Vector[]? Start to finish path for reverse movement.

---@type RawVentSegment[][]
Bishop.global.vents.rawData = {}
kVentMaps = {
  "ns2_ayumi",
  "ns2_biodome",
  "ns2_caged",
  "ns2_derelict",
  "ns2_descent",
  "ns2_docking",
  "ns2_eclipse",
  "ns2_kodiak",
  "ns2_metro",
  "ns2_mineshaft",
  "ns2_origin",
  "ns2_refinery",
  "ns2_summit",
  "ns2_tanith",
  "ns2_tram",
  "ns2_unearthed",
  "ns2_veil",
  -- Custom maps.
  "ns2_metal"
}

Bishop.debug.FileExit(debug.getinfo(1, "S"))
