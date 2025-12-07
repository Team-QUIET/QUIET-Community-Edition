local SeaUnit = import('/lua/defaultunits.lua').SeaUnit
local SeraphimWeapons = import('/lua/seraphimweapons.lua')
local SAAOlarisCannonWeapon = SeraphimWeapons.SAAOlarisCannonWeapon
local SDFAireauBolterWeapon = SeraphimWeapons.SDFAireauBolterWeapon

-- Energy cost multipliers per unit type
local EnergyCostPerUnitType = {
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
        AntiAirMissiles = ClassWeapon(SAAOlarisCannonWeapon) {},
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
        if cats['BATTLESHIP'] then
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

            if hasTargets then
                -- We have allies to project to
                if not self.IsProjectingShields then
                    -- Start projecting - disable personal shield
                    self.IsProjectingShields = true

                    -- Disable personal shield
                    if self.MyShield then
                        self.MyShield:TurnOff()
                    end
                end

                -- Count current projections
                local currentCount = 0
                for _ in self.ProjectedUnits do
                    currentCount = currentCount + 1
                end

                -- Project shields onto allies that don't have one from us (up to cap)
                for i, unit in targetunits do
                    if currentCount >= maxShieldedUnits then
                        break
                    end
                    if not (unit.Projectors and unit.Projectors[self:GetEntityId()])
                       and not unit.MyShield then
                        self:CreateProjectedShieldBubble(unit)
                        currentCount = currentCount + 1
                    end
                end

                -- Clean up projections on units that moved out of range
                self:CleanupOutOfRangeProjections(projectionRadius)

                -- Update energy consumption based on what we're shielding
                self:UpdateProjectionEnergy()

            else
                -- No allies nearby
                if self.IsProjectingShields then
                    -- Stop projecting - enable personal shield
                    self:ClearAllProjections()
                    self.IsProjectingShields = false

                    -- Re-enable personal shield
                    if self.MyShield then
                        self.MyShield:TurnOn()
                    end

                    -- Reset energy to base
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

