
local indexToAlienTechIdTable = debug.getupvaluex(IndexToAlienTechId, "indexToAlienTechIdTable")
table.insert(indexToAlienTechIdTable, kTechId.Prowler)
kProwlerTechIdIndex = #indexToAlienTechIdTable

function AlienBuy_GetClassStats(idx)

    if idx == nil then
        Print("AlienBuy_GetClassStats(nil) called")
    end

    -- name, hp, ap, cost
    local techId = IndexToAlienTechId(idx)

    if techId == kTechId.Fade then
        return {"Fade", Fade.kHealth, Fade.kArmor, kFadeCost}
    elseif techId == kTechId.Gorge then
        return {"Gorge", kGorgeHealth, kGorgeArmor, kGorgeCost}
    elseif techId == kTechId.Lerk then
        return {"Lerk", kLerkHealth, kLerkArmor, kLerkCost}
    elseif techId == kTechId.Onos then
        return {"Onos", Onos.kHealth, Onos.kArmor, kOnosCost}
    elseif techId == kTechId.Prowler then
        return {"Prowler", Prowler.kHealth, Prowler.kArmor, kProwlerCost}
    else
        return {"Skulk", Skulk.kHealth, Skulk.kArmor, kSkulkCost}
    end
end

local oldAlienBuy_OnSelectAlien = AlienBuy_OnSelectAlien
function AlienBuy_OnSelectAlien(type)
	if type == "Prowler" then
        type = "Skulk"
    end
    oldAlienBuy_OnSelectAlien(type)

end

