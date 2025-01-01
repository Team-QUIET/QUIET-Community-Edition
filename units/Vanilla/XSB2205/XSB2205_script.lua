local Torpedo = import('/lua/seraphimweapons.lua').SANAnaitTorpedo

XSB2205 = ClassUnit(import('/lua/seraphimunits.lua').SStructureUnit) {

    Weapons = {
        TorpedoTurret = ClassWeapon(Torpedo) {},
        AntiTorpedo = ClassWeapon(import('/lua/seraphimweapons.lua').SDFAjelluAntiTorpedoDefense) {},
    },
	
}

TypeClass = XSB2205