local oldStatsUI_GetStatusGrouping = StatsUI_GetStatusGrouping

local newStatusGrouping = {}
newStatusGrouping[kPlayerStatus.ProwlerEgg] = kPlayerStatus.Embryo
newStatusGrouping[kPlayerStatus.VokexEgg] = kPlayerStatus.Embryo

function StatsUI_GetStatusGrouping(playerStatus)
	return oldStatsUI_GetStatusGrouping(playerStatus) or newStatusGrouping[playerStatus]
end