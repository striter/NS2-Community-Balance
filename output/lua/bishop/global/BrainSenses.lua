Bishop.debug.FileEntry(debug.getinfo(1, "S"))

---@class BrainSenses
BrainSenses = nil
class "BrainSenses"

-- TODO: These were added by Bot_Maintenance, mirroring for compatibility.
gLastAlienReports = gLastAlienReports or {}
gLastMarineReports = gLastMarineReports or {}

function BrainSenses:Initialize()
  self.functions = {}
  self.values = {}
  self.evaluating = {}
end

---@param name string
---@param func function
function BrainSenses:Add(name, func)
  self.functions[name] = func
end

function BrainSenses:SetMaster()
  if self.parentSenses and not self.parentSenses.hasMaster then
    self.master = true
    self.parentSenses.hasMaster = true
  end
end

---@param senses BrainSenses
function BrainSenses:SetParentSenses(senses)
  self.parentSenses = senses
end

---@param teamNumber integer
function BrainSenses:SetTeamNumber(teamNumber)
  self.teamNumber = teamNumber
end

---@return integer
function BrainSenses:GetTeamNumber()
  return self.teamNumber
end

---@return Player|nil
function BrainSenses:GetPlayer()
  return self.player
end

---@param bot Bot
function BrainSenses:OnBeginFrame(bot)
  table.clear(self.values)
  self.bot = bot

  if bot then
    self.player = bot:GetPlayer()
  else
    self.player = nil
  end

  if self.master then
    self.parentSenses:OnBeginFrame()
  end
end

---@return string
function BrainSenses:GetDebugTrace()
  return self.debugTrace
end

function BrainSenses:ResetDebugTrace()
  self.debugTrace = ""
end

---@param name string
---@return any
function BrainSenses:Get(name)
  local value = self.values[name]

  if not value then
    local func = self.functions[name]
    
    if not func and self.parentSenses then
      return self.parentSenses:Get(name)
    end

    --assert(not self.evaluating[name])
    --assert(func)
    --self.evaluating[name] = true
    value = func(self, self.player)
    --self.evaluating[name] = nil
    self.values[name] = value
  end

  if self.debugTrace then
    local oldTrace = self.debugTrace
    self.debugTrace = ""
    self.debugTrace = string.format("%s%s = %s%s",
      oldTrace == "" and "" or oldTrace .. ", ", name, ToString(value),
      self.debugTrace == "" and "" or " (" .. self.debugTrace .. ")")
  end

  return value
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
