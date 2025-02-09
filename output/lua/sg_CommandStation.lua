--
--	ns2siege+ Custom Game Mode
--	ZycaR (c) 2016
--

-- Sudden death mode disable repair of CommandStation
function CommandStation:GetCanBeWeldedOverride()
	local front, siege, suddendeath, gameLength = GetGameInfoEntity():GetSiegeTimes()
    return (suddendeath > 0) or (gameLength == 0), true
end