-- FUTURE: Prioritize medpacks for marines that are in combat.

Script.Load("lua/Balance.lua")
Script.Load("lua/BalanceHealth.lua")
Script.Load("lua/TechTreeConstants.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local ipairs = ipairs
local kTechId = kTechId
local GetEntity = Shared.GetEntity ---@type function
local GetTime = Shared.GetTime ---@type function
local TInsert = table.insert
local TRemove = table.remove

local actions = Bishop.marineCom.actions
local kActionTypes = Bishop.marineCom.kActionTypes
local GetActionWeight = Bishop.marineCom.GetActionWeight
local kNilAction = Bishop.lib.constants.kNilAction

local kRequestExpiryTime = 20 -- Time support requests are relevant.

local kInvalidEntity = Entity.invalidId ---@type integer

---@class SupportRequest
---@field entId integer
---@field expiryTime number
---@field requestTime number
---@field wasServiced boolean

---Removes expired requests from supportRequests.
---@param supportRequests SupportRequest[]
local function RemoveExpiredRequests(supportRequests)
  local time = GetTime()
  for i = #supportRequests, 1, -1 do
    local entity = GetEntity(supportRequests[i].entId)
    if time > supportRequests[i].expiryTime
        or not entity or not entity:GetIsAlive() then
      TRemove(supportRequests, i)
    end
  end
end

---Adds a new medpack request or refreshes the current one if it already exists.
---@param entId integer
---@param medpackRequests SupportRequest[]
---@param wasServiced boolean
local function AddMedpackRequest(entId, medpackRequests, wasServiced)
  local time = GetTime()

  for i = 1, #medpackRequests do
    if medpackRequests[i].entId == entId then
      medpackRequests[i].expiryTime = time + kRequestExpiryTime
      medpackRequests[i].wasServiced = wasServiced
      return
    end
  end

  TInsert(medpackRequests, {
    entId = entId,
    expiryTime = time + kRequestExpiryTime,
    requestTime = time,
    wasServiced = wasServiced
  })
end

---Pulls medpack requests from the alertQueue and adds them to supportRequests.
---@param brain MarineCommanderBrain
---@param alertQueue Alert[]
local function ProcessNewRequests(brain, alertQueue)
  for i = #alertQueue, 1, -1 do
    if alertQueue[i].techId == kTechId.MarineAlertNeedMedpack then
      AddMedpackRequest(alertQueue[i].entityId, brain.medpackRequests, false)
      TRemove(alertQueue, i)
    end
  end
end

--------------------------------------------------------------------------------
-- Linearly scale drops with resource income.
--------------------------------------------------------------------------------
-- The commander often slows progression by dropping a ton of medpacks in the
-- first couple of minutes. This change scales drops with income, and removes
-- the default behaviour of halting drops during tech overrides.

local kMaxAlertAge = 8
local kMinAlertAge = 0.5

local kPackRateZeroExtractors = 999
local kPackResourceThreshold = 40

local kMedPackRateAboveThreshold = 0.80 -- ~7.5 secs/pack/extractor.
local kMedPackRateBelowThreshold = 0.65 -- ~9.2 secs/pack/extractor.

-- To prevent marines getting more than 1mp/s when standing inside Lerk gas.
local kMaxHealthFraction = 1 - (kSporesDustDamagePerSecond / kMarineHealth)

local kAmmoPackRateAboveThreshold = 0.45 -- 13.3 secs/pack/extractor.
local kAmmoPackRateBelowThreshold = 0.25 -- 24 secs/pack/extractor.

local function GetMedPackRate(resources, extractorCount)
  local resourceRate = kResourceTowerResourceInterval * kTeamResourcePerTick
  local packRate = resources < kPackResourceThreshold
    and kMedPackRateBelowThreshold or kMedPackRateAboveThreshold

  if extractorCount == 0 then
    return kPackRateZeroExtractors
  end

  return resourceRate / packRate / extractorCount
end

local function GetNextMedPackTime(brain, resources, extractorCount)
  return brain.lastMedPackTime + GetMedPackRate(resources, extractorCount)
end

---@param move Move
---@param bot Bot
---@param brain MarineCommanderBrain
---@param com Player
---@param action ActionEntPos
---@diagnostic disable-next-line: unused-local
local function PerformMedpackDrop(move, bot, brain, com, action)
  brain:ExecuteTechId(com, kTechId.MedPack, action.position, com, action.entId)
  brain.lastMedPackTime = GetTime()

  -- This forces the commander to pay attention to recently medpacked marines.
  AddMedpackRequest(action.entId, brain.medpackRequests, true)
end

---Queues a medpack drop from requested medpacks prioritized by health.
---@param _ Bot
---@param brain MarineCommanderBrain
---@param com Player
---@return Action
function Bishop.marineCom.actions.SupportMedPack(_, brain, com)
  RemoveExpiredRequests(brain.medpackRequests)
  ProcessNewRequests(brain, com:GetAlertQueue())

  local senses = brain:GetSenses()
  local nextPackTime = GetNextMedPackTime(brain, com:GetTeamResources(),
    #senses:Get("extractors"))
  local time = GetTime()

  if not senses:Get("doableTechIds")[kTechId.MedPack]
      or time < nextPackTime then
    return kNilAction
  end

  local entId = kInvalidEntity
  local lowestHealth = 1
  local position

  for _, request in ipairs(brain.medpackRequests) do
    local entity = GetEntity(request.entId) ---@type ScriptActor

    if entity and entity:GetIsAlive()
        and time >= request.requestTime + kMinAlertAge then
      local health = entity:GetHealthFraction()
      local serviceHealth = 1 or request.wasServiced and kMaxHealthFraction

      if health < lowestHealth and health < serviceHealth then
        entId = request.entId
        position = entity:GetOrigin()
        lowestHealth = health
      end
    end
  end

  if entId == kInvalidEntity or not position then return kNilAction end

  return {
    name = "SupportMedPack",
    weight = GetActionWeight(kActionTypes.SupportMedPack),
    perform = PerformMedpackDrop,

    entId = entId,
    position = position
  }
end

local function GetAmmoPackRate(resources, extractorCount)
  local resourceRate = kResourceTowerResourceInterval * kTeamResourcePerTick
  local packRate = resources < kPackResourceThreshold and
    kAmmoPackRateBelowThreshold or kAmmoPackRateAboveThreshold

  if extractorCount == 0 then
    return kPackRateZeroExtractors
  end

  return packRate / resourceRate / extractorCount
end

local function GetNextAmmoPackTime(brain, resources, extractorCount)
  return brain.lastAmmoPackTime + GetAmmoPackRate(resources, extractorCount)
end

local function GetEntityAmmoPercentage(target)
  local ammo = 0
  local maxAmmo = 0

  for i = 1,2 do
    local weapon = target:GetWeaponInHUDSlot(i)

    if weapon and weapon:isa("ClipWeapon") then
      ammo = ammo + weapon:GetAmmo()
      maxAmmo = maxAmmo + weapon:GetMaxAmmo()
    end
  end

  if maxAmmo == 0 then
    return 1
  end

  return ammo / maxAmmo
end

function actions.SupportAmmoPack(bot, brain, com)
  local resources = com:GetTeamResources()
  local senses = brain:GetSenses()
  local extractorCount = #senses:Get("extractors")
  local nextPackTime = GetNextAmmoPackTime(brain, resources, extractorCount)
  local currentTime = GetTime()

  if not senses:Get("doableTechIds")[kTechId.AmmoPack]
      or currentTime < nextPackTime then
    return kNilAction
  end

  local alertQueue = com:GetAlertQueue()
  local entityId
  local entity
  local position
  local alertIndex
  local lowestAmmo = 1

  for i, alert in ipairs(alertQueue) do
    local age = currentTime - alert.time
    if alert.techId == kTechId.MarineAlertNeedAmmo
        and age < kMaxAlertAge
        and age >= kMinAlertAge then
      local target = GetEntity(alert.entityId)

      if target and target:GetIsAlive() then
        local ammo = GetEntityAmmoPercentage(target)

        if ammo < lowestAmmo then
          entityId = alert.entityId
          entity = target
          position = entity:GetOrigin()
          alertIndex = i
          lowestAmmo = ammo
        end
      end
    end
  end

  if not entityId then
    return kNilAction
  end

  table.remove(alertQueue, alertIndex)
  com:SetAlertQueue(alertQueue)

  return {
    name = "SupportAmmoPack",
    weight = GetActionWeight(kActionTypes.SupportAmmoPack),
    perform = function(move, bot, brain, com, action)
      brain:ExecuteTechId(com, kTechId.AmmoPack, position, com, entityId)
      brain.lastAmmoPackTime = currentTime
    end
  }
end

--------------------------------------------------------------------------------
-- Actively drop medpacks with lots of resources.
--------------------------------------------------------------------------------
-- Extra resources should be used to keep the team alive. Scan for marines that
-- need health without looking at the alert queue.

function actions.SupportPreemptiveMedPack(bot, brain, com)
  local resources = com:GetTeamResources()
  local senses = brain:GetSenses()

  if not senses:Get("doableTechIds")[kTechId.MedPack]
      or resources <= kPackResourceThreshold then
    return kNilAction
  end

  local marines = senses:Get("marines")
  local entityId
  local position
  local lowestHealth = kMaxHealthFraction

  for _, marine in ipairs(marines) do
    local health = marine:GetHealthFraction()

    if health < lowestHealth and marine:GetIsAlive() then
      entityId = marine:GetId()
      position = marine:GetOrigin()
      lowestHealth = health
    end
  end

  if not entityId then
    return kNilAction
  end

  return {
    name = "SupportPreemptiveMedPack",
    weight = GetActionWeight(kActionTypes.SupportPreemptiveMedPack),
    perform = function(move, bot, brain, com, action)
      brain:ExecuteTechId(com, kTechId.MedPack, position, com, entityId)
    end
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
