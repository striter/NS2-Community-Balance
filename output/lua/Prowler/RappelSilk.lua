-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Alien\Web.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
-- Spit attack on primary.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

--Script.Load("lua/TechMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
--Script.Load("lua/LOSMixin.lua")
Script.Load("lua/OwnerMixin.lua")
Script.Load("lua/Mixins/BaseModelMixin.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/EffectsMixin.lua")

class 'RappelSilk' (Entity)

RappelSilk.kMapName = "rappelsilk"

RappelSilk.kRootModelName = PrecacheAsset("models/alien/gorge/web_helper.model")
local kRappelSilkModelName = PrecacheAsset("models/alien/gorge/web.model")

local kAnimationGraph = PrecacheAsset("models/alien/gorge/web.animation_graph")

local networkVars =
{
    endPoint = "vector",
    length = "float",
}

local kRappelSilkDistortMaterial = PrecacheAsset("models/alien/gorge/web_distort.material")
local kRappelSilkCloakedMaterial = PrecacheAsset("cinematics/vfx_materials/cloaked.material")

--AddMixinNetworkVars(TechMixin, networkVars)
AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
--AddMixinNetworkVars(LOSMixin, networkVars)

PrecacheAsset("models/alien/gorge/web.surface_shader")
local kRappelSilkMaterial = PrecacheAsset("models/alien/gorge/web.material")
local kRappelSilkWidth = 0.1

function RappelSilk:OnAdjustModelCoords(modelCoords)

    local result = modelCoords

    if result then
        result.xAxis = result.xAxis * self.chargeScalingFactor
        result.yAxis = result.yAxis * self.chargeScalingFactor
    end

    return result

end

function RappelSilk:OnCreate()

    Entity.OnCreate(self)

    --InitMixin(self, TechMixin)
    InitMixin(self, EffectsMixin)
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)  
    InitMixin(self, LiveMixin)
    InitMixin(self, EntityChangeMixin)
    --InitMixin(self, LOSMixin)

    if Server then

        InitMixin(self, InvalidOriginMixin)
        InitMixin(self, OwnerMixin)

        self.triggerSpawnEffect = false

    end

    self.numCharges = 1
    self.chargeScalingFactor = 1.0

    self:SetUpdates(true, kDefaultUpdateRate)
    self:SetRelevancyDistance(kMaxRelevancyDistance)

end

function RappelSilk:OnInitialized()

    self:SetModel(kRappelSilkModelName, kAnimationGraph)
    
    self:SetPhysicsType(PhysicsType.Kinematic)
    --self:SetPhysicsGroup(PhysicsGroup.WeaponGroup)
  
end

if Server then

    function RappelSilk:SetEndPoint(endPoint)
    
        self.endPoint = Vector(endPoint)
        self.length = Clamp((self:GetOrigin() - self.endPoint):GetLength(), 0.2, 20)
        
        local coords = Coords.GetIdentity()
        coords.origin = self:GetOrigin()
        coords.zAxis = GetNormalizedVector(self:GetOrigin() - self.endPoint)
        coords.xAxis = coords.zAxis:GetPerpendicular()
        coords.yAxis = coords.zAxis:CrossProduct(coords.xAxis)
        
        self:SetCoords(coords)
        
        self.checkRadius = (self:GetOrigin() - self.endPoint):GetLength() * .5 + 1
        
    end

end

if Server then

    function RappelSilk:GetDestroyOnKill()
        return true
    end

    function RappelSilk:OnKill()
        self:TriggerEffects("death")
    end

end

local function TriggerRappelSilkDestroyEffects(self)

    local startPoint = self:GetOrigin()
    local zAxis = -self:GetCoords().zAxis
    local coords = self:GetCoords()
    
    for i = 1, 20 do

        local effectPoint = startPoint + zAxis * 0.36 * i
        
        if (effectPoint - startPoint):GetLength() >= self.length then
            break
        end
        
        coords.origin = effectPoint

        self:TriggerEffects("web_destroy", { effecthostcoords = coords })    
    
    end

end

function RappelSilk:OnDestroy()

    Entity.OnDestroy(self)
    
    if self.RappelSilkRenderModel then
    
        DynamicMesh_Destroy(self.RappelSilkRenderModel)
        self.RappelSilkRenderModel = nil
        
    end
    
    -- TODO
    -- Shouldn't this be in OnKill, not OnDestroy???
    if Server then
        TriggerRappelSilkDestroyEffects(self)
    end

end

function RappelSilk:GetDistortMaterialName()
    return kRappelSilkDistortMaterial
end

if Client then
    
    function RappelSilk:OnUpdateRender()
        
        if self.RappelSilkRenderModel then
            self._renderModel:SetMaterialParameter("textureIndex", 0 )
        end        
        
    end
    
end

-- TODO: somehow the pose params dont work here when using clientmodelmixin. should figure out why this is broken and switch to clientmodelmixin
function RappelSilk:OnUpdatePoseParameters()
    self:SetPoseParam("scale", self.length)    
end

-- called by the players so they can predict the web effect
function RappelSilk:UpdateWebOnProcessMove(fromPlayer)
    --CheckForIntersection(self, fromPlayer)
end

if Server then

    function RappelSilk:TriggerSilkSpawnEffects()

        local startPoint = self:GetOrigin()
        local zAxis = -self:GetCoords().zAxis
        
        for i = 1, 20 do

            local effectPoint = startPoint + zAxis * 0.36 * i
            
            if (effectPoint - startPoint):GetLength() >= self.length then
                break
            end

            self:TriggerEffects("web_create", { effecthostcoords = Coords.GetTranslation(effectPoint) })    
        
        end
    
    end

    -- OnUpdate is only called when entities are in interest range, players are ignored here since they need to predict the effect
    function RappelSilk:OnUpdate(deltaTime)

        --[[if not self.triggerSpawnEffect then
            self:TriggerSilkSpawnEffects()
            self.triggerSpawnEffect = true
        end--]]

    end
    
    function RappelSilk:GetSendDeathMessageOverride()
        return false
    end

end

Shared.LinkClassToMap("RappelSilk", RappelSilk.kMapName, networkVars)
