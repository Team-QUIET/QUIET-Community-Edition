-- WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] * QUIET Hook for Unit.lua' )
-- This warning allows us to see exactly where our Hook Line starts so we can debug the exact line thats causing an error easier

QCEUnit = Unit
Unit = ClassUnit(QCEUnit) {

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
        --LOG("Hello, I am QUIET CE Unit Lua. Welcome to the Journey, Young Sir!")
    end,

    -- Called by the weapon class, these are expensive!
    OnGotTarget = function(self, Weapon) end,

    -- Called by the weapon class, these are expensive!
    OnLostTarget = function(self, Weapon) end,

    -- Hook OnStopBeingBuilt to track HQ factory completion
    OnStopBeingBuilt = function(self, builder, layer)
        -- Check if this is an HQ factory that just finished building using categories
        local brain = self:GetAIBrain()
        local blueprint = self:GetBlueprint()
        local cats = blueprint.Categories

        -- Check if this is an HQ factory using category search
        -- T2 HQ factories have: BUILTBYTIER1FACTORY + FACTORY + STRUCTURE + TECH2 + RESEARCH + LAND/AIR/NAVAL
        -- T3 HQ factories have: BUILTBYTIER2FACTORY + FACTORY + STRUCTURE + TECH3 + RESEARCH + LAND/AIR/NAVAL
        local isHQFactory = false
        local factoryType = nil
        local techLevel = nil

        if cats then
            local hasFactory = false
            local hasStructure = false
            local hasBuiltByT1 = false
            local hasBuiltByT2 = false
            local hasResearch = false
            local hasTech2 = false
            local hasTech3 = false
            local hasLand = false
            local hasAir = false
            local hasNaval = false

            -- Check all categories
            for _, category in cats do
                if category == 'FACTORY' then
                    hasFactory = true
                elseif category == 'STRUCTURE' then
                    hasStructure = true
                elseif category == 'BUILTBYTIER1FACTORY' then
                    hasBuiltByT1 = true
                elseif category == 'BUILTBYTIER2FACTORY' then
                    hasBuiltByT2 = true
                elseif category == 'RESEARCH' then
                    hasResearch = true
                elseif category == 'TECH2' then
                    hasTech2 = true
                elseif category == 'TECH3' then
                    hasTech3 = true
                elseif category == 'LAND' then
                    hasLand = true
                elseif category == 'AIR' then
                    hasAir = true
                elseif category == 'NAVAL' then
                    hasNaval = true
                end
            end

            -- Determine if this is an HQ factory
            -- T2 HQ: BUILTBYTIER1FACTORY + FACTORY + STRUCTURE + TECH2 + RESEARCH + layer
            -- T3 HQ: BUILTBYTIER2FACTORY + FACTORY + STRUCTURE + TECH3 + RESEARCH + layer
            local isT2HQ = hasFactory and hasStructure and hasBuiltByT1 and hasResearch and hasTech2
            local isT3HQ = hasFactory and hasStructure and hasBuiltByT2 and hasResearch and hasTech3

            isHQFactory = isT2HQ or isT3HQ

            -- Determine factory type
            if hasLand then
                factoryType = "LAND"
            elseif hasAir then
                factoryType = "AIR"
            elseif hasNaval then
                factoryType = "NAVAL"
            end

            -- Determine tech level
            if hasTech2 then
                techLevel = 2
            elseif hasTech3 then
                techLevel = 3
            end
        end

        if isHQFactory and factoryType and techLevel and brain then
            -- Add HQ factory to brain tracking
            brain:AddHQFactory(factoryType, "TECH" .. techLevel)

            --LOG("*QUIET* First " .. factoryType .. " T" .. techLevel ..
            --    " HQ factory completed - Support Factories unlocked for player " .. brain:GetArmyIndex())
        end

        -- Call the original OnStopBeingBuilt method
        return QCEUnit.OnStopBeingBuilt(self, builder, layer)
    end,
}