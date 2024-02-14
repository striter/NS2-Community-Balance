function Weapon:OnUpdateRender()

    local parent = self:GetParent()
    local settings = self:GetUIDisplaySettings()
    if parent and parent:GetIsLocalPlayer() and settings then

        local isActive = self:GetIsActive()
        local mapName = settings.textureNameOverride or self:GetMapName()
        local ammoDisplayUI = GetWeaponDisplayManager():GetWeaponDisplayScript(settings, mapName)
        self.ammoDisplayUI = ammoDisplayUI
        
        ammoDisplayUI:SetGlobal("weaponClip", parent:GetWeaponClip())
        ammoDisplayUI:SetGlobal("weaponClipSize", parent:GetWeaponClipSize())
        ammoDisplayUI:SetGlobal("weaponAmmo", parent:GetWeaponAmmo())
        ammoDisplayUI:SetGlobal("weaponAuxClip", parent:GetAuxWeaponClip())

        if settings.variant and isActive then
            --[[
                Only update variant if we are the active weapon, since some
                of these GUIViews are re-used. For example, the Builder and Welder GUIViews are one
                and the same, which could cause (randomly, depending on the order of execution) the builder
                to override the variant of the welder due to this method being called for both weapons, and the
                builder's UpdateRender function being called _after_ the welder's.
            --]]
            ammoDisplayUI:SetGlobal("weaponVariant", settings.variant)
        end
        self.ammoDisplayUI:SetGlobal("globalTime", Shared.GetTime())
        -- For some reason I couldn't pass a bool here so... this is for modding anyways!
        -- If you pass anything that's not "true" it will disable the low ammo warning
        self.ammoDisplayUI:SetGlobal("lowAmmoWarning", tostring(Weapon.kLowAmmoWarningEnabled))
        
        -- Render this frame, if the weapon is active.  This is called every frame, so we're just
        -- saying "render one frame" every frame it's equipped.  Easier than keeping track of
        -- when the weapon is holstered vs equipped, and this call is super cheap.
        if isActive then
            self.ammoDisplayUI:SetRenderCondition(GUIView.RenderOnce)
        end
        
    end
    
end

if Server then

    local ignoredWeapons = set { "Pistol", "Rifle" , "SubMachineGun" ,"LightMachineGun" , "Revolver"}
    function Weapon:StartExpiration()

        self.weaponWorldStateTime = Shared.GetTime()
        self.expireTime = Shared.GetTime() +  kWeaponStayTime

        if GetHasTech(self,kTechId.MilitaryProtocol) then
            self.expireTime = self.expireTime + kMilitaryProtocolWeaponAdditionalStayTime
        end

        if not self.timerActive then
        self.timerActive = true
        self:AddTimedCallback(self.CheckExpireTime, 0.5)
        end
        
    end

    -- The return value for this function tells the TimedCallback engine whether or not to repeat the timer. True means repeat.
    function Weapon:CheckExpireTime()
        PROFILE("Weapon:CheckExpireTime")

        if self:GetExpireTime() == 0 then
            self.timerActive = false
            return false
        end

        if not self.weaponWorldState then
            self.timerActive = false
            return false
        end

        -- don't check if there are nearby armories for weapons that should decay at armory
        if ignoredWeapons[self:GetClassName()] then
            return true
        end

        if #GetEntitiesForTeamWithinRange("Marine", self:GetTeamNumber(), self:GetOrigin(), 1.5) > 0 then
            self.weaponWorldStateTime = Shared.GetTime()
            self.expireTime = Shared.GetTime() + kWeaponStayTime
            if GetHasTech(self,kTechId.MilitaryProtocol) then
                self.expireTime = self.expireTime + kMilitaryProtocolWeaponAdditionalStayTime
            end
            return true
        end

        local armories = GetEntitiesForTeamWithinRange("Armory", self:GetTeamNumber(), self:GetOrigin(), kArmoryDroppedWeaponAttachRange)
        local nearbyArmory = false
        for _, armory in ipairs(armories) do
            if GetIsUnitActive(armory) then
                nearbyArmory = true
                break
            end
        end


        if nearbyArmory then
            self:PreventExpiration()
            return false
        end

        return true
    end
end