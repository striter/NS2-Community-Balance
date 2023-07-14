-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\Pheromone.lua
--
-- A way for the alien commander to communicate with his minions.
--
-- Goals
--   Create easy way for alien commander to communicate with his team without needing to click aliens and give orders. That wouldnt fit.
--   Keep it feeling bottom-up so players can make their own choices
--   Have orders feel environmental
--
-- First implementation
--   Create pheromones that act as a hive sight blip. Aliens can see pheromones like blips on their HUD. Examples: Need healing, Need protection, Building here,
--   Need infestation, Threat detected, Reinforce. These are not orders, but informational. Its up to aliens to decide what to do, if anything.
--
--   Each time you create pheromones, it will create a new signpost at that location if there isnt one nearby. Otherwise, if it is a new type, it will remove the
--   old one and create the new one. If there is one of the same type nearby, it will intensify the current one to make it more important. In this way, each pheromone
--   has an analog intensity which indicates the range at which it can be seen, as well as the alpha, font weight, etc. (how much it stands out to players).
--
--   Each time you click, a circle animates showing the new intensity (larger intensity shows a bigger circle). When creating pheromones, VAFX play slight gas sound and
--   foggy bits pop out of the environment and coalesce, spinning, around the new sign post text.
--
--   When mousing over them, a dismiss button appears so the commander and manually delete them if no longer relevant. They also dissipate over time.
--
--   Pheromones are public property and have no owner. Any commander can dismiss, modify or grow any other pheromone cloud.
--
--   Show very faint/basic pheromone indicator to marines also. They have an idea that they are nearby, but dont know what (perhaps just play faint sound when created, no visual).
--
--   Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/TeamMixin.lua")

class 'Pheromone' (Entity)

Pheromone.kMapName = "pheromone"
local kAppearDistance = 45
local kRallyLifetime = 30
local kExpandingLifetime = 60
local kHurtLifetime = 30

local networkVars =
{
    -- "Threat detected", "Reinforce", etc.
    type = "enum kTechId",

    -- timestamp when to kill the pheromone
    untilTime = "time",

    createTime = "time",
}
AddMixinNetworkVars(TeamMixin, networkVars)

function Pheromone:OnCreate()

    Entity.OnCreate(self)

    self:UpdateRelevancy()

    InitMixin(self, TeamMixin)
    self.type = kTechId.None
    self.lifetime = 0
    self.createTime = 0

    if Server then
        self:SetUpdates(true, kDefaultUpdateRate)
    end

end

function Pheromone:Initialize(techId)

    self.type = techId

    local lifetime = 20
    if techId == kTechId.ExpandingMarker then
        lifetime = kExpandingLifetime
    elseif techId == kTechId.ThreatMarker then
        lifetime = kRallyLifetime
    elseif techId == kTechId.NeedHealingMarker then
        lifetime = kHurtLifetime
    end

    self.untilTime = Shared.GetTime() + lifetime
    self.createTime = Shared.GetTime()

    if Server then
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
    end
end

function Pheromone:GetType()
    return self.type
end

function Pheromone:GetMapBlipType()
    if self.type == kTechId.ExpandingMarker then
        return kMinimapBlipType.Pheromone_Expand
    elseif self.type == kTechId.NeedHealingMarker then
        return kMinimapBlipType.Pheromone_Defend
    end
    
    return kMinimapBlipType.Pheromone_Threat
end

function Pheromone:GetDisplayName()
    return GetDisplayNameForTechId(self.type, "<no pheromone name>")
end

function Pheromone:GetAppearDistance()
    return kAppearDistance
end

function Pheromone:GetCreateTime()
    return self.createTime
end

function Pheromone:UpdateRelevancy()

    self:SetRelevancyDistance(self:GetAppearDistance())

    if self.teamNumber == 1 then
        self:SetIncludeRelevancyMask(kRelevantToTeam1)
    else
        self:SetIncludeRelevancyMask(kRelevantToTeam2)
    end

end

if Server then


    function CreatePheromone(techId, position, teamNumber)

        -- Create new pheromone (hover off ground a little).
        local newPheromone = CreateEntity(Pheromone.kMapName, position + Vector(0, 0.5, 0), teamNumber)
        newPheromone:Initialize(techId)

        local team = newPheromone:GetTeam()
        local cost = LookupTechData(techId,kTechDataCostKey,0)
        team:AddTeamResources(-cost)
        
        local pheromones = GetEntities("Pheromone")
        for p = 1, #pheromones do

            local pheromone = pheromones[p]
            if pheromone:GetId() ~= newPheromone:GetId() then

                if pheromone:GetType() == newPheromone:GetType() then
                    DestroyEntity(pheromone)
                end

            end

        end

        -- return new one we created
        return newPheromone

    end

    
    local kRallyTickInterval = 2
    function Pheromone:OnUpdate()

        -- Expire pheromones after a time
        if self.untilTime <= Shared.GetTime() then
            DestroyEntity(self)
            return
        end

        if self:GetType() == kTechId.ThreatMarker then
            local now = Shared.GetTime()
            if not self.timeLastRally or now - self.timeLastRally > kRallyTickInterval then
                self.timeLastRally = now
                local players = GetEntitiesForTeamWithinXZRange("Player",self.teamNumber,self:GetOrigin(),kRallyRadius)
                for _, player in pairs(players) do
                    player:AddContinuousScore("Rally",kRallyTickInterval, kRallyResultDuration,kRallyScoreEachDuration,kRallyPResEachDuration)
                end
            end
            
        end
        
    end

end

Shared.LinkClassToMap("Pheromone", Pheromone.kMapName, networkVars)
