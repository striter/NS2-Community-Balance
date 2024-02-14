
local indexToAlienTechIdTable = debug.getupvaluex(IndexToAlienTechId, "indexToAlienTechIdTable")
table.clear(indexToAlienTechIdTable)
indexToAlienTechIdTable[1] = kTechId.Gorge
indexToAlienTechIdTable[2] = kTechId.Skulk
indexToAlienTechIdTable[3] = kTechId.Prowler
indexToAlienTechIdTable[4] = kTechId.Lerk
indexToAlienTechIdTable[5] = kTechId.Fade
indexToAlienTechIdTable[6] = kTechId.Vokex
indexToAlienTechIdTable[7] = kTechId.Onos

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
    elseif techId == kTechId.Vokex then
        return {"Vokex" , Vokex.kHealth, Vokex.kArmor, kVokexCost}
    else
        return {"Skulk", Skulk.kHealth, Skulk.kArmor, kSkulkCost}
    end
end

local oldAlienBuy_OnSelectAlien = AlienBuy_OnSelectAlien
function AlienBuy_OnSelectAlien(type)
	if type == "Prowler" then
        type = "Skulk"
    elseif type == "Vokex" then
        type = "Fade"
    end
    oldAlienBuy_OnSelectAlien(type)
end

function AlienBuy_IsAlienResearched(alienType)
    local techNode = GetAlienTechNode(alienType, true)
    return (techNode ~= nil) and techNode:GetAvailable()
end