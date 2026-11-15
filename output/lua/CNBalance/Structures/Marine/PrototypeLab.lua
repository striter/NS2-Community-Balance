Script.Load("lua/SupplyUserMixin.lua")

local baseOnInitialized = PrototypeLab.OnInitialized
function PrototypeLab:OnInitialized()
    baseOnInitialized(self)
    if Server then
        InitMixin(self, SupplyUserMixin)
    end
end

PrototypeLab.kUpgradeToTargetType =
{
    [kTechId.JetpackProtoUpgrade] = kTechId.JetpackPrototypeLab,
    [kTechId.ExosuitProtoUpgrade] = kTechId.ExosuitPrototypeLab,
    [kTechId.CannonProtoUpgrade] = kTechId.CannonPrototypeLab,
}

local function GetResearchAllowed(self, techId)
    local stationTypeTechId = PrototypeLab.kUpgradeToTargetType[techId]
    local available = not GetHasTech(self, stationTypeTechId) and not GetIsTechResearching(self, techId)
    return available and techId or kTechId.None
end

local kStationResearchNodes = {
    [kTechId.ExosuitPrototypeLab] = kTechId.DualWeaponTech,
}

function PrototypeLab:GetTechButtons()

    local techId = self:GetTechId()
    local techButtons = { kTechId.None, kTechId.None, kTechId.None, kTechId.None,
                          kTechId.None, kTechId.None, kTechId.None, kTechId.None }
    if techId == kTechId.PrototypeLab then
        techButtons[1] = GetResearchAllowed(self,kTechId.JetpackProtoUpgrade)
        techButtons[2] = GetResearchAllowed(self,kTechId.ExosuitProtoUpgrade)
        techButtons[5] = GetResearchAllowed(self,kTechId.CannonProtoUpgrade)
    else
        techButtons[1] = kStationResearchNodes[techId] or kTechId.None
    end

    return techButtons
end

if Server then

    function PrototypeLab:UpdateResearch()

        local researchId = self:GetResearchingId()
        local stationTypeTechId = PrototypeLab.kUpgradeToTargetType[researchId]

        if stationTypeTechId then

            local techTree = self:GetTeam():GetTechTree()
            local researchNode = techTree:GetTechNode(stationTypeTechId)
            researchNode:SetResearchProgress(self.researchProgress)
            techTree:SetTechNodeChanged(researchNode, string.format("researchProgress = %.2f", self.researchProgress))

        end
    end

    function PrototypeLab:OnResearchCancel(researchId)

        local stationTypeTechId = PrototypeLab.kUpgradeToTargetType[researchId]
        if stationTypeTechId then

            local team = self:GetTeam()
            if team then
                local techTree = team:GetTechTree()
                local researchNode = techTree:GetTechNode(stationTypeTechId)
                if researchNode then
                    researchNode:ClearResearching()
                    techTree:SetTechNodeChanged(researchNode, string.format("researchProgress = %.2f", 0))
                end
            end
        end
    end

    function PrototypeLab:OnResearchComplete(researchId)
        local upgradeTech = PrototypeLab.kUpgradeToTargetType[researchId]
        if upgradeTech then
            self:UpgradeToTechId(upgradeTech)
        end
        local techTree = self:GetTeam():GetTechTree()
        local researchNode = techTree:GetTechNode(upgradeTech)

        if researchNode then
            researchNode:SetResearchProgress(1)
            techTree:SetTechNodeChanged(researchNode, string.format("researchProgress = %.2f", self.researchProgress))
            researchNode:SetResearched(true)
        end
    end

end

function PrototypeLab:GetItemList(forPlayer)

    if not forPlayer and Client then
        forPlayer = Client.GetLocalPlayer()
    end
    if forPlayer and forPlayer:isa("Exo") then
        local upgradeTechId = GetExoUpgradeTechId(forPlayer)
        return upgradeTechId and { upgradeTechId } or {}
    end
    return { kTechId.Jetpack, kTechId.ClawMinigunExosuit, kTechId.ClawRailgunExosuit, kTechId.Cannon }

end

local baseGetCanBeUsed = PrototypeLab.GetCanBeUsed
function PrototypeLab:GetCanBeUsed(player, useSuccessTable)
    baseGetCanBeUsed(self, player, useSuccessTable)
    if not useSuccessTable.useSuccess and player:isa("Exo")
        and not player:GetHasDualGuns()
        and player:GetTeamNumber() == self:GetTeamNumber()
        and self:GetIsBuilt() and self:GetIsPowered()
    then
        useSuccessTable.useSuccess = true
    end
end

