function ReadyRoomTeam:GetRespawnMapName(player)

    local mapName = player.kMapName    
    
    if mapName == nil then
        mapName = ReadyRoomPlayer.kMapName
    end
    
    -- Use previous life form if dead or in commander chair
    if mapName == MarineCommander.kMapName
       or mapName == AlienCommander.kMapName
       or mapName == Spectator.kMapName
       or mapName == AlienSpectator.kMapName
       or mapName == MarineSpectator.kMapName then 
    
        mapName = player:GetPreviousMapName()
        
    end
    
    if mapName == MarineCommander.kMapName
       or mapName == AlienCommander.kMapName
       or mapName == Spectator.kMapName
       or mapName == AlienSpectator.kMapName
       or mapName == MarineSpectator.kMapName then
           
        mapName = ReadyRoomPlayer.kMapName
        
    elseif mapName == Embryo.kMapName then
        mapName = ReadyRoomEmbryo.kMapName
	elseif mapName == DevouredPlayer.kMapName then
		mapName = ReadyRoomEmbryo.kMapName
    elseif mapName == Exo.kMapName then
        mapName = ReadyRoomExo.kMapName
    end
            
    return mapName
    
end