--
--	ns2siege+ Custom Game Mode
--	ZycaR (c) 2016
--

-- Sudden death mode disable healing of CommandStation or Hive
function CommandStructure:GetCanBeHealedOverride()
	local front, siege, suddendeath, gameLength = GetGameInfoEntity():GetSiegeTimes()
    return self:GetIsAlive() and (suddendeath > 0) or (gameLength == 0)
end
