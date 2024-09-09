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
    local T2_Adjustment = 0
    local T3_Adjustment = 0
    local T4_Adjustment = 0
    local energyScale = 0

    for id, bp in all_blueprints.Unit do

        if bp.Categories then

            for i, cat in bp.Categories do

                -- Economic Progression Rework
                -- This increases mass production at the T2 & T3 phase to encourage far more activity in the late early to mid late game.
                -- This also seeks to smooth out the transitions between t1 -> t2 & t2 -> t3
                if cat == 'ECONOMIC' then

                    econScaleT2 = 1.25
                    econScaleT3 = 1.325

                    for j, catj in bp.Categories do

                        if catj == 'MASSEXTRACTION' then

							T2_Adjustment = 1.5
							T3_Adjustment = 1.5
                            energyScale = 1.1

                            for _, cat_mobile in bp.Categories do

                                if cat_mobile == 'TECH2' then

                                    bp.Economy.ProductionPerSecondMass = bp.Economy.ProductionPerSecondMass * T2_Adjustment

                                    bp.Economy.BuildCostEnergy = bp.Economy.BuildCostEnergy * econScaleT2

                                    bp.Economy.BuildCostMass = bp.Economy.BuildCostMass * econScaleT2

                                    bp.Economy.MaintenanceConsumptionPerSecondEnergy = bp.Economy.MaintenanceConsumptionPerSecondEnergy * energyScale

                                elseif cat_mobile == 'TECH3' and not bp.Enhancements then

                                    bp.Economy.ProductionPerSecondMass = bp.Economy.ProductionPerSecondMass * T3_Adjustment

                                    bp.Economy.BuildCostEnergy = bp.Economy.BuildCostEnergy * econScaleT3

                                    bp.Economy.BuildCostMass = bp.Economy.BuildCostMass * econScaleT3

                                    bp.Economy.MaintenanceConsumptionPerSecondEnergy = bp.Economy.MaintenanceConsumptionPerSecondEnergy * energyScale
                                end
                            end
                        end
                    end
                end

                -- Special Rebalance for Integrated Storage Mass Extractors
                if cat == 'ECONOMIC' then

                    econScaleT4 = 2.25
                    energyScale = 1.2

                    for j, catj in bp.Categories do

                        if catj == 'MASSEXTRACTION' then

							T4_Adjustment = 1.18

                            for _, cat_mobile in bp.Categories do
                                if cat_mobile == 'TECH3' and bp.Enhancements then

                                    bp.Economy.ProductionPerSecondMass = bp.Economy.ProductionPerSecondMass * T4_Adjustment

                                    bp.Economy.BuildCostEnergy = bp.Economy.BuildCostEnergy * econScaleT4

                                    bp.Economy.BuildCostMass = bp.Economy.BuildCostMass * econScaleT4

                                    bp.Economy.MaintenanceConsumptionPerSecondEnergy = bp.Economy.MaintenanceConsumptionPerSecondEnergy * energyScale
                                end
                            end
                        end
                    end
                end

                -- Rebalance for Factories to cost less
                if cat == 'STRUCTURE' then
                    
                    econScaleT1 = 0.95
                    econScaleT2 = 0.80
                    econScaleT3 = 0.75

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