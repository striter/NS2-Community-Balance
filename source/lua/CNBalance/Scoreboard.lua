
local kStatusTranslationStringMap = debug.getupvaluex(Scoreboard_ReloadPlayerData, "kStatusTranslationStringMap")
kStatusTranslationStringMap[kPlayerStatus.Devoured] = "STATUS_DEVOURED"

kStatusTranslationStringMap[kPlayerStatus.Prowler]="PROWLER"
kStatusTranslationStringMap[kPlayerStatus.ProwlerEgg]="PROWLER_EGG"
kStatusTranslationStringMap[kPlayerStatus.Revolver]="STATUS_REVOLVER"
kStatusTranslationStringMap[kPlayerStatus.Submachinegun]="STATUS_SUBMACHINEGUN"
kStatusTranslationStringMap[kPlayerStatus.Cannon]="STATUS_CANNON"

debug.setupvaluex( Scoreboard_ReloadPlayerData, "kStatusTranslationStringMap", kStatusTranslationStringMap)