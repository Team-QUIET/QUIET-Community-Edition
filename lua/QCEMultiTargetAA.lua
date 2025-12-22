---  /lua/QCEMultiTargetAA.lua
---  Multi-Target AA Weapon
---  Distributes AA fire across multiple air targets within a salvo

local LOUDGETN = table.getn
local LOUDINSERT = table.insert
local LOUDMOD = math.mod

local GetUnitsAroundPoint = _G.moho.aibrain_methods.GetUnitsAroundPoint
local SetTargetEntity = _G.moho.weapon_methods.SetTargetEntity
local GetCurrentTarget = _G.moho.weapon_methods.GetCurrentTarget
local GetBlueprint = _G.moho.weapon_methods.GetBlueprint

local AIR = categories.AIR

---@class MultiTargetAAMixin
---Mixin that can be applied to any AA projectile weapon to enable multi-target fire distribution
---Add 'MultiTargetAA = true' to weapon blueprint to enable
---Add 'MaxAATargets = N' to limit targets per salvo (defaults to muzzle count)
MultiTargetAAMixin = {

    --- Build a table of valid air targets within weapon range
    ---@param self Weapon
    ---@param bp table Weapon blueprint
    ---@param maxTargets number Maximum targets to acquire
    BuildAATargetTable = function(self, bp, maxTargets)
        self.AATargetTable = {}
        
        local unit = self.unit
        if not unit or unit.Dead then return end
        
        local aiBrain = unit:GetAIBrain()
        if not aiBrain then return end
        
        local position = unit:GetPosition()
        local radius = bp.MaxRadius or 60
        
        -- Get all enemy air units in range
        local airUnits = GetUnitsAroundPoint(aiBrain, AIR, position, radius, 'Enemy')
        
        if not airUnits or LOUDGETN(airUnits) == 0 then
            return
        end
        
        -- Limit to maxTargets or available targets
        local targetLimit = bp.MaxAATargets or maxTargets
        local count = 0
        
        for _, target in airUnits do
            if target and not target:BeenDestroyed() and not target:IsDead() then
                LOUDINSERT(self.AATargetTable, target)
                count = count + 1
                if count >= targetLimit then break end
            end
        end
    end,
    
    --- Get the next target from the target table for this projectile
    ---@param self Weapon
    ---@return Entity|nil The target entity or nil
    GetNextAATarget = function(self)
        local tableSize = self.AATargetTable and LOUDGETN(self.AATargetTable) or 0
        if tableSize == 0 then
            return nil
        end

        -- Distribute projectiles across targets using modulo
        local targetIndex = LOUDMOD(self.AAFireCounter - 1, tableSize) + 1
        local target = self.AATargetTable[targetIndex]

        -- If target is valid, return it
        if target and not target:BeenDestroyed() and not target:IsDead() then
            return target
        end

        -- Target at this index is invalid, try to find any valid target
        for i = 1, tableSize do
            local altTarget = self.AATargetTable[i]
            if altTarget and not altTarget:BeenDestroyed() and not altTarget:IsDead() then
                return altTarget
            end
        end

        return nil
    end,
    
    --- Check if current target table has any valid targets remaining
    ---@param self Weapon
    ---@return boolean True if table has at least one valid target
    HasValidTargets = function(self)
        if not self.AATargetTable then return false end
        for _, target in self.AATargetTable do
            if target and not target:BeenDestroyed() and not target:IsDead() then
                return true
            end
        end
        return false
    end,

    --- Override this in the weapon to handle multi-target AA
    ---@param self Weapon
    ---@param bone string The muzzle bone name
    ---@param baseCreateProjectile function The original CreateProjectileForWeapon function
    ---@return Projectile The created projectile
    CreateProjectileForWeaponMultiAA = function(self, bone, baseCreateProjectile)
        local bp = self.bp or GetBlueprint(self)

        -- Only process if MultiTargetAA is enabled in blueprint
        if not bp.MultiTargetAA then
            return baseCreateProjectile(self, bone)
        end

        -- Get muzzle count from blueprint
        local muzzleCount = 1
        if bp.RackBones and bp.RackBones[1] and bp.RackBones[1].MuzzleBones then
            muzzleCount = LOUDGETN(bp.RackBones[1].MuzzleBones)
        end

        -- Initialize counter if needed
        if not self.AAFireCounter then
            self.AAFireCounter = 0
        end

        -- Rebuild target table at start of each salvo OR if no valid targets remain
        if self.AAFireCounter == 0 or not self:HasValidTargets() then
            self:BuildAATargetTable(bp, muzzleCount)
        end

        self.AAFireCounter = self.AAFireCounter + 1

        -- Wrap counter for next salvo
        if self.AAFireCounter >= muzzleCount then
            self.AAFireCounter = 0
        end

        -- Try to get a different target for this projectile
        local target = self:GetNextAATarget()
        if target then
            SetTargetEntity(self, target)
        end

        -- Call original projectile creation
        return baseCreateProjectile(self, bone)
    end,
}

