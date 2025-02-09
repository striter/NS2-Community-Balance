Script.Load("lua/Mixins/SignalEmitterMixin.lua")

local ns2_OnInitialized = Contamination.OnInitialized
function Contamination:OnInitialized()
    InitMixin(self, SignalEmitterMixin)

    ns2_OnInitialized(self)

    if Server then
        self:SetSignalRange(1000)
        self:EmitSignal(0, kSignalFuncMaid)
    end
end
