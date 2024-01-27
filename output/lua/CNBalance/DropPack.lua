
if Server then

    function DropPack:OnUpdate(deltaTime)
    
        PROFILE("DropPack:OnUpdate")
    
        ScriptActor.OnUpdate(self, deltaTime)    
        
        -- update fall
        
        local weapon = self.weapon and Shared.GetEntity(self.weapon)

        if self.onGroundPoint and self.onGroundPoint ~= self:GetOrigin() and self.fallSpeed and weapon == nil then
            
            self.fallSpeed = math.min(50, self.fallSpeed + deltaTime * 9.81)
            self:SetOrigin(SlerpVector(self:GetOrigin(), self.onGroundPoint, deltaTime * self.fallSpeed))
            
        elseif weapon ~= nil and weapon.weaponWorldState == true then
            if self:GetOrigin() ~= weapon:GetOrigin() then
                self.onGroundPoint = nil
                self:SetOrigin(weapon:GetOrigin())
            end
        
        elseif not (weapon ~= nil and weapon.weaponWorldState == true) then
            local trace = Shared.TraceRay(self:GetOrigin() + kUpVector * 0.025, self:GetOrigin() - kUpVector * 20, CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterOneAndIsa(self, "Player"))
            self:SetOrigin(Vector(trace.endPoint))
            
            self.weapon = nil
            
        elseif not self.hitStaticGround then

            if not self.lastOnGroundUpdate or self.lastOnGroundUpdate + 0.1 < Shared.GetTime() then        

                self.lastOnGroundUpdate = Shared.GetTime()
                
                local trace = Shared.TraceRay(self:GetOrigin() + kUpVector * 0.025, self:GetOrigin() - kUpVector * 20, CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterOneAndIsa(self, "Player"))
                if trace.fraction ~= 1 and self:GetOrigin().y - trace.endPoint.y > 0.025 then
                    
                    self.onGroundPoint = Vector(trace.endPoint)
                    self.fallSpeed = 0
                    
                else                
                    self.onGroundPoint = nil                    
                end
                
                if not trace.entity and trace.fraction ~= 1 then
                    self.hitStaticGround = true
                end
                
                if trace.fraction ~= 1 then                
                    
                    local coords = self:GetCoords()
                    coords.yAxis = trace.normal                    
                    coords.xAxis = coords.yAxis:CrossProduct(coords.zAxis)
                    coords.zAxis = coords.xAxis:CrossProduct(coords.yAxis)
                    
                    self.desiredAngles = Angles()
                    self.desiredAngles:BuildFromCoords(coords)
                    self.setAngleStartTime = Shared.GetTime()
                
                end
            
            end
        
        end

        
        -- set angles when on ground

        if self.desiredAngles then
        
            if self.onGroundPoint == nil or self.onGroundPoint == self:GetOrigin() then

                self:SetAngles(SlerpAngles(self:GetAngles(), self.desiredAngles, deltaTime * 5))
                
                if self.setAngleStartTime + 4 < Shared.GetTime() then
                    self.desiredAngles = nil
                end
                
            end
        
        end

        -- update pickup

        local playersNearby = GetEntitiesForTeamWithinXZRange( "Player", self:GetTeamNumber(), self:GetOrigin(), self.pickupRange )
        Shared.SortEntitiesByDistance(self:GetOrigin(), playersNearby)

        for _, player in ipairs(playersNearby) do
        
            if not player:isa("Commander") 
                    and not player:isa("DevouredPlayer")
                    and self:GetIsValidRecipient(player) then
            
                self:OnTouch(player)
                DestroyEntity(self)
                break
                
            end
        
        end
        
    end

end
