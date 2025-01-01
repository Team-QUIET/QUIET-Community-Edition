local TWalkingLandUnit = import('/lua/defaultunits.lua').WalkingLandUnit

local TerranWeaponFile = import('/lua/terranweapons.lua')

local TDFIonizedPlasmaCannon = TerranWeaponFile.TDFIonizedPlasmaCannon
local TDFPlasmaCannonWeapon = TerranWeaponFile.TDFPlasmaCannonWeapon
local TAALinkedRailgun = TerranWeaponFile.TAALinkedRailgun
local TAMPhalanxWeapon = import('/lua/terranweapons.lua').TAMPhalanxWeapon

local CreateBoneEffects = import('/lua/effectutilities.lua').CreateBoneEffects

local Effects = import('/lua/effecttemplates.lua')

WEL0305 = ClassUnit(TWalkingLandUnit) {

    Weapons = {
    
        PlasmaCannon01 = ClassWeapon(TDFIonizedPlasmaCannon) {},
        
		GatlingCannon = ClassWeapon(TDFPlasmaCannonWeapon) {
        
			PlayFxWeaponPackSequence = function(self)
            
                if self.SpinManip then
                    self.SpinManip:SetTargetSpeed(0)
                end
                
                self.ExhaustEffects = CreateBoneEffects( self.unit, 'Gatgun2', self.unit.Army, Effects.WeaponSteam01 )
				self.ExhaustEffects = CreateBoneEffects( self.unit, 'GatGunBarrel2', self.unit.Army, Effects.WeaponSteam01 )
				self.ExhaustEffects = CreateBoneEffects( self.unit, 'GatGunMuzzle01', self.unit.Army, Effects.WeaponSteam01 )
                
                TDFPlasmaCannonWeapon.PlayFxWeaponPackSequence(self)
            end,
        
            PlayFxRackSalvoChargeSequence = function(self)
            
                if not self.SpinManip then 
                    self.SpinManip = CreateRotator(self.unit, 'GatGunBarrel2', 'z', nil, 270, 180, 60)
                    self.unit.Trash:Add(self.SpinManip)
                end
                
                self.SpinManip:SetTargetSpeed(500)
                
                TDFPlasmaCannonWeapon.PlayFxRackSalvoChargeSequence(self)
            end,            
            
            PlayFxRackSalvoReloadSequence = function(self)
            
                if self.SpinManip then
                    self.SpinManip:SetTargetSpeed(200)
                end
                
                self.ExhaustEffects = CreateBoneEffects( self.unit, 'Gatgun2', self.unit.Army, Effects.WeaponSteam01 )
				self.ExhaustEffects = CreateBoneEffects( self.unit, 'GatGunBarrel2', self.unit.Army, Effects.WeaponSteam01 )
				self.ExhaustEffects = CreateBoneEffects( self.unit, 'GatGunMuzzle01', self.unit.Army, Effects.WeaponSteam01 )
                
                TDFPlasmaCannonWeapon.PlayFxRackSalvoChargeSequence(self)
            end,
		},
        
		AA = ClassWeapon(TAALinkedRailgun) {},
        
		TML = ClassWeapon(TAMPhalanxWeapon) {},
    },
}

TypeClass = WEL0305