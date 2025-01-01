local TStructureUnit = import('/lua/defaultunits.lua').StructureUnit

local TANTorpedoAngler = import('/lua/terranweapons.lua').TANTorpedoAngler

UEB2109 = ClassUnit(TStructureUnit) {
    Weapons = {
        Turret01 = ClassWeapon(TANTorpedoAngler) {},
    },
}

TypeClass = UEB2109

