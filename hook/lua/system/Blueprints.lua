do  -- Hook Start
    -- Reason: Add Wreckage to all Blueprints to create more wreckage in the game, goes in hand with the change in Unit.lua to overkillRatio. 
    -- We comment out MassMult Adjustments for now to see how it affects gameplay.
    -- We remove Energy Reclaim from all wrecks to focus Macro more on Energy Production rather then 30 minutes of Macro for Mass Extractor Upgrades.
    local oldModBlueprints = ModBlueprints

    function ModBlueprints(all_bps)

        if oldModBlueprints then
            oldModBlueprints(all_bps)
        end

        for id, bp in pairs(all_bps.Unit) do				
            
            local cats = {}

            if bp.Categories then
                
                for k,cat in pairs(bp.Categories) do
                    cats[cat] = true
                end
            
                if cats.NAVAL then
                
                    if not bp.Wreckage then
                    
                        bp.Wreckage = {
                            Blueprint = '/props/DefaultWreckage/DefaultWreckage_prop.bp',
                            EnergyMult = 0,
                            HealthMult = 0.9,
                            LifeTime = 720,	-- give naval wreckage a lifetime value of 12 minutes
                            MassMult = 0.5,
                            ReclaimTimeMultiplier = 1.2,
                            
                            WreckageLayers = {
                                Air = false,
                                Land = false,
                                Seabed = true,
                                Sub = true,
                                Water = true,
                            };
                        }
                    else
                        local wl = bp.Wreckage.WreckageLayers
                        wl.Seabed = true
                        wl.Sub = true
                        wl.Water = true
                        bp.Wreckage.LifeTime = 720
                    end
                    
                else
                    if bp.Wreckage then
                    
                        if not bp.Wreckage.LifeTime then

                            bp.Wreckage.LifeTime = 900
                            
                        end
                    else
                        --LOG("Adding BP Wreckage")
                        bp.Wreckage = {
                            Blueprint = '/props/DefaultWreckage/DefaultWreckage_prop.bp',
                            EnergyMult = 0,
                            HealthMult = 0.9,
                            LifeTime = 720,	-- give naval wreckage a lifetime value of 12 minutes
                            MassMult = 0.75,
                            ReclaimTimeMultiplier = 1.2,
                            WreckageLayers = {
                                Land = true,
                            };
                        }       
                        
                        --if bp.Wreckage.MassMult and bp.Wreckage.MassMult > 0.2 then
                        
                        --    bp.Wreckage.MassMult = bp.Wreckage.MassMult * 0.5
                            
                        --    bp.Wreckage.ReclaimTimeMultiplier = 1.2
                            
                        --end
                    end
                end
            end
        end
        -- Iterating over the whole table 
        -- Reason: (Azraeel) Imagine in the future that we're probably going to be doing more projectile edits in this so I'm keeping this as a while iteration for that reason. 
        for id, bp in pairs(all_bps.Projectile) do

            if bp.Categories then

                table.remove(all_bps.Projectile['/mods/4dc/projectiles/sniper_piercing/sniper_piercing_proj.bp'].Categories, 2)

            end

        end
    end
end