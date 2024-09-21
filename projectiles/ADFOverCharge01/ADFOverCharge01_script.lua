
local EffectTemplate = import('/lua/EffectTemplates.lua')

local ALaserBotProjectile = import('/lua/aeonprojectiles.lua').ALaserBotProjectile
local ALaserBotProjectileOnCreate = ALaserBotProjectile.OnCreate
local ALaserBotProjectileOnImpact = ALaserBotProjectile.OnImpact

local OverchargeProjectile = import("/lua/sim/defaultprojectiles.lua").OverchargeProjectile
local OverchargeProjectileOnCreate = OverchargeProjectile.OnCreate
local OverchargeProjectileOnImpact = OverchargeProjectile.OnImpact

TDFOverCharge01 = Class(ALaserBotProjectile, OverchargeProjectile) {
    
    PolyTrail = '/effects/emitters/aeon_commander_overcharge_trail_01_emit.bp',
    FxTrails = EffectTemplate.ACommanderOverchargeFXTrail01,
    
    FxImpactUnit = EffectTemplate.ACommanderOverchargeHit01,
    FxImpactProp = EffectTemplate.ACommanderOverchargeHit01,
    FxImpactLand = EffectTemplate.ACommanderOverchargeHit01,

    ---@param self TDFOverCharge01
    OnCreate = function(self)
        ALaserBotProjectileOnCreate(self)
        OverchargeProjectileOnCreate(self)
    end,

    ---@param self TDFOverCharge01
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        -- we need to run this the overcharge logic before running the usual on impact because
        -- that is where the damage is determined
        OverchargeProjectileOnImpact(self, targetType, targetEntity)
        ALaserBotProjectileOnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = TDFOverCharge01

