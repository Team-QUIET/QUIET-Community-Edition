local WeaponFile = import('/lua/sim/DefaultWeapons.lua')
local DefaultProjectileWeapon = WeaponFile.DefaultProjectileWeapon
local MultiTargetAAMixin = import('/mods/QUIET-Community-Edition/lua/QCEMultiTargetAA.lua').MultiTargetAAMixin

local EffectTemplate = import('/lua/EffectTemplates.lua')

SeraphimTargetPainter = ClassWeapon(DefaultBeamWeapon) {
    FxMuzzleFlash = {},
}

---@class SAAShleoCannonWeaponMultiTarget : DefaultProjectileWeapon
SAAShleoCannonWeaponMultiTarget = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SShleoCannonMuzzleFlash,

    BuildAATargetTable = MultiTargetAAMixin.BuildAATargetTable,
    GetNextAATarget = MultiTargetAAMixin.GetNextAATarget,
    HasValidTargets = MultiTargetAAMixin.HasValidTargets,

    CreateProjectileForWeapon = function(self, bone)
        return MultiTargetAAMixin.CreateProjectileForWeaponMultiAA(self, bone, DefaultProjectileWeapon.CreateProjectileForWeapon)
    end,
}

---@class SAAOlarisCannonWeaponMultiTarget : DefaultProjectileWeapon
SAAOlarisCannonWeaponMultiTarget = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SOlarisCannonMuzzleFlash01,
    FxChargeEffects = EffectTemplate.SOlarisCannonMuzzleCharge,

    BuildAATargetTable = MultiTargetAAMixin.BuildAATargetTable,
    GetNextAATarget = MultiTargetAAMixin.GetNextAATarget,
    HasValidTargets = MultiTargetAAMixin.HasValidTargets,

    CreateProjectileForWeapon = function(self, bone)
        return MultiTargetAAMixin.CreateProjectileForWeaponMultiAA(self, bone, DefaultProjectileWeapon.CreateProjectileForWeapon)
    end,
}

---@class SAALosaareAutoCannonWeaponMultiTarget : DefaultProjectileWeapon
SAALosaareAutoCannonWeaponMultiTarget = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SLosaareAutoCannonMuzzleFlash,

    BuildAATargetTable = MultiTargetAAMixin.BuildAATargetTable,
    GetNextAATarget = MultiTargetAAMixin.GetNextAATarget,
    HasValidTargets = MultiTargetAAMixin.HasValidTargets,

    CreateProjectileForWeapon = function(self, bone)
        return MultiTargetAAMixin.CreateProjectileForWeaponMultiAA(self, bone, DefaultProjectileWeapon.CreateProjectileForWeapon)
    end,
}