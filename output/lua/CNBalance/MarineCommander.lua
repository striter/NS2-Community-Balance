
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

local gMarineMenuButtons =
{
    [kTechId.BuildMenu] = { kTechId.CommandStation, kTechId.Extractor, kTechId.InfantryPortal, kTechId.Armory,
                            kTechId.RoboticsFactory, kTechId.ArmsLab, kTechId.None, kTechId.None },
                            
    [kTechId.AdvancedMenu] = { kTechId.Sentry, kTechId.Observatory, kTechId.PhaseGate, kTechId.PrototypeLab, 
                               kTechId.SentryBattery, kTechId.MineDeploy, kTechId.None, kTechId.None },

    [kTechId.AssistMenu] = { kTechId.AmmoPack, kTechId.MedPack, kTechId.NanoShield, kTechId.Scan,
                             kTechId.PowerSurge, kTechId.CatPack, kTechId.WeaponsMenu, kTechId.ProtosMenu },
                             
    [kTechId.WeaponsMenu] = { kTechId.DropShotgun, kTechId.DropGrenadeLauncher, kTechId.DropFlamethrower, kTechId.DropHeavyMachineGun,
                              kTechId.DropWelder ,kTechId.DropMines, kTechId.DropCombatBuilder,  kTechId.AssistMenu},
    
    [kTechId.ProtosMenu] = { kTechId.DropJetpack, kTechId.DropDualMinigunExosuit, kTechId.DropDualRailgunExosuit, kTechId.None,
                                kTechId.DropCannon, kTechId.None, kTechId.None, kTechId.AssistMenu}
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
    return Commander.GetIsInQuickMenu(self, techId) or techId == kTechId.WeaponsMenu or techId == kTechId.ProtosMenu
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

if Server then

    local function GetIsDroppack(techId)
        return techId == kTechId.MedPack or techId == kTechId.AmmoPack or techId == kTechId.CatPack
    end
    
    local function GetIsEquipment(techId)

        return techId == kTechId.DropWelder or techId == kTechId.DropMines or techId == kTechId.DropShotgun or techId == kTechId.DropHeavyMachineGun or techId == kTechId.DropGrenadeLauncher or
                techId == kTechId.DropFlamethrower or techId == kTechId.DropJetpack or techId == kTechId.DropExosuit
        or techId == kTechId.DropCombatBuilder or techId == kTechId.DropCannon or techId == kTechId.DropDualMinigunExosuit or techId == kTechId.DropDualRailgunExosuit

    end

    -- check if a notification should be send for successful actions
    function MarineCommander:ProcessTechTreeActionForEntity(techNode, position, normal, pickVec, orientation, entity, trace, targetId)

        local techId = techNode:GetTechId()
        local success = false
        local keepProcessing = false

        if techId == kTechId.Scan then

            success = self:TriggerScan(position, trace)
            keepProcessing = false

        elseif techId == kTechId.SelectObservatory then

            SelectNearest(self, "Observatory")

        elseif techId == kTechId.NanoShield then

            success = self:TriggerNanoShield(position)
            keepProcessing = false

        elseif techId == kTechId.PowerSurge then

            success = self:TriggerPowerSurge(position, entity, trace)
            keepProcessing = false

        elseif GetIsDroppack(techId) then

            -- use the client side trace.entity here
            local clientTargetEnt = Shared.GetEntity(targetId)
            if clientTargetEnt and ( clientTargetEnt:isa("Marine") or ( techId == kTechId.CatPack and clientTargetEnt:isa("Exo") ) ) then
                position = clientTargetEnt:GetOrigin() + Vector(0, 0.05, 0)
            end

            success = self:TriggerDropPack(position, techId)
            keepProcessing = false

        elseif GetIsEquipment(techId) or techId == kTechId.MineDeploy then

            success = self:AttemptToBuild(techId, position, normal, orientation, pickVec, false, entity)

            if success then
                self:TriggerEffects("spawn_weapon", { effecthostcoords = Coords.GetTranslation(position) })
            end

            keepProcessing = false
        else

            return Commander.ProcessTechTreeActionForEntity(self, techNode, position, normal, pickVec, orientation, entity, trace, targetId)

        end

        if success then

            self:ProcessSuccessAction(techId)

        end

        return success, keepProcessing

    end

end 