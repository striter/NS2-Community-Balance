if Client then
	local origGetCrosshairY = PlayerUI_GetCrosshairY
	function PlayerUI_GetCrosshairY()
		if mapname == Revolver.kMapName then
			mapname = Pistol.kMapName
		elseif mapname == LightMachineGun.kMapName then
			mapname = Rifle.kMapName
		elseif mapname == SubMachineGun.kMapName then
			mapname = Shotgun.kMapName
		elseif mapname == Knife.kMapName then
			mapname = Axe.kMapName
		elseif mapname == Cannon.kMapName then
			mapname = Rifle.kMapName
		end
		return origGetCrosshairY(self)
	end
end



if Server then

	local onReplace = Player.Replace
	function Player:Replace(mapName, newTeamNumber, preserveWeapons, atOrigin, extraValues, isPickup)
		local player = onReplace(self,mapName, newTeamNumber, preserveWeapons, atOrigin, extraValues, isPickup)
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

end 