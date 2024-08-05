-- // ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
-- //
-- // lua\Weapons\Alien\AcidRocket.lua
-- //
-- //    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
-- //
-- // ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/CNBalance/Weapons/Alien/AcidRocketBomb.lua")
Script.Load("lua/CNBalance/Weapons/Alien/ShadowStep.lua")

class 'AcidRocket' (ShadowStep)

AcidRocket.kMapName = "acid_rocket"

-- // part of the players velocity is use for the bomb
local kPlayerVelocityFraction = 1

local kViewModel = PrecacheAsset("models/alien/fade/acidRocket/acidRocket_view.model")
local kAnimationGraph = PrecacheAsset("models/alien/fade/acidRocket/acidRocket.animation_graph")
local kAcidRocketViewEffect = PrecacheAsset("cinematics/alien/fade/acid_rocket_residue.cinematic")

local kAttackDuration = Shared.GetAnimationLength(kViewModel, "Fire1")
local kAttackScalar = kAttackDuration * kAcidRocketRoundPerSecond

local kAttachPoint = "FX_Node_01"

local networkVars =
{
    firingPrimary = "boolean"
}

AddMixinNetworkVars(HealSprayMixin, networkVars)

function AcidRocket:OnCreate()

    ShadowStep.OnCreate(self)
    
    self.primaryAttacking = false
    self.timeLastAcidRocket = 0
    
    InitMixin(self, HealSprayMixin)
    
end

function AcidRocket:GetAnimationGraphName()
    return kAnimationGraph
end

function AcidRocket:GetEnergyCost(player)
    return kAcidRocketEnergyCost
end

function AcidRocket:GetHUDSlot()
    return 3
end

function AcidRocket:GetDeathIconIndex()
    return kDeathMessageIcon.AcidRocket
end

function AcidRocket:GetViewModelName()

    local viewModel = ""
    local parent = self:GetParent()
    
    if parent ~= nil and parent:isa("Alien") then
        viewModel = kViewModel
    end
    
    return viewModel
    
end

function AcidRocket:GetResetViewModelOnDraw()
    return false
end

function AcidRocket:GetSecondaryTechId()
    return kTechId.ShadowStep
end


local function DelayedShoot(self)

    local player = self:GetParent()        
    if player then

        if Server or (Client and Client.GetIsControllingPlayer()) then
            self:FireBombProjectile(player)
        end
        
        player:DeductAbilityEnergy(self:GetEnergyCost(player))            
        self.timeLastAcidRocket = Shared.GetTime()
        
        self:TriggerEffects("acidrocket_attack")
        
        if Client then
            local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
            cinematic:SetCinematic(kAcidRocketViewEffect)
        end
        
        -- TEST_EVENT("DelayedShoot")
        
    end
    return false
    
end

function AcidRocket:OnTag(tagName)

    PROFILE("AcidRocket:OnTag")

    if self.primaryAttacking and tagName == "shoot" then   
        self:AddTimedCallback(DelayedShoot, 0.05)   
    end
    
end

function AcidRocket:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost(player) then
    
        self.primaryAttacking = true
        
    else
        self.primaryAttacking = false
    end  
    
end

function AcidRocket:OnPrimaryAttackEnd(player)

    ShadowStep.OnPrimaryAttackEnd(self, player)
    
    self.primaryAttacking = false
    
end

function AcidRocket:GetTimeLastBomb()
    return self.timeLastAcidRocket
end

function AcidRocket:FireBombProjectile(player)

    PROFILE("AcidRocket:FireBombProjectile")

    if not Predict then
        local viewCoords = player:GetViewCoords()
        local eyePos = player:GetEyePos()

        local startPointTrace = Shared.TraceCapsule(eyePos, eyePos + (viewCoords.xAxis * -0.5) + (viewCoords.zAxis - 0.15), 0.2, 0, CollisionRep.Damage, PhysicsMask.PredictedProjectileGroup, EntityFilterOneAndIsa(player, "Babbler"))
        local startPoint = startPointTrace.endPoint

        local endPointTrace = Shared.TraceRay(eyePos, eyePos + viewCoords.zAxis * 1000 , CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOne(player))

        local startVelocity = GetNormalizedVector(endPointTrace.endPoint - startPoint) * kAcidRocketVelocity
        player:CreatePredictedProjectile("AcidRocketBomb", startPoint, startVelocity, 0, 0, 0)

        --DebugLine(startPoint, endPointTrace.endPoint, .2, 1,0,0,1)

        if Client and not player:GetIsFirstPerson() then
            local worldCinematic = Client.CreateCinematic(RenderScene.Zone_Default)
            worldCinematic:SetAttachPoint(player:GetAttachPointIndex("fxnode_acidrocket"))
            worldCinematic:SetCinematic(kAcidRocketViewEffect)
        end
    end
    
end

function AcidRocket:ModifyAttackSpeedView(attackSpeedTable)
    attackSpeedTable.attackSpeed = attackSpeedTable.attackSpeed * kAttackScalar
end

function AcidRocket:OnUpdateAnimationInput(modelMixin)

    PROFILE("AcidRocket:OnUpdateAnimationInput")
    
    local activityString = "none"
    if self.primaryAttacking then
        activityString = "rocket"
    end
    modelMixin:SetAnimationInput("activity", activityString)
    
end

Shared.LinkClassToMap("AcidRocket", AcidRocket.kMapName, networkVars)