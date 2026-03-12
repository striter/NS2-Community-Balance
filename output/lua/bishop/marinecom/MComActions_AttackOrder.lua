Script.Load("lua/Globals.lua")
Script.Load("lua/Table.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/Utility.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local ipairs = ipairs
local IsValid = IsValid
local Shared_GetEntity = Shared.GetEntity
local table_random = table.random
local table_remove = table.remove

local GetActionWeight = Bishop.marineCom.GetActionWeight

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kMarineDistanceSqr = 400 -- Only give an order if a marine is in position.
local kMaxHostiles       = 3   -- Ignore tech points with too many enemies.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kActionTypes = Bishop.marineCom.kActionTypes
local kAlienTeamType = kAlienTeamType
local kNilAction = Bishop.lib.constants.kNilAction
local kTechId_Attack = kTechId.Attack

--------------------------------------------------------------------------------
-- Give marines in empty unclaimed tech points attack orders.
--------------------------------------------------------------------------------
-- Sometimes a Hydra or Cyst remaining in a tech point blocks commander
-- construction. Nearby marines without orders should be directed to destroy
-- these structures.

local function PerformAttackOrder(move, bot, brain, com, action)
  local marine = action.marine
  local target = Shared_GetEntity(action.targetId)
  if IsValid(marine) and marine:GetIsAlive() and IsValid(target)
      and target:GetIsAlive() then
    marine:GiveOrder(kTechId_Attack, action.targetId, target:GetOrigin(), 0,
      true, true, com)
  end
end

function Bishop.marineCom.actions.AttackOrder(bot, brain, com)
  local senses = brain:GetSenses()
  local marines = senses:Get("marines")
  local techPoints = senses:Get("availTechPoints")

  -- Pre-filter marines that already have orders to save time.
  for i = #marines, 1, -1 do
    local marine = marines[i]
    if not IsValid(marine) or not marine:GetIsAlive()
        or marine:GetHasOrder() then
      table_remove(marines, i)
    end
  end
  if #marines <= 0 then
    return kNilAction
  end

  for _, techPoint in ipairs(techPoints) do
    local techPointOrigin = techPoint:GetOrigin()
    local enemyMemories = brain.teamBrain:GetMemoriesAtLocation(
      techPoint:GetLocationName(), kAlienTeamType)
    if #enemyMemories > 0 and #enemyMemories <= kMaxHostiles then
      for _, marine in ipairs(marines) do
        if marine:GetDistanceSquared(techPointOrigin) <= kMarineDistanceSqr then
          return {
            name = "AttackOrder",
            weight = GetActionWeight(kActionTypes.AttackOrder),
            perform = PerformAttackOrder,
        
            -- Action metadata.
            marine = marine,
            targetId = table_random(enemyMemories).entId
          }
        end
      end
    end
  end

  return kNilAction
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
