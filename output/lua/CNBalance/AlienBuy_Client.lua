
local indexToAlienTechIdTable = debug.getupvaluex(IndexToAlienTechId, "indexToAlienTechIdTable")
table.insert(indexToAlienTechIdTable, kTechId.Prowler)
kProwlerTechIdIndex = #indexToAlienTechIdTable
table.insert(indexToAlienTechIdTable, kTechId.Vokex)
kVokexTechIdIndex = #indexToAlienTechIdTable

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



function AlienBuy_IsAlienVisible(alienType)
    local scoreRestriction = kAlienNewComerRestriction[IndexToAlienTechId(alienType)]
    if scoreRestriction then
        local skill = Client.GetLocalPlayer():GetPlayerSkill() - Client.GetLocalPlayer():GetPlayerSkillOffset()
        if skill < scoreRestriction then
            return false
        end
    end
    return true
end

function AlienBuy_IsAlienResearched(alienType)
    local techNode = GetAlienTechNode(alienType, true)
    return (techNode ~= nil) and techNode:GetAvailable()
end