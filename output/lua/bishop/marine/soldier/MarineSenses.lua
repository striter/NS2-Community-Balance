Script.Load("lua/Entity.lua")
Script.Load("lua/bots/CommonMarineActions.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/marine/MarineSharedSenses.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local FilterEntitiesArray = FilterEntitiesArray
local GetPhaseDistanceForMarine = GetPhaseDistanceForMarine
local GetTime = Shared.GetTime ---@type function
local HasMixin = HasMixin

local GetClosestEntityTo = Bishop.lib.entity.GetClosestEntityTo
local GetEntityIfAlive = Bishop.lib.entity.GetEntityIfAlive

local kMarineChaseTime = 1.3
local kUrgencies = { ---@type [integer, number, number][]
  [kMinimapBlipType.Onos] =             {4, 0.11, 7.00},
  [kMinimapBlipType.Fade] =             {3, 0.11, 6.00},
  [kMinimapBlipType.Vokex] =             {3, 0.11, 6.00},
  [kMinimapBlipType.Lerk] =             {2, 0.11, 5.00},
  [kMinimapBlipType.Prowler] =             {2, 0.11, 5.00},
  [kMinimapBlipType.Skulk] =            {2, 0.11, 4.00},
  [kMinimapBlipType.Gorge] =            {2, 0.11, 3.50},
  [kMinimapBlipType.Whip] =             {2, 0.10, 3.50},
  [kMinimapBlipType.Hydra] =            {2, 0.10, 3.50},
  [kMinimapBlipType.Drifter] =          {2, 0.10, 3.00}
}

---@param senses BrainSenses
---@param _ Player
local function Ent_AdvArmories_Built(senses, _)
  local advBuiltFilter = Lambda [=[args ent; ent:GetIsBuilt()
    and ent:GetTechId() == kTechId.AdvancedArmory]=]
  return FilterEntitiesArray(senses:Get("ent_armories"), advBuiltFilter)
end

---@param senses BrainSenses
---@param marine Player
local function Ent_AdvArmory_NearestBuilt(senses, marine)
  return GetClosestEntityTo(marine, senses:Get("ent_advArmories_built"))
end

---@param _ BrainSenses
---@param marine Player
local function Ent_Armories(_, marine)
  return GetEntitiesForTeam("Armory", marine:GetTeamNumber())
end

---@param senses BrainSenses
---@param _ Player
local function Ent_Armories_Built(senses, _)
  local builtFilter = Lambda [=[args ent; ent:GetIsBuilt()]=]
  return FilterEntitiesArray(senses:Get("ent_armories"), builtFilter)
end

---@param senses BrainSenses
---@param marine Player
local function Ent_Armory_NearestBuilt(senses, marine)
  return GetClosestEntityTo(marine, senses:Get("ent_armories_built"))
end

---@param _ BrainSenses
---@param marine Player
local function Ent_ProtoLabs(_, marine)
  return GetEntitiesForTeam("PrototypeLab", marine:GetTeamNumber())
end

---@param senses BrainSenses
---@param _ Player
local function Ent_ProtoLabs_Built(senses, _)
  local builtFilter = Lambda [=[args ent; ent:GetIsBuilt()]=]
  return FilterEntitiesArray(senses:Get("ent_protoLabs"), builtFilter)
end

---@param senses BrainSenses
---@param marine Player
local function Ent_ProtoLab_NearestBuilt(senses, marine)
  return GetClosestEntityTo(marine, senses:Get("ent_protoLabs_built"))
end

---@param bot Bot
---@param player Player
---@param mem TeamBrain.Memory
local function GetAttackUrgency(bot, player, mem)
  local time = GetTime()
  local brain = bot.brain
  local teamBrain = brain.teamBrain

  local entId = mem.entId
  local target = GetEntityIfAlive(entId)
  if not target then return nil end

  -- Change designed to prevent marines being kited into further danger.
  if target:isa("Player")
      and time - mem.lastSeenTime > kMarineChaseTime then
    return nil
  end

  local isPartiallyCloaked = HasMixin(target, "Cloakable")
    and target:GetCloakFraction() > 0.5
  local isFullyCloaked = HasMixin(target, "Cloakable")
    and target:GetCloakFraction() > 0.8
  if isFullyCloaked then
    return nil
  elseif isPartiallyCloaked then
    local lastTimeCloak = brain.lastTargetCloakTimes[entId] or 0
    local timeSinceLastCloak = time - lastTimeCloak
    if timeSinceLastCloak < brain.kCloakDelayTime then return nil end
  else
    brain.lastTargetCloakTimes[entId] = time
  end

  -- TODO: GetBotWalkDistance here is probably very expensive.
  ---@type integer
  local numOthers = teamBrain:GetNumAssignedTo(mem,
    function(otherId)
      if otherId ~= player:GetId()
          and GetBotWalkDistance(player, mem.lastSeenPos, mem.lastSeenLoc)
          < 30 then
        return true
      end
      return false
    end)

  local closeBonus = 0
  local dist = GetBotWalkDistance(player, mem.lastSeenPos, mem.lastSeenLoc)

  -- TODO: This is a blatant cheat, marines shouldn't know enemy HP.
  --[[ if target.GetHealthScalar and target:GetHealthScalar() < 0.3 then
    closeBonus = closeBonus + (0.3-target:GetHealthScalar()) * 3
  end ]]

  local urgencyEntry = kUrgencies[mem.btype]
  if not urgencyEntry then return nil end

  if dist < 15 or player:GetIsInCombat() then
    numOthers = 0
  end

  if dist < 20 then
    if target:isa("Whip") and dist < 8 then
      closeBonus = 10.0
    else
      closeBonus = 10 / math.max(1.0, dist)
    end
  end

  return (numOthers >= urgencyEntry[1] and urgencyEntry[2] or urgencyEntry[3])
    + closeBonus + mem.threat
end

---@param senses BrainSenses
---@param marine Player
local function BiggestLifeformThreat(senses, marine)
  PROFILE("MarineBrain - biggestLifeformThreat")
  local maxMem = nil
  local maxUrgency = 0.0
  local threats = senses:Get("mem_threats") ---@type TeamBrain.Memory[]

  for _, mem in ipairs(threats) do
    local urgency = GetAttackUrgency(senses.bot, marine, mem)

    if urgency and urgency > maxUrgency then
      maxUrgency = urgency
      maxMem = mem
    end
  end

  if not maxMem then return nil end

  if senses.bot.brain.debug then
    Print("max mem type = %s", EnumToString(kMinimapBlipType, maxMem.btype))
  end
  LogConditional(gBotDebug:Get("target_prio"),
    "Bot Target: %s", EnumToString(kMinimapBlipType, maxMem.btype))

  local dist = GetPhaseDistanceForMarine(marine, maxMem.lastSeenPos,
    senses.bot.brain.lastGateId)

  return {
    urgency = maxUrgency,
    memory = maxMem,
    distance = dist
  }
end

local OldCreateMarineBrainSenses = CreateMarineBrainSenses

function CreateMarineBrainSenses()
  local senses = OldCreateMarineBrainSenses()

  senses:Add("ent_advArmories_built", Ent_AdvArmories_Built)
  senses:Add("ent_advArmory_nearestBuilt", Ent_AdvArmory_NearestBuilt)
  senses:Add("ent_armories", Ent_Armories)
  senses:Add("ent_armories_built", Ent_Armories_Built)
  senses:Add("ent_armory_nearestBuilt", Ent_Armory_NearestBuilt)
  senses:Add("ent_protoLabs", Ent_ProtoLabs)
  senses:Add("ent_protoLabs_built", Ent_ProtoLabs_Built)
  senses:Add("ent_protoLab_nearestBuilt", Ent_ProtoLab_NearestBuilt)
  senses:Add("biggestLifeformThreat", BiggestLifeformThreat)
  Bishop.marine.PopulateSharedSenses(senses)

  return senses
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
