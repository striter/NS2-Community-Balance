Welder.kHealPResAdded = 0.1
Welder.kHealScoreAdded = 2
Welder.kAmountHealedForPoints = 400

function Welder:GetReplacementWeaponMapName()
    return Axe.kMapName or Knife.kMapName
end

function Welder:GetObseleteWeaponNames()
    return Axe.kMapName , Knife.kMapName
end

function Welder:PerformWeld(player)

    local attackDirection = player:GetViewCoords().zAxis
    local success = false
    -- prioritize friendlies
    local didHit, target, endPoint, direction, surface

    local viewAngles = player:GetViewAngles()
    local viewCoords = viewAngles:GetCoords()
    local startPoint = player:GetEyePos()
    local endPoint = startPoint + viewCoords.zAxis * self:GetRange()

    -- Filter ourself out of the trace so that we don't hit ourselves.
    -- Filter also clogs out for the ray check because they ray "detection" box is somehow way bigger than the visual model
    local filter = EntityFilterTwo(player, self)
    local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, filter)

    if Server then
        local spores = GetEntitiesWithinRange("SporeCloud", endPoint, kSporesDustCloudRadius)

        for i = 1, #spores do
            local spore = spores[i]
            self:TriggerEffects("burn_spore", { effecthostcoords = Coords.GetTranslation(spore:GetOrigin()) } )
            DestroyEntity(spore)
        end
    end
    
    -- Perform a Ray trace first, otherwise fallback to a regular melee capsule
    if (trace.entity) then
        didHit = true
        target = trace.entity
        endPoint = trace.endPoint
        direction = viewCoords.zAxis
        surface = trace.surface
    else
        didHit, target, endPoint, direction, surface = CheckMeleeCapsule(self, player, 0, self:GetRange(), nil, true, 1, PrioritizeDamagedFriends, nil, PhysicsMask.Flame)
    end

    if didHit and target and HasMixin(target, "Live") then

        local timeSinceLastWeld = self.welding and Shared.GetTime() - self.timeLastWeld or 0

        if GetAreEnemies(player, target) then
            self:DoDamage(kWelderDamagePerSecond * timeSinceLastWeld, target, endPoint, attackDirection)
            success = true
        elseif player:GetTeamNumber() == target:GetTeamNumber() and HasMixin(target, "Weldable") then

            if target:GetHealthScalar() < 1 then

                local prevHealthScalar = target:GetHealthScalar()
                local prevHealth = target:GetHealth()
                local prevArmor = target:GetArmor()
                target:OnWeld(self, timeSinceLastWeld, player)
                success = prevHealthScalar ~= target:GetHealthScalar()

                if success then

                    local addAmount = (target:GetHealth() - prevHealth) + (target:GetArmor() - prevArmor)
                    player:AddContinuousScore("WeldHealth", addAmount, Welder.kAmountHealedForPoints, Welder.kHealScoreAdded,Welder.kHealPResAdded)

                    local oldArmor = player:GetArmor()

                    -- weld owner as well
                    player:SetArmor(oldArmor + kWelderFireDelay * kSelfWeldAmount)

                    if player.OnArmorWelded and oldArmor < player:GetArmor() then
                        player:OnArmorWelded(self)
                    end

                end

            end

            if HasMixin(target, "Construct") and target:GetCanConstruct(player) then
                target:Construct(timeSinceLastWeld, player)
            end

        end

    end

    if success then
        return endPoint
    end

end