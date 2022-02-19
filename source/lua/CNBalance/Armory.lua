
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

local function IsWeaponSupplyTech(techId)
    return techId == kTechId.ShotgunSupply or 
    kTechId == kTechId.FlamethrowerSupply or 
    kTechId == kTechId.GrenadeLauncherSupply or 
    kTechId== kTechId.HeavyMachineGunSupply or
    kTechId== kTechId.MinesSupply
end

function Armory:GetWeaponSupplyUnavailable()
    local researched=GetHasTech(self,kTechId.ShotgunSupply) or 
    GetHasTech(self,kTechId.FlamethrowerSupply) or
    GetHasTech(self,kTechId.GrenadeLauncherSupply) or 
    GetHasTech(self,kTechId.HeavyMachineGunSupply) or
    GetHasTech(self,kTechId.MinesSupply)

    if researched then
        return true
    end

    local researching = GetIsTechResearching(self,kTechId.ShotgunSupply) or
    GetIsTechResearching(self,kTechId.FlamethrowerSupply) or
    GetIsTechResearching(self,kTechId.GrenadeLauncherSupply) or
    GetIsTechResearching(self,kTechId.HeavyMachineGunSupply) or
    GetIsTechResearching(self,kTechId.MinesSupply)
    return researching
end

function Armory:GetTechButtons(techId)

    local techButtons = 
    {
        kTechId.ShotgunTech,kTechId.None, kTechId.None, kTechId.None, 
        kTechId.None, kTechId.MinesTech, kTechId.GrenadeTech, kTechId.None 
    }
    
    local advancedArmory = self:GetTechId() == kTechId.AdvancedArmory
    -- Show button to upgraded to advanced armory
    if self:GetTechId() == kTechId.Armory and not advancedArmory then
        techButtons[5] = kTechId.AdvancedArmoryUpgrade
    else
        if GetHasTech(self,kTechId.GrenadeLauncherSupply)  then
            techButtons[3] = kTechId.GrenadeLauncherImpactShot
            techButtons[4] =  kTechId.GrenadeLauncherAllyBlast

            if GetHasTech(self,kTechId.GrenadeLauncherImpactShot) then
                techButtons[3] = kTechId.GrenadeLauncherDetectionShot
            end
            if GetHasTech(self,kTechId.GrenadeLauncherAllyBlast) then
                techButtons[4] = kTechId.GrenadeLauncherUpgrade
            end
        end
    end


    local weaponSupplyUnavailable = self:GetWeaponSupplyUnavailable()
    if not weaponSupplyUnavailable then
        if GetHasTech(self,kTechId.ShotgunTech) then
            -- techButtons[1] = kTechId.ShotgunSupply
        end

        if advancedArmory then
            -- techButtons[2] = kTechId.FlamethrowerSupply
            techButtons[3] = kTechId.GrenadeLauncherSupply
            -- techButtons[4] = kTechId.HeavyMachineGunSupply
        end

        if GetHasTech(self,kTechId.MinesTech)  then
            -- techButtons[6] = kTechId.MinesSupply
        end
    end


    return techButtons

end

function Armory:GetTechAllowed(techId, techNode, player)

    local allowed, canAfford = ScriptActor.GetTechAllowed(self, techId, techNode, player)

    -- if  IsWeaponSupplyTech(techId) and self:GetWeaponSupplyUnavailable() then
    --     allowed = false
    -- end
    
    if techId == kTechId.HeavyRifleTech then
        allowed = allowed and self:GetTechId() == kTechId.AdvancedArmory
    end

    return allowed, canAfford

end