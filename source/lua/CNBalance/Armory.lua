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
    kTechId == kTechId.KinematicSupply or 
    kTechId == kTechId.ExplosiveSupply
end

function Armory:GetSupplyUnavailable()
    local researched=GetHasTech(self,kTechId.StandardSupply) or 
    GetHasTech(self,kTechId.KinematicSupply) or
    GetHasTech(self,kTechId.ExplosiveSupply)

    if researched then
        return true
    end

    local researching = GetIsTechResearching(self,kTechId.StandardSupply) or
    GetIsTechResearching(self,kTechId.KinematicSupply) or
    GetIsTechResearching(self,kTechId.ExplosiveSupply)
    return researching
end

function Armory:GetTechButtons(techId)

    local techButtons = 
    {
        kTechId.ShotgunTech,kTechId.None, kTechId.None, kTechId.None, 
        kTechId.None, kTechId.MinesTech, kTechId.GrenadeTech, kTechId.None 
    }
    

    local advancedArmory = self:GetTechId() == kTechId.AdvancedArmory
    local supplyAvailable = self:GetSupplyUnavailable()
    if not supplyAvailable then
        techButtons[2] = kTechId.StandardSupply
        techButtons[3] = kTechId.KinematicSupply
        techButtons[4] = kTechId.ExplosiveSupply
    end

    if GetHasTech(self,kTechId.ExplosiveSupply)  then
        techButtons[2] = kTechId.MinesUpgrade
        techButtons[3] = kTechId.GrenadeLauncherDetectionShot
        techButtons[4] = kTechId.GrenadeLauncherAllyBlast

        if GetHasTech(self,kTechId.GrenadeLauncherAllyBlast) then
            techButtons[4] = kTechId.GrenadeLauncherUpgrade
        end
    elseif GetHasTech(self,kTechId.KinematicSupply) then
        techButtons[2] = kTechId.DragonBreath
        techButtons[3] = kTechId.CannonTech
    elseif GetHasTech(self,kTechId.StandardSupply) then
        
        techButtons[2] = kTechId.AxeUpgrade
        techButtons[3] = kTechId.LightMachineGunUpgrade
    end

    -- Show button to upgraded to advanced armory
    if not advancedArmory then
        techButtons[5] = kTechId.AdvancedArmoryUpgrade
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