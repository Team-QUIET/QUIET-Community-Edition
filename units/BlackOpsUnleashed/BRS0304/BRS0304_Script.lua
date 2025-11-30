-- BRS0304 - Cybran T3 AA Cruiser "Reaper Class"
-- Modified to include Radar Jammer Aura that reduces enemy intel range

local CSeaUnit = import('/lua/defaultunits.lua').SeaUnit

local CybranWeaponsFile = import('/lua/cybranweapons.lua')

local CDFProtonCannonWeapon     = CybranWeaponsFile.CDFProtonCannonWeapon
local CAANanoDartWeapon         = CybranWeaponsFile.CAANanoDartWeapon
local CAMZapperWeapon           = CybranWeaponsFile.CAMZapperWeapon
local CANNaniteTorpedoWeapon    = CybranWeaponsFile.CANNaniteTorpedoWeapon

local AIFQuasarAntiTorpedoWeapon = import('/lua/aeonweapons.lua').AIFQuasarAntiTorpedoWeapon

local MicrowaveLaser             = import('/mods/BlackOpsUnleashed/lua/BlackOpsweapons.lua').MartyrHeavyMicrowaveLaserGenerator

local Buff = import('/lua/sim/buff.lua')
local EffectTemplate = import('/lua/EffectTemplates.lua')

CybranWeaponsFile = nil

-- Jammer field visual effect emitters
local JammerFieldEffects = {
    '/effects/emitters/jammer_ambient_01_emit.bp',
    '/effects/emitters/jammer_ambient_02_emit.bp',
}

-- Create the jammer debuff if it doesn't exist
if not Buffs['BRS0304_JammerDebuff'] then
    BuffBlueprint {
        Name = 'BRS0304_JammerDebuff',
        DisplayName = 'Radar Disruption',
        BuffType = 'COUNTERINTEL',
        Stacks = 'REPLACE',  -- Don't stack, just refresh duration
        Duration = 10,  -- 5 second duration, refreshed every 3 seconds
        Affects = {
            VisionRadius = {
                Add = 0,
                Mult = 0.75,  -- Reduce vision range to 75% (25% reduction)
            },
            RadarRadius = {
                Add = 0,
                Mult = 0.5,  -- Reduce radar range to 50%
            },
            SonarRadius = {
                Add = 0,
                Mult = 0.5,  -- Reduce sonar range to 50%
            },
            OmniRadius = {
                Add = 0,
                Mult = 0.6,  -- Reduce omni range to 60%
            },
        },
        Effects = {
            '/effects/emitters/jammer_ambient_01_emit.bp',
            '/effects/emitters/jammer_ambient_02_emit.bp',
        },
        EffectsScale = 0.25,
    }
end

