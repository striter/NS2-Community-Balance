--
--	ns2siege+ Custom Game Mode
--	ZycaR (c) 2016
--
Script.Load("lua/Mixins/SignalEmitterMixin.lua")

local ns2_OnInitialized = Cyst.OnInitialized
function Cyst:OnInitialized()
    InitMixin(self, SignalEmitterMixin)

    ns2_OnInitialized(self)

    if Server then
        self:SetSignalRange(1000)
        self:EmitSignal(0, kSignalFuncMaid)
    end
end
