Script.Load("lua/Alien_Upgrade.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/bots/AlienCommanderBrain_TechPathData.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetHasPrereqs = GetHasPrereqs
local GetTechPathProgressForAlien = GetTechPathProgressForAlien
local kBiomassResearchTechIds = kBiomassResearchTechIds
local kHasRechResult = kHasTechResult
local kTechId = kTechId

local actions = Bishop.alienCom.actions
local actionTypes = Bishop.alienCom.actionTypes
local GetActionWeight = Bishop.alienCom.GetActionWeight
local kNilAction = Bishop.lib.constants.kNilAction

--------------------------------------------------------------------------------
-- Streamline flow of research.
--------------------------------------------------------------------------------
-- The default research behaviour imposed an artificial resource limit and
-- prevented any research before upgrade chambers were dropped. This is now
-- handled using the priorities system. The default code also got bogged down in
-- a tech tier if it was waiting for the next hive, even if no tech points were
-- available.

local kMinResourcesForResearchDuringHiveDrop = 60

function actions.StartResearch(bot, brain, com)
  local senses = brain:GetSenses()
  local hive = senses:Get("researchEvolutionChamber")

  if not hive or
      (senses:Get("isEarlyGame") and com:GetTeamResources() < 80) then
    return kNilAction
  end

  local techTier, techId, techResult = GetTechPathProgressForAlien(brain, com)

  if techId == kTechId.None or techId == kTechId.Hive
      or techResult ~= kHasRechResult.NotStarted then
    return kNilAction
  end

  if not GetHasPrereqs(com:GetTeamNumber(), techId) then
    local biomassTable = senses:Get("cheapestBiomassUnit")

    if not biomassTable.isValid then
      return kNilAction
    end

    hive = biomassTable.hiveEnt
    techId = biomassTable.techId
  end

  if com:GetTeamResources() < kMinResourcesForResearchDuringHiveDrop
      and senses:Get("numUnbuiltHives") > 0
      and kBiomassResearchTechIds[techId] then
    return kNilAction
  end

  -- Fix to prevent the commander attempting to research Contamination.
  -- TODO: These techs should never be passed back to begin with.
  if not senses:Get("doableTechIds")[techId] or techId == kTechId.BoneWall
      or techId == kTechId.Contamination or techId == kTechId.Rupture then
    return kNilAction
  end

  local position = hive:GetOrigin()

  return {
    name = "StartResearch",
    weight = GetActionWeight(actionTypes.StartResearch),
    perform = function(move, bot, brain, com, action)
      brain:ExecuteTechId(com, techId, position, hive)
    end
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
