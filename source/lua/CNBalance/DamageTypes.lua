-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\DamageTypes.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
--    Contains all rules regarding damage types. New types behavior can be defined BuildDamageTypeRules().
--
--    Important callbacks for classes:
--
--    ComputeDamageAttackerOverride(attacker, damage, damageType)
--    ComputeDamageAttackerOverrideMixin(attacker, damage, damageType)
--
--    for target:
--    ComputeDamageOverride(attacker, damage, damageType)
--    ComputeDamageOverrideMixin(attacker, damage, damageType)
--    GetArmorUseFractionOverride(damageType, armorFractionUsed)
--    GetReceivesStructuralDamage(damageType)
--    GetReceivesBiologicalDamage(damageType)
--    GetHealthPerArmorOverride(damageType, healthPerArmor)
--
--
--
-- Damage types
--
-- In NS2 - Keep simple and mostly in regard to armor and non-armor. Can't see armor, but players
-- and structures spawn with an intuitive amount of armor.
-- http://www.unknownworlds.com/ns2/news/2010/6/damage_types_in_ns2
--
-- Normal - Regular damage
-- Light - Reduced vs. armor
-- Heavy - Extra damage vs. armor
-- Puncture - Extra vs. players
-- Structural - Double against structures
-- GrenadeLauncher - Double against structures with 20% reduction in player damage
-- Gas - Breathing targets only (Spores, Nerve Gas GL). Ignores armor.
-- StructuresOnly - Doesn't damage players or AI units (ARC)
-- Falling - Ignores armor for humans, no damage for some creatures or exosuit
-- Door - Like Structural but also does damage to Doors. Nothing else damages Doors.
-- Flame - Like Structural but catches target on fire and plays special flinch animation
-- Corrode - deals normal damage to structures but armor only to non structures
-- ArmorOnly - always affects only armor
-- Biological - only organic, biological targets (non mechanical)
-- StructuresOnlyLight - Light damage vs. structures with armor, normal damage otherwise
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================


--globals for balance-extension tweaking
kAlienVampirismNotHealArmor = false

-- utility functions

function GetReceivesStructuralDamage(entity)
    return entity.GetReceivesStructuralDamage and entity:GetReceivesStructuralDamage()
end

function GetReceivesBiologicalDamage(entity)
    return entity.GetReceivesBiologicalDamage and entity:GetReceivesBiologicalDamage()
end

local upgradedDamageScalars
function NS2Gamerules_GetUpgradedDamageScalar( attacker, weaponTechId )

    -- kTechId gets loaded after this, and i don't want to load it. :T
    if not upgradedDamageScalars then

        upgradedDamageScalars =
        {
            [kTechId.Shotgun]         = { kShotgunWeapons1DamageScalar,         kShotgunWeapons2DamageScalar,         kShotgunWeapons3DamageScalar },
            [kTechId.GrenadeLauncher] = { kGrenadeLauncherWeapons1DamageScalar, kGrenadeLauncherWeapons2DamageScalar, kGrenadeLauncherWeapons3DamageScalar },
            [kTechId.Flamethrower]    = { kFlamethrowerWeapons1DamageScalar,    kFlamethrowerWeapons2DamageScalar,    kFlamethrowerWeapons3DamageScalar },
            ["Default"]               = { kWeapons1DamageScalar,                kWeapons2DamageScalar,                kWeapons3DamageScalar },
        }

    end

    local upgradeScalars = upgradedDamageScalars["Default"]
    if upgradedDamageScalars[weaponTechId] then
        upgradeScalars = upgradedDamageScalars[weaponTechId]
    end

    if GetHasTech(attacker, kTechId.Weapons3, true) then
        return upgradeScalars[3]
    elseif GetHasTech(attacker, kTechId.Weapons2, true) then
        return upgradeScalars[2]
    elseif GetHasTech(attacker, kTechId.Weapons1, true) then
        return upgradeScalars[1]
    end

    return 1.0

end

