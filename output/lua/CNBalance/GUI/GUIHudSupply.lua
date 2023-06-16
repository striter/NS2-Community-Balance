-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/Hud2/topBar/GUIHudSupply.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Displays the amount of supply a team is consuming over the total amount of supply available.
--
--  Properties
--      Supply      The amount of supply currently consumed by the team.
--      SupplyMax   The maximum amount of supply available to the team.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/Hud2/topBar/GUIHudTopBarTeamThemedObject.lua")

local baseClass = GUIHudTopBarTeamThemedObject
class "GUIHudSupply" (baseClass)

GUIHudSupply.kLayoutSortPriority = 384

GUIHudSupply.kThemeData =
{
    icon = PrecacheAsset("ui/hud2/team_info_atlas.dds"),

    [kMarineTeamType] =
    {
        pxCoords = {50, 100, 100, 150}, -- optional, otherwise full texture is used.
    },

    [kAlienTeamType] =
    {
        pxCoords = {0, 100, 50, 150},
    },
}

GUIHudSupply:AddClassProperty("Supply", 0)
GUIHudSupply:AddClassProperty("SupplyMax", kMaxSupply)

function GUIHudSupply:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    self:HookEvent(self, "OnSupplyChanged", self.UpdateSupplyText)
    self:HookEvent(self, "OnSupplyMaxChanged", self.UpdateSupplyText)
    self:UpdateSupplyText()

    -- We hook a special global "OnTeam___SupplyUsedChanged" events from the global dispatcher to
    -- get team supply updates.  If the team changes for this widget, then we need to update which
    -- "OnTeam___SupplyUsedChanged" event we've hooked.
    self:HookEvent(self, "OnTeamNumberChanged", self.UpdateSupplyHook)
    self:HookEvent(self, "OnTeamInfoInitialized", self.UpdateSupplyHook)
    self:UpdateSupplyHook()

end

function GUIHudSupply:UpdateSupplyText()
    local supply = self:GetSupply()
    local supplyMax = self:GetSupplyMax()
    -- TODO maybe make the text color turn red if supply is near or exceeds supplyMax?
    self:GetTextObj():SetText(string.format("%d / %d", supply, supplyMax))
end

function GUIHudSupply:GetMaxWidthText()
    return "200 / 200"
end


function GUIHudSupply:UpdateSupplyHook()

    -- Clear old hook
    if self.supplyHook then
        self:UnHookEventsByCallback(self.supplyHook)
    end
    if self.supplyMaxHook then
        self:UnHookEventsByCallback(self.supplyMaxHook)
    end

    -- Hook into the correct event name for this team number.
    local teamNumber = self:GetTeamNumber()
    self.supplyHook = self:HookEvent(GetGlobalEventDispatcher(),  string.format("OnTeam%dSupplyUsedChanged", teamNumber),self.SetSupply)
    self.supplyMaxHook =  self:HookEvent(GetGlobalEventDispatcher(),string.format("OnTeam%dSupplyMaxChanged", teamNumber),self.SetSupplyMax)

    -- Update the Supply amount immediately if we can, since we're probably not starting at the correct value.
    local teamInfo = GetTeamInfoEntity(self:GetTeamNumber())
    if teamInfo then
        self:SetSupply(teamInfo.supplyUsed)
        self:SetSupplyMax(teamInfo.maxSupply)
    end

end


GUIHudTopBar.AddTopBarClass("GUIHudSupply")

