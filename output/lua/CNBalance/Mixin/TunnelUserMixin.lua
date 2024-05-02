-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\TunnelUserMixin.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

TunnelUserMixin = CreateMixin( TunnelUserMixin )
TunnelUserMixin.type = "TunnelUser"

local kTunnelSinkSpeed = 2.3
local kTunnelUseScreenCinematic = PrecacheAsset("cinematics/alien/tunnel/entrance_use_1p.cinematic")
local kScreenEffectDuration = 4
local kTunnelUseTimeout = 2
local kTunnelExitRadius = 3

TunnelUserMixin.networkVars =
{
    tunnelNearby = "private boolean",
    enableTunnelEntranceCheck = "private boolean",
    canUseTunnel = "private boolean"
}

function TunnelUserMixin:__initmixin()
    
    PROFILE("TunnelUserMixin:__initmixin")
    
    self.tunnelNearby = false
    -- set to true when colliding with a tunnel, resets to falls when no tunnel entrance entitiy is nearby
    self.enableTunnelEntranceCheck = false
    self.clientIsInTunnel = false
    self.clientTimeTunnelUsed = -20
    self.clientUseScreenEffect = false
    self.timeTunnelUsed = 0
    self.canUseTunnel = true
    self.disableMovement = false
    
    if Server then
        self.timeSinkInStarted = nil
        self.currentTunnelId = Entity.invalidId
    end
    
end

local function GetNearbyTunnelEntrance(self)
    local playerExtentY = self:GetExtents().y
    local playerCenter = self:GetOrigin() + Vector(0,playerExtentY,0)
    local nearbyTunnelEntrance = GetEntitiesWithinRange("TunnelEntrance", playerCenter, 5)
    for _, tunnelEntrance in pairs(nearbyTunnelEntrance) do
        local tunnelCoords = tunnelEntrance:GetCoords()
        local suckinCenter = tunnelCoords.origin + tunnelCoords.yAxis * playerExtentY
        --DebugLine(playerCenter, suckinCenter, 1, 0, 1, 0, 1)
        --Shared.Message(tostring((playerCenter - suckinCenter):GetLength()))
        if (playerCenter - suckinCenter):GetLength() < 1.3 then
            return tunnelEntrance
        end
    end
end

function TunnelUserMixin:OnUseGorgeTunnel(destinationOrigin)
    self.timeTunnelUsed = Shared.GetTime()
    if HasMixin(self, "SmoothedRelevancy") then
        -- TODO use relevancy portals for tunnels too?  Probably not as much of an improvement...
        -- tunnels usually not THAT crowded.
        self:StartSmoothedRelevancy(destinationOrigin)
    end
end

-- move the player closer to the tunnel entrance model
local function UpdateSinkIn(self, deltaTime)

    local tunnelEntrance = GetNearbyTunnelEntrance(self)
    if tunnelEntrance and tunnelEntrance:GetIsBuilt() and tunnelEntrance:GetIsConnected() then
    
        self.disableMovement = true
        
        if not self.timeSinkInStarted then
            self.timeSinkInStarted = Shared.GetTime()
        end

        local playerExtentY = self:GetExtents().y
        local playerCenter = self:GetOrigin() + Vector(0,playerExtentY,0)
        local tunnelCoords = tunnelEntrance:GetCoords()
        local suckInCenter = tunnelCoords.origin + tunnelCoords.yAxis * playerExtentY * .5 --suckin further
        
        local move = suckInCenter - playerCenter
        local moveLength = move:GetLength()
        if moveLength < 0.3 then
        
            move:Normalize()
            move:Scale(0.3)
            
        end
        
        local origin = self:GetOrigin()
        local newOrigin = origin + deltaTime * move * kTunnelSinkSpeed
        
        newOrigin.x = Limit(newOrigin.x, origin.x, suckInCenter.x)
        newOrigin.y = Limit(newOrigin.y, origin.y, suckInCenter.y)
        newOrigin.z = Limit(newOrigin.z, origin.z, suckInCenter.z)
        
        self:SetOrigin(newOrigin)
        tunnelEntrance:Interact(self)
        
        -- enter the tunnel when below the threshold distance
        if Server and self.timeSinkInStarted and self.timeSinkInStarted + 0.4 < Shared.GetTime() then
            tunnelEntrance:SuckinEntity(self)            
        end
        
    else
        self.disableMovement = false
    end

end

