-- Hook
-- Reason: Adjusting overkillRatio from 0.10 to 0.30 to allow more Wreckage to be created even if there large overkill, I.E T4 AA shooting down T2 Gunships.
Unit_LOUDCE = Unit
Unit = Class(Unit_LOUDCE) {

    DoTakeDamage = function(self, instigator, amount, vector, damageType)

		local GetHealth = GetHealth
	
        local preAdjHealth = GetHealth(self)
		
        AdjustHealth( self, instigator, -amount)
		
        if GetHealth(self) < 1 then
		
            if damageType == 'Reclaimed' then
			
                self:Destroy()
				
            else
			
                local excessDamageRatio = 0.0
				
                -- Calculate the excess damage amount
                local excess = preAdjHealth - amount
                local maxHealth = EntityMethods.GetMaxHealth(self)
				
                if (excess < 0 and maxHealth > 0) then
				
                    excessDamageRatio = -excess / maxHealth
					
                end
				
                Kill( self, instigator, damageType, excessDamageRatio)
				
            end
			
        end

        -- Handle incoming OC damage for ACUs
        if damageType == 'Overcharge' and LOUDENTITY(categories.COMMAND, self) then

            local wep = instigator:GetWeaponByLabel('OverCharge')

            amount = wep:GetBlueprint().Overcharge.commandDamage
            
        end

        -- Handle incoming OC damage for Structures
        if damageType == 'Overcharge' and LOUDENTITY(categories.STRUCTURE, self) then

            local wep = instigator:GetWeaponByLabel('OverCharge')

            amount = wep:GetBlueprint().Overcharge.structureDamage
            
        end
		
		
        if not self.Dead and LOUDENTITY(categories.COMMAND, self) then
		
			GetAIBrain(self):OnPlayCommanderUnderAttackVO()
			
        end
		
    end,

    DeathThread = function( self, overkillRatio, instigator)

        if self.DeathAnimManip then
            WaitFor(self.DeathAnimManip)
        end

        self.PlayUnitSound(self,'Destroyed')		
        
        WaitTicks(2)
        
        if self.DamageEffectsBag then
            self:DestroyAllDamageEffects()
        end

        -- if simspeed too low suppress destruction effects --
        if Sync.SimData.SimSpeed > -1 then
        
            if self.PlayDestructionEffects then
                self:CreateDestructionEffects( overkillRatio )
            end
        
            if ( self.ShowUnitDestructionDebris and overkillRatio ) then
        
                if overkillRatio <= 0.30 then
                    self:CreateUnitDestructionDebris( true, true, false )
                else
                    self:CreateUnitDestructionDebris( false, true, true )
                end
            end
        end
        
        if overkillRatio <= 0.30 then
            self:CreateWreckage( overkillRatio )
        end

        WaitTicks( (self.DeathThreadDestructionWaitTime or 0.1) * 10 )

        self:Destroy()
        --LOG("Hello, I am LOUD CE Unit Lua. Welcome to the Journey, Young Sir!")
    end,

}