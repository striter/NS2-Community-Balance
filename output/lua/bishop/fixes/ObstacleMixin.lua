Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

--------------------------------------------------------------------------------
-- Whitelist some buildings from navmesh exclusion.
--------------------------------------------------------------------------------
-- Tunnels and IPs can be run over by all bots, and certain tunnel placements in
-- corridors can effectively split the navmesh in two, completely preventing
-- movement through that area.

local ObstacleMixin_AddToMesh = _G.ObstacleMixin.AddToMesh

function ObstacleMixin:AddToMesh()
  if self:isa("TunnelEntrance") or self:isa("InfantryPortal") then
    return
  end

  ObstacleMixin_AddToMesh(self)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
