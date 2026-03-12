Bishop.debug.FileEntry(debug.getinfo(1, "S"))

---Contains common geo and trig functions used by the mod.
Bishop.lib.math = {}

local DotProduct = Math.DotProduct ---@type function

local kFacingAwayCosine = -0.2
local kHuge = math.huge

---@class Plane
---@field a number
---@field b number
---@field c number
---@field d number

---@class Vector
---@field GetDistance function
---@field GetDistanceSquared function
---@field Normalize function
---@field x number
---@field y number
---@field z number

---@class Volume
---@field min Vector
---@field max Vector

---Creates the plane for ax+by+cz+d=0 using the three points given.
---@param origin Vector
---@param pointA Vector
---@param pointB Vector
---@return Plane
function Bishop.lib.math.CreatePlane(origin, pointA, pointB)
  ---@type Vector
  local normal = (pointA - origin):CrossProduct(pointB - origin)
  normal:Normalize()

  return {
    a = normal.x,
    b = normal.y,
    c = normal.z,
    d = -DotProduct(origin, normal)
  }
end

---Given a master volume and a list of minor volumes expandVolumes, expand
---volume to enclose all of them.
---@param volume Volume
---@param expandVolumes Volume[]
function Bishop.lib.math.ExpandVolume(volume, expandVolumes)
  for _, expand in ipairs(expandVolumes) do
    if expand.min.x < volume.min.x then volume.min.x = expand.min.x end
    if expand.max.x > volume.max.x then volume.max.x = expand.max.x end
    if expand.min.y < volume.min.y then volume.min.y = expand.min.y end
    if expand.max.y > volume.max.y then volume.max.y = expand.max.y end
    if expand.min.z < volume.min.z then volume.min.z = expand.min.z end
    if expand.max.z > volume.max.z then volume.max.z = expand.max.z end
  end
end

---Returns the array index of the closest point in pointArray to point. Assumes
---pointArray contains at least one point.
---@param pointArray Vector[]
---@param point Vector
---@return integer
function Bishop.lib.math.GetClosestPointIndex(pointArray, point)
  local closestIndex = 1
  local closestDistanceSqr = kHuge

  for i = 1, #pointArray do
    local distanceSqr = point:GetDistanceSquared(pointArray[i])
    if distanceSqr < closestDistanceSqr then
      closestIndex = i
      closestDistanceSqr = distanceSqr
    end
  end

  return closestIndex
end

---Returns the orthogonal signed distance of point from plane.
---@param plane Plane
---@param point Vector
---@return number
function Bishop.lib.math.GetSignedDistanceFromPlane(plane, point)
  return point.x * plane.a + point.y * plane.b + point.z * plane.c + plane.d
end

---Returns true if entity is facing away from target.
---@param entity Player
---@param target Entity
---@return boolean
function Bishop.lib.math.IsFacingAway(entity, target)
  return DotProduct((target:GetOrigin() - entity:GetOrigin()):GetUnit(),
    entity:GetViewCoords().zAxis) < kFacingAwayCosine
end

---Returns true when point touches or lies within volume.
---@param point Vector
---@param volume Volume
---@return boolean
function Bishop.lib.math.IsPointWithinVolume(point, volume)
  -- Test X and Z first since they are the most likely to fail.
  return point.x >= volume.min.x
    and point.x <= volume.max.x
    and point.z >= volume.min.z
    and point.z <= volume.max.z
    and point.y >= volume.min.y
    and point.y <= volume.max.y
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
