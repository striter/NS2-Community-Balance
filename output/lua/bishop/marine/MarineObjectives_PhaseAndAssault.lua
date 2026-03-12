Script.Load("lua/Entity.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/Table.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local ipairs = ipairs
local Shared_GetTime = Shared.GetTime
local table_random = table.random

local GetMarineMoveFunction = Bishop.utility.GetMarineMoveFunction
local SearchMemoriesForAny = Bishop.utility.SearchMemoriesForAny

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kCompletionRadiusSqr = 5 * 5 -- Radius from command chair to complete.
local kMaxPhaseDistance = 40       -- Maximum distance from Phase Gate.
local kScanTargets = {             -- Targets to scan for around Phase Gates.
  kMinimapBlipType.Hive,
  kMinimapBlipType.Harvester,
  kMinimapBlipType.Whip,
  kMinimapBlipType.Shell,
  kMinimapBlipType.Spur,
  kMinimapBlipType.Veil,
  kMinimapBlipType.Crag,
  kMinimapBlipType.Shade,
  kMinimapBlipType.Shift,
  kMinimapBlipType.Hydra
}
local kTimeout = 10                -- Expiry to reconsider objectives.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kNilAction = Bishop.lib.constants.kNilAction

--------------------------------------------------------------------------------
-- Attack structures within range of Phase Gates.
--------------------------------------------------------------------------------
-- Encouraging marines to attack known memories located near Phase Gates will
-- both help them assault enemy Hives and defend tech points with known tunnels
-- nearby.

local function PerformPhaseAndAssault(move, bot, brain, marine, action)
  local distanceSqr = marine:GetOrigin():GetDistanceSquared(action.position)
  if distanceSqr <= kCompletionRadiusSqr
      or Shared_GetTime() >= action.expires then
    return true
  end
  
  GetMarineMoveFunction(marine)
    (marine:GetOrigin(), action.position, bot, brain, move)
end

local function ValidatePhaseAndAssault(bot, brain, marine, action)
  return true
end

function Bishop.marine.objectives.PhaseAndAssault(bot, brain, marine)
  local memories = SearchMemoriesForAny(kAlienTeamType, kScanTargets)
  local phaseGates = brain:GetSenses():Get("ent_phaseGates")
  if #memories == 0 or #phaseGates == 0 then
    return kNilAction
  end

  do
    local n = #memories
    local i = 1
    while i <= n do
      local keep = false
      local memoryPosition = memories[i].lastSeenPos
      for _, phaseGate in ipairs(phaseGates) do
        if memoryPosition:GetDistanceTo(phaseGate:GetOrigin())
            <= kMaxPhaseDistance then
          keep = true
          break
        end
      end
      if not keep then
        memories[i], memories[n] = memories[n], nil
        n = n - 1
      else
        i = i + 1
      end
    end
  end

  if #memories == 0 then
    return kNilAction
  end
  local memory = table_random(memories)

  return {
    name = "PhaseAndAssault",
    perform = PerformPhaseAndAssault,
    validate = ValidatePhaseAndAssault,
    weight = 1, -- Weight per class.

    -- Objective metadata.
    expires = Shared_GetTime() + kTimeout,
    position = memory.lastSeenPos
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
