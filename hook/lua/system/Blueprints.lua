-- WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] * QUIET Hook for Blueprints.lua' ) 
-- This warning allows us to see exactly where our Hook Line starts so we can debug the exact line thats causing an error easier
do
	local pairs = pairs
	
	local TableFind = table.find
	local TableGetn = table.getn
	local TableInsert = table.insert

	local MathMax = math.max
	local MathFloor = math.floor
	local MathSqrt = math.sqrt

	local StringFind = string.find

	local weaponTargetCheckUpperLimit = 6000

	-- QCE clobbers the ModBlueprints to remove many nebulous changes in the Blueprints.lua that significantly affect Unit BPs Globally
	-- QCE cleans the Blueprints.lua up and sections them into their own functions with exact action names to allow people to see what's going on more clearly
	local OldModBlueprints = ModBlueprints

	function ModBlueprints(all_blueprints)
		OldModBlueprints(all_blueprints)
		--
		BalanceAlterations(all_blueprints)
		EnergyChargeAlterations(all_blueprints)
		UnitAlterations(all_blueprints)
		ReclaimAlterations(all_blueprints)
		NotificationAlterations(all_blueprints)
		--
		NullifyUnitBlueprints(all_blueprints)
		--
		ProcessWeaponAlterations(all_blueprints, all_blueprints.Unit)
		ProcessPropAlterations(all_blueprints)
		ProcessDynamicLOD(all_blueprints)
	end

	--=======================================
	-- Various Local Functions that assist with Functions farther in this file
	--=======================================
	local function DetermineWeaponDPS(weapon)
		--- With thanks to Sean 'Balthazar' Wheeldon
		-- Base values
		local ProjectileCount
		if weapon.MuzzleSalvoDelay == 0 then
			ProjectileCount = MathMax(1, TableGetn(weapon.RackBones[1].MuzzleBones or { 'nehh' }))
		else
			ProjectileCount = (weapon.MuzzleSalvoSize or 1)
		end
		if weapon.RackFireTogether then
			ProjectileCount = ProjectileCount * MathMax(1, TableGetn(weapon.RackBones or { 'nehh' }))
		end
		-- Game logic rounds the timings to the nearest tick --  MathMax(0.1, 1 / (weapon.RateOfFire or 1)) for unrounded values
		local DamageInterval = MathFloor((MathMax(0.1, 1 / (weapon.RateOfFire or 1)) * 10) + 0.5) / 10 +
			ProjectileCount *
			(MathMax(weapon.MuzzleSalvoDelay or 0, weapon.MuzzleChargeDelay or 0) * (weapon.MuzzleSalvoSize or 1))
		local Damage = ((weapon.Damage or 0) + (weapon.NukeInnerRingDamage or 0)) * ProjectileCount * (weapon.DoTPulses or 1
			)
		
		-- Beam calculations.
		if weapon.BeamLifetime and weapon.BeamLifetime == 0 then
			-- Unending beam. Interval is based on collision delay only.
			DamageInterval = 0.1 + (weapon.BeamCollisionDelay or 0)
		elseif weapon.BeamLifetime and weapon.BeamLifetime > 0 then
			-- Uncontinuous beam. Interval from start to next start.
			DamageInterval = DamageInterval + weapon.BeamLifetime
			-- Damage is calculated as a single glob, beam weapons are typically underappreciated
			Damage = Damage * (weapon.BeamLifetime / (0.1 + (weapon.BeamCollisionDelay or 0)))
		end
		
		return (Damage / DamageInterval) or 0
	end

	local function DetermineWeaponCategory(weapon)
		--- With thanks to Sean 'Balthazar' Wheeldon
		if weapon.RangeCategory == 'UWRC_AntiAir' or weapon.TargetRestrictOnlyAllow == 'AIR' or
			StringFind(weapon.WeaponCategory or 'nope', 'Anti Air') then
			return 'ANTIAIR'
		end
		
		if weapon.RangeCategory == 'UWRC_AntiNavy' or StringFind(weapon.WeaponCategory or 'nope', 'Anti Navy') then
			return 'ANTINAVY'
		end
		
		if weapon.RangeCategory == 'UWRC_DirectFire' or StringFind(weapon.WeaponCategory or 'nope', 'Direct Fire') then
			return 'DIRECTFIRE'
		end
		
		if weapon.RangeCategory == 'UWRC_IndirectFire' or StringFind(weapon.WeaponCategory or 'nope', 'Artillery') then
			return 'INDIRECTFIRE'
		end
		
		if weapon.RangeCategory == 'UWRC_Countermeasure' or StringFind(weapon.WeaponCategory or 'nope', 'Defense') then
			return 'COUNTERMEASURE'
		end

		return nil
	end

	--=======================================
	-- Various Processing Functions To Pass Data Correctly
	-- To Various Functions
	--=======================================
	function ProcessWeaponAlterations(all_blueprints, units)
		local StringLower = string.lower
	
		local unitsToSkip = {
			daa0206 = true,
		}
	
		for _, unit in units do
			if not unitsToSkip[StringLower(unit.bp.BlueprintId or "")] then
				if unit.Weapon then
					for _, weapon in unit.Weapon do
						if not weapon.DummyWeapon then
	
							local projectile
							local projectileId = string.lower(tostring(weapon.ProjectileId))
							for k, projectile in all_blueprints.Projectile do
								if string.lower(tostring(projectile.Source)) == projectileId then
									projectile = projectile
									break
								end
							end
	
							WeaponAlterations(unit, weapon, projectile)
						end
					end
				end
			end
		end
	end

	function ProcessPropAlterations(all_blueprints)
		if all_blueprints.Prop then
			for _, prop in pairs(all_blueprints.Prop) do
				PropAlterations(prop)
			end
		end
	end

	--=======================================
	-- FUNCTION BalanceAlterations(ALL_BLUEPRINTS)
	-- Overrall Balance Alterations that are changing vast amounts of blueprints to standardize/change values in Blueprints
	--=======================================
	function BalanceAlterations(all_blueprints)
		local T1_Adjustment = 0
		local T2_Adjustment = 0
		local T3_Adjustment = 0
		local T4_Adjustment = 0

		for id, bp in all_blueprints.Unit do
			if bp.Categories then
				local cats = {}
				for k, cat in pairs(bp.Categories) do
					cats[cat] = true
				end

				if cats.LAND and cats.MOBILE then
					-- UniformScale universally to make t2 & t3 more mobile
					-- Reset T1 & T2 Health & Speed back to normal
					T1_Adjustment = 0.893
					T2_Adjustment = 0.944
					T3_Adjustment = 1.00

					if cats.TECH1 then
						bp.Defense.MaxHealth = bp.Defense.MaxHealth * T1_Adjustment

						bp.Defense.Health = bp.Defense.MaxHealth

						if bp.Physics.MaxSpeed then
							bp.Physics.MaxSpeed = bp.Physics.MaxSpeed * T1_Adjustment
						end
					elseif cats.TECH2 then
						bp.Defense.MaxHealth = bp.Defense.MaxHealth * T2_Adjustment

						bp.Defense.Health = bp.Defense.MaxHealth

						if bp.Physics.MaxSpeed then
							bp.Physics.MaxSpeed = bp.Physics.MaxSpeed * T2_Adjustment
						end

						-- make them appear a little smaller
						if bp.Display.UniformScale then
							bp.Display.UniformScale = bp.Display.UniformScale * .95
						end
					elseif cats.TECH3 then
						bp.Defense.MaxHealth = bp.Defense.MaxHealth * T3_Adjustment

						bp.Defense.Health = bp.Defense.MaxHealth

						-- make them appear a little smaller
						if bp.Display.UniformScale then
							bp.Display.UniformScale = bp.Display.UniformScale * .95
						end
					end
				end

				if cats.AIR and cats.BOMBER then
					-- This fixes all bombers to be not so weak to dodge micro
					-- This also fixes T2 & Ahwassa Bombers not dropping at all in many cases

					if cats.TECH1 or cats.TECH2 or cats.TECH3 or cats.EXPERIMENTAL then
						if bp.Weapon[1].BombDropThreshold then
							bp.Weapon[1].BombDropThreshold = bp.Weapon[1].BombDropThreshold * 2
						end

						if bp.Weapon[1].FiringTolerance then
							bp.Weapon[1].FiringTolerance = bp.Weapon[1].FiringTolerance * 2
						end
					end
				end

				-- Remove the FUELRATIO buff if it exists
				if cats.ALLUNITS then
					if bp.Weapon[1].Buffs and bp.Weapon[1].Buffs.BuffType == 'FUELRATIO' then
						bp.Weapon[1].Buffs = nil
					end
				end

				-- all structures
				-- LCE: Leaving this in here until we decide if we want to reset it to the default ranges instead of 9% least range
				if cats.STRUCTURE then
					-- the purpose of this alteration is to address the parity of T2 and T3 static defenses with respect to mobile units
					-- I felt, and the numbers clearly show, that a tremendous range difference crept into the game as many 3rd party
					-- point defenses were added - blame the UEF Ravager for setting a bad precedent with a range of 65 - others that
					-- followed often went beyond that, which made even mobile artillery effectively pointless, and greatly encouraged
					-- 'turtling' instead of mobile warfare

					-- This mod addresses that by bringing any DIRECTFIRE structures back into some kind of normalacy and giving the
					-- mobile units some chance of getting within firing range before being completely shellacked.
					if cats.DIRECTFIRE then
						if cats.EXPERIMENTAL then
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

				-- Adds DRAGBUILD to all Units
				local CatsMisc = {
					'DRAGBUILD',
				}
				for i, cat in CatsMisc do
					if not cats[cat] then
						table.insert(bp.Categories, cat)
					end
				end

				-- Allow T2, T3, & T4 Engineers to Build T2 Factories
				local CatsT2 = {
					'BUILTBYTIER2ENGINEER',
					'BUILTBYTIER3ENGINEER',
					'BUILTBYTIER4ENGINEER',
					'BUILTBYTIER2COMMANDER',
					'BUILTBYTIER3COMMANDER',
					'BUILTBYTIER4COMMANDER',
				}
				if cats.BUILTBYTIER1FACTORY and cats.FACTORY and cats.STRUCTURE and cats.TECH2 then
					for i, cat in CatsT2 do
						if not cats[cat] then
							table.insert(bp.Categories, cat)
						end
					end
				end

				-- Allow T3 Engineers to Build T3 Factories
				local CatsT3 = {
					'BUILTBYTIER3ENGINEER',
					'BUILTBYTIER3COMMANDER',
				}
				if cats.BUILTBYTIER2FACTORY and cats.FACTORY and cats.STRUCTURE and cats.TECH3 then
					for i, cat in CatsT3 do
						if not cats[cat] then
							table.insert(bp.Categories, cat)
						end
					end
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
			end
		end
		--LOG("*AI DEBUG Adding NAVAL Wreckage information and setting wreckage lifetime")
	end

	--=======================================
	-- FUNCTION UnitAlterations(ALL_BLUEPRINTS)
	-- This is for Unit Alterations that do not belong in BalanceAlterations 
	-- First function is mostly for direct balance the second one is for other stuff like QoL
	--=======================================
	function UnitAlterations(all_blueprints)
		for id, bp in all_blueprints.Unit do
			-- create hash tables for quick lookup
			bp.CategoriesCount = 0
			bp.CategoriesHash = {}
			if bp.Categories then
				bp.CategoriesCount = table.getn(bp.Categories)
				for k, category in pairs(bp.Categories) do
					bp.CategoriesHash[category] = true
				end
			end
		
			bp.CategoriesHash[bp.BlueprintId or 'nope'] = true
		
			-- sanitize guard scan radius
		
			-- The guard scan radius is used when:
			-- - A unit attack moves, it determines how far the unit remains from its target
			-- - A unit patrols, it determines when the unit decides to engage
		
			-- All of the decisions below are made based on when a unit attack moves, as that is
			-- the default meta to use in competitive play. This is by all means not perfect,
			-- but it is the best we can do when we need to consider the performance of it all
		
			local isEngineer = bp.CategoriesHash['ENGINEER']
			local isStructure = bp.CategoriesHash['STRUCTURE']
			local isDummy = bp.CategoriesHash['DUMMYUNIT']
			local isLand = bp.CategoriesHash['LAND']
			local isAir = bp.CategoriesHash['AIR']
			local isNaval = bp.CategoriesHash['NAVAL']
			local isBomber = bp.CategoriesHash['BOMBER']
			local isGunship = bp.CategoriesHash['GROUNDATTACK'] and isAir and (not isBomber)
			local isTransport = bp.CategoriesHash['TRANSPORTATION']
			local isPod = bp.CategoriesHash['POD']
		
			local isTech1 = bp.CategoriesHash['TECH1']
			local isTech2 = bp.CategoriesHash['TECH2']
			local isTech3 = bp.CategoriesHash['TECH3']
			local isExperimental = bp.CategoriesHash['EXPERIMENTAL']
			local isACU = bp.CategoriesHash['COMMAND']
			local isSACU = bp.CategoriesHash['SUBCOMMANDER']
		
			-- do not touch guard scan radius values of engineer-like units, as it is the reason we have
			-- the factory-reclaim-bug that we're keen in keeping that at this point
			if not isEngineer then
				bp.AI = bp.AI or {}
		
				if bp.AI.GuardScanRadius == nil then
					if isStructure or isDummy then
						bp.AI.GuardScanRadius = 0
					elseif isEngineer then -- engineers need their factory reclaim bug
						bp.AI.GuardScanRadius = 26 -- allows for factory reclaim bug
					else 
						local primaryWeapon = bp.Weapon[1]
						if primaryWeapon and not (
							primaryWeapon.DummyWeapon or
								primaryWeapon.WeaponCategory == 'Death' or
								primaryWeapon.Label == 'DeathImpact' or
								primaryWeapon.DisplayName == 'Air Crash'
							) then
							local isAntiAir = primaryWeapon.RangeCategory == 'UWRC_AntiAir'
							local maxRadius = primaryWeapon.MaxRadius or 0
		
							-- land to air units should not get triggered too fast
							if isLand and isAntiAir then
								bp.AI.GuardScanRadius = 0.80 * maxRadius
							else 
								bp.AI.GuardScanRadius = 1.10 * maxRadius
							end
						else 
							bp.AI.GuardScanRadius = 0
						end
		
						-- cap it, so units don't have extreme values based on their attack radius
						if isTech1 and bp.AI.GuardScanRadius > 40 then
							bp.AI.GuardScanRadius = 40
						elseif isTech2 and bp.AI.GuardScanRadius > 80 then
							bp.AI.GuardScanRadius = 80
						elseif isTech3 and bp.AI.GuardScanRadius > 120 then
							bp.AI.GuardScanRadius = 120
						elseif isExperimental and bp.AI.GuardScanRadius > 160 then
							bp.AI.GuardScanRadius = 160
						end
		
						-- ROUND THAT SHIT HOMIE
						bp.AI.GuardScanRadius = math.floor(bp.AI.GuardScanRadius)
					end
				end
			end

			-- Build range overlay
			if isEngineer and not (bp.CategoriesHash['INSIGNIFICANTUNIT'] or bp.CategoriesHash['AIRSTAGINGPLATFORM']) then
				if not bp.AI then bp.AI = {} end

				-- Engine allows building +2 range outside the max distance (or even more for large buildings)
				-- I hate pathfinding in Supreme Commander
				local overlayRadius = (bp.Economy.MaxBuildDistance or 5) + 2

				-- Display auto-assist range for engineer stations instead of max build distance if it is smaller and exists
				if bp.CategoriesHash['ENGINEERSTATION'] then
					local guardScanRadius = bp.AI.GuardScanRadius
					if guardScanRadius and guardScanRadius < overlayRadius then
						overlayRadius = guardScanRadius
					end
				end

				bp.AI.StagingPlatformScanRadius = overlayRadius
				table.insert(bp.Categories, 'OVERLAYMISC')
				bp.CategoriesHash.OVERLAYMISC = true
			end

			-- local ura0001 = bp.CategoriesHash["ura0001"]
			-- -- Check size of collision boxes
			-- local function logUra0001()
			-- 	if ura0001 then
			-- 		LOG("ura0001 is not nil, so collision box size is not being checked")
			-- 		LOG("bp.CategoriesHash: "..repr(bp.CategoriesHash["ura0001"]))
			-- 	else
			-- 		LOG("ura0001 is nil, so collision box size is being checked")
			-- 		--LOG("bp.CategoriesHash: "..repr(bp.CategoriesHash["ura0001"]))
			-- 	end
			-- end

			-- logUra0001()

			if not(bp.CategoriesHash["ura0001"] or isDummy) then
				-- find maximum speed
				local speed = bp.Physics.MaxSpeed
				if bp.Air and bp.Air.MaxAirspeed then
					speed = bp.Air.MaxAirspeed
				end
		
				-- determine if collision box is fine
				if speed then
					if bp.SizeSphere then
						if bp.SizeSphere < 0.1 * speed then
							-- WARN(string.format("Overriding the size of the collision sphere of unit ( %s ), it should be atleast 10 percent ( %s ) of the maximum speed ( %s ) to guarantee proper functioning beam weapons"
							--  	, tostring(bp.BlueprintId), tostring(0.1 * speed), tostring(speed)))
							bp.SizeSphere = 0.1 * speed
						end
					else
						if bp.SizeX < 0.1 * speed then
							-- WARN(string.format("Overriding the x axis of collision box of unit ( %s ), it should be atleast 10 percent ( %s ) of the maximum speed ( %s ) to guarantee proper functioning beam weapons"
							--  	, tostring(bp.BlueprintId), tostring(0.1 * speed), tostring(speed)))
							bp.SizeX = 0.1 * speed
						end
		
						if bp.SizeZ < 0.1 * speed then
							-- WARN(string.format("Overriding the z axis of collision box of unit ( %s ), it should be atleast 10 percent ( %s ) of the maximum speed ( %s ) to guarantee proper functioning beam weapons"
							--  	, tostring(bp.BlueprintId), tostring(0.1 * speed), tostring(speed)))
							bp.SizeZ = 0.1 * speed
						end
		
						if bp.SizeY < 0.5 then
							-- WARN(string.format("Overriding the y axis of collision box of unit ( %s ), it should be atleast 0.5 to guarantee proper functioning gunships"
							--  	, tostring(bp.BlueprintId), tostring(0.1 * speed), tostring(speed)))
							bp.SizeY = 0.5
						end
					end
				end
			end

			local weapons = bp.Weapon
			if weapons then

				-- determine total dps per category
				local damagePerRangeCategory = {
					DIRECTFIRE = 0,
					INDIRECTFIRE = 0,
					ANTIAIR = 0,
					ANTINAVY = 0,
					COUNTERMEASURE = 0,
				}

				for k, weapon in pairs(weapons) do
					local dps = DetermineWeaponDPS(weapon)
					local category = DetermineWeaponCategory(weapon)
					if category then
						damagePerRangeCategory[category] = damagePerRangeCategory[category] + dps
					else
						if weapon.WeaponCategory ~= 'Death' then
							--WARN("Invalid weapon on " .. bp.BlueprintId)
						end
					end
				end

				local array = {
					{
						RangeCategory = "DIRECTFIRE",
						Damage = damagePerRangeCategory["DIRECTFIRE"]
					},
					{
						RangeCategory = "INDIRECTFIRE",
						Damage = damagePerRangeCategory["INDIRECTFIRE"]
					},
					{
						RangeCategory = "ANTIAIR",
						Damage = damagePerRangeCategory["ANTIAIR"]
					},
					{
						RangeCategory = "ANTINAVY",
						Damage = damagePerRangeCategory["ANTINAVY"]
					},
					{
						RangeCategory = "COUNTERMEASURE",
						Damage = damagePerRangeCategory["COUNTERMEASURE"]
					}
				}

				table.sort(array, function(e1, e2) return e1.Damage > e2.Damage end)
				local factor = array[1].Damage

				for category, damage in pairs(damagePerRangeCategory) do
					if damage > 0 then
						local cat = "OVERLAY" .. category
						if not bp.CategoriesHash[cat] then
							table.insert(bp.Categories, cat)
							bp.CategoriesHash[cat] = true
							bp.CategoriesCount = bp.CategoriesCount + 1
						end

						local cat = "WEAK" .. category
						if not (
							category == 'COUNTERMEASURE' or
								bp.CategoriesHash['COMMAND'] or
								bp.CategoriesHash['STRATEGIC'] or
								bp.CategoriesHash[cat]
							) and damage < 0.2 * factor
						then
							table.insert(bp.Categories, cat)
							bp.CategoriesHash[cat] = true
							bp.CategoriesCount = bp.CategoriesCount + 1
						end
					end
				end
			end

			local averageDensity = 10
			if bp.Defense and bp.Defense.MaxHealth then
				averageDensity = bp.Defense.MaxHealth

				if bp.Physics and bp.Physics.MotionType == "RULEUMT_Hover" then
					averageDensity = 0.50 * averageDensity
				end
			end

			if not bp.AverageDensity then
				bp.AverageDensity = 0
			end

			if averageDensity ~= bp.AverageDensity then
				--WARN(string.format("Overwriting the average density of %s from %s to %s", tostring(bp.BlueprintId), bp.AverageDensity, averageDensity))
			end

			bp.AverageDensity = averageDensity
			--LOG("Unit is "..repr(bp.BlueprintId).." AverageDensity is "..repr(bp.AverageDensity))
		end
	end

	--=======================================
	-- FUNCTION WeaponAlterations(ALL_BLUEPRINTS)
	-- This is for Weapon Alterations that do not belong in BalanceAlterations or UnitAlterations
	--=======================================
	function WeaponAlterations(unit, weapon, projectile)
		--LOG("WeaponAlterations Start")
		-- pre-compute flags   
		local isAir = false
		local isStructure = false
		local isBomber = false
		local isExperimental = false
		local isTech3 = false
		local isTech2 = false
		if unit.Categories then
			for _, category in unit.Categories do
				isStructure = isStructure or category == "STRUCTURE"
				isAir = isAir or category == "AIR"
				isBomber = isBomber or category == "BOMBER"
				isTech2 = isTech2 or category == "TECH2"
				isTech3 = isTech3 or category == "TECH3"
				isExperimental = isExperimental or category == "EXPERIMENTAL"
			end
		end
	
		-- process weapon
	
		-- Death weapons of any kind
		if weapon.DamageType == "DeathExplosion" or weapon.Label == "DeathWeapon" or weapon.Label == "DeathImpact" then
			weapon.TargetCheckInterval = weaponTargetCheckUpperLimit
			weapon.AlwaysRecheckTarget = false
			weapon.TrackingRadius = 0.0
			return
		end
	
		-- Tactical, strategical missile and torpedo defenses
		if weapon.RangeCategory == "UWRC_Countermeasure" or weapon.TargetType == "RULEWTT_Projectile" then
			weapon.TargetCheckInterval = weapon.TargetCheckInterval or 0.4
			weapon.AlwaysRecheckTarget = false
			weapon.TrackingRadius = 1.0
			weapon.ManualFire = false
			return
		end
	
		-- manual launch of tactical and strategic missiles
		if weapon.ManualFire then
			weapon.TargetCheckInterval = weaponTargetCheckUpperLimit
			weapon.AlwaysRecheckTarget = false
			weapon.TrackingRadius = 0.0
			return
		end
	
		-- process target check interval
	
		-- if it is set then we use that - allows us to make adjustments as we see fit
		if weapon.TargetCheckInterval == nil then
			local intervalByRateOfFire = 0.5 / (weapon.RateOfFire or 1)
			local intervalByRadius = (weapon.MaxRadius or 10) / 30
			weapon.TargetCheckInterval = math.min(intervalByRateOfFire, intervalByRadius)
	
			-- clamp value to something sane
			if weapon.TargetCheckInterval < 0.4 and (not isExperimental) then
				weapon.TargetCheckInterval = 0.4
			end
	
			-- clamp value to something sane
			if weapon.TargetCheckInterval < 0.2 then
				weapon.TargetCheckInterval = 0.2
			end
	
			-- clamp value to something sane
			if weapon.TargetCheckInterval > 3 then
				weapon.TargetCheckInterval = 3
			end
	
			-- allow weapons that retarget to have a relative fast target check interval
			if projectile then
				if projectile.Physics.TrackTarget and weapon.TargetCheckInterval > 0.8 then
					weapon.TargetCheckInterval = 0.8
				end
			end
		end
	
		-- process target tracking radius 
	
		-- if it is set then we use that - allows us to make adjustments as we see fit
		if weapon.TrackingRadius == nil then
			-- by default, give every unit a 5% target checking radius
			weapon.TrackingRadius = 1.05
	
			-- remove target tracking radius for non-aa weaponry part of structures
			if isStructure and weapon.RangeCategory ~= "UWRC_AntiAir" then
				weapon.TrackingRadius = 1.0
			end
	
			-- give anti air a larger track radius
			if weapon.RangeCategory == "UWRC_AntiAir" then
				weapon.TrackingRadius = 1.15
			end
	
			-- add significant target checking radius for bombers
			if isBomber then 
				weapon.TrackingRadius = 1.25
			end
		end
	
		-- # process target rechecking
	
		-- if it is set then we use that - allows us to make adjustments as we see fit
		if weapon.AlwaysRecheckTarget == nil then
	
			-- by default, do not recheck targets as that is expensive when a lot of units are stacked on top of another
			weapon.AlwaysRecheckTarget = false
	
			-- allow 
			if  weapon.RangeCategory == 'UWRC_DirectFire' or
				weapon.RangeCategory == "UWRC_IndirectFire" or
				weapon.MaxRadius > 50 and (weapon.RangeCategory ~= "UWRC_AntiNavy") then
				weapon.AlwaysRecheckTarget = true
			end
	
			-- always allow anti air weapons attached to structures to retarget, as otherwise they may be stuck on a scout
			if isStructure and weapon.RangeCategory == "UWRC_AntiAir" then
				weapon.AlwaysRecheckTarget = true
			end
	
			-- always allow experimentals to retarget
			if isExperimental then
				weapon.AlwaysRecheckTarget = true
			end
		end
	
		-- # sanitize values
	
		-- do not allow the 'bomb weapon' of bombers to suddenly retarget, as then they won't drop their bomb when they do
		if weapon.NeedToComputeBombDrop then
			weapon.AlwaysRecheckTarget = false
		end
	
		weapon.TargetCheckInterval = 0.1 * math.floor(10 * weapon.TargetCheckInterval)
		weapon.TrackingRadius = 0.1 * math.floor(10 * weapon.TrackingRadius)
		--LOG("WeaponAlterations End")
	end

	function PropAlterations(prop)

		local sx = prop.SizeX or 1
		local sy = prop.SizeY or 1
		local sz = prop.SizeZ or 1
	
		-- give more emphasis to the x / z value as that is easier to see in the average camera angle
		local weighted = 0.40 * sx + 0.2 * sy + 0.4 * sz
		if prop.ScriptClass == 'Tree' or prop.ScriptClass == 'TreeGroup' then
			weighted = 2.6
		end
	
		-- https://www.desmos.com/calculator (0.9 * sqrt(100 * 500 * x))
		local lod = 0.9 * MathSqrt(100 * 500 * weighted)
	
		if prop.Display and prop.Display.Mesh and prop.Display.Mesh.LODs then
			local n = TableGetn(prop.Display.Mesh.LODs)
			for k = 1, n do
				local data = prop.Display.Mesh.LODs[k]
	
				-- https://www.desmos.com/calculator (x * x)
				local factor = (k / n) * (k / n)
				local LODCutoff = factor * lod
	
				-- sanitize the value
				data.LODCutoff = MathFloor(LODCutoff / 10 + 1) * 10
			end
		end
	end

	
	--=======================================
	-- FUNCTION ProcessDynamicLOD(ALL_BLUEPRINTS)
	-- Computes the LOD cut off values of props based on its blueprint properties. A
	-- prop that occupies less screen space will have a lower cut off value - allowing
	-- it to be culled sooner. This improves the framerate of the game in general,
	-- while having a minor impact on visual fidelity.
	--
	-- Technical detail: The LOD values of props in the blueprint are now ignored.
	--=======================================
	function ProcessDynamicLOD(all_blueprints)
		local function computeLOD(bp)
			if bp.Display and bp.Display.Mesh and bp.Display.Mesh.LODs then
				local n = TableGetn(bp.Display.Mesh.LODs)
				for k, data in pairs(bp.Display.Mesh.LODs) do
					local sx = bp.SizeX or 1
					local sy = bp.SizeY or 1
					local sz = bp.SizeZ or 1

					local weighted = 0.40 * sx + 0.2 * sy + 0.4 * sz
					local lod = 0.9 * MathSqrt(100 * 500 * weighted)
					local factor = (k / n) * (k / n)
					local LODCutoff = factor * lod

					data.LODCutoff = MathFloor(LODCutoff / 10 + 1) * 10
				end
			end
		end

		for id, bp in pairs(all_blueprints.Unit) do
			computeLOD(bp)
		end
		
		for id, bp in pairs(all_blueprints.Prop) do
			computeLOD(bp)
		end
	end

	--=======================================
	-- FUNCTION RECLAIMALTERATIONS(ALL_BLUEPRINTS)
	-- QCE's Reclaim Adjustments to encourage more aggression early game but punish hyper aggression lategame, this enables comeback mechanics.
	-- This also fixes an issue where many units lack a bp.wreckage table
	--=======================================
	function ReclaimAlterations(all_blueprints)
		for id, bp in pairs(all_blueprints.Unit) do
			local cats = {}

			if bp.Categories then
				for k, cat in pairs(bp.Categories) do
					cats[cat] = true
				end

				-- Rework This In the Future for Air, Naval, and Land
				if cats.NAVAL then
					if not bp.Wreckage then
						bp.Wreckage = {
							Blueprint = '/props/DefaultWreckage/DefaultWreckage_prop.bp',
							EnergyMult = 0,
							HealthMult = 0.9,
							LifeTime = 720, -- give naval wreckage a lifetime value of 12 minutes
							MassMult = 0.5,
							ReclaimTimeMultiplier = 1.2,

							WreckageLayers = {
								Air = false,
								Land = false,
								Seabed = true,
								Sub = true,
								Water = true,
							},
						}
					else
						local wl = bp.Wreckage.WreckageLayers
						wl.Seabed = true
						wl.Sub = true
						wl.Water = true
						bp.Wreckage.LifeTime = 720
					end

				else

					if not bp.Wreckage then
						-- Add Wreckage to all Blueprints to create more wreckage in the game, goes in hand with the change in Unit.lua to overkillRatio.
						-- We comment out MassMult Adjustments for now to see how it affects gameplay.
						-- We remove Energy Reclaim from all wrecks to focus Macro more on Energy Production rather then 30 minutes of Macro for Mass Extractor Upgrades.
						-- We remove the entire section that manipulates blueprints
						-- LOG("Adding BP Wreckage")
						bp.Wreckage = {
							Blueprint = '/props/DefaultWreckage/DefaultWreckage_prop.bp',
							EnergyMult = 0,
							HealthMult = 0.9,
							LifeTime = 720, -- give land wreckage a lifetime value of 12 minutes
							MassMult = 0.75,
							ReclaimTimeMultiplier = 1.2,
							WreckageLayers = {
								Land = true,
							},
						}
					else
						if not bp.Wreckage.LifeTime then
							bp.Wreckage.LifeTime = 720
						end

						if bp.Wreckage.MassMult <= 0.75 or bp.Wreckage.MassMult > 0.75 then
							bp.Wreckage.EnergyMult = 0
							bp.Wreckage.HealthMult = 0.9
							bp.Wreckage.LifeTime = 720
							bp.Wreckage.MassMult = 0.75
							bp.Wreckage.ReclaimTimeMultiplier = 1.2

							local wl = bp.Wreckage.WreckageLayers
							wl.Land = true
						end
					end
				end
				
			end
		end
	end

	--=======================================
	-- FUNCTION NOTIFICATIONALTERATIONS(ALL_BLUEPRINTS)
	-- QCE's NotificationAlterations + Misc
	-- Wonky Resources allows mexes to always be placed no matter the terrain
	-- Other part is notifications for pings/audio for Commanders, Mex Attacks, and etc
	--=======================================

	function NotificationAlterations(all_blueprints)
		--LOG("*AI DEBUG Adding Audio Cues for COMMANDERS - NUKES - FERRY ROUTES - EXTRACTORS")

		local factions = { 'UEF', 'Aeon', 'Cybran', 'Aeon' }

		for i, bp in pairs(all_blueprints.Unit) do
			if bp.Categories then
				local categories = {}

				for j, category in pairs(bp.Categories) do
					categories[category] = true
				end

				for j, faction in pairs(factions) do
					if categories['TRANSPORTATION'] == true then
						bp.Audio['FerryPointSetBy' .. faction] = nil
					end
				end
			end
		end
	end

	--=======================================
	-- FUNCTION NullifyUnitBlueprints(ALL_BLUEPRINTS)
	-- Nullify categories on units we don't want to see built
	--=======================================
	function NullifyUnitBlueprints(all_blueprints)
		local unitPruningId = {
			'brnt2bm',   -- Banshee
			'wrl0305',   -- Echidna
			'wel03041',  -- Walrus
			'brnt3wt',   -- WarHammer
			'dea0202',   -- Janus
			'dra0202',   -- Corsair
			'uel0402',   -- Rampage
			'brnt3abb',  -- Ironfist
			'brpat2bomber', -- Vesinee
			'xsa0202',   -- Notha
			'uab8765',   -- Exp Storage Aeon
			'urb8765',   -- Exp Storage Cybran
			'ueb8765',   -- Exp Storage UEF
			'xsb8765',   -- Exp Storage Seraphim
			'uabssg01',  -- Exp Square Shield Aeon
			'uebssg01',  -- Exp Square Shield UEF
			'urbssg01',  -- Exp Square Shield Cybran
			'xsbssg01',  -- Exp Square Shield Seraphim
			'seb2404',   -- Exp Drop-Pod Artillery
			'wel0405',   -- King Kraptor
		};
		for i, bp in pairs(unitPruningId) do
			if all_blueprints.Unit[bp] then
				local unit = all_blueprints.Unit[bp];
				if unit then
					unit.Categories = {}
				end
			end
		end
	end

	--=======================================
	-- FUNCTION EnergyChargeAlterations(ALL_BLUEPRINTS)
	-- Adds RenderFireClock to all EnergyCharge Units
	-- Removes RackSalvoFiresAfterCharge Temporarily until all units are fixed 
	--=======================================
	local unitContinueId = {
		'srb2402',
		'ueb2306',
		'ueb2401',
		'wal0401',
		'ual0401',
		'xsb2204',
		'url0401',
		'ssb2404',
		'xab2307',
		'uab2302',
		'ueb2302',
		'urb2302',
		'xsb2302',
		'wra0401',
		'brmt1expd',
		'brmt1expdt2',
		'brmt3pdro',
		'brnt3pdro',
		'brot1expd',
		'brot3pdro',
		'url0304',
		'uel0304',
		'xsl0304',
		'xal0305',
		'xsl0305',
		'ual0204',
		'brl0307',
		'lab2320',
		'leb2320',
		'lrb2320',
		'lsb2320',
		'srl0311',
		'uab2303',
		'urb2303',
		'xsb2303',
		'ueb2303',
		'eal0001',
		'eel0001',
		'erl0001',
		'esl0001',
	};
	-- This is temperory until all units are fixed correctly within the Blueprint
	-- Will be removed once all units are fixed
	function EnergyChargeAlterations(all_blueprints)
		for id, bp in pairs(all_blueprints.Unit) do
			if TableFind(unitContinueId, id) then
				continue
			else
				if bp.Weapon ~= nil then
					for idW, bpW in pairs(bp.Weapon) do
						if bpW.RackSalvoFiresAfterCharge ~= nil then
							bpW.RackSalvoFiresAfterCharge = false
						end
					end
				end
			end

			if bp.EnergyRequired ~= nil and bp.EnergyDrainPerSecond ~= nil then
				if bp.Weapon ~= nil then
					for idW, bpW in pairs(bp.Weapon) do
						if bpW.RenderFireClock == nil then
							bpW.RenderFireClock = true
						end
					end
				end
			end
		end
	end

end -- do end
