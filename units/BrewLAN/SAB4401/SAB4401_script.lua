--------------------------------------------------------------------------------
-- Description: Shield bubble projection unit
-- Author: Sean 'Balthazar' Wheeldon

local AShieldStructureUnit = import('/lua/defaultunits.lua').StructureUnit
local Shield = import('/lua/shield.lua').Shield

local CreateFlash = import('/lua/defaultexplosions.lua').CreateFlash
local EffectTemplate = import('/lua/EffectTemplates.lua')

SAB4401 = ClassUnit(AShieldStructureUnit) {

    ShieldEffects = {
        '/effects/emitters/aeon_shield_generator_t2_01_emit.bp',
        '/effects/emitters/aeon_shield_generator_t2_02_emit.bp',
        '/effects/emitters/aeon_shield_generator_t3_03_emit.bp',
        '/effects/emitters/aeon_shield_generator_t3_04_emit.bp',
    },

    OnStopBeingBuilt = function(self,builder,layer)
	
        AShieldStructureUnit.OnStopBeingBuilt(self,builder,layer)
		
        self:ForkThread(self.ShieldProjectionThread)

        self.Manipulators = {
            {'Ring_1', 'z', 45},
            {'Ring_3', 'z', 45},
            {'Gem', 'z', 45},
            {'Orb', 'x', 45},
            {'Orb', 'z', 45},
        }		

        self.ShieldEffectsBag = {}
    end,

    OnShieldEnabled = function(self)
	
        AShieldStructureUnit.OnShieldEnabled(self)
		
        self.ShieldProjectionEnabled = true
		
        if not self.Manipulators[1][4] then
		
            for i, v in self.Manipulators do
                v[4] = CreateRotator(self, v[1], v[2], nil, 0, v[3], v[3])
                self.Trash:Add(v[4])
            end
        end
		
        for i, v in self.Manipulators do
            v[4]:SetTargetSpeed(v[3])
        end
		
        for k, v in self.ShieldEffects do
            table.insert( self.ShieldEffectsBag, CreateAttachedEmitter( self, 0, self:GetArmy(), v ):ScaleEmitter(1.17) )
        end
    end,

    OnShieldDisabled = function(self)
	
        AShieldStructureUnit.OnShieldDisabled(self)
		
        self:ClearShieldProjections()
		
        self.ShieldProjectionEnabled = false
    end,

    ShieldProjectionThread = function(self)
	
		local aiBrain = self:GetAIBrain()
	
        while not self.Dead do
		
            if self.ShieldProjectionEnabled and self:ShieldIsOn() then --Both to cover all bases. Not all deactivation triggers hit the variable, and the function counts charging for activation as 'on'.

                local targetunits = aiBrain:GetUnitsAroundPoint(categories.STRUCTURE, self:GetPosition(), self:GetBlueprint().Defense.Shield.ShieldProjectionRadius or 60, 'Ally' )
				
                for i, unit in targetunits do
                    -- not self                                     -- not already targetted by this                  --is finished                        -- Not units with shields, except where created by Pillars but not already targeted by this
                    if unit:GetEntityId() ~= self:GetEntityId() and not unit.Projectors[self:GetEntityId()] and unit:GetFractionComplete() == 1 and (not unit.MyShield or unit.Projectors and not unit.Projectors[self:GetEntityId()]) then
                        self:CreateProjectedShieldBubble(unit)
                    end
                end
				
            elseif self.ShieldProjectionEnabled and not self:ShieldIsOn() then
			
                self:ClearShieldProjections()
                self.ShieldProjectionEnabled = false
                WaitTicks(11)
				
            else
			
                WaitTicks(11)
				
            end
			
            WaitTicks(10)
        end
		
    end,

    CreateProjectedShieldBubble = function(self, target)
	
        -- Create shield
        target:CreateProjectedShield(__blueprints.sab4401.Defense.TargetShield)

        -- Define self as projector of shield
        if not target.Projectors then target.Projectors = {} end
        target.Projectors[self:GetEntityId()] = self
    end,

    ClearShieldProjections = function(self)
	
        local aiBrain = self:GetAIBrain()
		
        local targetunits = aiBrain:GetUnitsAroundPoint(categories.STRUCTURE, self:GetPosition(), self:GetBlueprint().Defense.Shield.ShieldProjectionRadius or 60 )
		
        for i, unit in targetunits do
		
            if unit:GetEntityId() ~= self:GetEntityId() and unit.Projectors then
			
                unit.Projectors[self:GetEntityId()] = nil
				
                local keepshield = false
				
                for index, pillar in unit.Projectors do
				
                    if pillar then
                        keepshield = true
                        break
                    end
                end
				
                if not keepshield then
                    unit:DestroyShield()
                end
				
            end
			
        end

        --Stop the animations
        if self.Manipulators then

            for i, v in self.Manipulators do

                if v[4] then
                    v[4]:SetTargetSpeed(0)
                end
			
            end
            
        end
		
        --Kill the effects.
        if self.ShieldEffectsBag then
		
            for k, v in self.ShieldEffectsBag do
                v:Destroy()
            end
			
            self.ShieldEffectsBag = {}
        end
    end,

    DeathThread = function(self, overkillRatio, instigator)
	
        local army = self:GetArmy()
        local pos = self:GetPosition()
		
        self:PlayUnitSound('Destroyed')
		
        CreateFlash( self, 'Ring_1', 4.5, army )
		
        for i = 1, 3 do
            DamageArea(self, pos, 10, 1, 'Force', true)
            self:HideBone('Ring_' .. i, false)
            for k, v in EffectTemplate.ExplosionDebrisLrg01 do
                CreateAttachedEmitter( self, 'Base', army, v )
            end
        end
		
        if self.PlayDestructionEffects then
            self:CreateDestructionEffects( self, overkillRatio )
        end
		
        for i, v in self.Manipulators do
            if v[4] then
                v[4]:Destroy()
                v[4] = nil
            end
        end
		
        if overkillRatio <= 1.0 and self.DeathAnimManip then
            WaitFor(self.DeathAnimManip)
        end
		
        self:PlayUnitSound('Destroyed')
		
        CreateFlash( self, 'Ring_1', 4.5, army )
		
        self:CreateWreckage(overkillRatio)
        self:Destroy()
    end,

    OnDestroy = function(self)
        self:ClearShieldProjections()
        AShieldStructureUnit.OnDestroy(self)
    end,
}

TypeClass = SAB4401
