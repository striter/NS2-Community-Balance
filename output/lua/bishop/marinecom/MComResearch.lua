Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local IsTechStarted = Bishop.utility.IsTechStarted

local function GetTechPathVariable(name)
  local value = Shine.GetUpValue(GetMarineComNextTechStep, name)
  assert(value)

  return value
end

--------------------------------------------------------------------------------
-- Replace research override types.
--------------------------------------------------------------------------------
-- These are used for the chat messages sent by the commander when an override
-- is active. By default, when techOverrideType ~= None, no medpacks or ammo
-- will be dropped. Unused or reused enum entries are harmless here, but None
-- must be present; It is hardcoded in several places of the vanilla code.

kMarineTechPathOverrideType = enum({
  "None",
  "PhaseGates",
  "Shotguns",
  "Weapons"
})

-- React to marines waiting for Phase Gates at available tech points to increase
-- map control.
local techOverridePhaseGates = {
  type = kMarineTechPathOverrideType.PhaseGates,
  techPath = {
    {
      kTechId.Armory,
      kTechId.Observatory,
      kTechId.PhaseTech,
      kTechId.PhaseGate
    }
  },
  condition = function(sdb, com)
    if sdb:Get("mainPhaseGate") ~= nil
        or not IsTechStarted(com, kTechId.PhaseTech) then
      return false
    end

    -- The phase gate check covers the possibility that another gate was built
    -- before main base.
    return #sdb:Get("safeTechPoints") > 0 or #sdb:Get("phaseGates") > 0
  end
}

-- If the commander can't afford A2 after Phase Tech, grab W1 instead to keep
-- things moving.
local techOverrideWeapons = {
  type = kMarineTechPathOverrideType.Weapons,
  techPath = {
    {
      kTechId.ArmsLab,
      kTechId.Weapons1
    }
  },
  condition = function(sdb, com)
    if IsTechStarted(com, kTechId.Weapons1)
        or not IsTechStarted(com, kTechId.Armor1) then
      return false
    end

    return not sdb:Get("doableTechIds")[kTechId.Armor2]
  end
}

local kExtractorCountLosing = 3
-- If marines are locked to their base and natural res nodes, move shotguns up
-- before W2 to try and change the odds.
local techOverrideShotguns = {
  type = kMarineTechPathOverrideType.Shotguns,
  techPath = {
    {
      kTechId.Armory,
      kTechId.ShotgunTech
    }
  },
  condition = function(sdb, com)
    if IsTechStarted(com, kTechId.ShotgunTech)
        or not IsTechStarted(com, kTechId.PhaseTech) then
      return false
    end

    return #sdb:Get("extractors") <= kExtractorCountLosing
  end
}

--------------------------------------------------------------------------------
-- Swap the default overrides with the above custom ones.
--------------------------------------------------------------------------------
-- The overrides' condition functions are called every single commander tick by
-- the kMarineComBrainActions entry responsible for considering research. When a
-- condition returns true, no further conditions are considered, so this is a
-- priority list from top to bottom.

local kMarineTechPathOverrides = {
  techOverridePhaseGates,
  techOverrideWeapons,
  techOverrideShotguns
}

SetTechPathVariable("kMarineTechPathOverrides", kMarineTechPathOverrides)

--------------------------------------------------------------------------------
-- Allow immediate tech phase progression.
--------------------------------------------------------------------------------
-- The default behaviour prevents the commander from moving on to the next tech
-- tier in the array until the current one has been completely researched. This
-- hook allows the commander to start the next phase and assume research will
-- succeed. This also includes placed buildings that are awaiting construction.

local Hook_TechComplete = GetTechPathVariable("GetHasTechForMarineTechPath")

local function AssumeTechComplete(brain, com, techId)
  local result, techType = Hook_TechComplete(brain, com, techId)

  if result == kHasTechResult.InProgressOrUnbuilt then
    result = kHasTechResult.HasTech
  end

  return result, techType
end

SetTechPathVariable("GetHasTechForMarineTechPath", AssumeTechComplete)

Bishop.debug.FileExit(debug.getinfo(1, "S"))
