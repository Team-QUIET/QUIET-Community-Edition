function CreateResources()

	local memstart = gcinfo()
	
    local markers = GetMarkers()
    
	local Armies = ListArmies()
	local Starts = {}
    
    local coordsTbl = {}
    local newmarkers = {}

	for x = 1, 16 do
		if GetMarker('ARMY_'..x) then
			table.insert( Starts, 'ARMY_'..x )
		end
	end
    
    if ScenarioInfo.MetalWorld then
        LOG("*AI DEBUG MetalWorld DETECTED")
        
        -- we'll replace each existing mass point with 9
        -- but they'll be hidden
        coordsTbl = {
            { {-2,-2}, {-2, 2}, { 0, 0}, { 2,-2}, { 2, 2}, {-4, 0}, { 4, 0}, { 0,-4}, { 0, 4} },
        } 
    end
    
    if ScenarioInfo.MassPointRNG then
        LOG("*AI DEBUG MassPointRNG DETECTED")
        
        -- replace coordsTbl with data --
        -- randomly selected
        coordsTbl = {
            { {-2,-2}, {-2, 2}, { 2,-2}, { 2, 2}    },
            { {-2, 0}, { 0,-2}, { 2, 0}, { 0, 2}    },
            { { 0, 0}, {-2, 2}, { 2, 2}     },
            { {-2, 0}, { 0, 0}, { 2, 0}     },
            { { 0,-2}, { 0, 0}, { 0, 2}     },  
            { { 0,-2}, { 0, 2}  },
            { {-2, 0}, { 2, 0}  },
            { { 1, 1}, {-1,-1}  },
            { {-1, 1}, { 1,-1}  },
            { { 0, 0}   },
            { { 2, 0}   },
            { {-2, 0}   },
            { { 0,-2}   },
            { { 0, 2}   },
            { },
            { },
            { },
        } 
    end
    
    -- create the initial mass point list
    ScenarioInfo.StartingMassPointList = {}

	-- store the number of mass points on the map
	ScenarioInfo.NumMassPoints = 0

    ScenarioInfo.MassPointShare = 1
    
    local function CreateSingleResource(tblData)

        -- don't create Mass Points on MetalWorld
        if ScenarioInfo.MetalWorld and tblData.type == "Mass" then
            return
        end
        
        FlattenMapRect(tblData.position[1]-2, tblData.position[3]-2, 4, 4, tblData.position[2])

        CreateResourceDeposit( tblData.type, tblData.position[1], tblData.position[2], tblData.position[3],	tblData.size )

        -- fixme: texture names should come from editor
        local albedo, sx, sz, lod

        if tblData.type == "Mass" then

            albedo = "/env/common/splats/mass_marker.dds"
            sx = 2
            sz = 2
            lod = 100

            CreatePropHPR('/env/common/props/massDeposit01_prop.bp', tblData.position[1], tblData.position[2], tblData.position[3],	Random(0,360), 0, 0	)

        else

            albedo = "/env/common/splats/hydrocarbon_marker.dds"
            sx = 6
            sz = 6
            lod = 200

            CreatePropHPR('/env/common/props/hydrocarbonDeposit01_prop.bp',	tblData.position[1], tblData.position[2], tblData.position[3], Random(0,360), 0, 0 )

        end

        -- syntax reference -- Position, heading, texture name for albedo, sizex, sizez, LOD, duration, army, misc
        CreateSplat( tblData.position, 0, albedo, sx, sz, lod, 0, -1, 0	)

    end

    -- reports the percentage of mass points we'll remove at an Unused Start position
	local doit_value = tonumber(ScenarioInfo.Options.UnusedResources) or 1
    
    local count = 0
    
    LOG("*AI DEBUG Starting to Create/Relocate Resources ")  --..repr(ScenarioInfo.Env.Scenario.MasterChain._MASTERCHAIN_.Markers) )
    
    local AI = false
    
    -- test if there are any AI in the game
    -- for _, brain in ArmyBrains do
    
    --     if brain.BrainType == 'AI' and brain.Nickname != 'civilian' then
        
    --         AI = true
    --         LOG("*AI DEBUG AI on map - All AI and empty start locations will be resource relocated")
    --         break
    --     end
    -- end

    for i, tblData in ScenarioInfo.Env.Scenario.MasterChain._MASTERCHAIN_.Markers do

        count = count + 1

		tblData.hint = false

        if tblData.resource then

			-- assume we'll spawn the resource
			local doit = true
			
			-- loop thru all the Start positions
			for x = 1, table.getn(Starts) do
			
				local armyposition = MarkerToPosition(Starts[x])

                -- local AI_this_spot = false
                
                -- for _, brain in ArmyBrains do
                
                --     if brain.Name == Starts[x] then
                    
                --         if brain.BrainType == 'AI' then
                        
                --             AI_this_spot = true

                --         end
                --     end
                -- end
				
				-- if the resource is within 55 of a start position it should be examined for removal
				if VDist2(armyposition[1],armyposition[3], tblData.position[1], tblData.position[3]) < 55 then
				
					for y = 1, table.getn(Armies) do
					
						-- if the position is being used keep it 
						if Armies[y] == Starts[x] then
							doit = true
							break
						end
						
						-- else turn it off
						doit = false
						
					end
					
					if not tblData.hint then
					
						-- Give me a log when a mass point is too close to a start position and needs to be moved
						-- only 4 points are permitted at a range of 35 - all others will be 55 or greater
						-- those closer than 38.5 will be put at 36 from the start - those greater will be pushed out to 55
						if doit and VDist2(armyposition[1],armyposition[3], tblData.position[1], tblData.position[3]) > 38.5 then
                        
                            local origdistance = VDist2(armyposition[1],armyposition[3], tblData.position[1], tblData.position[3])
                        
                            if ScenarioInfo.Options.RelocateResources == 'on' then
						
                                if tblData.position[1] < armyposition[1] then
							
                                    tblData.position[1] = armyposition[1] - 39
							
                                elseif tblData.position[1] >= armyposition[1] then
						
                                    tblData.position[1] = armyposition[1] + 39
							
                                end
						
                                if tblData.position[3] < armyposition[3] then
						
                                    tblData.position[3] = armyposition[3] - 39
							
                                elseif tblData.position[3] >= armyposition[3] then
						
                                    tblData.position[3] = armyposition[3] + 39
							
                                end
						
                                tblData.position[2] = GetTerrainHeight( tblData.position[1], tblData.position[3] )
						
                                LOG("*AI DEBUG Mass Point "..repr(i).." moved to 55 "..repr(tblData.position).." from "..repr(origdistance) )
							
                                tblData.hint = true
                            
                            end

						elseif doit then
                        
                            local origdistance = VDist2(armyposition[1],armyposition[3], tblData.position[1], tblData.position[3])
                        
                            if ScenarioInfo.Options.RelocateResources == 'on' then
						
                                -- fix the X co-ordinate 
                                if tblData.position[1] < armyposition[1] then
						
                                    tblData.position[1] = armyposition[1] - 25
							
                                elseif tblData.position[1] >= armyposition[1] then
						
                                    tblData.position[1] = armyposition[1] + 25
							
                                end
						
                                -- fix the Y co-ordinate
                                if tblData.position[3] < armyposition[3] then
						
                                    tblData.position[3] = armyposition[3] - 25
							
                                elseif tblData.position[3] >= armyposition[3] then
						
                                    tblData.position[3] = armyposition[3] + 25
							
                                end
						
                                tblData.position[2] = GetTerrainHeight( tblData.position[1], tblData.position[3] )
						
                                LOG("*AI DEBUG Mass Point "..repr(i).." moved to 35 "..repr(tblData.position).." from "..repr(origdistance) )
							
                                tblData.hint = true
                                
                            end
						
                        -- if there are AI then ALWAYS relocate unused start positions
                        --LOG("*AI DEBUG Army Position "..repr(armyposition).." is not being used - always relocate resources")
                        
						elseif not doit and VDist2(armyposition[1],armyposition[3], tblData.position[1], tblData.position[3]) > 38.5 then
                        
                            if ScenarioInfo.Options.RelocateResources == 'on' then
                            
                                -- fix the X co-ordinate 
                                if tblData.position[1] < armyposition[1] then

                                    tblData.position[1] = armyposition[1] - 39
                                
                                elseif tblData.position[1] >= armyposition[1] then

                                    tblData.position[1] = armyposition[1] + 39

                                end

                                -- fix the Y co-ordinate
                                if tblData.position[3] < armyposition[3] then

                                    tblData.position[3] = armyposition[3] - 39

                                elseif tblData.position[3] >= armyposition[3] then

                                    tblData.position[3] = armyposition[3] + 39

                                end
						
                                tblData.position[2] = GetTerrainHeight( tblData.position[1], tblData.position[3] )
						
                                LOG("*AI DEBUG Mass Point "..repr(i).." moved to "..repr(tblData.position).." -- at unused start")

                                tblData.hint = true
 
                            end

                        elseif not doit then
                        
                            if ScenarioInfo.Options.RelocateResources == 'on' then
                            
                                -- fix the X co-ordinate 
                                if tblData.position[1] < armyposition[1] then

                                    tblData.position[1] = armyposition[1] - 25
                                
                                elseif tblData.position[1] >= armyposition[1] then

                                    tblData.position[1] = armyposition[1] + 25

                                end

                                -- fix the Y co-ordinate
                                if tblData.position[3] < armyposition[3] then

                                    tblData.position[3] = armyposition[3] - 25

                                elseif tblData.position[3] >= armyposition[3] then

                                    tblData.position[3] = armyposition[3] + 25

                                end
						
                                tblData.position[2] = GetTerrainHeight( tblData.position[1], tblData.position[3] )
						
                                LOG("*AI DEBUG Mass Point "..repr(i).." moved to "..repr(tblData.position).." -- at unused start")

                                tblData.hint = true
 
                            end
                        
                        end
						
					else
					
						LOG("*AI DEBUG Mass Point "..repr(i).." at "..repr(tblData.position).." was already processed")
					
					end
					
				end
				
			end
			
			-- randomize so that the resources being turned off will appear a certain % of the time
			if not doit then
				
				local chance = Random(1,math.min(doit_value,99))

				-- keep it (always keep it on MetalWorld)
				if chance == doit_value or ScenarioInfo.MetalWorld then
				
					doit = true
					
				-- delete the resource point from the masterchain
				else
				
					LOG("*AI DEBUG Removing resource "..repr(i).." at "..repr(tblData.position))
                    
					ScenarioInfo.Env.Scenario.MasterChain._MASTERCHAIN_.Markers[i] = nil
					
				end
				
			end	
			
			if doit then
            
                -- METAL WORLD --
                -- don't place mass point grahpic on MetalWorld
                -- but replace each existing point with 5
                if ScenarioInfo.MetalWorld and tblData.type == 'Mass' then
                
                    -- generate 5 points to replace the old single point
                    for _, coord in coordsTbl[math.random(1,table.getn(coordsTbl))] do
                        
                        local newttblsData = table.deepcopy(tblData)

                        newttblsData.position[1] = tblData.position[1] + coord[1]
                        newttblsData.position[3] = tblData.position[3] + coord[2]
                        newttblsData.position[2] = GetTerrainHeight(tblData.position[1],tblData.position[3])

                        -- put the new marker into the marker table
                        table.insert(newmarkers, newttblsData)

                    end

                    -- remove the source marker from original list
                    LOG("*AI DEBUG Removing original point "..repr(i).." at "..repr(tblData.position).." for METALWORLD")
                    
                    ScenarioInfo.Env.Scenario.MasterChain._MASTERCHAIN_.Markers[i] = nil

                    continue
                    
                else
                
                    -- MASS POINT RNG --
                    if ScenarioInfo.MassPointRNG and tblData.type == 'Mass' then

                        -- randomly generate between 0 and 4 new points to replace the old one
                        for _, coord in coordsTbl[math.random(1,table.getn(coordsTbl))] do
                        
                            local newttblsData = table.deepcopy(tblData)
                            
                            newttblsData.position[1] = tblData.position[1] + coord[1]
                            newttblsData.position[3] = tblData.position[3] + coord[2]
                            newttblsData.position[2] = GetTerrainHeight(tblData.position[1],tblData.position[3])
                            
                            -- put the new marker into the marker table
                            table.insert(newmarkers, newttblsData)

                        end

                        -- remove the source marker from original list
                        LOG("*AI DEBUG Removing original point "..repr(i).." at "..repr(tblData.position).." for MassPointRNG")
                        
                        ScenarioInfo.Env.Scenario.MasterChain._MASTERCHAIN_.Markers[i] = nil

                    end
			
                end
                
			end
            
        end

    end
    
    LOG("*AI DEBUG Reviewed "..repr(count).." markers in total")

    if newmarkers[1] then
    
        LOG("*AI DEBUG New markers were created")

        for _, data in newmarkers do
            table.insert(ScenarioInfo.Env.Scenario.MasterChain._MASTERCHAIN_.Markers, data)
        end
        
    end
    
    LOG("*AI DEBUG Checking for empty Start Positions and sanitizing markers")

	-- loop thru all the start positions and eliminate those which
	-- no longer have any resources within range 75 of them
    for i, tblData in ScenarioInfo.Env.Scenario.MasterChain._MASTERCHAIN_.Markers do
		
        if tblData.type == "Blank Marker" then
		
			local doit = false

			-- loop thru all the mass markers
			for j, massData in pairs(markers) do

				if massData.resource then
				
					-- if the resource is within 120 of a start position
					-- test it to see if that start position is being used
					if VDist2(massData.position[1],massData.position[3], tblData.position[1], tblData.position[3]) < 120 then
						--LOG("*AI DEBUG Start Position "..repr(i).." at "..repr(tblData.position).." has resources in range - keeping it")
						doit = true
						break
					end
				end
			end
			
			-- if no resources near start position then remove it
			if not doit then
            
				LOG("*AI DEBUG Removing Start Marker "..repr(i).." at "..repr(tblData.position))
                
				ScenarioInfo.Env.Scenario.MasterChain._MASTERCHAIN_.Markers[i] = nil
			end	

        end

		if tblData.editorIcon then
			tblData.editorIcon = nil
		end
	
		if tblData.orientation then
			tblData.orientation = nil
		end
		
		if tblData.color then
			tblData.color = nil
		end
		
		if tblData.size and not tblData.resource then
			tblData.size = nil
		end
		
		if tblData.amount then
			tblData.amount = nil
		end
		
		if tblData.prop then
			tblData.prop = nil
		end
		
		if tblData.position then
		
			local a = tblData.position[1]
			local b = tblData.position[2]
			local c = tblData.position[3]
			tblData.position = { a, b, c }
			
		end
	
    end

    ScenarioInfo.Options.RelocateResources = nil
    
    markers = GetMarkers()
    
    LOG("*AI DEBUG Placing Resources on the map")
    
    -- put the resources onto the map
    for i, tblData in markers do
    
        if tblData.resource then

            CreateSingleResource(tblData)

        end
        
    end

    -- clear the marker list (forces a rebuild)
    -- at this point there shouldn't be ANY type of markers at this level of the data anyhow
    ScenarioInfo['Mass'] = nil

	-- store the number of mass points on the map
	ScenarioInfo.NumMassPoints = table.getn( import('/lua/ai/aiutilities.lua').AIGetMarkerLocations('Mass') )

	LOG("*AI DEBUG Storing Mass Points = "..ScenarioInfo.NumMassPoints)
    
    -- create the initial mass point list - this call will force the mass point marker list to be recreated
    ScenarioInfo.StartingMassPointList = table.copy(import('/lua/ai/aiutilities.lua').AIGetMarkerLocations('Mass'))

    LOG("*AI DEBUG Number of Players is "..ScenarioInfo.Options.PlayerCount)
    
    -- mass point share is how many mass points should be considered necessary before offensive actions can commence - max is 12 + number of players
    -- this is useful in driving offensive action on mass heavy maps where the mex count might be stupidly large or low player counts on large maps
    ScenarioInfo.MassPointShare = math.min( 12 + ScenarioInfo.Options.PlayerCount, math.floor(ScenarioInfo.NumMassPoints/ScenarioInfo.Options.PlayerCount) - 1)
    
    LOG("*AI DEBUG Player Mass Point Share is "..ScenarioInfo.MassPointShare)
  	
	LOG("*AI DEBUG Created Resources and used "..( (gcinfo() - memstart)*1024 ).." bytes")
	
end