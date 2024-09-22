-- File     :  /data/projectiles/SDFChronatronCannon02/SDFChronatronCannon02_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  ChronatronCannon Projectile script, Seraphim commander overcharge, XSL0001
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------------------------

local ALaserBotProjectile = import('/lua/aeonprojectiles.lua').ALaserBotProjectile
local ALaserBotProjectileOnCreate = ALaserBotProjectile.OnCreate
local ALaserBotProjectileOnImpact = ALaserBotProjectile.OnImpact

local OverchargeProjectile = import("/lua/sim/defaultprojectiles.lua").OverchargeProjectile
local OverchargeProjectileOnCreate = OverchargeProjectile.OnCreate
local OverchargeProjectileOnImpact = OverchargeProjectile.OnImpact

local EffectTemplate = import("/lua/effecttemplates.lua")

TDFOverCharge01 = Class(ALaserBotProjectile, OverchargeProjectile) {
    PolyTrail = '/effects/emitters/aeon_commander_overcharge_trail_01_emit.bp',
    FxTrails = EffectTemplate.ACommanderOverchargeFXTrail01,

    -- Hit Effects
    FxImpactUnit = EffectTemplate.ACommanderOverchargeHit01,
    FxImpactProp = EffectTemplate.ACommanderOverchargeHit01,
    FxImpactLand = EffectTemplate.ACommanderOverchargeHit01,

    ---@param self TDFOverCharge01
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        -- we need to run this the overcharge logic before running the usual on impact because
        -- that is where the damage is determined
        OverchargeProjectileOnImpact(self, targetType, targetEntity)
        ALaserBotProjectileOnImpact(self, targetType, targetEntity)
    end,

    ---@param self TDFOverCharge01
    OnCreate = function(self)
        ALaserBotProjectileOnCreate(self)
        OverchargeProjectileOnCreate(self)
    end,
}

TypeClass = TDFOverCharge01

