-- TODO: Class quotas within packs.
-- TODO: Support for Gorge.
-- TODO: Hide the packLock variable in here behind function calls. Other files
-- shouldn't have to see that shit.

Script.Load("lua/Table.lua")
Script.Load("lua/Utility.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.alien.pack = {}

local ipairs = ipairs
local IsValid = IsValid
local TInsert = table.insert
local TRemoveValue = table.removevalue

local Log = Bishop.debug.PackLog

---@class AlienPack
---@field members PlayerBrain[]
---@field leader PlayerBrain
---@field size integer

local kDebug = Bishop.debug.pack
local maxPackSize = 5

---Attempts to create a new pack with brain as its only member. Will not create
---the pack if the bot is retreating or packLock is true.
---@param brain PlayerBrain
function Bishop.alien.pack.CreatePack(brain)
  if brain.activeRetreat or brain.packLock then return end

  brain.pack = {
    members = {brain},
    leader = brain,
    size = 1
  }
  TInsert(brain.teamBrain.packs, brain.pack)
  if kDebug then
    Log("%s formed a new pack.", brain.player)
  end
end

---@param pack AlienPack
local function ChoosePackLeader(pack)
  local newLeader = pack.members[1]

  -- Onos can meat shield for the rest of the pack, so should get priority.
  for _, brain in ipairs(pack.members) do
    if IsValid(brain.player) and brain.player:isa("Onos") then
      newLeader = brain
      break
    end
  end

  if pack.leader ~= newLeader then
    if kDebug and pack.leader and IsValid(pack.leader.player) then
      Log("%s took leadership from %s.", newLeader.player, pack.leader.player)
    elseif kDebug then
      Log("%s took leadership.", newLeader.player)
    end
    pack.leader = newLeader
  end
end

---Joins brain into pack if there is room.
---@param pack AlienPack
---@param brain PlayerBrain
function Bishop.alien.pack.JoinPack(pack, brain)
  -- Gorges are not supported for now.
  if not IsValid(brain.player) or brain.player:isa("Gorge")
      or pack.size >= maxPackSize
      or brain.activeRetreat
      or brain.packLock then
    return
  end

  TInsert(pack.members, brain)
  pack.size = pack.size + 1
  brain.pack = pack
  ChoosePackLeader(pack)
  if kDebug then
    Log("%s joined a pack.", brain.player)
  end
end

local JoinPack = Bishop.alien.pack.JoinPack

---Forces brain to leave its current pack and elects a new leader if required.
---@param brain PlayerBrain
function Bishop.alien.pack.LeavePack(brain)
  local pack = brain.pack
  if not pack then return end

  TRemoveValue(pack.members, brain)
  pack.size = pack.size - 1
  brain.pack = nil
  if kDebug and IsValid(brain.player) then
    Log("%s left its pack.", brain.player)
  elseif kDebug then
    Log("Deleted entity left its pack.")
  end

  if pack.size <= 0 then
    TRemoveValue(brain.teamBrain.packs, pack)
    if kDebug then
      Log("Deleted empty pack.")
    end
  elseif pack.leader == brain then
    ChoosePackLeader(pack)
  end
end

local LeavePack = Bishop.alien.pack.LeavePack

---Returns the current size of the pack.
---@param pack AlienPack
---@return integer
function Bishop.alien.pack.GetPackSize(pack)
  return pack.size
end

---Returns the currently set maximum pack size.
---@return integer
function Bishop.alien.pack.GetMaxPackSize()
  return maxPackSize
end

---Sets the maximum size for all future packs, does not immediately resize them.
---@param size integer
function Bishop.alien.pack.SetMaxPackSize(size)
  if size > 0 then
    local oldSize = maxPackSize
    maxPackSize = size

    if kDebug and oldSize ~= maxPackSize then
      Log("Max pack size set to %s.", maxPackSize)
    end
  end
end

---@param fromPack AlienPack
---@param toPack AlienPack
local function FoldPackIntoPack(fromPack, toPack)
  for i = fromPack.size, 1, -1 do
    local brain = fromPack.members[i]
    LeavePack(brain)
    JoinPack(toPack, brain)

    if toPack.size >= maxPackSize then break end
  end
end

---Merges the smaller pack into the larger pack until full.
---@param packa AlienPack
---@param packb AlienPack
function Bishop.alien.pack.MergePack(packa, packb)
  if packa.size == maxPackSize or packb.size == maxPackSize then return end

  if packa.size > packb.size then
    FoldPackIntoPack(packb, packa)
  else
    FoldPackIntoPack(packa, packb)
  end

  if kDebug then
    Log("Merged two packs.")
  end
end

---Removes any dead brains from their packs.
---@param teamBrain AlienTeamBrain
function Bishop.alien.pack.CleanPacks(teamBrain)
  local packs = teamBrain.packs

  for i = #packs, 1, -1 do
    local pack = packs[i]
    local members = pack.members

    for j = #members, 1, -1 do
      local brain = members[j]

      if not IsValid(brain.player) or not brain.player:GetIsAlive() then
        if kDebug then
          if IsValid(brain.player) then
            Log("Cleaning dead %s from pack.", brain.player)
          else
            Log("Cleaning deleted entity from pack.")
          end
        end

        LeavePack(brain)
      end
    end
  end
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
