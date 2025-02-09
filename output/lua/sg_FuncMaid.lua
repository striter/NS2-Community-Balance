--
--	ns2siege+ Custom Game Mode
--	ZycaR (c) 2016
--
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/SignalListenerMixin.lua")

class 'FuncMaid' (Trigger)

FuncMaid.kMapName = "ns2siege_funcmaid"
FuncMaid.kUpdateTime = 0.5
local networkVars = { }

-- copied from death_trigger, which should do it right
local function KillEntity(self, entity)
    -- don't kill powerpoint
    if entity:isa("PowerPoint") then return end

    if Server and HasMixin(entity, "Live") and entity:GetIsAlive() and entity:GetCanDie() then
        local direction = GetNormalizedVector(entity:GetModelOrigin() - self:GetOrigin())
        entity:Kill(self, self, self:GetOrigin(), direction)
    end
end

-- Fetches a list of Entities of the specified Class and kills them.
local function KillEntitiesByClassname(self, classname)
    for _, entity in ientitylist(Shared.GetEntitiesWithClassname(classname)) do
        if self:GetIsPointInside(entity:GetOrigin()) then
            Shared.Message('Maid\'s cleaning duty for ' .. classname .. ' .. ' .. entity:GetId())
            KillEntity(self, entity) -- do cleanup
        end
    end
end

local function FuncMaidTriggered(self)
    local front, siege, suddendeath = GetGameInfoEntity():GetSiegeTimes()
    local active = (self.type == 0 and front > 0) or (self.type == 1 and siege > 0)
    if GetGamerules():GetGameStarted() and active then
        KillEntitiesByClassname(self, "Cyst")
        KillEntitiesByClassname(self, "Contamination")
        KillEntitiesByClassname(self, "TunnelEntrance")
        KillEntitiesByClassname(self, "DrifterEgg")
    end
end

local function KillAllInMaid(self)
    local origin = self:GetOrigin()
    local radius = (self.scale * 0.25):GetLength()
    local hitEntities = GetEntitiesWithMixinWithinRange("Live", origin, radius)

    for _, entity in ipairs(hitEntities) do
        if self:GetIsPointInside(entity:GetOrigin()) and not entity:isa("Weapon") then
            Shared.Message('Maid\'s killing duty for .. ' .. entity:GetClassName())
            KillEntity(self, entity) -- do cleanup
        end
    end
end

function FuncMaid:OnCreate()
    Trigger.OnCreate(self)
    InitMixin(self, SignalListenerMixin)
    self:SetPropagate(Entity.Propagate_Never)
    self.listenMessage = self.listenMessage or "maid_kill"
end

function FuncMaid:OnInitialized()
    Trigger.OnInitialized(self)
    self:SetTriggerCollisionEnabled(true)
    self:SetUpdates(false)

    self:RegisterSignalListener(function()
        FuncMaidTriggered(self)
    end, kSignalFuncMaid)

    self:RegisterSignalListener(function()
        KillAllInMaid(self)
    end, self.listenMessage)

end

if Server then
    function FuncMaid:OnTriggerEntered(entity, triggerEnt) end
    function FuncMaid:OnTriggerExited(entity, triggerEnt) end
end


Shared.LinkClassToMap("FuncMaid", FuncMaid.kMapName, networkVars)
