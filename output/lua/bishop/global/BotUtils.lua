-- NOTE: This file is being loaded manually by BishopUtility.lua.

Script.Load("lua/CollisionRep.lua")
Script.Load("lua/NS2Utility.lua")
Script.Load("lua/Utility.lua")
Script.Load("lua/bots/LocationGraph.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local EntityFilterTwo = EntityFilterTwo
local GetLocationForPoint = GetLocationForPoint
local GetLocationGraph = GetLocationGraph
local Shared_TraceCapsule = Shared.TraceCapsule

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local CollisionRep_Damage = CollisionRep.Damage
local kNameFixes = { -- Contains naming errors and their corrected values.
  ["Nanogrid"] = "NanoGrid"
}
local PhysicsMask_Bullets = PhysicsMask.Bullets

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

local function GetLocationNameAndPosition(entityOrPosition, locationHint)
  local locationName
  local position

  if entityOrPosition:isa("Vector") then
    local location = GetLocationForPoint(entityOrPosition)
    locationName = location and location:GetName() or nil
    position = entityOrPosition
  elseif entityOrPosition:isa("ScriptActor") then
    locationName = entityOrPosition:GetLocationName()
    position = entityOrPosition:GetOrigin()
  elseif entityOrPosition:isa("Entity") then
    locationName = locationHint
    position = entityOrPosition:GetOrigin()
  end

  return locationName, position
end

--------------------------------------------------------------------------------
-- Minor rewrite of GetBotWalkDistance.
--------------------------------------------------------------------------------
-- This was necessary due to the naming mismatch on ns2_veil between the
-- location volumes "NanoGrid" and the minimap name "Nanogrid". It's still
-- better than editing the entire map.

function GetBotWalkDistance(botOrPos, targetOrPos, locationHint)
  local locationName, position = GetLocationNameAndPosition(botOrPos)
  local targetLocationName, targetPosition = GetLocationNameAndPosition(
    targetOrPos, locationHint)

  if not targetLocationName then
    local location = GetLocationForPoint(targetPosition)
    targetLocationName = location and location:GetName() or nil
  end

  -- Apply naming fixes here.
  locationName = kNameFixes[locationName] or locationName
  targetLocationName = kNameFixes[targetLocationName] or targetLocationName

  if not locationName or locationName == "" or not targetLocationName
      or targetLocationName == "" or locationName == targetLocationName then
    return position:GetDistance(targetPosition)
  end

  -- A final check for a nil gatewayDistTable to ensure it doesn't break the
  -- bots in the future.
  local gatewayDistTable = GetLocationGraph():GetGatewayDistance(locationName,
    targetLocationName)
  if not gatewayDistTable then
    Bishop.Error("ATTENTION: Please post this error on the workshop page:")
    Bishop.Error("  gatewayDistTable was nil for location pair.")
    Bishop.Error("  Locations were %s and %s", locationName, targetLocationName)
    return position:GetDistance(targetPosition)
  end
  local gatewayDistance = gatewayDistTable.distance
  local enterGatePos = gatewayDistTable.enterGatePos
  local exitGatePos = gatewayDistTable.exitGatePos

  -- Distance = position --> enterGatePos --> exitGatePos --> targetPosition
  local enterDist = (enterGatePos - position):GetLength()
  local exitDist = (targetPosition - exitGatePos):GetLength()
  return enterDist + gatewayDistance + exitDist
end

--------------------------------------------------------------------------------
-- Fix bots seeing and shooting through walls.
--------------------------------------------------------------------------------

function GetBotCanSeeTarget(attacker, target)
  local p0 = attacker:GetEyePos()
  local p1 = target:GetEngagementPoint()
  local trace = Shared_TraceCapsule(p0, p1, 0.15, 0, CollisionRep_Damage,
    PhysicsMask_Bullets, EntityFilterTwo(attacker, attacker:GetActiveWeapon()))

  return trace.fraction == 1
    or trace.entity == target
    or (trace.entity and trace.entity.GetTeamNumber and target.GetTeamNumber
      and trace.entity:GetTeamNumber() == target:GetTeamNumber())
    or (trace.endPoint - p1):GetLengthSquared() <= 0.02
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
