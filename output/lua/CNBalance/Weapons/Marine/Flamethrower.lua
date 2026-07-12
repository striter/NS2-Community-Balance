function Flamethrower:CreateFlame(player, position, normal, direction)

    -- create flame entity, but prevent spamming:
    local nearbyFlames = GetEntitiesForTeamWithinRange("Flame", self:GetTeamNumber(), position, 1.7)

    if (#nearbyFlames == 0) then

        local flame = CreateEntity(Flame.kMapName, position, player:GetTeamNumber())
        flame:SetOwner(player)

        local coords = Coords.GetTranslation(position)

        if math.abs(Math.DotProduct(normal, direction)) > 0.9999 then
            direction = normal:GetPerpendicular()
        end

        coords.yAxis = normal
        coords.zAxis = direction

        coords.xAxis = coords.yAxis:CrossProduct(coords.zAxis)
        coords.xAxis:Normalize()

        coords.zAxis = coords.xAxis:CrossProduct(coords.yAxis)
        coords.zAxis:Normalize()

        flame:SetCoords(coords)

    end

end

-- Burn target categories, checked in priority order per step
local kBurnTargets = {
    {
        effectName = "burn_spore",
        classes = { "SporeCloud" },
        radius = kSporesDustCloudRadius,
    },
    {
        effectName = "burn_bomb",
        classes = { "Bomb", "WhipBomb", "AcidMissile", "AcidRocketBomb", "BabblerPheromone", "Spit", "DotMarker" },
        radius = 1.6,
    },
    {
        effectName = "burn_umbra",
        classes = { "CragUmbra", "StormCloud", "MucousMembrane", "EnzymeCloud", "Vortex" },
        -- Each cloud class has its own radius, stored as className
        useClassRadius = true,
    },
}

function Flamethrower:BurnSporesAndUmbra(startPoint, endPoint)

    local now = Shared.GetTime()
    local timeLastBurn = self.timeLastBurn and now - self.timeLastBurn or 0
    self.timeLastBurn = now
    
    local toTarget = endPoint - startPoint
    local length = toTarget:GetLength()
    toTarget:Normalize()

    local stepLength = 2
    for i = 1, 5 do

        if length < i * stepLength then
            break
        end

        local burnSpent = false
        local checkAtPoint = startPoint + toTarget * i * stepLength

        for _, target in ipairs(kBurnTargets) do
            local radius = target.useClassRadius and nil or target.radius
            for _, className in ipairs(target.classes) do
                local r = target.useClassRadius and _G[className].kRadius or radius
                local ents = GetEntitiesWithinRange(className, checkAtPoint, r)
                if #ents > 0 then
                    local ent = ents[1]
                    self:TriggerEffects(target.effectName, { effecthostcoords = Coords.GetTranslation(ent:GetOrigin()) })
                    DestroyEntity(ent)
                    burnSpent = true
                    break
                end
            end
            if burnSpent then break end
        end

        if burnSpent then
            return true
        end

    end

    return false
end

function Flamethrower:ApplyConeDamage(player)

    local eyePos = player:GetEyePos()
    local ents = {}

    local fireDirection = player:GetViewCoords().zAxis
    local extents = Vector(self.kConeWidth, self.kConeWidth, self.kConeWidth)
    local range = self:GetRange()

    local startPoint = Vector(eyePos)
    local filterEnts = {self, player}
    local trace = TraceMeleeBox(self, startPoint, fireDirection, extents, range, PhysicsMask.Flame, EntityFilterList(filterEnts))

    local endPoint = trace.endPoint
    local normal = trace.normal

    -- Check for spores in the way.
    if Server then
        local burned = self:BurnSporesAndUmbra(startPoint, endPoint)
        if burned then
            local owner = self:GetParent()
            if owner then
                owner:AddContinuousScore("FlameThrowerBurns", kFlameThrowerEntityBurnReward, kFlameThrowerEntityBurnRewardInterval, kFlameThrowerEntityBurnScoreRewardEachInterval, kFlameThrowerEntityBurnPResRewardEachInterval)
            end
            self.clip = math.max(1, self.clip - kFlameThrowerBurnSpentExtraAmmoCost)
        end
    end

    if trace.fraction ~= 1 then

        local traceEnt = trace.entity
        if traceEnt and HasMixin(traceEnt, "Live") and traceEnt:GetCanTakeDamage() then
            table.insert(ents, traceEnt)
        end

        local hitEntities = GetEntitiesWithMixinWithinXZRange("Live", endPoint, self.kDamageRadius)
        local damageHeight =  self.kDamageRadius / 2
        for i = 1, #hitEntities do
            local ent = hitEntities[i]
            if ent ~= traceEnt and ent:GetCanTakeDamage() and math.abs(endPoint.y - ent:GetOrigin().y) <= damageHeight then
                table.insert(ents, ent)
            end
        end

        --Create flame below target
        if Server then
            if trace.entity then
                local groundTrace = Shared.TraceRay(endPoint, endPoint + Vector(0, -2.6, 0), CollisionRep.Default, PhysicsMask.CystBuild, EntityFilterAllButIsa("TechPoint"))
                if groundTrace.fraction ~= 1 then
                    fireDirection = fireDirection * 0.55 + normal
                    fireDirection:Normalize()
                    self:CreateFlame(player, groundTrace.endPoint, groundTrace.normal, fireDirection)
                end
            else
                fireDirection = fireDirection * 0.55 + normal
                fireDirection:Normalize()
                self:CreateFlame(player, endPoint, normal, fireDirection)
            end
        end

    end

    local attackDamage = kFlamethrowerDamage
    for i = 1, #ents do
        local ent = ents[i]
        local enemyOrigin = ent:GetModelOrigin()
        if ent ~= player and enemyOrigin then
            local toEnemy = GetNormalizedVector(enemyOrigin - eyePos)
            local health = ent:GetHealth()
            self:DoDamage( attackDamage, ent, enemyOrigin, toEnemy )
            if ent:GetHealth() ~= health and HasMixin(ent, "Fire") then
                ent:SetOnFire(player, self)
            end
        end
    end

end
