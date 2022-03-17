
function Axe:GetCatalystSpeedBase()
    local speed=1   

    if GetHasTech(self,kTechId.PistolAxeUpgrade) then
        speed =1.33
    end

    return speed
end

local kAxeUpgardeDamage = 31

function Axe:OnTag(tagName)

    PROFILE("Axe:OnTag")
    
    if tagName == "swipe_sound" then
    
        local player = self:GetParent()
        if player then
            player:TriggerEffects("axe_attack")
        end
        
    elseif tagName == "hit" then
    
        local player = self:GetParent()
        local coords = player:GetViewAngles():GetCoords()
        
        local damage = kAxeDamage
        if GetHasTech(self,kTechId.PistolAxeUpgrade) then
            damage = kAxeUpgardeDamage
        end
        local didHit, target = AttackMeleeCapsule(self, player, damage, self:GetRange())

        if not (didHit and target) and coords then -- Only for webs
            self:Axe_HitCheck(coords, player)
        end
        
    elseif tagName == "attack_end" then
        self.sprintAllowed = true
    elseif tagName == "deploy_end" then
        self.sprintAllowed = true
    elseif tagName == "idle_toss_start" then
        self:TriggerEffects("axe_idle_toss")
    elseif tagName == "idle_fiddle_start" then
        self:TriggerEffects("axe_idle_fiddle")
    end
    
end