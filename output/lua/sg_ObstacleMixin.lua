--
--	ns2siege+ Custom Game Mode
--	ZycaR (c) 2016
--

kFuncDoorMapName = "ns2siege_funcdoor"

local ns2_GetPathingInfo = ObstacleMixin._GetPathingInfo
function ObstacleMixin:_GetPathingInfo()

    -- command structures get a pass
    if  self:GetMapName() == "commandstructure"
        or self:GetMapName() == "commandstation"
        or self:GetMapName() == "hive" then
        
        -- by default, the game tries to make a 1000 unit tall thing. It's stupid. We can't use it.
        -- NS2s original implementation was bad, but we just want to avoid it altogether for the most part.
        local position = self:GetOrigin() + Vector(0, -3, 0)  
        local radius = LookupTechData(self:GetTechId(), kTechDataObstacleRadius, 1.0)
        local height = 8
        
        return position, radius, height
    end
    
    -- everything else doesn't add to the pathing mesh
    if (self:GetMapName() ~= kFuncDoorMapName)
        or not self._modelCoords  then
        
        --local position = self:GetOrigin() + Vector(0, -3, 0)  
        --local radius = LookupTechData(self:GetTechId(), kTechDataObstacleRadius, 1.0)
        --local height = 8
        
        --return position, radius, height
        return nil, 0, 0
    end

    -- front door has it's own function
    assert(self.GetObstaclePathingInfo)
    return self:GetObstaclePathingInfo()
end



function ObstacleMixin:AddToMesh()

    if GetIsPathingMeshInitialized() then
   
        if self.obstacleId ~= -1 then
            Pathing.RemoveObstacle(self.obstacleId)
            gAllObstacles[self] = nil
        end

        local position, radius, height = self:_GetPathingInfo()   
        if position ~= nil then
            self.obstacleId = Pathing.AddObstacle(position, radius, height) 
        else
            self.obstacleId = -1
        end
      
        if self.obstacleId ~= -1 then
        
            gAllObstacles[self] = true
            if self.GetResetsPathing and self:GetResetsPathing() then
                InformEntitiesInRange(self, 25)
            end
            
        end
    
    end
    
end