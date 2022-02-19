

function PrototypeLab:GetPrototypeSupplyUnavailable()
        local researched=GetHasTech(self,kTechId.JetpackSupply) or 
                         GetHasTech(self,kTechId.ExosuitSupply)

        if researched then
                return true
        end

        local researching = GetIsTechResearching(self,kTechId.JetpackSupply) or
                            GetIsTechResearching(self,kTechId.ExosuitSupply)
        return researching
end

function PrototypeLab:GetTechButtons(techId)
    local techTable = { kTechId.JetpackTech, kTechId.JetpackFuelTech, kTechId.None, kTechId.None, 
             kTechId.ExosuitTech, kTechId.None, kTechId.None, kTechId.None }
    
        local supplyUnavailable = self:GetPrototypeSupplyUnavailable()
        if not supplyUnavailable then
                if GetHasTech(self,kTechId.JetpackTech) then
                        techTable[1]=kTechId.JetpackSupply
                end
                if GetHasTech(self,kTechId.ExosuitTech) then
                        -- techTable[5]=kTechId.ExosuitSupply
                end
        end
    return techTable
end