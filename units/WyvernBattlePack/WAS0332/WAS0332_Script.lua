local SeaUnit = import('/lua/defaultunits.lua').SeaUnit
local SeraphimWeapons = import('/lua/seraphimweapons.lua')
local AeonWeapons = import('/lua/aeonweapons.lua')
local SDFAireauBolterWeapon = SeraphimWeapons.SDFAireauBolterWeapon
local AAAZealotMissileWeaponMultiTarget = AeonWeapons.AAAZealotMissileWeaponMultiTarget

-- Energy cost multipliers per unit type
local EnergyCostPerUnitType = {
    EXPERIMENTAL = 400,
    BATTLESHIP = 200,
    BATTLECRUISER = 150,
    CARRIER = 150,
    CRUISER = 80,
    DESTROYER = 50,
    FRIGATE = 25,
    SUBMARINE = 40,
    DEFAULT = 30,
}

WAS0332 = ClassUnit(SeaUnit) {

    Weapons = {
        MainGun = ClassWeapon(SDFAireauBolterWeapon) {},
        AntiAirMissiles = ClassWeapon(AAAZealotMissileWeaponMultiTarget) {},
    },

    OnStopBeingBuilt = function(self, builder, layer)
        SeaUnit.OnStopBeingBuilt(self, builder, layer)

        self.IsProjectingShields = false
        self.ProjectedUnits = {}
        self.BaseEnergyMaint = self:GetBlueprint().Economy.MaintenanceConsumptionPerSecondEnergy or 100
        self.CurrentProjectionEnergy = 0

        -- Enable personal shield on spawn
        if self.MyShield then
            self.MyShield:TurnOn()
        end

        -- Start shield projection thread
        self:ForkThread(self.ShieldProjectionThread)
    end,

    -- Get energy cost for shielding a specific unit
    GetUnitShieldCost = function(self, unit)
        if not unit or unit.Dead then
            return EnergyCostPerUnitType.DEFAULT
        end

        local bp = unit:GetBlueprint()
        if not bp or not bp.Categories then
            return EnergyCostPerUnitType.DEFAULT
        end

        -- Build category lookup from blueprint
        local cats = {}
        for _, cat in bp.Categories do
            cats[cat] = true
        end

        -- Check categories in order of specificity
        if cats['EXPERIMENTAL'] then
            return EnergyCostPerUnitType.EXPERIMENTAL
        elseif cats['BATTLESHIP'] then
            return EnergyCostPerUnitType.BATTLESHIP
        elseif cats['BATTLECRUISER'] then
            return EnergyCostPerUnitType.BATTLECRUISER
        elseif cats['CARRIER'] then
            return EnergyCostPerUnitType.CARRIER
        elseif cats['CRUISER'] then
            return EnergyCostPerUnitType.CRUISER
        elseif cats['DESTROYER'] then
            return EnergyCostPerUnitType.DESTROYER
        elseif cats['FRIGATE'] then
            return EnergyCostPerUnitType.FRIGATE
        elseif cats['SUBMARINE'] then
            return EnergyCostPerUnitType.SUBMARINE
        else
            return EnergyCostPerUnitType.DEFAULT
        end
    end,

    -- Calculate total energy for all projected units
    UpdateProjectionEnergy = function(self)
        local totalCost = 0
        local unitsToRemove = {}

        for entityId, unit in self.ProjectedUnits do
            if unit and not unit.Dead and unit.GetBlueprint then
                totalCost = totalCost + self:GetUnitShieldCost(unit)
            else
                table.insert(unitsToRemove, entityId)
            end
        end

        for _, entityId in unitsToRemove do
            self.ProjectedUnits[entityId] = nil
        end

        self.CurrentProjectionEnergy = totalCost
        
        -- Set new energy consumption (base + projection costs)
        local newEnergy = self.BaseEnergyMaint + totalCost
        self:SetConsumptionPerSecondEnergy(newEnergy)
        self:SetConsumptionActive(true)
    end,

    ShieldProjectionThread = function(self)
        local aiBrain = self:GetAIBrain()
        local bp = self:GetBlueprint()
        local projectionRadius = bp.Defense.Shield.ShieldProjectionRadius or 50
        local maxShieldedUnits = bp.Defense.Shield.MaxShieldedUnits or 6

        -- Initialize cooldown tracking for units that lost shields
        self.ShieldProjectionCooldownTime = 0

        -- Wait for shield to initialize
        WaitTicks(20)

        while not self.Dead do
            -- Find allied naval units within projection radius (exclude self and structures)
            local allunits = aiBrain:GetUnitsAroundPoint(categories.NAVAL - categories.STRUCTURE, self:GetPosition(), projectionRadius, 'Ally')
            local targetunits = {}

            for i, unit in allunits do
                if unit:GetEntityId() ~= self:GetEntityId()
                   and unit:GetFractionComplete() == 1
                   and not unit.Dead then
                    table.insert(targetunits, unit)
                end
            end

            local hasTargets = table.getn(targetunits) > 0

            -- Clean up projections on units that moved out of range
            self:CleanupOutOfRangeProjections(projectionRadius)

            -- Count current projections after cleanup
            local currentCount = 0
            for _ in self.ProjectedUnits do
                currentCount = currentCount + 1
            end

            if hasTargets then
                -- Check if we're still in cooldown from a shield being destroyed
                local currentTick = GetGameTick()
                local inCooldown = self.ShieldProjectionCooldownTime and currentTick < self.ShieldProjectionCooldownTime

                if not inCooldown then
                    -- Project shields onto allies that don't have one from us (up to cap)
                    for i, unit in targetunits do
                        if currentCount >= maxShieldedUnits then
                            break
                        end
                        -- Skip units we're already projecting to or that have their own shield
                        if not (unit.Projectors and unit.Projectors[self:GetEntityId()])
                           and not unit.MyShield then
                            self:CreateProjectedShieldBubble(unit)
                            currentCount = currentCount + 1
                        end
                    end
                end
            end

            -- Check if we're actually projecting to anyone
            local actuallyProjecting = false
            for _ in self.ProjectedUnits do
                actuallyProjecting = true
                break
            end

            if actuallyProjecting then
                -- We are projecting - disable personal shield
                if not self.IsProjectingShields then
                    self.IsProjectingShields = true
                    if self.MyShield then
                        self.MyShield:TurnOff()
                    end
                end
                self:UpdateProjectionEnergy()
            else
                -- Not projecting to anyone - enable personal shield
                if self.IsProjectingShields then
                    self:ClearAllProjections()
                    self.IsProjectingShields = false
                    if self.MyShield then
                        self.MyShield:TurnOn()
                    end
                    self:UpdateProjectionEnergy()
                end
            end

            WaitTicks(15)
        end
    end,

    CreateProjectedShieldBubble = function(self, target)
        local bp = self:GetBlueprint()
        local targetShieldSpec = bp.Defense.TargetShield

        if targetShieldSpec and not target.Dead then
            -- Create shield on target unit
            target:CreateProjectedShield(targetShieldSpec)

            -- Factory units (like Tempest) don't auto-enable shields, for some dumb ass reason
            if target.MyShield and EntityCategoryContains(categories.FACTORY, target) then
                target:SetFocusEntity(target.MyShield)
                target:EnableShield()
            end

            -- Track this projector on the target
            if not target.Projectors then target.Projectors = {} end
            target.Projectors[self:GetEntityId()] = self

            -- Track projected unit on self
            self.ProjectedUnits[target:GetEntityId()] = target
        end
    end,

    CleanupOutOfRangeProjections = function(self, radius)
        local myPos = self:GetPosition()

        for entityId, unit in self.ProjectedUnits do
            if unit.Dead then
                self.ProjectedUnits[entityId] = nil
            else
                local unitPos = unit:GetPosition()
                local dist = VDist3(myPos, unitPos)

                if dist > radius then
                    -- Unit moved out of range, remove our projection
                    if unit.Projectors then
                        unit.Projectors[self:GetEntityId()] = nil

                        -- Check if any other projectors remain
                        local keepshield = false
                        for idx, proj in unit.Projectors do
                            if proj and not proj.Dead then
                                keepshield = true
                                break
                            end
                        end

                        if not keepshield then
                            unit:DestroyShield()
                        end
                    end
                    self.ProjectedUnits[entityId] = nil
                end
            end
        end
    end,

    ClearAllProjections = function(self)
        for entityId, unit in self.ProjectedUnits do
            if unit and not unit.Dead and unit.Projectors then
                unit.Projectors[self:GetEntityId()] = nil

                -- Check if any other projectors remain
                local keepshield = false
                for idx, proj in unit.Projectors do
                    if proj and not proj.Dead then
                        keepshield = true
                        break
                    end
                end

                if not keepshield then
                    unit:DestroyShield()
                end
            end
        end
        self.ProjectedUnits = {}
    end,

    OnDestroy = function(self)
        self:ClearAllProjections()
        SeaUnit.OnDestroy(self)
    end,
}

TypeClass = WAS0332

