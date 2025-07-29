
Script.Load("lua/BiomassHealthMixin.lua")
local baseOnCreate = ARC.OnCreate
function ARC:OnCreate()
    baseOnCreate(self)
    InitMixin(self, BiomassHealthMixin)
end

function ARC:GetExtraHealth(techLevel,extraPlayers,recentWins)
    return kARCHealthPerPlayerAdd * extraPlayers
end

local baseValidateTargetPosition = ARC.ValidateTargetPosition
function ARC:ValidateTargetPosition(position)
    local successful = baseValidateTargetPosition(self,position)
    if successful then
        successful = not AlienDetectionParry(GetEnemyTeamNumber(self:GetTeamNumber()),position,ShadeInk.kShadeInkDisorientRadius)
    end
    return successful
end

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

    if target.GetIsSighted then
        if not target:GetIsSighted() and not GetIsTargetDetected(target) then
            return false
        end
    end

    local distToTarget = (target:GetOrigin() - self:GetOrigin()):GetLengthXZ()
    if (distToTarget > ARC.kFireRange) or (distToTarget < ARC.kMinFireRange) then
        return false
    end
    
    return true

end

if Server then
    local basePerformAttack = ARC.PerformAttack
    function ARC:PerformAttack()
        basePerformAttack(self)


        local team = self:GetTeam()
        if team then
            team:OnDeadlockExtend(kTechId.ARCDeploy)
        end
    end
    
end 