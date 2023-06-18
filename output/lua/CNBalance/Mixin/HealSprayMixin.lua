-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Alien\HealSprayMixin.lua
--
--    Created by:   Brian Cronin (brianc@unknownworlds.com) and
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

HealSprayMixin = CreateMixin( HealSprayMixin )
HealSprayMixin.type = "HealSpray"

-- Players heal by base amount + percentage of max health
local kHealPlayerPercent = 3

local kRange = 6
local kHealCylinderWidth = 3

HealSprayMixin.kHealScoreAdded = 2
-- Every kAmountHealedForPoints points of damage healed, the player gets
-- kHealScoreAdded points to their score.
HealSprayMixin.kAmountHealedForPoints = 400

-- Whenever a maturity-using entity is healed, skip this amount of seconds of maturity gain
-- immediately.
HealSprayMixin.kMaturityTimeSkipped = 1

-- Whenever an embryo is heal-sprayed, skip this amount of seconds of evolution time.
HealSprayMixin.kEvolutionTimeAdded = 1

-- HealSprayMixin:GetHasSecondary should completely override any existing
-- GetHasSecondary function defined in the object.
HealSprayMixin.overrideFunctions =
{
    "GetHasSecondary",
    "GetSecondaryEnergyCost"
}

HealSprayMixin.networkVars =
{
    lastSecondaryAttackTime = "float"
}

function HealSprayMixin:__initmixin()
    
    PROFILE("HealSprayMixin:__initmixin")
    
    self.secondaryAttacking = false
    self.lastSecondaryAttackTime = 0
    self.lastSprayAttacked = false

end

function HealSprayMixin:GetHasSecondary()
    return true
end

function HealSprayMixin:GetSecondaryAttackDelay()
    return kHealsprayFireDelay
end

function HealSprayMixin:GetSecondaryEnergyCost()
    return kHealsprayEnergyCost
end

function HealSprayMixin:GetDeathIconIndex()
    return kDeathMessageIcon.Spray 
end

function HealSprayMixin:OnSecondaryAttack(player)

    local enoughTimePassed = (Shared.GetTime() - self.lastSecondaryAttackTime) > self:GetSecondaryAttackDelay()
    if player:GetSecondaryAttackLastFrame() and enoughTimePassed then
    
        if player:GetEnergy() >= self:GetSecondaryEnergyCost() then
        
            self.lastSprayAttacked = true
            self:PerformSecondaryAttack(player)
            
            if self.OnHealSprayTriggered then
                self:OnHealSprayTriggered()
            end
        end

    end
    
end

function HealSprayMixin:PerformSecondaryAttack()
    self.secondaryAttacking = true
end

function HealSprayMixin:OnSecondaryAttackEnd(player)

    Ability.OnSecondaryAttackEnd(self, player)
    
    self.secondaryAttacking = false

end

local function GetHealOrigin(_, player)

    -- Don't project origin the full radius out in front of Gorge or we have edge-case problems with the Gorge
    -- not being able to hear himself
    local startPos = player:GetEyePos()
    local endPos = startPos + (player:GetViewAngles():GetCoords().zAxis * kHealsprayRadius * .9)
    local trace = Shared.TraceRay(startPos, endPos, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOne(player))
    return trace.endPoint
    
end

function HealSprayMixin:GetDamageType()
    return kHealsprayDamageType
end

function HealSprayMixin:OnPrimaryAttack()
    self.lastSprayAttacked = false
end

function HealSprayMixin:GetWasSprayAttack()
    return self.lastSprayAttacked
end

local function DamageEntity(self, player, targetEntity)

    self:DoDamage(kHealsprayDamage, targetEntity, targetEntity:GetEngagementPoint(), GetNormalizedVector(targetEntity:GetOrigin(), player:GetEyePos()), "none")

end

