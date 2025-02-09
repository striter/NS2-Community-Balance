
Script.Load("lua/Mixins/SignalEmitterMixin.lua")

local oldInitialized = TeamMixin.OnInitialized
function TeamMixin:OnInitialized()
  InitMixin(self, SignalEmitterMixin)
  oldInitialized(self)
  if Server then
    self:SetSignalRange(1000)
    self:EmitSignal(0, kSignalFuncMaid)
  end
end