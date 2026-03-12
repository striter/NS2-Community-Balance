Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/Utility.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/alien/Lifeform.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetActionWeight = Bishop.alienCom.GetActionWeight
local GetCostForTech = GetCostForTech
local GetRequiredLifeform = Bishop.alien.lifeform.GetRequiredLifeform
local IsValid = IsValid

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local cooldown = 0         -- File local used for tick counting.
local kMinResources = 60   -- Minimum resources (not including lifeform.)
local kRunEveryNthTick = 8 -- This action does not need to run every tick.
local lastLifeform = nil   -- Prevent duplicate lifeforms for variety.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kActionTypes = Bishop.alienCom.actionTypes
local kAlienTeamType = kAlienTeamType
local kLifeformToTech = {
  [kTechId.Gorge] = kTechId.GorgeEgg,
  [kTechId.Lerk]  = kTechId.LerkEgg,
  [kTechId.Fade]  = kTechId.FadeEgg,
  [kTechId.Onos]  = kTechId.OnosEgg
}
local kNilAction = Bishop.lib.constants.kNilAction
local kTechId = kTechId

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

local function SkipAction()
  cooldown = cooldown + 1
  if cooldown >= kRunEveryNthTick then
    cooldown = 0
    return false
  end
  return true
end

--------------------------------------------------------------------------------
-- Upgrade alien eggs.
--------------------------------------------------------------------------------
-- Often the alien commander builds up excess resources (particularly in two
-- hive stalemates) that could otherwise be used to help win the game. Use these
-- resources to evolve Skulks to required classes.

local function PerformUpgradeEgg(move, bot, brain, com, action)
  local egg = action.egg
  if not IsValid(egg) or not egg:GetIsAlive() then
    return
  end

  local origin = egg:GetOrigin()
  local success = brain:ExecuteTechId(com, kLifeformToTech[action.lifeform],
    egg:GetOrigin(), egg)
  if success then
    bot:SendTeamMessage(kTechId[action.lifeform]
      .. " egg has been hatched for the glory of the hive!", 20)
    lastLifeform = action.lifeform
  end
end

function Bishop.alienCom.actions.UpgradeEgg(bot, brain, com)
  if SkipAction() or com:GetTeamResources() < kMinResources then
    return kNilAction
  end

  local lifeform = GetRequiredLifeform(nil, true)
  local senses = brain:GetSenses()
  if not lifeform
      or lifeform == kTechId.Skulk
      or (lifeform == lastLifeform and lifeform ~= kTechId.Onos)
      or com:GetTeamResources() < kMinResources
        + GetCostForTech(kLifeformToTech[lifeform])
      or not senses:Get("doableTechIds")[kLifeformToTech[lifeform]] then
    return kNilAction
  end

  return {
    name = "UpgradeEgg",
    perform = PerformUpgradeEgg,
    weight = GetActionWeight(kActionTypes.UpgradeEgg),

    -- Action metadata.
    egg = senses:Get("doableTechIds")[kLifeformToTech[lifeform]][1],
    lifeform = lifeform
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
