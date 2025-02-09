-- sg_TunnelEntrance
-- We need to prevent Gorge Tunnels from getting too close to the door which
-- would spread infestation through it (alllowing comms to shift eggs through
-- during pre-game)

Script.Load("lua/Mixins/SignalEmitterMixin.lua")



local ns2_OnInitialized = TunnelEntrance.OnInitialized
function TunnelEntrance:OnInitialized()
    InitMixin(self, SignalEmitterMixin)

    ns2_OnInitialized(self)

    if Server then
        self:SetSignalRange(1000)
        self:EmitSignal(0, kSignalFuncMaid)
    end
end
