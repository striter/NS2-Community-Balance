ElectrifyMixin = CreateMixin(ElectrifyMixin)
ElectrifyMixin.type = "Electrify"

local kEletrifyMaterial = PrecacheAsset("cinematics/vfx_materials/pulse_gre_elec.material")

ElectrifyMixin.expectedCallbacks =
{
}

ElectrifyMixin.optionalCallbacks =
{
    OnDetectedChange = "Called when self.detected changes.",
    GetIsDetectedOverride = "Override to allow implementing classes to have contextual override option (Ex: attached babblers)"
}


ElectrifyMixin.networkVars =
{
    electrified = "boolean"
}

function ElectrifyMixin:__initmixin()

    PROFILE("ElectrifyMixin:__initmixin")
    self.timeElectrifyEnds = 0
    self.electrified = false

end

--function ElectrifyMixin:OnDestroy()
--
--end

function ElectrifyMixin:GetElectrified()
    return self.electrified
end
function ElectrifyMixin:SetElectrified(time)

    if Server then
        if self.timeElectrifyEnds - Shared.GetTime() < time then

            self.timeElectrifyEnds = Shared.GetTime() + time
            self.electrified = true

        end
    end

    self.electrified = true
end

function ElectrifyMixin:OnUpdate()

    PROFILE("ElectrifyMixin:OnUpdateRender")

    if Server then
        self.electrified = self.timeElectrifyEnds > Shared.GetTime()
    end
    
    if Client then

        if self._renderModel then

            if self.electrified and not self.electrifyMaterial then
                
                self.electrifyMaterial = Client.CreateRenderMaterial()
                self.electrifyMaterial:SetMaterial(kEletrifyMaterial)
                self._renderModel:AddMaterial(self.electrifyMaterial)

            elseif not self.electrified and self.electrifyMaterial then

                self._renderModel:RemoveMaterial(self.electrifyMaterial)
                Client.DestroyRenderMaterial(self.electrifyMaterial)
                self.electrifyMaterial = nil

            end
        end

        if self:isa("Player") and self:GetIsLocalPlayer() then

            local viewModelEntity = self:GetViewModelEntity()
            if viewModelEntity then

                local viewModel = self:GetViewModelEntity():GetRenderModel()
                if viewModel and (self.electrified and not self.viewelectrifyMaterial) then

                    self.viewelectrifyMaterial = Client.CreateRenderMaterial()
                    self.viewelectrifyMaterial:SetMaterial(kBurningViewMaterial)
                    viewModel:AddMaterial(self.viewelectrifyMaterial)

                elseif viewModel and (not self.electrified and self.viewelectrifyMaterial) then

                    viewModel:RemoveMaterial(self.viewelectrifyMaterial)
                    Client.DestroyRenderMaterial(self.viewelectrifyMaterial)
                    self.viewelectrifyMaterial = nil

                end

            end

        end
    end
end