-- Use this function to change damage according to current upgrades
function NS2Gamerules_GetUpgradedDamage(attacker, doer, damage)

    local damageScalar = 1

    if attacker ~= nil then

        -- Damage upgrades only affect weapons, not ARCs, Sentries, MACs, Mines, etc.
        if doer.GetIsAffectedByWeaponUpgrades and doer:GetIsAffectedByWeaponUpgrades() then
            damageScalar = NS2Gamerules_GetUpgradedDamageScalar( attacker, ConditionalValue(HasMixin(doer, "Tech"), doer:GetTechId(), kTechId.None) )
        end

    end

    return damage * damageScalar

end

--Utility function to apply chamber-upgraded modifications to alien damage
--Note: this should _always_ be called BEFORE damage-type specific modifications are done (i.e. Light vs Normal vs Structural, etc)
function NS2Gamerules_GetUpgradedAlienDamage( target, attacker, doer, damage, armorFractionUsed, _, damageType )

    if not doer then return damage, armorFractionUsed end

    local isAffectedByCrush = doer.GetIsAffectedByCrush and attacker:GetHasUpgrade( kTechId.Crush ) and doer:GetIsAffectedByCrush()
    local isAffectedByVampirism = doer.GetVampiricLeechScalar and attacker:GetHasUpgrade( kTechId.Vampirism )
    local isAffectedByFocus = doer.GetIsAffectedByFocus and attacker:GetHasUpgrade( kTechId.Focus ) and doer:GetIsAffectedByFocus()

    if isAffectedByCrush then --Crush
        local crushLevel = attacker:GetSpurLevel()
        if crushLevel > 0 then
            if target:isa("Exo") or target:isa("Exosuit") or target.GetReceivesStructuralDamage and target:GetReceivesStructuralDamage(damageType) then
                damage = damage + ( damage * ( crushLevel * kAlienCrushDamagePercentByLevel ) )
            elseif target:isa("Player") then
                armorFractionUsed = kBaseArmorUseFraction + ( crushLevel * kAlienCrushDamagePercentByLevel )
            end
        end
        
    end
    
    if Server then

        -- Vampirism
        local targetValidForVamp = true
        if target.GetCanVampirismBeUsedOn then
            targetValidForVamp = target:GetCanVampirismBeUsedOn()
        end
        
        if isAffectedByVampirism and targetValidForVamp then
            local vampirismLevel = attacker:GetShellLevel()
            if vampirismLevel > 0 then
                if attacker:GetIsHealable() and target:isa("Player") then
                    local scalar = doer:GetVampiricLeechScalar()
                    if scalar > 0 then

                        local focusBonus = 1
                        if isAffectedByFocus then
                            focusBonus = 1 + doer:GetFocusAttackCooldown()
                        end

                        local maxHealth = attacker:GetMaxHealth()
                        local leechedHealth =  maxHealth * vampirismLevel * scalar * focusBonus

                        attacker:AddOverShield(leechedHealth)

                    end
                end
            end
        end
        
    end

    --Focus
    if isAffectedByFocus then
        local veilLevel = attacker:GetVeilLevel()
        local damageBonus = doer:GetMaxFocusBonusDamage()
        damage = damage * (1 + (veilLevel/3) * damageBonus) --1.0, 1.333, 1.666, 2
    end
    
    --!!!Note: if more than damage and armor fraction modified, be certain the calling-point of this function is updated
    return damage, armorFractionUsed
    
end

function Gamerules_GetDamageMultiplier()

    if Server and Shared.GetCheatsEnabled() then
        return GetGamerules():GetDamageMultiplier()
    end

    return 1
    
end

kDamageType = enum( 
{
    'Normal', 'Light', 'Heavy', 'Puncture', 
    'Structural', 'StructuralHeavy', 'Splash', 
    'Gas', 'NerveGas', 'StructuresOnly', 
    'Falling', 'Door', 'Flame',
    'Corrode', 'ArmorOnly', 'Biological', 'StructuresOnlyLight', 
    'Spreading', 'GrenadeLauncher', 'MachineGun', 'ClusterFlame',
    'ClusterFlameFragment',
    'Exosuit',
})

