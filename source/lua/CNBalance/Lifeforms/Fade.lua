local kBlinkSpeed = 14    //14 Blink desire speed
local kBlinkAcceleration = 40   //40 Speed up per second
local kBlinkAddAcceleration = 1  //1 Speed after holding
local kBlinkSpeedCap = 25 //25 Blink Max Speed,Normal ppl wont reach it. except proDDDDDD

Fade.kAdrenalineEnergyRecuperationRate = 18
local kAdrenalineBlinkSpeedReduction = 1
local kAdrenalineBlinkAccelerationReduction = 0
local kAdrenalineBlinkAddAccelerationReduction = 0.5
local kAdrenalineBlinkSpeedCapReduction = 7

function Fade:ModifyVelocity(input, velocity, deltaTime)

    if self:GetIsBlinking() then

        local speed=kBlinkSpeed
        local speedCap=kBlinkSpeedCap
        local acceleration = kBlinkAcceleration
        local addAccelection = kBlinkAddAcceleration
        if self.hasAdrenalineUpgrade then
            speed = speed - kAdrenalineBlinkSpeedReduction
            acceleration = acceleration - kAdrenalineBlinkAccelerationReduction
            addAccelection = addAccelection - kAdrenalineBlinkAddAccelerationReduction
            speedCap = speedCap - kAdrenalineBlinkSpeedCapReduction
        end

        local wishDir = self:GetViewCoords().zAxis
        local maxSpeedTable = { maxSpeed = speed }
        self:ModifyMaxSpeed(maxSpeedTable, input)
        local prevSpeed = velocity:GetLength()
        local maxSpeed = math.min(prevSpeed, maxSpeedTable.maxSpeed)
        maxSpeed = math.min(speedCap,maxSpeed)
        velocity:Add(wishDir * acceleration * deltaTime)

        if velocity:GetLength() > maxSpeed then
            velocity:Normalize()
            velocity:Scale(maxSpeed)
        end

        velocity:Add(wishDir * addAccelection * deltaTime)
    end

end