local function UpdateTunnelEffects(self)

    local isInTunnel = GetIsPointInGorgeTunnel(self:GetOrigin())

    if self.clientIsInTunnel ~= isInTunnel then
    
        local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
        cinematic:SetCinematic(FilterCinematicName(kTunnelUseScreenCinematic))
        cinematic:SetRepeatStyle(Cinematic.Repeat_None)
        
        --[[
        Removed during Sweets sounds-update, duplicate of the 3D Sound Event anyways, b323
        if isInTunnel then
            self:TriggerEffects("tunnel_enter_2D")
        else
            self:TriggerEffects("tunnel_exit_2D")
        end
        --]]
        
        self.clientIsInTunnel = isInTunnel
        self.clientTimeTunnelUsed = Shared.GetTime()
        self.clientUseScreenEffect = not Client.kHideViewModel and self.clientTimeTunnelUsed + kScreenEffectDuration > Shared.GetTime()
    
    end

end

local function UpdateExitTunnel(self, deltaTime, tunnel)

    if not self.GetCanExitTunnel or self:GetCanExitTunnel() then

        local exitA = tunnel:GetExitA()
        local exitB = tunnel:GetExitB()
    
        local fracPos = tunnel:GetFractionalPosition( self:GetOrigin() )
        if exitA and fracPos < 0.05 then
            tunnel:UseExit(self, exitA, kTunnelExitSide.A)
        elseif exitB and fracPos > 0.95 then
            tunnel:UseExit(self, exitB, kTunnelExitSide.B)
        end
    
    end

end

local function SharedUpdate(self, deltaTime)

    if self.canUseTunnel then

        if self:GetIsEnteringTunnel() then
            UpdateSinkIn(self, deltaTime)
        elseif Server then
            
            self.timeSinkInStarted = nil
            local tunnel = GetIsPointInGorgeTunnel(self:GetOrigin())
            if tunnel then
                UpdateExitTunnel(self, deltaTime, tunnel)
            end
            
        end
    
    end
    
    if Server then
        self.canUseTunnel = self.timeTunnelUsed + kTunnelUseTimeout < Shared.GetTime()
    elseif Client and self.GetIsLocalPlayer and self:GetIsLocalPlayer() then    
        UpdateTunnelEffects(self)
    end

end

function TunnelUserMixin:GetIsEnteringTunnel()
    return self.tunnelNearby and self.enterTunnelDesired
end

function TunnelUserMixin:OnProcessSpectate(deltaTime)
    UpdateTunnelEffects(self)
end

-- called before processmove. disable move when sinking in
function TunnelUserMixin:HandleButtonsMixin(input)

    if self:GetIsEnteringTunnel() and self.disableMovement then
        self:SetVelocity(Vector(0, 0, 0))
    end
    
end

function TunnelUserMixin:OnProcessMove(input)

    --self:SetEnterTunnelDesired(bit.band(input.commands, Move.Crouch) ~= 0)
    self:SetEnterTunnelDesired(input.move:GetLength() == 0)
    SharedUpdate(self, input.time)
    
end

function TunnelUserMixin:OnUpdate(deltaTime)
    PROFILE("TunnelUserMixin:OnUpdate")
    SharedUpdate(self, deltaTime)
end

function TunnelUserMixin:SetEnterTunnelDesired(enterTunnelDesired)

    if not self.GetCanEnterTunnel or self:GetCanEnterTunnel() then
        self.enterTunnelDesired = enterTunnelDesired
    end
    
end

if Server then
    function TunnelUserMixin:GetCanEnterTunnel()
        return not GetConcedeSequenceActive()
    end
end

local function UpdateTunnelEntranceCheck(self)

    if self.enableTunnelEntranceCheck then
    
        local tunnelEntrance = GetNearbyTunnelEntrance(self)
        if tunnelEntrance then 
            self.tunnelNearby = tunnelEntrance:GetIsBuilt()
        else
            self.enableTunnelEntranceCheck = false
        end
        
    end    
    
    if not self.enableTunnelEntranceCheck then    
        self.tunnelNearby = false
    end

end

function TunnelUserMixin:SetOrigin()
   UpdateTunnelEntranceCheck(self) 
end

function TunnelUserMixin:SetCoords()
    UpdateTunnelEntranceCheck(self)
end

function TunnelUserMixin:OnCapsuleTraceHit(entity)

    PROFILE("TunnelUserMixin:OnCapsuleTraceHit")

    if entity and entity:isa("TunnelEntrance") then
    
        self.enableTunnelEntranceCheck = true
        self.tunnelNearby = true
        
    end
    
end

function TunnelUserMixin:OnUpdateRender()

    if Player.screenEffects.gorgetunnel then

        Player.screenEffects.gorgetunnel:SetActive(self.clientUseScreenEffect)
        
        if self.clientUseScreenEffect then
            Player.screenEffects.gorgetunnel:SetParameter("amount", 1 - Clamp((Shared.GetTime() - self.clientTimeTunnelUsed) * 0.5, 0, 1))
            Player.screenEffects.gorgetunnel:SetParameter("time", Shared.GetTime())
        end
        
    end

end
