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
            self:InitializeHQFactoryTracking()
        end

        if self.HQFactoryCounts[layer] and self.HQFactoryCounts[layer][tech] ~= nil then
            -- Increment count
            self.HQFactoryCounts[layer][tech] = self.HQFactoryCounts[layer][tech] + 1

            -- T3 HQ also provides T2 capabilities, so increment T2 count as well
            if tech == "TECH3" then
                self.HQFactoryCounts[layer]["TECH2"] = self.HQFactoryCounts[layer]["TECH2"] + 1
            end

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
            return
        end

        if self.HQFactoryCounts[layer] and self.HQFactoryCounts[layer][tech] ~= nil then
            -- Decrement count (don't go below 0)
            if self.HQFactoryCounts[layer][tech] > 0 then
                self.HQFactoryCounts[layer][tech] = self.HQFactoryCounts[layer][tech] - 1
            end

            -- T3 HQ also provided T2 capabilities, so decrement T2 count as well
            if tech == "TECH3" and self.HQFactoryCounts[layer]["TECH2"] > 0 then
                self.HQFactoryCounts[layer]["TECH2"] = self.HQFactoryCounts[layer]["TECH2"] - 1
            end

            -- If no HQ factories of this type remain, apply restrictions
            if self.HQFactoryCounts[layer][tech] == 0 then
                self:ApplyHQLossRestrictions(layer, tech)
            end

            -- Also check T2 count after T3 HQ loss (since T3 HQ contributed to T2 count)
            if tech == "TECH3" and self.HQFactoryCounts[layer]["TECH2"] == 0 then
                self:ApplyHQLossRestrictions(layer, "TECH2")
            end
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

            -- Re-enable T2 mobile units (in case they were restricted from a previous HQ loss)
            RemoveBuildRestriction(army,
                categories.BUILTBYTIER2FACTORY * categories[layer] * (categories.MOBILE - categories.ENGINEER) * categories.TECH2)
        end

        if tech == "TECH3" then
            -- T3 HQ built: unlock T3 support factories for this layer
            RemoveBuildRestriction(army,
                categories[layer] * categories.TECH3 * categories.SUPPORTFACTORY)

            -- Re-enable T3 mobile units (in case they were restricted from a previous HQ loss)
            RemoveBuildRestriction(army,
                categories.BUILTBYTIER3FACTORY * categories[layer] * (categories.MOBILE - categories.ENGINEER) * categories.TECH3)

            -- T3 HQ also provides T2 capabilities, so unlock T2 as well
            RemoveBuildRestriction(army,
                categories[layer] * categories.TECH2 * categories.SUPPORTFACTORY)
            RemoveBuildRestriction(army,
                categories.BUILTBYTIER2FACTORY * categories[layer] * (categories.MOBILE - categories.ENGINEER) * categories.TECH2)
        end
    end,

    -- Apply restrictions when HQ is lost
    -- Note: T3 HQ counts toward T2, so when T3 HQ is lost, RemoveHQFactory
    -- will also call this for TECH2 if the T2 count reaches 0
    ApplyHQLossRestrictions = function(self, layer, tech)
        local army = self:GetArmyIndex()

        if tech == "TECH2" then
            -- No T2 HQs remaining (including T3 HQs which count toward T2)
            -- 1. Restrict building new T2 support factories
            AddBuildRestriction(army,
                categories[layer] * categories.TECH2 * categories.SUPPORTFACTORY)

            -- 2. Restrict building T3 HQ factories (T2 HQ is prerequisite)
            AddBuildRestriction(army,
                categories[layer] * categories.TECH3 * categories.FACTORY * categories.STRUCTURE * categories.RESEARCH)

            -- 3. Restrict T2 mobile units (except engineers) from being built
            AddBuildRestriction(army,
                categories.BUILTBYTIER2FACTORY * categories[layer] * (categories.MOBILE - categories.ENGINEER) * categories.TECH2)

            -- 4. Also restrict T3 support factories
            AddBuildRestriction(army,
                categories[layer] * categories.TECH3 * categories.SUPPORTFACTORY)
        end

        if tech == "TECH3" then
            -- No T3 HQs remaining
            -- 1. Restrict building new T3 support factories
            AddBuildRestriction(army,
                categories[layer] * categories.TECH3 * categories.SUPPORTFACTORY)

            -- 2. Restrict T3 mobile units (except engineers) from being built
            AddBuildRestriction(army,
                categories.BUILTBYTIER3FACTORY * categories[layer] * (categories.MOBILE - categories.ENGINEER) * categories.TECH3)

            -- Note: T2 restrictions are handled separately by RemoveHQFactory
            -- which calls ApplyHQLossRestrictions for TECH2 if T2 count reaches 0
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
