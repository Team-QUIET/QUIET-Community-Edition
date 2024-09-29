local DefaultProjectile = import('/lua/sim/defaultprojectiles.lua')
local EffectTemplate = import('/lua/EffectTemplates.lua')

local EmitterProjectile                     = DefaultProjectile.EmitterProjectile

------------------
-- Aeon Prototype Hades ShoulderCannon
------------------
AeonBROT3HADES2proj = Class(EmitterProjectile) {

    FxTrails = EffectTemplate.SZthuthaamArtilleryProjectileFXTrails,
    FxTrailOffset = 0,
    PolyTrails = EffectTemplate.SZthuthaamArtilleryProjectilePolyTrails, 
    PolyTrailOffset = {0,0},
    FxImpactUnit = EffectTemplate.AQuantumCannonHit01,
    FxUnitHitScale = 2.55,
    FxImpactProp = EffectTemplate.AQuantumCannonHit01,
    FxPropHitScale = 2.55,
    FxImpactLand = EffectTemplate.AQuantumCannonHit01,
    FxLandHitScale = 2.55,
    FxImpactUnderWater = EffectTemplate.AQuantumCannonHit01,
    FxImpactWater = EffectTemplate.AQuantumCannonHit01,
    FxWaterHitScale = 2.55,
}

------------------
-- Aeon Prototype Hades cannons
------------------
AeonBROT3HADESproj = Class(EmitterProjectile) {
    FxTrails = {'/effects/emitters/oblivion_cannon_munition_01_emit.bp'},
    FxImpactUnit = EffectTemplate.AQuantumDisruptorHit01,
    FxUnitHitScale = 2.4,
    FxImpactProp = EffectTemplate.AQuantumDisruptorHit01,
    FxPropHitScale = 2.4,
    FxImpactLand = EffectTemplate.AQuantumDisruptorHit01,
    FxLandHitScale = 2.4,
    FxTrailOffset = 0,
    FxImpactUnderWater = {},
}