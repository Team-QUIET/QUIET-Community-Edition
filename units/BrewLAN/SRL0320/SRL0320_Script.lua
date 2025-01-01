local CLandUnit = import('/lua/defaultunits.lua').MobileUnit

local CAAMissileNaniteWeapon = import('/lua/sim/DefaultWeapons.lua').DefaultProjectileWeapon

local EffectUtil = import('/lua/EffectUtilities.lua')

SRL0320 = ClassUnit(CLandUnit) {

	IntelEffects = { { Bones = { 0 }, Offset = { 0, 1, 0 }, Type = 'Jammer01' } },

	Weapons = {

		MainGun = ClassWeapon(CAAMissileNaniteWeapon) {

			CreateProjectileAtMuzzle = function(self, muzzle)

			    -- if self.IntelOn then
			    --     self.IntelOn = nil
			    --     self:SetMaintenanceConsumptionInactive()
			    --     self:SetScriptBit('RULEUTC_CloakToggle', true)
			    --     self:DisableUnitIntel('Cloak')
			    --     self:RequestRefreshUI()
			    --     self.IntelWasOn = true
			    -- end

			    CAAMissileNaniteWeapon.CreateProjectileAtMuzzle(self, muzzle)
			end,

			OnWeaponFired = function(self)

				-- if self.IntelWasOn then
			    --     self.IntelOn = true
			    --     self:SetMaintenanceConsumptionActive()
			    --     self:SetScriptBit('RULEUTC_CloakToggle', false)
			    --     self:EnableUnitIntel('Cloak')
			    --     self:RequestRefreshUI()
			    --     self.IntelWasOn = nil
			    -- end

			    CAAMissileNaniteWeapon.OnWeaponFired(self)

			end,
			
		},
	},

	OnStopBeingBuilt = function(self, builder, layer)
		CLandUnit.OnStopBeingBuilt(self, builder, layer)

		if true then
			self.IntelOn = true
			self:SetMaintenanceConsumptionActive()
			self:SetScriptBit('RULEUTC_CloakToggle', false)
			self:EnableUnitIntel('Cloak')
			self:RequestRefreshUI()
			self.IntelWasOn = nil
		end
	end,

	OnIntelEnabled = function(self)
		CLandUnit.OnIntelEnabled(self)

		if self.IntelEffects and not self.IntelFxOn and self.IntelOn then
			self:PlaySound(self:GetBlueprint().Audio.Cloak)
			self.IntelEffectsBag = {}
			self.CreateTerrainTypeEffects(self, self.IntelEffects, 'FXIdle', self:GetCurrentLayer(), nil, self.IntelEffectsBag)
			self.IntelFxOn = true
		end
	end,

	OnIntelDisabled = function(self)
		CLandUnit.OnIntelDisabled(self)

		if self.IntelFxOn == true then
			self:PlaySound(self:GetBlueprint().Audio.Decloak)
			EffectUtil.CleanupEffectBag(self, 'IntelEffectsBag')
			self.IntelFxOn = nil
		end
	end,

	OnScriptBitSet = function(self, bit)
		if bit == 8 then -- cloak toggle
			self.IntelOn = nil
		end

		CLandUnit.OnScriptBitSet(self, bit)
	end,

	OnScriptBitClear = function(self, bit)
		if bit == 8 then -- cloak toggle
			self.IntelOn = true
		end

		CLandUnit.OnScriptBitClear(self, bit)
	end,
}

TypeClass = SRL0320
