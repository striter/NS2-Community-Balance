Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local cos = math.cos
local sin = math.sin

--------------------------------------------------------------------------------
-- Implement GetEngagementPoint for Harvesters.
--------------------------------------------------------------------------------
-- To prevent bots from shooting at the origin.

function Harvester:GetEngagementPointOverride()
  local yaw = self:GetAngles().yaw
  local radius = self:GetIsBuilt() and -0.4 or -1.7
  local height = self:GetIsBuilt() and 1.8 or 1.5
  return self:GetOrigin() + Vector(sin(yaw) * radius, height, cos(yaw) * radius)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
