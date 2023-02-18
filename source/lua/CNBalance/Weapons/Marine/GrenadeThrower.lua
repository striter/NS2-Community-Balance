--kMaxHandGrenades = 2
--
--function GrenadeThrower:OnCreate()
--
--    Weapon.OnCreate(self)
--
--    self.pinPulled = false
------
--    self.grenadesLeft = GetHasTech(self,kTechId.GrenadeTech) and kMaxHandGrenades or 1
-----
--    self.isQuickThrown = false
--    self.tertiaryButtonPressed = false
--    self.primaryButtonPressed = false
--    self.heldThrow = false
--    self.deployed = false
--
--    self:SetModel(self:GetThirdPersonModelName())
--end

function GrenadeThrower:GetCatalystSpeedBase()
    return GetHasTech(self,kTechId.GrenadeTech) and 2 or 1        --Speeed boost
end
