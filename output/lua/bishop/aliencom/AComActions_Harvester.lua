Script.Load("lua/NS2Utility.lua")
Script.Load("lua/TechTreeConstants.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local invalidId = Entity.invalidId
local ipairs = ipairs
local kTechId = kTechId
local Shared_GetTime = Shared.GetTime

local actions = Bishop.alienCom.actions
local actionTypes = Bishop.alienCom.actionTypes
local GetActionWeight = Bishop.alienCom.GetActionWeight
local GetIsPointOnInfestation = GetIsPointOnInfestation
local kNilAction = Bishop.lib.constants.kNilAction

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kTimeBetweenHarvesterAttempts = 60 -- TODO: Unused, but should be.

--------------------------------------------------------------------------------
-- Building Harvesters.
--------------------------------------------------------------------------------
-- The order for dropping Harvesters has been delegated to the Cyst actions.
-- Aggressively drop a Harvester anywhere an available resource node is
-- connected to infestation.

function actions.BuildHarvester(bot, brain, com)
  local techId = kTechId.Harvester
  local senses = brain:GetSenses()
  local nodes = senses:Get("cystedAvailResPoints")
  local time = Shared_GetTime()

  if #nodes == 0 or not senses:Get("doableTechIds")[techId] then
    return kNilAction
  end

  local selectedNode = nil
  local selectedId = invalidId

  for _, node in ipairs(nodes) do
    local id = node:GetId()
    local nextBuildTime = brain.lastHarvesterBuildTime[id] or 0

    if time >= nextBuildTime
        and brain:GetIsSafeToDropInLocation(node:GetLocationName(),
          kAlienTeamType)
        and GetIsPointOnInfestation(node:GetOrigin()) then
      selectedNode = node
      selectedId = id
      break
    end
  end

  if not selectedNode then
    return kNilAction
  end

  return {
    name = "BuildHarvester",
    weight = GetActionWeight(actionTypes.BuildHarvester),
    perform = function(move, bot, brain, com, action)
      local success = brain:ExecuteTechId(com, techId, selectedNode:GetOrigin(),
        com)
      
      if success then
        brain.lastHarvesterBuildTime[selectedId] = time
      end
    end
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
