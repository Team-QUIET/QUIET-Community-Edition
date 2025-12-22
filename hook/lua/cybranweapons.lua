local WeaponFile = import('/lua/sim/DefaultWeapons.lua')
local DefaultProjectileWeapon = WeaponFile.DefaultProjectileWeapon
local MultiTargetAAMixin = import('/mods/QUIET-Community-Edition/lua/QCEMultiTargetAA.lua').MultiTargetAAMixin

local EffectTemplate = import('/lua/EffectTemplates.lua')

CybranTargetPainter = ClassWeapon(DefaultBeamWeapon) {
    FxMuzzleFlash = {},
}

---@class CAANanoDartWeaponMultiTarget : DefaultProjectileWeapon
CAANanoDartWeaponMultiTarget = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/cannon_muzzle_flash_04_emit.bp',
        '/effects/emitters/cannon_muzzle_smoke_11_emit.bp',
    },

    BuildAATargetTable = MultiTargetAAMixin.BuildAATargetTable,
    GetNextAATarget = MultiTargetAAMixin.GetNextAATarget,
    HasValidTargets = MultiTargetAAMixin.HasValidTargets,

    CreateProjectileForWeapon = function(self, bone)
        return MultiTargetAAMixin.CreateProjectileForWeaponMultiAA(self, bone, DefaultProjectileWeapon.CreateProjectileForWeapon)
    end,
}
