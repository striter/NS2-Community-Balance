Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

--------------------------------------------------------------------------------
-- Change the engagement point for Hydras.
--------------------------------------------------------------------------------
-- The original engagement point is the origin - depending on the Hydra's
-- positioning, the origin can sometimes be inside a wall which prevents bots
-- from shooting at it.

function Hydra:GetEngagementPointOverride()
  return self:GetOrigin() + self:GetCoords().yAxis * 0.2
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
