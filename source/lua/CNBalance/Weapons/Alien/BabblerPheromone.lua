if Server then
    
    local kBabblerSearchRange = 1000
    local kMaxBabblerCount = 9

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
                if moveType == kBabblerMoveType.Attack then
                    do
                        if owner:GetBabblerCount() < kMaxBabblerCount then
                            local babbler = CreateEntity(Babbler.kMapName, origin, owner:GetTeamNumber())
                            babbler:SetOwner(owner)
                            babbler:SetSilenced(false)
                
                            local client = owner:GetClient()
                            if client and client.variantData then
                                babbler:SetVariant( client.variantData.babblerVariant )
                            end
                            babbler:TriggerEffects("babbler_engage")
                            babbler:SetMoveType(moveType, entity, origin, true)
                        end
                    end
                end

                for _, babbler in ipairs(GetEntitiesForTeamWithinRange("Babbler", self:GetTeamNumber(), origin, kBabblerSearchRange )) do

                    if babbler:GetOwner() == owner then

                        if babbler:GetIsClinged() and babbler:GetParent() == owner then
                            babbler:Detach()
                        end
                        
                        -- moveType, entity, position, boolean value
                        local position = HasMixin(entity, "Target") and entity:GetEngagementPoint() or entity:GetOrigin()
                        babbler:SetMoveType(moveType, entity, position, true)
                        if moveType == kBabblerMoveType.Attack then
                            babbler:TriggerEffects("babbler_engage")
                        end
                    end

                end

                DestroyEntity(self)

            end

        end

    end
    
end