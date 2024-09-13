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

    --local econScaleT1 = 0
    --local econScaleT2 = 0
    --local econScaleT3 = 0
    --local econScaleT4 = 0
    --[[local T2_Adjustment = 0
    local T3_Adjustment = 0
    local T4_Adjustment = 0

    for id, bp in all_blueprints.Unit do

        -- Eventually, I'll talk to Kami about doing the evenflow rework in this mod instead of touching the mass extractors imo
        -- @Azraeelian Angel

        if bp.Categories then

            for i, cat in bp.Categories do

                -- Nerf Hydrocarbon Income
                if cat == 'ECONOMIC' then
                    
                    --econScaleT1 = 0.95
                    --econScaleT2 = 0.925
                    --econScaleT3 = 0.915
                    --econScaleT4 = 0.90
                    T2_Adjustment = 0.90
                    T3_Adjustment = 0.80
                    T4_Adjustment = 0.75

                    for j, catj in bp.Categories do

                        if catj == 'HYDROCARBON' then

                            for _, cat_mobile in bp.Categories do
                                if cat_mobile == 'TECH2' then

                                    bp.Economy.ProductionPerSecondMass = bp.Economy.ProductionPerSecondMass * T2_Adjustment

                                elseif cat_mobile == 'TECH3' and not bp.Enhancements then

                                    bp.Economy.ProductionPerSecondMass = bp.Economy.ProductionPerSecondMass * T3_Adjustment

                                elseif cat_mobile == 'TECH3' and bp.Enhancements then

                                    bp.Economy.ProductionPerSecondMass = bp.Economy.ProductionPerSecondMass * T4_Adjustment
                                end
                            end
                        end
                    end
                end
            end
        end
    end]]--
end
end -- do end