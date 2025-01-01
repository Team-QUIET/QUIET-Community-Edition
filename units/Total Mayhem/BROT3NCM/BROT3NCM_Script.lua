local AWalkingLandUnit = import('/lua/defaultunits.lua').WalkingLandUnit

local TMWeaponsFile     = import('/mods/TotalMayhem/lua/TMAeonWeapons.lua')

local TMAmizurabluelaserweapon      = TMWeaponsFile.TMAmizurabluelaserweapon
local TMAnovacatbluelaserweapon     = TMWeaponsFile.TMAnovacatbluelaserweapon
local TMAnovacatgreenlaserweapon    = TMWeaponsFile.TMAnovacatgreenlaserweapon

TMWeaponsFile = nil

local MicrowaveLaser            = import('/lua/cybranweapons.lua').CDFHeavyMicrowaveLaserGeneratorCom
local TIFCommanderDeathWeapon   = import('/lua/terranweapons.lua').TIFCommanderDeathWeapon
local AAAZealotMissileWeapon    = import('/lua/aeonweapons.lua').AAAZealotMissileWeapon

local MissileRedirect = import('/lua/defaultantiprojectile.lua').MissileTorpDestroy

local TrashAdd = TrashBag.Add


BROT3NCM = ClassUnit(AWalkingLandUnit) {

    Weapons = {

        MainLaser = ClassWeapon(TMAnovacatgreenlaserweapon) {FxMuzzleFlashScale = 0.5},	

        laserblu = ClassWeapon(TMAnovacatbluelaserweapon) {FxMuzzleFlashScale = 0},
        laserred = ClassWeapon(MicrowaveLaser) {FxMuzzleFlashScale = 0},
        lasermix = ClassWeapon(TMAmizurabluelaserweapon) {FxMuzzleFlashScale = 0},

        AAMissiles = ClassWeapon(AAAZealotMissileWeapon) {},
		
        robottalk = ClassWeapon(AAAZealotMissileWeapon) { FxMuzzleFlashScale = 0 },
		
        DeathWeapon = ClassWeapon(TIFCommanderDeathWeapon) {},
    },
	
	OnStopBeingBuilt = function(self,builder,layer)

        AWalkingLandUnit.OnStopBeingBuilt(self,builder,layer)

        -- create MissileTorp Defense emitter
        local bp = __blueprints[self.BlueprintID].Defense.MissileTorpDestroy
        
        for _,v in bp.AttachBone do

            local antiMissile1 = MissileRedirect { Owner = self, Radius = bp.Radius, AttachBone = v, RedirectRateOfFire = bp.RedirectRateOfFire }

            TrashAdd( self.Trash, antiMissile1)
            
        end

	end,
}
TypeClass = BROT3NCM