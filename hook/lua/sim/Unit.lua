-- WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] * QUIET Hook for Unit.lua' )
-- This warning allows us to see exactly where our Hook Line starts so we can debug the exact line thats causing an error easier

-- Helper function to identify HQ factory properties from categories
local function GetHQFactoryInfo(cats)
    if not cats then
        return nil, nil, nil
    end

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
    local isHQFactory = isT2HQ or isT3HQ

    if not isHQFactory then
        return false, nil, nil
    end

    -- Determine factory type
    local factoryType = nil
    if hasLand then
        factoryType = "LAND"
    elseif hasAir then
        factoryType = "AIR"
    elseif hasNaval then
        factoryType = "NAVAL"
    end

    -- Determine tech level
    local techLevel = nil
    if hasTech2 then
        techLevel = 2
    elseif hasTech3 then
        techLevel = 3
    end

    return isHQFactory, factoryType, techLevel
end

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
                self:CreateUnitDestructionDebris( true, true, false )
            end
        end
            
		self:CreateWreckage( overkillRatio )

        WaitTicks( (self.DeathThreadDestructionWaitTime or 0.1) * 10 )

        self:Destroy()
        --LOG("Hello, I am QUIET CE Unit Lua. Welcome to the Journey, Young Sir!")
    end,

    -- Called by the weapon class, these are expensive!
    OnGotTarget = function(self, Weapon) end,

    -- Called by the weapon class, these are expensive!
    OnLostTarget = function(self, Weapon) end,

    -- Hook OnStartBuild to detect when an HQ factory is upgrading
    OnStartBuild = function(self, unitBeingBuilt, order)
        -- Check if this HQ factory is upgrading to a higher tier
        if order == 'Upgrade' and self.IsHQFactory and self.HQFactoryType and self.HQTechLevel then
            -- Mark that this HQ is upgrading, we'll handle removal when the new HQ finishes
            self.IsUpgradingHQ = true
            -- Transfer our HQ info to the unit being built so it knows it's an upgrade
            unitBeingBuilt.UpgradedFromHQ = self
        end

        -- Call the original OnStartBuild method
        return QCEUnit.OnStartBuild(self, unitBeingBuilt, order)
    end,

    -- Hook OnStopBeingBuilt to track HQ factory completion
    OnStopBeingBuilt = function(self, builder, layer)
        -- Check if this is an HQ factory that just finished building
        local brain = self:GetAIBrain()
        local blueprint = self:GetBlueprint()
        local cats = blueprint.Categories

        local isHQFactory, factoryType, techLevel = GetHQFactoryInfo(cats)

        --LOG("*QUIET* OnStopBeingBuilt - isHQFactory: " .. tostring(isHQFactory) ..
        --    ", factoryType: " .. tostring(factoryType) ..
        --    ", techLevel: " .. tostring(techLevel))

        if isHQFactory and factoryType and techLevel and brain then
            -- Store HQ factory info on the unit for use in OnKilled/OnReclaimed
            self.IsHQFactory = true
            self.HQFactoryType = factoryType
            self.HQTechLevel = techLevel

            -- Check if this was an upgrade from an older HQ
            if self.UpgradedFromHQ and self.UpgradedFromHQ.IsHQFactory then
                local oldHQ = self.UpgradedFromHQ
                -- Remove the old HQ from tracking BEFORE adding the new one
                if brain.RemoveHQFactory then
                    brain:RemoveHQFactory(oldHQ.HQFactoryType, "TECH" .. oldHQ.HQTechLevel)
                end
                -- Clear the old HQ's flags so it won't be removed again
                oldHQ.IsHQFactory = false
                self.UpgradedFromHQ = nil
            end

            -- Check if brain has AddHQFactory method
            if brain.AddHQFactory then
                -- Add HQ factory to brain tracking
                brain:AddHQFactory(factoryType, "TECH" .. techLevel)

                --LOG("*QUIET* HQ Factory completed: " .. factoryType .. " T" .. techLevel ..
                --    " for player " .. brain:GetArmyIndex())
            else
                LOG("*QUIET* ERROR: brain.AddHQFactory method not found!")
            end
        end

        -- Call the original OnStopBeingBuilt method
        return QCEUnit.OnStopBeingBuilt(self, builder, layer)
    end,

    -- Hook OnKilled to track HQ factory destruction
    OnKilled = function(self, instigator, type, overkillRatio)
        -- Check if this was an HQ factory and notify the brain
        if self.IsHQFactory and self.HQFactoryType and self.HQTechLevel then
            local brain = self:GetAIBrain()
            if brain and brain.RemoveHQFactory then
                brain:RemoveHQFactory(self.HQFactoryType, "TECH" .. self.HQTechLevel)

                --LOG("*QUIET* HQ Factory destroyed (killed): " .. self.HQFactoryType ..
                --    " T" .. self.HQTechLevel .. " for player " .. brain:GetArmyIndex())
            end
        end

        -- Call the original OnKilled method
        return QCEUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

    -- Hook OnReclaimed to track HQ factory reclamation (same as destruction for restrictions)
    OnReclaimed = function(self, entity)
        -- Check if this was an HQ factory and notify the brain
        if self.IsHQFactory and self.HQFactoryType and self.HQTechLevel then
            local brain = self:GetAIBrain()
            if brain and brain.RemoveHQFactory then
                brain:RemoveHQFactory(self.HQFactoryType, "TECH" .. self.HQTechLevel)

                --LOG("*QUIET* HQ Factory reclaimed: " .. self.HQFactoryType ..
                --    " T" .. self.HQTechLevel .. " for player " .. brain:GetArmyIndex())
            end
        end

        -- Call the original OnReclaimed method if it exists
        if QCEUnit.OnReclaimed then
            return QCEUnit.OnReclaimed(self, entity)
        end
    end,

    -- Hook OnCaptured to handle HQ factory capture (transfer ownership)
    OnCaptured = function(self, captor)
        -- If this was an HQ factory, remove it from the original owner's tracking
        if self.IsHQFactory and self.HQFactoryType and self.HQTechLevel then
            local originalBrain = self:GetAIBrain()
            if originalBrain and originalBrain.RemoveHQFactory then
                originalBrain:RemoveHQFactory(self.HQFactoryType, "TECH" .. self.HQTechLevel)

                --LOG("*QUIET* HQ Factory captured (removed from original owner): " ..
                --    self.HQFactoryType .. " T" .. self.HQTechLevel ..
                --    " for player " .. originalBrain:GetArmyIndex())
            end
        end

        -- Call the original OnCaptured method if it exists
        if QCEUnit.OnCaptured then
            return QCEUnit.OnCaptured(self, captor)
        end
    end,

    -- Hook OnGiven to handle HQ factory being given to another player
    OnGiven = function(self, newUnit)
        -- The new unit will have OnStopBeingBuilt called automatically by the engine
        -- which will add it to the new owner's tracking.
        -- We need to remove it from the original owner's tracking here.
        if self.IsHQFactory and self.HQFactoryType and self.HQTechLevel then
            local originalBrain = self:GetAIBrain()
            if originalBrain and originalBrain.RemoveHQFactory then
                originalBrain:RemoveHQFactory(self.HQFactoryType, "TECH" .. self.HQTechLevel)

                --LOG("*QUIET* HQ Factory given away: " .. self.HQFactoryType ..
                --    " T" .. self.HQTechLevel .. " for player " .. originalBrain:GetArmyIndex())
            end
        end

        -- Call the original OnGiven method if it exists
        if QCEUnit.OnGiven then
            return QCEUnit.OnGiven(self, newUnit)
        end
    end,
}
