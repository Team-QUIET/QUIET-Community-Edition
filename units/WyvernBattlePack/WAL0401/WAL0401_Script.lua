-----------------------------------------------------------------
-- File     :  /cdimage/units/UAL0401/UAL0401_script.lua
-- Author(s):  John Comes, Gordon Duclos
-- Summary  :  Aeon Galactic Colossus Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

--  Credit to Jip (FAF) for GC TractorClaw Rework

local AWalkingLandUnit = import('/lua/defaultunits.lua').WalkingLandUnit
local WeaponsFile = import ('/lua/aeonweapons.lua')
local ADFPhasonLaser = WeaponsFile.ADFPhasonLaser
local ADFTractorClaw = WeaponsFile.ADFTractorClaw
WeaponsFile = nil
local explosion = import('/lua/defaultexplosions.lua')

-- TODO PORT (FAF)
--local CreateAeonColossusBuildingEffects = import("/lua/effectutilities.lua").CreateAeonColossusBuildingEffects

-- upvalue for performance
local MathSqrt = math.sqrt
local MathCos = math.cos 
local MathSin = math.sin 


-- store for performance
local ZeroDegrees = Vector(0, 0, 1)
local SignCheck = Vector(1, 0, 0)

WAL0401 = ClassUnit(AWalkingLandUnit) {
    Weapons = {
        EyeWeapon = ClassWeapon(ADFPhasonLaser) {
            CreateProjectileAtMuzzle = function(self, muzzle)
                ADFPhasonLaser.CreateProjectileAtMuzzle(self, muzzle)

                -- if possible, try not to fire on units that we're tractoring
                local target = self:GetCurrentTarget()
                if target then
                    local unit = (IsUnit(target) and target) or target:GetSource()
                    if unit and unit.Tractored then
                        self:ResetTarget()
                    end
                end
            end,
        },
        RightArmTractor = ClassWeapon(ADFTractorClaw) {},
        LeftArmTractor = ClassWeapon(ADFTractorClaw) {},
    },

    OnCreate = function (self, spec)
        AWalkingLandUnit.OnCreate(self, spec)

        self:ForkThread(self.AdjustWeaponsThread)
    end,


    AdjustWeaponsThread = function(self)

        while not self.Dead do 

            -- only perform this logic if the unit is on the move
            if self:IsUnitState("Moving") then

                -- compute the direction of the heading
                local sx, sy, sz = self:GetPositionXYZ()
                local heading = self:GetHeading()
                local hx, hz = MathSin(heading), MathCos(heading)

                local bp = self:GetBlueprint()
                for k = 1, 3 do
                --for k = 1, self.WeaponCount do 

                    -- retrieve weapon and its target
                    local weapon = self:GetWeapon(k)
                    local target = weapon:GetCurrentTarget()

                    if target then 

                        -- compute direction and normalize
                        local tx, ty, tz = target:GetPositionXYZ()
                        local dx, dz = tx - sx, tz - sz
                        local invLength = 1.0 / MathSqrt(dx * dx + dz * dz)
                        dx, dz = invLength * dx, invLength * dz

                        -- compute dot product between weapon target and our heading, if it is lower than 0 it means the target is behind us
                        local dot = dx * hx + dz * hz
                        if dot < 0 then 
                            weapon:ResetTarget()
                        end
                    end
                end
            end

            WaitSeconds(0.2)
        end
    end,

    --StartBeingBuiltEffects = function(self, builder, layer)
    --    AWalkingLandUnit.StartBeingBuiltEffects(self, builder, layer)
    --    CreateAeonColossusBuildingEffects(self)
    --end,

    OnKilled = function(self, instigator, type, overkillRatio)
        AWalkingLandUnit.OnKilled(self, instigator, type, overkillRatio)

        local wep = self:GetWeaponByLabel('EyeWeapon')
        local bp = wep:GetBlueprint()
        if bp.Audio.BeamStop then
            wep:PlaySound(bp.Audio.BeamStop)
        end

        if bp.Audio.BeamLoop and wep.Beams[1].Beam then
            wep.Beams[1].Beam:SetAmbientSound(nil, nil)
        end

        for k, v in wep.Beams do
            v.Beam:Disable()
        end
    end,

    DeathThread = function(self, overkillRatio , instigator)
        self:PlayUnitSound('Destroyed')
        explosion.CreateDefaultHitExplosionAtBone(self, 'Torso', 4.0)
        explosion.CreateDebrisProjectiles(self, explosion.GetAverageBoundingXYZRadius(self), {self:GetUnitSizes()}) --size.SizeX, size.SizeY, size.SizeZ
        WaitSeconds(2)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Right_Leg_B02', 1.0)
        WaitSeconds(0.1)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Right_Leg_B01', 1.0)
        WaitSeconds(0.1)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Left_Arm_B02', 1.0)
        WaitSeconds(0.3)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Right_Arm_B01', 1.0)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Right_Leg_B01', 1.0)

        WaitSeconds(3.5)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Torso', 5.0)

        if self.DeathAnimManip then
            WaitFor(self.DeathAnimManip)
        end

        -- only apply death damage when the unit is sufficiently build
        local bp = self:GetBlueprint()
        local FractionThreshold = bp.General.FractionThreshold or 0.5
        if self:GetFractionComplete() >= FractionThreshold then 
            local bp = self:GetBlueprint()
            local position = self:GetPosition()
            local qx, qy, qz, qw = unpack(self:GetOrientation())
            local a = math.atan2(2.0 * (qx * qz + qw * qy), qw * qw + qx * qx - qz * qz - qy * qy)
            for i, numWeapons in bp.Weapon do
                if bp.Weapon[i].Label == 'CollossusDeath' then
                    position[3] = position[3]+5*math.cos(a)
                    position[1] = position[1]+5*math.sin(a)
                    DamageArea(self, position, bp.Weapon[i].DamageRadius, bp.Weapon[i].Damage, bp.Weapon[i].DamageType, bp.Weapon[i].DamageFriendly)
                    break
                end
            end
        end

        self:DestroyAllDamageEffects()
        self:CreateWreckage(overkillRatio)

        -- CURRENTLY DISABLED UNTIL DESTRUCTION
        -- Create destruction debris out of the mesh, currently these projectiles look like crap,
        -- since projectile rotation and terrain collision doesn't work that great. These are left in
        -- hopes that this will look better in the future.. =)
        if self.ShowUnitDestructionDebris and overkillRatio then
            if overkillRatio <= 1 then
                self.CreateUnitDestructionDebris(self, true, true, false)
            elseif overkillRatio <= 2 then
                self.CreateUnitDestructionDebris(self, true, true, false)
            elseif overkillRatio <= 3 then
                self.CreateUnitDestructionDebris(self, true, true, true)
                self.CreateUnitDestructionDebris(self, true, true, true)
            else -- Vaporized
                self.CreateUnitDestructionDebris(self, true, true, true)
            end
        end

        self:Destroy()
    end,
}
TypeClass = WAL0401