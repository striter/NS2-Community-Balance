Script.Load("lua/bots/LocationContention.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetLocationContention = GetLocationContention

--------------------------------------------------------------------------------
-- Remove ejected Exosuits from the LocationContention structure.
--------------------------------------------------------------------------------
-- Not doing this permanently corrupted the structure, preventing the alien
-- commander building in that location for the rest of the match. Unfortunately
-- the same is true for death as well.

local Exo_PerformEject = _G.Exo.PerformEject

local function RemoveExoFromLocation(exo)
  local locationGroup = GetLocationContention():GetLocationGroup(
    exo:GetLocationName())
  if locationGroup then
    locationGroup:UpdateForEntity(exo, false)
  end
end

function Exo:PerformEject()
  RemoveExoFromLocation(self)
  Exo_PerformEject(self)
end

local Exo_OnKill = _G.Exo.OnKill

function Exo:OnKill(attacker, doer, point, direction)
  RemoveExoFromLocation(self)
  Exo_OnKill(self, attacker, doer, point, direction)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
