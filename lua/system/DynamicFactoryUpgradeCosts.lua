--****************************************************************************
--**
--**  File     :  /lua/system/DynamicFactoryUpgradeCosts.lua
--**  Author(s):  QUIET Community Edition
--**
--**  Summary  :  Dynamic Factory Upgrade Cost System
--**              Makes the first T2/T3 factory upgrade more expensive while
--**              keeping subsequent factories at normal costs
--**
--****************************************************************************

local LOUDGETN = table.getn
local LOUDENTITY = EntityCategoryContains
local GetCurrentUnits = moho.aibrain_methods.GetCurrentUnits

-- Categories for factory types
local FACTORY = categories.FACTORY
local LAND = categories.LAND
local AIR = categories.AIR
local NAVAL = categories.NAVAL
local TECH1 = categories.TECH1
local TECH2 = categories.TECH2
local TECH3 = categories.TECH3

-- Cost multipliers for first-time upgrades
local FIRST_UPGRADE_MULTIPLIERS = {
    BuildTime = 2.25,
    BuildCostMass = 1.35,
    BuildCostEnergy = 1.8,
}

-- Track which players have built their first factories of each type/tech
-- Structure: FirstFactoryBuilt[armyIndex][factoryType][techLevel] = boolean
local FirstFactoryBuilt = {}

-- Initialize tracking for all armies
function InitializeFirstFactoryTracking()
    local armies = ListArmies()
    for _, armyIndex in armies do
        if not FirstFactoryBuilt[armyIndex] then
            FirstFactoryBuilt[armyIndex] = {
                LAND = { [2] = false, [3] = false },
                AIR = { [2] = false, [3] = false },
                NAVAL = { [2] = false, [3] = false },
            }
        end
    end
end

-- Get the factory type (LAND, AIR, NAVAL) from a unit blueprint
function GetFactoryType(blueprint)
    if not blueprint or not blueprint.Categories then
        LOG("*QUIET* DEBUG: GetFactoryType - no blueprint or categories")
        return nil
    end

    for _, category in blueprint.Categories do
        if category == 'LAND' then
            return 'LAND'
        elseif category == 'AIR' then
            return 'AIR'
        elseif category == 'NAVAL' then
            return 'NAVAL'
        end
    end

    return nil
end

-- Get the tech level from a unit blueprint
function GetTechLevel(blueprint)
    if not blueprint or not blueprint.Categories then
        LOG("*QUIET* DEBUG: GetTechLevel - no blueprint or categories")
        return nil
    end

    for _, category in blueprint.Categories do
        if category == 'TECH1' then
            return 1
        elseif category == 'TECH2' then
            return 2
        elseif category == 'TECH3' then
            return 3
        end
    end

    return nil
end

-- Check if a player already owns any factories of the target tech level and type
function PlayerHasFactoryOfType(brain, factoryType, techLevel)
    if not brain or not factoryType or not techLevel then
        return false
    end
    
    local categoryToCheck = FACTORY
    
    -- Add factory type filter
    if factoryType == 'LAND' then
        categoryToCheck = categoryToCheck * LAND
    elseif factoryType == 'AIR' then
        categoryToCheck = categoryToCheck * AIR
    elseif factoryType == 'NAVAL' then
        categoryToCheck = categoryToCheck * NAVAL
    else
        return false
    end
    
    -- Add tech level filter
    if techLevel == 2 then
        categoryToCheck = categoryToCheck * TECH2
    elseif techLevel == 3 then
        categoryToCheck = categoryToCheck * TECH3
    else
        return false
    end
    
    -- Check if player has any factories of this type and tech level
    local count = GetCurrentUnits(brain, categoryToCheck)
    return count > 0
end

-- Check if this would be the player's first factory of this type and tech level
function IsFirstFactoryUpgrade(brain, upgradeBlueprint)
    if not brain or not upgradeBlueprint then
        LOG("*QUIET* DEBUG: Missing brain or blueprint")
        return false
    end

    local factoryType = GetFactoryType(upgradeBlueprint)
    local techLevel = GetTechLevel(upgradeBlueprint)

    -- Only apply to T2 and T3 factories
    if not factoryType or not techLevel or (techLevel ~= 2 and techLevel ~= 3) then
        return false
    end

    -- Check if player already has factories of this type and tech level
    local hasFactory = PlayerHasFactoryOfType(brain, factoryType, techLevel)

    local result = not hasFactory
    return result
end

-- Mark that a player has built their first factory of this type and tech level
function MarkFirstFactoryBuilt(brain, factoryType, techLevel)
    if not brain or not factoryType or not techLevel then
        return
    end
    
    local armyIndex = brain:GetArmyIndex()
    
    if not FirstFactoryBuilt[armyIndex] then
        InitializeFirstFactoryTracking()
    end
    
    if FirstFactoryBuilt[armyIndex][factoryType] and FirstFactoryBuilt[armyIndex][factoryType][techLevel] ~= nil then
        FirstFactoryBuilt[armyIndex][factoryType][techLevel] = true
    end
end

-- Get the modified costs for a first-time factory upgrade
function GetFirstUpgradeCosts(originalBlueprint)
    if not originalBlueprint or not originalBlueprint.Economy then
        return nil
    end
    
    local modifiedCosts = {
        BuildTime = originalBlueprint.Economy.BuildTime * FIRST_UPGRADE_MULTIPLIERS.BuildTime,
        BuildCostMass = originalBlueprint.Economy.BuildCostMass * FIRST_UPGRADE_MULTIPLIERS.BuildCostMass,
        BuildCostEnergy = originalBlueprint.Economy.BuildCostEnergy * FIRST_UPGRADE_MULTIPLIERS.BuildCostEnergy,
    }
    
    return modifiedCosts
end

-- Initialize the system when the module is loaded
InitializeFirstFactoryTracking()

-- Export functions for use by other modules
return {
    IsFirstFactoryUpgrade = IsFirstFactoryUpgrade,
    GetFirstUpgradeCosts = GetFirstUpgradeCosts,
    MarkFirstFactoryBuilt = MarkFirstFactoryBuilt,
    GetFactoryType = GetFactoryType,
    GetTechLevel = GetTechLevel,
    PlayerHasFactoryOfType = PlayerHasFactoryOfType,
}
