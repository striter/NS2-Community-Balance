Script.Load("lua/Entity.lua")
Script.Load("lua/Gamerules_Global.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/Table.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/bots/BotUtils.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.alien.lifeform = {}

local ceil = math.ceil
local floor = math.floor
local GetEntitiesAliveForTeam = GetEntitiesAliveForTeam
local GetGamerules = GetGamerules
local GetTeamBrain = GetTeamBrain
local ipairs = ipairs
local pairs = pairs
local table_insert = table.insert
local table_random = table.random

local Log = Bishop.debug.LifeformLog

--------------------------------------------------------------------------------
-- Balance values and constants.
--------------------------------------------------------------------------------

local kAlienPriority = {    -- Take tickets in this order from top to bottom.
  kTechId.Onos,
  kTechId.Fade,
  kTechId.Gorge,
  kTechId.Lerk,
  kTechId.Skulk
}
local kLifeformUpgrades = { -- Only consider these upgrades for each lifeform.
  [kTechId.Skulk] = {
    {kTechId.Carapace, kTechId.Vampirism},
    {kTechId.Aura, kTechId.Focus, kTechId.Camouflage},
    {kTechId.Celerity, kTechId.Adrenaline, kTechId.Crush}
  },
  [kTechId.Gorge] = {
    {kTechId.Carapace, kTechId.Regeneration},
    {kTechId.Aura, kTechId.Focus},
    {kTechId.Celerity, kTechId.Adrenaline, kTechId.Crush}
  },
  [kTechId.Lerk] = {
    {kTechId.Regeneration},
    {kTechId.Aura, kTechId.Camouflage},
    {kTechId.Celerity, kTechId.Adrenaline}
  },
  [kTechId.Fade] = {
    {kTechId.Carapace, kTechId.Vampirism},
    {kTechId.Focus},
    {kTechId.Celerity, kTechId.Adrenaline}
  },
  [kTechId.Onos] = {
    {kTechId.Carapace, kTechId.Vampirism},
    {kTechId.Focus},
    {kTechId.Celerity, kTechId.Crush}
  }
}
local kMinPresAdvantage = 5 -- Steal a ticket from another bot with less res.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kAlienTeamType = kAlienTeamType
local kDebug = Bishop.debug.lifeform
local kLifeformTable = {
  ["Skulk"] = kTechId.Skulk,
  ["Gorge"] = kTechId.Gorge,
  ["Lerk"] = kTechId.Lerk,
  ["Fade"] = kTechId.Fade,
  ["Onos"] = kTechId.Onos
}
local kTechId = kTechId

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

--[[ The functions below implement this table:
          1  2  3  4  5  6  7  8  9 10 11 12 13 14
skulks    0  0  0  0  0  0  0  0  0  0  0  0  0  0
gorges    0  1  1  1  1  1  2  2  2  2  2  3  3  3
lerks     0  0  0  1  1  1  1  1  2  2  2  2  2  3
fades     0  0  1  1  1  1  1  2  2  2  2  2  3  3
onos      1  1  1  1  2  3  3  3  3  4  5  5  5  5
]]

local function DesiredSkulks(teamSize)
  return 0
end

local function DesiredGorges(teamSize)
  return floor((teamSize + 3) / 5)
end

local function DesiredLerks(teamSize)
  return floor((teamSize + 1) / 5)
end

local function DesiredFades(teamSize)
  return floor((teamSize + 2) / 5)
end

local function DesiredOnos(teamSize)
  return ceil(teamSize / 5) + floor(teamSize / 5)
end

---@param alien Player
---@return integer?
function Bishop.alien.lifeform.GetCurrentLifeform(alien)
  if not alien:GetIsAlive() then
    return nil
  end

  if alien:isa("Embryo") then
    return alien.gestationTypeTechId
  end

  for lifeform, techId in pairs(kLifeformTable) do
    if alien:isa(lifeform) then
      return techId
    end
  end

  Bishop.Error("Lifeform for alive alien %s not in kLifeformTable!", alien)
  return kTechId.None
end

local GetCurrentLifeform = Bishop.alien.lifeform.GetCurrentLifeform

--------------------------------------------------------------------------------
-- Return a required lifeform for the team.
--------------------------------------------------------------------------------
-- Bots take a "ticket" for the lifeform they're saving for. If a bot is holding
-- a ticket, thier current lifeform is ignored.

-- TODO: Re-add support for warm-up random lifeforms.

local function StealToken(lifeform, pres)
  local bots = GetTeamBrain(kAlienTeamType).teamBots

  for _, bot in ipairs(bots) do
    local targetPres = bot:GetPlayer():GetPersonalResources()
    local targetLifeform = bot.desiredLifeform

    if targetLifeform == lifeform
        and pres > targetPres + kMinPresAdvantage then
      if kDebug then
        Log("%s token has been stolen from %s.", kTechId[lifeform],
          bot:GetPlayer():GetName())
      end
      bot.desiredLifeform = nil
      return true
    end
  end

  return false
end

local function TryToStealToken(pres)
  for _, lifeform in ipairs(kAlienPriority) do
    if StealToken(lifeform, pres) then
      return lifeform
    end
  end

  return nil
end

function Bishop.alien.lifeform.GetRequiredLifeform(pres, nosteal)
  if not nosteal then
    local stolenToken = TryToStealToken(pres)

    if stolenToken then
      return stolenToken
    end
  end

  local teamSize = GetGamerules():GetTeam(kAlienTeamType):GetNumPlayers() - 1
  local desiredLifeforms = {
    [kTechId.Skulk] = DesiredSkulks(teamSize),
    [kTechId.Gorge] = DesiredGorges(teamSize),
    [kTechId.Lerk] = DesiredLerks(teamSize),
    [kTechId.Fade] = DesiredFades(teamSize),
    [kTechId.Onos] = DesiredOnos(teamSize)
  }

  local aliens = GetEntitiesAliveForTeam("Player", kAlienTeamType)

  for _, alien in ipairs(aliens) do
    if alien:GetIsAlive()
        and not alien:isa("Commander") then
      local lifeform = GetCurrentLifeform(alien)

      if lifeform then
        desiredLifeforms[lifeform] = desiredLifeforms[lifeform] - 1
      end
    end
  end

  local bots = GetTeamBrain(kAlienTeamType).teamBots

  for _, bot in ipairs(bots) do
    local targetLifeform = bot.desiredLifeform

    if targetLifeform then
      desiredLifeforms[targetLifeform] = desiredLifeforms[targetLifeform] - 1
    end
  end

  for lifeform, desired in pairs(desiredLifeforms) do
    if desired > 0 then
      if kDebug then
        Log("GetRequiredLifeform returning %s.", kTechId[lifeform])
      end
      return lifeform
    end
  end

  return nil
end

--------------------------------------------------------------------------------
-- Return lifeform specific upgrade choices.
--------------------------------------------------------------------------------

function Bishop.alien.lifeform.GenerateDesiredUpgrades(bot)
  bot.desiredUpgrades = {}

  for _, lifeform in pairs(kLifeformTable) do
    local upgrades = {}

    for _, category in ipairs(kLifeformUpgrades[lifeform]) do
      table_insert(upgrades, table_random(category))
    end

    bot.desiredUpgrades[lifeform] = upgrades
  end
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
