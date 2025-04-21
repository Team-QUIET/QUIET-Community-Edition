QCEProjectile = Projectile
Projectile = ClassProjectile(QCEProjectile) {
    OnCreate = function(self, InWater)

		local bp = GetBlueprint(self)
        
        local AudioExist        = bp.Audio.ExistLoop or false
        local TrackTargetGround = bp.Physics.TrackTargetGround or false
        
        self.Army = GetArmy(self)        
        self.BlueprintID = bp.BlueprintId or false
        self.Launcher = self:GetLauncher()
		
        SetMaxHealth( self, bp.Defense.MaxHealth or 1)
        SetHealth( self, self, GetMaxHealth(self))

        if AudioExist then
            self:SetAmbientSound( AudioExist, nil)
        end
        
        if TrackTargetGround then
		
            local pos = GetCurrentTargetPosition(self)
			
            pos[2] = GetSurfaceHeight( pos[1], pos[3] )
            self:SetNewTargetGround(pos)
        end

		if ScenarioInfo.ProjectileDialog then

            if self.BlueprintID then
                LOG("*AI DEBUG Projectile OnCreate BlueprintID is "..repr(self.BlueprintID) )
            else
                LOG("*AI DEBUG Projectile OnCreate BlueprintID is FALSE "..repr(bp) )
            end

		end

        if bp.Physics.TrackTargetGround == true then
            ForkThread(self.OnTrackTargetGround, self)
        end
    end,

    --- Credits to FAF
    OnTrackTargetGround = function(self)
        local target = self.OriginalTarget or self:GetTrackingTarget() or self.Launcher:GetTargetEntity()
        if target and IsUnit(target) then

            local unitBlueprint = target.bp

            -- X-offset units often have displaced center bones, so they're not accounted for.
            local cy, cz = unitBlueprint.CollisionOffsetY or 0, unitBlueprint.CollisionOffsetZ or 0
            local sx, sy, sz = unitBlueprint.SizeX or 1, unitBlueprint.SizeY or 1, unitBlueprint.SizeZ or 1
            local px, py, pz = target:GetPositionXYZ()
            
            -- don't target the part of the hitbox below the surface
            if cy < 0 then
                sy = sy + cy
                cy = 0
            end

            local bp = GetBlueprint(self)
            local physics = bp.Physics
            local fuzziness = physics.TrackTargetGroundFuzziness or 0.8
            local offset = physics.TrackTargetGroundOffset or 0
            sx = sx + offset
            sz = sz + offset
            
            local dx = sx * (Random() - 0.5) * fuzziness
            local dy = (sy + offset) * (Random() - 0.5) * fuzziness + sy/2 + cy
            local dz = sz * (Random() - 0.5) * fuzziness + cz
            local dw


            -- Rotate a vector by a quaternion: q * v * conjugate(q)
            -- Supreme Commander quaternions use y,z,x,w!
            local ty, tz, tx, tw = unpack(target:GetOrientation())

            -- compute the product in a single assignment to not have to use temporary, single-use variables.
            dw, dx, dy, dz = 
            -tx * dx - tz * dy - ty * dz,
             tw * dx + tz * dz - ty * dy,
             tw * dy + ty * dx - tx * dz,
             tw * dz + tx * dy - tz * dx

            tx, tz, ty = -tx, -tz, -ty
            
            -- compute the product in a single assignment to not have to use temporary, single-use variables.
            dx, dy, dz = 
            dw * tx + dx * tw + dy * ty - dz * tz,
            dw * tz + dy * tw + dz * tx - dx * ty,
            dw * ty + dz * tw + dx * tz - dy * tx


            local pos = { px + dx, py + dy, pz + dz }
            self:SetNewTargetGround(pos)
        else
            local pos = self:GetCurrentTargetPosition()

            local bp = GetBlueprint(self)
            local physics = bp.Physics
            local fuzziness = physics.TrackTargetGroundFuzziness or 0.8
            local offset = physics.TrackTargetGroundOffset or 0
            local dx = (Random() - 0.5) * fuzziness * (1 + offset)
            local dz = (Random() - 0.5) * fuzziness * (1 + offset)

            pos[1] = pos[1] + dx
            pos[3] = pos[3] + dz

            pos[2] = GetSurfaceHeight(pos[1], pos[3])
            self:SetNewTargetGround(pos)
        end
    end,

    OnImpact = function(self, targetType, targetEntity)
        
        local ProjectileDialog = ScenarioInfo.ProjectileDialog
        local VectorCached     = Vector(0, 0, 0)
        local EntityMethods = moho.entity_methods
        local EntityGetPositionXYZ = EntityMethods.GetPositionXYZ

        local DD            = self.DamageData
        local DamageType    = DD.DamageType
        local radius        = DD.DamageRadius or 0
        
        local STRINGSUB     = STRINGSUB
        local TONUMBER      = TONUMBER

        if DD.DamageAmount then

            if DD.Buffs then
                self:DoUnitImpactBuffs( GetPosition(self), targetEntity )
            end		

            -- because shield effects directly change the damage table
            -- we'll take a copy of and use that instead
            if targetType == 'Shield' then
            
                local DD = LOUDCOPY(self.DamageData)

                -- LOUD ShieldMult effect
                if STRINGSUB(DamageType, 1, 10) == 'ShieldMult' then

                    local mult = TONUMBER( STRINGSUB(DamageType, 11) ) or 1
                    self.DamageData.DamageAmount = DD.DamageAmount * mult

                end
            end

            if ProjectileDialog then
        
                LOG("*AI DEBUG Projectile OnImpact targetType is "..repr(targetType).." damage data is "..repr(DD.DamageAmount).." at "..GetGameTick() )
            
                if targetEntity then
                    LOG("*AI DEBUG Projectile OnImpact Target entity is "..repr(targetEntity.BlueprintID)..repr(targetEntity))
                end
            end

            -- localize information for performance
            local vc = VectorCached
            vc[1], vc[2], vc[3] = EntityGetPositionXYZ(self)

            -- adjust the impact location based on the velocity of the thing we're hitting, this fixes a bug with damage being applied the tick after the collision
            -- is registered. As a result, the unit has moved one step ahead already, allowing it to 'miss' the area damage that we're trying to apply. Usually
            -- air units are affected by this, see also the pull request for a visual aid on this issue on Github
            if radius > 0 and targetEntity then
                if targetType == 'Unit' or targetType == 'UnitAir' then
                    local vx, vy, vz = targetEntity:GetVelocity()
                    vc[1] = vc[1] + vx
                    vc[2] = vc[2] + vy
                    vc[3] = vc[3] + vz
                elseif targetType == 'Shield' then
                    local vx, vy, vz = targetEntity.Owner:GetVelocity()
                    vc[1] = vc[1] + vx
                    vc[2] = vc[2] + vy
                    vc[3] = vc[3] + vz
                end
            end

            self:DoDamage( GetLauncher(self) or self, DD, targetEntity)
        end

        local bp = ALLBPS[self.BlueprintID]
        


        -- when simspeed drops too low turn off visual impact effects
        if Sync.SimData.SimSpeed > -1 then

            local ImpactEffects = false
            local ImpactEffectScale = 0.8     -- default scaling

            local army = self.Army

            --ImpactEffects
            if targetType == 'Shield' then
        
                ImpactEffects = self.FxImpactShield
                ImpactEffectScale = self.FxShieldHitScale
            
            elseif targetType == 'Unit' then
        
                ImpactEffects = self.FxImpactUnit
                ImpactEffectScale = self.FxUnitHitScale
            
            elseif targetType == 'UnitAir' then
        
                ImpactEffects = self.FxImpactAirUnit
                ImpactEffectScale = self.FxAirUnitHitScale
            
            elseif targetType == 'Terrain' then
        
                ImpactEffects = self.FxImpactLand
                ImpactEffectScale = self.FxLandHitScale
            
                if (self.FxImpactLandScorch) then
            
                    CreateRandomScorchSplatAtObject(self, self.FxImpactLandScorchScale, 110, 20, army)
                
                end
            
            elseif targetType == 'Prop' then
        
                ImpactEffects = self.FxImpactProp
                ImpactEffectScale = self.FxPropHitScale

            elseif targetType == 'Water' then
        
                ImpactEffects = self.FxImpactWater
                ImpactEffectScale = self.FxWaterHitScale

            elseif targetType == 'Underwater' then
        
                ImpactEffects = self.FxImpactUnderWater
                ImpactEffectScale = self.FxUnderWaterHitScale

            elseif  targetType == 'UnitUnderwater' then
        
                ImpactEffects = self.FxImpactUnitUnderWater or self.FxImpactUnderWater
                ImpactEffectScale = self.FxUnderWaterHitScale

            elseif targetType == 'Air' then
        
                ImpactEffects = self.FxImpactNone
                ImpactEffectScale = self.FxNoneHitScale
            
            elseif targetType == 'Projectile' then
        
                ImpactEffects = self.FxImpactProjectile
                ImpactEffectScale = self.FxProjectileHitScale
            
            elseif targetType == 'ProjectileUnderwater' then
        
                ImpactEffects = self.FxImpactProjectileUnderWater or self.FxImpactProjectile
                ImpactEffectScale = self.FxUnderWaterHitScale			
            
            end

            if ImpactEffects then
            
                if targetType != 'Shield' then

                    self:CreateImpactEffects( army, ImpactEffects, ImpactEffectScale )
                end
            end
            
            local ImpactEffectsType = bp.Display.ImpactEffects.Type

            if ImpactEffectsType then

                local TerrainType = DefaultTerrainType
            
                if TerrainType.FXImpact[targetType][ImpactEffectsType] == nil then
                    TerrainType = DefaultTerrainType
                end
            
                local TerrainEffect = TerrainType.FXImpact[targetType][ImpactEffectsType] or false
            
                if TerrainEffect[1] then

                    if ProjectileDialog then
                        LOG("*AI DEBUG CollisionBeam UpdateTerrainCollisionEffects is "..repr(TerrainType.Description).." impact type "..repr(self.TerrainImpactType).." table data is "..repr(TerrainType.FXImpact[targetType][ImpactEffectsType]).." "..repr(TerrainEffect) )
                    end
            
                    if not BeenDestroyed(self) then
                        ForkTo( self.CreateTerrainEffects, self, army, TerrainEffect, bp.Display.ImpactEffects.Scale or 1 )
                    end
                end
            end
        end

        -- Railgun damage drops by 20% per target it collides with
        if DamageType == 'Railgun' then
            
            local DD = LOUDCOPY(self.DamageData)

            DD.DamageAmount = DD.DamageAmount * 0.8
            
            bp.Physics.ImpactTimeout = 0.1
        else
        
            self:SetCollisionShape( 'none' )

        end
        
        local Audio = bp.Audio['Impact'..targetType] or bp.Audio.Impact or false
        
        if Audio then
            PlaySound( self, Audio )
        end
        
        local ImpactTimeout = bp.Physics.ImpactTimeout

        if ImpactTimeout and (targetType == 'Terrain' or targetType == 'Air' or targetType == 'Underwater') then
        
            ForkTo( self.ImpactTimeoutThread, self, ImpactTimeout )
            
        else

            if DamageType != 'Railgun' then
                self:OnImpactDestroy( targetType, targetEntity)
            end 
        end
        
    end,
}