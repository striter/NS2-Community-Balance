Script.Load("lua/TechTreeConstants.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.alien.retreat = {}

local kTechId = kTechId
local max = math.max

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

-- Don't allow the retreat health to scale below this value.
local kRetreatMinHealth = {
  [kTechId.Skulk] = 0.02,
  [kTechId.Gorge] = 0.30,
  [kTechId.Lerk] = 0.55,
  [kTechId.Fade] = 0.46,
  [kTechId.Onos] = 0.45
}
-- The absolute retreat health, regardless of enemy presence.
local kRetreatHealth = {
  [kTechId.Skulk] = 0.1,
  [kTechId.Gorge] = 0.80,
  [kTechId.Lerk] = 0.67,
  [kTechId.Fade] = 0.62,
  [kTechId.Onos] = 0.55
}
-- The kRetreatHealth increases by this much for every extra marine, or down
-- for every outnumbered marine.
local kRetreatHealthScale = {
  [kTechId.Skulk] = 0.04,
  [kTechId.Gorge] = 0.08,
  [kTechId.Lerk] = 0.11,
  [kTechId.Fade] = 0.10,
  [kTechId.Onos] = 0.07
}

--------------------------------------------------------------------------------
-- Scale retreat health based on lifeform and surroundings.
--------------------------------------------------------------------------------

-- Returns the health fraction to begin a retreat based on the number of enemies
-- outnumbering the alien. Access this via the "per_danger" sense rather than
-- directly to avoid recomputation.
function Bishop.alien.retreat.GetRetreatHealth(lifeform, outnumber)
  return max(kRetreatMinHealth[lifeform],
    kRetreatHealth[lifeform] + (kRetreatHealthScale[lifeform] * outnumber))
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
