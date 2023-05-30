-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Alien\BoneShield.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
--    Puts the onos in a defensive, slow moving position where it uses energy to absorb damage.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/StompMixin.lua")

class 'BoneShield' (Ability)

BoneShield.kMapName = "boneshield"

local kAnimationGraph = PrecacheAsset("models/alien/onos/onos_view.animation_graph")

local networkVars =
{
    lastShieldTime = "private time",
    timeFuelChanged = "private time",
    fuelAtChange = "private float (0 to 1 by 0.01)",
}

AddMixinNetworkVars(StompMixin, networkVars)

function BoneShield:OnCreate()

    Ability.OnCreate(self)
    
    InitMixin(self, StompMixin)

    self.lastShieldTime = 0
    self.timeFuelChanged = 0
    self.fuelAtChange = 1

end

function BoneShield:GetEnergyCost()
    return kBoneShieldMinimumEnergyNeeded
end

function BoneShield:SetFuel(fuel)
    self.timeFuelChanged = Shared.GetTime()
    self.fuelAtChange = fuel
end

function BoneShield:GetFuel()
    
    if self.primaryAttacking then
        return Clamp(self.fuelAtChange - (Shared.GetTime() - self.timeFuelChanged) / kBoneShieldMaxDuration, 0, 1)
    else
        return Clamp(self.fuelAtChange + (Shared.GetTime() - self.timeFuelChanged) / kBoneShieldCooldown, 0, 1)
    end
end

function BoneShield:GetAnimationGraphName()
    return kAnimationGraph
end

function BoneShield:GetHUDSlot()
    return 2
end

function BoneShield:GetCooldownFraction()
    local fuelFraction = 1 - self:GetFuel()

    local player = self:GetParent()
    local canUse = player and self:GetCanUseBoneShield(self:GetParent())
    return canUse and fuelFraction or 1
end

function BoneShield:IsOnCooldown()
    return self:GetFuel() < kBoneShieldMinimumFuel
end

function BoneShield:GetCanUseBoneShield(player)
    local canUse = not self:IsOnCooldown()
            and player:GetIsOnGround()
            and not self.secondaryAttacking
            and not player.charging and Shared.GetTime() - self.lastShieldTime > .5
    local devourWeapon = player:GetWeapon(Devour.kMapName)
    if devourWeapon then
        local devouring = devourWeapon.devouringScalar and devourWeapon.devouringScalar > 0.01
        canUse = canUse and not devouring
    end
    return canUse
end

function BoneShield:OnPrimaryAttack(player)
    if not self.primaryAttacking then
        if self:GetCanUseBoneShield(player) then
            self:SetFuel( self:GetFuel() ) -- set it now, because it will go down from this point
            self.primaryAttacking = true

            if Server then
                player:TriggerEffects("onos_shield_start")
            end
        end
    end
end

function BoneShield:OnPrimaryAttackEnd()

    if self.primaryAttacking then
        self:SetFuel( self:GetFuel() ) -- set it now, because it will go up from this point
        self.primaryAttacking = false
        self.lastShieldTime = Shared.GetTime()
    end

end

--Note: POSE 3P params are controlled in Onos.lua
function BoneShield:OnUpdateAnimationInput(modelMixin)

    local activityString = "none"
    local abilityString = "boneshield"
    
    if self.primaryAttacking then
        activityString = "primary"
    end
    
    modelMixin:SetAnimationInput("ability", abilityString)
    modelMixin:SetAnimationInput("activity", activityString)
    
end


function BoneShield:OnHolster(player)

    Ability.OnHolster(self, player)
    
    self:OnPrimaryAttackEnd(player)
    
end

function BoneShield:ProcessMoveOnWeapon(player, input) --FIXME This is almost certainly causing Energy bar to jitter
    if self.primaryAttacking then
        if self:GetFuel() < 0.01 and Shared.GetTime() - self.lastShieldTime > .5  or not player:GetIsAlive() then

            self:SetFuel( 0 )
            self.primaryAttacking = false
            self.lastShieldTime = Shared.GetTime()

        end

    end
end


Shared.LinkClassToMap("BoneShield", BoneShield.kMapName, networkVars)