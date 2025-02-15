Fade.kBountyThreshold = kBountyClaimMinFade

local kBlinkSpeed = 14    --14 Blink desire speed
local kBlinkAcceleration = 40   --40 Speed up per second
local kBlinkAddAcceleration = 1  --1 Speed after holding
local kBlinkSpeedCap = 25 --25 Blink Max Speed,Normal ppl wont reach it. except proDDDDDD

Fade.kAdrenalineEnergyRecuperationRate = 20
local kAdrenalineBlinkSpeed = 13
local kAdrenalineBlinkAcceleration = 20
local kAdrenalineBlinkAddAcceleration = 0
local kAdrenalineBlinkSpeedCap = 15


function Fade:ModifyVelocity(input, velocity, deltaTime)
    if self:GetIsBlinking() then

        local speed = kBlinkSpeed
        local speedCap = kBlinkSpeedCap
        local acceleration = kBlinkAcceleration
        local addAccelection = kBlinkAddAcceleration
        if self.hasAdrenalineUpgrade then
            speed = kAdrenalineBlinkSpeed
            acceleration =  kAdrenalineBlinkAcceleration
            addAccelection = kAdrenalineBlinkAddAcceleration
            speedCap = kAdrenalineBlinkSpeedCap
        end

        if GetHasCarapaceUpgrade(self) then
            addAccelection = 0
        end

        local wishDir = self:GetViewCoords().zAxis
        local maxSpeedTable = { maxSpeed = speed }
        self:ModifyMaxSpeed(maxSpeedTable, input)
        local prevSpeed = velocity:GetLength()
        local maxSpeed = math.max(prevSpeed, maxSpeedTable.maxSpeed)
        maxSpeed = math.min(speedCap,maxSpeed)

        velocity:Add(wishDir * acceleration * deltaTime)

        if velocity:GetLength() > maxSpeed then
            velocity:Normalize()
            velocity:Scale(maxSpeed)
        end

        velocity:Add(wishDir * addAccelection * deltaTime)
    end

end

function Fade:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint) -- dud
    local reduction = kFadeDamageReduction[doer:GetClassName()]
    if reduction then
        damageTable.damage = damageTable.damage * reduction
    end
end

local baseHandleButtons = Fade.HandleButtons
function Fade:HandleButtons(input)
    
    if self.ethereal and Shared.GetTime() - self.etherealStartTime > 0.18 then
        input.commands = bit.bor(input.commands, Move.Crouch)
    end
    baseHandleButtons(self,input)
end


function Fade:GetExtraHealth(techLevel,extraPlayers,recentWins)
    return techLevel * kFadeHealthPerBioMass
            - recentWins * 5
end

--function Fade:OnInterrupt()
--    if not self:GetIsBlinking() then return end
--    
--    self:SecondaryAttackEnd()
--    self:DeductAbilityEnergy(20)
--end