-- Punch shoves the victim back like the rifle butt does, slightly stronger.
local kClawRange = 2.8
local kClawPushbackSpeed = 6
local kClawPushbackDisableTime = 0.2

function Claw:OnTag(tagName)

    PROFILE("Claw:OnTag")

    local player = self:GetParent()
    if not player then
        return
    end

    if tagName == "hit" then

        local didHit, target = AttackMeleeCapsule(self, player, kClawDamage, kClawRange)
        if didHit and target and target:isa("Player") then
            local direction = player:GetViewCoords().zAxis
            direction.y = 0
            local length = direction:GetLength()
            if length > 0.01 then
                ApplyPushback(target, kClawPushbackDisableTime, direction * (kClawPushbackSpeed / length))
            end
        end

    elseif tagName == "claw_attack_start" then
        player:TriggerEffects("claw_attack")
    end

end