if Client then

    Script.Load("lua/MaterialUtility.lua")

    PrecacheAsset("cinematics/vfx_materials/lab_hologram.surface_shader")
    local kHologramMaterialName = PrecacheAsset("cinematics/vfx_materials/lab_hologram.material")

    local kHologramModels =
    {
        [kTechId.ExosuitPrototypeLab] =
        {
            modelName = PrecacheAsset("models/marine/exosuit/exosuit_cm.model"),
            size = 1.36,
            yaw = 0,
            elevation = 0,
            roll = 0,
            offsetY = -0.28,
        },
        [kTechId.JetpackPrototypeLab] =
        {
            modelName = PrecacheAsset("models/marine/jetpack/jetpack.model"),
            size = 0.9,
            yaw = math.pi,
            elevation = 0,
            roll = 0,
            offsetY = -0.36,
        },
        [kTechId.CannonPrototypeLab] =
        {
            modelName = PrecacheAsset("models/marine/heavy_cannon/heavy_cannon_world.model"),
            size = 1.52,
            yaw = math.pi * 0.5,
            elevation = math.pi * 0.25,
            flip = true,
            offsetY = -0.2,
            shiftX = -0.3,
        },
    }

    local kHologramGap = 1.1
    local kHologramSpinSpeed = 0.9
    local kHologramLabTopFallback = 2.2

    local function DestroyHologram(self)

        if self.hologramRenderModel then

            RemoveMaterial(self.hologramRenderModel, self.hologramMaterial)
            Client.DestroyRenderModel(self.hologramRenderModel)
            self.hologramRenderModel = nil

        end

        self.hologramMaterial = nil
        self.hologramScale = nil
        self.hologramCenterY = nil
        self.hologramBarrelAxis = nil

    end

    local function GetHologramConfig(self)
        return kHologramModels[self:GetTechId()]
    end

    local function GetLabTop(self)

        if not self.hologramLabTop then

            local ok, minExtents, maxExtents = pcall(self.GetModelExtents, self)

            if ok and maxExtents and maxExtents.y > 0 then
                self.hologramLabTop = maxExtents.y
            end

        end

        return self.hologramLabTop or kHologramLabTopFallback

    end

    local function CreateHologram(self)

        local config = GetHologramConfig(self)

        if not config then
            return false
        end

        local modelIndex = Shared.GetModelIndex(config.modelName)

        if not modelIndex or modelIndex == 0 then
            return false
        end

        local renderModel = Client.CreateRenderModel(RenderScene.Zone_Default)

        renderModel:SetModel(modelIndex)
        renderModel:InstanceMaterials()
        renderModel:SetMaterialParameter("hiddenAmount", 1)
        renderModel:SetCastsShadows(false)
        renderModel:SetIsVisible(true)

        local scale = 1
        local centerY = 0
        local model = Shared.GetModel(modelIndex)

        if model then

            local poses = PosesArray()
            local boneCoords = CoordsArray()

            pcall(function() model:GetReferencePose(poses) end)
            pcall(function() model:GetBoneCoords(poses, boneCoords) end)
            pcall(function() renderModel:SetBoneCoords(boneCoords) end)

            local ok, minExtents, maxExtents = pcall(model.GetExtents, model, boneCoords)

            if ok and minExtents and maxExtents then

                local sizeX = maxExtents.x - minExtents.x
                local sizeY = maxExtents.y - minExtents.y
                local sizeZ = maxExtents.z - minExtents.z
                local longest = math.max(sizeX, sizeY, sizeZ)

                if longest > 0.01 then
                    scale = config.size / longest
                end

                centerY = (minExtents.y + maxExtents.y) * 0.5 * scale

                if sizeX >= sizeY and sizeX >= sizeZ then
                    self.hologramBarrelAxis = "x"
                elseif sizeZ >= sizeY then
                    self.hologramBarrelAxis = "z"
                else
                    self.hologramBarrelAxis = "y"
                end

            end

        end

        self.hologramRenderModel = renderModel
        self.hologramMaterial = AddMaterial(renderModel, kHologramMaterialName)
        self.hologramScale = scale
        self.hologramCenterY = centerY

        return true

    end

    local baseOnUpdateRender = PrototypeLab.OnUpdateRender

    function PrototypeLab:OnUpdateRender()

        if baseOnUpdateRender then
            baseOnUpdateRender(self)
        end

        local config = GetHologramConfig(self)

        if not config then
            return
        end

        if self:GetIsPowered() == false then

            if self.hologramRenderModel then
                self.hologramRenderModel:SetIsVisible(false)
            end

            return

        end

        if not self.hologramRenderModel and not CreateHologram(self) then
            return
        end

        local elevation = config.elevation or 0
        local yaw = config.yaw + Shared.GetTime() * kHologramSpinSpeed
        local cosElevation = math.cos(elevation)
        local height = GetLabTop(self) + kHologramGap - (self.hologramCenterY or 0) * cosElevation + (config.offsetY or 0)
        local origin = self:GetOrigin() + Vector.yAxis * height
        local coords

        if self.hologramBarrelAxis == "x" then

            local sinElevation = math.sin(elevation)
            local cosYaw = math.cos(yaw)
            local sinYaw = math.sin(yaw)
            local flip = config.flip and -1 or 1
            local barrelX = Vector(cosElevation * cosYaw, sinElevation, -cosElevation * sinYaw)
            local shift = config.shiftX or 0

            if shift ~= 0 then
                origin = origin + barrelX * shift
            end

            coords = Angles(0, 0, 0):GetCoords(origin)
            coords.xAxis = barrelX * self.hologramScale
            coords.yAxis = Vector(sinYaw, 0, cosYaw) * (self.hologramScale * flip)
            coords.zAxis = Vector(sinElevation * cosYaw, -cosElevation, -sinElevation * sinYaw) * (self.hologramScale * flip)

        else

            coords = Angles(-elevation, yaw, config.roll or 0):GetCoords(origin)
            coords.xAxis = coords.xAxis * self.hologramScale
            coords.yAxis = coords.yAxis * self.hologramScale
            coords.zAxis = coords.zAxis * self.hologramScale

        end

        self.hologramRenderModel:SetIsVisible(true)
        self.hologramRenderModel:SetCoords(coords)

    end

    local baseOnDestroy = PrototypeLab.OnDestroy

    function PrototypeLab:OnDestroy()

        if baseOnDestroy then
            baseOnDestroy(self)
        end

        DestroyHologram(self)

    end

end

class 'ExosuitPrototypeLab' (PrototypeLab)
ExosuitPrototypeLab.kMapName = "exosuit_prototypelab"

class 'JetpackPrototypeLab' (PrototypeLab)
JetpackPrototypeLab.kMapName = "jetpack_prototypelab"

class 'CannonPrototypeLab' (PrototypeLab)
CannonPrototypeLab.kMapName = "cannon_prototypelab"