kDamageTriggerTypes = enum(
{
    'Normal', 'Gas', 'Fire'
})

-- Describe damage types for tooltips
kDamageTypeDesc = {
    "",
    "Light: reduced vs. armor",
    "Heavy: extra vs. armor",
    "Puncture: extra vs. players",
    "Structural: Double vs. structures",
    "StructuralHeavy: Double vs. structures and double vs. armor",
    "Gas damage: affects breathing targets only",
    "NerveGas: affects biological units, player will take only armor damage",
    "Structures only: Doesn't damage players or AI units",
    "Falling: Ignores armor for humans, no damage for aliens",
    "Door: Can also affect Doors",
    "Flame: Deals 4.5x damage vs. flammable structures and double vs. all other structures",
    "Corrode damage: Damage structures or armor only for non structures",
    "Armor damage: Will never reduce health",
    "Biological: Will only damage biological targets.",
    "StructuresOnlyLight: reduced vs. structures with armor",
    "Spreading: Does less damage against small targets.",
    "GrenadeLauncher: Double structure damage, 20% reduction in player damage",
    "MachineGun: Deals 1.5x amount of base damage vs. players",
    "ClusterFlame: Deals 5x damage vs. flammable structures and 2.5x vs. all other structures, 50% reduction in player damage",
    "Exosuit:1.5xstructure damage"
}

kSpreadingDamageScalar = 0.75

kBaseArmorUseFraction = 0.7
kExosuitArmorUseFraction = 1 -- exos have no health
kStructuralDamageScalar = 2
kPuncturePlayerDamageScalar = 2
kGLPlayerDamageReduction = 0.8

kLightHealthPerArmor = 4
kHealthPointsPerArmor = 2
kHeavyHealthPerArmor = 1

kFlameableMultiplier = 2.5
kCorrodeDamagePlayerArmorScalar = 0.12
kCorrodeDamageExoArmorScalar = 0.4

kStructureLightHealthPerArmor = 9
kStructureLightArmorUseFraction = 0.9

-- deal only 33% of damage to friendlies
kFriendlyFireScalar = 0.33


local function ApplyDefaultArmorUseFraction(_, _, _, damage, _, healthPerArmor, _, _, _, overshieldDamage)
    return damage, kBaseArmorUseFraction, healthPerArmor, overshieldDamage
end

local function ApplyHighArmorUseFractionForExos(target, _, _, damage, armorFractionUsed, healthPerArmor, _, _, _, overshieldDamage)
    
    if target:isa("Exo") then
        armorFractionUsed = kExosuitArmorUseFraction
    end
    
    return damage, armorFractionUsed, healthPerArmor, overshieldDamage
    
end

local function ApplyDefaultHealthPerArmor(_, _, _, damage, armorFractionUsed, _, _, _, _, overshieldDamage)
    return damage, armorFractionUsed, kHealthPointsPerArmor, overshieldDamage
end

local function DoubleHealthPerArmor(_, _, _, damage, armorFractionUsed, healthPerArmor)
    return damage, armorFractionUsed, healthPerArmor * (kLightHealthPerArmor / kHealthPointsPerArmor)
end

local function HalfHealthPerArmor(_, _, _, damage, armorFractionUsed, healthPerArmor)
    return damage, armorFractionUsed, healthPerArmor * (kHeavyHealthPerArmor / kHealthPointsPerArmor)
end

