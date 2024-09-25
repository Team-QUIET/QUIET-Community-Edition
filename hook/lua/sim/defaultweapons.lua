-- WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] * QUIET Hook for DW.lua' ) 
-- This warning allows us to see exactly where our Hook Line starts so we can debug the exact line thats causing an error easier


-- This hook fixes the math that caused many units with a charge to have extra seconds.
-- The reason why we have so many states pulled into here is removing variables such as...
-- WeaponCharged, Firstshot, EconDrain = Nil, Forking EconomyDrainThread, and more
-- Everything is now located in the actual EconomyDrainThread
DefaultWeapons_QUIET = DefaultProjectileWeapon
DefaultProjectileWeapon = Class(DefaultWeapons_QUIET) {

    OnCreate = function(self)
	
        WeaponOnCreate(self)

        self.HadTarget = false
        self.WeaponCanFire = true
        self.WeaponIsEnabled = false

        self.CurrentRackNumber = 1
        
        local bp = self.bp
		
        if bp.RackRecoilDistance and bp.RackRecoilDistance != 0 then
		
			if bp.MuzzleSalvoDelay != 0 then
				local strg = '*ERROR: You can not have a RackRecoilDistance with a MuzzleSalvoDelay not equal to 0, aborting weapon setup.  Weapon: ' .. bp.DisplayName .. ' on Unit: ' .. self.unit.BlueprintID
				error(strg, 2)
				return false
			end
		
            self.RecoilManipulators = {}
			
            local dist = bp.RackRecoilDistance or 1
			
            if bp.RackBones[1].TelescopeRecoilDistance then
			
                local tpDist = bp.RackBones[1].TelescopeRecoilDistance or 0

                if LOUDABS(tpDist) > LOUDABS(dist) then
				
                    dist = tpDist
                end
            end
			
            self.RackRecoilReturnSpeed = bp.RackRecoilReturnSpeed or LOUDABS( dist / (( 1 / bp.RateOfFire ) - (bp.MuzzleChargeDelay or 0))) * 1.25
        end

        if bp.EnergyChargeForFirstShot == false then
            self.FirstShot = true
        end
		
        if bp.RenderFireClock then
            self.unit:SetWorkProgress(1)
        end
		
        if bp.FixBombTrajectory then
        
            if bp.ProjectilesPerOnFire then
                self.CBFP_CalcBallAcc = { Do = true, ProjectilesPerOnFire = bp.ProjectilesPerOnFire }
            else
                self.CBFP_CalcBallAcc = { Do = true, ProjectilesPerOnFire = 1 }
            end
        end

        if not bp.EnabledByEnhancement then

            self:SetWeaponEnabled(true)
            
            ChangeState( self, self.IdleState)
            
        end

	end,

    StartEconomyDrain = function(self)
        if self.FirstShot then return end
        if self.unit:GetFractionComplete() ~= 1 then return end

        local bp = self.bp

        if not self.EconDrain and bp.EnergyRequired and bp.EnergyDrainPerSecond then

            local nrgReq = self:GetWeaponEnergyRequired(bp)
            local nrgDrain = self:GetWeaponEnergyDrain(bp)

            if nrgReq > 0 and nrgDrain > 0 then
                local time = nrgReq / nrgDrain
                if time < 0.1 then
                    time = 0.1
                end
                self.EconDrain = CreateEconomyEvent(self.unit, nrgReq, 0, time)
                self.FirstShot = true
                ForkThread(self.EconomyDrainThread, self)
            end
        end
    end,

    ---@param self DefaultProjectileWeapon
    EconomyDrainThread = function(self)
        WaitFor(self.EconDrain)
        RemoveEconomyEvent(self.unit, self.EconDrain)
        self.EconDrain = nil
    end,

    -- Determine how much Energy is required to fire
    ---@param self DefaultProjectileWeapon
    ---@return integer
    GetWeaponEnergyRequired = function(self, bp)
        local weapNRG = (self.bp.EnergyRequired or 0) * (self.AdjEnergyMod or 1)
        if weapNRG < 0 then
            weapNRG = 0
        end
        return weapNRG
    end,

    -- Determine how much Energy should be drained per second
    ---@param self DefaultProjectileWeapon
    ---@return integer
    GetWeaponEnergyDrain = function(self, bp)
        local weapNRG = (self.bp.EnergyDrainPerSecond or 0) * (self.AdjEnergyMod or 1)
        return weapNRG
    end,

    -- WEAPON STATES:
    
    -- Removed EconDrain = Nil as it's now part of the main EconomyDrainThread Function
    -- Removed RemoveEconomyEvent as it's now part of the main EconomyDrainThread Function
    IdleState = State {
	
		WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        Main = function(self)
         
            local bp = self.bp
            local unit = self.unit

            if unit.Dead then return end
            
            if ScenarioInfo.WeaponStateDialog then
                LOG("*AI DEBUG DefaultWeapon Idle State "..repr(bp.Label).." at "..GetGameTick() )
            end

            SetBusy( unit, false )

            if self.RecoilManipulators then
                self:WaitForAndDestroyManips()
            end

			if not self.EconDrain then
                self:ForkThread( self.StartEconomyDrain )
			end
   	     
            if self.EconDrain then

                WaitFor(self.EconDrain)    

                if ScenarioInfo.WeaponStateDialog then
                    LOG("*AI DEBUG DefaultWeapon Idle State "..repr(self.bp.Label).." Economy Event Ends" )
                end

            end
            
            if bp.RackBones then
			
                for _, v in bp.RackBones do
			
                    if v.HideMuzzle == true then
				
                        for _, mv in v.MuzzleBones do
                            unit:ShowBone( mv, true )
                        end
                    end
                end
            
                -- NOTE: This is setup so that it only works if there is more than 1 rack to be fired
                -- but the rack wasn't reset (weapon didn't fire all the rackbones)
                -- we force the reload rack process
                -- this seems to happen when a multi-rackboned unit loses it's target during the fire sequence
                if LOUDGETN(bp.RackBones) > 1 and self.CurrentRackNumber > 1 then

                    self.CurrentRackNumber = 1 

                    LOUDSTATE(self, self.RackSalvoReloadState)

                end
                
            end
			
            if bp.CountedProjectile == true and bp.MaxProjectileStorage > 0 and not self.bp.NukeWeapon then
            
                if unit:GetTacticalSiloAmmoCount() <= 0 then
                    LOUDSTATE(self, self.WeaponEmptyState)
                end
            end
        end,

        OnGotTarget = function(self)
            
            local bp = self.bp
            local unit = self.unit

            if ScenarioInfo.WeaponStateDialog then
                LOG("*AI DEBUG DefaultWeapon Idle State OnGotTarget "..repr(bp.Label).." Target is "..repr(self:GetCurrentTargetPos()).." at "..GetGameTick() )
            end
	
            if (bp.WeaponUnpackLocksMotion != true or (bp.WeaponUnpackLocksMotion == true and not unit:IsUnitState('Moving'))) then

                if bp.CountedProjectile and bp.MaxProjectileStorage > 0 then

                    if not self:CanWeaponFire(bp,unit) then
				
                        unit.HasTMLTarget = true
                        return
                    else
                        unit.HasTMLTarget = true
                    end
                    
                end
				
                if bp.WeaponUnpacks == true then
				
                    LOUDSTATE(self, self.WeaponUnpackingState)
					
                else

                    LOUDSTATE(self, self.RackSalvoChargeState)
					
                end
				
            end
			
        end,

        OnFire = function(self)
            
            local bp = self.bp

            if ScenarioInfo.WeaponStateDialog then
                LOG("*AI DEBUG DefaultWeapon Idle State OnFire "..repr(bp.Label).." at "..GetGameTick() )
            end
			
            if bp.WeaponUnpacks == true then
			
                LOUDSTATE(self, self.WeaponUnpackingState)
				
            else

                LOUDSTATE(self, self.RackSalvoChargeState)

            end
			
        end,
    },

    RackSalvoChargeState = State {

        WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        Main = function(self)

            local bp = self.bp
            local unit = self.unit
            local RackSalvoChargeTime = bp.RackSalvoChargeTime or false
  
            if ScenarioInfo.WeaponStateDialog then
                LOG("*AI DEBUG DefaultWeapon RackSalvo Charge State "..repr(bp.Label).." at "..GetGameTick() )
			end
          
            self.ElapsedRackChargeTime = 0
			
            if self.EconDrain then
            
                self.ElapsedRackChargeTime = GetGameTick()

                WaitFor(self.EconDrain)
                
                self.ElapsedRackChargeTime = GetGameTick() - self.ElapsedRackChargeTime

                if ScenarioInfo.WeaponStateDialog then
                    LOG("*AI DEBUG DefaultWeapon RackSalvo Charge State "..repr(bp.Label).." Economy Event Ends after "..self.ElapsedRackChargeTime.." ticks at "..GetGameTick() )
                end

            end

            self:PlayFxRackSalvoChargeSequence(bp)

            if RackSalvoChargeTime and (LOUDFLOOR(RackSalvoChargeTime*10) - self.ElapsedRackChargeTime) >= 1 then
            
                if ScenarioInfo.WeaponStateDialog then
                    LOG("*AI DEBUG DefaultWeapon RackSalvo Charge for "..repr(bp.Label).." waiting "..LOUDFLOOR(RackSalvoChargeTime*10) - self.ElapsedRackChargeTime.." ticks at "..GetGameTick() )
                end
            
                WaitTicks( LOUDFLOOR(RackSalvoChargeTime*10) - self.ElapsedRackChargeTime ) 
            end

            LOUDSTATE(self, self.RackSalvoFireReadyState)

        end,
--[[
        OnFire = function(self)

            if ScenarioInfo.WeaponStateDialog then
                LOG("*AI DEBUG DefaultWeapon RackSalvo Charge State "..repr(self.bp.Label).." OnFire at "..GetGameTick() )
            end
            
            LOUDSTATE(self, self.RackSalvoFireReadyState)
        end,
--]]        
        OnGotTarget = function(self)

            if ScenarioInfo.WeaponStateDialog then
                LOG("*AI DEBUG DefaultWeapon RackSalvo Charge State "..repr(self.bp.Label).." OnGotTarget at "..GetGameTick() )		
            end
          
        end,
    },

    RackSalvoFireReadyState = State {

        WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        Main = function(self)
            
            local bp = self.bp
            local unit = self.unit
            
            if ScenarioInfo.WeaponStateDialog then
                LOG("*AI DEBUG DefaultWeapon RackSalvo Fire Ready State "..repr(bp.Label).." at "..GetGameTick() )
            end

            self.WeaponCanFire = false
			
            if self.EconDrain then

                WaitFor(self.EconDrain)

                if ScenarioInfo.WeaponStateDialog then
                    LOG("*AI DEBUG DefaultWeapon RackSalvo Fire Ready State "..repr(self.bp.Label).." Economy Event Ends at "..GetGameTick() )
                end

            end
			
            self.WeaponCanFire = true

            --We change the state on counted projectiles because we won't get another OnFire call.
            --The second part is a hack for units with reload animations.  They have the same problem
            --they need a RackSalvoReloadTime that's 1/RateOfFire set to avoid firing twice on the first shot
            if (bp.CountedProjectile and bp.MaxProjectileStorage > 0) or bp.AnimationReload then
            
                while unit:GetFireState() == 1 do
                    WaitTicks(1)
                end
                
                LOUDSTATE(self, self.RackSalvoFiringState)
            end

        end,

		-- while debugging the WeaponUnpackLocksMotion I discovered that if you have the value NeedsUnpack = true in the AI section
		-- then the weapon will Never do an OnFire() event unless the unit is set to IMMOBILE
        OnFire = function(self)

            if ScenarioInfo.WeaponStateDialog then
                LOG("*AI DEBUG DefaultWeapon RackSalvo Fire Ready State "..repr(self.bp.Label).." OnFire at "..GetGameTick() )
            end

            if self.WeaponCanFire and WeaponHasTarget(self) then
                LOUDSTATE(self, self.RackSalvoFiringState)
            end
			
        end,
        
        OnGotTarget = function(self)

            if ScenarioInfo.WeaponStateDialog then
                LOG("*AI DEBUG DefaultWeapon RackSalvo Fire Ready State "..repr(self.bp.Label).." OnGotTarget at "..GetGameTick() )		
            end
          
        end,

    },

    RackSalvoFiringState = State {
	
        WeaponWantEnabled       = true,
        WeaponAimWantEnabled    = true,

        Main = function(self)
            
            local bp                    = self.bp
            
            local Audio                 = bp.Audio
            local Buffs                 = bp.Buffs
            local CountedProjectile     = bp.CountedProjectile or false
            local MuzzleChargeDelay     = bp.MuzzleChargeDelay or false
            local MuzzleSalvoDelay      = bp.MuzzleSalvoDelay
            local MuzzleSalvoSize       = bp.MuzzleSalvoSize
            local NotExclusive          = bp.NotExclusive
            local RackBones             = bp.RackBones or {}
            local unit                  = self.unit
            
            local WeaponStateDialog     = ScenarioInfo.WeaponStateDialog
            
            if WeaponStateDialog then
                LOG("*AI DEBUG DefaultWeapon RackSalvo Firing State for "..repr(bp.Label).." at "..GetGameTick() )
			end
            
            -- ok -- with multiple weaponed units - this is the command that halts other weapons from firing
            -- when Exclusive, all other weapons will 'pause' until this function completes
            if NotExclusive then
                SetBusy( unit, false )
            end
            
			if self.RecoilManipulators then
				self:DestroyRecoilManips()
			end
			
            local numRackFiring = self.CurrentRackNumber
		
			local TotalRacksOnWeapon = LOUDGETN(RackBones) or 1
			
            if bp.RackFireTogether == true then
                numRackFiring = TotalRacksOnWeapon
            end	
			
            -- this used to be placed AFTER the firing events 
            if bp.RenderFireClock and bp.RateOfFire > 0 then
			
	            if not unit.Dead then
				
                    local rof = 1 / bp.RateOfFire                

                    self:ForkThread(self.RenderClockThread, rof)                
                end
            end

            self:OnWeaponFired(bp)
            
            local CurrentRackInfo, MuzzlesToBeFired, NumMuzzlesFiring, muzzleIndex, muzzle, projectilefired

            local HideBone          = HideBone
            local LOUDGETN          = LOUDGETN
            local PlaySound         = PlaySound
            local ShowBone          = ShowBone
            local WaitSeconds       = WaitSeconds

            -- Most of the time this will only run once per rack, the only time it doesn't is when racks fire together.
            while self.CurrentRackNumber <= numRackFiring and not self.HaltFireOrdered and not unit.Dead do
 			
                CurrentRackInfo = RackBones[self.CurrentRackNumber] or {}

                if CurrentRackInfo.MuzzleBones then
                    MuzzlesToBeFired = LOUDGETN( CurrentRackInfo.MuzzleBones )
                else
                    MuzzlesToBeFired = 1
                end

                NumMuzzlesFiring = MuzzleSalvoSize or 1

                -- this is a highly questionable statement since it always overrides the MuzzleSalvoSize
                -- IF the number of muzzles is different and the MuzzleSalvoDelay is zero
                if MuzzleSalvoDelay == 0 then
                    NumMuzzlesFiring = MuzzlesToBeFired
                end

                muzzleIndex = 1

				-- fire all the muzzles --
                for i = 1, NumMuzzlesFiring do

                    if not self.HaltFireOrdered and (not self:GetCurrentTarget() and bp.CannotAttackGround) then

                        if WeaponStateDialog then
                            LOG("*AI DEBUG Weapon "..repr(bp.Label).." on "..repr(unit.BlueprintID).." has no target to shoot at")
                        end

                        self:OnLostTarget()

                        HaltFireOrdered = true
                    end

                    if self.HaltFireOrdered then
                        continue
                    end

                    if CountedProjectile == true and bp.MaxProjectileStorage > 0 then
					
                        if bp.NukeWeapon == true then
                            if unit:GetNukeSiloAmmoCount() <= 0 then
                                self.WeaponCanFire = false
                                continue
                            end
                        else
                            if unit:GetTacticalSiloAmmoCount() <= 0 then
                                self.WeaponCanFire = false
                                continue
                            end
                        end
                    end

                    self:StartEconomyDrain() -- the recharge begins as soon as the weapon starts firing
					
                    muzzle = CurrentRackInfo.MuzzleBones[muzzleIndex]
            
                    if WeaponStateDialog then
                        LOG("*AI DEBUG DefaultWeapon RackSalvo Firing State "..repr(bp.Label).." - preps rack "..self.CurrentRackNumber.." "..repr(CurrentRackInfo.RackBone).." at "..GetGameTick() )
                    end
 					
                    if CurrentRackInfo.HideMuzzle == true then
                        ShowBone( unit, muzzle, true)
                    end
					
                    -------------------
					-- muzzle charge --
                    -------------------
                    if MuzzleChargeDelay and MuzzleChargeDelay > 0 then
					
                        if Audio.MuzzleChargeStart then
                            PlaySound( self, Audio.MuzzleChargeStart)
                        end
						
                        self:PlayFxMuzzleChargeSequence(muzzle)
            
                        if WeaponStateDialog then

                            if self.EconDrain then
                                LOG("*AI DEBUG DefaultWeapon RackSalvo Firing State "..repr(bp.Label).." Muzzle Charge Delay "..LOUDFLOOR(MuzzleChargeDelay * 10).." ticks (not firing cycle) at "..GetGameTick() )
                            else
                                LOG("*AI DEBUG DefaultWeapon RackSalvo Firing State "..repr(bp.Label).." Muzzle Charge Delay waiting "..LOUDFLOOR(MuzzleChargeDelay * 10).." ticks at "..GetGameTick() )
                            end

                        end
						
                        WaitSeconds( MuzzleChargeDelay )

                    end

                    ------------------
					-- muzzle fires --
                    ------------------					
            
                    if WeaponStateDialog then
                        LOG("*AI DEBUG DefaultWeapon RackSalvo Firing State "..repr(bp.Label).." - FIRES rack "..self.CurrentRackNumber.." muzzle "..i.." at "..GetGameTick() )
                    end

                    self:PlayFxMuzzleSequence(muzzle)                    
					
                    if CurrentRackInfo.HideMuzzle == true then
                        HideBone( unit, muzzle, true)
                    end

                    projectilefired = self:CreateProjectileAtMuzzle(muzzle)
                    
                    if ScenarioInfo.ProjectileDialog and projectilefired then
                        LOG("*AI DEBUG DefaultWeapon RackSalvo Firing State "..repr(bp.Label).." - FIRED rack "..self.CurrentRackNumber.." projectile is "..repr(projectilefired.BlueprintID).." at "..GetGameTick() )
                    end

                    if CountedProjectile and bp.MaxProjectileStorage > 0 then
					
                        if bp.NukeWeapon == true then
						
                            unit:NukeCreatedAtUnit()
                            unit:RemoveNukeSiloAmmo(1)
                        else
                            unit:RemoveTacticalSiloAmmo(1)
                        end

                    end
					
                    muzzleIndex = muzzleIndex + 1

					-- reset the muzzle index if fired all muzzles
                    if muzzleIndex > MuzzlesToBeFired then
                        muzzleIndex = 1
                    end

                    -------------------
					-- muzzle salvo  --
                    -------------------
                    if MuzzleSalvoDelay > 0 then
            
                        if WeaponStateDialog then

                            if self.EconDrain then
                                LOG("*AI DEBUG DefaultWeapon RackSalvo Firing State "..repr(bp.Label).." Muzzle Salvo Delay "..LOUDFLOOR(MuzzleSalvoDelay * 10).." ticks (not firing cycle) at "..GetGameTick() )
                            else
                                LOG("*AI DEBUG DefaultWeapon RackSalvo Firing State "..repr(bp.Label).." Muzzle Salvo Delay waiting "..LOUDFLOOR(MuzzleSalvoDelay * 10).." ticks at "..GetGameTick() )
                            end
                        end
						
                        WaitSeconds( MuzzleSalvoDelay )
                    end
                    
                end
                
                if bp.CameraShakeRadius or bp.ShipRock or bp.RackRecoilDistance != 0 then
                    self:PlayFxRackReloadSequence(bp)
                end
			
				-- advance the rack number --
                if self.CurrentRackNumber <= TotalRacksOnWeapon then
                    self.CurrentRackNumber = self.CurrentRackNumber + 1
                end

            end

			if Buffs then
				self:DoOnFireBuffs(Buffs)
			end

            self.HaltFireOrdered = false

			-- if all the racks have fired --
            if (self.CurrentRackNumber > TotalRacksOnWeapon) or CountedProjectile then
			
				-- reset the rack count
                self.CurrentRackNumber = 1

                -- this takes precedence - delay for reloading the rack
                if bp.RackSalvoReloadTime > 0 or bp.AnimationReload or self.EconDrain or CountedProjectile then
				
                    LOUDSTATE(self, self.RackSalvoReloadState)

                -- anything else is just ready to fire again --
                else
				
                    LOUDSTATE(self, self.RackSalvoChargeState)
					
                end

            else

                LOUDSTATE(self, self.RackSalvoChargeState)

            end
            
        end,
		
		OnFire = function(self)

		end,


        -- Set a bool so we won't fire if the target reticle is moved
        OnHaltFire = function(self)
            
            if ScenarioInfo.WeaponStateDialog then
                LOG("*AI DEBUG DefaultWeapon RackSalvo Firing State OnHaltFire "..repr(self.bp.Label) )
			end
            
            self.HaltFireOrdered = true
        end,
		
        RenderClockThread = function(self, rof)
		
            local clockTime = rof
            local unit = self.unit
			local WaitTicks = WaitTicks
			
            while clockTime > 0.0 and not self:BeenDestroyed() and not unit.Dead do
                
                clockTime = clockTime - 0.1
                
                WaitTicks(1)                

                unit:SetWorkProgress( 1 - clockTime / rof )

            end
        end,
    },

}

