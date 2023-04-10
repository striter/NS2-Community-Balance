

function Parasite:OnHolster(player)

    Ability.OnHolster(self, player)
    self.timeLastAttack = 0
end

function Parasite:GetEnergyCost()
    local player = self:GetParent()
    if player and player.hasAdrenalineUpgrade then
        return kAdrenalineParasiteEnergyCost
    end
    return kParasiteEnergyCost
end