do  -- Hook Start
    -- Reason: Add Wreckage to all Blueprints to create more wreckage in the game, goes in hand with the change in Unit.lua to overkillRatio. 
    -- We comment out MassMult Adjustments for now to see how it affects gameplay.
    -- We remove Energy Reclaim from all wrecks to focus Macro more on Energy Production rather then 30 minutes of Macro for Mass Extractor Upgrades.
    -- We remove the entire section that manipulates blueprints
    function ModBlueprints(all_blueprints)

        -- TODO: move this load to someplace more central so Tanksy and others can use it
        -- Load Phoenix's Helper Library
        -- This includes primarily functions that calculate DPS and Threat, but also includes
        -- a set of functions that return clean unit information.
        -- This method of inclusion loads a single table of info, constants, and functions
        -- called PhxLib
        doscript '/lua/PhxLib.lua'
        
        --LOG("PhxLib is "..repr(PhxLib))

        -- Used for loading loose files in the Development build, as part of the GitHub Repo.
        for bptype, array in all_blueprints do
            if (bptype != "Unit" and bptype != "Mesh") then
                for id, bp in array do
                    if string.find(bp.BlueprintId, "/") and string.find(bp.BlueprintId, "/gamedata/") then
                        local slash = string.find(bp.BlueprintId, "/", 2)
                        slash = string.find(bp.BlueprintId, "/", slash + 1)
                        --LOG(bp.BlueprintId)
                        bp.BlueprintId = string.sub(bp.BlueprintId, slash)
                        --LOG(bp.BlueprintId)
                    end
                end
            end
        end

        --LOG("*AI DEBUG ScenarioInfo data is "..repr( _G ) )

        local ROFadjust = 0.9
        
        local units_threatchange = 0

        for id, bp in all_blueprints.Unit do

            local tpc = bp.Transport and bp.Transport.TransportClass or 1
            local sizes = {'Small', 'Medium', 'Large', [5]='Drone'}

            if bp.General.CommandCaps.RULEUCC_CallTransport
                and sizes[tpc]
                and bp.Categories
                and not table.find(bp.Categories, 'TECH'..tpc)
            then
                if not bp.Display           then bp.Display = {}           end
                if not bp.Display.Abilities then bp.Display.Abilities = {} end
                table.insert(bp.Display.Abilities, 'Transport hook size: '..sizes[tpc])
            end
            
            if bp.Weapon then

                -- Begin Threat Update: overwrite threat with updated values

                -- details available in:
                -- https://docs.google.com/document/d/1oMpHiHDKjTID0szO1mvNSH_dAJfg0-DuZkZAYVdr-Ms/edit

                -- TODO: Update this to handle non-weapon bearing units
                -- TODO: Currently only supports surface threat, update to handle air,sub,surf threats
                local unitDPS = PhxLib.calcUnitDPS(id,bp)
                
                if bp.Defense and bp.Defense.SurfaceThreatLevel and unitDPS.Threat.srfTotal	then

                    --LOG("Threat Overriden: "..id..", "..PhxLib.cleanUnitName(bp)..", ".."PrevThreat = "..bp.Defense.SurfaceThreatLevel..",".."NewThreat = "..unitDPS.Threat.srfTotal )

                    if bp.Defense.SurfaceThreatLevel != unitDPS.Threat.srfTotal then

                        bp.Defense.SurfaceThreatLevel = unitDPS.Threat.srfTotal
                        --bp.Defense.AirThreatLevel = unitDPS.Threat.airTotal
                        --bp.Defense.SubThreatLevel = unitDPS.Threat.subTotal
                        
                        units_threatchange = units_threatchange + 1
                    end

                end
                -- End Threat Update

                for ik, wep in bp.Weapon do
                    
                    if wep.RateOfFire then
                    
                        if wep.RateOfFire < 5 then
                            wep.RateOfFire = wep.RateOfFire * ROFadjust
                        else
                            --LOG("*AI DEBUG "..id.." "..repr(bp.Description).." "..repr(wep.Label).." has an RoF of "..wep.RateOfFire)
                        end
                        
                        if wep.MuzzleSalvoDelay == nil then
                            wep.MuzzleSalvoDelay = 0
                        end
                    end

                    if not (wep.BeamLifetime or wep.Label == 'DeathWeapon' or wep.Label == 'DeathImpact' or wep.WeaponCategory == 'Air Crash') and not wep.ProjectileLifetime and not wep.ProjectileLifetimeUsesMultiplier then
                        --LOG("*AI DEBUG "..id.." "..repr(bp.Description).." "..repr(wep.Label).." has no projectile lifetime for "..repr(wep.DisplayName).." Label "..repr(wep.Label))
                    end
                    
                    if not wep.ProjectileLifetime or wep.ProjectileLifetime == 0 then
                    
                        if wep.MuzzleVelocity and wep.MuzzleVelocity > 0 then
                        
                            wep.ProjectileLifetime = (wep.MaxRadius / wep.MuzzleVelocity) * 1.15
                        end
                    end

                    if wep.TargetCheckInterval then
                    
                        if wep.TargetCheckInterval < .1 then 
                            wep.TargetCheckInterval = .1
                        end
                        
                        if wep.TargetCheckInterval > 6 then
                            wep.TargetCheckInterval = 6
                        end
                    end

                    if wep.DisplayName then
                        wep.DisplayName = nil
                    end

                    if wep.RangeCategory == 'UWRC_AntiAir' then
                    
                        if not wep.AntiSat == true then
                            wep.TargetRestrictDisallow = wep.TargetRestrictDisallow .. ', SATELLITE'
                        end
                    end
                end
            end
        end 
        
        LOG("*AI DEBUG "..units_threatchange.." units had threat revised")

        local capreturnradius = 65
        
        local econScale = 0
        local speedScale = 0
        local viewScale = 0

        for id, bp in all_blueprints.Unit do

            if bp.Economy.MaxBuildDistance and bp.Economy.MaxBuildDistance < 3 then

                bp.Economy.MaxBuildDistance = 3
                
            end

            -- anything that builds has it's StagingPlatformScanRadius set to it's build distance
            -- for use as the build range indication
            if bp.Economy.BuildRate >= 2 and bp.Economy.MaxBuildDistance then
            
                if not bp.AI then
                    bp.AI = {}
                end
                
                if not bp.AI.StagingPlatformScanRadius then

                    bp.AI.StagingPlatformScanRadius = bp.Economy.MaxBuildDistance + 1

                end
                
                if bp.AI.InitialAutoMode then
                
                    for _,cat in bp.Categories do
                    
                        if cat == "COMMAND" then

                            bp.AI.InitialAutoMode = false
                            
                            LOG("*AI DEBUG Automode "..repr(bp.Description).." set to false")
                            break
                        end
                    end
                end
            end
        end

        if bp.Categories then

            if cat == 'LAND' then
    
                for j, catj in bp.Categories do
            
                    if catj == 'MOBILE' then
            
                        if not bp.AI then

                            --LOG("*AI DEBUG No AI section for "..repr(bp.Description) )

                        else

                            if bp.Weapon[1] and not bp.AI.GuardScanRadius then

                                --LOG("*AI DEBUG No AI GuardScanRadius for "..repr(bp.Description).." weapon 1 has maxRadius of "..repr(bp.Weapon[1].MaxRadius) )

                            elseif bp.Weapon[1] and bp.AI.GuardScanRadius < bp.Weapon[1].MaxRadius then

                            --  LOG("*AI DEBUG GuardScanRadius for "..repr(bp.Description).." is "..bp.AI.GuardScanRadius.." less than weapon 1 "..repr(bp.Weapon[1].MaxRadius))

                            end

                        end

                        if bp.SizeY and not bp.Physics.LayerChangeOffsetHeight then
                            bp.Physics.LayerChangeOffsetHeight = bp.SizeY/2 * -1
                        end
                        
                        if bp.Physics.RotateOnSpot then
                            bp.Physics.RotateOnSpot = false
                        end
                        
                        -- UniformScale universally to make t2 & t3 more mobile
                        for _, cat_mobile in bp.Categories do
                            if cat_mobile == 'TECH2' then
                                table.remove(all_blueprints.Projectile['/mods/4dc/projectiles/sniper_piercing/sniper_piercing_proj.bp'].Categories, 2) -- Removes SHIELDPIERCING Category from T2 Aeon Sniper
                                -- make them appear a little smaller
                                if bp.Display.UniformScale then
                                    bp.Display.UniformScale = bp.Display.UniformScale * .95
                                end
                            
                            elseif cat_mobile == 'TECH3' then
                                -- make them appear a little smaller
                                if bp.Display.UniformScale then
                                    bp.Display.UniformScale = bp.Display.UniformScale * .95
                                end
                            end
                        end
                    end
                end  
            end
        end
                                
        
        if bp.Categories then
            
            for i, cat in bp.Categories do
        
                if cat == 'NAVAL' then
        
                    speedScale = -0.10  --- move slower
            
                    for j, catj in bp.Categories do
                
                        if catj == 'MOBILE' then
                        
                            if not bp.AI then

                                --LOG("*AI DEBUG No AI section for "..repr(bp.Description) )

                            else

                                if bp.Weapon[1] and not bp.AI.GuardScanRadius then

                                    --LOG("*AI DEBUG No AI GuardScanRadius for "..repr(bp.Description).." weapon 1 has maxRadius of "..repr(bp.Weapon[1].MaxRadius) )

                                elseif bp.Weapon[1] and bp.AI.GuardScanRadius < bp.Weapon[1].MaxRadius then

                                    --LOG("*AI DEBUG GuardScanRadius for "..repr(bp.Description).." is "..bp.AI.GuardScanRadius.." less than weapon 1 "..repr(bp.Weapon[1].MaxRadius))

                                end

                            end
        
                            if bp.Economy.BuildTime then
                                -- simple 10% energy cost reduction for all naval units
                                bp.Economy.BuildCostEnergy = bp.Economy.BuildCostEnergy * 0.9
                            end
                        
                            if bp.Physics.Maxspeed then
                            
                                bp.Physics.MaxSpeed = bp.Physics.MaxSpeed + (bp.Physics.MaxSpeed * speedScale)
                                
                            end	   
                        end			
                    end
                end
            end
        end
                
        if cat == 'AIR' then
                
            econScale = 0.075	-- cost more

            for j, catj in bp.Categories do
        
                if catj == 'MOBILE' then
        
                    if not bp.AI then

                        --LOG("*AI DEBUG No AI section for "..repr(bp.Description) )

                    else

                        if bp.Weapon[1] and not bp.AI.GuardScanRadius then

                            --LOG("*AI DEBUG No AI GuardScanRadius for "..repr(bp.Description).." weapon 1 has maxRadius of "..repr(bp.Weapon[1].MaxRadius) )

                        elseif bp.Weapon[1] and bp.AI.GuardScanRadius < bp.Weapon[1].MaxRadius then

                        --  LOG("*AI DEBUG GuardScanRadius for "..repr(bp.Description).." is "..bp.AI.GuardScanRadius.." less than weapon 1 "..repr(bp.Weapon[1].MaxRadius))

                        end

                    end
                    
                    if bp.Air.KMove and bp.Air.KMoveDamping > 1 then
                        --LOG("AI DEBUG KMoveDamping for "..repr(bp.Description).." reduced from "..bp.Air.KMoveDamping.." to 1 - KMove is "..bp.Air.KMove)
                        bp.Air.KMoveDamping = 1.0
                    end
                    
                    if bp.Air.KTurn then
                        if bp.Air.KTurnDamping and bp.Air.KTurnDamping > (bp.Air.KTurn * 1.25) then
                            --LOG("AI DEBUG KTurnDamping for "..repr(bp.Description).." reduced from "..repr(bp.Air.KTurnDamping).." to "..bp.Air.KTurn * 1.25)
                            bp.Air.KTurnDamping = bp.Air.KTurn * 1.25
                        end
                    end
                    
                    -- this is the one that controls air unit speed
                    -- enforce a minimum airspeed
                    if bp.Air.MaxAirspeed then
                        bp.Air.MinAirspeed = bp.Air.MaxAirspeed * 0.5
                    end
            
                    if bp.Economy.BuildTime then
                        bp.Economy.BuildTime = bp.Economy.BuildTime + (bp.Economy.BuildTime * econScale)
                        bp.Economy.BuildCostEnergy = bp.Economy.BuildCostEnergy + (bp.Economy.BuildCostEnergy * econScale)
                        bp.Economy.BuildCostMass = bp.Economy.BuildCostMass + (bp.Economy.BuildCostMass * econScale)
                    end

                    -- air units speed is not controlled by this
                    if bp.Physics.Maxspeed then
                        bp.Physics.MinSpeed = bp.Physics.MaxSpeed * 0.5
                    end
                
                    -- if the unit uses a SizeSphere for collisions, make sure it's big enough as related to it's max speed
                    -- if the value is set too low, the unit becomes nearly unhittable except by tracking SAMs
                    -- this steep dropoff starts to occur around .9 but is tolerable at that setting with a decent amount of
                    -- hits but a few misses at the top end (of particular note are the AA lasers)
                    if bp.SizeSphere and bp.Air.MaxAirspeed then
                        bp.SizeSphere = math.max( 0.9, bp.Air.MaxAirspeed * 0.095 )
                    end
                    
                    if bp.Weapon then
                    
                        for w, weap in bp.Weapon do
                    
                            --if weap.AutoInitiateAttackCommand and weap.RangeCategory == 'UWRC_AntiAir'then
                                --LOG("*AI DEBUG Air Unit "..id.." "..bp.Description.." Weapon "..w.." - AA weapon has AutoInitiateAttack ")
                                --bp.Weapon[w].AutoInitiateAttackCommand = false
                            --end
                        end
                    end

                end
            end
        end
                    
        -- all structures
        if cat == 'STRUCTURE' then
                
            viewScale = 0.15    -- see further				
        
            if bp.Intel.VisionRadius then
            
                bp.Intel.VisionRadius = math.floor(bp.Intel.VisionRadius + (bp.Intel.VisionRadius * viewScale))
                
            end

            if bp.Intel.WaterVisionRadius then
            
                bp.Intel.WaterVisionRadius = math.floor(bp.Intel.WaterVisionRadius + (bp.Intel.WaterVisionRadius * viewScale))
                
            else
            
                if bp.Intel then
                    bp.Intel.WaterVisionRadius = 0
                end
                
            end
        
            local buildtimemod = 1	-- take longer to build (but costs remain same)
        
            if bp.Economy.BuildTime then
                bp.Economy.BuildTime = bp.Economy.BuildTime * buildtimemod
            end
            
            -- the purpose of this alteration is to address the parity of T2 and T3 static defenses with respect to mobile units
            -- I felt, and the numbers clearly show, that a tremendous range difference crept into the game as many 3rd party
            -- point defenses were added - blame the UEF Ravager for setting a bad precedent with a range of 65 - others that 
            -- followed often went beyond that, which made even mobile artillery effectively pointless, and greatly encouraged
            -- 'turtling' instead of mobile warfare
        
            -- This mod addresses that by bringing any DIRECTFIRE structures back into some kind of normalacy and giving the 
            -- mobile units some chance of getting within firing range before being completely shellacked.
            for _, cat_structure in bp.Categories do
            
                if cat_structure == 'DIRECTFIRE' then
                    
                    for _, cat_tech in bp.Categories do

                        if cat_tech == 'EXPERIMENTAL' then
                        
                            --LOG("*AI DEBUG Modifying Weapon Range on EXPERIMENTAL "..bp.Description)
                            
                            for ik, wep in bp.Weapon do
                                if wep.MaxRadius and wep.MaxRadius > 60 then
                                    --LOG("*AI DEBUG MaxRadius goes from "..wep.MaxRadius.." to "..math.floor(wep.MaxRadius * 0.91))
                                    wep.MaxRadius = math.floor(wep.MaxRadius * 0.91)
                                end
                            end										
                        end									
                    end
                end
            end					
        end

        --LOG("*AI DEBUG Adding NAVAL Wreckage information and setting wreckage lifetime")
        
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

        --LOG("*AI DEBUG Adding Audio Cues for COMMANDERS - NUKES - FERRY ROUTES - EXTRACTORS")

        local factions = {'UEF', 'Aeon', 'Cybran', 'Aeon'}

        for i, bp in pairs(all_blueprints.Unit) do

            if usermodUnitIcons[i] then
                bp.Display.IconPath = usermodUnitIcons[i]
            end

            -- Wonky Resources
            if bp.Physics and bp.Physics.BuildRestriction then
                bp.Physics.MaxGroundVariation = 512
                bp.Physics.FlattenSkirt = false
                bp.Physics.SlopeToTerrain = true
            end
            
            if bp.Categories then
            
                local categories = {}
                
                for j,category in pairs(bp.Categories) do
                    categories[category] = true
                end

                for j,faction in pairs(factions) do
                
                    if categories['COMMAND'] == true then
                    
                        --DETECTED
                        local Detected = Sound { Bank = 'XGG', Cue = 'XGG_Computer_CV01_04724',}

                        bp.Audio['EnemyUnitDetected'..faction] = Detected
                    end
                    
                    if categories['STRATEGIC'] == true and categories['NUKE'] == true and categories['SILO'] == true then
                        
                        --DETECTED
                        local Detected = Sound { Bank = 'XGG', Cue = 'XGG_Rhiza_MP1_04588',}

                        bp.Audio['EnemyUnitDetected'..faction] = Detected
                    end

                    -- if categories['TRANSPORTATION'] == true then
                    
                    --     local FerrySet = Sound { Bank = 'XGG', Cue = 'XGG_HQ_GD1_04193',}

                    --     bp.Audio['FerryPointSetBy'..faction] = FerrySet
                    -- end

                    --UNDER ATTACK
                    if categories['MASSEXTRACTION'] then
                    
                        local MexUnderAttack = Sound { Bank = 'XGG', Cue = 'XGG_Computer_CV01_04728',}
                        
                        bp.Audio['UnitUnderAttack'..faction] = MexUnderAttack
                    end
                end
            end
        end
        usermodUnitIcons = nil
    end
end