local function ApplyAttackerModifiers(_, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint, _, overshieldDamage)

    damage = NS2Gamerules_GetUpgradedDamage(attacker, doer, damage, damageType, hitPoint)
    damage = damage * Gamerules_GetDamageMultiplier()
    
    if attacker and attacker.ComputeDamageAttackerOverride then
        damage, overshieldDamage = attacker:ComputeDamageAttackerOverride(attacker, damage, damageType, doer, hitPoint, overshieldDamage)
    end
    
    if doer and doer.ComputeDamageAttackerOverride then
        damage, overshieldDamage = doer:ComputeDamageAttackerOverride(attacker, damage, damageType, doer, hitPoint, overshieldDamage)
    end
    
    if attacker and attacker.ComputeDamageAttackerOverrideMixin then
        damage, overshieldDamage = attacker:ComputeDamageAttackerOverrideMixin(attacker, damage, damageType, doer, hitPoint, overshieldDamage)
    end
    
    if doer and doer.ComputeDamageAttackerOverrideMixin then
        damage, overshieldDamage = doer:ComputeDamageAttackerOverrideMixin(attacker, damage, damageType, doer, hitPoint, overshieldDamage)
    end
    
    return damage, armorFractionUsed, healthPerArmor, overshieldDamage

end

local function ApplyTargetModifiers(target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint, weapon, overshieldDamage)

    -- The host can provide an override for this function.
    if target.ComputeDamageOverride then
        damage, overshieldDamage = target:ComputeDamageOverride(attacker, damage, damageType, hitPoint, overshieldDamage)
    end

    -- Used by mixins.
    if target.ComputeDamageOverrideMixin then
        damage, overshieldDamage = target:ComputeDamageOverrideMixin(attacker, damage, damageType, hitPoint, overshieldDamage)
    end

    if target.ShieldComputeDamageOverrideMixin then
        damage, overshieldDamage = target:ShieldComputeDamageOverrideMixin(attacker, damage, damageType, hitPoint, overshieldDamage)
    end
    
    if target.GetArmorUseFractionOverride then
        armorFractionUsed = target:GetArmorUseFractionOverride(damageType, armorFractionUsed, hitPoint)
    end
    
    if target.GetHealthPerArmorOverride then
        healthPerArmor = target:GetHealthPerArmorOverride(damageType, healthPerArmor, hitPoint)
    end
    
    local damageTable = {}
    damageTable.damage = damage
    damageTable.armorFractionUsed = armorFractionUsed
    damageTable.healthPerArmor = healthPerArmor
    
    if target.ModifyDamageTaken then
        target:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint, weapon)
    end
    
    return damageTable.damage, damageTable.armorFractionUsed, damageTable.healthPerArmor, overshieldDamage

end

local function ApplyFriendlyFireModifier(target, attacker, _, damage, armorFractionUsed, healthPerArmor, _, _, _, overshieldDamage)

    if target and attacker and target ~= attacker and HasMixin(target, "Team") and HasMixin(attacker, "Team") and target:GetTeamNumber() == attacker:GetTeamNumber() then
        damage = damage * kFriendlyFireScalar
    end
    
    return damage, armorFractionUsed, healthPerArmor, overshieldDamage
end

local function IgnoreArmor(_, _, _, damage, _, healthPerArmor)
    return damage, 0, healthPerArmor
end

local function MultiplyForStructures(target, _, _, damage, armorFractionUsed, healthPerArmor, damageType)

    if target.GetReceivesStructuralDamage and target:GetReceivesStructuralDamage(damageType) then
        damage = damage * kStructuralDamageScalar
    end
    
    return damage, armorFractionUsed, healthPerArmor
end

local function MultiplyForPlayers(target, _, _, damage, armorFractionUsed, healthPerArmor)
    return ConditionalValue(target:isa("Player") or target:isa("Exosuit"), damage * kPuncturePlayerDamageScalar, damage), armorFractionUsed, healthPerArmor
end

local function ReducedDamageAgainstSmall(target, _, _, damage, armorFractionUsed, healthPerArmor)

    if target.GetIsSmallTarget and target:GetIsSmallTarget() then
        damage = damage * kSpreadingDamageScalar
    end

    return damage, armorFractionUsed, healthPerArmor
end

local function IgnoreHealthForPlayersUnlessExo(target, _, _, damage, armorFractionUsed, healthPerArmor)
    if target:isa("Player") and not target:isa("Exo") then
        local maxDamagePossible = healthPerArmor * target.armor
        damage = math.min(damage, maxDamagePossible) 
        armorFractionUsed = 1
    end
    
    return damage, armorFractionUsed, healthPerArmor
