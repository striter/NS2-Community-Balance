local oldBuildClassToGrid = BuildClassToGrid
function BuildClassToGrid()

    local ClassToGrid = oldBuildClassToGrid()
    
	ClassToGrid["DevouredPlayer"] = { 5, 3 }
    ClassToGrid["Prowler"] = { 6, 3 }
    
    return ClassToGrid
    
end

local loadAdditional = true
local oldGetTexCoordsForTechId = GetTexCoordsForTechId
function GetTexCoordsForTechId(techId)
	if loadAdditional and gTechIdPosition then
		gTechIdPosition[kTechId.Devour] = kDeathMessageIcon.Devour
		gTechIdPosition[kTechId.Volley] = kDeathMessageIcon.Spikes
        gTechIdPosition[kTechId.AcidSpray] = kDeathMessageIcon.Spray
        gTechIdPosition[kTechId.Rappel] = kDeathMessageIcon.Claw
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