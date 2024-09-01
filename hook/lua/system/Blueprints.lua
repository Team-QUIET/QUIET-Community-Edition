-- Hook Start
-- Reason: Add Wreckage to all Blueprints to create more wreckage in the game, goes in hand with the change in Unit.lua to overkillRatio. 
-- We comment out MassMult Adjustments for now to see how it affects gameplay.
-- We remove Energy Reclaim from all wrecks to focus Macro more on Energy Production rather then 30 minutes of Macro for Mass Extractor Upgrades.
function ModBlueprints(all_blueprints)

    for id, bp in pairs(all_blueprints.Unit) do				
        
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
                    LOG("Adding BP Wreckage")
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
end