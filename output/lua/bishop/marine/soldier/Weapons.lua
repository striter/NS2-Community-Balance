Script.Load("lua/Entity.lua")
Script.Load("lua/Gamerules_Global.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/bots/BotUtils.lua")
Script.Load("lua/Weapons/Marine/ClipWeapon.lua")
Script.Load("lua/Weapons/Marine/Flamethrower.lua")
Script.Load("lua/Weapons/Marine/GrenadeLauncher.lua")
Script.Load("lua/Weapons/Marine/HeavyMachineGun.lua")
Script.Load("lua/Weapons/Marine/Shotgun.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.marine.soldier.weapons = {}

local floor = math.floor
local GetEntitiesAliveForTeam = GetEntitiesAliveForTeam
local GetGamerules = GetGamerules
local GetTeamBrain = GetTeamBrain
local ipairs = ipairs
local max = math.max
local pairs = pairs

local kTechId = kTechId

--[[ The functions below implement this table:
          1  2  3  4  5  6  7  8  9 10 11 12 13 14
shotguns  1  1  1  1  1  2  2  2  3  3  3  4  4  4 max(floor(numMarines / 3), 1)
hmg       0  1  1  1  1  1  2  2  2  3  3  3  4  4
exo	      0  0  0  0  1  1  1  2  2  2  3  3  3  4
flam	    0  0  0  0  1  1  1  1  1  1  1  1  1  1
gl        0  0  0  0  1  1  1  1  1  1  1  1  1  1

]]

---@param numMarines integer
local function GetDesiredMGCount(numMarines)
  return numMarines < 2 and 0 or max(floor((numMarines - 1) / 3), 1)
end

---@param numMarines integer
local function GetDesiredExoCount(numMarines)
  return floor((numMarines - 2) / 3)
end

---@param numMarines integer
local function GetDesiredFTCount(numMarines)
  return numMarines >= 5 and 1 or 0
end

---@param numMarines integer
local function GetDesiredGLCount(numMarines)
  return numMarines >= 5 and 1 or 0
end

---Gets the current non-LMG primary weapon or the bot's desired weapon.
---@param marine Player
---@return integer
local function GetCurrentWeapon(marine)
  if marine:isa("Exosuit") then
    Bishop.debug.WeaponsLog("!!! REMOVE ME !!! currentWeapon = Exosuit")
    return kTechId.DualMinigunExosuit
  end

  local currentWeapon = marine:GetWeaponInHUDSlot(1)
  if currentWeapon and currentWeapon:GetTechId() ~= kTechId.Rifle then
    return currentWeapon:GetTechId()
  end

  return kTechId.None
end

---Returns the kTechId entry of a weapon that should be purchased.
---@return integer
function Bishop.marine.soldier.weapons.GetRequiredWeapon()
  local teamSize = GetGamerules():GetTeam(kMarineTeamType):GetNumPlayers() - 1
  local desiredWeapons = {
    [kTechId.HeavyMachineGun] = GetDesiredMGCount(teamSize),
    [kTechId.DualMinigunExosuit] = GetDesiredExoCount(teamSize),
    [kTechId.Flamethrower] = GetDesiredFTCount(teamSize),
    [kTechId.GrenadeLauncher] = GetDesiredGLCount(teamSize),
  }

  do
    ---@type Player[]
    local marines = GetEntitiesAliveForTeam("Player", kMarineTeamType)
    for _, marine in ipairs(marines) do
      if marine:GetIsAlive() and not marine:isa("Commander") then
        local weapon = GetCurrentWeapon(marine)
        if weapon and desiredWeapons[weapon] then
          desiredWeapons[weapon] = desiredWeapons[weapon] - 1
        end
      end
    end

    local bots = GetTeamBrain(kMarineTeamType).teamBots ---@type Bot[]
    for _, bot in ipairs(bots) do
      local desiredWeapon = bot.desiredWeapon

      if desiredWeapon and desiredWeapons[desiredWeapon] then
        desiredWeapons[desiredWeapon] = desiredWeapons[desiredWeapon] - 1
      end
    end
  end

  local weapon = kTechId.Shotgun
  for potentialWeapon, missingCount in pairs(desiredWeapons) do
    if missingCount > 0 then
      weapon = potentialWeapon
      break
    end
  end

  return weapon
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