local function HealEntity(_, player, targetEntity)
    
    -- Heal players by base amount plus a scaleable amount so it's effective vs. small and large targets.
    local health = kHealsprayDamage + targetEntity:GetMaxHealth() * kHealPlayerPercent / 100.0
    
    -- Heal structures by multiple of damage(so it doesn't take forever to heal hives, ala NS1)
    if GetReceivesStructuralDamage(targetEntity) then
        health = 60
    -- Don't heal self at full rate - don't want Gorges to be too powerful. Same as NS1.
    elseif targetEntity == player then
        health = health * 0.5
    end
    
    local amountHealed = targetEntity:AddHealth(health, true, false, false, player) --????Why was heal effect explicitly set to not show?!
    
    -- Do not count amount self healed.
    if targetEntity ~= player then
        player:AddContinuousScore("HealSpray", amountHealed, HealSprayMixin.kAmountHealedForPoints, HealSprayMixin.kHealScoreAdded)
    end
    
    if targetEntity.OnHealSpray then
        targetEntity:OnHealSpray(player)
    end
    
    -- Put out entities on fire sometimes.
    if targetEntity.PutOutFire and math.random() < kSprayDouseOnFireChance then
        targetEntity:PutOutFire()
    end
    --if HasMixin(targetEntity, "GameEffects") and math.random() < kSprayDouseOnFireChance then
    --    targetEntity:SetGameEffectMask(kGameEffect.OnFire, false)
    --end
    
    -- If the entity has maturity, take off some of the remaining maturity time.
    local shouldAddMaturity = 
        Server and 
        HasMixin(targetEntity, "Maturity") and 
        HasMixin(targetEntity, "Live") and 
        targetEntity:GetIsAlive() and 
        HasMixin(targetEntity, "Construct") and 
        targetEntity:GetIsBuilt()
        
    if shouldAddMaturity then
        targetEntity:AddMaturity(HealSprayMixin.kMaturityTimeSkipped)
    end
    
    if Server and targetEntity:isa("Embryo") then
        targetEntity:AddEvolutionTime(HealSprayMixin.kEvolutionTimeAdded)
    end
    
end

local function GetEntitiesInCylinder(_, player, viewCoords, range, width)

    -- gorge always heals itself
    local ents = { player }
    local startPoint = viewCoords.origin

    -- Pick entities a bit above the actual range to ease building and healing
    for _, entity in ipairs( GetEntitiesWithMixinWithinRange("Live", startPoint, Clamp(range + 0.25, 0, kRange)) ) do

        if entity:GetIsAlive() and not entity:isa("Weapon") and entity ~= player then

            local relativePos = entity:GetOrigin() - startPoint
            local yDistance = viewCoords.yAxis:DotProduct(relativePos)
            local xDistance = viewCoords.xAxis:DotProduct(relativePos)
            local zDistance = viewCoords.zAxis:DotProduct(relativePos)

            local xyDistance = math.sqrt(yDistance * yDistance + xDistance * xDistance)

            -- could perform a LOS check here or simply keeo the code a bit more tolerant. healspray is kinda gas and it would require complex calculations to make this check be exact
            if xyDistance <= width and zDistance >= 0 then
                if startPoint:GetDistanceTo(entity:GetOrigin()) < range or not GetWallBetween(startPoint, entity:GetOrigin(), entity)
                then
                    table.insert(ents, entity)
                end
            end

        end

    end

    return ents

end

local function GetEntitiesInCone(self, player)

    local range = 0
    
    local viewCoords = player:GetViewCoords()
    local fireDirection = viewCoords.zAxis
    
    local startPoint = viewCoords.origin
    local lineTrace0 = Shared.TraceRay(startPoint, startPoint + kRange * fireDirection, CollisionRep.LOS, PhysicsMask.Melee, EntityFilterAll())
    range = (lineTrace0.endPoint - startPoint):GetLength()

    startPoint = viewCoords.origin + viewCoords.yAxis * kHealCylinderWidth * 0.2
    local lineTrace1 = Shared.TraceRay(startPoint, startPoint + kRange * fireDirection, CollisionRep.LOS, PhysicsMask.Melee, EntityFilterAll())
    if (lineTrace1.endPoint - startPoint):GetLength() > range then
        range = (lineTrace1.endPoint - startPoint):GetLength()
    end

    startPoint = viewCoords.origin - viewCoords.yAxis * kHealCylinderWidth * 0.2
    local lineTrace2 = Shared.TraceRay(startPoint, startPoint + kRange * fireDirection, CollisionRep.LOS, PhysicsMask.Melee, EntityFilterAll())    
    if (lineTrace2.endPoint - startPoint):GetLength() > range then
        range = (lineTrace2.endPoint - startPoint):GetLength()
    end
    
    startPoint = viewCoords.origin - viewCoords.xAxis * kHealCylinderWidth * 0.2
    local lineTrace3 = Shared.TraceRay(startPoint, startPoint + kRange * fireDirection, CollisionRep.LOS, PhysicsMask.Melee, EntityFilterAll())    
    if (lineTrace3.endPoint - startPoint):GetLength() > range then
        range = (lineTrace3.endPoint - startPoint):GetLength()
    end
    
    startPoint = viewCoords.origin + viewCoords.xAxis * kHealCylinderWidth * 0.2
    local lineTrace4 = Shared.TraceRay(startPoint, startPoint + kRange * fireDirection, CollisionRep.LOS, PhysicsMask.Melee, EntityFilterAll())
    if (lineTrace4.endPoint - startPoint):GetLength() > range then
        range = (lineTrace4.endPoint - startPoint):GetLength()
    end

    -- To heal hydras placed on weird corners (distances can be just a bit further because of the corner not being aimed perfectly)
    -- if #GetEntitiesInCylinder(self, player, viewCoords, range, kHealCylinderWidth) == 1 then
    --     Log("Nothing found but the gorge itself, retrying with a slightly longer range")
    -- end
    return (GetEntitiesInCylinder(self, player, viewCoords, range, kHealCylinderWidth))

end

local function PerformHealSpray(self, player)

    for _, entity in ipairs(GetEntitiesInCone(self, player)) do
    
        if HasMixin(entity, "Team") then
        
            if entity:GetTeamNumber() == player:GetTeamNumber() then
                HealEntity(self, player, entity)
            elseif GetAreEnemies(entity, player) then
                DamageEntity(self, player, entity)
            end
            
        end
        
    end
    
end

function HealSprayMixin:OnTag(tagName)

    PROFILE("HealSprayMixin:OnTag")

    if self.secondaryAttacking and tagName == "heal" then
        
        local player = self:GetParent()
        if player and player:GetEnergy() >= self:GetSecondaryEnergyCost(player) then
        
            PerformHealSpray(self, player)            
            player:DeductAbilityEnergy(self:GetSecondaryEnergyCost(player))
            
            local effectCoords = Coords.GetLookIn(GetHealOrigin(self, player), player:GetViewCoords().zAxis)
            player:TriggerEffects("heal_spray", { effecthostcoords = effectCoords })
            
            self.lastSecondaryAttackTime = Shared.GetTime()
        
        end
    
    end
    
end

function HealSprayMixin:OnUpdateAnimationInput(modelMixin)

    PROFILE("HealSprayMixin:OnUpdateAnimationInput")

    local player = self:GetParent()
    if player and self.secondaryAttacking and player:GetEnergy() >= self:GetSecondaryEnergyCost(player) or Shared.GetTime() - self.lastSecondaryAttackTime < 0.5 then
        modelMixin:SetAnimationInput("activity", "secondary")
    end
    
end
