local SWalkingLandUnit = import('/lua/defaultunits.lua').WalkingLandUnit

local SDFAireauBolterWeapon = import('/lua/seraphimweapons.lua').SDFAireauBolterWeapon

SSL0311 = Class(SWalkingLandUnit) {
    Weapons = {
        MainGun = Class(SDFAireauBolterWeapon) {}
    },

    OnShieldIsUp = function (self)
        self:SetCanTakeDamage(false)
    end,

    OnShieldIsDown = function (self)
        self:SetCanTakeDamage(true) 
    end,
}
TypeClass = SSL0311
