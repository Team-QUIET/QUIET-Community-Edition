-- File     :  /data/projectiles/SDFChronatronCannon02/SDFChronatronCannon02_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  ChronatronCannon Projectile script, Seraphim commander overcharge, XSL0001
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------------------------

local TLaserBotProjectile = import('/lua/terranprojectiles.lua').TLaserBotProjectile
local OverchargeProjectile = import("/lua/sim/defaultprojectiles.lua").OverchargeProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")

TDFOverCharge01 = Class(TLaserBotProjectile, OverchargeProjectile) {
    FxTrails = EffectTemplate.TCommanderOverchargeFXTrail01,
    FxTrailScale = 1.0,

	-- Hit Effects
    FxImpactUnit =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactProp =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactLand =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactAirUnit =  EffectTemplate.TCommanderOverchargeHit01,
    
    ---@param self TDFOverCharge01
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        -- we need to run this the overcharge logic before running the usual on impact because that is where the damage is determined
        OverchargeProjectile.OnImpact(self, targetType, targetEntity)
        TLaserBotProjectile.OnImpact(self, targetType, targetEntity)
    end,

    ---@param self TDFOverCharge01
    OnCreate = function(self)
        TLaserBotProjectile.OnCreate(self)
        OverchargeProjectile.OnCreate(self)
    end,
}

TypeClass = TDFOverCharge01

