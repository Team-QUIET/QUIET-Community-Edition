local CStructureUnit = import('/lua/defaultunits.lua').StructureUnit

local CANNaniteTorpedoWeapon = import('/lua/cybranweapons.lua').CANNaniteTorpedoWeapon

URB2205 = ClassUnit(CStructureUnit) {

    Weapons = {
        TorpedoLauncher = ClassWeapon(CANNaniteTorpedoWeapon) { FxMuzzleFlashScale = 0.5 },
    },
}

TypeClass = URB2205