Script.Load("lua/TechTreeConstants.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/alien/AlienTeamSenses.lua")
Script.Load("lua/bishop/alien/Pack.lua")
Script.Load("lua/bishop/aliencom/OffensiveTunnel.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local Shared_GetTime = Shared.GetTime

local CleanPacks = Bishop.alien.pack.CleanPacks
local kTunnelState = Bishop.alienCom.offensiveTunnel.kTunnelState
local SetMaxPackSize = Bishop.alien.pack.SetMaxPackSize

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kAlienTechs = {               -- Techs split into hive tiers.
  [kTechId.Skulk] = {{kTechId.Leap}, {}, {kTechId.Xenocide}},
  [kTechId.Gorge] = {{kTechId.BileBomb}, {}, {}},
  [kTechId.Lerk]  = {{}, {kTechId.Spores, kTechId.Umbra}, {}},
  [kTechId.Fade]  = {{kTechId.MetabolizeEnergy}, {kTechId.MetabolizeHealth,
                     kTechId.Stab}, {}},
  [kTechId.Onos]  = {{}, {kTechId.BoneShield, kTechId.Stomp}, {}}
}
local kChamberNotCragProb    = 0.25 -- Probability first chamber is not Crag.

local kTimeBetweenPackCleans = 5    -- Periodically delete empty packs.
local kTimeBetweenPackResize = 30   -- Resize pack if team size has changed.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local AlienTeamBrain_Initialize = _G.AlienTeamBrain.Initialize
local AlienTeamBrain_Reset = _G.AlienTeamBrain.Reset

--------------------------------------------------------------------------------
-- Pack system initialization.
--------------------------------------------------------------------------------

local function InitializePacks(teamBrain)
  teamBrain.lastPackCleanTime = 0
  teamBrain.lastPackResize = -kTimeBetweenPackResize
  teamBrain.packs = {}
end

--------------------------------------------------------------------------------
-- Offensive tunnel initialization.
--------------------------------------------------------------------------------

local function InitializeOffensiveTunnel(teamBrain)
  teamBrain.nextOffensiveShadeTime = 0
  teamBrain.nextOffensiveTunnelScan = 0
  teamBrain.nextOffensiveTunnelTime = 0
  teamBrain.offensiveShade = false
  teamBrain.offensiveTunnelState = kTunnelState.Unbuilt
end

--------------------------------------------------------------------------------
-- Tech randomization.
--------------------------------------------------------------------------------

local function GenerateChamberOrder(teamBrain)
  teamBrain.chamberOrder = {}
  local chambers = {kTechId.UpgradeToCragHive, kTechId.UpgradeToShadeHive,
    kTechId.UpgradeToShiftHive}
  local roll = math.random()

  if roll <= kChamberNotCragProb then
    table.insert(teamBrain.chamberOrder, table.remove(chambers, 1))
  elseif roll <= 1 - ((1 - kChamberNotCragProb) / 2) then
    table.insert(teamBrain.chamberOrder, table.remove(chambers, 2))
  else
    table.insert(teamBrain.chamberOrder, table.remove(chambers, 3))
  end

  table.shuffle(chambers)
  table.addtable(chambers, teamBrain.chamberOrder)
end

local function GenerateClassOrder(teamBrain)
  teamBrain.classOrder = {kTechId.Skulk, kTechId.Gorge, kTechId.Fade,
    kTechId.Lerk, kTechId.Onos}
  table.shuffle(teamBrain.classOrder)

  if Bishop.debug.alienClass then
    local techId = Bishop.lib.constants.kClassNameToTechId
      [Bishop.debug.alienClass]
    if techId then
      table.removevalue(teamBrain.classOrder, techId)
      table.insert(teamBrain.classOrder, 1, techId)
    end
  end
end

local function GenerateTechOrder(teamBrain)
  GenerateChamberOrder(teamBrain)
  GenerateClassOrder(teamBrain)
  teamBrain.techOrder = {}

  for techLevel = 1, 3 do
    for _, class in ipairs(teamBrain.classOrder) do
      table.addtable(kAlienTechs[class][techLevel], teamBrain.techOrder)
    end
  end

  table.insert(teamBrain.techOrder, kTechId.Contamination)
  Shine.SetUpValue(GetTechPathProgressForAlien, "kAlienCommanderTechPath",
    {teamBrain.techOrder}, true)
end

--------------------------------------------------------------------------------
-- Hooks.
--------------------------------------------------------------------------------

---@param senses BrainSenses
function AlienTeamBrain:PopulateTeamSenses(senses)
  Bishop.alien.PopulateTeamSenses(senses)
end

function AlienTeamBrain:Initialize(label, teamNumber)
  AlienTeamBrain_Initialize(self, label, teamNumber)

  InitializePacks(self)
  InitializeOffensiveTunnel(self)
  GenerateTechOrder(self)
end

function AlienTeamBrain:Reset()
  AlienTeamBrain_Reset(self)

  InitializePacks(self)
  InitializeOffensiveTunnel(self)
  GenerateTechOrder(self)
end

local function AlienTeamBrain_Update(self)
  local time = Shared_GetTime()

  if time > self.lastPackCleanTime + kTimeBetweenPackCleans then
    CleanPacks(self)
    self.lastPackCleanTime = time
  end

  if time > self.lastPackResize + kTimeBetweenPackResize then
    SetMaxPackSize(math.ceil(#self.teamBots / 2))
    self.lastPackResize = time
  end
end

Shine.Hook.SetupClassHook("AlienTeamBrain", "Update",
  "BishopAlienTeamBrainUpdate", "PassivePost")
Shine.Hook.Add("BishopAlienTeamBrainUpdate", "BishopATBUHook",
  AlienTeamBrain_Update)

Bishop.debug.FileExit(debug.getinfo(1, "S"))
