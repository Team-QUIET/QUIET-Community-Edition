local SWalkingLandUnit = import('/lua/defaultunits.lua').WalkingLandUnit

local SDFAireauBolterWeapon = import('/lua/seraphimweapons.lua').SDFAireauBolterWeapon

SSL0311 = ClassUnit(SWalkingLandUnit) {
    Weapons = {
        MainGun = ClassWeapon(SDFAireauBolterWeapon) {}
    },
}
TypeClass = SSL0311
