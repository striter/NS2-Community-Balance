-- GUIAlienBuyMenu.kAlienTypes = { { LocaleName = Locale.ResolveString("FADE"), Name = "Fade", Width = GUIScale(188), Height = GUIScale(220), XPos = 4, Index = 1 },
-- { LocaleName = Locale.ResolveString("GORGE"), Name = "Gorge", Width = GUIScale(200), Height = GUIScale(167), XPos = 1, Index = 2 },
-- { LocaleName = Locale.ResolveString("LERK"), Name = "Lerk", Width = GUIScale(284), Height = GUIScale(253), XPos = 3, Index = 3 },
-- { LocaleName = Locale.ResolveString("ONOS"), Name = "Onos", Width = GUIScale(304), Height = GUIScale(326), XPos = 5, Index = 4 },
-- { LocaleName = Locale.ResolveString("SKULK"), Name = "Skulk", Width = GUIScale(240), Height = GUIScale(170), XPos = 2, Index = 5 } }

local oldFunc = GUIAlienBuyMenu._InitializeBackground
function GUIAlienBuyMenu:_InitializeBackground()
	oldFunc(self)
	local prowlerXpos = 3
	-- local vokexXpos = 6
    for k, alienType in ipairs(GUIAlienBuyMenu.kAlienTypes) do
		
		if alienType.XPos >= prowlerXpos then
			alienType.XPos = alienType.XPos + 1
		end

		-- if alienType.XPos >= vokexXpos then
			-- alienType.XPos = alienType.XPos + 1
		-- end
	end
    table.insert(GUIAlienBuyMenu.kAlienTypes, { LocaleName = "Prowler", Name = "Prowler", Width = GUIScale(240), Height = GUIScale(170), XPos = prowlerXpos, Index = kProwlerTechIdIndex })
    -- table.insert(GUIAlienBuyMenu.kAlienTypes, { LocaleName = "Vokex", Name = "Vokex", Width = GUIScale(240), Height = GUIScale(170), XPos = vokexXpos, Index = kVokexTechIdIndex })
end