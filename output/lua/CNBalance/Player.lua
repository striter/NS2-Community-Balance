if Client then
	
	function PlayerUI_GetCrosshairY()
		local player = Client.GetLocalPlayer()

		if(player and not player:GetIsThirdPerson()) then

			local weapon = player:GetActiveWeapon()
			if(weapon ~= nil) then

				-- Get class name and use to return index
				local index
				local mapname = weapon:GetMapName()

				if mapname == Rifle.kMapName or mapname == HeavyMachineGun.kMapName or mapname == LightMachineGun.kMapName  then
					index = 0
				elseif mapname == Pistol.kMapName or mapname == Revolver.kMapName or mapname == Cannon.kMapName then
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
				elseif mapname == SpitSpray.kMapName or mapname == BabblerAbility.kMapName then
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