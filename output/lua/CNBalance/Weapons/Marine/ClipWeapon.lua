function ClipWeapon:GetAmmoPercent()
	return math.ceil(self.clip / self:GetClipSize() * 100), math.ceil(self.ammo / self:GetMaxAmmo() * 100)
end

function ClipWeapon:SetAmmoPercent(newClipPercent, newAmmoPercent)

	self.clip = math.round(self:GetClipSize() * newClipPercent / 100)
	self.ammo = math.round(self:GetMaxAmmo() * newAmmoPercent / 100)
	
end

function ClipWeapon:OnFireBullets(direction)

end
function ClipWeapon:OnBulletFirstHit(direction,endPoint)
	
end


local function FireBullets(self, player)

	PROFILE("FireBullets")

	local viewAngles = player:GetViewAngles()
	local shootCoords = viewAngles:GetCoords()

	-- Filter ourself out of the trace so that we don't hit ourselves.
	local filter = EntityFilterTwo(player, self)
	local range = self:GetRange()

	local numberBullets = self:GetBulletsPerShot()
	local startPoint = player:GetEyePos()
	local bulletSize = self:GetBulletSize()

	self:OnFireBullets(shootCoords)
	for bullet = 1, numberBullets do

		local spreadDirection = self:CalculateSpreadDirection(shootCoords, player)

		local endPoint = startPoint + spreadDirection * range
		local targets, trace, hitPoints = GetBulletTargets(startPoint, endPoint, spreadDirection, bulletSize, filter)
		local damage = self:GetBulletDamage()

		HandleHitregAnalysis(player, startPoint, endPoint, trace)

		local direction = (trace.endPoint - startPoint):GetUnit()
		local hitOffset = direction * kHitEffectOffset
		local impactPoint = trace.endPoint - hitOffset
		local effectFrequency = self:GetTracerEffectFrequency()
		local showTracer = math.random() < effectFrequency

		local numTargets = #targets

		if numTargets == 0 then
			self:OnBulletFirstHit(spreadDirection,impactPoint,nil)
			self:ApplyBulletGameplayEffects(player, nil, impactPoint, direction, 0, trace.surface, showTracer)
		end

		if Client and showTracer then
			TriggerFirstPersonTracer(self, impactPoint)
		end

		for i = 1, numTargets do

			local target = targets[i]
			local hitPoint = hitPoints[i]

			local targetHitPoint = hitPoint - hitOffset
			if i==1 then
				self:OnBulletFirstHit(spreadDirection,targetHitPoint,target)
			end
			
			self:ApplyBulletGameplayEffects(player, target, targetHitPoint, direction, damage, "", showTracer and i == numTargets)

			local client = Server and player:GetClient() or Client
			if not Shared.GetIsRunningPrediction() and client.hitRegEnabled then
				RegisterHitEvent(player, bullet, startPoint, trace, damage)
			end

		end

	end

end


function ClipWeapon:FirePrimary(player)
	self.fireTime = Shared.GetTime()
	FireBullets(self, player)
end