-- WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] * QUIET Hook for DW.lua' ) 
-- This warning allows us to see exactly where our Hook Line starts so we can debug the exact line thats causing an error easier


-- This hook fixes the math that caused many units with a charge to have extra seconds.
-- The reason why we have so many states pulled into here is removing variables such as...
-- WeaponCharged, Firstshot, EconDrain = Nil, Forking EconomyDrainThread, and more
-- Everything is now located in the actual EconomyDrainThread
-- This goes through and adds variables back that are documented in the FA Blueprint Wiki
-- Current ones are: RackSalvoFiresAfterCharge
-- Current Modified are: RenderFireClock, FirstShot, EconDrain

-- Many of these stats are written to not be full of bloat from the EnergyDrain & include some fixes for outlying issues.
DefaultWeapons_QUIET = DefaultProjectileWeapon
DefaultProjectileWeapon = Class(DefaultWeapons_QUIET) {

    FxRackChargeMuzzleFlash = {},
    FxRackChargeMuzzleFlashScale = 1,
    FxChargeMuzzleFlash = {},
    FxChargeMuzzleFlashScale = 1,
    FxMuzzleFlash = {
        '/effects/emitters/default_muzzle_flash_01_emit.bp',
        '/effects/emitters/default_muzzle_flash_02_emit.bp',
    },
    FxMuzzleFlashScale = 1,

    WeaponPackState = 'Packed',

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
            
            LOUDSTATE( self, self.IdleState)
            
        end

	end,

    -- modded this so only retrieve bp if old or new is 'stopped'
    OnMotionHorzEventChange = function(self, new, old)
        Weapon.OnMotionHorzEventChange(self, new, old)

        local bp = self.bp

        -- Handle weapons which must pack before moving
        if bp.WeaponUnpackLocksMotion == true and old == 'Stopped' and self.WeaponPackState ~= 'Packed' then
            self:PackAndMove()
        end

        -- Handle motion-triggered FiringRandomness changes
        if bp.FiringRandomnessWhileMoving then
            if old == 'Stopped' then
                self:SetFiringRandomness(bp.FiringRandomnessWhileMoving)
            elseif new == 'Stopped' then
                self:SetFiringRandomness(bp.FiringRandomness)
            end
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

    -- Played when a muzzle is fired. Mostly used for muzzle flashes
    PlayFxMuzzleSequence = function(self, muzzle)
        if type(self.FxMuzzleFlash) ~= "table" then
            WARN(self.unit:GetUnitId() .. " FxMuzzleFlash is not a table, it's a " .. type(self.FxMuzzleFlash))
            return
        end
        local unit = self.unit
        local army = self.Army
        local scale = self.FxMuzzleFlashScale
        for _, effect in self.FxMuzzleFlash do
            CreateAttachedEmitter(unit, muzzle, army, effect):ScaleEmitter(scale)
        end
    end,

    -- Played during the beginning of the MuzzleChargeDelay time when a muzzle in a rack is fired.
    PlayFxMuzzleChargeSequence = function(self, muzzle)
        if type(self.FxChargeMuzzleFlash) ~= "table" then
            WARN(self.unit:GetUnitId() .. " FxChargeMuzzleFlash is not a table, it's a " .. type(self.FxChargeMuzzleFlash))
            return
        end
        local unit = self.unit
        local army = self.Army
        local scale = self.FxChargeMuzzleFlashScale
        for _, effect in self.FxChargeMuzzleFlash do
            CreateAttachedEmitter(unit, muzzle, army, effect):ScaleEmitter(scale)
        end
    end,

    -- Played when a rack salvo charges
    -- Do not wait in here or the sequence in the blueprint will be messed up. Fork a thread instead
    PlayFxRackSalvoChargeSequence = function(self, blueprint)
        if type(self.FxRackChargeMuzzleFlash) ~= "table" then
            WARN(self.unit:GetUnitId() .. " FxRackChargeMuzzleFlash is not a table, it's a " .. type(self.FxRackChargeMuzzleFlash))
            return
        end
        local bp = blueprint or self.bp
        local muzzleBones = bp.RackBones[self.CurrentRackNumber].MuzzleBones
        local unit = self.unit
        local army = self.Army
        local scale = self.FxRackChargeMuzzleFlashScale
        --local effectfx = self.FxRackChargeMuzzleFlash
        for _, effect in self.FxRackChargeMuzzleFlash do
            for _, muzzle in muzzleBones do
                CreateAttachedEmitter(unit, muzzle, army, effect):ScaleEmitter(scale)
            end
        end
        local chargeStart = bp.Audio.ChargeStart
        if chargeStart then
            self:PlaySound(chargeStart)
        end
        local animationCharge = bp.AnimationCharge
        if animationCharge and self.Animator then
            local animator = CreateAnimator(unit)
            self.Animator = animator
            animator:PlayAnim(animationCharge):SetRate(bp.AnimationChargeRate or 1)
        end
    end,

    -- Played when a rack salvo reloads
    -- Do not wait in here or the sequence in the blueprint will be messed up. Fork a thread instead
    PlayFxRackSalvoReloadSequence = function(self, blueprint)
        local bp = blueprint or self.bp
        local animationReload = bp.AnimationReload
        if animationReload and not self.Animator then
            local animator = CreateAnimator(self.unit)
            self.Animator = animator
            animator:PlayAnim(animationReload):SetRate(bp.AnimationReloadRate or 1)
        end
    end,

    -- Played when a rack reloads. Mostly used for Recoil
    PlayFxRackReloadSequence = function(self, blueprint)
        local bp = self.bp
        local cameraShakeRadius = bp.CameraShakeRadius
        local cameraShakeMax = bp.CameraShakeMax
        local cameraShakeMin = bp.CameraShakeMin
        local cameraShakeDuration = bp.CameraShakeDuration
        if cameraShakeRadius and cameraShakeRadius > 0 and
            cameraShakeMax and cameraShakeMax > 0 and
            cameraShakeMin and cameraShakeMin >= 0 and
            cameraShakeDuration and cameraShakeDuration > 0
        then
            self.unit:ShakeCamera(cameraShakeRadius, cameraShakeMax, cameraShakeMin, cameraShakeDuration)
        end
        if bp.RackRecoilDistance and bp.RackRecoilDistance ~= 0 then
            self:PlayRackRecoil({ bp.RackBones[self.CurrentRackNumber]}, bp)
        end
    end,

    -- Played when a weapon unpacks
    PlayFxWeaponUnpackSequence = function(self)
        -- Deal with owner's audio cues
        local unitBP = self.unit:GetBlueprint()
        local unitBPAudio = unitBP.Audio
        local activate = unitBPAudio.Activate
        if activate then
            self:PlaySound(activate)
        end
        local open = unitBPAudio.Open
        if open then
            self:PlaySound(open)
        end

        -- Deal with the Weapon's audio and animations
        local bp = self.bp
        local unpack = bp.Audio.Unpack
        if unpack then
            self:PlaySound(unpack)
        end
        local unpackAnimation = bp.WeaponUnpackAnimation
        local unpackAnimator = self.UnpackAnimator
        if unpackAnimation and not unpackAnimator then
            unpackAnimator = CreateAnimator(self.unit)
            self.UnpackAnimator = unpackAnimator
            unpackAnimator:PlayAnim(unpackAnimation):SetRate(0)
            unpackAnimator:SetPrecedence(bp.WeaponUnpackAnimatorPrecedence or 0)
            self.Trash:Add(unpackAnimator)
        end
        if unpackAnimator then
            unpackAnimator:SetRate(bp.WeaponUnpackAnimationRate)
            self.WeaponPackState = 'Unpacking'
            WaitFor(unpackAnimator)
        end
        self.WeaponPackState = 'Unpacked'
    end,

    -- Played when a weapon packs up
    -- There is no target, and all rack salvos are complete
    PlayFxWeaponPackSequence = function(self, blueprint)
        local bp = blueprint or self.bp
        local close = self.unit.bp.Audio.Close
        if close then
            self:PlaySound(close)
        end
        local unpackAnimator = self.UnpackAnimator
        if unpackAnimator then
            if bp.WeaponUnpackAnimation then
                unpackAnimator:SetRate(-bp.WeaponUnpackAnimationRate)
            end

            self.WeaponPackState = 'Packing'
            WaitFor(unpackAnimator)
        end
        self.WeaponPackState = 'Packed'
    end,

    -- Create the visual side of rack recoil
    PlayRackRecoil = function(self, rackList, blueprint)
    
        local CreateSlider = CreateSlider
        local LOUDINSERT = LOUDINSERT
        local SetPrecedence = SetPrecedence
        local TrashAdd = TrashAdd
        
        local unit = self.unit
        local RackRecoilDistance = self.bp.RackRecoilDistance
        
        local tmpSldr
        
        for _, v in rackList do
		
            tmpSldr = CreateSlider( unit, v.RackBone)
			
            LOUDINSERT( self.RecoilManipulators, tmpSldr)
			
            SetPrecedence( tmpSldr, 11 )
            SetGoal( tmpSldr, 0, 0, RackRecoilDistance )
            SetSpeed( tmpSldr, -self.RackRecoilReturnSpeed )
			
            TrashAdd( unit.Trash, tmpSldr )
			
            if v.TelescopeBone then
            
                tmpSldr = CreateSlider( unit, v.TelescopeBone)
                
                LOUDINSERT( self.RecoilManipulators, tmpSldr)
                
                SetPrecedence( tmpSldr, 11 )
                SetGoal( tmpSldr, 0, 0, v.TelescopeRecoilDistance or RackRecoilDistance)
                SetSpeed( tmpSldr, -1)
                
                TrashAdd( unit.Trash, tmpSldr )
            end

        end
        
        self:ForkThread( self.PlayRackRecoilReturn, rackList)
    end,

    -- The opposite function to PlayRackRecoil, returns the rack to default position
    PlayRackRecoilReturn = function(self, rackList)
        WaitTicks(1)
        local speed = self.RackRecoilReturnSpeed
        for _, recManip in self.RecoilManipulators do
            recManip:SetGoal(0, 0, 0)
            recManip:SetSpeed(speed)
        end
    end,

    -- Wait for all recoil and animations
    WaitForAndDestroyManips = function(self)
        local manips = self.RecoilManipulators
        if manips then
            for _, manip in manips do
                WaitFor(manip)

            end
            self:DestroyRecoilManips()
        end
        local animator = self.Animator
        if animator then
            WaitFor(animator)

            animator:Destroy()
            self.Animator = nil
        end
    end,

    -- Destroy the sliders which cause weapon visual recoil
    DestroyRecoilManips = function(self)

        for _, v in self.RecoilManipulators do
            v:Destroy()
        end

        self.RecoilManipulators = {}
    end,

    -- Should be called whenever a target is lost
    -- Includes the manual selection of a new target, and the issuing of a move order
    ---@param self DefaultProjectileWeapon
    OnLostTarget = function(self)
        -- Issue 43
        -- Tell the owner this weapon has lost the target
        local unit = self.unit
        if unit then
            unit:OnLostTarget(self)
        end

        Weapon.OnLostTarget(self)

        if self.bp.WeaponUnpacks then
            ChangeState(self, self.WeaponPackingState)
        else
            ChangeState(self, self.IdleState)
        end
    end,

    -- Present for Overcharge to hook into
    OnWeaponFired = function(self)
    end,

    -- I think this is triggered whenever the state changes to anything but DeadState
    OnEnterState = function(self)

        local weaponWantEnabled = self.WeaponWantEnabled
        local weaponIsEnabled = self.WeaponIsEnabled
        if weaponWantEnabled and not weaponIsEnabled then
            self.WeaponIsEnabled = true
            self:SetWeaponEnabled(true)
        elseif not weaponWantEnabled and weaponIsEnabled then
            local bp = self.bp
            if bp.CountedProjectile ~= true then
                self.WeaponIsEnabled = false
                self:SetWeaponEnabled(false)
            end
        end

        local weaponAimWantEnabled = self.WeaponAimWantEnabled
        local weaponAimIsEnabled = self.WeaponAimIsEnabled
        if weaponAimWantEnabled and not weaponAimIsEnabled then
            self.WeaponAimIsEnabled = true
            self:AimManipulatorSetEnabled(true)
        elseif not weaponAimWantEnabled and weaponAimIsEnabled then
            self.WeaponAimIsEnabled = false
            self:AimManipulatorSetEnabled(false)
        end
    end,

    -- WEAPON STATES:
    
    IdleState = State {
	
		WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        Main = function(self)
            local unit = self.unit
            if unit.Dead then return end
            unit:SetBusy(false)

            -- at this point salvo is always done so reset the data in case firing was interrupted
            self.CurrentSalvoData = nil
            if self.RecoilManipulators then
                self:WaitForAndDestroyManips()
            end
            local bp = self.bp

            if bp.RackBones then
                for _, v in bp.RackBones do
                
                    if v.HideMuzzle == true then
                
                        for _, mv in v.MuzzleBones do
                            unit:ShowBone( mv, true )
                        end
                    end
                end
                self:StartEconomyDrain()
                if LOUDGETN(bp.RackBones) > 1 and self.CurrentRackNumber > 1 then
                    if bp.RackReloadTimeout then
                        WaitSeconds(bp.RackReloadTimeout)
                    end
                    self:PlayFxRackSalvoReloadSequence()
                    self.CurrentRackNumber = 1
                end
            end
        end,

        OnGotTarget = function(self)
            local unit = self.unit
            local bp = self.bp

            local unit = self.unit

            if unit then
                unit:OnGotTarget(self)
            end

            if not bp.WeaponUnpackLockMotion or (bp.WeaponUnpackLocksMotion and not self.unit:IsUnitState('Moving')) then
                if bp.CountedProjectile and not self:CanFire() then
                    return
                end
                if bp.WeaponUnpacks then
                    LOUDSTATE(self, self.WeaponUnpackingState)
                else
                    if bp.RackSalvoChargeTime and bp.RackSalvoChargeTime > 0 then
                        LOUDSTATE(self, self.RackSalvoChargeState)
                    else
                        LOUDSTATE(self, self.RackSalvoFireReadyState)
                    end
                end
            end
        end,

        OnFire = function(self)

            local bp = self.bp
            if bp.WeaponUnpacks and self.WeaponPackState ~= 'Unpacked' then
                LOUDSTATE(self, self.WeaponUnpackingState)
            else
                if (bp.RackSalvoChargeTime and bp.RackSalvoChargeTime > 0) or bp.RackSalvoFiresAfterCharge == true then
                    LOUDSTATE(self, self.RackSalvoChargeState)

                    -- SkipReadyState used for Janus and Corsair
                elseif bp.SkipReadyState then
                    LOUDSTATE(self, self.RackSalvoFiringState)
                else
                    LOUDSTATE(self, self.RackSalvoFireReadyState)
                end
            end
        end,
    },

    RackSalvoChargeState = State {

        WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        Main = function(self)
            local unit = self.unit
            local bp = self.bp
            local notExclusive = bp.NotExclusive
            unit:SetBusy(true)
            self:PlayFxRackSalvoChargeSequence()

            if notExclusive then
                unit:SetBusy(false)
            end

            if bp.RackSalvoChargeTime then
                WaitSeconds(bp.RackSalvoChargeTime)
            end

            if notExclusive then
                unit:SetBusy(true)
            end

            if bp.RackSalvoFiresAfterCharge == true then
                LOUDSTATE(self, self.RackSalvoFiringState)
            else
                LOUDSTATE(self, self.RackSalvoFireReadyState)
            end

        end,

        OnFire = function(self)
        end,
    },

    RackSalvoFireReadyState = State {

        WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        Main = function(self)
            
            local bp = self.bp
            local unit = self.unit
            if bp.CountedProjectile and bp.WeaponUnpacks then
                unit:SetBusy(true)
            else
                unit:SetBusy(false)
            end

            self.WeaponCanFire = true
            local econDrain = self.EconDrain
            if econDrain then
                self.WeaponCanFire = false
                WaitFor(econDrain)
                self.WeaponCanFire = true
            end

            --We change the state on counted projectiles because we won't get another OnFire call.
            --The second part is a hack for units with reload animations.  They have the same problem
            --they need a RackSalvoReloadTime that's 1/RateOfFire set to avoid firing twice on the first shot
            if (bp.CountedProjectile) then

                -- But, as we're doing something unnatural we need to take into account the fire state. As an interesting side effect,

                -- prevent firing the weapon through `OnFire`
                self.WeaponCanFire = false
            
                while unit:GetFireState() == 1 do
                    WaitTicks(1)
                end

                -- now we're good and ready to fire as we see fit
                self.WeaponCanFire = true
                
                LOUDSTATE(self, self.RackSalvoFiringState)
            end

            -- Bombers should not have their targets reset since they take a large path much longer than their reload time.
            if not (IsDestroyed(unit) or IsDestroyed(self)) and not bp.NeedToComputeBombDrop then
                if bp.TargetResetWhenReady then

                    -- attempts to fix weapons that intercept projectiles to being stuck on a projectile while reloading, preventing
                    -- other weapons from targeting that projectile. Is a side effect of the blueprint field `DesiredShooterCap`. For a more
                    -- aggressive version see the blueprint field `DisableWhileReloading` which completely disables the weapon

                    WaitTicks(5)

                    self:ResetTarget()
                else

                    -- attempts to fix weapons being stuck on targets that are outside their current attack radius, but inside
                    -- the tracking radius. This happens when the weapon acquires a target, but never actually fires and
                    -- therefore the thread of this state is not destroyed

                    -- wait reload time + 3 seconds, then force the weapon to recheck its target
                    WaitSeconds((1 / bp.RateOfFire) + 3)
                    self:ResetTarget()
                end
            end
        end,

		-- while debugging the WeaponUnpackLocksMotion I discovered that if you have the value NeedsUnpack = true in the AI section
		-- then the weapon will Never do an OnFire() event unless the unit is set to IMMOBILE
        OnFire = function(self)
            if self.WeaponCanFire then
                LOUDSTATE(self, self.RackSalvoFiringState)
            end
        end,

        OnGotTarget = function(self)
        end,
    },

    RackSalvoFiringState = State {
	
        StateName = 'RackSalvoFiringState',

        WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        RenderClockThread = function(self, rateOfFire)
            local unit = self.unit
            local clockTime = math.round(10 * rateOfFire)
            local totalTime = clockTime
            while clockTime >= 0 and
                not self:BeenDestroyed() and
                not unit.Dead do
                unit:SetWorkProgress(1 - clockTime / totalTime)
                clockTime = clockTime - 1
                WaitSeconds(0.1)
            end
        end,

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
            if not self:BeenDestroyed() and
                not unit.Dead then
                if bp.RenderFireClock and bp.RateOfFire > 0 then
                    self:ForkThread(self.RenderClockThread, 1 / bp.RateOfFire)
                end
            end
            
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
					
                    muzzle = CurrentRackInfo.MuzzleBones[muzzleIndex]
 					
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
                        WaitSeconds( MuzzleChargeDelay )
                    end

                    ------------------
					-- muzzle fires --
                    ------------------					

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

            self.FirstShot = false
            self:StartEconomyDrain() -- the recharge begins as soon as the weapon starts firing
            self:OnWeaponFired() -- Used primarily by Overcharge

			if Buffs then
				self:DoOnFireBuffs(Buffs) -- TODO: Need to investigate how the buffs are applied currently
			end

            self.HaltFireOrdered = false

            if self.CurrentRackNumber > TotalRacksOnWeapon then
                self.CurrentRackNumber = 1
                if bp.RackSalvoReloadTime > 0 or self.EconDrain then
                    LOUDSTATE(self, self.RackSalvoReloadState)
                elseif bp.RackSalvoChargeTime > 0 then
                    LOUDSTATE(self, self.IdleState)
                elseif CountedProjectile then
                    if bp.WeaponUnpacks then
                        LOUDSTATE(self, self.WeaponPackingState)
                    else
                        LOUDSTATE(self, self.IdleState)
                    end
                else
                    LOUDSTATE(self, self.RackSalvoFireReadyState)
                end
            elseif CountedProjectile then
                if bp.WeaponUnpacks then
                    LOUDSTATE(self, self.WeaponPackingState)
                else
                    LOUDSTATE(self, self.IdleState)
                end
            else
                LOUDSTATE(self, self.RackSalvoFireReadyState)
            end
        end,
		
		OnFire = function(self)

		end,


        -- Set a bool so we won't fire if the target reticle is moved
        OnHaltFire = function(self)
            self.HaltFireOrdered = true
        end,
    },

    RackSalvoReloadState = State {

        WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        Main = function(self)
            local unit = self.unit
            unit:SetBusy(true)
            self:PlayFxRackSalvoReloadSequence()

            local bp = self.bp
            local notExclusive = bp.NotExclusive

            if notExclusive then
                unit:SetBusy(false)
            end
            
            if bp.RackSalvoReloadTime then
                WaitSeconds(bp.RackSalvoReloadTime)
            end
            
            if self.BeamLifetimeWatch then
            
                while self.BeamLifetimeWatch do
                    WaitTicks(1)
                end

            end

            if self.RecoilManipulators then
                self:WaitForAndDestroyManips()
            end

            local hasTarget = self:WeaponHasTarget()

            -- Weapons that fire after charging will ignore the fire rate if we don't send them to the idle state
            -- and if we send them to the fire ready state instead, they will ignore charge effects
            local autoFire = not bp.ManualFire and not bp.RackSalvoFiresAfterCharge == true

            if hasTarget and bp.RackSalvoChargeTime > 0 and autoFire then
                LOUDSTATE(self, self.RackSalvoChargeState)
            elseif hasTarget and autoFire then
                LOUDSTATE(self, self.RackSalvoFireReadyState)
            elseif not hasTarget and bp.WeaponUnpacks and not bp.WeaponUnpackLocksMotion then
                LOUDSTATE(self, self.WeaponPackingState)
            else
                LOUDSTATE(self, self.IdleState)
            end
			
        end,

        OnFire = function(self)
        end,
        
        OnLostTarget = function(self)
            -- Override default OnLostTarget to prevent bypassing reload time by switching to idle state immediately
            local unit = self.unit
            if unit then
                unit:OnLostTarget(self)
            end

            Weapon.OnLostTarget(self)
        end,
    },

    WeaponUnpackingState = State {

        StateName = 'WeaponUnpackingState',

        WeaponWantEnabled = false,
        WeaponAimWantEnabled = false,

        Main = function(self)
            local unit = self.unit
            unit:SetBusy(true)

            local bp = self.bp
            if bp.WeaponUnpackLocksMotion then
                unit:SetImmobile(true)
            end
            self:PlayFxWeaponUnpackSequence()

            local rackSalvoChargeTime = bp.RackSalvoChargeTime
            if rackSalvoChargeTime and rackSalvoChargeTime > 0 then
                LOUDSTATE(self, self.RackSalvoChargeState)
            else
                LOUDSTATE(self, self.RackSalvoFireReadyState)
            end
        end,

        OnFire = function(self)
        end,
    },

    -- This state is for weapons which have to pack up before moving or whatever
    WeaponPackingState = State {

        StateName = 'WeaponPackingState',

        WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        ---@param self DefaultProjectileWeapon
        Main = function(self)
            local unit = self.unit

            if not IsDestroyed(unit) then
                unit:SetBusy(true)
            end

            local bp = self.bp
            
            if bp.WeaponRepackTimeout then
                WaitSeconds(bp.WeaponRepackTimeout)
            end

            self:AimManipulatorSetEnabled(false)
            self:PlayFxWeaponPackSequence(bp)
            if bp.WeaponUnpackLocksMotion then
                unit:SetImmobile(false)
            end
            LOUDSTATE(self, self.IdleState)
        end,

        ---@param self DefaultProjectileWeapon
        OnGotTarget = function(self)
            local bp = self.bp

            Weapon.OnGotTarget(self)

            local unit = self.unit
            if unit then
                unit:OnGotTarget(self)
            end

            if not self.bp.ForceSingleFire then
                LOUDSTATE(self, self.WeaponUnpackingState)
            end
        end,

        ---@param self DefaultProjectileWeapon
        OnFire = function(self)
            local bp = self.bp
            if 
            self.WeaponPackState == 'Unpacking' or

                -- triggers when we fired a missile but we're still waiting for the pack animation to finish
                (bp.CountedProjectile and (not bp.ForceSingleFire))
            then
                LOUDSTATE(self, self.WeaponUnpackingState)
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

            self.WeaponCanFire = false
			
            if self.EconDrain then

                WaitFor(self.EconDrain)

            end
			
            self.WeaponCanFire = true

            LOUDSTATE(self, self.RackSalvoFiringState)

        end,

    },

    OnFire = function(self)
        local myProjectile = CreateProjectile( self.unit, projectilebp, 0, 0, 0, nil, nil, nil):SetCollision(false)
        
        if self.Data then
            myProjectile:PassData(self.Data)
        end
    end,

}