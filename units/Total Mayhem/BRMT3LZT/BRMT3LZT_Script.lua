-- BRMT3LZT Trilobyte - Amphibious AA/Support Tank
-- Weapon toggle between AA (default) and Ground fire modes
-- Both weapons stay enabled, we control firing via FireTargetLayerCaps

local TLandUnit = import('/lua/defaultunits.lua').MobileUnit
local CDFHeavyDisintegratorWeapon = import('/lua/cybranweapons.lua').CDFHeavyDisintegratorWeapon

BRMT3LZT = ClassUnit(TLandUnit) {

    Weapons = {
        AAGun = ClassWeapon(CDFHeavyDisintegratorWeapon) {},
        GroundGun = ClassWeapon(CDFHeavyDisintegratorWeapon) {},
    },

    OnCreate = function(self)
        TLandUnit.OnCreate(self)
        self.GroundMode = false
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        TLandUnit.OnStopBeingBuilt(self, builder, layer)
        -- Start in AA mode - ground weapon can't target anything
        self:GetWeaponByLabel('GroundGun'):SetFireTargetLayerCaps('None')
    end,

    OnScriptBitSet = function(self, bit)
        TLandUnit.OnScriptBitSet(self, bit)
        if bit == 1 then
            self.GroundMode = true
            -- Ground mode: disable AA targeting, enable ground targeting
            self:GetWeaponByLabel('AAGun'):SetFireTargetLayerCaps('None')
            self:GetWeaponByLabel('GroundGun'):SetFireTargetLayerCaps('Land|Water|Seabed')
        end
    end,

    OnScriptBitClear = function(self, bit)
        TLandUnit.OnScriptBitClear(self, bit)
        if bit == 1 then
            self.GroundMode = false
            -- AA mode: disable ground targeting, enable AA targeting
            self:GetWeaponByLabel('AAGun'):SetFireTargetLayerCaps('Air')
            self:GetWeaponByLabel('GroundGun'):SetFireTargetLayerCaps('None')
        end
    end,
}

TypeClass = BRMT3LZT

