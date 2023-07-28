-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\PhaseGateUserMixin.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

PhaseGateUserMixin = CreateMixin( PhaseGateUserMixin )
PhaseGateUserMixin.type = "PhaseGateUser"

local kPhaseDelay = 1

PhaseGateUserMixin.networkVars =
{
    timeOfLastPhase = "compensated private time"
}

local function SharedUpdate(self)
    PROFILE("PhaseGateUserMixin:OnUpdate")
    if self:GetCanPhase() then

        for _, phaseGate in ipairs(GetEntitiesForTeamWithinRange("PhaseGate", self:GetTeamNumber(), self:GetOrigin(), 0.5)) do
        
            if phaseGate:GetIsDeployed() and GetIsUnitActive(phaseGate) and phaseGate:Phase(self) then

                self.timeOfLastPhase = Shared.GetTime()
                
                if Client then               
                    self.timeOfLastPhaseClient = Shared.GetTime()
                    local viewAngles = self:GetViewAngles()
                    Client.SetYaw(viewAngles.yaw)
                    Client.SetPitch(viewAngles.pitch)     
                end
                --[[
                if HasMixin(self, "Controller") then
                    self:SetIgnorePlayerCollisions(1.5)
                end
                --]]
                break
                
            end
        
        end
    
    end

end

function PhaseGateUserMixin:__initmixin()
    
    PROFILE("PhaseGateUserMixin:__initmixin")
    
    self.timeOfLastPhase = 0
end

local kOnPhase =
{
    phaseGateId = "entityid",
    phasedEntityId = "entityid"
}
Shared.RegisterNetworkMessage("OnPhase", kOnPhase)

if Server then

    function PhaseGateUserMixin:OnProcessMove(input)
        PROFILE("PhaseGateUserMixin:OnProcessMove")

        if self:GetCanPhase() then
            for _, phaseGate in ipairs(GetEntitiesForTeamWithinRange("PhaseGate", self:GetTeamNumber(), self:GetOrigin(), 0.5)) do
                if phaseGate:GetIsDeployed() and GetIsUnitActive(phaseGate) and phaseGate:Phase(self) then
                    -- If we can found a phasegate we can phase through, inform the server
                    self.timeOfLastPhase = Shared.GetTime()
                    local id = self:GetId()
                    Server.SendNetworkMessage(self:GetClient(), "OnPhase", { phaseGateId = phaseGate:GetId(), phasedEntityId = id or Entity.invalidId }, true)
                    return
                end
            end
        end
    end

    function PhaseGateUserMixin:OnUpdate(deltaTime)
        SharedUpdate(self)
    end
    
end

if Client then

    local function OnMessagePhase(message)
        PROFILE("PhaseGateUserMixin:OnMessagePhase")

        -- TODO: Is there a better way to do this?
        local phaseGate = Shared.GetEntity(message.phaseGateId)
        local phasedEnt = Shared.GetEntity(message.phasedEntityId)

        -- Need to keep this var updated so that client side effects work correctly
        phasedEnt.timeOfLastPhaseClient = Shared.GetTime()

        phaseGate:Phase(phasedEnt)
        local viewAngles = phasedEnt:GetViewAngles()

        -- Update view angles
        Client.SetYaw(viewAngles.yaw)
        Client.SetPitch(viewAngles.pitch)
    end

    Client.HookNetworkMessage("OnPhase", OnMessagePhase)

end

function PhaseGateUserMixin:GetCanPhase()
    if Server then
        return self:GetIsAlive() and Shared.GetTime() > self.timeOfLastPhase + kPhaseDelay and not GetConcedeSequenceActive()
    else
        return self:GetIsAlive() and Shared.GetTime() > self.timeOfLastPhase + kPhaseDelay
    end
    
end


function PhaseGateUserMixin:OnPhaseGateEntry(destinationOrigin)
    if Server and HasMixin(self, "LOS") then
        self:MarkNearbyDirtyImmediately()
    end
end
