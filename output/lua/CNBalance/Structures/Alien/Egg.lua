
-- Grab player out of respawn queue unless player passed in (for test framework)
function Egg:SpawnPlayer(player)

    PROFILE("Egg:SpawnPlayer")

    local queuedPlayer = player
    
    if not queuedPlayer or self.queuedPlayerId ~= nil then
        queuedPlayer = Shared.GetEntity(self.queuedPlayerId)
    end
    
    if queuedPlayer ~= nil then
    
        local queuedPlayer = player
        if not queuedPlayer then
            queuedPlayer = Shared.GetEntity(self.queuedPlayerId)
        end
    
        
        -- Spawn player on top of egg
        local spawnOrigin = Vector(self:GetOrigin())
        -- Move down to the ground.
        local _, normal = GetSurfaceAndNormalUnderEntity(self)
        local extents = self:GetExtents().y
        spawnOrigin.y = spawnOrigin.y - (extents / 2)
        if normal.y < 1 then
            spawnOrigin = spawnOrigin + normal * 1
        end

        local gestationClass = self:GetClassToGestate()
        
        -- We must clear out queuedPlayerId BEFORE calling ReplaceRespawnPlayer
        -- as this will trigger OnEntityChange() which would requeue this player.
        self.queuedPlayerId = nil
        
        local team = queuedPlayer:GetTeam()
        local success, player = team:ReplaceRespawnPlayer(queuedPlayer, spawnOrigin, queuedPlayer:GetAngles(), gestationClass)                
        player:SetCameraDistance(0)
        player:SetHatched()
        -- It is important that the player was spawned at the spot we specified.
        assert(player:GetOrigin() == spawnOrigin)
        
        if success then
            SetPlayerStartingLocation(player)
            self:PickUpgrades(player)

            self:TriggerEffects("egg_death")
            DestroyEntity(self) 
            
            return true, player
            
        end
            
    end
    
    return false, nil

end
