--
--	ns2siege+ Custom Game Mode
--	ZycaR (c) 2016
--

decoda_name = "Client"
--Shared.Message('ns2siege+ ... beta06')

if kTranslateMessage then
    kTranslateMessage["SG_DOOR_TIMER"] = "交战区: %s | 攻城区: %s"
    kTranslateMessage["SG_DOOR_OPEN"] = "已开启"
    kTranslateMessage["SG_SUDDEN_DEATH"] = "终局时刻: %s"
    kTranslateMessage["SG_SUDDEN_DEATH_ACTIVATED"] = "已开启! 无法进行建筑治疗。"
end

if kLocales then
    kLocales["SG_DOOR_TIMER"] = "Front door: %s | Siege door: %s"
    kLocales["SG_DOOR_OPEN"] = "Opened"
    kLocales["SG_SUDDEN_DEATH"] = "Sudden death: %s"
    kLocales["SG_SUDDEN_DEATH_ACTIVATED"] = "ACTIVATED! Cannot heal or build CC/hive!"
end 