Script.Load("lua/TechData.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/Utility.lua")
Script.Load("lua/bots/BotUtils.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/marine/soldier/Weapons.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetDistanceToTouch = GetDistanceToTouch
local IsValid = IsValid
local LookupTechData = LookupTechData
local random = math.random

local DoMove = Bishop.marine.DoMove
local GetObjectiveWeight = Bishop.marine.GetObjectiveWeight
local GetRequiredWeapon = Bishop.marine.soldier.weapons.GetRequiredWeapon
local Log = Bishop.debug.WeaponsLog

local kAbundantRes = 60 -- Expendable resources regardless of desired weapon.
local kRailgunProbability = 0.15 -- Probability to pick Railgun over Minigun.

local kBuildingSenses = {
  [kTechId.Shotgun] = "ent_armory_nearestBuilt",
  [kTechId.HeavyMachineGun] = "ent_advArmory_nearestBuilt",
  [kTechId.GrenadeLauncher] = "ent_advArmory_nearestBuilt",
  [kTechId.Flamethrower] = "ent_advArmory_nearestBuilt",
  [kTechId.DualMinigunExosuit] = "ent_protoLab_nearestBuilt",
}
local kDebug = Bishop.debug.weapons
local kNilAction = Bishop.lib.constants.kNilAction
local kObjectiveTypes = Bishop.marine.kObjectiveTypes
local kTechDataCostKey = kTechDataCostKey
local kTechId = kTechId
local kTechUnlocks = {
  [kTechId.Shotgun] = kTechId.ShotgunTech,
  [kTechId.Flamethrower] = kTechId.AdvancedWeaponry,
  [kTechId.GrenadeLauncher] = kTechId.AdvancedWeaponry,
  [kTechId.HeavyMachineGun] = kTechId.AdvancedWeaponry,
  [kTechId.DualMinigunExosuit] = kTechId.ExosuitTech,
  [kTechId.DualRailgunExosuit] = kTechId.ExosuitTech,
}
local kUseDistance = 1.35
local kUsePositions = {
  Vector(kUseDistance, 0, 0),
  Vector(0, 0, -kUseDistance),
  Vector(0, 0, kUseDistance),
  Vector(-kUseDistance, 0, 0)
}

---Sends a marine to purchase a weapon.
---@param move Move
---@param bot Bot
---@param brain MarineBrain
---@param marine Player
---@param action ActionBuy
---@return boolean?
local function PerformBuyWeapon(move, bot, brain, marine, action)
  local building = action.building
  local touchDistance = GetDistanceToTouch(marine, building) + 0.1

  if not action.usePosition then
    local useIndex = random(1, #kUsePositions)
    action.usePosition = building:GetOrigin()
      + building:GetCoords():TransformVector(kUsePositions[useIndex])

    if kDebug then
      Log("%s moving to buy %s", marine:GetName(), kTechId[action.techId])
    end
  end

  ---GetUseMaxRange() is specific to Armory and PrototypeLab.
  ---@diagnostic disable-next-line: undefined-field
  if touchDistance >= building:GetUseMaxRange() - 0.1 then
    DoMove(marine:GetOrigin(), action.usePosition, bot, brain, move, true)
  else
    local motion = bot:GetMotion()
    motion:SetDesiredMoveTarget()
    motion:SetDesiredViewTarget(building:GetEngagementPoint())
    marine:ProcessBuyAction({action.techId})
    bot.desiredWeapon = kTechId.None
    return true
  end
end

---Abandons buy action if the building was destroyed.
---@param bot Bot
---@param brain MarineBrain
---@param marine Player
---@param action ActionBuy
---@return boolean?
local function ValidateBuyWeapon(bot, brain, marine, action)
  if not IsValid(action.building) or not action.building:GetIsAlive() then
    return false
  end
end

---Handles decision-making for weapon purchases.
---@param bot Bot
---@param brain MarineBrain
---@param marine Player
---@return Action
function Bishop.marine.soldier.objectives.BuyWeapon(bot, brain, marine)
  do
    local currentWeapon = marine:GetWeaponInHUDSlot(1)
    if currentWeapon and currentWeapon:GetTechId() ~= kTechId.Rifle then
      return kNilAction
    end
  end

  if bot.desiredWeapon == kTechId.None then
    bot.desiredWeapon = GetRequiredWeapon()
    if kDebug then
      Log("%s wants to buy %s.", marine:GetName(), kTechId[bot.desiredWeapon])
    end
  end

  local purchase = bot.desiredWeapon
  local building = brain:GetSenses():Get(kBuildingSenses[purchase]).entity
  local resources = marine:GetResources()

  -- Rather than hoarding resources for a tech that isn't unlocked, fall back to
  -- a shotgun for the team.
  if not building and purchase ~= kTechId.Shotgun
      and resources >= kAbundantRes - bot.buyTemptation then
    purchase = kTechId.Shotgun
    building = brain:GetSenses():Get(kBuildingSenses[purchase]).entity
  end

  if purchase == kTechId.DualMinigunExosuit
      and random() <= kRailgunProbability then
    purchase = kTechId.DualRailgunExosuit
  end

  local techTree = GetTechTree(marine:GetTeamNumber())

  -- If jetpacks are unlocked then the marine should also take into account a
  -- mandatory jetpack purchase with their weapon.
  local jetpackOffset = 0
  if purchase ~= kTechId.DualMinigunExosuit
      and purchase ~= kTechId.DualRailgunExosuit
      and techTree and techTree:GetHasTech(kTechId.JetpackTech, true)
      and not marine:isa("JetpackMarine")
      and not Bishop.settings.marine.jetpackLmg then
    jetpackOffset = LookupTechData(kTechId.Jetpack, kTechDataCostKey)
  end

  if not building or not techTree
      or not techTree:GetHasTech(kTechUnlocks[purchase], true)
      or resources < LookupTechData(purchase, kTechDataCostKey)
        + jetpackOffset then
    return kNilAction
  end

  return {
    name = "BuyWeapon",
    weight = GetObjectiveWeight(kObjectiveTypes.BuyWeapon),
    perform = PerformBuyWeapon,
    validate = ValidateBuyWeapon,

    building = building,
    techId = purchase
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
