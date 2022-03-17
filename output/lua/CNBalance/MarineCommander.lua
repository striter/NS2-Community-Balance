
-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\MarineCommander.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- Handled Commander movement and actions.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Commander.lua")
Script.Load("lua/NS2Utility.lua")
Script.Load("lua/MarineCommanderSkinsMixin.lua")


class 'MarineCommander' (Commander)

MarineCommander.kMapName = "marine_commander"

local netVars = {}

AddMixinNetworkVars(MarineCommanderSkinsMixin, netVars)


if Client then
    Script.Load("lua/MarineCommander_Client.lua")
elseif Server then    
    Script.Load("lua/MarineCommander_Server.lua")
end

MarineCommander.kSentryFiringSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/sentry_firing")
MarineCommander.kSentryTakingDamageSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/sentry_taking_damage")
MarineCommander.kSentryLowAmmoSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/sentry_low_ammo")
MarineCommander.kSentryNoAmmoSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/sentry_no_ammo")
MarineCommander.kSoldierLostSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/soldier_lost")
MarineCommander.kSoldierAcknowledgesSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/ack")
MarineCommander.kSoldierNeedsAmmoSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/soldier_needs_ammo")
MarineCommander.kSoldierNeedsHealthSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/soldier_needs_health")
MarineCommander.kSoldierNeedsOrderSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/soldier_needs_order")
MarineCommander.kUpgradeCompleteSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/upgrade_complete")
MarineCommander.kResearchCompleteSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/research_complete")
MarineCommander.kManufactureCompleteSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/all_clear")
MarineCommander.kObjectiveCompletedSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/complete")
MarineCommander.kMACObjectiveCompletedSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/mac/welded")
MarineCommander.kMoveToWaypointSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/move")
MarineCommander.kAttackOrderSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/move")
MarineCommander.kStructureUnderAttackSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/base_under_attack")
MarineCommander.kSoldierUnderAttackSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/soldier_under_attack")
MarineCommander.kBuildStructureSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/build")
MarineCommander.kWeldOrderSound = PrecacheAsset("sound/NS2.fev/marine/structures/mac/weld")
MarineCommander.kDefendTargetSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/defend")
MarineCommander.kCommanderEjectedSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/commander_ejected")
MarineCommander.kCommandStationCompletedSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/online")
MarineCommander.kTriggerNanoShieldSound = PrecacheAsset("sound/NS2.fev/marine/commander/nano_shield")

MarineCommander.kOrderClickedEffect = PrecacheAsset("cinematics/marine/order.cinematic")
MarineCommander.kSelectSound = PrecacheAsset("sound/NS2.fev/marine/commander/select")
MarineCommander.kChatSound = PrecacheAsset("sound/NS2.fev/marine/common/chat")

local kHoverSound = PrecacheAsset("sound/NS2.fev/marine/commander/hover")

function MarineCommander:OnCreate()

    Commander.OnCreate(self)
    
    if Server then 
        
        local mask = bit.bor(kRelevantToReadyRoom, kRelevantToTeam1Unit, kRelevantToTeam1Commander)        
        self:SetExcludeRelevancyMask(mask)    
    
    end

end

function MarineCommander:OnInitialized()

    Commander.OnInitialized(self)

    if not Predict then
        InitMixin(self, MarineCommanderSkinsMixin)
    end

end

function MarineCommander:GetSelectionSound()
    return MarineCommander.kSelectSound
end

function MarineCommander:GetHoverSound()
    return kHoverSound
end

function MarineCommander:GetTeamType()
    return kMarineTeamType
end

function MarineCommander:GetOrderConfirmedEffect()
    return MarineCommander.kOrderClickedEffect
end

function MarineCommander:GetIsInQuickMenu(techId)
    return Commander.GetIsInQuickMenu(self, techId) or techId == kTechId.WeaponsMenu
end


local gMarineMenuButtons =
{

    [kTechId.BuildMenu] = { kTechId.CommandStation, kTechId.Extractor, kTechId.InfantryPortal, kTechId.Armory,
                            kTechId.RoboticsFactory, kTechId.ArmsLab, kTechId.None, kTechId.None },
                            
    [kTechId.AdvancedMenu] = { kTechId.Sentry, kTechId.Observatory, kTechId.PhaseGate, kTechId.PrototypeLab, 
                               kTechId.SentryBattery, kTechId.None, kTechId.None, kTechId.None },

    [kTechId.AssistMenu] = { kTechId.AmmoPack, kTechId.MedPack, kTechId.NanoShield, kTechId.Scan,
                             kTechId.PowerSurge, kTechId.CatPack, kTechId.WeaponsMenu, kTechId.None },
                             
    [kTechId.WeaponsMenu] = { kTechId.DropShotgun, kTechId.DropGrenadeLauncher, kTechId.DropFlamethrower, kTechId.DropHeavyMachineGun,
                              kTechId.DropWelder, kTechId.DropMines, kTechId.ProtosMenu , kTechId.AssistMenu},

    [kTechId.ProtosMenu] = { kTechId.DropJetpack, kTechId.DropExosuit, kTechId.None, kTechId.None,
                                kTechId.None, kTechId.None, kTechId.None, kTechId.WeaponsMenu}

}

local gMarineMenuIds = {}
do
    for menuId, _ in pairs(gMarineMenuButtons) do
        gMarineMenuIds[#gMarineMenuIds+1] = menuId
    end
end

function MarineCommander:GetButtonTable()
    return gMarineMenuButtons
end

function MarineCommander:GetMenuIds()
    return gMarineMenuIds
end

function MarineCommander:GetIsInQuickMenu(techId)
    return Commander.GetIsInQuickMenu(self, techId) or techId == kTechId.WeaponsMenu or techId == ProtosMenu
end

-- Top row always the same. Alien commander can override to replace.
function MarineCommander:GetQuickMenuTechButtons(techId)

    -- Top row always for quick access
    local marineTechButtons = { kTechId.BuildMenu, kTechId.AdvancedMenu, kTechId.AssistMenu, kTechId.RootMenu }
    local menuButtons = gMarineMenuButtons[techId]    
    
    if not menuButtons then
        menuButtons = {kTechId.None, kTechId.None, kTechId.None, kTechId.None, kTechId.None, kTechId.None, kTechId.None, kTechId.None }
    end

    table.copy(menuButtons, marineTechButtons, true)        

    -- Return buttons and true/false if we are in a quick-access menu
    return marineTechButtons
    
end

function MarineCommander:GetChatSound()
    return MarineCommander.kChatSound
end

function MarineCommander:GetPlayerStatusDesc()
    return kPlayerStatus.Commander
end

Shared.LinkClassToMap( "MarineCommander", MarineCommander.kMapName, netVars )