

local kGrenadeTechIds =
{
    kTechId.ClusterGrenade,
    kTechId.GasGrenade,
    kTechId.PulseGrenade,
}

local kDefensiveTechIds =
{
    kTechId.CombatBuilder,
    kTechId.LayMines,
}


function MarineBuy_GetHasDefensiveTech( techId )

    if techId == kTechId.CombatBuilder or techId == kTechId.LayMines then
        return true
    end

    return false

end

function MarineBuy_GetEquipment()
    
    local inventory = {}
    local player = Client.GetLocalPlayer()
    local items = GetChildEntities( player, "ScriptActor" )
    
    for _, item in ipairs(items) do
    
        local techId = item:GetTechId()

        local itemName = GetDisplayNameForTechId(techId)    --simple validity check
        if itemName then
            inventory[techId] = { Has = true, Occupied = false }
        end

        if MarineBuy_GetHasGrenades( techId ) then

            for i = 1, #kGrenadeTechIds do
                local grenadeTechId = kGrenadeTechIds[i]
                inventory[grenadeTechId] = { Has = true, Occupied = techId ~= grenadeTechId }
            end

        end

        if MarineBuy_GetHasDefensiveTech(techId) then
            for i = 1, #kDefensiveTechIds do
                local defensiveTech = kDefensiveTechIds[i]
                inventory[defensiveTech] = { Has = true, Occupied = techId ~= defensiveTech }
            end
        end
    end
    
    if player:isa("JetpackMarine") then
        inventory[kTechId.Jetpack] = { Has = true, Occupied = false }
    --elseif player:isa("Exo") then
        --Exo's are inherently handled by how the BuyMenus are organized
    end
    
    return inventory
    
end


function MarineBuy_GetHas( techId )

    _playerInventoryCache = MarineBuy_GetEquipment()

    if techId == kTechId.LightMachineGunAcquire then
        techId = kTechId.LightMachineGun
    end
    
    if _playerInventoryCache[techId] ~= nil then
        return _playerInventoryCache[techId]
    end

    return { Has = false, Occupied = false }

end
