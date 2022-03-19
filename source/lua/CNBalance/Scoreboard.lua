
local kStatusTranslationStringMap = debug.getupvaluex(Scoreboard_ReloadPlayerData, "kStatusTranslationStringMap")
kStatusTranslationStringMap[kPlayerStatus.Devoured] = "STATUS_DEVOURED"

kStatusTranslationStringMap[kPlayerStatus.Prowler]="STATUS_PROWLER"
kStatusTranslationStringMap[kPlayerStatus.ProwlerEgg]="PROWLER_EGG"


debug.setupvaluex( Scoreboard_ReloadPlayerData, "kStatusTranslationStringMap", kStatusTranslationStringMap)