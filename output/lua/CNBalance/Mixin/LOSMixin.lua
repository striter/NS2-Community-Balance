if Server then
    
    
    function LOSMixin:GetLastViewer()

        if self.lastViewerId and self.lastViewerId ~= Entity.invalidId then
        
            local viewer = Shared.GetEntity(self.lastViewerId)
            
            if viewer and not HasMixin(viewer, "LOS") then
                
                Shared.Message(string.format("%s: %s added as a viewer without having LOS mixin", ToString(self), ToString(viewer)))
                self.lastViewerId = Entity.invalidId
                return nil
            end
            
            return viewer
            
        end
        
    end
    
end
