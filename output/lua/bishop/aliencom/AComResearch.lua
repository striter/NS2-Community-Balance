Script.Load("lua/TechTreeConstants.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local kTechId = kTechId

local function SetTechPathVariable(name, value)
  local result = Shine.SetUpValue(GetTechPathProgressForAlien, name, value,
    true)
  assert(result)
end

--------------------------------------------------------------------------------
-- Replace research override types.
--------------------------------------------------------------------------------

kAlienTechPathOverrideType = enum({
  "None",
  "OneHiveLimit",
  "TwoHiveLimit"
})

--------------------------------------------------------------------------------
-- Swap in tech paths based on the hive situation.
--------------------------------------------------------------------------------
-- Hold back research if a tech point is available and it should be taken before
-- researching anything else.

local techOverrideOneHiveLimit = {
  type = kAlienTechPathOverrideType.OneHiveLimit,
  techPath = { -- Research a level of Biomass before dropping the second Hive.
    {
      kTechId.Rupture
    }
  },
  condition = function(sdb, com)
    if #sdb:Get("hives") == 1 and sdb:Get("techPointToTakeInfest") then
      return true
    end

    return false
  end
}

local techOverrideTwoHiveLimit = {
  type = kAlienTechPathOverrideType.TwoHiveLimit,
  techPath = { -- Bare minimum techs before dropping the third Hive.
    {
      kTechId.Leap,
      kTechId.MetabolizeEnergy
    }
  },
  condition = function(sdb, com)
    if #sdb:Get("hives") == 2 and sdb:Get("techPointToTakeInfest") then
      return true
    end

    return false
  end
}

--------------------------------------------------------------------------------
-- Swap the default overrides with the above custom ones.
--------------------------------------------------------------------------------
-- The overrides' condition functions are called every single commander tick by
-- the kAlienComBrainActions entry responsible for considering research. When a
-- condition returns true, no further conditions are considered, so this is a
-- priority list from top to bottom.

local kAlienTechPathOverrides = {
  techOverrideOneHiveLimit,
  techOverrideTwoHiveLimit
}

SetTechPathVariable("kAlienTechPathOverrides", kAlienTechPathOverrides)

Bishop.debug.FileExit(debug.getinfo(1, "S"))
