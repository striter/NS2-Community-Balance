Script.Load("lua/Marine.lua")
Script.Load("lua/Combat/Heavy.lua")

class 'HeavyMarine' (Marine)

HeavyMarine.kMapName = "heavymarine"

HeavyMarine.kModelName = PrecacheAsset("models/marine/male/male.model")

HeavyMarine.kHealth = 240
HeavyMarine.kBaseArmor = 150

HeavyMarine.kSpeed = 0.8
HeavyMarine.kScale = 1.2
HeavyMarine.kHealth = kHeavyMarineHealth
HeavyMarine.kBaseArmor = kHeavyMarineArmor
HeavyMarine.kArmorPerUpgradeLevel = kHeavyMarineArmorPerUpgradeLevel

function HeavyMarine:GetArmorAmount(armorLevels)

    if not armorLevels then
    
        armorLevels = 0
    
        if GetHasTech(self, kTechId.Armor3, true) then
            armorLevels = 3
        elseif GetHasTech(self, kTechId.Armor2, true) then
            armorLevels = 2
        elseif GetHasTech(self, kTechId.Armor1, true) then
            armorLevels = 1
        end
    
    end
    
    return HeavyMarine.kBaseArmor + armorLevels * HeavyMarine.kArmorPerUpgradeLevel
end


function HeavyMarine:GetMaxSpeed(possible)
    return Marine.GetMaxSpeed(self,possible)*HeavyMarine.kSpeed
end

function HeavyMarine:GetMaxViewOffsetHeight()
    return Player.GetMaxViewOffsetHeight(self)*HeavyMarine.kScale
end

function HeavyMarine:GetCanJump()
    return false
end

function HeavyMarine:GetVariant()
    return 1
end

function HeavyMarine:OnAdjustModelCoords(coords)
    coords.xAxis = coords.xAxis * HeavyMarine.kScale
    coords.yAxis = coords.yAxis * HeavyMarine.kScale
    coords.zAxis = coords.zAxis * HeavyMarine.kScale
    return coords
end

Shared.LinkClassToMap("HeavyMarine", HeavyMarine.kMapName, networkVars, true)
