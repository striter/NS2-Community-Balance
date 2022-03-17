    function Cyst:GetIsActuallyConnected()
        
        -- Always in dev mode, for making movies and testing
        if Shared.GetDevMode() then
            return true
        end
        
        local parent = self:GetCystParent()
        if parent then
        
            if parent:isa("Hive") then
                return true
            end

            if parent:isa("TunnelEntrance") then
                return true
            end
            
            return parent:GetIsActuallyConnected()
            
        end
        
        return false
        
    end