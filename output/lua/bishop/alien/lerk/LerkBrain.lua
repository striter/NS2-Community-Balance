Bishop.debug.FileEntry(debug.getinfo(1, "S"))

--------------------------------------------------------------------------------
-- Initialize Bishop-specific Lerk brain variables.
--------------------------------------------------------------------------------

local OldLerkBrainInit = _G.LerkBrain.Initialize

---@diagnostic disable-next-line: duplicate-set-field
function LerkBrain:Initialize()
  OldLerkBrainInit(self)

  self.forceFlap = false -- LerkActions_Attack.lua flap movement override.

  self.lerkStuckCounter = 0                -- LerkMovement.lua stuck detection.
  self.lerkStuckPosition = Vector(0, 0, 0) -- LerkMovement.lua last position.
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
