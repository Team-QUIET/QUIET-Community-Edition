local WalkingLandUnit = import('/lua/defaultunits.lua').WalkingLandUnit
local SDFAireauBolterWeapon = import('/lua/seraphimweapons.lua').SDFAireauBolterWeapon

BRPT2BTBOT = ClassUnit(WalkingLandUnit) {
    Weapons = {
        MainGun = ClassWeapon(SDFAireauBolterWeapon) {},
        MainGun2 = ClassWeapon(SDFAireauBolterWeapon) {},
    },
}

TypeClass = BRPT2BTBOT
