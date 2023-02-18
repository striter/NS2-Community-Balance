if Client then
	local origGetCrosshairY = PlayerUI_GetCrosshairY
	function PlayerUI_GetCrosshairY()
		if mapname == Revolver.kMapName then
			mapname = Pistol.kMapName
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