-- ****************************************************************************
-- **
-- **  File     :  /cdimage/units/UAL0401/UAL0401_script.lua
-- **  Author(s):  John Comes, Gordon Duclos
-- **
-- **  Summary  :  Aeon Galactic Colossus Script
-- **
-- **  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************
local AWalkingLandUnit = import('/lua/defaultunits.lua').WalkingLandUnit
local WeaponsFile = import('/lua/terranweapons.lua')
local AWeapons = import('/lua/aeonweapons.lua')
local TMAnovacatbluelaserweapon = AWeapons.TMAnovacatbluelaserweapon
local TDFGaussCannonWeapon = WeaponsFile.TDFLandGaussCannonWeapon
local ADFCannonOblivionWeapon = AWeapons.ADFCannonOblivionWeapon
local AAAZealotMissileWeapon = AWeapons.AAAZealotMissileWeapon
local EffectTemplate = import('/lua/EffectTemplates.lua')
--local TMEffectTemplate = import('/mods/TotalMayhem/lua/TMEffectTemplates.lua')
local AANChronoTorpedoWeapon = AWeapons.AANChronoTorpedoWeapon

BROT3HADES = ClassUnit(AWalkingLandUnit) {
	Weapons = {
		laserblue = ClassWeapon(TMAnovacatbluelaserweapon) {
		},
		laserblue2 = ClassWeapon(TMAnovacatbluelaserweapon) {
		},
		Torpedo2 = ClassWeapon(AANChronoTorpedoWeapon) {
		},
		MainGun = ClassWeapon(TDFGaussCannonWeapon) {  
			FxMuzzleFlashScale = 3.95,
			FxMuzzleFlash = EffectTemplate.ASDisruptorCannonChargeMuzzle01,
		}, 
		MainGun2 = ClassWeapon(TDFGaussCannonWeapon) {  
			FxMuzzleFlashScale = 3.95,
			FxMuzzleFlash = EffectTemplate.ASDisruptorCannonChargeMuzzle01,
		}, 
		MainGun3 = ClassWeapon(ADFCannonOblivionWeapon) {  
			FxMuzzleFlashScale = 2,
		}, 
		AntiAirMissiles2 = ClassWeapon(AAAZealotMissileWeapon) {
		},
		robottalk = ClassWeapon(AAAZealotMissileWeapon) {
			FxMuzzleFlashScale = 0,
		},
	}, 

	OnStopBeingBuilt = function(self,builder,layer)
		AWalkingLandUnit.OnStopBeingBuilt(self,builder,layer)
		if self:GetAIBrain().BrainType == 'Human' and IsUnit(self) then
			self:SetWeaponEnabledByLabel('robottalk', false)
		else
			self:SetWeaponEnabledByLabel('robottalk', true)
		end      
	end,

	OnKilled = function(self, instigator, damagetype, overkillRatio)
		AWalkingLandUnit.OnKilled(self, instigator, damagetype, overkillRatio)
		self:CreatTheEffectsDeath()  
	end,


	CreatTheEffectsDeath = function(self)
		local army =  self:GetArmy()
		for k, v in EffectTemplate['SZthuthaamArtilleryHit'] do
			self.Trash:Add(CreateAttachedEmitter(self, 'BROT3HADES', army, v):ScaleEmitter(6.85))
		end
		-- for k, v in TMEffectTemplate['AeonUnitDeathRing03'] do
		-- 	self.Trash:Add(CreateAttachedEmitter(self, 'Turret', army, v):ScaleEmitter(3.25))
		-- end
		-- for k, v in TMEffectTemplate['UEFDeath01'] do
		-- 	self.Trash:Add(CreateAttachedEmitter(self, 'Turret', army, v):ScaleEmitter(1.85))
		-- end
	end,
}
TypeClass = BROT3HADES