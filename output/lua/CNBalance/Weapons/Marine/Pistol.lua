function Pistol:GetCatalystSpeedBase()
    local speed = 1   

    if GetHasTech(self,kTechId.PistolAxeUpgrade)  then
        speed = 1.5
    end

    return speed
end
