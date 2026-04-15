local helpScreenImages = {
    metabolize          = PrecacheAsset("ui/helpScreen/icons/metabolize.dds"),
}

local function EvaluateTechAvailability(techId, requirementMessage)

    local player = Client.GetLocalPlayer()
    if GetIsTechUnlocked(player, techId) then
        return true, ""
    else
        local biomassRequirement = GetRequiresBiomass(techId)

        if biomassRequirement == nil then
            return false, requirementMessage
        end

        local techId = kTechToBiomassLevel[biomassRequirement]
        local techTree = GetTechTree()
        local techNode = techTree:GetTechNode(techId)
        if techNode:GetHasTech() then
            return false, requirementMessage
        else
            return false, kBioMassLevelToHelpText[biomassRequirement]
        end
    end

end

local baseHelpScreen_InitializeContent = HelpScreen_InitializeContent
function HelpScreen_InitializeContent()
    baseHelpScreen_InitializeContent()
    
    HelpScreen_AddContent({
        name = "Devour",
        title = "HELP_SCREEN_DEVOUR",
        description = "HELP_SCREEN_DEVOUR_DESCRIPTION",
        imagePath = nil,
        actions = {
            { "Weapon3", },
            { "PrimaryAttack", },
        },
        classNames = {"Onos"},
        theme = "alien",
        useLocale = true,
    })
    
    --Prowler
    HelpScreen_AddContent({
        name = "Volley",
        title = "HELP_SCREEN_VOLLEY",
        description = "HELP_SCREEN_VOLLEY_DESCRIPTION",
        imagePath = nil,
        actions = {
            { "PrimaryAttack", },
        },
        classNames = {"Prowler"},
        theme = "alien",
        useLocale = true,
    })
    HelpScreen_AddContent({
        name = "Rappel",
        title = "HELP_SCREEN_RAPPEL",
        description = "HELP_SCREEN_RAPPEL_DESCRIPTION",
        imagePath = nil,
        actions = {
            { "SecondaryAttack", },
        },
        classNames = {"Prowler"},
        theme = "alien",
        useLocale = true,
    })
    HelpScreen_AddContent({
        name = "Reel",
        title = "HELP_SCREEN_REEL",
        description = "HELP_SCREEN_REEL_DESCRIPTION",
        imagePath = nil,
        actions = {
            { "MovementModifier", },
            { "SecondaryAttack", },
        },
        classNames = {"Prowler"},
        theme = "alien",
        useLocale = true,
    })
    HelpScreen_AddContent({
        name = "ProwlerWeb",
        title = "HELP_SCREEN_PROWLER_WEB",
        description = "HELP_SCREEN_PROWLER_WEB_DESCRIPTION",
        imagePath = nil,
        actions = {
            { "Weapon2", },
            { "PrimaryAttack", },
        },
        classNames = {"Prowler"},
        theme = "alien",
        useLocale = true,
    })
    HelpScreen_AddContent({
        name = "AcidSpray",
        title = "HELP_SCREEN_ACIDSPRAY",
        description = "HELP_SCREEN_ACIDSPRAY_DESCRIPTION",
        --requirementFunction = function()
        --    local result, msg = EvaluateTechAvailability(kTechId.AcidSpray, "HELP_SCREEN_ACIDSPRAY_REQUIREMENT")
        --    return result, msg
        --end,
        imagePath = nil,
        actions = {
            { "Weapon3", },
            { "PrimaryAttack", },
        },
        classNames = {"Prowler"},
        theme = "alien",
        useLocale = true,
    })
    
    --Vokex
    HelpScreen_AddContent({
        name = "ShadowStepSwipe",
        title = "HELP_SCREEN_SWIPE",
        description = "HELP_SCREEN_SWIPE_DESCRIPTION",
        actions = {
            { "Weapon1", },
            { "PrimaryAttack", },
        },
        classNames = {"Vokex"},
        theme = "alien",
        useLocale = true,
    })
    HelpScreen_AddContent({
        name = "ShadowStep",
        title = "HELP_SCREEN_SHADOWSTEP",
        description = "HELP_SCREEN_SHADOWSTEP_DESCRIPTION",
        actions = {
            { "SecondaryAttack", },
        },
        classNames = {"Vokex"},
        theme = "alien",
        useLocale = true,
    })
    HelpScreen_AddContent({
        name = "ShadowStepJump",
        title = "HELP_SCREEN_SHADOWSTEP_JUMP",
        description = "HELP_SCREEN_SHADOWSTEP_JUMP_DESCRIPTION",
        actions = {
            { "Jump" },
            { "Jump" },
        },
        classNames = {"Vokex"},
        theme = "alien",
        useLocale = true,
    })
    HelpScreen_ReplaceContent({
        name = "Metabolize",
        title = "HELP_SCREEN_METABOLIZE",
        --requirementFunction = function()
        --    local result, msg = EvaluateTechAvailability(kTechId.MetabolizeEnergy, "HELP_SCREEN_METABOLIZE_REQUIREMENT")
        --    return result, msg
        --end,
        description = "HELP_SCREEN_METABOLIZE_DESCRIPTION",
        imagePath = helpScreenImages.metabolize,
        actions = {
            { "MovementModifier", },
        },
        classNames = {"Vokex","Fade"},
        theme = "alien",
        useLocale = true,
    })
    HelpScreen_AddContent({
        name = "AcidRocket",
        title = "HELP_SCREEN_ACIDROCKET",
        description = "HELP_SCREEN_ACIDROCKET_DESCRIPTION",
        imagePath = nil,
        --requirementFunction = function()
        --    local result, msg = EvaluateTechAvailability(kTechId.AcidRocket, "HELP_SCREEN_ACIDROCKET_REQUIREMENT")
        --    return result, msg
        --end,
        actions = {
            { "Weapon3", },
            { "PrimaryAttack", },
        },
        classNames = {"Vokex"},
        theme = "alien",
        useLocale = true,
    })
    HelpScreen_AddContent({
        name = "Vortex",
        title = "HELP_SCREEN_VORTEX",
        description = "HELP_SCREEN_VORTEX_DESCRIPTION",
        imagePath = nil,
        --requirementFunction = function()
        --    local result, msg = EvaluateTechAvailability(kTechId.Vortex, "HELP_SCREEN_VORTEX_REQUIREMENT")
        --    return result, msg
        --end,
        actions = {
            { "Weapon4", },
            { "PrimaryAttack", },
        },
        classNames = {"Vokex"},
        theme = "alien",
        useLocale = true,
    })
end


