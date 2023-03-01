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

local function IsSupplyTech(techId)
    return techId == kTechId.StandardSupply or 
    kTechId == kTechId.ExplosiveSupply
end

function Armory:GetSupplyUnavailable()
    local researched=GetHasTech(self,kTechId.StandardSupply) or 
    GetHasTech(self,kTechId.ExplosiveSupply)

    if researched then
        return true
    end

    local researching = GetIsTechResearching(self,kTechId.StandardSupply) or
    GetIsTechResearching(self,kTechId.ExplosiveSupply)
    return researching
end

function Armory:GetTechButtons(techId)

    local techButtons = 
    {
        kTechId.ShotgunTech,kTechId.MinesTech, kTechId.GrenadeTech, kTechId.CombatBuilderTech, 
        kTechId.None, kTechId.None, kTechId.None, kTechId.None 
    }
    
    -- Show button to upgraded to advanced armory
    local advancedArmory = self:GetTechId() == kTechId.AdvancedArmory
    if not advancedArmory then
        techButtons[5] = kTechId.AdvancedArmoryUpgrade
    else
        local supplyAvailable = self:GetSupplyUnavailable()
        if not supplyAvailable then
            techButtons[5] = kTechId.StandardSupply
            techButtons[6] = kTechId.ExplosiveSupply
        end

        if GetHasTech(self,kTechId.ExplosiveSupply)  then
            techButtons[5] = kTechId.MinesUpgrade
            techButtons[6] = kTechId.GrenadeLauncherDetectionShot
            techButtons[7] = kTechId.GrenadeLauncherAllyBlast

            if GetHasTech(self,kTechId.GrenadeLauncherAllyBlast) then
                techButtons[7] = kTechId.GrenadeLauncherUpgrade
            end
        elseif GetHasTech(self,kTechId.StandardSupply) then

            techButtons[5] = kTechId.DragonBreath
            techButtons[6] = kTechId.LightMachineGunUpgrade
            techButtons[7] = kTechId.CannonTech
        end
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