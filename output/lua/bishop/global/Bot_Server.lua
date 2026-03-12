Script.Load("lua/TechTreeConstants.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/alien/Lifeform.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

---@class Bot
---@field aim BotAim
---@field buyTemptation integer Random resource offset to purchase a weapon now.
---@field brain PlayerBrain
---@field desiredWeapon integer Desired weapon purchase for Marine bots.
---@field GetBotCanSeeTarget function
---@field GetMotion function
---@field GetPlayer Player?
---@field nextVentEntropyTime number
---@field nextVentResetTime number
---@field nextVentScanTime number
---@field ventEntropy number -- TODO: Should be elsewhere?
---@field ventPath VentPath -- TODO: Should be elsewhere?

local kBuyTemptation = 30 -- Random offset desire to buy early.

--------------------------------------------------------------------------------
-- Allow bots to imbalance teams.
--------------------------------------------------------------------------------
-- To support Bishop's bot manager allowing imbalanced teams, allow bots to
-- force join a team regardless of balance.

---@diagnostic disable-next-line: duplicate-set-field
function Bot:UpdateTeam()
  PROFILE("Bot:UpdateTeam")

  local player = self:GetPlayer()
  if player and player:GetTeamNumber() == 0 then
    if not self.team or self.team == 0 then
      local nTeam1Players = GetGamerules():GetTeam1():GetNumPlayers()
      local nTeam2Players = GetGamerules():GetTeam2():GetNumPlayers()
      if nTeam1Players < nTeam2Players then
        self.team = 1
      else
        self.team = 2
      end
    end

    local gamerules = GetGamerules()
    if gamerules then
      if gamerules:JoinTeam(player, self.team, true) then
        self.teamJoined = true
      end
    end 
  end
end

--------------------------------------------------------------------------------
-- Give each bot a unique ID on join.
--------------------------------------------------------------------------------
-- All bots have the unfortunate situation of sharing client ID 0. This means
-- structures like Hydras are shared between all bots, allowing only three
-- Hydras total instead of three per Gorge. This change pairs with the changes
-- made to AlienTeam to give bots their own unique ID for use with buildings.

-- An arbitrarily high number that will hopefully never conflict.
local uniqueBotId = 1700

local function Bot_InitializePost(self)
  self.botId = uniqueBotId
  uniqueBotId = uniqueBotId + 1

  -- Generate preferred upgrades ahead of time.
  Bishop.alien.lifeform.GenerateDesiredUpgrades(self)

  self.buyTemptation = math.random(0, kBuyTemptation)
  self.desiredWeapon = kTechId.None

  self.nextEvolveTime = 0

  self.ventEntropy = 0
  self.ventPath = { active = false }
  self.nextVentEntropyTime = 0
  self.nextVentResetTime = 0
  self.nextVentScanTime = 0
end

Shine.Hook.SetupClassHook("Bot", "Initialize", "BishopBotInitialize",
  "PassivePost")
Shine.Hook.Add("BishopBotInitialize", "BishopBIHook", Bot_InitializePost)

Bishop.debug.FileExit(debug.getinfo(1, "S"))
