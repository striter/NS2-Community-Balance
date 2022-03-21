if Client then
	local origGetCrosshairY = PlayerUI_GetCrosshairY
	function PlayerUI_GetCrosshairY()
		if mapname == Revolver.kMapName then
			mapname = Pistol.kMapName
		end
		return origGetCrosshairY(self)
	end
end
	
