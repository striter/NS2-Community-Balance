if Client then
    function JetpackOnBack:GetIsHighlightEnabled()
        local parent = self:GetParent()
        if parent and parent.GetIsHighlightEnabled then
            return parent:GetIsHighlightEnabled()
        end
        return 0.98
    end
end 