end

local function IgnoreHealth(target, _, _, damage, _, healthPerArmor)
    local maxDamagePossible = healthPerArmor * target.armor
    damage = math.min(damage, maxDamagePossible)

    return damage, 1, healthPerArmor
end

local function ReduceGreatlyForPlayers(target, _, _, damage, armorFractionUsed, healthPerArmor)
    if target:isa("Exo") or target:isa("Exosuit") then
        damage = damage * kCorrodeDamageExoArmorScalar
    elseif target:isa("Player") then
        damage = damage * kCorrodeDamagePlayerArmorScalar
    end
    return damage, armorFractionUsed, healthPerArmor
end

local function DamageAlienOnly(target, _, _, damage, armorFractionUsed, healthPerArmor)
    return ConditionalValue(HasMixin(target, "Team") and target:GetTeamType() == kAlienTeamType, damage, 0), armorFractionUsed, healthPerArmor
end

local function DamageStructuresOnly(target, _, _, damage, armorFractionUsed, healthPerArmor, damageType)
    if not target.GetReceivesStructuralDamage or not target:GetReceivesStructuralDamage(damageType) then
        damage = 0
    end
    
    return damage, armorFractionUsed, healthPerArmor
end

local function DamageBiologicalOnly(target, _, _, damage, armorFractionUsed, healthPerArmor, damageType)
    if not target.GetReceivesBiologicalDamage or not target:GetReceivesBiologicalDamage(damageType) then
        damage = 0
    end
    
    return damage, armorFractionUsed, healthPerArmor
end

local function DamageBreathingOnly(target, _, _, damage, armorFractionUsed, healthPerArmor, damageType)
    if not target.GetReceivesVaporousDamage or not target:GetReceivesVaporousDamage(damageType) then
        damage = 0
    end
    
    return damage, armorFractionUsed, healthPerArmor
end

local function MultiplyFlameAble(target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType)
    if target.GetIsFlameAble and target:GetIsFlameAble(damageType) then
        local multi = kFlameableMultiplier
        if target.GetIsFlameableMultiplier then
            multi = target:GetIsFlameableMultiplier()
        end

        damage = damage * multi
    end
    
    return damage, armorFractionUsed, healthPerArmor
end

--Note: This actually splits health and armor 9 to 1
local function DoubleHealthPerArmorForStructures(target, _, _, damage, armorFractionUsed, healthPerArmor, damageType)
    if target.GetReceivesStructuralDamage and target:GetReceivesStructuralDamage(damageType) then
        healthPerArmor = healthPerArmor * (kStructureLightHealthPerArmor / kHealthPointsPerArmor)
        armorFractionUsed = kStructureLightArmorUseFraction
    end
    return damage, armorFractionUsed, healthPerArmor
end

local kMachineGunPlayerDamageScalar = 1.5
local function MultiplyForMachineGun(target, _, _, damage, armorFractionUsed, healthPerArmor)
    return ConditionalValue(target:isa("Player") or target:isa("Exosuit"), damage * kMachineGunPlayerDamageScalar, damage), armorFractionUsed, healthPerArmor
end

local kGLStructuralDamageScalar = 3
local function GrenadeLauncherForStructure(target, _, _, damage, armorFractionUsed, healthPerArmor, damageType)

    if target.GetReceivesStructuralDamage and target:GetReceivesStructuralDamage(damageType) then
        damage = damage * kGLStructuralDamageScalar
    end

    return damage, armorFractionUsed, healthPerArmor
end

local kExosuitDamageScarlar = 1.5
local function ExosuitForStructure(target, _, _, damage, armorFractionUsed, healthPerArmor, damageType)

    if target.GetReceivesStructuralDamage and target:GetReceivesStructuralDamage(damageType) then
        damage = damage * kExosuitDamageScarlar
    end

    return damage, armorFractionUsed, healthPerArmor
