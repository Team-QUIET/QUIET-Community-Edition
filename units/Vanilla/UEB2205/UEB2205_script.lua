local TStructureUnit = import('/lua/defaultunits.lua').StructureUnit
local TANTorpedoAngler = import('/lua/terranweapons.lua').TANTorpedoAngler

UEB2205 = ClassUnit(TStructureUnit) {

    Weapons = {
        TorpedoLauncher = ClassWeapon(TANTorpedoAngler) {},
    },

}

TypeClass = UEB2205