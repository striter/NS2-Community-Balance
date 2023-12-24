
local GetPickupTextureCoordinates = debug.getupvaluex(GUIPickups.Update, "GetPickupTextureCoordinates")
local kPickupTypes = debug.getupvaluex(GetPickupTextureCoordinates, "kPickupTypes")
table.insert(kPickupTypes, "Revolver")
table.insert(kPickupTypes, "SubMachineGun")
table.insert(kPickupTypes, "LightMachineGun")
table.insert(kPickupTypes, "Cannon")
table.insert(kPickupTypes, "CombatBuilder")
table.insert(kPickupTypes, "Heavy")
local kPickupTextureYOffsets = debug.getupvaluex(GetPickupTextureCoordinates, "kPickupTextureYOffsets")
kPickupTextureYOffsets["Revolver"] = 13
kPickupTextureYOffsets["SubMachineGun"] = 14
kPickupTextureYOffsets["Cannon"] = 15
kPickupTextureYOffsets["LightMachineGun"] = 16
kPickupTextureYOffsets["CombatBuilder"] = 17
kPickupTextureYOffsets["Heavy"] = 17


local kPickupsVisibleRange = 15
local kMinPickupSize = 16
local kMaxPickupSize = 48
-- Note: This graphic can probably be smaller as we don't need the icons to be so big.
local kIconsTextureName = "ui/drop_icons.dds"
local kExpireBarTextureName = "ui/healthbarsmall.dds"
local kIconWorldOffset = Vector(0, 0.5, 0)
local kBounceSpeed = 2
local kBounceAmount = 0.05

local pickups = {}

local function GetNearbyPickups()

    local localPlayer = Client.GetLocalPlayer()
    table.clear(pickups)

    if localPlayer then
        local team = localPlayer:GetTeamNumber()
        local origin = localPlayer:GetOrigin()
        local queries = {}
        local count = Shared_GetEntitiesWithTagInRange("Pickupable", origin, kPickupsVisibleRange, queries)
        for i = 1, count do
            local _entity = queries[i]
            local sameTeam = _entity:GetTeamNumber() == team
            local canPickup = _entity:GetIsValidRecipient(localPlayer)
            if sameTeam and canPickup then
                table.insert(pickups,_entity)
            end
        end
        table.clear(queries)
    end

    return pickups

end


function GUIPickups:Update()

    PROFILE("GUIPickups:Update")

    local localPlayer = Client.GetLocalPlayer()

    if localPlayer then

        for _, pickupGraphic in pairs(self.allPickupGraphics) do
            pickupGraphic:SetIsVisible(false)
            pickupGraphic.expireBarBg:SetIsVisible(false)
            pickupGraphic.expireBar:SetIsVisible(false)
        end

        local nearbyPickups = GetNearbyPickups()
        local count = 0
        for _,v in pairs(nearbyPickups) do
            count = count + 1
        end
        
        for _, pickup in pairs(nearbyPickups) do
            -- Check if the pickup is in front of the player.
            local playerForward = localPlayer:GetCoords().zAxis
            local playerToPickup = GetNormalizedVector(pickup:GetOrigin() - localPlayer:GetOrigin())
            local dotProduct = Math.DotProduct(playerForward, playerToPickup)

            if dotProduct > 0 then

                local timeLeft = pickup.GetExpireTimeFraction and pickup:GetExpireTimeFraction() or 0

                local isBarVisible = false
                if GUIPickups.kExpirationBarMode == 2 then
                    isBarVisible = timeLeft > 0
                elseif GUIPickups.kExpirationBarMode == 1 then
                    isBarVisible = timeLeft > 0 and pickup:isa("Weapon")
                end

                local distance = pickup:GetDistanceSquared(localPlayer)
                distance = distance / (kPickupsVisibleRange * kPickupsVisibleRange)
                distance = 1 - distance
                local pickupSize = kMinPickupSize + ((kMaxPickupSize - kMinPickupSize) * distance)

                local bounceAmount = math.sin(Shared.GetTime() * kBounceSpeed) * kBounceAmount
                local pickupWorldPosition = pickup:GetOrigin() + kIconWorldOffset + Vector(0, bounceAmount, 0)
                local pickupInScreenspace = Client.WorldToScreen(pickupWorldPosition)
                -- Adjust for the size so it is in the middle.
                pickupInScreenspace = pickupInScreenspace + Vector(-pickupSize / 2, -pickupSize / 2, 0)

                local freePickupGraphic = self:GetFreePickupGraphic()
                freePickupGraphic:SetIsVisible(self.visible)
                freePickupGraphic:SetColor(Color(1, 1, 1, distance))
                freePickupGraphic:SetSize(GUIScale(Vector(pickupSize, pickupSize, 0)))
                freePickupGraphic:SetPosition(Vector(pickupInScreenspace.x, pickupInScreenspace.y-5*distance, 0))
                freePickupGraphic:SetTexturePixelCoordinates(GetPickupTextureCoordinates(pickup))

                freePickupGraphic.expireBarBg:SetIsVisible(self.visible and isBarVisible)
                freePickupGraphic.expireBar:SetIsVisible(self.visible and isBarVisible)
                if isBarVisible then

                    local barColor = GUIPickups_GetExpirationBarColor( timeLeft, distance )

                    freePickupGraphic.expireBarBg:SetColor(Color(0, 0, 0, distance*0.75))
                    freePickupGraphic.expireBar:SetColor(barColor)

                    freePickupGraphic.expireBarBg:SetSize(GUIScale(Vector(pickupSize, 6, 0)))
                    freePickupGraphic.expireBar:SetSize(GUIScale(Vector((pickupSize-1)*timeLeft, 6, 0)))
                    freePickupGraphic.expireBar:SetTexturePixelCoordinates(0,0,64*timeLeft,6)

                    freePickupGraphic.expireBar:SetPosition(Vector(pickupInScreenspace.x+1, pickupInScreenspace.y+GUIScale(pickupSize), 0))
                    freePickupGraphic.expireBarBg:SetPosition(Vector(pickupInScreenspace.x, pickupInScreenspace.y+GUIScale(pickupSize), 0))

                end

            end

        end

    end

end