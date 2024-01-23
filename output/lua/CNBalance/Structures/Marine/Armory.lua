Armory.kWeldAmount = 10
Armory.kHealAmount = 25

local oldArmoryGetItemList = Armory.GetItemList
function Armory:GetItemList(forPlayer)
    local itemList = oldArmoryGetItemList(self, forPlayer)
    table.insert(itemList, kTechId.Knife)
    table.insert(itemList, kTechId.Revolver)
    table.insert(itemList, kTechId.SubMachineGun)
    --table.insert(itemList, kTechId.LightMachineGun)
    table.insert(itemList, kTechId.LightMachineGunAcquire)
    table.insert(itemList, kTechId.Cannon)
    table.insert(itemList, kTechId.CombatBuilder)
	return itemList
end

local oldAdvancedArmoryGetItemList = AdvancedArmory.GetItemList
function AdvancedArmory:GetItemList(forPlayer)
    local itemList = oldAdvancedArmoryGetItemList(self, forPlayer)
	if self:GetTechId() == kTechId.AdvancedArmory then
        table.insert(itemList, kTechId.Knife)
        table.insert(itemList, kTechId.Revolver)
        table.insert(itemList, kTechId.SubMachineGun)
        --table.insert(itemList, kTechId.LightMachineGun)
        table.insert(itemList, kTechId.LightMachineGunAcquire)
        table.insert(itemList, kTechId.Cannon)
        table.insert(itemList, kTechId.CombatBuilder)
    end
	return itemList
end

function Armory:GetTechButtons(techId)

    local techButtons = 
    {
        kTechId.ShotgunTech,kTechId.None, kTechId.None, kTechId.None,
        kTechId.MinesTech, kTechId.GrenadeTech, kTechId.None, kTechId.None 
    }
    
    -- Show button to upgraded to advanced armory
    local advancedArmory = self:GetTechId() == kTechId.AdvancedArmory
    if not advancedArmory then
        techButtons[4] = kTechId.AdvancedArmoryUpgrade
    end
    
    return techButtons

end

function Armory:GetTechAllowed(techId, techNode, player)

    local allowed, canAfford = ScriptActor.GetTechAllowed(self, techId, techNode, player)

    if techId == kTechId.HeavyRifleTech then
        allowed = allowed and self:GetTechId() == kTechId.AdvancedArmory
    end

    return allowed, canAfford

end


--local baseGetCanBeUsed = Armory.GetCanBeUsed
--function Armory:GetCanBeUsed(player, useSuccessTable)
--
--    baseGetCanBeUsed(self,player,useSuccessTable)
--    if GetHasTech(self,kTechId.MilitaryProtocol) then
--        useSuccessTable.useSuccess = false
--    end
--    
--end

if Server then


    function Armory:GetShouldResupplyPlayer(player)

        if not player:GetIsAlive() then
            return false
        end

        local stunned = HasMixin(player, "Stun") and player:GetIsStunned()

        if stunned then
            return false
        end

        local inNeed = false

        -- Don't resupply when already full
        if (player:GetHealthScalar() < 1) then
            inNeed = true
        else

            -- Do any weapons need ammo?
            for i = 1, player:GetNumChildren() do
                local child = player:GetChildAtIndex(i - 1)
                if child:isa("ClipWeapon") and child:GetNeedsAmmo(false) then
                    inNeed = true
                    break
                end
            end

        end

        if inNeed then

            -- Check player facing so players can't fight while getting benefits of armory
            local viewVec = player:GetViewAngles():GetCoords().zAxis

            local toArmoryVec = self:GetOrigin() - player:GetOrigin()

            if(GetNormalizedVector(viewVec):DotProduct(GetNormalizedVector(toArmoryVec)) > .75) then

                if self:GetTimeToResupplyPlayer(player) then

                    return true

                end

            end

        end

        return false

    end

    function Armory:ResupplyPlayer(player)

        local resuppliedPlayer = false

        -- Heal player first
        if (player:GetHealthScalar() < 1) then

            -- third param true = ignore armor
            if player:GetHealthFraction() < 1 then
                player:AddHealth(self.kHealAmount, false, true)
            else
                player:AddArmor(self.kWeldAmount, false, true)
            end
            self:TriggerEffects("armory_health", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})

            resuppliedPlayer = true
            --[[
            if HasMixin(player, "ParasiteAble") and player:GetIsParasited() then
            
                player:RemoveParasite()
                
            end
            --]]

            if player:isa("Marine") and player.poisoned then

                player.poisoned = false

            end

        end

        -- Give ammo to all their weapons, one clip at a time, starting from primary
        local weapons = player:GetHUDOrderedWeaponList()

        for _, weapon in ipairs(weapons) do

            if weapon:isa("ClipWeapon") then

                if weapon:GiveAmmo(1, false) then

                    self:TriggerEffects("armory_ammo", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})

                    resuppliedPlayer = true

                    break

                end

            end

        end

        if resuppliedPlayer then

            -- Insert/update entry in table
            self.resuppliedPlayers[player:GetId()] = Shared.GetTime()

            -- Play effect
            --self:PlayArmoryScan(player:GetId())

        end

    end
end 