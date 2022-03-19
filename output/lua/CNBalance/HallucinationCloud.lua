function GetHallucinationTechId(techId)

    if not gTechIdToHallucinateTechId then
    
        gTechIdToHallucinateTechId = {}
        gTechIdToHallucinateTechId[kTechId.Drifter] = kTechId.HallucinateDrifter
        gTechIdToHallucinateTechId[kTechId.Prowler] = kTechId.HallucinateProwler   
        gTechIdToHallucinateTechId[kTechId.Skulk] = kTechId.HallucinateSkulk
        gTechIdToHallucinateTechId[kTechId.Gorge] = kTechId.HallucinateGorge
        gTechIdToHallucinateTechId[kTechId.Lerk] = kTechId.HallucinateLerk
        gTechIdToHallucinateTechId[kTechId.Fade] = kTechId.HallucinateFade
        gTechIdToHallucinateTechId[kTechId.Onos] = kTechId.HallucinateOnos
        
        gTechIdToHallucinateTechId[kTechId.Hive] = kTechId.HallucinateHive
        gTechIdToHallucinateTechId[kTechId.Whip] = kTechId.HallucinateWhip
        gTechIdToHallucinateTechId[kTechId.Shade] = kTechId.HallucinateShade
        gTechIdToHallucinateTechId[kTechId.Crag] = kTechId.HallucinateCrag
        gTechIdToHallucinateTechId[kTechId.Shift] = kTechId.HallucinateShift
        gTechIdToHallucinateTechId[kTechId.Harvester] = kTechId.HallucinateHarvester
        gTechIdToHallucinateTechId[kTechId.Hydra] = kTechId.HallucinateHydra
    
    elseif not gTechIdToHallucinateTechId[kTechId.Prowler] then
        
        gTechIdToHallucinateTechId[kTechId.Prowler] = kTechId.HallucinateProwler
    
    end
    
    return gTechIdToHallucinateTechId[techId]
end


if Server then
    
    local kHallucinationClassNameMap = debug.getupvaluex(HallucinationCloud.Perform, "kHallucinationClassNameMap")
    kHallucinationClassNameMap[Prowler.kMapName] = ProwlerHallucination.kMapName    

end

Shared.LinkClassToMap("HallucinationCloud", HallucinationCloud.kMapName, networkVars)