QCEAirUnit = AirUnit
AirUnit = ClassUnit(QCEAirUnit) {

    OnHealthChanged = function(self, new, old)

        -- if not self.Dead and new > 0 then
        
        --     local Fuel = self.HasFuel
        
        --     -- Health values come in at fixed 25% intervals
        --     if new < old then

        --         -- so at 50% damage air performance drops
        --         if old == 0.75 then
                
        --             if not HasBuff( self, 'HeavyDamageAir' ) then 
        --                 ApplyBuff( self, 'HeavyDamageAir' )
        --             end

        --         -- and below 25% it drops even more
        --         elseif old <= 0.5 then
                
        --             if not HasBuff( self, 'SevereDamageAir' ) then 
        --                 ApplyBuff( self, 'SevereDamageAir' )
        --             end
                    
        --         end
                
        --     else

        --         -- at 25% move performance back up 
        --         if new == 0.25 then
                
        --             if HasBuff( self, 'SevereDamageAir' ) then 
        --                 RemoveBuff( self, 'SevereDamageAir' )
        --             end
                    
        --         -- at 50% restore full performance
        --         elseif new >= 0.5 then
                
        --             if HasBuff( self, 'HeavyDamageAir' ) then 
        --                 RemoveBuff( self, 'HeavyDamageAir' )
        --             end

        --         end
        --     end
        -- end
        -- end
        -- UnitOnHealthChanged(self, new, old)
    end,	
}