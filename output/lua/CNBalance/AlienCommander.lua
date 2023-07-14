
local gAlienMenuButtons =
{
    [kTechId.BuildMenu] = { kTechId.Cyst, kTechId.Harvester, kTechId.None, kTechId.Hive,
                            kTechId.ExpandingMarker, kTechId.ThreatMarker, kTechId.None, kTechId.BuildTunnelMenu },
                                                 --ThreatMarker   --kTechId.NeedHealingMarker
    [kTechId.AdvancedMenu] = { kTechId.Crag, kTechId.Shade, kTechId.Shift, kTechId.Whip,
                               kTechId.Shell, kTechId.Veil, kTechId.Spur, kTechId.BabblerEgg },

    [kTechId.AssistMenu] = { kTechId.HealWave, kTechId.ShadeInk, kTechId.SelectShift, kTechId.SelectDrifter,
                             kTechId.NutrientMist, kTechId.Rupture, kTechId.BoneWall, kTechId.Contamination }
}

local gAlienMenuIds = {}
do
    for menuId, _ in pairs(gAlienMenuButtons) do
        gAlienMenuIds[#gAlienMenuIds+1] = menuId
    end
end

function AlienCommander:GetButtonTable()
    return gAlienMenuButtons
end

function AlienCommander:GetMenuIds()
    return gAlienMenuIds
end

-- Top row always the same. Alien commander can override to replace.
function AlienCommander:GetQuickMenuTechButtons(techId)

    -- Top row always for quick access.
    local alienTechButtons = { kTechId.BuildMenu, kTechId.AdvancedMenu, kTechId.AssistMenu, kTechId.RootMenu }
    local menuButtons = gAlienMenuButtons[techId]

    if not menuButtons then

        -- Make sure all slots are initialized so entities can override simply.
        menuButtons = { kTechId.None, kTechId.None, kTechId.None, kTechId.None, kTechId.None, kTechId.None, kTechId.None, kTechId.None }

    end

    table.copy(menuButtons, alienTechButtons, true)

    -- Return buttons and true/false if we are in a quick-access menu.
    return alienTechButtons

end

if Client then

    local baseOnInitialized = AlienCommander.OnInitialized
    function AlienCommander:OnInitialized()
        baseOnInitialized(self)
        self.darkVisionTime = Shared.GetTime()
    end
    
    function AlienCommander:UpdateClientEffects(deltaTime, isLocal)

        Commander.UpdateClientEffects(self,deltaTime, isLocal)
        
        if isLocal then

            local useShader = Player.screenEffects.darkVision

            if useShader then

                useShader:SetActive(true)
                useShader:SetParameter("startTime", self.darkVisionTime)
                useShader:SetParameter("time", Shared.GetTime())
                useShader:SetParameter("amount", 1)

            end

        end

    end
    
end

if Server then

    local function GetIsPheromone(techId)
        return techId == kTechId.ThreatMarker or techId == kTechId.LargeThreatMarker or techId ==  kTechId.NeedHealingMarker or techId == kTechId.WeakMarker or techId == kTechId.ExpandingMarker
    end

    local function GetIsSelectTunnel(techId)
        return techId >= kTechId.SelectTunnelEntryOne and techId <= kTechId.SelectTunnelExitFour
    end

    local function SelectNearest(self, className)

        local nearestEnt = GetNearest(self, className)

        if nearestEnt then

            DeselectAllUnits(self:GetTeamNumber())
            nearestEnt:SetSelected(self:GetTeamNumber(), true, false)
            if Server then
                Server.SendNetworkMessage(self, "SelectAndGoto", BuildSelectAndGotoMessage(nearestEnt:GetId()), true)
            end

            return true

        end

        return false

    end
end 