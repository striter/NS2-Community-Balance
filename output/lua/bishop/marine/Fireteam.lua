Script.Load("lua/Table.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.marine.fireteam = {}

local ipairs = ipairs
local table_clear = table.clear
local table_insert = table.insert
local table_remove = table.remove
local table_removevalue = table.removevalue

local Log = Bishop.debug.FireteamLog

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kDebug = Bishop.debug.fireteams
local kFireteamSize = 4 -- Max marines per fireteam.

--------------------------------------------------------------------------------
-- Fireteam management.
--------------------------------------------------------------------------------

local function GetJoinableFireteam(brain)
  local selectedFireteam
  local fireteams = brain.teamBrain.fireteams

  for i, fireteam in ipairs(fireteams) do
    if #fireteam.members < kFireteamSize then
      if kDebug then Log("A bot is joining fireteam #%s.", i) end
      selectedFireteam = fireteam
      break
    end
  end

  if not selectedFireteam then
    if kDebug then Log("A bot is forming a new fireteam.") end
    selectedFireteam = {}
    selectedFireteam.members = {}
    selectedFireteam.leader = nil
    table_insert(fireteams, selectedFireteam)
  end

  return selectedFireteam
end

-- Forces a marine to abandon their fireteam.
function Bishop.marine.fireteam.LeaveFireteam(brain)
  local fireteam = brain.fireteam
  if fireteam then
    table_removevalue(fireteam.members, brain)
    brain.fireteam = nil
    if kDebug then Log("A bot was forced to leave its fireteam.") end
  end
end

-- Joins a marine into a fireteam if it doesn't have one already. The marine
-- will assume leadership of the fireteam if there isn't one.
local function JoinFireteam(brain)
  local fireteam = brain.fireteam
  if not fireteam then
    fireteam = GetJoinableFireteam(brain)
    table_insert(fireteam.members, brain)
    brain.fireteam = fireteam
  end
end

-- Returns true if the marine is a member of a fireteam and is its leader.
-- Passively ensures marines are in a fireteam and have a leader.
function Bishop.marine.fireteam.IsFireteamLeader(brain)
  if not brain.fireteam then
    JoinFireteam(brain)
  end
  local leader = brain.fireteam.leader and brain.fireteam.leader.player
  if not IsValid(leader) or not leader:GetIsAlive() then
    if kDebug then Log("A bot has taken leadership of its fireteam.") end
    brain.fireteam.leader = brain
  end
  return brain.fireteam.leader == brain
end

--------------------------------------------------------------------------------
-- Internal fireteam bookkeeping and cleanup.
--------------------------------------------------------------------------------
-- Should only be called from the TeamBrain.

local function MergeSmallestFireteams(teamBrain)
  local fireteamA, fireteamB
  local fireteamASize = kFireteamSize
  local fireteamBSize = kFireteamSize
  for _, fireteam in ipairs(teamBrain.fireteams) do
    if #fireteam.members > 0 and #fireteam.members < fireteamASize then
      fireteamA = fireteam
      fireteamASize = #fireteam.members
    end
  end
  for _, fireteam in ipairs(teamBrain.fireteams) do
    if #fireteam.members > 0 and #fireteam.members < fireteamBSize
        and fireteam ~= fireteamA then
      fireteamB = fireteam
      fireteamBSize = #fireteam.members
    end
  end

  if fireteamA and fireteamB
      and fireteamASize + fireteamBSize <= kFireteamSize then
    if kDebug then
      Log("Fireteams of size %s and %s merging.", fireteamASize, fireteamBSize)
    end

    for _, brain in ipairs(fireteamB.members) do
      table_insert(fireteamA.members, brain)
      brain.fireteam = fireteamA
    end
    -- The cleanup function will deal with the empty fireteam.
    table_clear(fireteamB.members)
    fireteamB.leader = nil
  end
end

local function RemoveInvalidMarines(teamBrain)
  for _, fireteam in ipairs(teamBrain.fireteams) do
    for i = #fireteam.members, 1, -1 do
      local brain = fireteam.members[i]
      if not IsValid(brain.player) then
        if kDebug then Log("Removing invalid marine from fireteam.") end
        table_remove(fireteam.members, i)
      end
    end
  end
end

local function DeleteEmptyFireteams(teamBrain)
  local fireteams = teamBrain.fireteams
  for i = #fireteams, 1, -1 do
    if #fireteams[i].members == 0 then
      if kDebug then Log("Deleting empty fireteam %s.", i) end
      table_remove(fireteams, i)
    end
  end
end

-- Merges partial fireteams together and cleans up any empty fireteams.
function Bishop.marine.fireteam.CleanFireteams(teamBrain)
  MergeSmallestFireteams(teamBrain)
  RemoveInvalidMarines(teamBrain)
  DeleteEmptyFireteams(teamBrain)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
