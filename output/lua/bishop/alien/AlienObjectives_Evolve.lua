Script.Load("lua/TechData.lua")
Script.Load("lua/TechTreeConstants.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/alien/Lifeform.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetCostForTech = GetCostForTech
local LookupTechData = LookupTechData
local Shared_GetTime = Shared.GetTime
local table_contains = table.contains
local table_insert = table.insert

local GetCurrentLifeform = Bishop.alien.lifeform.GetCurrentLifeform
local GetRequiredLifeform = Bishop.alien.lifeform.GetRequiredLifeform
local Log = Bishop.debug.LifeformLog

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kCooldown          = 1  -- One evolve attempt every kCooldown seconds.
local kGorgeEvolve       = 70 -- Shift from Gorge to Onos with enough resources.
local kLifeformCooldown  = 10 -- Throttle lifeform evolution checks.
local kMaxHiveDistanceSqr   = 15 * 15 -- Do not evolve away from a Hive.
local kMinThreatDistanceSqr = 28 * 28 -- Do not evolve if a threat is close.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kDebug = Bishop.debug.lifeform
local kDebugClass = Bishop.lib.constants.kClassNameToTechId
  [Bishop.debug.alienClass]
local kNilAction = Bishop.lib.constants.kNilAction
local kTechId = kTechId

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

-- To counter bots attempting to evolve in invalid positions. The code to check
-- positioning is deeply intertwined in Alien_Server.lua so a cooldown is used
-- instead.
local function CanAttemptEvolve(bot)
  local time = Shared_GetTime()
  if time < bot.nextEvolveTime then
    return false
  end

  bot.nextEvolveTime = time + kCooldown
  return true
end

--------------------------------------------------------------------------------
-- Central override for lifeform evolution and upgrade selection.
--------------------------------------------------------------------------------

local function PerformEvolve(move, bot, brain, alien, action)
  alien:ProcessBuyAction(action.evolution)

  if action.isLifeformSwitch then
    bot.desiredLifeform = nil
  end

  return true
end

function Bishop.alien.objectives.Evolve(bot, brain, alien)
  if alien.isHallucination then
    return kNilAction
  end

  local senses = brain:GetSenses()
  local hiveDistanceSqr = senses:Get("ent_hive_nearestBuilt").distanceSqr
  local threatDistanceSqr = senses:Get("mem_threat_nearest").distanceSqr
  local resources = alien:GetPersonalResources()

  if not alien:GetIsAllowedToBuy()
      or (threatDistanceSqr and threatDistanceSqr <= kMinThreatDistanceSqr)
      or (not hiveDistanceSqr or hiveDistanceSqr > kMaxHiveDistanceSqr)
      or alien:GetIsInCombat() then
    if kDebug and bot.desiredLifeform
        and threatDistanceSqr and threatDistanceSqr <= kMinThreatDistanceSqr
        and hiveDistanceSqr and hiveDistanceSqr <= kMaxHiveDistanceSqr
        and alien:isa("Skulk") then
      local nearestThreat = senses:Get("mem_threat_nearest")
      Log("%s cannot evolve because %s is at distance^2 %s.", alien:GetName(),
        kMinimapBlipType[nearestThreat.memory.btype], threatDistanceSqr)
    end
    return kNilAction
  end

  if not bot.desiredLifeform
      and alien:isa("Skulk") then
    if not brain.lastLifeformCheck
        or brain.lastLifeformCheck + kLifeformCooldown < Shared_GetTime() then
      bot.desiredLifeform = GetRequiredLifeform(resources)
      if kDebug and bot.desiredLifeform then
        Log("%s selected %s.", alien:GetName(), kTechId[bot.desiredLifeform])
      end
    end
  elseif not bot.desiredLifeform and alien:isa("Gorge")
      and resources > kGorgeEvolve then
    bot.desiredLifeform = kTechId.Onos
    if kDebug then Log("Gorge swapping to Onos due to excessive resources.") end
  end

  local evolution = {}
  local lifeform = GetCurrentLifeform(alien)
  local lifeformTarget = bot.desiredLifeform
  local isEvolving = false
  local techTree = alien:GetTechTree()

  if kDebugClass then
    if lifeform ~= kDebugClass then
      lifeformTarget = kDebugClass
    end
    if resources < GetCostForTech(lifeformTarget) then
      alien:AddResources(GetCostForTech(lifeformTarget))
    end
  end

  if lifeformTarget then
    local techNode = techTree:GetTechNode(lifeformTarget)
    local cost = GetCostForTech(lifeformTarget)

    if cost <= resources
        and techNode:GetAvailable() then
      resources = resources - cost
      table_insert(evolution, lifeformTarget)
      lifeform = lifeformTarget
      isEvolving = true
    end
  end

  local currentUpgrades = isEvolving and {} or alien:GetUpgrades()

  for _, upgrade in ipairs(bot.desiredUpgrades[lifeform]) do
    local techNode = techTree:GetTechNode(upgrade)
    local cost = LookupTechData(lifeform, kTechDataUpgradeCost, 0)

    if cost <= resources
        and techNode:GetAvailable()
        and not table_contains(currentUpgrades, upgrade) then
      resources = resources - cost
      table_insert(evolution, upgrade)
    end
  end

  local stupidOnos = table_contains(evolution, kTechId.Onos) and #evolution < 2
    and kDebugClass ~= kTechId.Onos

  if #evolution == 0 or stupidOnos or not CanAttemptEvolve(bot) then
    return kNilAction
  end

  return {
    name = "Evolve",
    perform = PerformEvolve,
    validate = nil, -- One shot objective.
    weight = 1, -- Override per lifeform.

    -- Objective metadata.
    evolution = evolution,
    isLifeformSwitch = isEvolving
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
