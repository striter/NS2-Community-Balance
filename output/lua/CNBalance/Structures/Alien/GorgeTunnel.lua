Script.Load("lua/TunnelEntrance.lua")
Script.Load("lua/BiomassHealthMixin.lua")

--Script.Load("lua/DigestMixin.lua")

class 'GorgeTunnel' (TunnelEntrance)
GorgeTunnel.kMapName = "gorgetunnel"

local kDigestDuration = 1.5
local kTunnelInfestationRadius = 7

local networkVars =
{
    ownerId = "entityid",
    variant = "enum kGorgeVariants"
}

function GorgeTunnel:OnCreate()

    TunnelEntrance.OnCreate(self)
    --InitMixin(self, DigestMixin)
    self.variant = kGorgeVariants.normal
    
end

function GorgeTunnel:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = useSuccessTable.useSuccess and self:GetCanDigest(player)
end

function GorgeTunnel:OnDestroy()
    
    TunnelEntrance.OnDestroy(self)
    --if Server then
    --    if self:GetGorgeOwner() then
    --        local player = self:GetOwner()
    --        if player and not GetWarmupActive() then
    --            if (self.consumed) then
    --                player:AddResources(kGorgeTunnelCostDigest)
    --            elseif self.refundsOnKill then
    --                player:AddResources(kGorgeTunnelCostKill)
    --            end
    --        
    --        end
    --    end
    --end
end

function GorgeTunnel:GetOwnerClientId()
    return self.ownerClientId
end

function GorgeTunnel:SetOwnerClientId(clientId)
    self.ownerClientId = clientId
end

if Server then

    function GorgeTunnel:UpdateConnectedTunnel()

        local hasValidTunnel = self.tunnelId ~= nil and Shared.GetEntity(self.tunnelId) ~= nil

        if hasValidTunnel or self:GetOwnerClientId() == nil or not self:GetIsBuilt() then
            return
        end

        local foundTunnel

        -- register if a tunnel entity already exists or a free tunnel has been found
        for _, tunnel in ientitylist( Shared.GetEntitiesWithClassname("Tunnel") ) do
            if tunnel:GetOwnerClientId() == self:GetOwnerClientId() then
                foundTunnel = tunnel
                break
            end
        end
        local newTunnel = false
        if not foundTunnel then
            -- no tunnel entity present
            foundTunnel = CreateEntity(Tunnel.kMapName, nil, self:GetTeamNumber())
            newTunnel = true
        end

        -- check if there is another tunnel entrance to connect with
        foundTunnel:SetOwnerClientId(self:GetOwnerClientId())

        local selfId = self:GetId()

        --Print(ToString(selfId).." self")

        if foundTunnel.exitAId ~= selfId and foundTunnel.exitBId ~= selfId then
            foundTunnel:AddExit(self)
        end
        self.tunnelId = foundTunnel:GetId()

        local foundTunnelEntrance
        -- register if a tunnel entity already exists or a free tunnel has been found
        for _, tunnelEntrance in ientitylist( Shared.GetEntitiesWithClassname("TunnelEntrance") ) do
            -- check the other entrance has been built and isn't killed
            if tunnelEntrance:GetOwnerClientId() == self:GetOwnerClientId() and tunnelEntrance ~= self and tunnelEntrance:GetIsAlive() and tunnelEntrance:GetIsBuilt() then
                foundTunnelEntrance = tunnelEntrance
                --Print("found old entrance %s", foundTunnelEntrance:GetId())
                break
            end
        end

        self:SetOtherEntrance(foundTunnelEntrance)

        if (foundTunnelEntrance) then
            foundTunnelEntrance:SetOtherEntrance(self)
            if newTunnel then
                foundTunnelEntrance:SetTunnel(foundTunnel)
            end
            --local foundTunnelEntranceId = foundTunnelEntrance:GetId()
            --if foundTunnel.exitAId ~= foundTunnelEntranceId and foundTunnel.exitBId ~= foundTunnelEntranceId then
            --    foundTunnel:AddExit(foundTunnelEntrance)
            --    foundTunnelEntrance.tunnelId = self.tunnelId
            --end
        end

        --Print(ToString(foundTunnel.exitAId).." + "..ToString(foundTunnel.exitBId))
    
    end
    
    function GorgeTunnel:OnConstructionComplete()
        
        -- Just finished construction, so open animation should play (if it is open).  This is to prevent the open
        -- animation from playing when the tunnel comes into view.
        self.skipOpenAnimation = false
        
        if self:GetGorgeOwner() then
            self:UpdateConnectedTunnel()
            --self:UpgradeToTechId(kTechId.InfestedTunnel)
            self:SetDesiredInfestationRadius(self:GetInfestationMaxRadius())
        else

            -- If the tunnel entrance has another (completed) tunnel entrance, ensure a tunnel connects the two together.
            local otherEntrance = self:GetOtherEntrance()
            
            -- If the other side started the infestation research before this side finished building, we want to set our progress to match.
            if otherEntrance and otherEntrance:GetIsResearching() then
                self.researchProgress = otherEntrance.researchProgress    
            end
            
            if otherEntrance and otherEntrance:GetIsBuilt() then
                
                assert(self:GetTunnelEntity() == nil) -- this TunnelEntrance should not already have a tunnel assigned to it.
                
                -- See if the other entrance already has a tunnel assigned to it (eg this is a relocate).
                local tunnel = otherEntrance:GetTunnelEntity()
                if not tunnel then
                    
                    -- Create a new tunnel since neither of the two entrances had one.
                    tunnel = CreateEntity(Tunnel.kMapName, nil, self:GetTeamNumber())
                    otherEntrance:SetTunnel(tunnel)
                
                end
                
                self:SetTunnel(tunnel)
            
            end
        
        end
    end
        
