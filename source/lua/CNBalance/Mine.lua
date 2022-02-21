if Client then
    
    function Mine:GetIsHighlightEnabled()
        local highlight = 1
        
        Shared.Message("Mine" .. tostring(GetHasTech(self,kTechId.MinesUpgrade)) )
        if GetHasTech(self,kTechId.MinesUpgrade) then
            highlight = 0.94
        end 

        return 1
    end
    
end
