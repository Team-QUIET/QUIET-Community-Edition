do
-- LCE E&F modifies the economy significantly in an experimental and new way to encourage a more active game across all Tiers (1 - 4)
local OldModBlueprints = ModBlueprints
    
function ModBlueprints(all_blueprints)
    
    OldModBlueprints(all_blueprints)
    
    EconomicAlterations(all_blueprints)
    
end

--=======================================
-- FUNCTION ECONOMICALTERATIONS(ALL_BLUEPRINTS)
-- Overrall Economic Alterations that are changing vast amounts of the economic game.
--=======================================
    
function EconomicAlterations(all_blueprints)

    local econScaleT1 = 0
    local econScaleT2 = 0
    local econScaleT3 = 0
    local econScaleT4 = 0

    for id, bp in all_blueprints.Unit do

        -- Eventually, I'll talk to Kami about doing the evenflow rework in this mod instead of touching the mass extractors imo
        -- @Azraeelian Angel

        if bp.Categories then

            for i, cat in bp.Categories do

                -- Rebalance for Factories to cost less
                if cat == 'STRUCTURE' then
                    
                    econScaleT1 = 0.935
                    econScaleT2 = 0.80
                    econScaleT3 = 0.75
                    econScaleT4 = 0.75

                    for j, catj in bp.Categories do

                        if catj == 'FACTORY' then

                            for _, cat_mobile in bp.Categories do
                                if cat_mobile == 'TECH1' then

                                    bp.Economy.BuildCostEnergy = bp.Economy.BuildCostEnergy * econScaleT1

                                    bp.Economy.BuildCostMass = bp.Economy.BuildCostMass * econScaleT1
                                elseif cat_mobile == 'TECH2' then

                                    bp.Economy.BuildCostEnergy = bp.Economy.BuildCostEnergy * econScaleT2
    
                                    bp.Economy.BuildCostMass = bp.Economy.BuildCostMass * econScaleT2
                                elseif cat_mobile == 'TECH3' then

                                    bp.Economy.BuildCostEnergy = bp.Economy.BuildCostEnergy * econScaleT3
    
                                    bp.Economy.BuildCostMass = bp.Economy.BuildCostMass * econScaleT3
                                elseif cat_mobile == 'GATE' then

                                    bp.Economy.BuildCostEnergy = bp.Economy.BuildCostEnergy * econScaleT4
    
                                    bp.Economy.BuildCostMass = bp.Economy.BuildCostMass * econScaleT4
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
end -- do end