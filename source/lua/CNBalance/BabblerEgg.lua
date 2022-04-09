if Server then

    function BabblerEgg:OnTakeDamage(_, attacker, doer)
        -- if self:GetIsBuilt() then
        --     local owner = self:GetOwner()
        --     local doerClassName = doer and doer:GetClassName()

        --     if owner and doer and attacker == owner and doerClassName == "Spit" then
        --         self:Explode()
        --     end
        -- end
    end


    function BabblerEgg:DetectThreatFilter()
        return function (t)
            return t ~= self and not t:isa("Clog")
        end
    end

    function BabblerEgg:DetectThreat()
        if self:GetIsBuilt() then
            local otherTeam = GetEnemyTeamNumber(self:GetTeamNumber())
            local allEnemies = GetEntitiesForTeamWithinRange("Player", otherTeam, self:GetOrigin(), kBabblerEggDamageRadius)
            local enemies = {}

            for _, ent in ipairs(allEnemies) do
                if ent:GetIsAlive() then
                    table.insert(enemies, ent)
                end
            end

            Shared.SortEntitiesByDistance(self:GetOrigin(), enemies)
            for _, ent in ipairs(enemies) do
                local dir = self:GetCoords().yAxis
                local startPoint = ent:GetEngagementPoint()
                local endPoint = self:GetOrigin() + dir * self:GetExtents().y
                local filter = self:DetectThreatFilter()

                local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Move, PhysicsMask.Bullets, filter)
                local visibleTarget = trace.entity == self

                -- If a clog is blocking our LOS, check from our origin instead of our model top
                if not visibleTarget and GetIsPointInsideClogs(endPoint) then
                    -- Log("%s is inside clog, doing origin traceray", self)
                    endPoint = self:GetOrigin()
                    trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Move, PhysicsMask.Bullets, filter)
                end

                if visibleTarget and trace.fraction < 1 then
                    
                        local owner = self:GetOwner()
                        local client = owner:GetClient()
                        local varaint = client and client.variantData and client.variantData.babblerVariant
                        local position = HasMixin(visibleTarget, "Target") and visibleTarget:GetEngagementPoint() or visibleTarget:GetOrigin()
                        for i=0 ,6 ,1 do
                            local babbler = CreateEntity(Babbler.kMapName, origin, self:GetTeamNumber())
                            -- -- babbler:SetSilenced(false)

                            if varaint then
                                babbler:SetVariant( varaint )
                            end
                            babbler:TriggerEffects("babbler_engage")
                            babbler:SetOwner(owner)
                            babbler.clinged = true
                            babbler:Detach(true)
                            babbler:SetMoveType(kBabblerMoveType.Attack, visibleTarget, position, true)

                        end
                        self:TriggerEffects("Babbler_hatch")
                        DestroyEntity(self)

                        self:Explode()
                    break
                end
            end
        end

        return self:GetIsAlive()
    end

end
