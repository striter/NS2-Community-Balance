
local kWebDamageTaken = {
    ["Axe"] = true,
    ["Knife"] = true,
    ["Grenade"] = true,
    ["ClusterGrenade"] = true,
    ["ImpactGrenade"] = true,
    ["SubMachineGun"] = true,
    ["LightMachineGun"] = true,
    ["Flamethrower"] = true,
}

function Web:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint)
    -- webs can't be destroyed with bullet weapons
    if doer ~= nil and  damageType ~= kDamageType.Flame and not kWebDamageTaken[doer:GetClassName()] then
        damageTable.damage = 0
    end

end


local kWebDistortMaterial = PrecacheAsset("models/alien/gorge/web_distort.material")
local kWebCloakedMaterial = PrecacheAsset("cinematics/vfx_materials/cloaked.material")

if Client then

    function Web:OnUpdateRender()

        if self.webRenderModel then
            if self.variant == kGorgeVariants.toxin then
                self._renderModel:SetMaterialParameter("textureIndex", 1 )
            else
                self._renderModel:SetMaterialParameter("textureIndex", 0 )
            end
        end

        if not self:GetIsCamouflaged() then return end

        local player = Client.GetLocalPlayer()
        local model = self:GetRenderModel()

        if player and model and self.endPoint then

            local isFriendly = GetAreFriends(self, player)

            -- Try distances from both endpoints and the middle, and use the shortest one.
            -- We compare the midpoint and the origin distance first, since the midpoint is the most common case in-game (from close range)
            local midPoint = (self:GetOrigin() + self.endPoint) * 0.5
            local midDistance = (midPoint - player:GetOrigin()):GetLengthSquared()
            local originDistance = (self:GetOrigin() - player:GetOrigin()):GetLengthSquared()

            local distance = midDistance

            -- Since midpoint will never be the furthest point, we can potentially eliminate a length calculation.
            if originDistance <= midDistance then
                distance = originDistance
            else
                -- Either the endpoint or midpoint is closest
                local endDistance = (self.endPoint - player:GetOrigin()):GetLengthSquared()
                if endDistance < midDistance then
                    distance = endDistance
                end
            end

            distance = math.sqrt(distance)
            local opaque = Clamp((distance - kWebFullVisDistance) / (kWebZeroVisDistance - kWebFullVisDistance), 0, 1)

            if isFriendly then
                if not self.cloakedMaterial then
                    self.cloakedMaterial = AddMaterial(model, kWebCloakedMaterial)
                end

                if self.distortMaterial then
                    RemoveMaterial(model, self.distortMaterial)
                    self.distortMaterial = nil
                end
            else
                if not self.distortMaterial then
                    self.distortMaterial = AddMaterial(model, kWebDistortMaterial)
                    self.distortMaterial:SetParameter("noVisDist", kWebDistortionZeroVisDistance)
                    self.distortMaterial:SetParameter("fullVisDist", kWebDistortionFullVisDistance)
                    self.distortMaterial:SetParameter("distortionIntensity", kWebDistortionIntensity)
                end

                if self.cloakedMaterial then
                    RemoveMaterial(model, self.cloakedMaterial)
                    self.cloakedMaterial = nil
                end
            end

            if self.cloakedMaterial then
                self:SetOpacity(1 - opaque, "cloak")
                self.cloakedMaterial:SetParameter("cloakAmount", Clamp(opaque, 0, 0.2))
            end

            if self.distortMaterial then
                self:SetOpacity(1 - opaque, "cloak")
            end
        end

    end

end

function Web:GetIsCamouflaged()
    return true -- GetIsTechUnlocked(self,kTechId.Veil)
end