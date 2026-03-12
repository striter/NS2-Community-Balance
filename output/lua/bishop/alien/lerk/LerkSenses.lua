Script.Load("lua/Balance.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/bots/BotUtils.lua")

Script.Load("lua/bishop/alien/AlienSharedSenses.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetTeamBrain = GetTeamBrain
local Shared_GetEntity = Shared.GetEntity

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kAlienTeamType = kAlienTeamType
local kMarineTeamType = kMarineTeamType
local kSporesMaxRange = kSporesMaxRange

--------------------------------------------------------------------------------
-- Lerk Spore target.
--------------------------------------------------------------------------------
-- The vanilla "nearestSporesTarget" sense considered Exos as a valid target.

local function NearestSporesTarget(senses, lerk)
  local closestDistance = kSporesMaxRange
  local enemy = nil
  local origin = lerk:GetOrigin()
  local teamBrain = GetTeamBrain(kAlienTeamType)

  for _, mem in teamBrain:IterMemoriesNearLocation(lerk:GetLocationName(),
      kMarineTeamType) do
    local entity = Shared_GetEntity(mem.entId)

    if entity:isa("Player") and not entity:isa("Exo")
        and entity:GetIsAlive() then
      local distance = origin:GetDistance(entity:GetOrigin())
      if distance < closestDistance then
        closestDistance = distance
        enemy = entity
      end
    end
  end

  return enemy
end

--------------------------------------------------------------------------------
-- Apply shared functions to the sense DB.
--------------------------------------------------------------------------------

local OldCreateLerkBrainSenses = CreateLerkBrainSenses

function CreateLerkBrainSenses()
  local senses = OldCreateLerkBrainSenses()

  Bishop.alien.PopulateSharedSenses(senses)
  senses:Add("nearestSporesTarget", NearestSporesTarget)

  return senses
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