end
----
local kClusterStructuralDamageScalar = 3.2  -- 2.5
local kClusterPlayerDamageScalar = 0.5 -- 0.2
----
local function ClusterFlameModifier(target, _, _, damage, armorFractionUsed, healthPerArmor, damageType)
    if target:isa("Player") then
        damage = damage * kClusterPlayerDamageScalar
    else
        if target.GetReceivesStructuralDamage and target:GetReceivesStructuralDamage(damageType) then
            damage = damage * kClusterStructuralDamageScalar
        end

        if target.GetIsFlameAble and target:GetIsFlameAble(damageType) then -- GetIsFlameAble is only used for structures at the moment.

            -- If damage is <= 0 (friendly fire), also disable fire damage.
            local wouldBeFireDamage = ConditionalValue(damage <= 0, 0, kBurnDamagePerSecond * kFlamethrowerBurnDuration)

            local multi = kFlameableMultiplier
            if target.GetIsFlameableMultiplier then
                multi = target:GetIsFlameableMultiplier()
            end

            damage = damage + (wouldBeFireDamage * multi)
        end
    end

    return damage, armorFractionUsed, healthPerArmor
end

local function ClusterFlameFragmentModifier(target, _, _, damage, armorFractionUsed, healthPerArmor, damageType)
    if target:isa("Player") then
        damage = damage * kClusterPlayerDamageScalar
    else
        if target.GetReceivesStructuralDamage and target:GetReceivesStructuralDamage(damageType) then
            damage = damage * kClusterStructuralDamageScalar
        end
    end

    return damage, armorFractionUsed, healthPerArmor
end

kDamageTypeGlobalRules = nil
kDamageTypeRules = nil

--[[
 * Define any new damage type behavior in this function
 --]]
local function BuildDamageTypeRules()

    -- global rules
    kDamageTypeGlobalRules = {
        ApplyDefaultArmorUseFraction,
        ApplyHighArmorUseFractionForExos,
        ApplyDefaultHealthPerArmor,
        ApplyAttackerModifiers,
        ApplyTargetModifiers,
        ApplyFriendlyFireModifier,
    }
    -- ------------------------------

    kDamageTypeRules = {}
    
    -- normal damage rules
    kDamageTypeRules[kDamageType.Normal] = {}
    
    -- light damage rules
    kDamageTypeRules[kDamageType.Light] = {
        DoubleHealthPerArmor
    }
    -- ------------------------------
    
    -- heavy damage rules
    kDamageTypeRules[kDamageType.Heavy] = {
        HalfHealthPerArmor
    }
    -- ------------------------------

    -- Puncture damage rules
    kDamageTypeRules[kDamageType.Puncture] = {
        MultiplyForPlayers
    }
    -- ------------------------------
    
    -- Spreading damage rules
    kDamageTypeRules[kDamageType.Spreading] = {
        ReducedDamageAgainstSmall
    }
    -- ------------------------------

    -- structural rules
    kDamageTypeRules[kDamageType.Structural] = {
        MultiplyForStructures
    }
    -- ------------------------------
    
    -- Grenade Launcher rules
    kDamageTypeRules[kDamageType.GrenadeLauncher] = {
        GrenadeLauncherForStructure
    }
    -- ------------------------------

    kDamageTypeRules[kDamageType.Exosuit] = {
        ExosuitForStructure
    }
    -- Machine Gun rules
    kDamageTypeRules[kDamageType.MachineGun] = {
        MultiplyForMachineGun
    }
    -- ------------------------------
    
    -- structural heavy rules
    kDamageTypeRules[kDamageType.StructuralHeavy] = {
        HalfHealthPerArmor,
        MultiplyForStructures
    }
    -- ------------------------------
    
    -- gas damage rules
    kDamageTypeRules[kDamageType.Gas] = {
        IgnoreArmor,
        DamageBreathingOnly
    }
    -- ------------------------------
   
    -- structures only rules
    kDamageTypeRules[kDamageType.StructuresOnly] = {
        DamageStructuresOnly
    }
    -- ------------------------------
    
     -- Splash rules
    kDamageTypeRules[kDamageType.Splash] = {
        DamageStructuresOnly
    }
    -- ------------------------------
 
    -- fall damage rules
    kDamageTypeRules[kDamageType.Falling] = {
        IgnoreArmor
    }
    -- ------------------------------

    -- Door damage rules
    kDamageTypeRules[kDamageType.Door] = {
        MultiplyForStructures,
        HalfHealthPerArmor
    }
    -- ------------------------------
    
    -- Flame damage rules
    kDamageTypeRules[kDamageType.Flame] = {
        MultiplyFlameAble,
        MultiplyForStructures
    }
    -- ------------------------------

    -- ClusterFlame damage rules
    kDamageTypeRules[kDamageType.ClusterFlame] = {
        ClusterFlameModifier
    }
    -- ------------------------------

    -- ClusterFlameFragment damage rules
    kDamageTypeRules[kDamageType.ClusterFlameFragment] = {
        ClusterFlameFragmentModifier
    }
    -- ------------------------------
    
    -- Corrode damage rules
    kDamageTypeRules[kDamageType.Corrode] = {
        ReduceGreatlyForPlayers,
        IgnoreHealthForPlayersUnlessExo,
    }
    -- ------------------------------
    
    -- nerve gas rules
    kDamageTypeRules[kDamageType.NerveGas] = {
        DamageAlienOnly,
        IgnoreHealth,
    }
    -- ------------------------------
    
    -- StructuresOnlyLight damage rules
    kDamageTypeRules[kDamageType.StructuresOnlyLight] = {
        DoubleHealthPerArmorForStructures
    }
    -- ------------------------------
    
    -- ArmorOnly damage rules
    kDamageTypeRules[kDamageType.ArmorOnly] = {
        IgnoreHealth
    }
    -- ------------------------------
    
    -- Biological damage rules
    kDamageTypeRules[kDamageType.Biological] = {
        DamageBiologicalOnly
    }
    -- ------------------------------
    
