---  /lua/aeonweapons.lua
---  Default definitions of Aeon weapons
---  Credit to Jip (FAF) for GC TractorClaw Rework
---  QUIET's First Overhaul, Courtesy of FAF!

local Entity = import('/lua/sim/Entity.lua').Entity
local Weapon = import('/lua/sim/weapon.lua').Weapon
local WeaponFile = import('/lua/sim/DefaultWeapons.lua')
local CollisionBeamFile = import('defaultcollisionbeams.lua')
local TractorClawCollisionBeam = CollisionBeamFile.TractorClawCollisionBeam
local Explosion = import('defaultexplosions.lua')
local EffectTemplate = import("/lua/effecttemplates.lua")
local QCECollisionbeams = import('/mods/QUIET-Community-Edition/lua/QCECollisionbeams.lua')

local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon



---@class ADFTractorClaw
---@field TractorTrash TrashBag
---@field RunningTractorThread boolean
ADFTractorClaw = ClassWeapon(Weapon) {

    VacuumFx = EffectTemplate.ACollossusTractorBeamVacuum01,
    TractorFx = EffectTemplate.ATractorAmbient,
    CrushFx = EffectTemplate.ACollossusTractorBeamCrush01,
    TractorMuzzleFx = { EffectTemplate.ACollossusTractorBeamGlow01 },
    BeamFx = { EffectTemplate.ACollossusTractorBeam01 },

    SliderVelocity = {
        TECH3 = 10,
        TECH2 = 13,
        TECH1 = 16,
    },

    --- Adds logic to catch edge cases
    ---@param self ADFTractorClaw
    ---@param spec table
    OnCreate = function(self, spec)
        Weapon.OnCreate(self, spec)

        -- make us quite a bit slower
        self.AimControl:SetResetPoseTime(4.0)

        -- add a unit callback to fix edge cases
        self.unit:AddUnitCallback(
            function(colossus, instigator)
                if self.RunningTractorThread then
                    -- reset target state
                    local blipOrUnit = self:GetCurrentTarget()
                    if not IsDestroyed(blipOrUnit) then 
                        local target = self:GetUnitBehindTarget(blipOrUnit)
                        if target then
                            self:MakeVulnerable(target)
                        end
                    end

                    -- detach everything from this weapon
                    self.unit:DetachAll(self.bp.MuzzleSpecial)
                    self:SetEnabled(false)
                end
            end,
            'OnKilled'
        )
    end,

    --- Attempts to perform the tracting
    ---@param self ADFTractorClaw
    OnFire = function(self)
        -- only tractor one target at a time
        if self.RunningTractorThread then
            self.Trash:Add(ForkThread(self.OnInvalidTargetThread, self))
            return
        end

        ---@type Blip | Unit
        local blipOrUnit = self:GetCurrentTarget()
        if not blipOrUnit then
            return
        end

        -- only tractor actual units
        local target = self:GetUnitBehindTarget(blipOrUnit)
        if not target then
            self.Trash:Add(ForkThread(self.OnInvalidTargetThread, self))
            return
        end

        -- only tract units that are not being tracted at the moment
        if target.Tractored then
            self.Trash:Add(ForkThread(self.OnInvalidTargetThread, self))
            return
        end

        -- start tractoring
        target.Tractored = true
        self.RunningTractorThread = true
        local muzzle = self.bp.MuzzleSpecial
        self.TractorThreadInstance = ForkThread(self.TractorThread, self, target, muzzle)
    end,

    --- Disables the weapon to make sure we try and get a new target
    ---@param self ADFTractorClaw
    OnInvalidTargetThread = function(self)
        self:ResetTarget()
        self:SetEnabled(false)
        WaitTicks(5)
        if not IsDestroyed(self) then
            self:SetEnabled(true)
        end
    end,

    --- Attempts to retrieve the unit behind the target, can return false if the blip is too far away from the unit due to jamming
    ---@param self ADFTractorClaw
    ---@param blip Blip | Unit
    ---@return Unit | boolean
    GetUnitBehindTarget = function(self, blip)
        if IsUnit(blip) then
            -- return the unit
            return blip
        else
            local blipPosition = blip:GetPosition()
            local unit = blip:GetSource()
            local unitPosition = unit:GetPosition()
            local distance = VDist3(blipPosition, unitPosition)
            if distance < 10 then
                return unit
            else
                return false
            end
        end
    end,

    --- Performs the tractoring, starting from this point all is good
    ---@param self ADFTractorClaw
    ---@param target Unit
    ---@param muzzle string
    TractorThread = function(self, target, muzzle)

        local unit = self.unit
        local trash = TrashBag()
        self.Trash:Add(trash)

        -- apparently `CreateEmitterAtBone` doesn't attach to the bone, only positions it at the bone
        local effectsEntity = Entity({Owner = unit})
        Warp(effectsEntity, unit:GetPosition(self.bp.TurretBoneMuzzle))
        effectsEntity:AttachTo(unit, self.bp.TurretBoneMuzzle)
        trash:Add(effectsEntity)

        -- create vacuum effect
        for k, effect in self.VacuumFx do
            trash:Add(CreateEmitterOnEntity(target, self.Army, effect):ScaleEmitter(0.75))
        end

        -- create tractor effect
        for k, effect in self.TractorFx do 
            trash:Add(CreateEmitterOnEntity(target, self.Army, effect))
        end

        -- create start effect
        for k, effect in self.TractorMuzzleFx do
            trash:Add(CreateEmitterOnEntity(effectsEntity, self.Army, effect))
        end

        -- compute the distance to set the slider
        local bonePosition = unit:GetPosition(muzzle)
        local targetPosition = target:GetPosition()
        local distance = VDist3(bonePosition, targetPosition)

        local slider = CreateSlider(unit, muzzle, 0, 0, distance, -1, true)
        trash:Add(slider)

        WaitTicks(1)
        WaitFor(slider)

        if (not IsDestroyed(target)) and (not IsDestroyed(unit)) then

            -- attach the slider to the target
            target:SetDoNotTarget(false)
            target:AttachBoneTo(-1, unit, muzzle)
            self:MakeImmune(target)

            -- make it stop what it was doing
            IssueClearCommands(target)

            local velocity = self.SliderVelocity[target.bp.TechCategory] or 13

            -- start pulling back the slider
            slider:SetSpeed(velocity)
            slider:SetGoal(0, 0, 0)

            local rotatorA = CreateRotator(target, 0, 'x', nil, 0, 15 + Random(0, 45), 20 + Random(0, 80))
            trash:Add(rotatorA)

            local rotatorB = CreateRotator(target, 0, 'y', nil, 0, 15 + Random(0, 15), 20 + Random(0, 80))
            trash:Add(rotatorB)

            local rotatorC = CreateRotator(target, 0, 'z', nil, 0, 15 + Random(0, 45), 20 + Random(0, 80))
            trash:Add(rotatorC)

            WaitTicks(1)
            WaitFor(slider)

            -- we're at the arm, do destruction effects
            if (not IsDestroyed(target)) and (not IsDestroyed(unit)) and (not IsDestroyed(self)) then

                -- stop rotating
                rotatorA:SetGoal(0)
                rotatorB:SetGoal(0)
                rotatorC:SetGoal(0)

                -- create crush effect
                for k, effect in self.CrushFx do
                    CreateEmitterAtBone(unit, muzzle, unit.Army, effect)
                end

                -- create light particles
                CreateLightParticle(unit, muzzle, self.Army, 1, 4, 'glow_02', 'ramp_blue_16')
                WaitTicks(1)

                if not IsDestroyed(unit) then

                    target.CanTakeDamage = true
                    while not IsDestroyed(target) and not IsDestroyed(unit) and not unit.Dead and
                        target:GetHealth() >= (self.bp.TractorDamage or 4999) + 1 do
                        Damage(unit, bonePosition, target, (self.bp.TractorDamage or 4999), "Normal")
                        Explosion.CreateScalableUnitExplosion(target, 1, true)
                        WaitTicks((self.bp.TractorDamageInterval or 10) + 1)
                    end

                    CreateLightParticle(unit, muzzle, self.Army, 4, 2, 'glow_02', 'ramp_blue_16')
                    Explosion.CreateScalableUnitExplosion(target, 3, true)

                    -- deattach the unit, destroy the slider
                    unit:DetachAll(muzzle)
                    slider:Destroy()

                    -- create thread to take into account the fall
                    if not IsDestroyed(self) then
                        self:ResetTarget()
                        self:ForkThread(self.TargetFallThread, target, trash, muzzle)
                    else
                        self:MakeVulnerable(target)
                        trash:Destroy()
                    end
                else
                    self:MakeVulnerable(target)
                    trash:Destroy()
                end
            else 
                self:MakeVulnerable(target)
                trash:Destroy()
            end
        else 
            self:MakeVulnerable(target)
            trash:Destroy()
        end

        self.TractorThreadInstance = nil
        self.RunningTractorThread = false
    end,

    --- Semi-realistic fall from the tractor claw to the ground
    ---@param self ADFTractorClaw
    ---@param target Unit
    ---@param trash TrashBag
    ---@param muzzle string
    TargetFallThread = function(self, target, trash, muzzle)

        -- clean up the effects once the unit starts falling
        if not IsDestroyed(self) then
            self.Trash:Add(ForkThread(self.TrashDelayedDestroyThread, self, trash))
        end

        -- if the unit is magically already destroyed, then just return - nothing we can do,
        -- we'll likely end up with a flying wreck :)
        if IsDestroyed(target) then
            return
        end

        -- air units drop on their own
        if target.bp.CategoriesHash["AIR"] then
            target:Kill()
        -- assist land units with a natural drop
        else
            -- let it create the wreck, with the rotator manipulators attached
            target.PlayDeathAnimation = false
            target.DestructionExplosionWaitDelayMin = 0
            target.DestructionExplosionWaitDelayMax = 0

            -- create a projectile to help identify when the unit is on the terrain
            local projectile = target:CreateProjectileAtBone('/mods/QUIET-Community-Edition/effects/entities/ADFTractorFall01/ADFTractorFall01_proj.bp', 0)

            -- is not defined when the projectile is created underwater
            if not projectile.bp then
                Explosion.CreateScalableUnitExplosion(target, 0, true)
                target:Destroy()
                return
            end

            -- match velocity and orientation of unit
            local vx, vy, vz = target:GetVelocity()
            projectile:SetVelocity(10 * vx, 10 * vy, 10 * vz)
            Warp(projectile, target:GetPosition(), target:GetOrientation())
            projectile.OnImpact = function(projectile)
                if not IsDestroyed(target) then
                    target:Kill()

                    CreateLightParticle(target, 0, self.Army, 4, 2, 'glow_02', 'ramp_blue_16')

                    local position = target:GetPosition()
                    DamageArea(target, position, 3, 1, 'TreeFire', false, false)
                    DamageArea(target, position, 2, 1, 'TreeForce', false, false)
                end

                projectile:Destroy()
            end
        end
    end,

    --- Delayed destruction of the trashbag, allows the wreck to copy over the rotators
    ---@param self ADFTractorClaw
    ---@param trash TrashBag
    TrashDelayedDestroyThread = function(self, trash)
        WaitTicks(1)
        trash:Destroy()
    end,

    ---@param self ADFTractorClaw
    ---@param target Unit
    MakeImmune = function (self, target)
        if not IsDestroyed(target) then
            target:SetDoNotTarget(true)
        end
    end,

    ---@param self ADFTractorClaw
    ---@param target Unit
    MakeVulnerable = function (self, target)
        if not IsDestroyed(target) then
            target:SetDoNotTarget(false)
            target.Tractored = nil
        end
    end,
}

