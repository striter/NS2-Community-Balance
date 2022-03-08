if Server then

    local kTechIdToLifeformHeal =
    {
        [kTechId.Skulk] = 10,
        [kTechId.Gorge] = 15,
        [kTechId.Lerk] = 16,
        [kTechId.Fade] = 25,
        [kTechId.Onos] = 80,
    }

    function Crag:TryHeal(target)

        local unclampedHeal = target:GetMaxHealth() * Crag.kHealPercentage
        local heal = Clamp(unclampedHeal, Crag.kMinHeal, Crag.kMaxHeal)

        if target.GetTechId then
            heal = kTechIdToLifeformHeal[target:GetTechId()] or heal
        end

        if self.healWaveActive then
            heal = heal * Crag.kHealWaveMultiplier
        end

        if (not target.timeLastCragHeal or target.timeLastCragHeal + Crag.kHealInterval <= Shared.GetTime()) then

            local canAttach =  HasMixin(target, "BabblerCling") and target:GetCanAttachBabbler()
            local ownerBlocked = HasMixin(target,"BabblerOwner") and target:GetBabblerCount() >= target:GetMaxBabblers()
            if canAttach and not ownerBlocked then
                local babbler = CreateEntity(Babbler.kMapName, self:GetOrigin(), self:GetTeamNumber())
                -- -- babbler:SetSilenced(false)
    
                local client = target:GetClient()
                if client and client.variantData then
                    babbler:SetVariant( client.variantData.babblerVariant )
                end
                babbler:TriggerEffects("babbler_engage")
                babbler:SetOwner(target)
                babbler.clinged = true
                babbler:Detach(true)
                babbler:SetMoveType(kBabblerMoveType.Cling, target, position, true)
                target.timeLastCragHeal = Shared.GetTime()
            end
            
            if target:GetHealthScalar() ~= 1 then
                target.timeLastCragHeal = Shared.GetTime()
                return target:AddHealth(heal, false, false, false, self, true)
            end

        end
        return 0
    end
end