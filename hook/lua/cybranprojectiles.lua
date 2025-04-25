CKrilTorpedo = ClassProjectile(OnWaterEntryEmitterProjectile) {

    FxTrails        = {'/effects/emitters/torpedo_munition_trail_01_emit.bp',},
    FxTrailScale    = 0.8,
    TrailDelay      = 2,

    FxEnterWater= { '/effects/emitters/water_splash_ripples_ring_01_emit.bp'},
    FxSplashScale = 0.5,

    FxUnitHitScale          = 0.7,
    FxUnderWaterHitScale    = 1.1,
    
    FxImpactUnit                    = EffectTemplate.CMolecularRipperHit01,
    FxImpactUnitUnderWater          = EffectTemplate.CTorpedoUnitHit01,
    FxImpactProjectileUnderWater    = EffectTemplate.SUallTorpedoHit,

    OnCreate = function(self, inWater)
	
        OnWaterEntryEmitterProjectileOnCreate(self, inWater)
		
        if inWater then
        
            SetCollisionShape( self, 'Sphere', 0, 0, 0, 1.5)
            
        else
        
            self.OnExitWater(self)
        end
		
    end,	
   
    OnEnterWater = function(self)
    
        OnWaterEntryEmitterProjectileOnEnterWater(self)
        
        SetCollisionShape( self, 'Sphere', 0, 0, 0, 1.5)
        
        local bp = __blueprints[self.BlueprintID].Physics

        self:SetAcceleration( bp.Acceleration )                 -- restore blueprint accel
        
        self:ChangeZigZagFrequency( bp.ZigZagFrequency or 0 )   -- restore ZigZag

        StayUnderwater(self, bp.StayUnderwater)                 -- restore

		self:ForkThread(self.EnableTargetTrack)
		
    end,

	OnExitWater = function(self)
    
        OnWaterEntryEmitterProjectile.OnExitWater(self)
        
        SetCollisionShape( self, 'Sphere', 0, 0, 0, 0.5)
	
		TrackTarget(self,false)         -- stop tracking 
        
        self:SetAcceleration(-2)        -- slow down while in mid-air
        
        self:ChangeZigZagFrequency(0)   -- stop any zigzag action
		
	end,

	EnableTargetTrack = function(self)
	
		WaitTicks( 1 )
		
		TrackTarget(self,true)
	
	end,
	
}