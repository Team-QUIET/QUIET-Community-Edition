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

        -- Start shield projection thread
        self:ForkThread(self.ShieldProjectionThread)
    end,

    -- Get energy cost for shielding a specific unit
    GetUnitShieldCost = function(self, unit)
        local bp = unit:GetBlueprint()

        -- Check categories in order of specificity
        if EntityCategoryContains(categories.BATTLESHIP, unit) then
            return EnergyCostPerUnitType.BATTLESHIP
        elseif EntityCategoryContains(categories.BATTLECRUISER, unit) then
            return EnergyCostPerUnitType.BATTLECRUISER
        elseif EntityCategoryContains(categories.CARRIER, unit) then
            return EnergyCostPerUnitType.CARRIER
        elseif EntityCategoryContains(categories.CRUISER, unit) then
            return EnergyCostPerUnitType.CRUISER
        elseif EntityCategoryContains(categories.DESTROYER, unit) then
            return EnergyCostPerUnitType.DESTROYER
        elseif EntityCategoryContains(categories.FRIGATE, unit) then
            return EnergyCostPerUnitType.FRIGATE
        elseif EntityCategoryContains(categories.SUBMARINE, unit) then
            return EnergyCostPerUnitType.SUBMARINE
        else
            return EnergyCostPerUnitType.DEFAULT
        end
    end,

    -- Calculate total energy for all projected units
    UpdateProjectionEnergy = function(self)
        local totalCost = 0

        for entityId, unit in self.ProjectedUnits do
            if unit and not unit.Dead then
                totalCost = totalCost + self:GetUnitShieldCost(unit)
            end
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

        -- Wait for shield to initialize
        WaitTicks(20)

        while not self.Dead do
            -- Find allied naval units within projection radius (exclude self)
            local allunits = aiBrain:GetUnitsAroundPoint(categories.NAVAL, self:GetPosition(), projectionRadius, 'Ally')
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

                -- Project shields onto allies that don't have one from us
                for i, unit in targetunits do
                    if not (unit.Projectors and unit.Projectors[self:GetEntityId()])
                       and not unit.MyShield then
                        self:CreateProjectedShieldBubble(unit)
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

