Script.Load("lua/Entity.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")
Script.Load("lua/Table.lua")
Script.Load("lua/bots/BotUtils.lua")
Script.Load("lua/bots/LocationGraph.lua")

Script.Load("lua/bishop/global/SharedBotSenses.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetEnemyTeamNumber = GetEnemyTeamNumber
local GetEntitiesForTeam = GetEntitiesForTeam
local GetLocationGraph = GetLocationGraph
local GetMinTableEntry = GetMinTableEntry
local ientitylist = ientitylist
local Shared = Shared
local table = table

local kMinimapBlipType = kMinimapBlipType

--------------------------------------------------------------------------------
-- Tech point and resource point map knowledge.
--------------------------------------------------------------------------------

local function UnclaimedNatural(resourceNode, teamBrain)
  local naturals = GetLocationGraph():GetNaturalRtsForTechpoint(
    teamBrain.initialTechPointLoc) or {}
  if table.contains(naturals, resourceNode) and (not resourceNode:GetAttached()
      or resourceNode:GetAttached():isa("Harvester")) then
    return true
  end
  return false
end

---@param mem TeamBrain.Memory
---@return boolean
local function HiveMemoryFilter(mem)
  return mem.btype == kMinimapBlipType.Hive
end

-- TODO: Move the decision logic out of here, just retrieve the set of all nodes
-- minus the set of owned nodes.
local function IdealResourceNode(senses, marine)
  local marineNodes = 0
  local totalNodes = 0
  local availableNodes = {}
  local enemyNodes = {}

  for _, resourceNode in ientitylist(Shared.GetEntitiesWithClassname(
      "ResourcePoint")) do
    totalNodes = totalNodes + 1
    if UnclaimedNatural(resourceNode, senses.bot.brain.teamBrain) then
      return resourceNode
    end
    if not resourceNode:GetAttached() then
      table.insert(availableNodes, resourceNode)
    elseif resourceNode:GetAttached():isa("Harvester") then
      table.insert(enemyNodes, resourceNode)
    else
      marineNodes = marineNodes + 1
    end
  end

  -- If resource map control is over 65%, return nil to focus on other tasks.
  if totalNodes == 0 or marineNodes / totalNodes > 0.65 then
    return nil
  end

  -- Prefer available nodes over enemy ones.
  -- A penalty is added for nodes near enemy Hives to push marines towards wider
  -- map control.
  local origin = marine:GetOrigin()
  local closestNode
  if #availableNodes > 0 then
    local _, node = GetMinTableEntry(availableNodes,
      function(node)
        return origin:GetDistanceSquared(node:GetOrigin())
      end)
    closestNode = node
  elseif #enemyNodes > 0 then
    local _, node = GetMinTableEntry(enemyNodes,
      function(node)
        local penalty = 0
        local teamBrain = GetTeamBrain(marine:GetTeamNumber())
        local nearbyHives = teamBrain:FilterNearbyMemories(
          node:GetLocationName(), GetEnemyTeamNumber(marine:GetTeamNumber()),
          HiveMemoryFilter)

        if #nearbyHives > 0 then penalty = 10000 end

        return origin:GetDistanceSquared(node:GetOrigin()) + penalty
      end)
    closestNode = node
  end

  return closestNode
end

---@param senses BrainSenses
---@param marine Entity
local function Ent_PhaseGates(senses, marine)
  return GetEntitiesForTeam("PhaseGate", marine:GetTeamNumber())
end

---@param senses BrainSenses
function Bishop.marine.PopulateSharedSenses(senses)
  Bishop.global.PopulateSharedBotSenses(senses)

  senses:Add("ent_phaseGates", Ent_PhaseGates)
  senses:Add("idealResourceNode", IdealResourceNode)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
