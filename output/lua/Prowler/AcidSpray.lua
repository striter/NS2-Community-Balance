
Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Prowler/AcidMissile.lua")
Script.Load("lua/Prowler/RappelMixin.lua")


class 'AcidSpray' (Ability)
AcidSpray.kMapName = "acidspray"
AcidSpray.kNumMissiles = 3
AcidSpray.AttackSpeedMod = 2.66  -- 0.69second
local kAcidSpraySpread = Math.Radians(12) -- degrees

local kAnimationGraph = PrecacheAsset("models/alien/prowler/prowler_view.animation_graph")
local kAttackDuration = Shared.GetAnimationLength("models/alien/prowler/prowler_view.model", "bite_attack3") / AcidSpray.AttackSpeedMod

local networkVars =
{
}

AddMixinNetworkVars(RappelMixin, networkVars)

function AcidSpray:OnCreate()

    Ability.OnCreate(self)
    InitMixin(self, RappelMixin)
    
    self.primaryAttacking = false

end

function AcidSpray:GetHUDSlot()
    return 2
end

local kBombVelocity = 22.5

local function CreateAcidProjectile(self, player, index)
    
    if not Predict then
        
        local startPoint
        local startVelocity
        --if GetIsPointInsideClogs(player:GetEyePos()) then
        --    startPoint = player:GetEyePos()
        --    startVelocity = Vector(0,0,0)
        --else
        local viewCoords = player:GetViewAngles():GetCoords()
        local spreadDirection = CalculateSpread(viewCoords, kAcidSpraySpread, NetworkRandom)
        startPoint = player:GetEyePos() + viewCoords.zAxis * 1.4 + viewCoords.xAxis * (0.1 * index - 0.2)
        startVelocity = spreadDirection * kBombVelocity
        
        local startPointTrace = Shared.TraceRay(player:GetEyePos(), startPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOneAndIsa(player, "Babbler"))
        
        startPoint = startPointTrace.endPoint
        --end
        
        player:CreatePredictedProjectile( "AcidMissile", startPoint, startVelocity, 0, 0, 20 )
        
    end
    
end

function AcidSpray:GetAnimationGraphName()
    return kAnimationGraph
end

function AcidSpray:GetAttackAnimationDuration()
    return kAttackDuration
end

function AcidSpray:OnTag(tagName)

    PROFILE("AcidSpray:OnTag")

    if self.primaryAttacking and tagName == "hit" then --tagName == "shoot" then
        
        local player = self:GetParent()
        
        if player then
        
            if Server or (Client and Client.GetIsControllingPlayer()) then
                for i = 1, AcidSpray.kNumMissiles do
                    
                    CreateAcidProjectile(self, player, i)
                                        
                end
            end
            
            player:DeductAbilityEnergy(self:GetEnergyCost())
            --Print(ToString(Shared.GetTime() - (self.timeLastAcidSpray or Shared.GetTime())))
            self.timeLastAcidSpray = Shared.GetTime()
            
            self:TriggerEffects("spitspray_attack")
            
            --[[if Client then
            
                local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
                cinematic:SetCinematic(kBbombViewEffect)
                
            end--]]
            
        end
    
    end
    
end

function AcidSpray:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost() then
    
        self.primaryAttacking = true
        
    else
        self.primaryAttacking = false
    end  
    
end

function AcidSpray:OnPrimaryAttackEnd(player)

    Ability.OnPrimaryAttackEnd(self, player)
    
    self.primaryAttacking = false
    
end

function AcidSpray:OnHolster(player)

    Ability.OnHolster(self, player)
    
    self.primaryAttacking = false
    
end

function AcidSpray:GetEnergyCost()
    return kAcidSprayEnergyCost
end

function AcidSpray:GetSecondaryTechId()
    return kTechId.Rappel
end

function AcidSpray:OnUpdateAnimationInput(modelMixin)

    PROFILE("AcidSpray:OnUpdateAnimationInput")


    modelMixin:SetAnimationInput("ability", "parasite")
    
    local activityString = (self.primaryAttacking and "primary") or "none"
    modelMixin:SetAnimationInput("activity", activityString)
    
    --[[local player = self:GetParent()
    if player then
        
        local viewmodel = player:GetViewModelEntity()
        if viewmodel  then
            viewmodel:SetIsVisible(false)
        end
    end--]]
    
end

function AcidSpray:GetDeathIconIndex()
    return kDeathMessageIcon.AcidSpray
end

Shared.LinkClassToMap("AcidSpray", AcidSpray.kMapName, networkVars)