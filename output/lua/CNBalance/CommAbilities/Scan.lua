

if Server then

    function Scan:Perform()
    
        PROFILE("Scan:Perform")
        
        AlienDetectionParry(GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(),Scan.kScanDistance)
        
        local inkClouds = GetEntitiesForTeamWithinRange("ShadeInk", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), Scan.kScanDistance)

        if #inkClouds > 0 then
            
            for _, cloud in ipairs(inkClouds) do
                cloud:SetIsSighted(true)
            end

        else

            -- avoid scanning entities twice
            local scannedIdMap = {}
            local enemies = GetEntitiesWithMixinForTeamWithinXZRange("LOS", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), Scan.kScanDistance)
            for _, enemy in ipairs(enemies) do

                local entId = enemy:GetId()
                scannedIdMap[entId] = true

                self:ScanEntity(enemy)

            end

            local detectable = GetEntitiesWithMixinForTeamWithinXZRange("Detectable", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), Scan.kScanDistance)
            for _, enemy in ipairs(detectable) do

                local entId = enemy:GetId()
                if not scannedIdMap[entId] then
                    self:ScanEntity(enemy)
                end

            end
            
        end    
        
    end
    
    function Scan:OnDestroy()
    
        for _, entity in ipairs( GetEntitiesWithMixinForTeamWithinRange("LOS", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), Scan.kScanDistance)) do
            entity.updateLOS = true
        end
        
        CommanderAbility.OnDestroy(self)
    
    end
    
end
