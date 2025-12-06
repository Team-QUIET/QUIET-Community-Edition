-- WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] * QUIET Hook for AIBrain.lua' )
-- This warning allows us to see exactly where our Hook Line starts so we can debug the exact line thats causing an error easier

-- upvalue scope for performance
local categories = categories
local AddBuildRestriction = AddBuildRestriction
local RemoveBuildRestriction = RemoveBuildRestriction

-- Store original brain class
QCEAIBrain = AIBrain
AIBrain = Class(QCEAIBrain) {

    -- Initialize HQ Factory tracking when brain is created
    OnCreateAI = function(self, planName)
        -- Call original function first
        QCEAIBrain.OnCreateAI(self, planName)

        self:InitializeHQFactoryTracking()
    end,

    -- Also initialize on OnCreateHuman for human players
    OnCreateHuman = function(self, planName)
        -- Call original function first
        if QCEAIBrain.OnCreateHuman then
            QCEAIBrain.OnCreateHuman(self, planName)
        end

        self:InitializeHQFactoryTracking()
    end,

    -- Initialize HQ Factory tracking system
    InitializeHQFactoryTracking = function(self)
        -- Initialize tracking tables with counts (not booleans) to track multiple HQs
        self.HQFactoryCounts = {
            LAND = { TECH2 = 0, TECH3 = 0 },
            AIR = { TECH2 = 0, TECH3 = 0 },
            NAVAL = { TECH2 = 0, TECH3 = 0 },
        }

        -- Restrict all support factories by default
        local army = self:GetArmyIndex()
        AddBuildRestriction(army,
            (categories.TECH3 + categories.TECH2) * categories.SUPPORTFACTORY)

        -- Also restrict T3 HQ factories (they require T2 HQ first)
        AddBuildRestriction(army,
            categories.TECH3 * categories.FACTORY * categories.STRUCTURE * categories.RESEARCH)
    end,

    -- Add HQ factory (called when HQ factory finishes building)
    AddHQFactory = function(self, layer, tech)
        if not self.HQFactoryCounts then
            LOG("*QUIET* AddHQFactory: Initializing tracking for player " .. self:GetArmyIndex())
            self:InitializeHQFactoryTracking()
        end

        if self.HQFactoryCounts[layer] and self.HQFactoryCounts[layer][tech] ~= nil then
            -- Increment count
            self.HQFactoryCounts[layer][tech] = self.HQFactoryCounts[layer][tech] + 1

            --LOG("*QUIET* AddHQFactory: Added HQ Factory " .. layer .. " " .. tech ..
            --    " for player " .. self:GetArmyIndex() ..
            --    " (total: " .. self.HQFactoryCounts[layer][tech] .. ")")

            -- Unlock support factories and potentially T3 HQ factories
            self:UnlockHQCapabilities(layer, tech)
        else
            LOG("*QUIET* ERROR: Failed to add HQ Factory " .. layer .. " " .. tech ..
                " for player " .. self:GetArmyIndex() .. " - tracking not initialized properly")
        end
    end,

    -- Remove HQ factory (called when HQ factory is destroyed or reclaimed)
    RemoveHQFactory = function(self, layer, tech)
        if not self.HQFactoryCounts then
            LOG("*QUIET* RemoveHQFactory: No tracking initialized for player " .. self:GetArmyIndex())
            return
        end

        if self.HQFactoryCounts[layer] and self.HQFactoryCounts[layer][tech] ~= nil then
            -- Decrement count (don't go below 0)
            if self.HQFactoryCounts[layer][tech] > 0 then
                self.HQFactoryCounts[layer][tech] = self.HQFactoryCounts[layer][tech] - 1
            end

            local newCount = self.HQFactoryCounts[layer][tech]

            --LOG("*QUIET* RemoveHQFactory: Removed HQ Factory " .. layer .. " " .. tech ..
            --    " for player " .. self:GetArmyIndex() ..
            --    " (remaining: " .. newCount .. ")")

            -- If no HQ factories of this type remain, apply restrictions
            if newCount == 0 then
                self:ApplyHQLossRestrictions(layer, tech)
            end
        else
            LOG("*QUIET* ERROR: Failed to remove HQ Factory " .. layer .. " " .. tech ..
                " for player " .. self:GetArmyIndex() .. " - tracking not initialized properly")
        end
    end,

    -- Unlock capabilities when HQ is built
    UnlockHQCapabilities = function(self, layer, tech)
        local army = self:GetArmyIndex()

        if tech == "TECH2" then
            -- T2 HQ built: unlock T2 support factories for this layer
            RemoveBuildRestriction(army,
                categories[layer] * categories.TECH2 * categories.SUPPORTFACTORY)

            -- Unlock T3 HQ factory building for this layer
            RemoveBuildRestriction(army,
                categories[layer] * categories.TECH3 * categories.FACTORY * categories.STRUCTURE * categories.RESEARCH)

            --LOG("*QUIET* UnlockHQCapabilities: Unlocked T2 support factories and T3 HQ for " ..
            --    layer .. " for player " .. army)
        end

        if tech == "TECH3" then
            -- T3 HQ built: unlock T3 support factories for this layer
            -- (Also ensures T2 support factories remain unlocked)
            RemoveBuildRestriction(army,
                categories[layer] * categories.TECH2 * categories.SUPPORTFACTORY)
            RemoveBuildRestriction(army,
                categories[layer] * categories.TECH3 * categories.SUPPORTFACTORY)

            --LOG("*QUIET* UnlockHQCapabilities: Unlocked T3 support factories for " ..
            --    layer .. " for player " .. army)
        end
    end,

    -- Apply restrictions when HQ is lost
    ApplyHQLossRestrictions = function(self, layer, tech)
        local army = self:GetArmyIndex()

        if tech == "TECH2" then
            -- T2 HQ destroyed and no more T2 HQs of this layer:
            -- 1. Restrict building new T2 support factories
            AddBuildRestriction(army,
                categories[layer] * categories.TECH2 * categories.SUPPORTFACTORY)

            -- 2. Restrict building T3 HQ factories (T2 HQ is prerequisite)
            AddBuildRestriction(army,
                categories[layer] * categories.TECH3 * categories.FACTORY * categories.STRUCTURE * categories.RESEARCH)

            -- 3. Restrict T2 units from being built by existing T2 support factories
            -- This is done by restricting T2 mobile units built by T2 factories
            AddBuildRestriction(army,
                categories.BUILTBYTIER2FACTORY * categories[layer] * categories.MOBILE * categories.TECH2)

            -- 4. Also restrict T2 structures built by T2 factories for this layer
            AddBuildRestriction(army,
                categories.BUILTBYTIER2SUPPORTFACTORY * categories[layer] * categories.STRUCTURE)

            -- 5. If there are no T3 HQs either, restrict T3 support factories too
            if self.HQFactoryCounts[layer]["TECH3"] == 0 then
                AddBuildRestriction(army,
                    categories[layer] * categories.TECH3 * categories.SUPPORTFACTORY)
            end

            --LOG("*QUIET* ApplyHQLossRestrictions: Applied T2 HQ loss restrictions for " ..
            --    layer .. " for player " .. army)
        end

        if tech == "TECH3" then
            -- T3 HQ destroyed and no more T3 HQs of this layer:
            -- 1. Restrict building new T3 support factories
            AddBuildRestriction(army,
                categories[layer] * categories.TECH3 * categories.SUPPORTFACTORY)

            -- 2. Restrict T3 units from being built by existing T3 support factories
            AddBuildRestriction(army,
                categories.BUILTBYTIER3FACTORY * categories[layer] * categories.MOBILE * categories.TECH3)

            -- 3. Also restrict T3 structures built by T3 factories for this layer
            AddBuildRestriction(army,
                categories.BUILTBYTIER3SUPPORTFACTORY * categories[layer] * categories.STRUCTURE)

            -- Note: T2 capabilities should remain unaffected

            --LOG("*QUIET* ApplyHQLossRestrictions: Applied T3 HQ loss restrictions for " ..
            --    layer .. " for player " .. army)
        end
    end,

    -- Check if HQ factory has been built
    HasHQFactory = function(self, layer, tech)
        if not self.HQFactoryCounts then
            return false
        end

        return self.HQFactoryCounts[layer] and self.HQFactoryCounts[layer][tech] > 0 or false
    end,

    -- Get count of HQ factories
    GetHQFactoryCount = function(self, layer, tech)
        if not self.HQFactoryCounts then
            return 0
        end

        return self.HQFactoryCounts[layer] and self.HQFactoryCounts[layer][tech] or 0
    end,

    -- Completely re-evaluate all HQ Support Factory restrictions
    ReEvaluateHQSupportFactoryRestrictions = function(self)
        if not self.HQFactoryCounts then
            self:InitializeHQFactoryTracking()
            return
        end

        local army = self:GetArmyIndex()
        local layers = { "LAND", "AIR", "NAVAL" }
        local techs = { "TECH2", "TECH3" }

        -- First, apply default restrictions for all
        AddBuildRestriction(army,
            (categories.TECH3 + categories.TECH2) * categories.SUPPORTFACTORY)
        AddBuildRestriction(army,
            categories.TECH3 * categories.FACTORY * categories.STRUCTURE * categories.RESEARCH)

        -- Then unlock based on what HQs we actually have
        for _, layer in layers do
            for _, tech in techs do
                if self.HQFactoryCounts[layer][tech] > 0 then
                    self:UnlockHQCapabilities(layer, tech)
                end
            end
        end

        --LOG("*QUIET* ReEvaluateHQSupportFactoryRestrictions: Re-evaluated for player " .. army)
    end,
}
