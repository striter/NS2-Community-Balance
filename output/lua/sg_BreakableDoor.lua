--Kyle 'Avoca' Abent


Script.Load("lua/LiveMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/StaticTargetMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/WeldableMixin.lua")

class 'BreakableDoor'(ScriptActor)

BreakableDoor.kMapName = "breakable_door"

BreakableDoor.kModelName = PrecacheAsset("models/misc/door/door.model")
local kDoorAnimationGraph = PrecacheAsset("models/misc/door/door.animation_graph")
local networkVars = {
    open              = "boolean",
    team              = "integer (0 to 2)",
    timeOfDestruction = "private time",
    
}
AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function BreakableDoor:OnCreate()
    
    ScriptActor.OnCreate(self)
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, TeamMixin)
    self.timeOfDestruction = 0


end
function BreakableDoor:OnInitialized()
    ScriptActor.OnInitialized(self)
    self:SetModel(BreakableDoor.kModelName, kDoorAnimationGraph)
    InitMixin(self, WeldableMixin)
    
    self.open = false
    
    if Server then
        self:SetPhysicsType(PhysicsType.Kinematic)
        self:SetPhysicsGroup(0)
        self.health = 4000
        self:SetMaxHealth(self.health)
        self.teamNumber = 1
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        InitMixin(self, StaticTargetMixin)
        self:SetUpdates(true)
    elseif Client then
        InitMixin(self, UnitStatusMixin)
    end

end
function BreakableDoor:GetCanTakeDamage()
    if self.health == 0 then
        return false
    else
        return true
    end
end

function BreakableDoor:OnUpdate(deltatime)
    --Add in scan for arcs and macs to open for
    if Server then
        if self.health == 0 and not self.open then
            self.open = true
            self.timeOfDestruction = Shared.GetTime()
            return true
        end
    end

end
function BreakableDoor:GetReceivesStructuralDamage()
    return true
end
function BreakableDoor:GetCanDieOverride()
    return false
end
function BreakableDoor:Reset()
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(0)
    self:SetModel(BreakableDoor.kModelName, kDoorAnimationGraph)
    self.open = false
    self.health = 4000
end

local function GetRecentlyDestroyed(self)
    return (self.timeOfDestruction + 8) > Shared.GetTime()
end
function BreakableDoor:GetCanBeWeldedOverride()
    return not GetRecentlyDestroyed(self)
end
--
--local function DisplayTimeTillWeldable(self)
--local NowToWeld = 8 - (Shared.GetTime() - self.timeOfDestruction)
--local WeldLength = math.ceil( Shared.GetTime() + NowToWeld - Shared.GetTime())
--local time = WeldLength
--return string.format(Locale.ResolveString("%s seconds"), time)
--end
--function BreakableDoor:GetUnitNameOverride(viewer) --though not working, not big deal
--local unitName = GetDisplayName(self)
--if not self.open then
--unitName = string.format(Locale.ResolveString("Locked Door"))
--else
--if GetRecentlyDestroyed(self) then
--return DisplayTimeTillWeldable(self)
--end
--
--unitName = string.format(Locale.ResolveString("Open Door"))
--end
--return unitName
--end

function BreakableDoor:OnGetMapBlipInfo()
    
    local success = false
    local blipType = kMinimapBlipType.Undefined
    local blipTeam = -1
    local isAttacked = HasMixin(self, "Combat") and self:GetIsInCombat()
    local isParasited = HasMixin(self, "ParasiteAble") and self:GetIsParasited()
    
    blipType = kMinimapBlipType.Door
    blipTeam = self:GetTeamNumber()
    
    return blipType, blipTeam, isAttacked, isParasited
end
function BreakableDoor:GetCanBeUsed(player, useSuccessTable)
    if player:GetTeamNumber() == 1 and self.health > 0 and not self.open then
        useSuccessTable.useSuccess = true
    else
        useSuccessTable.useSuccess = false
    end
end
local function AutoClose(self, timePassed)
    if self.open then
        self.open = false
    end
    return false
end
function BreakableDoor:OnUse(player, elapsedTime, useSuccessTable)
    
    if not self.open then
        self.open = true
    end
    self:AddTimedCallback(AutoClose, 4)
end
function BreakableDoor:OnAddHealth()
    if self.open and self.health >= 1 then
        self.open = false
    end
end
function BreakableDoor:GetHealthbarOffset()
    return 0.45
end
function BreakableDoor:GetHealthbarOffset()
    return 0.45
end
function BreakableDoor:OnUpdateAnimationInput(modelMixin)
    
    PROFILE("BreakableDoor:OnUpdateAnimationInput")
    
    local open = self.open == true
    local lock = not open
    
    modelMixin:SetAnimationInput("open", open)
    modelMixin:SetAnimationInput("lock", lock)

end
function BreakableDoor:GetShowHitIndicator()
    return true
end
function BreakableDoor:GetSendDeathMessageOverride()
    return false
end

Shared.LinkClassToMap("BreakableDoor", BreakableDoor.kMapName, networkVars)