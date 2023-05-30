
function ARC:GetCanFireAtTargetActual(target, targetPoint)

    if not target.GetReceivesStructuralDamage or not target:GetReceivesStructuralDamage() then
        return false
    end

    -- don't target eggs (they take only splash damage)
    if target:isa("Egg") or target:isa("Cyst") then
        return false
    end

    if not target:GetIsSighted() and not GetIsTargetDetected(target) then
        return false
    end

    local distToTarget = (target:GetOrigin() - self:GetOrigin()):GetLengthXZ()
    if (distToTarget > ARC.kFireRange) or (distToTarget < ARC.kMinFireRange) then
        return false
    end

    return true

end
