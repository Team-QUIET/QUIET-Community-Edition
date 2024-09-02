-- Hook
-- Reason: Adjusting overkillRatio from 0.10 to 0.30 to allow more Wreckage to be created even if there large overkill, I.E T4 AA shooting down T2 Gunships.
Unit_LOUDCE = Unit
Unit = Class(Unit_LOUDCE) {

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