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
        -- Initialize tracking tables
        self.HQFactoriesBuilt = {
            LAND = { TECH2 = false, TECH3 = false },
            AIR = { TECH2 = false, TECH3 = false },
            NAVAL = { TECH2 = false, TECH3 = false },
        }

        -- Restrict all support factories by default
        AddBuildRestriction(self:GetArmyIndex(),
            (categories.TECH3 + categories.TECH2) * categories.SUPPORTFACTORY)
    end,

    -- Add HQ factory
    AddHQFactory = function(self, layer, tech)
        if not self.HQFactoriesBuilt then
            LOG("*QUIET* AddHQFactory: Initializing tracking for player " .. self:GetArmyIndex())
            self:InitializeHQFactoryTracking()
        end

        if self.HQFactoriesBuilt[layer] and self.HQFactoriesBuilt[layer][tech] ~= nil then
            self.HQFactoriesBuilt[layer][tech] = true

            LOG("*QUIET* AddHQFactory: Added HQ Factory " .. layer .. " " .. tech .. " for player " .. self:GetArmyIndex())

            -- Update build restrictions
            self:UpdateSupportFactoryRestrictions(layer, tech)
        else
            LOG("*QUIET* ERROR: Failed to add HQ Factory " .. layer .. " " .. tech .. " for player " .. self:GetArmyIndex() .. " - tracking not initialized properly")
        end
    end,

    -- Update support factory restrictions
    UpdateSupportFactoryRestrictions = function(self, layer, tech)
        local army = self:GetArmyIndex()

        -- Remove restrictions for this specific tech/layer combination
        if tech == "TECH2" and self.HQFactoriesBuilt[layer]["TECH2"] then
            RemoveBuildRestriction(army,
                categories[layer] * categories["TECH2"] * categories.SUPPORTFACTORY)
        end

        if tech == "TECH3" and self.HQFactoriesBuilt[layer]["TECH3"] then
            RemoveBuildRestriction(army,
                categories[layer] * categories["TECH2"] * categories.SUPPORTFACTORY)
            RemoveBuildRestriction(army,
                categories[layer] * categories["TECH3"] * categories.SUPPORTFACTORY)
        end
    end,

    -- Check if HQ factory has been built
    HasHQFactory = function(self, layer, tech)
        if not self.HQFactoriesBuilt then
            return false
        end

        return self.HQFactoriesBuilt[layer] and self.HQFactoriesBuilt[layer][tech] or false
    end,

    -- Completely re-evaluate all HQ Support Factory restrictions
    ReEvaluateHQSupportFactoryRestrictions = function(self)
        if not self.HQFactoriesBuilt then
            self:InitializeHQFactoryTracking()
            return
        end

        -- Re-evaluate restrictions for all layer/tech combinations
        local layers = { "LAND", "AIR", "NAVAL" }
        local techs = { "TECH2", "TECH3" }

        for _, layer in layers do
            for _, tech in techs do
                self:UpdateSupportFactoryRestrictions(layer, tech)
            end
        end
    end,
}