else

    function GorgeTunnel:GetOwner()
        return self.ownerId ~= nil and Shared.GetEntity(self.ownerId)
    end
    
end

function GorgeTunnel:GetOwnerClientId()
    return self.ownerClientId
end

function GorgeTunnel:GetGorgeOwner()
    return self.ownerId and self.ownerId ~= Entity.invalidId
end

function GorgeTunnel:GetDigestDuration()
    return kDigestDuration
end

function GorgeTunnel:GetCanDigest(player)
    return player == self:GetOwner() and player:isa("Gorge") and (not HasMixin(self, "Live") or self:GetIsAlive()) --and self:GetIsBuilt()
end

function GorgeTunnel:SetOwner(owner)
    
    if owner and not self.ownerClientId then
        
        local client = Server.GetOwner(owner)
        self.ownerClientId = client:GetUserId()
        
        --[[if Server then
            self:UpdateConnectedTunnel()
        end--]]
        
        if self.tunnelId and self.tunnelId ~= Entity.invalidId then
            
            local tunnelEnt = Shared.GetEntity(self.tunnelId)
            tunnelEnt:SetOwnerClientId(self.ownerClientId)
        
        end
    
    end

end



function GorgeTunnel:GetCanBuildOtherEnd()
    return not self:GetGorgeOwner() and not self:GetHasOtherEntrance() and not self:GetIsCollapsing() and self:GetIsAlive()
end

function GorgeTunnel:GetCanTriggerCollapse()
    return not self:GetGorgeOwner() and self:GetIsBuilt() and not self:GetIsCollapsing() and not self:GetIsResearching() and self:GetIsAlive()
end

function GorgeTunnel:GetCanRelocate()
    return not self:GetGorgeOwner() and self:GetHasOtherEntrance() and self:GetIsBuilt() and not self:GetIsCollapsing()
end

function GorgeTunnel:GetCanBeUsedConstructed()
    return true
end

function GorgeTunnel:GetUnitNameOverride(viewer)
    
    local unitName = GetDisplayName(self)
    
    if not GetAreEnemies(self, viewer) and self.ownerId then
        local ownerName
        for _, playerInfo in ientitylist(Shared.GetEntitiesWithClassname("PlayerInfoEntity")) do
            if playerInfo.playerId == self.ownerId then
                ownerName = playerInfo.playerName
                break
            end
        end
        if ownerName then
            
            local lastLetter = ownerName:sub(-1)
            if lastLetter == "s" or lastLetter == "S" then
                return string.format( Locale.ResolveString( "TUNNEL_ENTRANCE_OWNER_ENDS_WITH_S" ), ownerName )
            else
                return string.format( Locale.ResolveString( "TUNNEL_ENTRANCE_OWNER" ), ownerName )
            end
        end
    
    end
    
    return unitName

end

function GorgeTunnel:GetMapBlipType()
    return kMinimapBlipType.TunnelEntrance
end

Shared.LinkClassToMap("GorgeTunnel", GorgeTunnel.kMapName, networkVars)