do
	-- LCE clobbers the ModBlueprints to remove many nebulous changes in the Blueprints.lua that significantly affect Unit BPs Globally
	-- LCE cleans the Blueprints.lua up and sections them into their own functions with exact action names to allow people to see what's going on more clearly
	local OldModBlueprints = ModBlueprints

	function ModBlueprints(all_blueprints)
		OldModBlueprints(all_blueprints)

		UnitAlterations(all_blueprints)
		ReclaimAlterations(all_blueprints)
		NotificationAlterations(all_blueprints)
		NullifyUnitBlueprints(all_blueprints)
	end

	--=======================================
	-- FUNCTION UNITALTERATIONS(ALL_BLUEPRINTS)
	-- Overrall Unit Alterations that are changing vast amounts of blueprints to standardize/change values in Blueprints
	--=======================================

	function UnitAlterations(all_blueprints)
		local T1_Adjustment = 0
		local T2_Adjustment = 0
		local T3_Adjustment = 0
		local T4_Adjustment = 0

		for id, bp in all_blueprints.Unit do
			if bp.Categories then
				for i, cat in bp.Categories do
					if cat == 'LAND' then
						for j, catj in bp.Categories do
							if catj == 'MOBILE' then
								-- UniformScale universally to make t2 & t3 more mobile
								-- Reset T1 & T2 Health & Speed back to normal
								T1_Adjustment = 0.893
								T2_Adjustment = 0.944
								T3_Adjustment = 1.00

								for _, cat_mobile in bp.Categories do
									if cat_mobile == 'TECH1' then
										bp.Defense.MaxHealth = bp.Defense.MaxHealth * T1_Adjustment

										bp.Defense.Health = bp.Defense.MaxHealth

										if bp.Physics.MaxSpeed then
											bp.Physics.MaxSpeed = bp.Physics.MaxSpeed * T1_Adjustment
										end
									elseif cat_mobile == 'TECH2' then
										bp.Defense.MaxHealth = bp.Defense.MaxHealth * T2_Adjustment

										bp.Defense.Health = bp.Defense.MaxHealth

										if bp.Physics.MaxSpeed then
											bp.Physics.MaxSpeed = bp.Physics.MaxSpeed * T2_Adjustment
										end

										-- make them appear a little smaller
										if bp.Display.UniformScale then
											bp.Display.UniformScale = bp.Display.UniformScale * .95
										end
									elseif cat_mobile == 'TECH3' then
										bp.Defense.MaxHealth = bp.Defense.MaxHealth * T3_Adjustment

										bp.Defense.Health = bp.Defense.MaxHealth

										-- make them appear a little smaller
										if bp.Display.UniformScale then
											bp.Display.UniformScale = bp.Display.UniformScale * .95
										end
									end
								end
							end
						end
					end

					if cat == 'AIR' then
						for j, catj in bp.Categories do
							if catj == 'BOMBER' then
								-- This fixes all bombers to be not so weak to dodge micro
								-- This also fixes T2 & Ahwassa Bombers not dropping at all in many cases

								for _, cat_mobile in bp.Categories do
									if cat_mobile == 'TECH1' or cat_mobile == 'TECH2' or cat_mobile == 'TECH3' or cat_mobile == 'EXPERIMENTAL' then
										if bp.Weapon.BombDropThreshold then
											bp.Weapon.BombDropThreshold = bp.Weapon.BombDropThreshold * 2
										end

										if bp.Weapon.FiringTolerance then
											bp.Weapon.FiringTolerance = bp.Weapon.FiringTolerance * 2
										end
									end
								end
							end
						end
					end

					-- all structures
					-- LCE: Leaving this in here until we decide if we want to reset it to the default ranges instead of 9% least range
					if cat == 'STRUCTURE' then
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
				end
			end
		end
		--LOG("*AI DEBUG Adding NAVAL Wreckage information and setting wreckage lifetime")
	end

	--=======================================
	-- FUNCTION RECLAIMALTERATIONS(ALL_BLUEPRINTS)
	-- LCE's Reclaim Adjustments to encourage more aggression early game but punish hyper aggression lategame, this enables comeback mechanics.
	-- This also fixes an issue where many units lack a bp.wreckage table
	--=======================================

	function ReclaimAlterations(all_blueprints)
		for id, bp in pairs(all_blueprints.Unit) do
			local cats = {}

			if bp.Categories then
				for k, cat in pairs(bp.Categories) do
					cats[cat] = true
				end

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
					if bp.Wreckage then
						if not bp.Wreckage.LifeTime then
							bp.Wreckage.LifeTime = 900
						end
					else
						-- Add Wreckage to all Blueprints to create more wreckage in the game, goes in hand with the change in Unit.lua to overkillRatio.
						-- We comment out MassMult Adjustments for now to see how it affects gameplay.
						-- We remove Energy Reclaim from all wrecks to focus Macro more on Energy Production rather then 30 minutes of Macro for Mass Extractor Upgrades.
						-- We remove the entire section that manipulates blueprints
						-- LOG("Adding BP Wreckage")
						bp.Wreckage = {
							Blueprint = '/props/DefaultWreckage/DefaultWreckage_prop.bp',
							EnergyMult = 0,
							HealthMult = 0.9,
							LifeTime = 720, -- give naval wreckage a lifetime value of 12 minutes
							MassMult = 0.75,
							ReclaimTimeMultiplier = 1.2,
							WreckageLayers = {
								Land = true,
							},
						}

						if bp.Wreckage.MassMult and bp.Wreckage.MassMult >= 0.9 then
							bp.Wreckage.EnergyMult = 0
							bp.Wreckage.MassMult = 0.75
							bp.Wreckage.ReclaimTimeMultiplier = 1.2
						elseif bp.Wreckage.MassMult and bp.Wreckage.MassMult >= 0.1 and bp.Wreckage.MassMult < 0.75 then
							bp.Wreckage.EnergyMult = 0
							bp.Wreckage.MassMult = 0.75
							bp.Wreckage.ReclaimTimeMultiplier = 1.2
						end
					end
				end
			end
		end
	end

	--=======================================
	-- FUNCTION NOTIFICATIONALTERATIONS(ALL_BLUEPRINTS)
	-- LCE's NotificationAlterations + Misc
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
	-- LCE's NotificationAlterations
	-- Nullify categories on units we don't want to see built
	--=======================================
	function NullifyUnitBlueprints(all_blueprints)
		local unitPruningId = {
			'brnt2bm', -- Banshee
			'brnt3wt', -- WarHammer
			'dea0202', -- Janus
			'dra0202', -- Corsair
			'uel0402', -- Rampage
			'uab8765', -- Exp Storage Aeon
			'urb8765', -- Exp Storage Cybran
			'ueb8765', -- Exp Storage UEF
			'xsb8765'  -- Exp Storage Seraphim
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
end -- do end
