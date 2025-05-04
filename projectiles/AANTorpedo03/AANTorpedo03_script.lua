local ATorpedoShipProjectile = import("/lua/aeonprojectiles.lua").ATorpedoShipProjectile
local ATorpedoShipProjectileOnCreate = ATorpedoShipProjectile.OnCreate
local ATorpedoShipProjectileOnEnterWater = ATorpedoShipProjectile.OnEnterWater

--- Aeon Torpedo Projectile script
---@class AANTorpedo03 : ATorpedoShipProjectile
AANTorpedo03 = ClassProjectile(ATorpedoShipProjectile) {
    FxTrail = import("/lua/effecttemplates.lua").ATorpedoPolyTrails01,

    ---@param self AANTorpedo03
    ---@param inWater boolean
    OnCreate = function(self, inWater)
        ATorpedoShipProjectileOnCreate(self, inWater)
        CreateTrail(self, -1, self.Army, import("/lua/effecttemplates.lua").ATorpedoPolyTrails01)
    end,

    ---@param self AANTorpedo03
    OnEnterWater = function(self)
        ATorpedoShipProjectileOnEnterWater(self)

        -- set the magnitude of the velocity to something tiny to really make that water
        -- impact slow it down. We need this to prevent torpedo's striking the bottom
        -- of a shallow pond, like in setons
        self:SetVelocity(0)
        self:SetAcceleration(0.5)
        self.Trash:Add(ForkThread(self.MovementThread, self))
    end,

    --- Adjusted movement thread to gradually speed up the torpedo. It needs to slowly speed
    --- up to prevent it from hitting the floor in relative undeep water
    ---@param self AANTorpedo03
    MovementThread = function(self)
        -- local scope for performance
        local WaitTicks = WaitTicks
        local IsDestroyed = IsDestroyed
        local ProjectileSetAcceleration = self.SetAcceleration

        for k = 1, 6 do
            WaitTicks(2)
            if not IsDestroyed(self) then
                ProjectileSetAcceleration(self, k)
            else
                break
            end
        end
    end,
}
TypeClass = AANTorpedo03
