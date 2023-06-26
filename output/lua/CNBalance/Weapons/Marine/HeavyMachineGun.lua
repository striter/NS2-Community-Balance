HeavyMachineGun.kReloadAnimationLength = 5.0 -- from art asset.
HeavyMachineGun.kReloadLength = 3.5 -- desired reload time.
HeavyMachineGun.kBaseReloadMultipier = HeavyMachineGun.kReloadAnimationLength / HeavyMachineGun.kReloadLength


if Client then
    function HeavyMachineGun:GetUIDisplaySettings()
        return { xSize = 256, ySize = 160, script = "lua/CNBalance/GUI/GUIHeavyMachineGunDisplay.lua", variant = self:GetHMGVariant() }
    end

end