Script.Load("lua/Entity.lua")
Script.Load("lua/Gamerules_Global.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")
Script.Load("lua/Utility.lua")
Script.Load("lua/bots/BotTeamController.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetEntitiesForTeam = GetEntitiesForTeam
local GetGameInfoEntity = GetGameInfoEntity
local GetGamemode = GetGamemode
local GetGamerules = GetGamerules
local Shared_GetTime = Shared.GetTime

--------------------------------------------------------------------------------
-- Technical values.
--------------------------------------------------------------------------------

local kCommanderUpdateTime = 5
local kUpdateTime = 0.9
local nextCommanderUpdateTime = 10
local nextUpdateTime = 0
local numHallucinations = 0 -- Number of bots on Aliens without real clients.
local settings = Bishop.settings.botManager

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kAlienTeamType = kAlienTeamType
local kMarineTeamType = kMarineTeamType

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

local function IsClassicGamemode()
  return GetGamemode() == "ns2"
end

local function GameHasHumans()
  local botTeamController = GetGamerules().botTeamController
  return botTeamController:GetPlayerNumbersForTeam(kMarineTeamType, true) > 0
    or botTeamController:GetPlayerNumbersForTeam(kAlienTeamType, true) > 0
end

local function GameNotStarted()
  local state = GetGameInfoEntity():GetState()
  return state < kGameState.PreGame
end

local function GameStarted()
  local state = GetGameInfoEntity():GetState()
  return state == kGameState.Started
end

local function GameEnded()
  local state = GetGameInfoEntity():GetState()
  return state > kGameState.Started
end

local function MarineTeamSize()
  return GetGamerules():GetTeam(kMarineTeamType):GetNumPlayers()
end

local function CountHallucinations(player)
  if player.isHallucination then
    numHallucinations = numHallucinations + 1
  end
end

local function AlienTeamSize()
  local team = GetGamerules():GetTeam(kAlienTeamType)
  numHallucinations = 0
  team:ForEachPlayer(CountHallucinations)
  return team:GetNumPlayers() - numHallucinations
end

local function HasMarineCommander()
  local botTeamController = GetGamerules().botTeamController
  return botTeamController:GetTeamHasCommander(kMarineTeamType)
end

local function HasAlienCommander()
  local botTeamController = GetGamerules().botTeamController
  return botTeamController:GetTeamHasCommander(kAlienTeamType)
end

local function HasMarineCommanderConflict()
  local botTeamController = GetGamerules().botTeamController
  if not botTeamController:GetCommanderBot(kMarineTeamType) then
    return false
  end

  local commanders = 0
  local stations = GetEntitiesForTeam("CommandStructure", kMarineTeamType)

  for _, station in ipairs(stations) do
    if station.occupied or station.gettingUsed then
      commanders = commanders + 1
    end
  end

  return commanders > 1
end

local function HasAlienCommanderConflict()
  local botTeamController = GetGamerules().botTeamController
  if not botTeamController:GetCommanderBot(kAlienTeamType) then
    return false
  end

  local commanders = 0
  local stations = GetEntitiesForTeam("CommandStructure", kAlienTeamType)

  for _, station in ipairs(stations) do
    if station.occupied or station.gettingUsed then
      commanders = commanders + 1
    end
  end

  return commanders > 1
end

--------------------------------------------------------------------------------
-- Add and remove bots.
--------------------------------------------------------------------------------

local function AddBot(team, commander)
  OnConsoleAddBots(nil, 1, team, commander and "com" or nil)
end

local function RemoveBot(team, commander)
  if not commander then
    OnConsoleRemoveBots(nil, 1, team)
  elseif #gCommanderBots > 0 then
    gCommanderBots[1]:Disconnect()
  end
end

local function RemoveAllBots()
  if #gServerBots > 0 then
    OnConsoleRemoveBots(nil, #gServerBots, nil)
  end
end

--------------------------------------------------------------------------------
-- Manage teams.
--------------------------------------------------------------------------------

-- TODO: How does this behave if two human commanders jump in commander on the
-- same team, with a bot commander on the opposite team?

local function UpdateCommanders()
  local botTeamController = GetGamerules().botTeamController

  if #gCommanderBots > 2 then
    gCommanderBots[1]:Disconnect()
    return
  end

  if settings.marineCommander then
    local humans = botTeamController:GetPlayerNumbersForTeam(kMarineTeamType,
      true)
    local botSlots = settings.marineTeamSize - humans

    if not HasMarineCommander() and botSlots > 0 and #gCommanderBots < 2 then
      AddBot(kMarineTeamType, true)
    elseif HasMarineCommanderConflict() then
      RemoveBot(kMarineTeamType, true)
    end
  end

  if settings.alienCommander then
    local humans = botTeamController:GetPlayerNumbersForTeam(kAlienTeamType,
      true)
    local botSlots = settings.alienTeamSize - humans

    if not HasAlienCommander() and botSlots > 0 and #gCommanderBots < 2 then
      AddBot(kAlienTeamType, true)
    elseif HasAlienCommanderConflict() then
      RemoveBot(kAlienTeamType, true)
    end
  end
end

local function UpdateTeams()
  local gameSize = settings.marineTeamSize + settings.alienTeamSize

  if settings.marines then
    if MarineTeamSize() < settings.marineTeamSize
        and #gServerBots < gameSize then
      AddBot(kMarineTeamType)
    elseif MarineTeamSize() > settings.marineTeamSize then
      RemoveBot(kMarineTeamType)
    end
  end
  if settings.aliens then
    if AlienTeamSize() < settings.alienTeamSize
        and #gServerBots < gameSize then
      AddBot(kAlienTeamType)
    elseif AlienTeamSize() > settings.alienTeamSize then
      RemoveBot(kAlienTeamType)
    end
  end
end

local playerJoined = false

local function BotManager()
  local gamemode = GetGamerules()
  if not gamemode or gamemode.justCreated or not gamemode:GetMapLoaded()
      or not IsClassicGamemode() or not settings.manage or not playerJoined then
    return
  end
  
  if not settings.continueGame and not Shared.GetTestsEnabled()
      and GameStarted() and not GameHasHumans() then
    RemoveAllBots()
  elseif (not settings.forceGame or not settings.continueGame)
      and GameNotStarted() and not GameHasHumans() then
    return
  elseif GameEnded() then
    RemoveAllBots()
    return
  end
  
  local time = Shared_GetTime()
  if nextCommanderUpdateTime < time then
    nextCommanderUpdateTime = time + kCommanderUpdateTime
    UpdateCommanders()
  end
  
  if nextUpdateTime < time then
    nextUpdateTime = time + kUpdateTime
    UpdateTeams()
  end
end

--------------------------------------------------------------------------------
-- Override default bot controls.
--------------------------------------------------------------------------------
-- If a player decides not to use Bishop's manager, re-enable the defaults.

local UpdateBotsVanilla = _G.BotTeamController.UpdateBots

function BotTeamController:UpdateBots()
  if not settings.manage then
    UpdateBotsVanilla(self)
  end
end

local UpdateBotsForTeamVanilla = _G.BotTeamController.UpdateBotsForTeam

function BotTeamController:UpdateBotsForTeam(teamNumber)
  if not settings.manage then
    UpdateBotsForTeamVanilla(self, teamNumber)
  end
end

--------------------------------------------------------------------------------
-- Shine hook to run the BotManager each tick.
--------------------------------------------------------------------------------

Shine.Hook.Add("Think", "BishopBMU", BotManager)

-- A once off ignition to only kick the BotManager into gear once a player has
-- reached the ready room.
Shine.Hook.Add("ClientConnect", "BishopBMStart",
  function()
    playerJoined = true
    Shine.Hook.Remove("ClientConnect", "BishopBMStart")
  end)

Bishop.debug.FileExit(debug.getinfo(1, "S"))
