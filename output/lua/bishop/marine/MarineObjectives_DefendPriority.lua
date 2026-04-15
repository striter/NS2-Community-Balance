Script.Load("lua/Table.lua")
Script.Load("lua/bots/BotUtils.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetBotWalkDistance = GetBotWalkDistance
local GetEntity = Shared.GetEntity ---@type function
local ipairs = ipairs
local TAddTable = table.addtable

local GetMarineMoveFunction = Bishop.utility.GetMarineMoveFunction
local GetObjectiveWeight = Bishop.marine.GetObjectiveWeight

local kCompletionRadiusSqr = 4*4 -- Radius from structure to complete objective.
local kMaxMarines = 3 -- Number of marines that move to assist per entity.
local kMaxResponseDistance = 50 -- Travel distance a marine willing cover.

local kObjectiveTypes = Bishop.marine.kObjectiveTypes
local kNilAction = Bishop.lib.constants.kNilAction

---@param move Move
---@param bot Bot
---@param brain PlayerBrain
---@param marine Player
---@param action ActionEntPos
---@return boolean?
local function PerformDefendPriority(move, bot, brain, marine, action)
  local structure = GetEntity(action.entId)
  brain.teamBrain:AssignPlayerToEntity(marine, action.entId)

  if marine:GetOrigin():GetDistanceSquared(action.position)
      < kCompletionRadiusSqr
      or (IsValid(structure) and structure.GetIsUnderFire and
        not structure:GetIsUnderFire()) then
    brain.teamBrain:UnassignPlayer(marine)
    return true
  end

  GetMarineMoveFunction(marine)
    (marine:GetOrigin(), action.position, bot, brain, move)
end

local function ValidateDefendPriority(bot, brain, marine, action)
  return true
end

---@param bot Bot
---@param brain PlayerBrain
---@param marine Player
---@return Action | ActionEntPos
function Bishop.marine.objectives.DefendPriority(bot, brain, marine)
  -- Phase gates are higher priority than Extractors.
  ---@type ScriptActor[]
  local structures = GetEntitiesAliveForTeam("PhaseGate",
    marine:GetTeamNumber())
  TAddTable(GetEntitiesAliveForTeam("Extractor", marine:GetTeamNumber()),
    structures)
  local teamBrain = brain.teamBrain

  for _, structure in ipairs(structures) do
    local distance = GetBotWalkDistance(marine, structure)

    if distance < kMaxResponseDistance and structure:GetIsUnderFire()
        and teamBrain:GetNumAssignedToEntity(structure:GetId())
          < kMaxMarines then
      return {
        name = "DefendPriority",
        perform = PerformDefendPriority,
        validate = ValidateDefendPriority,
        -- NOTE: This needs to be reweighted if ever added to Exo.
        weight = GetObjectiveWeight(kObjectiveTypes.DefendPriority),

        -- Objective metadata.
        entId = structure:GetId(),
        position = structure:GetOrigin()
      }
    end
  end

  return kNilAction
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
