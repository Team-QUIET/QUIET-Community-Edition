-- WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] * QUIET Hook for Unit.lua' )
-- This warning allows us to see exactly where our Hook Line starts so we can debug the exact line thats causing an error easier

local DynamicCosts = import('/mods/QUIET-Community-Edition/lua/system/DynamicFactoryUpgradeCosts.lua')

-- Store original blueprint data and tracking for upgrade costs
local OriginalBlueprints = {}
local UnitsWithModifiedCosts = {}

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

    -- Hook into the OnStartBuild method to implement Dynamic Factory Upgrade Cost to replicate
    -- HQ System without having to use the HQ System from FAF
    OnStartBuild = function(self, unitBeingBuilt, order)
        
        -- Check if this is an upgrade order
        if order == 'Upgrade' then
            local brain = self:GetAIBrain()
            local unitId = unitBeingBuilt:GetUnitId()
            local upgradeBlueprint = __blueprints[unitId]

            -- Check if this is a first-time factory upgrade
            if upgradeBlueprint then
                local isFirstUpgrade = DynamicCosts.IsFirstFactoryUpgrade(brain, upgradeBlueprint)

                if isFirstUpgrade then
                    -- Apply modified costs for first-time upgrade
                    local modifiedCosts = DynamicCosts.GetFirstUpgradeCosts(upgradeBlueprint)

                    if modifiedCosts then
                        -- Store original blueprint data if not already stored
                        local blueprintId = unitId
                        if not OriginalBlueprints[blueprintId] then
                            OriginalBlueprints[blueprintId] = {
                                BuildTime = upgradeBlueprint.Economy.BuildTime,
                                BuildCostMass = upgradeBlueprint.Economy.BuildCostMass,
                                BuildCostEnergy = upgradeBlueprint.Economy.BuildCostEnergy,
                            }
                        end

                        -- Apply modified costs to blueprint
                        upgradeBlueprint.Economy.BuildTime = modifiedCosts.BuildTime
                        upgradeBlueprint.Economy.BuildCostMass = modifiedCosts.BuildCostMass
                        upgradeBlueprint.Economy.BuildCostEnergy = modifiedCosts.BuildCostEnergy

                        -- Track this unit for cost restoration
                        UnitsWithModifiedCosts[self.EntityID] = {
                            blueprintId = blueprintId,
                            factoryType = DynamicCosts.GetFactoryType(upgradeBlueprint),
                            techLevel = DynamicCosts.GetTechLevel(upgradeBlueprint),
                        }

                        -- LOG("*QUIET* First " .. (UnitsWithModifiedCosts[self.EntityID].factoryType or "UNKNOWN") ..
                        --     " T" .. (UnitsWithModifiedCosts[self.EntityID].techLevel or "?") ..
                        --     " factory upgrade - applying increased costs: " ..
                        --     "BuildTime=" .. modifiedCosts.BuildTime ..
                        --     ", Mass=" .. modifiedCosts.BuildCostMass ..
                        --     ", Energy=" .. modifiedCosts.BuildCostEnergy)

                        -- Show floating text to inform the player
                        local factoryType = UnitsWithModifiedCosts[self.EntityID].factoryType or "UNKNOWN"
                        local techLevel = UnitsWithModifiedCosts[self.EntityID].techLevel or "?"
                        local message = "First " .. factoryType .. " T" .. techLevel .. " Upgrade\n" ..
                                      "Time: " .. math.floor(modifiedCosts.BuildTime) .. "s, " ..
                                      "Mass: " .. math.floor(modifiedCosts.BuildCostMass) .. ", " ..
                                      "Energy: " .. math.floor(modifiedCosts.BuildCostEnergy)

                        FloatingEntityText(self.EntityID, message)

                        -- Schedule cost restoration after the upgrade starts
                        ForkThread(function()
                            WaitTicks(5) -- Wait a few ticks for the upgrade to start

                            -- Restore original costs so future upgrades use normal costs
                            if OriginalBlueprints[blueprintId] then
                                upgradeBlueprint.Economy.BuildTime = OriginalBlueprints[blueprintId].BuildTime
                                upgradeBlueprint.Economy.BuildCostMass = OriginalBlueprints[blueprintId].BuildCostMass
                                upgradeBlueprint.Economy.BuildCostEnergy = OriginalBlueprints[blueprintId].BuildCostEnergy

                                -- LOG("*QUIET* Restored original costs for " .. blueprintId)
                            end
                        end)
                    end
                end
            end
        end

        -- Call the original OnStartBuild method
        return QCEUnit.OnStartBuild(self, unitBeingBuilt, order)
    end,

    -- Hook into OnStopBeingBuilt to mark first factory built
    OnStopBeingBuilt = function(self, builder, layer)

        -- Check if this unit had modified costs during upgrade
        local unitData = UnitsWithModifiedCosts[self.EntityID]
        if unitData then

            -- Mark that this player has built their first factory of this type
            local brain = self:GetAIBrain()
            DynamicCosts.MarkFirstFactoryBuilt(brain, unitData.factoryType, unitData.techLevel)

            -- LOG("*QUIET* Marked first " .. unitData.factoryType .. " T" .. unitData.techLevel ..
            --     " factory as built for player " .. brain:GetArmyIndex())

            -- Remove from tracking
            UnitsWithModifiedCosts[self.EntityID] = nil
        end

        -- Call the original OnStopBeingBuilt method
        return QCEUnit.OnStopBeingBuilt(self, builder, layer)
    end,

}