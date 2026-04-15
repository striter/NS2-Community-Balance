function Gore:GetMaxFocusBonusDamage()
    return kGoreFocusDamageBonusAtMax
end

function Gore:GetFocusAttackCooldown()
    return kGoreFocusAttackSlowAtMax
end


local kAttackRange = 1.7
local kFloorAttackRage = 0.9

local function GetGoreAttackRange(viewCoords)
    return kAttackRange + math.max(0, -viewCoords.zAxis.y) * kFloorAttackRage
end

function Gore:Attack(player)

    local now = Shared.GetTime()
    local didHit = false
    local impactPoint
    local target

    local viewCoords = player:GetViewCoords()
    local range = GetGoreAttackRange(viewCoords)
    didHit, target, impactPoint = AttackMeleeCapsule(self, player, kGoreDamage, range)

    self:OnAttack(player)

    if target then
        ApplyPushback(target,0,viewCoords.yAxis * 6 + viewCoords.zAxis * 2)
    end

    return didHit, impactPoint, target

end