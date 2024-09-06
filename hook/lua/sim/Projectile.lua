--- A dummy projectile that solely inherits what it needs. Useful for
-- effects that require projectiles without additional overhead.
--  Credit to Jip (FAF) for GC TractorClaw Rework

-- Upvalue for Performance
local EntityGetBlueprint = _G.moho.entity_methods.GetBlueprint
local EntityGetArmy = _G.moho.entity_methods.GetArmy

---@class DummyProjectile : moho.projectile_methods
DummyProjectile = Class(moho.projectile_methods) {

    ---@param self DummyProjectile
    ---@param inWater? boolean
    OnCreate = function(self, inWater)
        -- expected to be cached by all projectiles
        self.bp = EntityGetBlueprint(self)
        self.Army = EntityGetArmy(self)
    end,

    ---@param self DummyProjectile
    ---@param targetType string
    ---@param targetEntity Unit | Prop
    OnImpact = function(self, targetType, targetEntity)
        self:Destroy()
    end,
}