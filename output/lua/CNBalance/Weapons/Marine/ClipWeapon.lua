function ClipWeapon:GetAmmoPercent()
	return math.ceil(self.clip / self:GetClipSize() * 100), math.ceil(self.ammo / self:GetMaxAmmo() * 100)
end

function ClipWeapon:SetAmmoPercent(newClipPercent, newAmmoPercent)

	self.clip = math.round(self:GetClipSize() * newClipPercent / 100)
	self.ammo = math.round(self:GetMaxAmmo() * newAmmoPercent / 100)
	
end