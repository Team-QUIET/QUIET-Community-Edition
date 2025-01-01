local CStructureUnit = import('/lua/defaultunits.lua').StructureUnit

local CANNaniteTorpedoWeapon = import('/lua/cybranweapons.lua').CANNaniteTorpedoWeapon

URB2109 = ClassUnit(CStructureUnit) {
    Weapons = {
        Turret01 = ClassWeapon(CANNaniteTorpedoWeapon) {},
    },
}

TypeClass = URB2109