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
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/BiomassHealthMixin.lua")

class 'SporeMine' (ScriptActor)

local kStartScale = 0.5
local kFinalScale = 1.2
local kCollisionRadius = 0.37
SporeMine.kMapName = "sporemine"
SporeMine.kDropRange = 6.5

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
AddMixinNetworkVars(LOSMixin, networkVars)

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
    InitMixin(self, LOSMixin)
    InitMixin(self, CloakableMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, BiomassHealthMixin)
    
    if Server then
        self.silenced = false
        self.timeLastSpore = Shared.GetTime()
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

        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end

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

function SporeMine:GetExtraHealth(techLevel,extraPlayers,recentWins)
    return kSporeMineHealthPerBioMass * techLevel
end

function SporeMine:GetReceivesStructuralDamage()
    return true
end

function SporeMine:OnAdjustModelCoords(modelCoords)
    local scale = kStartScale + self.buildFraction * (kFinalScale - kStartScale)
    modelCoords.xAxis = modelCoords.xAxis * scale
    modelCoords.yAxis = modelCoords.yAxis * scale
    modelCoords.zAxis = modelCoords.zAxis * scale
    return modelCoords
end

function SporeMine:GetIsFlameAble()
    return true
end

if Server then

    function SporeMine:GetSendDeathMessageOverride()
        return false
    end
    
    --function SporeMine:OnTakeDamage(_, attacker, doer)
    --    if self:GetIsBuilt() then
    --        local owner = self:GetOwner()
    --        local doerClassName = doer and doer:GetClassName()
    --
    --        if owner and doer and attacker == owner and doerClassName == "Spit" then
    --            self:Explode(attacker:GetOrigin())
    --        end
    --    end
    --end
    
    function SporeMine:CastSpore(_destination)
        local coords = self:GetCoords()
        local upward = coords.yAxis
        local origin = self:GetOrigin()
        if not _destination then    --Trace upward and try find the destination
            local trace = Shared.TraceRay(self:GetOrigin() + coords.yAxis * 0.1, self:GetOrigin() + coords.yAxis * kSporeMineCloudCastRadius,  CollisionRep.Default,  PhysicsMask.Bullets, EntityFilterAll())
            if trace.fraction ~= 1 then
                _destination = trace.endPoint - upward * 2
            else
                _destination =  self:GetOrigin() + upward * 2      --Nothing traced? leave a dust cloud
            end
        end
        
        local spores = CreateEntity( SporeCloud.kMapName, origin - upward * 1 , self:GetTeamNumber())
        local sporeDirection = _destination - origin
        spores:SetTravelDestination( origin + GetNormalizedVector(sporeDirection) * math.min(sporeDirection:GetLength(), kSporeMineCloudCastRadius) ,true)
        spores:SetOwner(self:GetOwner())
    end

    function SporeMine:Explode()

        local owner = self:GetOwner()
        
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
        dotMarker:SetOwner(owner)
        
        local function NoFalloff()
            return 0
        end
        dotMarker:SetFallOffFunc(NoFalloff)
        dotMarker:TriggerEffects("bilebomb_hit")

        DestroyEntity(self)
    end

    function SporeMine:DetectThreatFilter()
        return function (t)
            return t ~= self and not t:isa("Clog")
        end
    end

    function SporeMine:DetectThreat()
        if self:GetIsBuilt() then
            local castSpore = GetIsTechUnlocked(self,kTechId.Spores)
            local otherTeam = GetEnemyTeamNumber(self:GetTeamNumber())
            if castSpore then
                
                local time = Shared.GetTime()
                if time - self.timeLastSpore > kSporeMineCloudCastInterval then
                    local allEnemies = GetEntitiesForTeamWithinRange("Player", otherTeam, self:GetOrigin(),  kSporeMineCloudCastRadius)
                    if #allEnemies > 0 then
                        self.timeLastSpore = time
                        self:CastSpore(nil)
                    end
                end
                
            else
                local allEnemies = GetEntitiesForTeamWithinRange("Player", otherTeam, self:GetOrigin(),  kSporeMineDamageRadius)
                local enemies = {}

                for _, ent in ipairs(allEnemies) do
                    if ent:GetIsAlive() then
                        table.insert(enemies, ent)
                    end
                end
                
                local targetPoint
                Shared.SortEntitiesByDistance(self:GetOrigin(), enemies)
                for _, ent in ipairs(enemies) do
                    local startPoint = ent:GetEngagementPoint()
                    local endPoint = self:GetOrigin() + self:GetCoords().yAxis * (kCollisionRadius - 0.1)
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
                        targetPoint = startPoint
                        break
                    end
                end
                
                if targetPoint then
                    self:Explode()
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
        self:TriggerEffects("death")
        if self:GetIsBuilt() then
            if GetIsTechUnlocked(self,kTechId.Spores) then
                self:CastSpore(attacker and attacker:GetOrigin() or nil)
            else
                self:Explode()
            end         
        end
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
