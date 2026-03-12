Bishop.debug.FileEntry(debug.getinfo(1, "S"))

---@class StuckPosition
---@field volume Volume
---@field destination Vector?
---@field flag integer

---@type StuckPosition[][]
kStuckData = {}
kStuckFlag = enum({
  "None",          -- Run normally.
  "Crouch",        -- Requires traversal under an obstacle.
  "Jump",          -- The bot should jump to its destination.
  "NoSkulk",       -- Skulks are exempt from this position.
  "NoSkulkJump",   -- Skulks exempt, all others must jump.
  "OnosCrouch",    -- Onos must crouch to navigate through here.
  "AndOnosCrouch", -- Stuck, plus Onos much crouch.
})
kStuckMaps = {
  "ns2_caged",
  "ns2_refinery",
  "ns2_summit",
  "ns2_tanith",
  "ns2_tram",
  "ns2_unearthed",
  "ns2_veil"
}
kStuckVolume = {}

-- NOTES:
-- Stuck data is made up of single volumes and the escape path. Extra flags
-- allow for special behaviour such as jumping.
-- kStuckData = {
--   { -- Cluter of nearby positions (for optimization purposes.)
--     { -- A problematic position.
--       volume = { min =, max = },     Detection volume.
--       destination = Vector(),        Escape direction.
--       flag = 0                       Special flag for this position.
--     }, ...
--   }, ...
-- }

Bishop.debug.FileExit(debug.getinfo(1, "S"))
