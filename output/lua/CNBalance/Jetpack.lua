

function Jetpack:OnInitialized()

    ScriptActor.OnInitialized(self)
    self:SetModel(Jetpack.kModelName)

    local coords = self:GetCoords()
    local raisedCoords = Coords.GetTranslation(coords.origin + Vector(0, 0.3, 0))

    self.jetpackBody = Shared.CreatePhysicsSphereBody(false, 0.55, 0, raisedCoords)
    self.jetpackBody:SetCollisionEnabled(true)
    self.jetpackBody:SetGroup(PhysicsGroup.WeaponGroup)
    self.jetpackBody:SetEntity(self)

end
