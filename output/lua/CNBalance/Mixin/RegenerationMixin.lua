-- ======= Copyright (c) 2003-2016, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\RegenerationMixin.lua
--
--    Created by:   Sebastian Schuck (sebastian@naturalselection2.com)
--
--    Mixin that can be used to apply regeneration to a unit
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

RegenerationMixin = CreateMixin(RegenerationMixin)
RegenerationMixin.type = "Regeneration"

RegenerationMixin.expectedMixins =
{
	Live = "Required to change health."
}

RegenerationMixin.networkVars = {
	regenerating = "boolean",

	regenerationHealth = string.format("float (0 to %f by 0.0625)", LiveMixin.kMaxHealth)
}

function RegenerationMixin:__initmixin()
    
    PROFILE("RegenerationMixin:__initmixin")
    
	if Server then
		self.regenerating = false
		self.regenerationHealth = 0

		self.regenerationValue = kMarineRegenerationHeal
	end
end

if Server then
	function RegenerationMixin:AddRegeneration(value)
		local max = self:GetMaxHealth() - self:GetHealth()


		self.regenerationHealth = math.min(self.regenerationHealth + value, max)

		self.regenerating = true
	end

	function RegenerationMixin:OnProcessMove(input)
		if not self.regenerating then return end

		local deltaTime = input.time

		local amount = deltaTime * self.regenerationValue

		self.regenerationHealth = math.max(self.regenerationHealth - amount, 0)

		--returns false if entity is allready fully healed
		if self.regenerationHealth == 0 or not self:Heal(amount) then
			self.regenerating = false
			self.regenerationHealth = 0
		end
	end
end

function RegenerationMixin:GetRegeneratingHealth()
	return self.regenerationHealth
end

function RegenerationMixin:GetIsRegenerating()
	return self.regenerating
end

function RegenerationMixin:GetRegenerationFraction()
	local max = self:GetMaxHealth()

	return math.min((self:GetHealth() + self:GetRegeneratingHealth()) / max, 1)
end


