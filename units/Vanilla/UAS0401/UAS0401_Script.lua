local ASubUnit =  import('/lua/defaultunits.lua').SubUnit

local WeaponsFile = import('/lua/aeonweapons.lua')

local ADFCannonOblivionWeapon       = WeaponsFile.ADFCannonOblivionWeapon02
local AANChronoTorpedoWeapon        = WeaponsFile.AANChronoTorpedoWeapon
local AIFQuasarAntiTorpedoWeapon    = WeaponsFile.AIFQuasarAntiTorpedoWeapon

WeaponsFile = nil

local MissileRedirect = import('/lua/defaultantiprojectile.lua').MissileTorpDestroy

local TrashBag = TrashBag
local TrashAdd = TrashBag.Add

UAS0401 = ClassUnit(ASubUnit) {

    Weapons = {
        MainGun     = ClassWeapon(ADFCannonOblivionWeapon) {},
        Torpedo     = ClassWeapon(AANChronoTorpedoWeapon) {},
        AntiTorpedo = ClassWeapon(AIFQuasarAntiTorpedoWeapon) {},
    },

    BuildAttachBone = 'Attachpoint01',

    OnStopBeingBuilt = function(self,builder,layer)

        self:SetWeaponEnabledByLabel('MainGun', true)

        ASubUnit.OnStopBeingBuilt(self,builder,layer)

        if layer == 'Water' then
            self:RestoreBuildRestrictions()
            self:RequestRefreshUI()
        else
            self:AddBuildRestriction(categories.ALLUNITS)
            self:RequestRefreshUI()
        end

        ChangeState(self, self.IdleState)

        --Button status toggles
		self.DroneMaintenance = true
		self.DroneAssist = true

		--Assist management globals
		self.MyAttacker = nil
		self.MyTarget = nil

		--Drone construction/repair buildrate
		self.BuildRate = self:GetBlueprint().Economy.BuildRate or 30

		--Drone setup (load globals/tables & create drones)
		self:DroneSetup()

        -- create Torp Defense emitter
        local bp = __blueprints[self.BlueprintID].Defense.MissileTorpDestroy

        for _,v in bp.AttachBone do

            local antiMissile1 = MissileRedirect { Owner = self, Radius = bp.Radius, AttachBone = v, RedirectRateOfFire = bp.RedirectRateOfFire }

            TrashAdd( self.Trash, antiMissile1)

        end

    end,

    OnFailedToBuild = function(self)

        ASubUnit.OnFailedToBuild(self)

        ChangeState(self, self.IdleState)

    end,

    OnMotionVertEventChange = function( self, new, old )

        ASubUnit.OnMotionVertEventChange(self, new, old)

        if new == 'Top' then

            self:RestoreBuildRestrictions()
            self:RequestRefreshUI()

            local Gun = self:GetWeaponByLabel('MainGun')

            Gun:SetEnabled(true)

            self:PlayUnitSound('Open')
            self.DroneAssist = true

        elseif new == 'Down' then

            local Gun = self:GetWeaponByLabel('MainGun')

            Gun:SetEnabled(false)

            self:AddBuildRestriction(categories.ALLUNITS)
            self:RequestRefreshUI()
            self:PlayUnitSound('Close')
            self:RecallDrones()
            self.DroneAssist = false

        end

    end,

    IdleState = State {

        Main = function(self)

            self:DetachAll(self.BuildAttachBone)
            self:SetBusy(false)

        end,

        OnStartBuild = function(self, unitBuilding, order)

            ASubUnit.OnStartBuild(self, unitBuilding, order)

            self.UnitBeingBuilt = unitBuilding

            ChangeState(self, self.BuildingState)

        end,

    },

    BuildingState = State {

        Main = function(self)

            local unitBuilding = self.UnitBeingBuilt

            self:SetBusy(true)

            local bone = self.BuildAttachBone

            self:DetachAll(bone)

            if not self.UnitBeingBuilt.Dead then

                unitBuilding:AttachBoneTo( -2, self, bone )

                if EntityCategoryContains( categories.ENGINEER + categories.uas0102 + categories.uas0103, unitBuilding ) then

                    unitBuilding:SetParentOffset( {0,0,1} )

                elseif EntityCategoryContains( categories.TECH2 - categories.ENGINEER, unitBuilding ) then

                    unitBuilding:SetParentOffset( {0,0,3} )

                elseif EntityCategoryContains( categories.uas0203, unitBuilding ) then

                    unitBuilding:SetParentOffset( {0,0,1.5} )

                else

                    unitBuilding:SetParentOffset( {0,0,2.5} )

                end

            end

            self.UnitDoneBeingBuilt = false

        end,

        OnStopBuild = function(self, unitBeingBuilt)
            ASubUnit.OnStopBuild(self, unitBeingBuilt)
            ChangeState(self, self.FinishedBuildingState)
        end,
    },

    FinishedBuildingState = State {

        Main = function(self)

            self:SetBusy(true)

            local unitBuilding = self.UnitBeingBuilt

			if  unitBuilding:GetFractionComplete() == 1 then

				self.UnitDoneBeingBuilt = true

				unitBuilding:DetachFrom(true)

				self:DetachAll(self.BuildAttachBone)

				local worldPos = self:CalculateWorldPositionFromRelative({0, 0, -20})

				IssueMoveOffFactory({unitBuilding}, worldPos)

			end

            self:SetBusy(false)

            ChangeState(self, self.IdleState)

        end,

    },

    --Places the first drone-targetable attacker into a global
	OnDamage = function(self, instigator, amount, vector, damagetype)

		if not self.Dead
		and self.MyAttacker == nil
		and self:IsValidDroneTarget(instigator) then

			self.MyAttacker = instigator

		end

		ASubUnit.OnDamage(self, instigator, amount, vector, damagetype)

	end,

	--Drone control buttons
	OnScriptBitSet = function(self, bit)

		if bit == 1 then

			self.DroneAssist = false

		elseif bit == 7 then

			self:RecallDrones()
			self:SetScriptBit('RULEUTC_SpecialToggle', false)

		else
			ASubUnit.OnScriptBitSet(self, bit)
		end
	end,

	OnScriptBitClear = function(self, bit)

		if bit == 1 then

			self.DroneAssist = true

		elseif bit == 7 then

		else
			ASubUnit.OnScriptBitClear(self, bit)
		end
	end,

	--Handles drone docking
    OnTransportAttach = function(self, attachBone, unit)

    	self.DroneData[unit.Name].Docked = attachBone

    	unit:SetDoNotTarget(true)

        ASubUnit.OnTransportAttach(self, attachBone, unit)

    end,

    --Handles drone undocking
    OnTransportDetach = function(self, attachBone, unit)

	    self.DroneData[unit.Name].Docked = false

	    unit:SetDoNotTarget(false)

		if unit.Name == self.BuildingDrone then
			self:CleanupDroneMaintenance(self.BuildingDrone)
		end

        ASubUnit.OnTransportDetach(self, attachBone, unit)

    end,

    --Cleans up threads and drones on death
	OnKilled = function(self, instigator, type, overkillRatio)

		KillThread(self.HeartBeatThread)

		ChangeState(self, self.DeadState)

		if self.DroneTable then

			for name, drone in self.DroneTable do

				IssueClearCommands({drone})
				IssueKillSelf({drone})

			end

		end

        ASubUnit.OnKilled(self, instigator, type, overkillRatio)

	end,

	--+ Drone Setup / Creation +--

	DroneSetup = function(self)

        LOG("*AI DEBUG Tempest Drone Setup")

		self.DroneTable = {}

		self.BuildingDrone = false

        local AI = self:GetBlueprint().AI

		self.ControlRange       = AI.DroneControlRange or 70
		self.ReturnRange        = AI.DroneReturnRange or (ControlRange / 2)
		self.AssistRange        = self.ControlRange + 10
		self.AirMonitorRange    = AI.AirMonitorRange or (self.AssistRange / 2)
		self.HeartBeatInterval  = AI.AssistHeartbeatInterval or 1

		self.DroneData = table.deepcopy(self:GetBlueprint().DroneData)

		for droneName, droneData in self.DroneData do

			if not droneData.Name then
				droneData.Name = droneName
			end

			droneData.Blueprint = table.deepcopy(GetUnitBlueprintByName(droneData.UnitID))
			droneData.Economy = droneData.Blueprint.Economy
			droneData.BuildProgress = 1

			self:ForkThread(self.CreateDrone, droneName)

		end

		self.HeartBeatThread = self:ForkThread(self.AssistHeartBeat)

		ChangeState(self, self.DroneMaintenanceState)

	end,

	CreateDrone = function(self, droneName)

		if not self.Dead and not self.DroneTable[droneName] and not self.DroneData[droneName].Active then

			if not self:IsValidBone(self.DroneData[droneName].Attachpoint) then
				error("*ERROR: Attachpoint '" .. self.DroneData[droneName].Attachpoint .. "' not a valid bone!", 2)
				return
			end

			local location = self:GetPosition(self.DroneData[droneName].Attachpoint)
			local newdrone = CreateUnitHPR(self.DroneData[droneName].UnitID, self:GetArmy(), location[1], location[2], location[3], 0, 0, 0)

			newdrone:SetParent(self, self.DroneData[droneName].Name)
			newdrone:SetCreator(self)
			self.DroneTable[droneName] = newdrone
			self.DroneData[droneName].Active = newdrone
			self.DroneData[droneName].Docked = false
			self.DroneData[droneName].Damaged = false
			self.DroneData[droneName].BuildProgress = 1

			self.Trash:Add(newdrone)

			self:RequestRefreshUI()

		end

	end,

	NotifyOfDroneDeath = function(self,droneName)

		self.DroneTable[droneName] = nil
		self.DroneData[droneName].Active = false
		self.DroneData[droneName].Docked = false
		self.DroneData[droneName].Damaged = false
		self.DroneData[droneName].BuildProgress = 0

	end,

	DroneMaintenanceState = State {

		Main = function(self)

			self.DroneMaintenance = true

			if self.BuildingDrone then
				ChangeState(self, self.DroneRebuildingState)
			end

			while self and not self.Dead and not self.BuildingDrone do

				for droneName, droneData in self.DroneData do

					if not droneData.Active or (droneData.Active and droneData.Damaged and droneData.Docked) then

						self.BuildingDrone = droneName
						ChangeState(self, self.DroneRebuildingState)

					end

				end

				WaitTicks(2)

			end

		end,

		OnPaused = function(self)
			ChangeState(self, self.PausedState)
		end,
	},



	DroneRebuildingState = State {

		Main = function(self)

			local isRepair = self.DroneData[self.BuildingDrone].Active and self.DroneData[self.BuildingDrone].Damaged
			local buildTimeSeconds = self.DroneData[self.BuildingDrone].Economy.BuildTime / self.BuildRate

			self:EnableResourceConsumption(self.DroneData[self.BuildingDrone].Economy)

			if not isRepair then

				self:CreateDroneEffects(self.DroneData[self.BuildingDrone].Attachpoint)

				if not self.DroneData[self.BuildingDrone].BuildProgress then
					self:SetWorkProgress(0.01)
				end

				while self and not self.Dead and self.DroneData[self.BuildingDrone].BuildProgress < 1 do

					WaitTicks(1)

					local tickprogress = (self:GetResourceConsumed() * 0.1) / buildTimeSeconds

					self.DroneData[self.BuildingDrone].BuildProgress = self.DroneData[self.BuildingDrone].BuildProgress + tickprogress
					self:SetWorkProgress(self.DroneData[self.BuildingDrone].BuildProgress)

				end

				self:CreateDrone(self.BuildingDrone)

			elseif isRepair then

				self:CreateDroneEffects(self.DroneData[self.BuildingDrone].Docked)

				local repairingDrone = self.DroneData[self.BuildingDrone].Active
				local maxhealth = repairingDrone:GetMaxHealth()

				while self and not self.Dead and self.DroneData[self.BuildingDrone].Damaged
				and self.DroneData[self.BuildingDrone].Docked
				and repairingDrone and not repairingDrone.Dead do

					WaitTicks(1)

					local restorehealth = ((self:GetResourceConsumed() * 0.1) / buildTimeSeconds) * maxhealth

					repairingDrone:AdjustHealth(self, restorehealth)
					local totalprogress = repairingDrone:GetHealth() / maxhealth

					self:SetWorkProgress(totalprogress)

					if totalprogress >= 1 then
						self.DroneData[self.BuildingDrone].Damaged = false
					end

				end

			end

			self:CleanupDroneMaintenance(self.BuildingDrone)

			ChangeState(self, self.DroneMaintenanceState)

		end,

		OnPaused = function(self)
			ChangeState(self, self.PausedState)
		end,
	},

	PausedState = State {

		Main = function(self)
			self:CleanupDroneEffects()
			self:DisableResourceConsumption()
			self.DroneMaintenance = false
		end,

		OnUnpaused = function(self)
			ChangeState(self, self.DroneMaintenanceState)
		end,
	},

	DeadState = State {
		Main = function(self)
			self:CleanupDroneMaintenance(nil, true)
		end,
	},

	EnableResourceConsumption = function(self, econdata)

		local energy_rate = econdata.BuildCostEnergy / (econdata.BuildTime / self.BuildRate)
		local mass_rate = econdata.BuildCostMass / (econdata.BuildTime / self.BuildRate)

		self:SetConsumptionPerSecondEnergy(energy_rate)
		self:SetConsumptionPerSecondMass(mass_rate)
		self:SetConsumptionActive(true)

	end,

	DisableResourceConsumption = function(self)

		self:SetConsumptionPerSecondEnergy(0)
		self:SetConsumptionPerSecondMass(0)
		self:SetConsumptionActive(false)

	end,

	CleanupDroneMaintenance = function(self, droneName, deadState)

		if deadState or (droneName and droneName == self.BuildingDrone) then

			self:SetWorkProgress(0)
			self.BuildingDrone = false
			self:CleanupDroneEffects()
			self:DisableResourceConsumption()

		end

	end,

    CreateDroneEffects = function(self, bone)
    end,

	CleanupDroneEffects = function(self)
	end,


	--+ Drone Assist Management

	AssistHeartBeat = function(self)

		local SuspendAssist = 0
		local LastFireState
		local LastDroneTarget

		local TargetWeapon = self:GetWeaponByLabel('MainGun')

		while not self.Dead do

			local MyFireState = self:GetFireState()
			local HoldFire = MyFireState == 1

			local TargetBlip = TargetWeapon:GetCurrentTarget()

			if TargetBlip != nil then
				self.MyTarget = self:GetRealTarget(TargetBlip)
			else
				self.MyTarget = nil
			end

			if LastFireState != MyFireState then
				LastFireState = MyFireState
				self:SetDroneFirestate(MyFireState)
			end

			if self.DroneAssist and not HoldFire and SuspendAssist <= 0 then

				local NewDroneTarget
				local GunshipTarget = self:SearchForGunshipTarget(self.AirMonitorRange)

				if GunshipTarget and not GunshipTarget.Dead then
					if GunshipTarget != LastDroneTarget then
						NewDroneTarget = GunshipTarget
					end
				elseif self.MyTarget != nil and not self.MyTarget.Dead then
					if self.MyTarget != LastDroneTarget then
						NewDroneTarget = self.MyTarget
					end
				elseif self.MyAttacker != nil and not self.MyAttacker.Dead and self:IsTargetInRange(self.MyAttacker) then
					if self.MyAttacker != LastDroneTarget then
						NewDroneTarget = self.MyAttacker
					end
				elseif self.MyAttacker != nil then
					self.MyAttacker = nil
				end

				if NewDroneTarget and self:IsValidDroneTarget(NewDroneTarget) then
					if NewDroneTarget == GunshipTarget then
						SuspendAssist = 7
					end
					LastDroneTarget = NewDroneTarget
					self:AssignDroneTarget(NewDroneTarget)
				else
					if LastDroneTarget and self:IsValidDroneTarget(LastDroneTarget)
					and self:IsTargetInRange(LastDroneTarget) then
						if self:GetDronesDocked() then
							self:AssignDroneTarget(LastDroneTarget)
						end
					else
						LastDroneTarget = nil
					end
				end

			elseif SuspendAssist > 0 then
				SuspendAssist = SuspendAssist - 1
			end

			WaitSeconds(self.HeartBeatInterval)

		end

	end,

	RecallDrones = function(self)
		if next(self.DroneTable) then
			for id, drone in self.DroneTable do
				drone:DroneRecall()
			end
		end
	end,

	AssignDroneTarget = function(self, dronetarget)
		if next(self.DroneTable) then
			for id, drone in self.DroneTable do
				if drone.AwayFromCarrier == false then
					local targetblip = dronetarget:GetBlip(self:GetArmy())
					if targetblip != nil then
						IssueClearCommands({drone})
						IssueAttack({drone}, targetblip)
					end
				end
			end
		end
	end,

	SetDroneFirestate = function(self, firestate)
		if next(self.DroneTable) then
			for id, drone in self.DroneTable do
				if drone and not drone.Dead then
					drone:SetFireState(firestate)
				end
			end
		end
	end,

	GetDronesDocked = function(self)
		local docked = {}
		if next(self.DroneTable) then
			for id, drone in self.DroneTable do
				if drone and not drone.Dead and self.DroneData[id].Docked then
					table.insert(docked, id)
				end
			end
		end
		if next(docked) then
			return docked
		else
			return false
		end
	end,

	SearchForGunshipTarget = function(self, radius)
		local targetindex, target
		local units = self:GetAIBrain():GetUnitsAroundPoint(categories.AIR - (categories.HIGHALTAIR + categories.UNTARGETABLE), self:GetPosition(), radius, 'Enemy')
		if next(units) then
			targetindex, target = next(units)
		end
		return target
	end,

	GetRealTarget = function(self, target)
		if target and not IsUnit(target) then
			local unitTarget = target:GetSource()
			local unitPos = unitTarget:GetPosition()
			local reconPos = target:GetPosition()
			local dist = VDist2(unitPos[1], unitPos[3], reconPos[1], reconPos[3])
			if dist < 5 then
				return unitTarget
			end
		end
		return target
	end,

	IsValidDroneTarget = function(self, target)
		local ivdt
		if target != nil
		and target.Dead != nil
		and not target.Dead
		and IsEnemy(self:GetArmy(), target:GetArmy())
		and not EntityCategoryContains(categories.HIGHALTAIR + categories.UNTARGETABLE, target)
		and target:GetCurrentLayer() != 'Sub'
		and target:GetBlip(self:GetArmy()) != nil then
			ivdt = true
		end
		return ivdt
	end,

	IsTargetInRange = function(self, target)
		local tpos = target:GetPosition()
		local mpos = self:GetPosition()
		local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
		local itir
		if dist <= self.AssistRange then
			itir = true
		end
		return itir
	end,
}

TypeClass = UAS0401