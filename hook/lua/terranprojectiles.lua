TMissileCruiseProjectileCE1 = Class(SingleBeamProjectile) {

    FxTrails = EffectTemplate.TMissileExhaust03,
    FxTrailOffset = -0.8,
    BeamName = '/effects/emitters/missile_munition_exhaust_beam_01_emit.bp',

    FxImpactUnit = EffectTemplate.TMissileEffect09,
    FxUnitHitScale = 1.7,
    FxImpactProp = EffectTemplate.TMissileEffect09,
    FxPropHitScale = 1.7,
    FxImpactLand = EffectTemplate.TMissileEffect09,
    FxLandHitScale = 1.7,
    FxImpactUnderWater = EffectTemplate.TMissileEffect09,
    FxImpactWater = EffectTemplate.TMissileEffect09,

    OnImpact = function(self, targetType, targetEntity)

        SingleBeamProjectileOnImpact(self, targetType, targetEntity)
    end,   
}