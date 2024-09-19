local CWalkingLandUnit = import('/lua/defaultunits.lua').WalkingLandUnit

local CDFLaserHeavyWeapon       = import('/lua/cybranweapons.lua').CDFLaserHeavyWeapon
local ScorpDisintegratorWeapon  = import('/mods/BlackOpsUnleashed/lua/BlackOpsweapons.lua').ScorpDisintegratorWeapon

local CreateCybranBuildBeams = import('/lua/EffectUtilities.lua').CreateCybranBuildBeams

local ScaleEmitter = moho.IEffect.ScaleEmitter
local TrashDestroy = TrashBag.Destroy

BRL0205 = Class(CWalkingLandUnit) {

    Weapons = {
    
        LaserArms = Class(CDFLaserHeavyWeapon) {
        
			OnWeaponFired = function(self, target)
            
				CDFLaserHeavyWeapon.OnWeaponFired(self, target)
                
			end,
			
			OnLostTarget = function(self)
            
				CDFLaserHeavyWeapon.OnLostTarget(self)

			end,
        },
		
        Disintigrator01 = Class(ScorpDisintegratorWeapon) {},
    },
    
    OnCreate = function(self)
    
        CWalkingLandUnit.OnCreate(self)
        
        self:SetMaintenanceConsumptionActive()
		
		if __blueprints[self.BlueprintID].General.BuildBones then
            self:SetupBuildBones()
        end
    end,
	
    CreateBuildEffects = function( self, unitBeingBuilt, order )

       CreateCybranBuildBeams( self, unitBeingBuilt, __blueprints[self.BlueprintID].General.BuildBones.BuildEffectBones, self.BuildEffectsBag )
       
    end,
    
    OnStopBuild = function( self, unitBeingBuilt )

        if self.BuildProjectile then
        
            for _, v in self.BuildProjectile do
            
                TrashDestroy( v.BuildEffectsBag )
   
                ScaleEmitter( v.Emitter, .1)
                ScaleEmitter( v.Sparker, .1)

                if v.Detached then
                    v:AttachTo( self, v.Name )
                end
   
                v.Detached = false
                
            end
        end
        
        CWalkingLandUnit.OnStopBuild( self, unitBeingBuilt )

    end,

    OnStopBeingBuilt = function(self, builder, layer)
    
        CWalkingLandUnit.OnStopBeingBuilt(self, builder, layer) 

		self:EnableUnitIntel('Cloak') 

    end,
}
TypeClass = BRL0205