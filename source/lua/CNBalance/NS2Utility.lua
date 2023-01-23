local oldBuildClassToGrid = BuildClassToGrid
function BuildClassToGrid()

    local ClassToGrid = oldBuildClassToGrid()
    
	ClassToGrid["DevouredPlayer"] = { 8, 2 }
    ClassToGrid["Prowler"] = { 1, 9 }

    ClassToGrid["Vokex"] = { 8, 2 }
    ClassToGrid["WeaponCache"] = { 8, 5 }
    ClassToGrid["HeavyMarine"] = { 7, 8 }

    return ClassToGrid
    
end

local loadAdditional = true
local oldGetTexCoordsForTechId = GetTexCoordsForTechId
function GetTexCoordsForTechId(techId)
	if loadAdditional and gTechIdPosition then
		gTechIdPosition[kTechId.Volley] = kDeathMessageIcon.Volley
		gTechIdPosition[kTechId.Devour] = kDeathMessageIcon.Devour
        gTechIdPosition[kTechId.AcidSpray] = kDeathMessageIcon.AcidSpray
        gTechIdPosition[kTechId.Rappel] = kDeathMessageIcon.Rappel
        gTechIdPosition[kTechId.SwipeShadowStep] = kDeathMessageIcon.Swipe
--         gTechIdPosition[kTechId.AcidRocket] = kDeathMessageIcon.AcidRocket

		gTechIdPosition[kTechId.Revolver] = kDeathMessageIcon.Revolver
		gTechIdPosition[kTechId.SubMachineGun] = kDeathMessageIcon.SubMachineGun
		gTechIdPosition[kTechId.LightMachineGun] = kDeathMessageIcon.LightMachineGun
		gTechIdPosition[kTechId.Knife] = kDeathMessageIcon.Knife
		gTechIdPosition[kTechId.Cannon] = kDeathMessageIcon.Cannon
		gTechIdPosition[kTechId.CombatBuilder] = kDeathMessageIcon.CombatBuilder
		loadAdditional = false
	end
	return oldGetTexCoordsForTechId(techId)
end



function CanEntityDoDamageTo(attacker, target, cheats, devMode, friendlyFire, damageType)

    if not GetGameInfoEntity():GetGameStarted() and not GetWarmupActive() then
        return false
    end

    if target:isa("Clog") then
        return true
    end

    if not HasMixin(target, "Live") then
        return false
    end

    if GetWarmupActive() and not GetValidTargetInWarmUp(target) then
        return false
    end

    if target:isa("ARC") and damageType == kDamageType.Splash then
        return true
    end

    if not target:GetCanTakeDamage() then
        return false
    end

    if target:isa("DevouredPlayer") then
        return target.devouringOnosId and target.devouringOnosId == attacker:GetId()    
    end

    if target == nil or (target.GetDarwinMode and target:GetDarwinMode()) then
        return false
    elseif cheats or devMode then
        return true
    elseif attacker == nil then
        return true
    end

    -- You can always do damage to yourself.
    if attacker == target then
        return true
    end

    -- Command stations can kill even friendlies trapped inside.
    if attacker ~= nil and attacker:isa("CommandStation") then
        return true
    end

    -- Your own grenades can hurt you.
    if attacker:isa("Grenade") then

        local owner = attacker:GetOwner()
        if owner and owner:GetId() == target:GetId() then
            return true
        end

    end

    -- Same teams not allowed to hurt each other unless friendly fire enabled.
    local teamsOK = true
    if attacker ~= nil then
        teamsOK = GetAreEnemies(attacker, target) or friendlyFire
    end

    -- Allow damage of own stuff when testing.
    return teamsOK

end