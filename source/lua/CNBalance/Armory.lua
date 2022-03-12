
function Armory:GetItemList()

    local itemList =
    {
        kTechId.Rifle,
        kTechId.Pistol,
        kTechId.Axe,

        kTechId.Welder,
        kTechId.LayMines,
        
        kTechId.Shotgun,

        kTechId.ClusterGrenade,
        kTechId.GasGrenade,
        kTechId.PulseGrenade
    }

    if self:GetTechId() == kTechId.AdvancedArmory then

        itemList =
        {
            kTechId.Rifle,
            kTechId.Pistol,
            kTechId.Axe,

            kTechId.Welder,
            kTechId.LayMines,
            kTechId.Shotgun,
            kTechId.GrenadeLauncher,
            kTechId.Flamethrower,
            kTechId.HeavyMachineGun,
            kTechId.ClusterGrenade,
            kTechId.GasGrenade,
            kTechId.PulseGrenade,
        }

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
    elseif GetHasTech(self,kTechId.StandardSupply) then
        
        techButtons[3] = kTechId.PistolAxeUpgrade

        if GetHasTech(self,kTechId.PistolAxeUpgrade) then
            techButtons[3] = kTechId.RifleUpgrade
        end

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