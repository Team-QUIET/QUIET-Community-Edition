local WeaponFile = import('/lua/sim/DefaultWeapons.lua')
local DefaultProjectileWeapon = WeaponFile.DefaultProjectileWeapon
local MultiTargetAAMixin = import('/mods/QUIET-Community-Edition/lua/QCEMultiTargetAA.lua').MultiTargetAAMixin

local EffectTemplate = import('/lua/EffectTemplates.lua')

TerranTargetPainter = ClassWeapon(DefaultBeamWeapon) {
    FxMuzzleFlash = {},
}

---@class TSAMLauncherMultiTarget : DefaultProjectileWeapon
TSAMLauncherMultiTarget = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TAAMissileLaunch,

    BuildAATargetTable = MultiTargetAAMixin.BuildAATargetTable,
    GetNextAATarget = MultiTargetAAMixin.GetNextAATarget,
    HasValidTargets = MultiTargetAAMixin.HasValidTargets,

    CreateProjectileForWeapon = function(self, bone)
        return MultiTargetAAMixin.CreateProjectileForWeaponMultiAA(self, bone, DefaultProjectileWeapon.CreateProjectileForWeapon)
    end,
}

---@class TAASerpentine2WeaponMultiTarget : DefaultProjectileWeapon
TAASerpentine2WeaponMultiTarget = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/terran_sam_launch_01_emit.bp',
    },

    BuildAATargetTable = MultiTargetAAMixin.BuildAATargetTable,
    GetNextAATarget = MultiTargetAAMixin.GetNextAATarget,
    HasValidTargets = MultiTargetAAMixin.HasValidTargets,

    CreateProjectileForWeapon = function(self, bone)
        return MultiTargetAAMixin.CreateProjectileForWeaponMultiAA(self, bone, DefaultProjectileWeapon.CreateProjectileForWeapon)
    end,
}