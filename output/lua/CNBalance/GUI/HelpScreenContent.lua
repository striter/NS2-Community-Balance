local helpScreenImages = {
    bite                = PrecacheAsset("ui/helpScreen/icons/bite.dds"),
    parasite            = PrecacheAsset("ui/helpScreen/icons/parasite.dds"),
    rifle               = PrecacheAsset("ui/helpScreen/icons/rifle.dds"),
    rifleButt           = PrecacheAsset("ui/helpScreen/icons/rifle_butt.dds"),
}

local baseHelpScreen_InitializeContent = HelpScreen_InitializeContent
function HelpScreen_InitializeContent()
    baseHelpScreen_InitializeContent()
    
    --HelpScreen_AddContent({
    --    name = "Devour",
    --    title = "HELP_SCREEN_DEVOUR",
    --    description = "HELP_SCREEN_DEVOUR_DESCRIPTION",
    --    imagePath = helpScreenImages.bite,
    --    actions = {
    --        { "Weapon3", },
    --        { "PrimaryAttack", },
    --    },
    --    classNames = {"Onos"},
    --    theme = "alien",
    --    useLocale = true,
    --})
end


