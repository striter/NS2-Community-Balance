Bishop.debug.FileEntry(debug.getinfo(1, "S"))

---Contains functions that query Entity objects.
Bishop.lib.entity = {}

local GetEntity = Shared.GetEntity ---@type function
local HasMixin = HasMixin
local ipairs = ipairs

local kHuge = math.huge

---@class Entity
---@field GetCoords function
---@field GetDistance function
---@field GetDistanceSquared function
---@field GetId function
---@field GetOrigin function
---@field GetTeamNumber function
---@field isa function

---@class ScriptActor : Entity
---@field GetCloakFraction function Requires Cloakable
---@field GetEngagementPoint function Requires TargetMixin
---@field GetHealthFraction function Requires LiveMixin
---@field GetHealthScalar function Requires LiveMixin
---@field GetIsAlive function Requires LiveMixin
---@field GetIsDoingDamage function Requires CombatMixin
---@field GetIsGhostStructure function Requires GhostStructureMixin
---@field GetIsInCombat function Requires CombatMixin
---@field GetIsParasited function Requires ParasiteAbleMixin
---@field GetIsUnderFire function Requires CombatMixin
---@field GetLastTakenDamageOrigin function Requires CombatMixin
---@field GetLastTarget function Requies CombatMixin
---@field GetLocationName function
---@field GetMaxExtents function Requires Extents
---@field GetTimeLastDamageTaken function Requires CombatMixin

---@class Player : ScriptActor
---@field botBrain PlayerBrain?
---@field GetAlertQueue function
---@field GetEyePos function
---@field GetName function
---@field GetResources function
---@field GetTeamResources function
---@field GetVelocity function
---@field GetViewCoords function
---@field GetWeapon function
---@field GetWeaponInHUDSlot function
---@field isHallucination boolean
---@field ProcessBuyAction function
---@field SetActiveWeapon function Requires WeaponOwnerMixin

---@class PowerPoint : ScriptActor
---@field HasConsumerRequiringPower function

---@class EntityDistanceSqr
---@field entity Entity?
---@field distanceSqr number?

---Returns the closest Entity with squared distance to entity. Can potentially
---return nil entries if entities is nil or invalid.
---@param entity Entity
---@param entities table
---@return EntityDistanceSqr
function Bishop.lib.entity.GetClosestEntityTo(entity, entities)
  local minDistanceSqr = kHuge
  local closestEntity

  for _, ent in ipairs(entities) do
    local distanceSqr = entity:GetDistanceSquared(ent)
    if distanceSqr < minDistanceSqr then
      minDistanceSqr = distanceSqr
      closestEntity = ent
    end
  end

  return {
    entity = closestEntity,
    distanceSqr = closestEntity and minDistanceSqr or nil
  }
end

---If entId refers to a valid living Entity, return the Entity.
---@param entId integer
---@return ScriptActor? entity
function Bishop.lib.entity.GetEntityIfAlive(entId)
  local ent = GetEntity(entId)
  if not ent or not HasMixin(ent, "Live") or not ent:GetIsAlive() then
    return nil
  end

  return ent
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
