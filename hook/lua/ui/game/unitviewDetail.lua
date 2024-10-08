function WrapAndPlaceText(air, physics, intel, weapons, abilities, capCost, text, control)
	
	-- Create the table of text to be displayed once populated.
	local textLines = {}
	
	-- -1 so that no line color can change (As there won't be an index of -1),
	-- but only if there's no Air or Physics on the blueprint.
	local physics_line = -1
	local intel_line = -1
	local cap_line = -1
	
	if text ~= nil then
		textLines = import('/lua/maui/text.lua').WrapText(text, control.Value[1].Width(), function(text) 
			return control.Value[1]:GetStringAdvance(text) 
		end)
	end

	-- Keep a count of the Ability lines.
	local abilityLines = 0

	-- Check for abilities on the BP.
	if abilities ~= nil then

		local i = table.getn(abilities)

		if textLines[1] then
			table.insert(textLines, 1, "")
		end
		
		-- Insert each ability into the textLines table.
		while abilities[i] do
			table.insert(textLines, 1, LOC(abilities[i]))
			i = i - 1
		end
		
		--Update the count of Ability lines.
		abilityLines = table.getsize(abilities)
	end

	-- Inserts a blank line for readability.
	table.insert(textLines, "")

	-- Start point of the weapon lines.
	local weapon_start = table.getn(textLines)
	
	if weapons and not table.empty(weapons) then
		-- Import PhoenixMT's DPS Calculator script.
		doscript '/lua/PhxLib.lua'

		-- Used for comparing last weapon checked.
		local lastWeaponDmg = 0
		local lastWeaponDPS = 0
		local lastWeaponPPOF = 0
		local lastWeaponDoT = 0
		local lastWeaponDmgRad = 0
		local lastWeaponMinRad = 0
		local lastWeaponMaxRad = 0
		local lastWeaponROF = 0
		local lastWeaponFF = false
		local lastWeaponCF = false
		local lastWeaponTarget = ''
		local lastWeaponNukeInDmg = 0
		local lastWeaponNukeInRad = 0
		local lastWeaponNukeOutDmg = 0
		local lastWeaponNukeOutRad = 0
		local weaponText = ""
		
		-- BuffType.
		local bType = ""
		-- Weapon Category is checked to color lines, as well as checked for countermeasure weapons and differentiating the info displayed.
		local wepCategory = ""
		
		local dupWeaponCount = 1

		for i, weapon in weapons do
			-- Check for DummyWeapon Label (Used by Paragons for Range Rings).
			if not LOUDFIND(weapon.Label, 'Dummy') and not LOUDFIND(weapon.Label, 'Tractor') and not LOUDFIND(weapon.Label, 'Painter') then
				-- Check for RangeCategories.
				if weapon.RangeCategory ~= nil then
					if weapon.RangeCategory == 'UWRC_DirectFire' then
						wepCategory = "Direct"
					end
					if weapon.RangeCategory == 'UWRC_IndirectFire' then
						wepCategory = "Indirect"
					end
					if weapon.RangeCategory == 'UWRC_AntiAir' then
						wepCategory = "Anti Air"
					end
					if weapon.RangeCategory == 'UWRC_AntiNavy' then
						wepCategory = "Anti Navy"
					end
					if weapon.RangeCategory == 'UWRC_Countermeasure' then
						wepCategory = " Defense"
					end
				end
				
				-- Check for Death weapon labels
				if LOUDFIND(weapon.Label, 'Death') then
					wepCategory = "Volatile"
				end
				if weapon.Label == 'DeathImpact' then
					wepCategory = "Crash"
				end
				if weapon.Label == 'Suicide' then
					wepCategory = "Suicide"
				end
				
				-- These weapons have no RangeCategory, but do have Labels.
				if weapon.Label == 'Bomb' then
					wepCategory = "Indirect"
				end
				if weapon.Label == 'Torpedo' then
					wepCategory = "Anti Navy"
				end
				if weapon.Label == 'QuantumBeamGeneratorWeapon' then
					wepCategory = "Direct"
				end
				if weapon.Label == 'ChinGun' then
					wepCategory = "Direct"
				end
				if LOUDFIND(weapon.Label, 'Melee') then
					wepCategory = "Melee"
				end
				
				-- Check if we're a Nuke weapon by checking our InnerRingDamage, which all Nukes must have.
				if weapon.NukeInnerRingDamage > 0 then
					wepCategory = "Nuke"
				end
				
				-- Now categories are established, we check which category we ended up using.
				
				-- Check if it's a death weapon.
				if wepCategory == "Crash" or wepCategory == "Volatile" or wepCategory == "Suicide" then
					
					-- Start the weaponText string with the weapon category.
					weaponText = wepCategory
					
					-- Check DamageFriendly and concat.
					if weapon.CollideFriendly ~= false or weapon.DamageRadius > 0 then
						weaponText = (weaponText .. " (FF)")
					end
					
					-- Concat damage.
					weaponText = (weaponText .. " { Dmg: " .. LOUD_ThouCheck(weapon.Damage))
					
					-- Check DamageRadius and concat.
					if weapon.DamageRadius > 0 then
						weaponText = (weaponText .. ", AoE: " .. LOUD_KiloCheck(weapon.DamageRadius * 20))
					end

					-- Finish text line.
					weaponText = (weaponText .. " }")

					-- Insert death weapon text line.
					table.insert(textLines, weaponText)
					
				-- Check if it's a nuke weapon.
				elseif wepCategory == "Nuke" then
				
					-- Check if this nuke is a Death nuke.
					if LOUDFIND(weapon.Label, "Death") then
						wepCategory = "Volatile"
						weaponText = wepCategory
					else
						weaponText = wepCategory
					end
					
					-- Check DamageFriendly and Buffs
					if weapon.CollideFriendly ~= false or (weapon.NukeInnerRingRadius > 0 and weapon.DamageFriendly ~= false) or weapon.Buffs ~= nil then
						weaponText = (weaponText .. " (")
						if weapon.Buffs then
							for i, buff in weapon.Buffs do
								bType = buff.BuffType
								if i == 1 then
									weaponText = (weaponText .. bType)
								else
									weaponText = (weaponText .. ", " .. bType)
								end
							end
						end
						if weapon.CollideFriendly ~= false or (weapon.NukeInnerRingRadius > 0 and weapon.DamageFriendly ~= false) then
							if weapon.Buffs then
								weaponText = (weaponText .. ", FF")
							else
								weaponText = (weaponText .. "FF")
							end
						end
						weaponText = (weaponText .. ")")
					end
					
					weaponText = (weaponText .. " { Inner Dmg: " .. LOUD_ThouCheck(weapon.NukeInnerRingDamage) .. ", AoE: " .. LOUD_KiloCheck(weapon.NukeInnerRingRadius * 20) .. " | Outer Dmg: " .. LOUD_ThouCheck(weapon.NukeOuterRingDamage) .. ", AoE: " .. LOUD_KiloCheck(weapon.NukeOuterRingRadius * 20))
					
					-- Finish text lines.
					weaponText = (weaponText .. " }")

					if weapon.NukeInnerRingDamage == lastWeaponNukeInDmg and weapon.NukeInnerRingRadius == lastWeaponNukeInRad  and weapon.NukeOuterRingDamage == lastWeaponNukeOutDmg and weapon.NukeOuterRingRadius == lastWeaponNukeOutRad and weapon.DamageFriendly == lastWeaponFF then
						dupWeaponCount = dupWeaponCount + 1
						-- Remove the old lines, to insert the new ones with the updated weapon count.
						table.remove(textLines, table.getn(textLines))
						table.insert(textLines, LOUDFORMAT("%s (x%d)", weaponText, dupWeaponCount))
					else
						dupWeaponCount = 1
						-- Insert the textLine.
						table.insert(textLines, weaponText)
					end
				else
					-- Start the weaponText string if we do damage.
					if weapon.Damage > 0.01 then
						
						-- Start the weaponText string with the weapon category.
						weaponText = wepCategory
						
						-- Check DamageFriendly and Buffs
						if wepCategory ~= " Defense" and wepCategory ~= "Melee" then
							if weapon.CollideFriendly ~= false or (weapon.DamageRadius > 0 and weapon.DamageFriendly ~= false) or weapon.Buffs ~= nil then
								weaponText = (weaponText .. " (")
								if weapon.Buffs then
									for i, buff in weapon.Buffs do
										bType = buff.BuffType
										if i == 1 then
											weaponText = (weaponText .. bType)
										else
											weaponText = (weaponText .. ", " .. bType)
										end
									end
								end
								if weapon.CollideFriendly ~= false or (weapon.DamageRadius > 0 and weapon.DamageFriendly ~= false) then
									if weapon.Buffs then
										weaponText = (weaponText .. ", FF")
									else
										weaponText = (weaponText .. "FF")
									end
								end
								weaponText = (weaponText .. ")")
							end
						
							-- Concat Damage. We don't check it here because we already checked it exists to get this far.
							weaponText = (weaponText .. " { Dmg: " .. LOUD_ThouCheck(weapon.Damage))
							
							-- Check PPF and concat.
							if weapon.ProjectilesPerOnFire > 1 then
								weaponText = (weaponText .. " (" .. tostring(weapon.ProjectilesPerOnFire) .. " Shots)")
							end
							
							-- Check DoTPulses and concat.
							if weapon.DoTPulses > 0 then
								weaponText = (weaponText .. " (" .. tostring(weapon.DoTPulses) .. " Hits)")
							end
							
							-- Concat DPS, calculated from PhxLib.
							weaponText = (weaponText .. ", DPS: " .. LOUD_ThouCheck(LOUDFLOOR(PhxLib.PhxWeapDPS(weapon).DPS + 0.5)))
						
							-- Check DamageRadius and concat.
							if weapon.DamageRadius > 0 then
								weaponText = (weaponText .. ", AoE: " .. LOUD_KiloCheck(weapon.DamageRadius * 20))
							end
						else
							if wepCategory == " Defense" then
								-- Display Countermeasure Targets as the weapon type.
								if weapon.TargetRestrictOnlyAllow then
									weaponText = (TitleCase(weapon.TargetRestrictOnlyAllow) .. wepCategory)
								end
								
								-- If a weapon is a Countermeasure, we don't care about its damage or DPS,
								-- as it's all very small numbers purely for shooting projectiles.
								weaponText = (weaponText .. " {"):gsub(",", " ")

								-- Show RoF for Countermeasure weapons.
								if PhxLib.PhxWeapDPS(weapon).RateOfFire > 0 then
									weaponText = (weaponText .. " RoF: " .. LOUDFORMAT("%.2f", PhxLib.PhxWeapDPS(weapon).RateOfFire) .. "/s"):gsub("%.?0+$", "")
								end
							end
							-- Special case for Melee weapons, only showing Damage.
							if wepCategory == "Melee" then
								weaponText = (weaponText .. " { Dmg: " .. LOUD_ThouCheck(weapon.Damage))
							end
						end
						
						-- Check RateOfFire and concat.
						-- (NOTE: Commented out for now. DPS can infer ROF well enough and we have limited real-estate in the rollover box until someone figures out how to extend its width limit.)
						if PhxLib.PhxWeapDPS(weapon).RateOfFire > 0 then
						--	weaponText = (weaponText .. ", RoF: " .. LOUDFORMAT("%.2f", weapon.RateOfFire) .. "/s"):gsub("%.?0+$", "")
						end
						
						-- Check Min/Max Radius and concat.
						if weapon.MaxRadius > 0 then
							if weapon.MinRadius > 0 then
								weaponText = (weaponText .. ", Rng: " .. LOUD_KiloCheck(weapon.MinRadius * 20) .. "-" .. LOUD_KiloCheck(weapon.MaxRadius * 20))
							else
								weaponText = (weaponText .. ", Rng: " .. LOUD_KiloCheck(weapon.MaxRadius * 20))
							end
						end
						
						-- Finish text line.
						weaponText = (weaponText .. " }")

						-- Check duplicate weapons. We compare lots of values here, 
						-- any slight difference should be considered a different weapon. 
						if weapon.Damage == lastWeaponDmg and LOUDFLOOR(PhxLib.PhxWeapDPS(weapon).DPS + 0.5) == lastWeaponDPS and weapon.ProjectilesPerOnFire == lastWeaponPPOF and weapon.DoTPulses == lastWeaponDoT and weapon.DamageRadius == lastWeaponDmgRad and weapon.MinRadius == lastWeaponMinRad and weapon.MaxRadius == lastWeaponMaxRad and weapon.DamageFriendly == lastWeaponFF and PhxLib.PhxWeapDPS(weapon).RateOfFire == lastWeaponROF and weapon.CollideFriendly == lastWeaponCF and weapon.TargetRestrictOnlyAllow == lastWeaponTarget then
							dupWeaponCount = dupWeaponCount + 1
							-- Remove the old line, to insert the new one with the updated weapon count.
							table.remove(textLines, table.getn(textLines))
							table.insert(textLines, LOUDFORMAT("%s (x%d)", weaponText, dupWeaponCount))
						else
							dupWeaponCount = 1
							-- Insert the textLine.
							table.insert(textLines, weaponText)
						end
					end
				end
				
				-- Set lastWeapon stuff.
				lastWeaponDmg = weapon.Damage
				lastWeaponDPS = LOUDFLOOR(PhxLib.PhxWeapDPS(weapon).DPS + 0.5)
				lastWeaponPPOF = weapon.ProjectilesPerOnFire
				lastWeaponDoT = weapon.DoTPulses
				lastWeaponDmgRad = weapon.DamageRadius
				lastWeaponROF = PhxLib.PhxWeapDPS(weapon).RateOfFire
				lastWeaponMinRad = weapon.MinRadius
				lastWeaponMaxRad = weapon.MaxRadius
				lastWeaponFF = weapon.DamageFriendly
				lastWeaponCF = weapon.CollideFriendly
				lastWeaponTarget = weapon.TargetRestrictOnlyAllow
				lastWeaponNukeInDmg = weapon.NukeInnerRingDamage
				lastWeaponNukeInRad = weapon.NukeInnerRingRadius
				lastWeaponNukeOutDmg = weapon.NukeOuterRingDamage
				lastWeaponNukeOutRad = weapon.NukeOuterRingRadius
			end
		end
	end

	local weapon_end = table.getn(textLines)
	local physicsText = ""

	--Physics info
	if physics and physics.MotionType ~= 'RULEUMT_None' then
		if physics.MotionType == 'RULEUMT_Air' then
			if air.MaxAirspeed ~= 0 then
				physicsText = ("Top Speed: " .. LOUD_SpeedCheck(air.MaxAirspeed))
				
				if air.TurnSpeed ~= 0 then
					physicsText = (physicsText .. ", Turn Speed: " .. LOUD_SpeedCheck(air.TurnSpeed))
				end
				if physics.FuelUseTime ~= 0 then
					physicsText = (physicsText .. ", Fuel Time: " .. LOUD_FuelCheck(physics.FuelUseTime))
				end
			end

            -- Display the TransportSpeedReduction stat in the UI.
            if physics.TransportSpeedReduction then
                table.insert(textLines, LOCF("<LOC uvd_0017>Transport Speed Reduction: %.3g",
                physics.TransportSpeedReduction, physicsText))
            end
			
			-- Insert the physics text into the table.
			table.insert(textLines, physicsText)
			-- Get the index of the physics text line from the textLines table.
			physics_line = table.getn(textLines)
		else
			if physics.MaxSpeed ~= 0 then
				physicsText = ("Top Speed: " .. LOUD_SpeedCheck(physics.MaxSpeed))
				
				if physics.MaxAcceleration ~= 0 then
					physicsText = (physicsText .. ", Acceleration: " .. LOUD_SpeedCheck(physics.MaxAcceleration))
				end
			end
			
			-- Insert the physics text into the table.
			table.insert(textLines, physicsText)
			-- Get the index of the physics text line from the textLines table.
			physics_line = table.getn(textLines)
		end
	end

	local intelText = ""
	
	-- Intel info
	if intel then
		if intel.VisionRadius ~= 0 then
			intelText = ("Vision: " .. LOUD_KiloCheck(intel.VisionRadius * 20))
		end
		if intel.RadarRadius ~= 0 then
			intelText = (intelText .. ", Radar: " .. LOUD_KiloCheck(intel.RadarRadius * 20))
		end
		if intel.SonarRadius ~= 0 then
			intelText = (intelText .. ", Sonar: " .. LOUD_KiloCheck(intel.SonarRadius * 20))
		end
		
		-- Insert the intel text into the table.
		if intelText ~= "" then
			table.insert(textLines, intelText)
		end
		-- Get the index of the intel text line from the textLines table.
		intel_line = table.getn(textLines)
	end

	-- Unit cap
	if capCost then
		local capCostStr = string.format("%.1f", capCost)
		capCostStr = capCostStr:gsub("%.?0+$", "")
		table.insert(textLines, "Unit Cap Cost: "..capCostStr)
	else
		table.insert(textLines, "Unit Cap Cost: 1")
	end
	cap_line = table.getn(textLines)

	for i, v in textLines do
	
		local index = i
		
		if control.Value[index] then
			-- If control.Value (View.Description) has a value, 
			-- set the text of the value to the value of the index we're looping through.
			control.Value[index]:SetText(v)
		else
			-- If control.Value (View.Description) has no value, we create the value.
			control.Value[index] = UIUtil.CreateText( control, v, 12, UIUtil.bodyFont)
			LayoutHelpers.Below(control.Value[index], control.Value[index-1])
			LayoutHelpers.AtRightIn(control.Value[index], control, 7)
			control.Value[index].Width:Set(function() return control.Right() - control.Left() - LayoutHelpers.ScaleNumber(14) end)
			control.Value[index]:SetClipToWidth(true)
			control.Value[index]:DisableHitTest(true)
		end
		
		-- Set colors of lines.
		if index <= abilityLines then
			control.Value[index]:SetColor(UIUtil.bodyColor)
			control.Value[index]:SetFont(UIUtil.bodyFont, 12)
		elseif index == physics_line then
			-- Physics text color
			control.Value[index]:SetColor('ff83d5e6')
			-- Text font size
			control.Value[index]:SetFont(UIUtil.bodyFont, 11)
		elseif index == intel_line then
			-- Intel text color
			control.Value[index]:SetColor('ff29757e')
			-- Text font size
			control.Value[index]:SetFont(UIUtil.bodyFont, 11)
		elseif index > weapon_start and index <= weapon_end then
			control.Value[index]:SetFont(UIUtil.bodyFont, 11)
			if LOUDFIND(tostring(v), "Direct") then	-- Direct Fire
				control.Value[index]:SetColor('ffff3333')
			elseif LOUDFIND(tostring(v), "Indirect") then -- Indirect Fire
				control.Value[index]:SetColor('ffffff00')
			elseif LOUDFIND(tostring(v), "Anti Navy") then -- Anti Navy
				control.Value[index]:SetColor('ff00ff00')
			elseif LOUDFIND(tostring(v), "Anti Air") then -- Anti Air
				control.Value[index]:SetColor('ff00ffff')
			elseif LOUDFIND(tostring(v), " Defense") then -- Countermeasure
				control.Value[index]:SetColor('ffffa500')
			elseif LOUDFIND(tostring(v), "Nuke") then -- Nuke
				control.Value[index]:SetColor('ffffa500')
			elseif LOUDFIND(tostring(v), "Crash") then -- Air Crash
				control.Value[index]:SetColor('ffb077ff')
			elseif LOUDFIND(tostring(v), "Volatile") then -- Volatile
				control.Value[index]:SetColor('ffb077ff')
			elseif LOUDFIND(tostring(v), "Suicide") then -- Kamikaze/Suicide
				control.Value[index]:SetColor('ffb077ff')
			elseif LOUDFIND(tostring(v), "Melee") then	-- Melee
				control.Value[index]:SetColor('ffff3333')
			else
				control.Value[index]:SetColor('ff909090')
			end
		elseif index == cap_line then
			control.Value[index]:SetColor(UIUtil.fontColor)
			control.Value[index]:SetFont(UIUtil.bodyFont, 11)
		else
			control.Value[index]:SetColor(UIUtil.fontColor)
			control.Value[index]:SetFont(UIUtil.bodyFont, 12)
		end
		
		control.Height:Set(function() return (math.max(table.getsize(textLines), 4) * control.Value[1].Height()) + LayoutHelpers.ScaleNumber(30) end)
	end
	
	for i, v in control.Value do
	
		local index = i
		
		if index > table.getsize(textLines) then
			v:SetText("")
		end
	end
end