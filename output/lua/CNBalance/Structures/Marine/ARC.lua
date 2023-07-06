
function ARC:GetCanFireAtTargetActual(target, targetPoint, manuallyTargeted)

    if not target.GetReceivesStructuralDamage or not target:GetReceivesStructuralDamage() then
        return false
    end

    -- don't target eggs (they take only splash damage)
    -- Hydra exclusion has to due with people using them to prevent ARC shooting Hive. 
    if target:isa("Egg") or target:isa("Cyst") then -- or target:isa("Contamination") then
        return false
    end

    if not manuallyTargeted and (target:isa("Hydra") or target:isa("SporeMine"))then
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