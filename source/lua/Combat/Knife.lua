Script.Load("lua/Weapons/Weapon.lua")

class 'Knife' (Weapon)

Knife.kMapName = "knife"

Knife.kModelName = PrecacheAsset("models/marine/knife/knife.model")
Knife.kViewModelName = PrecacheAsset("models/marine/knife/knife_view.model")
local kAnimationGraph = PrecacheAsset("models/marine/axe/axe_view.animation_graph")

local networkVars =
{
    sprintAllowed = "boolean",
}

function Knife:OnCreate()

    Weapon.OnCreate(self)
    
    self.sprintAllowed = true
    
end

function Knife:OnInitialized()

    Weapon.OnInitialized(self)
    
    self:SetModel(Knife.kModelName)
    
end

function Knife:GetViewModelName(sex, variant)
    return Knife.kViewModelName
end

function Knife:GetAnimationGraphName()
    return kAnimationGraph
end

function Knife:GetHUDSlot()
    return kTertiaryWeaponSlot
end

function Knife:GetRange()
    return kKnifeRange
end

function Knife:GetShowDamageIndicator()
    return true
end

function Knife:GetSprintAllowed()
    return self.sprintAllowed
end

function Knife:GetDeathIconIndex()
    return kDeathMessageIcon.Knife
end

function Knife:OnDraw(player, previousWeaponMapName)

    Weapon.OnDraw(self, player, previousWeaponMapName)
    
    self:SetAttachPoint(Weapon.kHumanAttachPoint)
end

function Knife:OnHolster(player)

    Weapon.OnHolster(self, player)
    
    self.sprintAllowed = true
    self.primaryAttacking = false
    
end

function Knife:OnPrimaryAttack(player)

    if not self.attacking then
        
        self.sprintAllowed = false
        self.primaryAttacking = true
        
    end

end

function Knife:OnPrimaryAttackEnd(player)
    self.primaryAttacking = false
end


function Knife:Knife_HitCheck(coords, player)

    local boxTrace = Shared.TraceBox(Vector(0.07,0.07,0.07),
                                     player:GetEyePos(),
                                     player:GetEyePos() + coords.zAxis * (0.50 + self:GetRange()),
                                     CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls,
                                     EntityFilterTwo(player, self))
    -- Log("Boxtrace entity: %s, target: %s", boxTrace.entity, target)
    if boxTrace.entity and boxTrace.entity:isa("Web") then
        self:DoDamage(kKnifeDamage, boxTrace.entity, boxTrace.endPoint, coords.zAxis, "organic", false)
    else
        -- local rayTrace = Shared.TraceRay(eyePos, targetOrigin, CollisionRep.LOS, PhysicsMask.All, EntityFilterAll())
        local rayTrace = Shared.TraceRay(player:GetEyePos(), player:GetEyePos() + coords.zAxis * (0.50 + self:GetRange()), CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
        -- Log("Raytrace entity: %s", rayTrace.entity)
        if rayTrace.entity and rayTrace.entity:isa("Web") then
            self:DoDamage(kKnifeDamage, boxTrace.entity, boxTrace.endPoint, coords.zAxis, "organic", false)
        end
    end

end

function Knife:OnTag(tagName)
	
	if tagName == "swipe_sound" then
        local player = self:GetParent()
        if player then
            player:TriggerEffects("knife_attack")
        end
    elseif tagName == "hit" then
    
        local player = self:GetParent()
        local coords = player:GetViewAngles():GetCoords()
        local didHit, target = AttackMeleeCapsule(self, player, kKnifeDamage, self:GetRange())

        if not (didHit and target) and coords then -- Only for webs
            self:Knife_HitCheck(coords, player)
        end
        
    elseif tagName == "attack_end" then
        self.sprintAllowed = true
    end
	
end

function Knife:OverrideWeaponName()
    return "axe"
end

function Knife:OnUpdateAnimationInput(modelMixin)

    PROFILE("Knife:OnUpdateAnimationInput")

    local activity = "none"
    if self.primaryAttacking then
        activity = "primary"
    end
    modelMixin:SetAnimationInput("activity", activity)
    
end

function Knife:GetCatalystSpeedBase()
    return 1
end

Shared.LinkClassToMap("Knife", Knife.kMapName, networkVars)