end

-- applies all rules and returns damage, armorUsed, healthUsed
function GetDamageByType(target, attacker, doer, damage, damageType, hitPoint, weapon)

    assert(target)
    
    if not kDamageTypeGlobalRules or not kDamageTypeRules then
        BuildDamageTypeRules()
    end
    
    -- at first check if damage is possible, if not we can skip the rest
    if not CanEntityDoDamageTo(attacker, target, Shared.GetCheatsEnabled(), Shared.GetDevMode(), GetFriendlyFire(), damageType) then
        return 0, 0, 0, 0
    end
    
    local armorUsed = 0
    local healthUsed = 0
    
    local armorFractionUsed = 0
    local healthPerArmor = 0
    local overshieldDamage = 0
    
    -- apply global rules at first
    for _, rule in ipairs(kDamageTypeGlobalRules) do
        damage, armorFractionUsed, healthPerArmor, overshieldDamage = rule(target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint, weapon, overshieldDamage)
    end
    
    --Account for Alien Chamber Upgrades damage modifications (must be before damage-type rules)
    if attacker:GetTeamType() == kAlienTeamType and attacker:isa("Player") then
        damage, armorFractionUsed = NS2Gamerules_GetUpgradedAlienDamage( target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint, weapon )
    end
    
    -- apply damage type specific rules
    for _, rule in ipairs(kDamageTypeRules[damageType]) do
        damage, armorFractionUsed, healthPerArmor = rule(target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint)
    end
    
    if damage > 0 and healthPerArmor > 0 then

        -- Each point of armor blocks a point of health but is only destroyed at half that rate (like NS1)
        -- Thanks Harimau!
        local healthPointsBlocked = math.min(healthPerArmor * target.armor, armorFractionUsed * damage)
        armorUsed = healthPointsBlocked / healthPerArmor
        
        -- Anything left over comes off of health
        healthUsed = damage - healthPointsBlocked

    end
    
    return damage, armorUsed, healthUsed, overshieldDamage

end
