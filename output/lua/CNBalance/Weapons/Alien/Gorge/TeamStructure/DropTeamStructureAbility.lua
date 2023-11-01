
Script.Load("lua/CNBalance/Weapons/Alien/Gorge/TeamStructure/HiveAbility.lua")

class 'DropTeamStructureAbility' (DropStructureAbility)
DropTeamStructureAbility.kSupportedStructures = { HiveStructureAbility }
DropTeamStructureAbility.kMapName = "drop_team_structure_ability"

function DropTeamStructureAbility:GetHUDSlot()
    return 5
end

Shared.LinkClassToMap("DropTeamStructureAbility", DropTeamStructureAbility.kMapName, {})