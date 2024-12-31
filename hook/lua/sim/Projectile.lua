QCEProjectile = Projectile
Projectile = ClassProjectile(QCEProjectile) {
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