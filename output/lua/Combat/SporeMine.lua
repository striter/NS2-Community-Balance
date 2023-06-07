Script.Load("lua/TeamMixin.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/StaticTargetMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/OwnerMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/MaturityMixin.lua")
Script.Load("lua/ClogFallMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/FireMixin.lua")
Script.Load("lua/IdleMixin.lua")
Script.Load("lua/DetectableMixin.lua")
Script.Load("lua/Weapons/DotMarker.lua")
Script.Load("lua/CloakableMixin.lua")

class 'SporeMine' (ScriptActor)

local kStartScale = 0.5
local kFinalScale = 1.2
local kCollisionRadius = 0.5
SporeMine.kMapName = "sporemine"
SporeMine.kDropRange = 2

SporeMine.kModelName = PrecacheAsset("models/alien/sporemine/sporemine.model")
local kAnimationGraph = PrecacheAsset("models/alien/sporemine/sporemine.animation_graph")

local networkVars =
{
    ownerId = "entityid",
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(ConstructMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(MaturityMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(UmbraMixin, networkVars)
AddMixinNetworkVars(FireMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)
AddMixinNetworkVars(DetectableMixin, networkVars)
AddMixinNetworkVars(CloakableMixin, networkVars)

function SporeMine:OnCreate()

    ScriptActor.OnCreate(self)

    InitMixin(self, ClogFallMixin)
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    
    InitMixin(self, LiveMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, ConstructMixin)
    InitMixin(self, SelectableMixin)

    InitMixin(self, MaturityMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, UmbraMixin)
    InitMixin(self, FireMixin)
    InitMixin(self, DetectableMixin)
    InitMixin(self, CloakableMixin)
    
    if Server then
        self.silenced = false
    end

    self:SetRelevancyDistance(kMaxRelevancyDistance)

end

function SporeMine:OnInitialized()

    self:SetModel(SporeMine.kModelName, kAnimationGraph)
    
    if Server then    

        ScriptActor.OnInitialized(self)

        InitMixin(self, StaticTargetMixin)
    
        local mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom)
        
        if self:GetTeamNumber() == 1 then
            mask = bit.bor(mask, kRelevantToTeam1Commander)
        elseif self:GetTeamNumber() == 2 then
            mask = bit.bor(mask, kRelevantToTeam2Commander)
        end
        
        self:SetExcludeRelevancyMask(mask)

    elseif Client then

        InitMixin(self, UnitStatusMixin)

        self.dirtySkinState = false
        self.delayedSkinUpdate = false

    end

    
    self:MarkPhysicsDirty()

    self.physicsBody = Shared.CreatePhysicsSphereBody(false, kCollisionRadius, 0,  self:GetCoords() )
    self.physicsBody:SetCollisionEnabled(true)
    self.physicsBody:SetGroup(PhysicsGroup.SmallStructuresGroup)
    self.physicsBody:SetPhysicsType(CollisionObject.Static)
    self.physicsBody:SetEntity(self)

    InitMixin(self, IdleMixin)
end

function SporeMine:OnDestroy()

    ScriptActor.OnDestroy(self)
    if self.physicsBody then
        Shared.DestroyCollisionObject(self.physicsBody)
        self.physicsBody = nil
    end

    if Client then
        Client.DestroyRenderDecal(self.decal)
        self.decal = nil
    elseif Server then
        self.preventEntityChangeCallback = true
    end
end

function SporeMine:GetPhysicsModelAllowedOverride()
    return false
end

function SporeMine:GetCanSleep()
    return true
end

function SporeMine:GetMinimumAwakeTime()
    return 0
end

function SporeMine:GetMaturityRate()
    return kSporeMineMatureTime
end

function SporeMine:GetMatureMaxHealth()
    return kMatureSporeMineHealth
end

function SporeMine:GetMatureMaxArmor()
    return kMatureSporeMineArmor
end

function SporeMine:GetMatureMaxEnergy()
    return 0
end

function SporeMine:GetUseMaxRange()
    return SporeMine.kDropRange
end

function SporeMine:OnAdjustModelCoords(modelCoords)
    local scale = kStartScale + self.buildFraction * (kFinalScale - kStartScale)
    modelCoords.xAxis = modelCoords.xAxis * scale
    modelCoords.yAxis = modelCoords.yAxis * scale
    modelCoords.zAxis = modelCoords.zAxis * scale
    return modelCoords
end

if Server then

    function SporeMine:GetSendDeathMessageOverride()
        return not self.consumed
    end
    
    function SporeMine:OnTakeDamage(_, attacker, doer)
        if self:GetIsBuilt() then
            local owner = self:GetOwner()
            local doerClassName = doer and doer:GetClassName()

            if owner and doer and attacker == owner and doerClassName == "Spit" then
                self:Explode(attacker:GetOrigin())
            end
        end
    end

    function SporeMine:Explode(_destination)

        local dotMarker = CreateEntity(DotMarker.kMapName, self:GetOrigin(), self:GetTeamNumber())
        dotMarker:SetTechId(kTechId.SporeMine)
        dotMarker:SetDamageType(kSporeMineDamageType)
        dotMarker:SetLifeTime(kSporeMineDamageDuration)
        dotMarker:SetDamage(kSporeMineDamage)
        dotMarker:SetRadius(kSporeMineDamageRadius)
        dotMarker:SetDamageIntervall(kSporeMineDotInterval)
        dotMarker:SetDotMarkerType(DotMarker.kType.Static)
        dotMarker:SetTargetEffectName("bilebomb_onstructure")
        dotMarker:SetDeathIconIndex(kDeathMessageIcon.SporeMine)
        dotMarker:SetOwner(self:GetOwner())

        local function NoFalloff()
            return 0
        end
        dotMarker:SetFallOffFunc(NoFalloff)

        dotMarker:TriggerEffects("bilebomb_hit")

        if _destination and GetHasTech(self,kTechId.Spores) then
            local position = self:GetOrigin()
            local spores = CreateEntity( SporeCloud.kMapName,position , self:GetTeamNumber() )
            local direction = _destination - position
            spores:SetTravelDestination( position + GetNormalizedVector(direction) * math.min(direction:GetLength(), kSporeMineDamageRadius) )
        end
        
        DestroyEntity(self)
    end

    function SporeMine:DetectThreatFilter()
        return function (t)
            return t ~= self and not t:isa("Clog")
        end
    end

    function SporeMine:DetectThreat()
        if self:GetIsBuilt() then
            local otherTeam = GetEnemyTeamNumber(self:GetTeamNumber())
            local allEnemies = GetEntitiesForTeamWithinRange("Player", otherTeam, self:GetOrigin(), kSporeMineDamageRadius)
            local enemies = {}

            for _, ent in ipairs(allEnemies) do
                if ent:GetIsAlive() then
                    table.insert(enemies, ent)
                end
            end

            Shared.SortEntitiesByDistance(self:GetOrigin(), enemies)
            for _, ent in ipairs(enemies) do
                local dir = self:GetCoords().yAxis
                local startPoint = ent:GetEngagementPoint()
                local endPoint = self:GetOrigin() + dir * self:GetExtents().y
                local filter = self:DetectThreatFilter()

                local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Move, PhysicsMask.Bullets, filter)
                local visibleTarget = trace.entity == self

                -- If a clog is blocking our LOS, check from our origin instead of our model top
                if not visibleTarget and GetIsPointInsideClogs(endPoint) then
                    -- Log("%s is inside clog, doing origin traceray", self)
                    endPoint = self:GetOrigin()
                    trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Move, PhysicsMask.Bullets, filter)
                end

                if visibleTarget and trace.fraction < 1 then
                    self:Explode(startPoint)
                    break
                end
            end
        end

        return self:GetIsAlive()
    end

    function SporeMine:Arm()
        if self:DetectThreat() ~= false then
            self:AddTimedCallback(SporeMine.DetectThreat, 0.60)
        end
    end

    function SporeMine:OnConstructionComplete()
        self:AddTimedCallback(SporeMine.Arm, 1.60)
    end
    
    function SporeMine:GetDestroyOnKill()
        return true
    end

    function SporeMine:OnKill(attacker, doer, point, direction)
        self:Explode(attacker and attacker:GetOrigin() or nil)
        self:TriggerEffects("death")
    end
    
    function SporeMine:SetOwner(owner)
    
        if GetHasSilenceUpgrade(owner) then
            self.silenced = true
        end
    
    end
    
end

function SporeMine:GetEffectParams(tableParams)
    tableParams[kEffectFilterSilenceUpgrade] = self.silenced
end

function SporeMine:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = self.ownerId == player:GetId() and self:GetIsBuilt()
end

function SporeMine:OnUpdateRender()

    local showDecal = self:GetIsVisible() and not self:GetIsCloaked()

    if not self.decal and showDecal then
        self.decal = CreateSimpleInfestationDecal(0.9, self:GetCoords())
    elseif self.decal and not showDecal then
        Client.DestroyRenderDecal(self.decal)
        self.decal = nil
    end

end

Shared.LinkClassToMap("SporeMine", SporeMine.kMapName, networkVars)
