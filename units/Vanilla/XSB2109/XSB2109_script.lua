local SStructureUnit = import('/lua/seraphimunits.lua').SStructureUnit

local Torpedo = import('/lua/seraphimweapons.lua').SANAnaitTorpedo

XSB2109 = ClassUnit(SStructureUnit) {

    Weapons = {
        Turret01 = ClassWeapon(Torpedo) {},
    },     

}

TypeClass = XSB2109