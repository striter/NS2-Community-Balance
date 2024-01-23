local function DestroyShockwave(self)

    if Server then

        local owner = self:GetOwner()
        if owner then

            for i = 0, owner:GetNumChildren() - 1 do

                local child = owner:GetChildAtIndex(i)
                if HasMixin(child, "Stomp") then
                    child:UnregisterShockwave(self)
                end

            end

        end

        DestroyEntity(self)

    end

end

function Shockwave:Detonate()

    local origin = self:GetOrigin()

    local groundTrace = Shared.TraceRay(origin, origin - Vector.yAxis * 3, CollisionRep.Move, PhysicsMask.Movement, EntityFilterAllButIsa("Tunnel"))
    local enemies = GetEntitiesWithMixinWithinRange("Live", groundTrace.endPoint, 2.2)

    if Shared.GetTestsEnabled() then
        DebugLine(origin,groundTrace.endPoint, 2, 1, 0, 1, 1)
    end

    -- never damage the owner
    local owner = self:GetOwner()
    if owner then
        table.removevalue(enemies, owner)
    end

    if groundTrace.fraction < 1 then

        if Shared.GetTestsEnabled() then
            DebugBox(groundTrace.endPoint, groundTrace.endPoint, Vector(2.2,0.8,2.2), 5, 0, 0, 1, 1 )
        end

        self:SetOrigin(groundTrace.endPoint + (Vector.yAxis * .5) )

        for _, enemy in ipairs(enemies) do

            local enemyId = enemy:GetId()

            if enemy:GetIsAlive() and
                    not table.contains(self.damagedEntIds, enemyId) and
                    math.abs(enemy:GetOrigin().y - groundTrace.endPoint.y) < 0.8
            then
                table.insert(self.damagedEntIds, enemyId)

                if not HasMixin(enemy, "GroundMove") or enemy:GetIsOnGround() then
                    self:TriggerEffects("shockwave_hit", { effecthostcoords = enemy:GetCoords() })
                end


                local finalDamage = kStompDamage
                if enemy:isa("Player") and not enemy:isa("Exo") then

                    local index = #self.damagedEntIds
                    if index <= 2 then
                        local firstOne = index == 1
                        finalDamage = firstOne and kStompFirstPDamage or kStompSecondPDamage
                        if HasMixin(enemy, "Stun") then
                            enemy:SetStun(firstOne and kStompDisruptTime or kStompSecondDisruptTime)
                        end
                    else
                        finalDamage = kStompElseDamage
                    end
                    
                    ApplyPushback(enemy,0.2,self:GetCoords().zAxis * 4 + Vector(0,4,0))
                end
                
                if finalDamage > 0 then
                    self:DoDamage(finalDamage, enemy, enemy:GetOrigin(), GetNormalizedVector(enemy:GetOrigin() - groundTrace.endPoint), "none")
                end


            end
        end

    else
        DestroyShockwave(self)
    end

    return true

end


