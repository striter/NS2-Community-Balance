
--local baseTriggerBeaconEffects = Player.TriggerBeaconEffects
--function Player:TriggerBeaconEffects()
--	baseTriggerBeaconEffects(self)
--
--	if HasMixin(self, "ParasiteAble") and self:GetIsParasited() then
--		self:RemoveParasite()
--	end
--end

if Client then
	
	function PlayerUI_GetCrosshairY()
		local player = Client.GetLocalPlayer()

		if(player and not player:GetIsThirdPerson()) then

			local weapon = player:GetActiveWeapon()
			if(weapon ~= nil) then

				-- Get class name and use to return index
				local index
				local mapname = weapon:GetMapName()

				if mapname == Rifle.kMapName or mapname == HeavyMachineGun.kMapName or mapname == LightMachineGun.kMapName or mapname == Cannon.kMapName then
					index = 0
				elseif mapname == Pistol.kMapName or mapname == Revolver.kMapName then
					index = 1
				elseif mapname == Shotgun.kMapName or mapname == SubMachineGun.kMapName then
					index = 3
				elseif mapname == Minigun.kMapName then
					index = 4
				elseif mapname == Flamethrower.kMapName or mapname == GrenadeLauncher.kMapName then
					index = 5
					-- All alien crosshairs are the same for now
				elseif mapname == LerkBite.kMapName or mapname == Spores.kMapName or mapname == LerkUmbra.kMapName or mapname == Parasite.kMapName or mapname == BileBomb.kMapName or mapname == VolleyRappel.kMapName then
					index = 6
				elseif mapname == SpitSpray.kMapName or mapname == BabblerAbility.kMapName or mapname == AcidRocket.kMapName then
					index = 7
					-- Blanks (with default damage indicator)
				else
					index = 8
				end

				return index * 64

			end
		end
	end
end

if Server then

	local onReplace = Player.Replace
	function Player:Replace(mapName, newTeamNumber, preserveWeapons, atOrigin, extraValues, isPickup)
		local player = onReplace(self,mapName, newTeamNumber, preserveWeapons, atOrigin, extraValues, isPickup)

		if newTeamNumber and newTeamNumber ~= kTeam1Index then
			player.primaryRespawn = nil
			player.secondaryRespawn = nil
			player.meleeRespawn = nil
		end
		
		if player:isa("Marine") and not self:GetIsAlive() then

			if player.primaryRespawn then
				player:GiveItem(player.primaryRespawn,true)
			end
			
			if player.secondaryRespawn then
				player:GiveItem(player.secondaryRespawn,false)
			end

			if player.meleeRespawn then
				player:GiveItem(player.meleeRespawn,false)
			end
		end
		
		return player
	end

	local baseOnInitialSpawn = Player.OnInitialSpawn
	function Player:OnInitialSpawn(techPointOrigin)
		baseOnInitialSpawn(self,techPointOrigin)
		self.primaryRespawn = nil
		self.secondaryRespawn = nil
		self.meleeRespawn = nil
	end
	
	local baseCopyPlayerDataFrom = Player.CopyPlayerDataFrom
	function Player:CopyPlayerDataFrom(player)
		baseCopyPlayerDataFrom(self,player)
		
		self.primaryRespawn = player.primaryRespawn
		self.secondaryRespawn = player.secondaryRespawn
		self.meleeRespawn = player.meleeRespawn
	end

	
	--local baseSetResources = Player.SetResources
	--function Player:SetResources(amount)
	--	Shared.Message(amount)
	--	baseSetResources(self,amount)
	--end
	--
	--function Player:AddResources(amount)
	--
	--	local resReward = 0
	--
	--	if Shared.GetCheatsEnabled() or ( amount <= 0 or not self.blockPersonalResources ) then
	--		resReward = math.min(amount, kMaxPersonalResources - self:GetResources())
	--		self:SetResources(self:GetResources() + resReward)
	--
	--	end
	--
	--	return resReward
	--
	--end
end


local baseGetCanShootSeasonalObject = Player.GetCanShootSeasonalObject
function Player:GetCanShootSeasonalObject()
	if self:GetIsDestroyed() then return false end
	return baseGetCanShootSeasonalObject(self)
end

Shared.LinkClassToMap("Player", Player.kMapName, {playerScale = "float (0 to 4 by 0.02)"}, true)

local oldOnCreate = Player.OnCreate
function Player:OnCreate()
    self.playerScale = 1
    oldOnCreate(self)
end

function Player:GetPlayerScale()
    return self.playerScale
end

function Player:SetPlayerScale(_scale)
    self.playerScale = _scale
    self:UpdateControllerFromEntity()
end

function Player:GetCanDieOverride()     --Just die Anyway
    local teamNumber = self:GetTeamNumber()
    return (teamNumber == kTeam1Index or teamNumber == kTeam2Index or teamNumber == kTeamReadyRoom)
end

function Player:OnAdjustModelCoords(modelCoords)
    local coords = modelCoords
    local scale = self:GetPlayerScale()
    coords.xAxis = coords.xAxis * scale
    coords.yAxis = coords.yAxis * scale
    coords.zAxis = coords.zAxis * scale
    return coords
end

local baseGetTraceCapsule = Player.GetTraceCapsule
function Player:GetTraceCapsule()
    local height,radius = baseGetTraceCapsule(self)
    local scale = self:GetPlayerScale()
    height = height * scale
    radius = radius * scale
    return height,radius
end

local baseGetControllerSize = Player.GetControllerSize
function Player:GetControllerSize()
    local scale = self:GetPlayerScale()
    local height,radius = baseGetControllerSize(self)
    height = height * scale
    radius = radius * scale
    return height,radius
end


local baseGetMaxSpeed =  Player.GetMaxSpeed
function Player:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible)  * self:ScaledBasedSpeedMultiplier()
end

-- local baseModifyGravityForce = Player.ModifyGravityForce
-- function Player:ModifyGravityForce(gravityTable)
--     baseModifyGravityForce(self,gravityTable)
--     gravityTable.gravity = gravityTable.gravity* (self.scale == 1 and 1 or 0.35)
-- end

function Player:OnPostUpdateCamera(deltaTime)
    self:SetViewOffsetHeight(self:GetMaxViewOffsetHeight() * self:GetPlayerScale())
end

local kCrouchShrinkAmount = 0.7
function Player:GetCrouchShrinkAmount()
    return kCrouchShrinkAmount * self:GetPlayerScale()
end

function Player:ScaledBasedSpeedMultiplier()
    return 0.8  + self:GetPlayerScale() * 0.2
end
