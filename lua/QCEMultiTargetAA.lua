--- Distribute AA fire across eligible targets, including single-shot launchers.
local LOUDGETN = table.getn
local LOUDINSERT = table.insert
local LOUDSORT = table.sort
local GetUnitsAroundPoint = _G.moho.aibrain_methods.GetUnitsAroundPoint
local SetTargetEntity = _G.moho.weapon_methods.SetTargetEntity
local GetBlueprint = _G.moho.weapon_methods.GetBlueprint
local AIR = categories.AIR

local function IsValidAATarget(self, target)
    local unit = self.unit
    if not unit or unit.Dead or unit:BeenDestroyed() or not target or target:BeenDestroyed() or target:IsDead() then
        return false
    end
    local army = unit:GetArmy()
    if not IsEnemy(army, target:GetArmy()) or target:GetCurrentLayer() ~= 'Air'
        or not EntityCategoryContains(self.AATargetCategory, target) then
        return false
    end
    local blip = target:GetBlip(army)
    if not blip or not (blip:IsSeenNow(army) or blip:IsOnRadar(army)) then
        return false
    end
    local position = unit:GetPosition()
    local targetPosition = target:GetPosition()
    local dx, dz = targetPosition[1] - position[1], targetPosition[3] - position[3]
    local distanceSquared = dx * dx + dz * dz
    local bp = self.bp or GetBlueprint(self)
    local minimum, maximum = bp.MinRadius or 0, bp.MaxRadius
    return distanceSquared >= minimum * minimum and distanceSquared <= maximum * maximum
end

---@class MultiTargetAAMixin
--- Enable with MultiTargetAA; MaxAATargets caps candidates per weapon salvo.
MultiTargetAAMixin = {
    BuildAATargetTable = function(self, bp, maxTargets)
        self.AATargetTable = {}
        local unit = self.unit
        if not unit or unit.Dead or unit:BeenDestroyed() then return end
        local brain = unit:GetAIBrain()
        if not brain then return end

        local allowed = AIR
        if bp.TargetRestrictOnlyAllow and bp.TargetRestrictOnlyAllow ~= '' then
            allowed = allowed * ParseEntityCategory((string.gsub(bp.TargetRestrictOnlyAllow, ',', ' + ')))
        end
        if bp.TargetRestrictDisallow and bp.TargetRestrictDisallow ~= '' then
            allowed = allowed - ParseEntityCategory((string.gsub(bp.TargetRestrictDisallow, ',', ' + ')))
        end
        self.AATargetCategory = allowed
        local airUnits = GetUnitsAroundPoint(brain, allowed, unit:GetPosition(), bp.MaxRadius, 'Enemy') or {}
        local candidates = {}
        for _, target in airUnits do
            if IsValidAATarget(self, target) then LOUDINSERT(candidates, target) end
        end
        LOUDSORT(candidates, function(a, b) return a:GetEntityId() < b:GetEntityId() end)
        local limit = math.max(1, bp.MaxAATargets or maxTargets)
        for i = 1, math.min(limit, LOUDGETN(candidates)) do
            LOUDINSERT(self.AATargetTable, candidates[i])
        end
    end,

    GetNextAATarget = function(self)
        -- Share the cursor between launchers so separate single-shot turrets
        -- distribute their fire too. Entity order stays stable between salvos.
        local lastId = self.unit.QCEAALastTargetId or -1
        local first
        for _, target in self.AATargetTable or {} do
            if IsValidAATarget(self, target) then
                first = first or target
                if target:GetEntityId() > lastId then
                    self.unit.QCEAALastTargetId = target:GetEntityId()
                    return target
                end
            end
        end
        if first then self.unit.QCEAALastTargetId = first:GetEntityId() end
        return first
    end,

    HasValidTargets = function(self)
        for _, target in self.AATargetTable or {} do
            if IsValidAATarget(self, target) then return true end
        end
        return false
    end,

    CreateProjectileForWeaponMultiAA = function(self, bone, baseCreateProjectile)
        local bp = self.bp or GetBlueprint(self)
        if not bp.MultiTargetAA then return baseCreateProjectile(self, bone) end

        -- QCE's firing state sets this for each shot, independently of muzzle
        -- count, and restarts it when a new rack salvo begins after an interrupt.
        if self.CurrentSalvoNumber == 1 or not self:HasValidTargets() then
            local rack = bp.RackBones[self.CurrentRackNumber or 1]
            local shots = bp.MuzzleSalvoSize or 1
            if (bp.MuzzleSalvoDelay or 0) == 0 then shots = LOUDGETN(rack.MuzzleBones) end
            self:BuildAATargetTable(bp, shots)
        end
        local target = self:GetNextAATarget()
        if target then SetTargetEntity(self, target) end
        return baseCreateProjectile(self, bone)
    end,
}

