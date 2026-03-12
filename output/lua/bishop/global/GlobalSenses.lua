Script.Load("lua/Entity.lua")

Script.Load("lua/bots/BrainSenses.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetEntitiesWithClassname = Shared.GetEntitiesWithClassname
local GetEntitiesWithFilter = GetEntitiesWithFilter

---Holds senses accessible by all bots, where results are cached and reused for
---a short period.
---@type BrainSenses
local globalSenses

function Bishop.global.GetSenses()
  if not globalSenses then
    globalSenses = BrainSenses()
    globalSenses:Initialize()
    Bishop.global.PopulateGlobalSenses(globalSenses)
  end

  return globalSenses
end

---@param senses BrainSenses
---@return Entity[]
local function Ent_TechPoints_Unclaimed(senses)
  local notAttachedFilter = Lambda "args ent; not ent:GetAttached()"
  return GetEntitiesWithFilter(GetEntitiesWithClassname("TechPoint"),
    notAttachedFilter)
end

---@param senses BrainSenses
function Bishop.global.PopulateGlobalSenses(senses)
  senses:Add("ent_techPoints_unclaimed", Ent_TechPoints_Unclaimed)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