---@class ADFTractorClawStructure : DefaultBeamWeapon
ADFTractorClawStructure = ClassWeapon(DefaultBeamWeapon) {
    BeamType = TractorClawCollisionBeam,
    FxMuzzleFlash = {},
}

AIFArtilleryMiasmaShellWeapon   = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = {},

    CreateProjectileForWeapon = function(self, bone)
    
        local proj = self:CreateProjectile(bone)
        
        local damageTable = self.damageTable
        
        local blueprint = self.bp
        local data = false
        
        if blueprint.DoTDamage then
        
            data = {
                Damage = blueprint.DoTDamage,
                Duration = blueprint.DoTDuration,
                Frequency = blueprint.DoTFrequency,
                Radius = blueprint.DamageRadius,
                Type = 'Normal',
                DamageFriendly = blueprint.DamageFriendly,
            }
        end

        if proj and not proj:BeenDestroyed() then
        
            proj:PassDamageData(damageTable)
            
            if data then
                proj:PassData(data)
            end
        end

        return proj
    end,
}

AeonTargetPainter = ClassWeapon(DefaultBeamWeapon) { 
    FxMuzzleFlash = {},
}

TMAnovacatbluelaserweapon = ClassWeapon(DefaultBeamWeapon) {
    BeamType = QCECollisionbeams.TMNovaCatBlueLaserBeam,
    FxMuzzleFlash = {},
    FxChargeMuzzleFlash = {},
    FxUpackingChargeEffects = EffectTemplate.CMicrowaveLaserCharge01,
    FxUpackingChargeEffectScale = 1,
}