local oldBuildClassToGrid = BuildClassToGrid
function BuildClassToGrid()

    local ClassToGrid = oldBuildClassToGrid()
    
	ClassToGrid["DevouredPlayer"] = { 8, 2 }
    ClassToGrid["Prowler"] = { 1, 9 }

    ClassToGrid["Vokex"] = { 8, 2 }
    ClassToGrid["WeaponCache"] = { 8, 5 }
    ClassToGrid["HeavyMarine"] = { 7, 8 }
    ClassToGrid["MarineSentry"] = { 5, 4 }

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

if Server then
    function CreateEntityForTeam(techId, position, teamNumber, player)

        local newEnt

        local mapName = LookupTechData(techId, kTechDataMapName)
        if mapName ~= nil then

            -- Allow entities to be positioned off ground (eg, hive hovers over tech point)
            local spawnHeight = LookupTechData(techId, kTechDataSpawnHeightOffset, 0)
            local spawnHeightPosition = Vector(position.x,
                    position.y + spawnHeight,
                    position.z)

            newEnt = CreateEntity( mapName, spawnHeightPosition, teamNumber )

            -- Hook it up to attach entity
            local attachEntity = GetAttachEntity(techId, position)
            if attachEntity then
                newEnt:SetAttached(attachEntity)
            end


            local layout = LookupTechData(techId, kTechDataLayoutKey)
            if layout then
                newEnt:SetLayout(layout)
            end
            
        else
            Print("CreateEntityForTeam(%s): Couldn't kTechDataMapName for entity.", EnumToString(kTechId, techId))
            assert(false)
        end

        return newEnt

    end
end


function PlayerUI_GetGameTimeString()

    local gameTime, state = PlayerUI_GetGameLengthTime()
    if state < kGameState.PreGame then
        gameTime = 0
    end

    local minutes = math.floor(gameTime / 60)
    local seconds = math.floor(gameTime % 60)
    local team = PlayerUI_GetTeamType()
    local gameTimeString = string.format("%s - %d:%.2d", Locale.ResolveString(string.format("GAME_LENGTH_TEAM%i",team)), minutes, seconds)
    
    local respawnExtend = GetRespawnTimeExtend(gameTime)

    if team == kMarineTeamType then
        respawnExtend = respawnExtend + kMarineRespawnTime
    elseif team == kAlienTeamType then
        respawnExtend = respawnExtend + kAlienSpawnTime
    end
    
    gameTimeString = gameTimeString .. string.format("\n%s - %is", Locale.ResolveString(string.format("RESPAWN_EXTEND_TEAM%i",team)),respawnExtend)
    return gameTimeString

end