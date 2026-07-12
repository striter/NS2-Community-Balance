-- Custom GUIHudTres that also displays Commander Aggressive Credit.
-- Format: "100+5" (Tres + Credit), or just "100" when credit is 0.

Script.Load("lua/Hud2/topBar/GUIHudTopBarTeamThemedObject.lua")

local baseClass = GUIHudTopBarTeamThemedObject
class "GUIHudTres" (baseClass)

GUIHudTres.kLayoutSortPriority = 128

GUIHudTres.kThemeData =
{
    icon = PrecacheAsset("ui/hud2/team_info_atlas.dds"),

    [kMarineTeamType] =
    {
        pxCoords = {50, 0, 100, 50},
    },

    [kAlienTeamType] =
    {
        pxCoords = {0, 0, 50, 50},
    },
}

GUIHudTres:AddClassProperty("Tres", 0)
GUIHudTres:AddClassProperty("Credit", 0)

function GUIHudTres:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    baseClass.Initialize(self, params, errorDepth)

    self:HookEvent(self, "OnTresChanged", self.UpdateTresText)
    self:HookEvent(self, "OnCreditChanged", self.UpdateTresText)
    self:UpdateTresText()

    self:HookEvent(self, "OnTeamNumberChanged", self.UpdateTresHook)
    self:HookEvent(self, "OnTeamInfoInitialized", self.UpdateTresHook)
    self:UpdateTresHook()
end

function GUIHudTres:UpdateTresText()
    local tres = self:GetTres()
    local credit = math.floor(self:GetCredit())
    if credit > 0 then
        self:GetTextObj():SetText(string.format("%d (^%d)", tres, credit))
    else
        self:GetTextObj():SetText(tostring(tres))
    end
    -- Dynamic width: resize textHolder to match current text
    self.textHolder:SetSize(self:GetTextObj():GetSize())
end

function GUIHudTres:GetMaxWidthText()
    local tres = self:GetTres()
    local credit = math.floor(self:GetCredit())
    if credit > 0 then
        return string.format("%d (^%d)", tres, credit)
    else
        return tostring(tres)
    end
end

function GUIHudTres:UpdateTresHook()

    -- Clear old hooks
    if self.tresHook then
        self:UnHookEventsByCallback(self.tresHook)
    end
    if self.creditHook then
        self:UnHookEventsByCallback(self.creditHook)
    end

    local teamNumber = self:GetTeamNumber()

    -- Hook Tres changes
    self.tresHook = self:HookEvent(GetGlobalEventDispatcher(), string.format("OnTeam%dResourcesChanged", teamNumber), self.SetTres)

    -- Hook Credit changes
    self.creditHook = self:HookEvent(GetGlobalEventDispatcher(), string.format("OnTeam%dCommanderAggressiveCreditChanged", teamNumber), self.SetCredit)

    -- Update immediately
    local teamInfo = GetTeamInfoEntity(self:GetTeamNumber())
    if teamInfo then
        self:SetTres(teamInfo.teamResources)
        self:SetCredit(teamInfo.commanderAggressiveCredit or 0)
    end

end

GUIHudTopBar.AddTopBarClass("GUIHudTres")