BareBonesWeapon_QUIET = BareBonesWeapon
BareBonesWeapon = Class(BareBonesWeapon_QUIET) {
    
    RackSalvoFireReadyState = State {

        WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        Main = function(self)
            
            local bp = self.bp
            local unit = self.unit
            
            if ScenarioInfo.WeaponStateDialog then
                LOG("*AI DEBUG BareBonesWeapon RackSalvo Fire Ready State "..repr(bp.Label).." at "..GetGameTick() )
            end

            self.WeaponCanFire = false
			
            if self.EconDrain then

                WaitFor(self.EconDrain)

                if ScenarioInfo.WeaponStateDialog then
                    LOG("*AI DEBUG BareBonesWeapon RackSalvo Fire Ready State "..repr(self.bp.Label).." Economy Event Ends at "..GetGameTick() )
                end

            end
			
            self.WeaponCanFire = true

            LOUDSTATE(self, self.RackSalvoFiringState)

        end,

    },

    OnFire = function(self)

        if ScenarioInfo.WeaponStateDialog then
            LOG("*AI DEBUG BareBonesWeapon RackSalvo Fire Ready State "..repr(self.bp.Label).." OnFire at "..GetGameTick() )
        end

        local myProjectile = CreateProjectile( self.unit, projectilebp, 0, 0, 0, nil, nil, nil):SetCollision(false)
        
        if self.Data then
            myProjectile:PassData(self.Data)
        end
    end,

}