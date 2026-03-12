Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.global.pathHistory = {}

local GetTime = Shared.GetTime

local GetCachedTable = Bishop.lib.table.GetCachedTable

local kNudgeVector = Vector(0, 0.2, 0)
local kUpdateDistanceSqr = 8 * 8
local kUpdateDelay = 0.5
local kUpdateDeleteToleranceSqr = 0.5
local kWithinHiveRangeSqr = 35 * 35

---@param alien Player
---@param bot Bot
---@param brain PlayerBrain
---@param move Move
---@param DoMove function
function Bishop.global.pathHistory.RetreatAlien(alien, bot, brain, move, DoMove)
  local pathHistory = GetCachedTable(alien, "pathHistory")
  pathHistory.p = pathHistory.p or {}
  pathHistory.skip = true

  local lastPoint = #pathHistory.p > 0 and pathHistory.p[#pathHistory.p] or nil
  local nearestHive = brain:GetSenses():Get("ent_hive_nearest")
  if not lastPoint or (nearestHive.distanceSqr
      and nearestHive.distanceSqr <= kWithinHiveRangeSqr) then
    table.clear(pathHistory.p)

    -- TODO: Is this good enough?
    if nearestHive.entity then
      DoMove(alien:GetOrigin(), nearestHive.entity:GetOrigin(), bot, brain,
        move)
    else
      bot:GetMotion():SetDesiredMoveTarget()
    end
    return
  end

  if alien:GetDistanceSquared(lastPoint) <= kUpdateDistanceSqr then
    table.remove(pathHistory.p, #pathHistory.p)
  end

  bot:GetMotion():SetDesiredViewTarget()
  DoMove(alien:GetOrigin(), lastPoint, bot, brain, move)
end

local function InsertHistoryPoint(pathHistory, point)
  for i = #pathHistory.p, 1, -1 do
    if point:GetDistanceSquared(pathHistory.p[i])
        <= kUpdateDistanceSqr - kUpdateDeleteToleranceSqr then
      table.remove(pathHistory.p, i)
    end
  end

  table.insert(pathHistory.p, point)
end

---@param player Player
function Bishop.global.pathHistory.UpdatePathHistory(player)
  local pathHistory = GetCachedTable(player, "pathHistory")
  pathHistory.p = pathHistory.p or {}

  if pathHistory.skip then
    pathHistory.skip = false
    return
  elseif pathHistory.nextUpdateTime and GetTime()
      < pathHistory.nextUpdateTime then
    return
  else
    pathHistory.nextUpdateTime = GetTime() + kUpdateDelay
  end

  local lastPoint = #pathHistory.p > 0 and pathHistory.p[#pathHistory.p] or nil
  local point = player:GetOrigin() + kNudgeVector

  if not lastPoint or player:GetDistanceSquared(lastPoint)
      > kUpdateDistanceSqr then
    InsertHistoryPoint(pathHistory, point)
  end
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
