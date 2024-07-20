if Server then
    
    local kBabblerSearchRange = 1000

    local function CanGetAttach(self, entity)
        -- Can only attach to friends
        if not GetAreFriends(self, entity) then
            return false
        end

        -- Can only attach when there are attach points available
        if HasMixin(entity, "BabblerCling") and not entity:GetCanAttachBabbler() then
            return false
        end

        -- Don't attach to babbler owners that allready have max babblers
        -- Exclude current owner so gorge can reattack own bablers
        local owner = self:GetOwner()
        if entity ~= owner and HasMixin(entity, "BabblerOwner")
                and entity:GetBabblerCount() >= entity:GetMaxBabblers() then
            return false
        end

        return true
    end

    local function GetMoveType(self, entity)
        local moveType = kBabblerMoveType.Move

        if CanGetAttach(self, entity) then
            moveType = kBabblerMoveType.Cling
        elseif GetAreEnemies(self, entity) and HasMixin(entity, "Live") and entity:GetIsAlive() and entity:GetCanTakeDamage() or ( entity:isa("PowerPoint") and entity:GetBuiltFraction() >= 0.009 ) then
            moveType = kBabblerMoveType.Attack
        end

        return moveType
    end


    function BabblerPheromone:MoveBabblers()
        local orig = self:GetOrigin()
        local enemyTeamNumber = GetEnemyTeamNumber(self:GetTeamNumber())
        local nearestTargets = GetEntitiesForTeamWithinRange("Player", enemyTeamNumber, orig, 15)
        local target
        local targetPos

        for _, ent in ipairs(nearestTargets) do
            if ent and not GetWallBetween(orig, ent:GetOrigin(), ent) then
                target = ent
                targetPos = ent.GetEngagementPoint and ent:GetEngagementPoint() or ent:GetOrigin()
                break
            end
        end

        local owner = self:GetOwner()
        for _, babbler in ipairs(GetEntitiesForTeamWithinRange("Babbler", self:GetTeamNumber(), orig, kBabblerSearchRange )) do
            if babbler:GetOwner() == owner and not babbler:GetIsClinged() then
                if target then
                    babbler:SetMoveType(kBabblerMoveType.Attack, target, targetPos, true)
                    -- Log("Attack group order issued by the bait toward %s", target)
                else
                    -- Log("Move group order issued by the bait toward %s", target)
                    babbler:SetMoveType(kBabblerMoveType.Move, nil, self:GetOrigin(), true)
                end
            end
        end
    end
    
    function BabblerPheromone:ProcessHit(entity)

        if not self.worldCollision then
            if not entity then -- the rest of the code will handle the case where we hit an entity
                self:MoveBabblers() -- Move babblers where the ball bounce
            end
            self.worldCollision = true
        end

        local isValidHit = 
            entity and
            ( entity:isa("PowerPoint") and entity:GetBuiltFraction() >= 0.009 ) or
            ( entity and (GetAreEnemies(self, entity) or HasMixin(entity, "BabblerCling")) and HasMixin(entity, "Live") and entity:GetIsAlive() )

        if isValidHit then

            -- Ensure the impact flag is set even if the entity can't take damage.
            -- Otherwise there will be errors when attacking a Vortexed Marine for example.
            self.impact = true
            if entity:GetCanTakeDamage() then

                self.destinationEntityId = entity:GetId()
                self:SetModel(nil)
                self:TriggerEffects("babbler_pheromone_puff")
                self.triggeredPuff = true
                
                local owner = self:GetOwner()
                local moveType = GetMoveType(self, entity)
                local origin = self:GetOrigin()
                local position = HasMixin(entity, "Target") and entity:GetEngagementPoint() or entity:GetOrigin()
                if moveType == kBabblerMoveType.Attack then
                    local newBabbler = CreateEntity(Babbler.kMapName, origin, self:GetTeamNumber())
                    local client = owner:GetClient()
                    if client and client.variantData then
                        newBabbler:SetVariant( client.variantData.babblerVariant )
                    end
                    newBabbler:TriggerEffects("babbler_engage")
                    newBabbler:SetOwner(owner)
                    newBabbler.clinged = true
                    newBabbler:Detach(true,kBabblerPheromoneHatchLifeTime)
                    newBabbler:SetMoveType(moveType, entity, position, true)
                    self:TriggerEffects("Babbler_hatch")
                elseif moveType == kBabblerMoveType.Cling then
                    for _, babbler in ipairs(GetEntitiesForTeamWithinRange("Babbler", self:GetTeamNumber(), origin, kBabblerSearchRange )) do
                        if babbler:GetOwner() == owner then
                            if babbler:GetIsClinged() then

                                if babbler:GetParent() == owner then
                                    babbler:Detach()
                                end

                                babbler:SetMoveType(moveType, entity, position, true)

                            end
                        end
                    end
                end


                DestroyEntity(self)

            end

        end

    end
    
    function BabblerPheromone:OnUpdate(deltaTime)

        Projectile.OnUpdate(self, deltaTime)

        if not self.firstUpdate then

            self.firstUpdate = true

            --local gorge = self:GetOwner()
            --for _, babbler in ipairs(GetEntitiesForTeamWithinRange("Babbler", self:GetTeamNumber(), self:GetOrigin(), kBabblerSearchRange )) do
            --
            --    if babbler:GetIsClinged() and babbler:GetOwner() == gorge and babbler:GetParent() == gorge then
            --
            --        babbler:Detach()
            --
            --    end
            --
            --end

        end

    end

end