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

	regenerationHealth = string.format("float (0 to %f by 0.0625)", LiveMixin.kMaxHealth),

	timeLastAutoAmmoPack = "private time",
	timeLastAutoMedPack = "private time",
}

function RegenerationMixin:__initmixin()
    
    PROFILE("RegenerationMixin:__initmixin")
	timeLastAutoAmmoPack = -kAutoAmmoCooldown
	timeLastAutoMedPack = -kAutoMedCooldown
	
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
	
	RegenerationMixin.kPickupDelay = 0.5
	local kAlertHandleDelay = 0.75
	function RegenerationMixin:MedSelf()
		local time = Shared.GetTime()
		if time - self.timeLastAutoMedPack < kAutoMedCooldown then return end
		
		if not MedPack.GetIsValidRecipient(self,self) then return end
		if self:GetResources() < kAutoMedPRes then return end
		
		self.timeLastAutoMedPack = time
		self:AddResources(-kAutoMedPRes)

		self:AddHealth(MedPack.kHealth, false, true)
		self:AddRegeneration(MedPack.kRegen)
		self:TriggerEffects("medpack_pickup", { effecthostcoords = self:GetCoords() })
	end

	function RegenerationMixin:AmmoSelf()
		local time = Shared.GetTime()
		if time - self.timeLastAutoAmmoPack < kAutoAmmoCooldown then return end

		if not AmmoPack.GetIsValidRecipient(self,self) then return end
		if self:GetResources() < kAutoAmmoPRes then return end
		self:AddResources(-kAutoAmmoPRes)
		self.timeLastAutoAmmoPack = time

		for i = 0, self:GetNumChildren() - 1 do
			local child = self:GetChildAtIndex(i)
			if child:isa("ClipWeapon") then
				if child:GiveAmmo(AmmoPack.kNumClips, false) then
					consumedPack = true
				end
			end
		end

		self:TriggerEffects("ammopack_pickup", { effecthostcoords = self:GetCoords()})
	end

	function RegenerationMixin:HandleAlert(techId)

		if techId == kTechId.MarineAlertNeedMedpack then
			self:AddTimedCallback(self.MedSelf,kAlertHandleDelay)
			return true
		end

		if techId == kTechId.MarineAlertNeedAmmo then
			self:AddTimedCallback(self.AmmoSelf,kAlertHandleDelay)
			return true
		end

		return false
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


