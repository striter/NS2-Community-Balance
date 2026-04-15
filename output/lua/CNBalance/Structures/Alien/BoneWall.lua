
function BoneWall:OnInitialized()

    CommanderAbility.OnInitialized(self)
    
    self.spawnPoint = self:GetOrigin()
    self:SetModel(BoneWall.kModelName, kAnimationGraph)
    
    if Server then
        self:TriggerEffects("bone_wall_burst")
        
        local team = self:GetTeam()
        if team then
            local level = math.max(0, team:GetBioMassLevel() - 1)
            local newMaxHealth = kBoneWallHealth + level * kBoneWallHealthPerBioMass + GetPlayersAboveLimit(self:GetTeamNumber()) * kBoneWallExtraHealthPerPlayer
            if newMaxHealth ~= self.maxHealth  then
                self:SetMaxHealth(newMaxHealth)
                self:SetHealth(self.maxHealth)
            end
        end
    end
    
    -- Make the structure kinematic so that the player will collide with it.
    self:SetPhysicsType(PhysicsType.Kinematic)

end


function BoneWall:GetReceivesStructuralDamage()
    return false
end