BRS0304 = ClassUnit(CSeaUnit) {

    Weapons = {
	
        ParticleGun     = ClassWeapon(CDFProtonCannonWeapon) {},

        RightGun        = ClassWeapon(MicrowaveLaser) {},
        LeftGun         = ClassWeapon(MicrowaveLaser) {},
		
        AAGun           = ClassWeapon(CAANanoDartWeapon) {},
        GroundGun       = ClassWeapon(CAANanoDartWeapon) {},
		
        Zapper          = ClassWeapon(CAMZapperWeapon) {},
        Torpedo         = ClassWeapon(CANNaniteTorpedoWeapon) {},
        AntiTorpedo     = ClassWeapon(AIFQuasarAntiTorpedoWeapon) {},
		
    },

    IntelEffects = {
        { Bones = {'URS0202'}, Offset = {0, 2, 0}, Type = 'Jammer01' },
    },

    OnCreate = function(self)

        CSeaUnit.OnCreate(self)

        self:SetWeaponEnabledByLabel('GroundGun', false)
        self.JammerEffectsBag = {}

    end,

    OnStopBeingBuilt = function(self, builder, layer)
        CSeaUnit.OnStopBeingBuilt(self, builder, layer)

        -- Start the jammer aura thread
        self:SetMaintenanceConsumptionActive()
        self:ForkThread(self.JammerAuraThread)
        self:ForkThread(self.JammerFieldEffectThread)
    end,

    OnScriptBitSet = function(self, bit)
        CSeaUnit.OnScriptBitSet(self, bit)
        if bit == 1 then
            self:SetWeaponEnabledByLabel('AAGun', false)
            self:SetWeaponEnabledByLabel('GroundGun', true)
        end
    end,

    OnScriptBitClear = function(self, bit)
        CSeaUnit.OnScriptBitClear(self, bit)
        if bit == 1 then
            self:SetWeaponEnabledByLabel('AAGun', true)
            self:SetWeaponEnabledByLabel('GroundGun', false)
        end
    end,

    -- Jammer Aura: Periodically applies debuff to nearby enemy units
    JammerAuraThread = function(self)
        local aiBrain = self:GetAIBrain()
        local bp = self:GetBlueprint()
        local jamRadius = 60  -- Jammer aura radius

        local WaitSeconds = WaitSeconds
        local GetPosition = self.GetPosition
        local GetUnitsAroundPoint = moho.aibrain_methods.GetUnitsAroundPoint
        local EntityCategoryContains = EntityCategoryContains
        local ApplyBuff = Buff.ApplyBuff

        -- Categories to exclude from jamming (commanders, experimentals)
        local excludeCats = categories.COMMAND + categories.SUBCOMMANDER + categories.EXPERIMENTAL

        while not self.Dead do
            -- Only jam if we have energy
            if self:GetResourceConsumed() >= 1 then
                local pos = GetPosition(self)

                -- Get all enemy units with intel capabilities in range
                local enemies = GetUnitsAroundPoint(aiBrain, categories.ALLUNITS, pos, jamRadius, 'Enemy')

                for _, enemy in enemies do
                    if not enemy.Dead and not EntityCategoryContains(excludeCats, enemy) then
                        -- Apply the jammer debuff
                        ApplyBuff(enemy, 'BRS0304_JammerDebuff')
                    end
                end
            end

            WaitSeconds(3)  -- Check every 3 seconds
        end
    end,

    -- Visual effect thread for the jammer field aura
    JammerFieldEffectThread = function(self)
        local army = self:GetArmy()
        local WaitSeconds = WaitSeconds
        local CreateAttachedEmitter = CreateAttachedEmitter

        while not self.Dead do
            -- Only show effect if we have energy
            if self:GetResourceConsumed() >= 1 then
                -- Clean up old effects
                if self.JammerEffectsBag then
                    for k, v in self.JammerEffectsBag do
                        if v then v:Destroy() end
                    end
                    self.JammerEffectsBag = {}
                end

                -- Create the jammer field visual effects
                for _, effect in JammerFieldEffects do
                    local emitter = CreateAttachedEmitter(self, 'URS0202', army, effect)
                    emitter:ScaleEmitter(2.5)  -- Scale up for visibility
                    emitter:OffsetEmitter(0, 1.5, 0)  -- Raise it above the unit
                    table.insert(self.JammerEffectsBag, emitter)
                end

                WaitSeconds(2)  -- Refresh effects every 2 seconds
            else
                -- No energy, clean up effects
                if self.JammerEffectsBag then
                    for k, v in self.JammerEffectsBag do
                        if v then v:Destroy() end
                    end
                    self.JammerEffectsBag = {}
                end
                WaitSeconds(1)
            end
        end
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        -- Clean up jammer effects on death
        if self.JammerEffectsBag then
            for k, v in self.JammerEffectsBag do
                if v then v:Destroy() end
            end
            self.JammerEffectsBag = {}
        end
        CSeaUnit.OnKilled(self, instigator, type, overkillRatio)
    end,
}

TypeClass = BRS0304

