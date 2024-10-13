local SZhanaseeBombProjectile = import('/lua/seraphimprojectiles.lua').SZhanaseeBombProjectile

local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local CreateDecal = CreateDecal
local CreateLightParticle = CreateLightParticle
local DamageArea = DamageArea

SBOZhanaseeBombProjectile01 = Class(SZhanaseeBombProjectile){

    OnImpact = function(self, TargetType, TargetEntity)   
        CreateLightParticle(self, -1, self:GetArmy(), 26, 5, 'sparkle_white_add_08', 'ramp_white_24' )
        
        self:CreateProjectile('/effects/entities/SBOZhanaseeBombEffect01/SBOZhanaseeBombEffect01_proj.bp', 0, 0, 0, 0, 10.0, 0):SetCollision(false):SetVelocity(0,10.0, 0)
        self:CreateProjectile('/effects/entities/SBOZhanaseeBombEffect02/SBOZhanaseeBombEffect02_proj.bp', 0, 0, 0, 0, 0.05, 0):SetCollision(false):SetVelocity(0,0.05, 0)
        
        if TargetType == 'Terrain' then

            local pos = self:GetPosition()

            DamageArea( self, pos, self.DamageData.DamageRadius, 1, 'Force', true )
            DamageArea( self, pos, self.DamageData.DamageRadius, 1, 'Force', true )              

            CreateDecal( pos, RandomFloat(0.0,6.28), 'Scorch_012_albedo', '', 'Albedo', 40, 40, 300, 200, self:GetArmy())          
        end
        
		SZhanaseeBombProjectile.OnImpact(self, TargetType, TargetEntity) 
        
    end,
}
TypeClass = SBOZhanaseeBombProjectile01
