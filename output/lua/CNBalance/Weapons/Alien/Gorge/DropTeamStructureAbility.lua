Script.Load("lua/Weapons/Alien/DropStructureAbility.lua")
Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/WhipAbility.lua")
Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/ShadeAbility.lua")
Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/ShiftAbility.lua")
Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/CragAbility.lua")
Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/EggAbility.lua")
Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/SpurAbility.lua")
Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/VeilAbility.lua")
Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/ShellAbility.lua")
Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/TunnelEntranceAbility.lua")
Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/TunnelExitAbility.lua")
Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/CystAbility.lua")

Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AttachStructure/AttachStructureAbility.lua")
Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AttachStructure/ShadeHiveAbility.lua")
Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AttachStructure/CragHiveAbility.lua")
Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AttachStructure/ShiftHiveAbility.lua")
Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AttachStructure/HarvesterAbility.lua")

class 'DropTeamStructureAbility' (DropStructureAbility)
DropStructureAbility.kSupportedStructures[kTechId.Harvester] = HarvesterAbility
DropStructureAbility.kSupportedStructures[kTechId.ShiftHive] = ShiftHiveAbility
DropStructureAbility.kSupportedStructures[kTechId.ShadeHive] = ShadeHiveAbility
DropStructureAbility.kSupportedStructures[kTechId.CragHive] = CragHiveAbility
DropStructureAbility.kSupportedStructures[kTechId.Cyst] = CystAbility

DropStructureAbility.kSupportedStructures[kTechId.BuildMenu] = AttachStructureAbility
DropStructureAbility.kSupportedStructures[kTechId.AdvancedMenu] = AttachStructureAbility

DropStructureAbility.kSupportedStructures[kTechId.Veil] = VeilAbility
DropStructureAbility.kSupportedStructures[kTechId.Spur] = SpurAbility
DropStructureAbility.kSupportedStructures[kTechId.Shell] = ShellAbility

DropStructureAbility.kSupportedStructures[kTechId.Whip] = WhipAbility
DropStructureAbility.kSupportedStructures[kTechId.Shift] = ShiftAbility
DropStructureAbility.kSupportedStructures[kTechId.Crag] = CragAbility
DropStructureAbility.kSupportedStructures[kTechId.Shade] = ShadeAbility
DropStructureAbility.kSupportedStructures[kTechId.Egg] = EggAbility
DropStructureAbility.kSupportedStructures[kTechId.Tunnel] = TunnelEntranceAbility
DropStructureAbility.kSupportedStructures[kTechId.TunnelExit] = TunnelExitAbility

local networkVars =
{
    entranceDropped = "private boolean",
    exitDropped = "private boolean",
}

DropTeamStructureAbility.kMapName = "drop_team_structure_ability"

if Client then
    function DropTeamStructureAbility:OnDraw(player, previousWeaponMapName)
        DropStructureAbility.OnDraw(self,player,previousWeaponMapName)
        self.menu = nil
    end

    function DropTeamStructureAbility:OnHolsterClient()

        DropStructureAbility.OnHolsterClient(self)
        self.menu = nil
    end
    
    local function GetTechChosen(_localPlayer ,_techId)
        
        local entityTeamNumber = HasMixin(_localPlayer, "Team") and _localPlayer:GetTeamNumber() or kTeamInvalid
        local techTree = GetTechTree(entityTeamNumber)
        if techTree then
            local techNode = techTree:GetTechNode(_techId)
            local progress = techNode:GetResearchProgress()
            if progress ~= 0 and progress ~= 1 then
                progressing = true
                return true
            end
            return techNode:GetHasTech()
        end
        return false
    end
    
    function DropTeamStructureAbility:GetAvailableStructureTechIds()
        local originform = GetHasTech(self,kTechId.OriginForm)
        if not originform then
            return { kTechId.Cyst ,kTechId.Egg }
        end
        
        if not self.menu then
            return { kTechId.Cyst ,kTechId.Egg,kTechId.Tunnel,kTechId.TunnelExit,kTechId.BuildMenu }
        elseif self.menu == kTechId.BuildMenu then
            return { kTechId.Whip ,kTechId.Shift,kTechId.Shade,kTechId.Crag, kTechId.AdvancedMenu }
        else
            local localPlayer = Client.GetLocalPlayer()
            local advancedTable ={ kTechId.Harvester ,kTechId.ShiftHive, kTechId.ShadeHive, kTechId.CragHive }
            if localPlayer then
                if GetTechChosen(localPlayer, kTechId.ShiftHive) then
                    advancedTable[2] = kTechId.Spur
                end
                
                if GetTechChosen(localPlayer, kTechId.ShadeHive) then
                    advancedTable[3] = kTechId.Veil
                end
                
                if GetTechChosen(localPlayer, kTechId.CragHive)  then
                    advancedTable[4] = kTechId.Shell
                end
            end

            return advancedTable
        end
    end
end

function DropTeamStructureAbility:GetHUDSlot()
    return 5
end

function DropTeamStructureAbility:SetActiveStructure(_structureTechId)
    if _structureTechId == kTechId.BuildMenu
        or _structureTechId == kTechId.AdvancedMenu
    then
        self.menu = _structureTechId
        return false
    end

    self.menu = nil
    return DropStructureAbility.SetActiveStructure(self, _structureTechId)
end

if Client then

    function DropTeamStructureAbility:GetHUDText(_structureId)
        return Locale.ResolveString(LookupTechData(_structureId,kTechDataDisplayName)),.7
    end
end

function DropTeamStructureAbility:GetNumStructuresBuilt(techId)

    if techId == kTechId.Tunnel then
        return self.entranceDropped and 1 or 0
    end

    if techId == kTechId.TunnelExit then
        return self.exitDropped and 1 or 0
    end

    -- unlimited
    return -1
end


function DropTeamStructureAbility:ProcessMoveOnWeapon(input)

    local player = self:GetParent()
    if player and player:GetIsAlive() then

        if Server then

            local team = player:GetTeam()
            self.entranceDropped = team:GetNumDroppedGorgeStructures(player, kTechId.Tunnel) > 0
            self.exitDropped = team:GetNumDroppedGorgeStructures(player, kTechId.TunnelExit) > 0
        end

    end

end


function DropTeamStructureAbility:GetNumStructuresCanDrop(techId,biomassLevel)

    if techId == kTechId.Tunnel then
        return TunnelEntranceAbility.GetMaxStructures(nil,biomassLevel)
    end

    if techId == kTechId.TunnelExit then
        return TunnelExitAbility.GetMaxStructures(nil,biomassLevel)
    end

    -- unlimited
    return -1
end
Shared.LinkClassToMap("DropTeamStructureAbility", DropTeamStructureAbility.kMapName, networkVars)