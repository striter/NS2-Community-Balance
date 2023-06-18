local oldArmoryGetItemList = Armory.GetItemList
function Armory:GetItemList(forPlayer)
    local itemList = oldArmoryGetItemList(self, forPlayer)
    table.insert(itemList, kTechId.Knife)
    table.insert(itemList, kTechId.Revolver)
    table.insert(itemList, kTechId.SubMachineGun)
    table.insert(itemList, kTechId.LightMachineGun)
    table.insert(itemList, kTechId.Cannon)
    table.insert(itemList, kTechId.CombatBuilder)
	return itemList
end

local oldAdvancedArmoryGetItemList = AdvancedArmory.GetItemList
function AdvancedArmory:GetItemList(forPlayer)
    local itemList = oldAdvancedArmoryGetItemList(self, forPlayer)
	if self:GetTechId() == kTechId.AdvancedArmory then
        table.insert(itemList, kTechId.Knife)
        table.insert(itemList, kTechId.Revolver)
        table.insert(itemList, kTechId.SubMachineGun)
        table.insert(itemList, kTechId.LightMachineGun)
        table.insert(itemList, kTechId.Cannon)
        table.insert(itemList, kTechId.CombatBuilder)
    end
	return itemList
end

function Armory:GetTechButtons(techId)

    local techButtons = 
    {
        kTechId.ShotgunTech,kTechId.None, kTechId.None, kTechId.None,
        kTechId.MinesTech, kTechId.GrenadeTech, kTechId.None, kTechId.None 
    }
    
    -- Show button to upgraded to advanced armory
    local advancedArmory = self:GetTechId() == kTechId.AdvancedArmory
    if not advancedArmory then
        techButtons[4] = kTechId.AdvancedArmoryUpgrade
    else
        techButtons[2] = kTechId.GrenadeLauncherUpgrade
        techButtons[7] = kTechId.CombatBuilderTech
    end
    
    return techButtons

end

function Armory:GetTechAllowed(techId, techNode, player)

    local allowed, canAfford = ScriptActor.GetTechAllowed(self, techId, techNode, player)

    if techId == kTechId.HeavyRifleTech then
        allowed = allowed and self:GetTechId() == kTechId.AdvancedArmory
    end

    return allowed, canAfford

end