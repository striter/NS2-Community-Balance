-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\EnergizeMixin.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

--
-- EnergizeMixin drags out parts of an umbra cloud to protect an alien for additional EnergizeMixin.kUmbraDragTime seconds.
--
EnergizeMixin = CreateMixin(EnergizeMixin)
EnergizeMixin.type = "Energize"

EnergizeMixin.kSegment1Cinematic = PrecacheAsset("cinematics/alien/crag/umbraTrail1.cinematic")
EnergizeMixin.kSegment2Cinematic = PrecacheAsset("cinematics/alien/crag/umbraTrail2.cinematic")
EnergizeMixin.kViewModelCinematic = PrecacheAsset("cinematics/alien/crag/umbra_1p.cinematic")

local kMaxEnergizeLevel = 1

EnergizeMixin.expectedMixins =
{
    GameEffects = "Required to track energize state",
}

EnergizeMixin.networkVars =
{
    energizeLevel = "private integer (0 to " .. kMaxEnergizeLevel .. ")"
}

function EnergizeMixin:__initmixin()
    
    PROFILE("EnergizeMixin:__initmixin")
    
    self.energizeLevel = 0

    if Server then
        self.energizeGivers = unique_set()
        self.energizeGiverTime = {}
    end    
end

function EnergizeMixin:GetEnergizeLevel()
    return self.energizeLevel
end

if Server then
    local function UpdateEnergizedState(self)
        PROFILE("EnergizeMixin:UpdateState")

        local energizeAllowed = not self.GetIsEnergizeAllowed or self:GetIsEnergizeAllowed()

        local now = Shared.GetTime()
        for _, giverId in ipairs(self.energizeGivers:GetList()) do

            if not energizeAllowed or self.energizeGiverTime[giverId] + 1 < now then
                self.energizeGiverTime[giverId] = nil
                self.energizeGivers:Remove(giverId)
            end

        end

        self.energizeLevel = Clamp(self.energizeGivers:GetCount(), 0, kMaxEnergizeLevel)
        local energized = self.energizeLevel > 0
        self:SetGameEffectMask(kGameEffect.Energize, energized)

        if energized then

            local energy = kStructureEnergyPerEnergize
            if self:isa("Player") then
                energy = kPlayerEnergyPerEnergize
                local reduceEnergize = HasMixin(self, "Combat") and self:GetIsInCombat()
                if reduceEnergize then
                    energy = kPlayerEnergyPerEnergizeInCombat
                end
            end
            
            energy = energy * self.energizeLevel
            self:AddEnergy(energy)

        end

        return energized
    end

    function EnergizeMixin:Energize(giver)
    
        local energizeAllowed = not self.GetIsEnergizeAllowed or self:GetIsEnergizeAllowed()
        
        if energizeAllowed then
        
            self.energizeGivers:Insert(giver:GetId())
            self.energizeGiverTime[giver:GetId()] = Shared.GetTime()

            if self:GetEnergizeLevel() == 0 then
                UpdateEnergizedState(self) -- energize
                self:AddTimedCallback(UpdateEnergizedState, kEnergizeUpdateRate)
            end
        
        end
    
    end

    function EnergizeMixin:CopyPlayerDataFrom(player)

        if HasMixin(player, "Energize") and player:GetEnergizeLevel() > 0 then
            self:AddTimedCallback(UpdateEnergizedState, kEnergizeUpdateRate)
        end

    end

end