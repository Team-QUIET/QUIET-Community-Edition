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


    -- log all changes
    local show_log = false

    -- this controls the buildpower of factories and the buildtime of the units they build
    -- by multiplying the buildpower AND the time of the units they build, the overall impact
    -- of 'assisting' is divided - which helps to curb 'engineer spam'

    -- this effectively divides the buildpower of factories so their buildpower is NOT 1 to 1 like the engineers
    -- and is the factor which controls the difference in resource usage between factories and engineers
    -- if you reduce this value, the factories will build faster

    local factory_buildpower_ratio = 4


    -- the result of the above effectively divides the buildpower of the factorys by 4
    -- this means that a factory with a buildpower of 40 will be able to utilize 40/4 or 10 mass per tick


    --- Here is where we will try and equalize BUILD POWER for engineers building STRUCTURES
    -- using the current mass and energy costs, we calc a new buildtime using the max mass and energy
    -- we'll use the buildtime that is the longest which means we cap mass or energy at the max rate

    --loop through the blueprints and adjust as desired.
    for id,bp in pairs(all_blueprints.Unit) do

        if bp.IgnoreEvenflow == true then
            break
        end

        if bp.Categories then

            local max_mass, max_energy
            local alt_mass, alt_energy

            for i, cat in ipairs(bp.Categories) do

                local reportflag = false

                local oldtime = 0

                -- structures --
                if cat == 'STRUCTURE' then

                    for j, catj in ipairs(bp.Categories) do

                        if catj == 'TECH1' then

                            max_mass = 5
                            max_energy = 50

                            if bp.Economy.BuildTime then

                                alt_mass =  bp.Economy.BuildCostMass/max_mass * 5
                                alt_energy = bp.Economy.BuildCostEnergy/max_energy * 5

                                local best_adjust = math.ceil(math.max( 1, alt_mass, alt_energy))

                                if best_adjust ~= math.ceil(bp.Economy.BuildTime) then

                                    oldtime = bp.Economy.BuildTime
                                    bp.Economy.BuildTime = best_adjust
                                    reportflag = true
                                end
                            end
                        end

                        if catj == 'TECH2' then

                            max_mass = 10
                            max_energy = 100

                            if bp.Economy.BuildTime then

                                alt_mass =  bp.Economy.BuildCostMass/max_mass * 10
                                alt_energy = bp.Economy.BuildCostEnergy/max_energy * 10

                                local best_adjust = math.ceil(math.max( 1, alt_mass, alt_energy))

                                if best_adjust ~= math.ceil(bp.Economy.BuildTime) then

                                    oldtime = bp.Economy.BuildTime
                                    bp.Economy.BuildTime = best_adjust
                                    reportflag = true
                                end
                            end
                        end

                        if catj == 'TECH3' then

                            max_mass = 15
                            max_energy = 150

                            if bp.Economy.BuildTime then

                                alt_mass =  bp.Economy.BuildCostMass/max_mass * 15
                                alt_energy = bp.Economy.BuildCostEnergy/max_energy * 15

                                local best_adjust = math.ceil(math.max( 1, alt_mass, alt_energy))

                                if best_adjust ~= math.ceil(bp.Economy.BuildTime) then

                                    oldtime = bp.Economy.BuildTime
                                    bp.Economy.BuildTime = best_adjust
                                    reportflag = true
                                end
                            end
                        end

                        if catj == 'EXPERIMENTAL' then

                            max_mass = 60
                            max_energy = 600

                            if bp.Economy.BuildTime then

                                alt_mass =  bp.Economy.BuildCostMass/max_mass * 60
                                alt_energy = bp.Economy.BuildCostEnergy/max_energy * 60

                                local best_adjust = math.ceil(math.max( 1, alt_mass, alt_energy))

                                if best_adjust ~= math.ceil(bp.Economy.BuildTime) then

                                    oldtime = bp.Economy.BuildTime
                                    bp.Economy.BuildTime = best_adjust
                                    reportflag = true
                                end
                            end
                        end

                        -- factories would have immense self-upgrade speeds without this
                        if catj == 'FACTORY' then

                            -- this is not the best solution for factory upgrades since it doesn't
                            -- quite follow the rules for factory built units - but it's close enough
                            -- and reasonably balanced across the factory types

                            if bp.General.UpgradesFrom ~= nil then
                                bp.Economy.BuildTime = bp.Economy.BuildTime * 2.75
                            end

                        end

                    end

                    -- this covers MOBILE Factories - namely Cybran Eggs - which are structures themselves that produce mobile units
                    if bp.Economy.BuildUnit then
                        bp.Economy.BuildTime = bp.Economy.BuildTime * (1/2) * factory_buildpower_ratio
                    end

                end

                -- units --
                if cat == 'MOBILE' then		-- ok lets handle all the factory built mobile units and mobile experimentals

                    -- You'll notice that I allow factory built units to build with higher energy limits (scales up thru tiers - 20,30,45)
                    -- this compensates somewhat for the division of their buildpower (in particular for the energy heavy air factories)
                    for j, catj in ipairs(bp.Categories) do

                        if catj == 'TECH1' then

                            local buildpower = 40	-- default T1 factory buildpower

                            max_mass = buildpower / factory_buildpower_ratio
                            max_energy = (buildpower * 20) / factory_buildpower_ratio

                            if bp.Economy.BuildTime then

                                alt_mass =  bp.Economy.BuildCostMass/max_mass		-- about 10 mass/second
                                alt_energy = bp.Economy.BuildCostEnergy/max_energy	-- about 200 energy/second

                                -- regardless of the mass & energy, a minimum build time of 1 second is required
                                -- or else you get very wierd economy results when building the unit
                                local best_adjust = math.max( 1, alt_mass, alt_energy)

                                --LOG("*AI DEBUG id is "..repr(catj).." "..id.."  alt_mass is "..alt_mass.."  alt_energy is "..alt_energy.." Adjusting Buildtime from "..repr(bp.Economy.BuildTime).." to "..( best_adjust * buildpower ) )

                                if math.ceil( best_adjust * buildpower ) ~= math.ceil(bp.Economy.BuildTime) then

                                    oldtime = bp.Economy.BuildTime

                                    --LOG("*AI DEBUG id is "..repr(catj).." "..id.."  alt_mass is "..alt_mass.."  alt_energy is "..alt_energy.." Adjusting Buildtime from "..repr(bp.Economy.BuildTime).." to "..( best_adjust * buildpower ) )

                                    bp.Economy.BuildTime = best_adjust

                                    bp.Economy.BuildTime = math.ceil(bp.Economy.BuildTime * buildpower)

                                    reportflag = true
                                end
                            end
                        end

                        if catj == 'TECH2' then

                            local buildpower = 70	-- default T2 factory buildpower

                            max_mass = buildpower / factory_buildpower_ratio
                            max_energy = (buildpower * 30) / factory_buildpower_ratio

                            if bp.Economy.BuildTime then

                                alt_mass =  bp.Economy.BuildCostMass/max_mass       -- about 17.5 mass/second
                                alt_energy = bp.Economy.BuildCostEnergy/max_energy  -- about 525 energy/second

                                local best_adjust = math.max( 1, alt_mass, alt_energy)

                                if math.ceil( best_adjust * buildpower ) ~= math.ceil(bp.Economy.BuildTime) then

                                    oldtime = bp.Economy.BuildTime

                                    --LOG("*AI DEBUG id is "..repr(catj).." "..id.."  alt_mass is "..alt_mass.."  alt_energy is "..alt_energy.." Adjusting Buildtime from "..repr(bp.Economy.BuildTime).." to "..( best_adjust * buildpower ) )

                                    bp.Economy.BuildTime = best_adjust

                                    bp.Economy.BuildTime = math.ceil(bp.Economy.BuildTime * buildpower)

                                    reportflag = true
                                end
                            end
                        end

                        if catj == 'TECH3' then

                            local buildpower = 100	-- default T3 factory buildpower

                            max_mass = buildpower / factory_buildpower_ratio            -- about 25 mass/second
                            max_energy = (buildpower * 45) / factory_buildpower_ratio   -- about 1125 energy/second

                            if bp.Economy.BuildTime then

                                alt_mass =  bp.Economy.BuildCostMass/max_mass
                                alt_energy = bp.Economy.BuildCostEnergy/max_energy

                                local best_adjust = math.max( 1, alt_mass, alt_energy)

                                if math.ceil( best_adjust * buildpower ) ~= math.ceil(bp.Economy.BuildTime) then

                                    oldtime = bp.Economy.BuildTime

                                    bp.Economy.BuildTime = best_adjust

                                    bp.Economy.BuildTime = math.ceil(bp.Economy.BuildTime * buildpower)

                                    reportflag = true
                                end
                            end
                        end

                        -- OK - a small problem here - No factory built experimentals - these will be the SACU built MOBILE units
                        -- as engineers they have remarkable bulidpower rates for mass compared to factories - but lower energy rates
                        -- that are only slightly improved over a T2 factory
                        if catj == 'EXPERIMENTAL' then

                            max_mass = 60
                            max_energy = 600

                            if bp.Economy.BuildTime then

                                -- experimental units are not factory built so factory_buildpower_ratio is NO applied (we just use the default SACU buildpower (60)
                                alt_mass =  (bp.Economy.BuildCostMass/max_mass) * 60
                                alt_energy = (bp.Economy.BuildCostEnergy/max_energy) * 60

                                local best_adjust = math.max( 1, alt_mass, alt_energy)

                                if math.ceil( best_adjust ) ~= math.ceil(bp.Economy.BuildTime) then

                                    oldtime = bp.Economy.BuildTime

                                    bp.Economy.BuildTime = math.ceil(best_adjust)

                                    reportflag = true
                                end
                            end
                        end
                    end
                end

                if reportflag then

                    if show_log then

                        LOG("*AI DEBUG class is "..cat.." "..id.." "..bp.Description.."  alt_mass is "..repr(alt_mass).."  alt_energy is "..repr(alt_energy).." Buildtime set to "..repr(bp.Economy.BuildTime).." was "..oldtime)

                    end

                    break   -- onto next unit
                end
            end
        end
    end

    local econScaleT2 = 0
    local econScaleT3M = 0
    local econScaleT3E = 0
    local econScaleT4M = 0
    local econScaleT4E = 0
    local T2_Adjustment = 0
    local T3_Adjustment = 0
    local T4_Adjustment = 0

    for id, bp in all_blueprints.Unit do

        if bp.Categories then

            for i, cat in bp.Categories do

                if cat == 'ECONOMIC' then
                    
                    -- Note: These numbers are exact to replicate what getting to a single Advanced T3 Power Generator would be in mass / energy cost
                    econScaleT2 = 1.20
                    econScaleT3M = 2.347
                    econScaleT3E = 1.627
                    econScaleT4M = 0.399
                    econScaleT4E = 0.5016
                    T2_Adjustment = 0.572
                    T3_Adjustment = 0.5645
                    T4_Adjustment = 0.6394

                    for j, catj in bp.Categories do

                        if catj == 'HYDROCARBON' then

                            for _, cat_mobile in bp.Categories do
                                if cat_mobile == 'TECH2' then

                                    bp.Economy.BuildCostMass = bp.Economy.BuildCostMass * econScaleT2

                                    bp.Economy.ProductionPerSecondEnergy = bp.Economy.ProductionPerSecondEnergy * T2_Adjustment

                                elseif cat_mobile == 'TECH3' and not bp.Enhancements then

                                    bp.Economy.BuildCostMass = bp.Economy.BuildCostMass * econScaleT3M

                                    bp.Economy.BuildCostEnergy = bp.Economy.BuildCostEnergy * econScaleT3E

                                    bp.Economy.ProductionPerSecondEnergy = bp.Economy.ProductionPerSecondEnergy * T3_Adjustment

                                elseif cat_mobile == 'TECH3' and bp.Enhancements then

                                    bp.Economy.BuildCostMass = bp.Economy.BuildCostMass * econScaleT4M

                                    bp.Economy.BuildCostEnergy = bp.Economy.BuildCostEnergy * econScaleT4E

                                    bp.Economy.ProductionPerSecondEnergy = bp.Economy.ProductionPerSecondEnergy * T4_Adjustment
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local EnhancementReduction = 0

    for id, bp in all_blueprints.Unit do

        if bp.Categories then

            for i, cat in bp.Categories do

                if cat == 'STRUCTURE' then
                    
                    -- Note: This is to reduce BuildTime for enhancements to allow them to be completed significantly faster to stimulate T3 Production Further into the game
                    EnhancementReduction = 0.70

                    for j, catj in bp.Categories do

                        if catj == 'FACTORY' then

                            -- Note: had to do a ugly if end / if end method because all t3 factories have these upgrades.. so it would end on the first if and not continue down the elseif statements.
                            for _, cat_mobile in bp.Categories do
                                if cat_mobile == 'TECH3' and bp.Enhancements.ImprovedProduction then

                                    bp.Enhancements.ImprovedProduction.BuildTime = bp.Enhancements.ImprovedProduction.BuildTime * EnhancementReduction

                                end

                                if cat_mobile == 'TECH3' and bp.Enhancements.AdvancedProduction then

                                    bp.Enhancements.AdvancedProduction.BuildTime = bp.Enhancements.AdvancedProduction.BuildTime * EnhancementReduction

                                end

                                if cat_mobile == 'TECH3' and bp.Enhancements.ImprovedMateriels then

                                    bp.Enhancements.ImprovedMateriels.BuildTime = bp.Enhancements.ImprovedMateriels.BuildTime * EnhancementReduction

                                end

                                if cat_mobile == 'TECH3' and bp.Enhancements.AdvancedMateriels then

                                    bp.Enhancements.AdvancedMateriels.BuildTime = bp.Enhancements.AdvancedMateriels.BuildTime * EnhancementReduction
                                
                                end

                                if cat_mobile == 'TECH3' and bp.Enhancements.ExperimentalMateriels then

                                    bp.Enhancements.ExperimentalMateriels.BuildTime = bp.Enhancements.ExperimentalMateriels.BuildTime * EnhancementReduction

                                end
                            end
                        end
                    end
                end
            end
        end
    end

    for id, bp in all_blueprints.Unit do
        local cats = {} -- Note: Just redo the entire blueprints.lua so theres no multi for loops -- We can do it like we did it here instead
        if bp.Categories then
            for k, cat in pairs(bp.Categories) do
                cats[cat] = true
            end

            -- T1 & T2 Air Scout Cost Reduction
            if cats.SCOUT and cats.INTELLIGENCE and cats.HIGHALTAIR and cats.AIR then
                do
                    if cats.TECH1 then
                        bp.Economy.BuildCostEnergy = bp.Economy.BuildCostEnergy * 0.315
                    elseif cats.TECH2 then
                        bp.Economy.BuildCostEnergy = bp.Economy.BuildCostEnergy * 0.5
                    end
                end
            end

            -- Mass Extractor Energy Upkeep Reduction
            if cats.MASSEXTRACTION and cats.STRUCTURE and cats.ECONOMIC then
                do
                    if cats.TECH1 then
                        bp.Economy.MaintenanceConsumptionPerSecondEnergy = bp.Economy.MaintenanceConsumptionPerSecondEnergy * 0.34
                    elseif cats.TECH2 then
                        bp.Economy.MaintenanceConsumptionPerSecondEnergy = bp.Economy.MaintenanceConsumptionPerSecondEnergy * 0.34
                    elseif cats.TECH3 then
                        bp.Economy.MaintenanceConsumptionPerSecondEnergy = bp.Economy.MaintenanceConsumptionPerSecondEnergy * 0.525
                    end
                end
            end

            -- Engineer Cost Reduction
            if cats.ENGINEER and cats.LAND and cats.MOBILE then
                do
                    if cats.TECH1 then
                        bp.Economy.BuildCostEnergy = bp.Economy.BuildCostEnergy * 0.65

                        bp.Economy.BuildCostMass = bp.Economy.BuildCostMass * 0.69
                    elseif cats.TECH2 then
                        bp.Economy.BuildCostEnergy = bp.Economy.BuildCostEnergy * 0.42

                        bp.Economy.BuildCostMass = bp.Economy.BuildCostMass * 0.54
                    elseif cats.TECH3 then
                        bp.Economy.BuildCostEnergy = bp.Economy.BuildCostEnergy * 0.325

                        bp.Economy.BuildCostMass = bp.Economy.BuildCostMass * 0.50
                    end
                end
        end
    end
end
end -- do end