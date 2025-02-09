
local safeCommandStuctureRadius = 25

function CanCommandStructureBeBuilt(techId, origin, normal, commander)
	local front, siege, suddendeath, gameLength = GetGameInfoEntity():GetSiegeTimes()
    
    if front > 0 then
    
        local cs = GetEntitiesForTeamWithinRange("CommandStructure", GetEnemyTeamNumber(commander:GetTeamNumber()), origin, safeCommandStuctureRadius)
        if cs and #cs > 0 then
            return false
        end
    end
    
    return suddendeath > 0
end

local oldBuildTechData = BuildTechData
function BuildTechData()
    
    local techData = oldBuildTechData()
    
    for index,record in ipairs(techData) do 
        local currentField = record[kTechDataId]
        
        if(currentField == kTechId.CommandStation) or (currentField == kTechId.Hive) then
          
          -- patch the tech data to prevent building if sudden death
            record[kTechDataBuildRequiresMethod] = CanCommandStructureBeBuilt
            record[kTechDataBuildMethodFailedMessage] = "Can't build command structure!"
        end

    end
    
    return techData
end
    