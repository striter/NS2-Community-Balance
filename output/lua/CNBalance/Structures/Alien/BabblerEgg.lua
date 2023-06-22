Script.Load("lua/PointGiverMixin.lua")

local baseOnCreate = BabblerEgg.OnCreate
function BabblerEgg:OnCreate()
    baseOnCreate(self)
    InitMixin(self, PointGiverMixin)
end

if Server then
    
    function BabblerEgg:GetSendDeathMessageOverride()
        return not self.consumed
    end

    --Actually Babbler Egg
    function BabblerEgg:HatchBabbler(owner)
        
        local client = owner:GetClient()
        local varaint = client and client.variantData and client.variantData.babblerVariant
        local babbler = CreateEntity(Babbler.kMapName, self:GetOrigin(), self:GetTeamNumber())
        -- -- babbler:SetSilenced(false)
        if varaint then
            babbler:SetVariant( varaint )
        end

        babbler:TriggerEffects("babbler_engage")
        babbler:SetOwner(owner)
        babbler.clinged = true
        babbler:Detach(true)
        return babbler
    end
    
    function BabblerEgg:OnTakeDamage(_, attacker, doer)
        -- if self:GetIsBuilt() then
        --     local owner = self:GetOwner()
        --     local doerClassName = doer and doer:GetClassName()

        --     if owner and doer and attacker == owner and doerClassName == "Spit" then
        --         self:Explode()
        --     end
        -- end
    end

    function BabblerEgg:OnKill(attacker, doer, point, direction)
        self:TriggerEffects("death")
        
        if not self:GetIsBuilt() then return end
        
        local owner = self:GetOwner()
        if  owner and owner.GetBabblerCount and attacker then
            for i=1 ,kBabblerExplodeAmount ,1 do
                local babbler = self:HatchBabbler(owner)
                babbler:SetMoveType(kBabblerMoveType.Attack, attacker, attacker:GetOrigin(), true)
            end
            self:TriggerEffects("Babbler_hatch")
            DestroyEntity(self)
        else
            self:Explode()
        end
        
    end

    function BabblerEgg:TryBabblerHatch()
        local owner = self:GetOwner()
        if not owner then
            self:Explode()
            return false
        end
        
        if self:GetIsBuilt() and owner.GetBabblerCount and owner:GetBabblerCount() < kBabblerHatchMaxAmount then
            local otherTeam = GetEnemyTeamNumber(self:GetTeamNumber())
            local allEnemies = GetEntitiesWithMixinForTeamWithinRange("Live", otherTeam, self:GetOrigin(), kBabblerEggHatchRadius)
            
            local enemies = {}
            for _, ent in ipairs(allEnemies) do
                if ent:GetIsAlive() then
                    table.insert(enemies, ent)
                end
            end

            Shared.SortEntitiesByDistance(self:GetOrigin(), enemies)
            for _, ent in ipairs(enemies) do
                local babbler = self:HatchBabbler(owner)
                babbler:SetMoveType(kBabblerMoveType.Attack, ent, ent:GetOrigin(), true)
                break;
            end
        end

        return self:GetIsAlive()
    end

    function BabblerEgg:Arm()
        if self:DetectThreat() ~= false then
            self:AddTimedCallback(BabblerEgg.TryBabblerHatch, kBabblerEggHatchInterval)
        end
    end

end
