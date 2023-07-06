
function RecycleMixin:OnRecycled()
    if self.PreOnKill then
        self:PreOnKill(nil,nil,nil,nil) --The nil army!
    end
end