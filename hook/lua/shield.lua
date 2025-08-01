-- WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] * QUIET Hook for Shield.lua' )
-- This warning allows us to see exactly where our Hook Line starts so we can debug the exact line thats causing an error easier
-- Begins at Line 998
-- to get the exact line number, you can substract the line number of the line where the error occurs by the line 998 in this file

--  /lua/shield.lua

do -- encasing the code in do .... end means that you dont have to worry about using unique variables

local Entity = import('/lua/sim/Entity.lua').Entity
local EffectTemplate = import('/lua/EffectTemplates.lua')

local shieldAbsorptionValues = import("/mods/QUIET-Community-Edition/lua/ShieldAbsorptionValues.lua").shieldAbsorptionValues

local ChangeState = ChangeState

local LOUDENTITY    = EntityCategoryContains
local LOUDMAX       = math.max
local LOUDMIN       = math.min
local LOUDPARSE     = ParseEntityCategory	
local LOUDPOW       = math.pow
local LOUDSQRT      = math.sqrt

local TableAssimilate = table.assimilate

-- cache globals
local Warp = Warp
local IsEntity = IsEntity
local IsAlly = IsAlly
local IsEnemy = IsEnemy
local Random = Random
local GetGameTick = GetGameTick
local ForkThread = ForkThread
local ForkTo = ForkThread
local ChangeState = ChangeState
local ArmyGetHandicap = ArmyGetHandicap
local CoroutineYield = coroutine.yield
local CreateEmitterAtBone = CreateEmitterAtBone
local _c_CreateShield = _c_CreateShield
local KillThread = KillThread
local WaitTicks = coroutine.yield

-- cache moho functions
local GetResourceConsumed = moho.unit_methods.GetResourceConsumed
local GetEconomyStored = moho.aibrain_methods.GetEconomyStored

-- cache trashbag functions
local TrashBag = TrashBag
local TrashAdd = TrashBag.Add
local TrashDestroy = TrashBag.Destroy

local VectorCached = Vector(0, 0, 0)
	
local AdjustHealth      = _G.moho.entity_methods.AdjustHealth
local GetArmy           = _G.moho.entity_methods.GetArmy        
local GetBlueprint      = _G.moho.entity_methods.GetBlueprint
local GetHealth         = _G.moho.entity_methods.GetHealth
local GetMaxHealth      = _G.moho.entity_methods.GetMaxHealth
local SetMesh           = _G.moho.entity_methods.SetMesh

local GetArmorMult      = _G.moho.unit_methods.GetArmorMult
local GetStat           = _G.moho.unit_methods.GetStat
local SetStat           = _G.moho.unit_methods.SetStat
local SetShieldRatio    = _G.moho.unit_methods.SetShieldRatio

local EntityGetHealth = _G.moho.entity_methods.GetHealth
local EntityGetMaxHealth = _G.moho.entity_methods.GetMaxHealth
local EntitySetHealth = _G.moho.entity_methods.SetHealth
local EntitySetMaxHealth = _G.moho.entity_methods.SetMaxHealth
local EntityAdjustHealth = _G.moho.entity_methods.AdjustHealth
local EntityGetArmy = _G.moho.entity_methods.GetArmy
local EntityGetEntityId = _G.moho.entity_methods.GetEntityId
local EntitySetVizToFocusPlayer = _G.moho.entity_methods.SetVizToFocusPlayer
local EntitySetVizToEnemies = _G.moho.entity_methods.SetVizToEnemies
local EntitySetVizToAllies = _G.moho.entity_methods.SetVizToAllies
local EntitySetVizToNeutrals = _G.moho.entity_methods.SetVizToNeutrals
local EntityAttachBoneTo = _G.moho.entity_methods.AttachBoneTo
local EntityGetPosition = _G.moho.entity_methods.GetPosition
local EntityGetPositionXYZ = _G.moho.entity_methods.GetPositionXYZ
local EntitySetMesh = _G.moho.entity_methods.SetMesh
local EntitySetDrawScale = _G.moho.entity_methods.SetDrawScale
local EntitySetOrientation = _G.moho.entity_methods.SetOrientation
local EntityDestroy = _G.moho.entity_methods.Destroy
local EntityBeenDestroyed = _G.moho.entity_methods.BeenDestroyed
local EntitySetCollisionShape = _G.moho.entity_methods.SetCollisionShape

local EntitySetParentOffset = _G.moho.entity_methods.SetParentOffset

local UnitSetScriptBit = _G.moho.unit_methods.SetScriptBit
local UnitIsUnitState = _G.moho.unit_methods.IsUnitState
local UnitRevertCollisionShape = _G.moho.unit_methods.RevertCollisionShape

local IEffectOffsetEmitter = _G.moho.IEffect.OffsetEmitter

-- cache categories computations
local CategoriesOverspill = categories.SHIELD * categories.DEFENSE

-- default values for a shield specification table (to be passed to native code)
local DEFAULT_OPTIONS = {
    Mesh = '',
    MeshZ = '',
    ImpactMesh = '',
    ImpactEffects = '',
    Size = 10,
    ShieldMaxHealth = 250,
    ShieldRechargeTime = 10,
    ShieldEnergyDrainRechargeTime = 10,
    ShieldVerticalOffset = -1,
    ShieldRegenRate = 1,
    ShieldRegenStartTime = 5,
    PassOverkillDamage = false,

    -- flags for mods
    -- SkipAttachmentCheck = false, -- defaults to nil, same as false
}

LargestShieldDiameter = 0
for k, bp in __blueprints do
    -- check for blueprints that have a shield and a shield size set
    if bp.Defense and bp.Defense.Shield and bp.Defense.Shield.ShieldSize then
        -- skip Aeon palace and UEF shield boat as they skew the results
        if not (bp.BlueprintId == "xac2101" or bp.BlueprintId == "xes0205") then
            local size = bp.Defense.Shield.ShieldSize
            if size > LargestShieldDiameter then
                LargestShieldDiameter = size
            end
        end
    end
end

QCEShield = Shield
Shield = ClassShield(QCEShield) {

    RemainEnabledWhenAttached = false,
    --LOG("We've entered LCE Version of Shield.lua"),

    __init = function(self, spec)
        -- Apply default options
        local spec = TableAssimilate(spec, DEFAULT_OPTIONS)

        _c_CreateShield(self, spec)
    end,

    OnCreate = function( self, spec )

        -- cache information that is used frequently
        local owner = spec.Owner
        self.Army = EntityGetArmy(self)
        self.EntityId = EntityGetEntityId(self)
        self.Brain = owner:GetAIBrain()
        self.Owner = owner

		self.Dead = false

        -- cache impact effects and mesh
        local impactEffects = spec.ImpactEffects
        if impactEffects and impactEffects ~= '' then
			self.ImpactEffects = EffectTemplate[impactEffects]
		else
			self.ImpactEffects = false
		end

        local impactMesh = spec.ImpactMesh
        if impactMesh and impactMesh ~= '' then
            self.ImpactMeshBp = impactMesh
        else
            self.ImpactMeshBp = false
        end

        -- manage impact entities
        self.LiveImpactEntities = 0
        self.ImpactEntitySpecs = { Owner = owner }

		self.OffHealth = -1

        -- copy over information from specification
        self.Size = spec.Size
        self.MeshBp = spec.Mesh
        self.MeshZBp = spec.MeshZ
        self.SpillOverDmgMod = spec.ShieldSpillOverDamageMod or 0.15
        self.ShieldRechargeTime = spec.ShieldRechargeTime or 5
        self.ShieldEnergyDrainRechargeTime = spec.ShieldEnergyDrainRechargeTime or 5
        self.ShieldVerticalOffset = spec.ShieldVerticalOffset or -1
        self.PassOverkillDamage = spec.PassOverkillDamage
        self.SkipAttachmentCheck = spec.SkipAttachmentCheck

        -- lookup whether we're a static shield for absorbing deathnukes with modded shields that don't have the value set
        local absorptionType = spec.AbsorptionType
        -- lookup whether we're a static or a commander shield for overcharge's fixed damage
        local ownerBp = self.Owner.bp
        local ownerCategories = ownerBp.CategoriesHash
        if ownerCategories.STRUCTURE then
            self.StaticShield = true
            if not absorptionType then
                absorptionType = "StaticShield"
            end
        elseif ownerCategories.COMMAND then
            self.CommandShield = true
        end

        -- lookup our damage absorption type's table
        self.AbsorptionTypeDamageTypeToMulti = shieldAbsorptionValues[absorptionType or "Default"]

        -- use trashbag of the unit that owns us
        self.Trash = self.Owner.Trash

        -- manage overlapping shields
        self.OverlappingShields = {}
        self.OverlappingShieldsCount = 0
        self.OverlappingShieldsTick = -1

        -- manage overspill
        self.DamagedTick = {}
        self.DamagedRegular = {}
        self.DamagedOverspill = {}

        -- set some internal state related to shields
        self._IsUp = false
        self.MyShieldType = 'Shield'

        self:SetSize(spec.Size)

        -- attach us to the owner
        EntityAttachBoneTo(self, -1, spec.Owner, -1)
		
        -- set our health
        EntitySetMaxHealth(self, spec.ShieldMaxHealth)
        EntitySetHealth(self, self, spec.ShieldMaxHealth)

		SetShieldRatio( self.Owner, 1 )

        self:SetShieldRegenRate(spec.ShieldRegenRate)
        self:SetShieldRegenStartTime(spec.ShieldRegenStartTime)

        -- tell the engine when we should be visible
        EntitySetVizToFocusPlayer(self, 'Always')
        EntitySetVizToEnemies(self, 'Intel')
        EntitySetVizToAllies(self, 'Always')
        EntitySetVizToNeutrals(self, 'Intel')
        
        GetStat( self.Owner,'SHIELDHP', 0 )
        GetStat( self.Owner,'SHIELDREGEN', 0 )
  
        SetStat( self.Owner,'SHIELDHP', spec.ShieldMaxHealth )
        SetStat( self.Owner,'SHIELDREGEN', spec.ShieldRegenRate)

        self.Enabled = true
		
		if ScenarioInfo.ShieldDialog then
			LOG("*AI DEBUG Shield created on "..__blueprints[self.Owner.BlueprintID].Description) 
		end

        ChangeState(self, self.EnergyDrainRechargeState)

        --LOG("We've exitting LCE Version of Shield.lua - OnCreate Function")
    end,
	
    ForkThread = function(self, fn, ...)
        local thread = ForkThread(fn, self, unpack(arg))
        TrashAdd( self.Owner.Trash, thread )
		return thread
    end,
	
	SetRechargeTime = function(self, rechargeTime, energyRechargeTime)
        self.ShieldRechargeTime = rechargeTime
        self.ShieldEnergyDrainRechargeTime = energyRechargeTime
    end,

	SetVerticalOffset = function(self, offset)
        self.ShieldVerticalOffset = offset
    end,

    SetSize = function(self, size)
        self.Size = size
    end,

    SetShieldRegenRate = function(self, rate)
        self.RegenRate = rate
    end,

    SetShieldRegenStartTime = function(self, time)
        self.RegenStartTime = time
    end,

    UpdateShieldRatio = function(self, value)
	
        if value >= 0 then
		
            SetShieldRatio( self.Owner, value )
        else
		
            SetShieldRatio( self.Owner, EntityGetHealth(self) / EntityGetMaxHealth(self))
        end
		
    end,

    GetCachePosition = function(self)
        return self:GetPosition()
    end,

    -- Note, this is called by native code to calculate spillover damage. The
    -- damage logic will subtract this value from any damage it does to units
    -- under the shield. The default is to always absorb as much as possible
    -- but the reason this function exists is to allow flexible implementations
    -- like shields that only absorb partial damage (like armor).
    --- How much of incoming damage is absorbed by the shield. Used by the engine to calculate remainder spillover damage
    ---@param self Shield
    ---@param instigator Unit
    ---@param amount number
    ---@param type DamageType
    ---@return number damageAbsorbed If not all damage is absorbed, the remainder passes to targets under the shield.
    OnGetDamageAbsorption = function(self, instigator, amount, type)
        if type == "TreeForce" or type == "TreeFire" then
            return amount
        end
        -- Allow decoupling the shield from the owner's armor multiplier
        local absorptionMulti = self.AbsorptionTypeDamageTypeToMulti[type] or self.Owner:GetArmorMult(type)

        -- Like armor damage, first multiply by armor reduction, then apply handicap
        -- See SimDamage.cpp (DealDamage function) for how this should work
        amount = amount * absorptionMulti
        amount = amount * (1.0 - ArmyGetHandicap(self.Army))

        local health = EntityGetHealth(self)
        if health < amount then
            return health
        else
            return amount
        end
    end,

    --- Retrieves allied shields that overlap with this shield, caches the results per tick
    -- @param self A shield that we're computing the overlapping shields for
    -- @param tick Optional parameter, represents the game tick. Used to determine if we need to refresh the cache
    GetOverlappingShields = function(self, tick)

        -- allow the game tick to be send to us, saves cycles
        tick = tick or GetGameTick()

        -- see if we need to re-compute the overlapping shields as the information we're requesting is of a different tick
        if tick ~= self.OverlappingShieldsTick then
            self.OverlappingShieldsTick = tick

            -- cache frequently used values
            local brain = self.Brain
            local owner = self.Owner
            local ownerEntityId = owner.EntityId
            local position = EntityGetPosition(owner)
            local selfSize = self.Size
            local radius = 0.5 * selfSize

            -- diameter where other shields overlap with us or are contained by us
            local diameter = LargestShieldDiameter + selfSize

            -- retrieve candidate units
            local units = brain:GetUnitsAroundPoint(CategoriesOverspill, position, 0.5 * diameter, 'Ally')

            if units then
                -- pre-allocate locals for better performance
                local shieldOther, radiusOther, distanceToOverlap
                local osx, osy, osz, d, dx, dy, dz
                local shieldSize, shieldType

                -- compute our position only once
                local psx, psy, psz = EntityGetPositionXYZ(self)

                local head = 1
                local overlappingShields = self.OverlappingShields

                -- clear previous results efficiently
                for i = 1, self.OverlappingShieldsCount do
                    overlappingShields[i] = nil
                end

                for k, other in units do
                    -- store reference to reduce table lookups
                    shieldOther = other.MyShield

                    -- check if it is a different unit and that it has an active shield with a radius
                    -- larger than 0, as engine defaults shield table to 0
                    if shieldOther then
                        shieldType = shieldOther.MyShieldType
                        shieldSize = shieldOther.Size

                        if shieldType ~= "Personal"
                            and shieldOther:IsUp()
                            and shieldSize
                            and shieldSize > 0
                            and ownerEntityId ~= other.EntityId
                        then
                            -- compute radius of shield
                            radiusOther = 0.5 * shieldSize

                            -- compute total distance to overlap and square it to prevent a square root
                            distanceToOverlap = radius + radiusOther
                            distanceToOverlap = distanceToOverlap * distanceToOverlap

                            -- retrieve position of other shield
                            osx, osy, osz = EntityGetPositionXYZ(shieldOther)

                            -- compute vector from self to other
                            dx = osx - psx
                            dy = osy - psy
                            dz = osz - psz

                            -- compute squared distance and check it
                            d = dx * dx + dy * dy + dz * dz
                            if d < distanceToOverlap then
                                overlappingShields[head] = shieldOther
                                head = head + 1
                            end
                        end
                    end
                end
                -- keep track of the number of adjacent shields
                self.OverlappingShieldsCount = head - 1
            else
                -- no units found
                self.OverlappingShieldsCount = 0
            end
        end
        -- return the shields in question
        return self.OverlappingShields, self.OverlappingShieldsCount
    end,

    OnCollisionCheckWeapon = function(self, firingWeapon)

		local GetArmy = GetArmy
	
		if IsAlly( self.Army, GetArmy(firingWeapon.unit) ) then
		
			return false
			
		end
	
		local weaponBP = firingWeapon.bp
	
        -- Check DNC list
        if weaponBP.DoNotCollideList then
			--LOG("*AI DEBUG Processing Shield DNC List "..repr(weaponBP.DoNotCollideList))
			
			local LOUDENTITY = LOUDENTITY
			local LOUDPARSE = LOUDPARSE
			
			for _, v in weaponBP.DoNotCollideList do
				if LOUDENTITY(LOUDPARSE(v), self) then
					return false
				end
			end
		end   
        
        return true
    end,
    
    GetOverkill = function(self,instigator,amount,type)
        -- Like armor damage, first multiply by armor reduction, then apply handicap
        -- See SimDamage.cpp (DealDamage function) for how this should work
        amount = amount * (self.Owner:GetArmorMult(type))
        amount = amount * (1.0 - ArmyGetHandicap(self.Army))
        local finalVal = amount - EntityGetHealth(self)
        if finalVal < 0 or type == "FAF_AntiShield" then
            finalVal = 0
        end
        return finalVal
    end,    

    -- QCE OnDamage function was here
    -- Moved to QUIET Base Repo -- 12/31/2024 -- Azraeelian Angel

    ApplyDamage = function(self, instigator, amount, vector, dmgType, doOverspill)
        -- cache frequently used values
        local tick = GetGameTick()
        local owner = self.Owner
        local myShieldType = self.MyShieldType

        -- damage correction for overcharge
        -- These preset damages deal `2 * dmg * absorbMult or armorMult`, currently absorption multiplier is 1x so we need to divide by 2
        if dmgType == 'Overcharge' then
            local wep = instigator:GetWeaponByLabel('OverCharge')
            local overchargeBp = wep:GetBlueprint().Overcharge
            if self.StaticShield then -- fixed damage for static shields
                amount = overchargeBp.structureDamage * 0.5  -- multiply is faster than divide
            elseif self.CommandShield then -- fixed damage for UEF bubble shield
                amount = overchargeBp.commandDamage * 0.5
            end
        end

        -- damage correction for overspill, do not apply to personal shields
        if myShieldType ~= "Personal" then
            local instigatorId = instigator and instigator.EntityId
            if instigatorId then
                local damagedTick = self.DamagedTick
                local damagedRegular = self.DamagedRegular
                local damagedOverspill = self.DamagedOverspill

                -- reset our status quo for this instigator
                if damagedTick[instigatorId] ~= tick then
                    damagedTick[instigatorId] = tick
                    damagedRegular[instigatorId] = false
                    damagedOverspill[instigatorId] = 0
                end

                -- anything but shield spill damage is regular damage, remove any previous overspill damage from the same instigator during the same tick
                if dmgType ~= "ShieldSpill" then
                    damagedRegular[instigatorId] = tick
                    amount = amount - damagedOverspill[instigatorId]
                    damagedOverspill[instigatorId] = 0
                else
                    -- if we have already received regular damage from this instigator at this tick, skip the overspill damage
                    if damagedRegular[instigatorId] == tick then
                        return
                    end

                    -- keep track of overspill damage if we have not received any actual damage yet
                    damagedOverspill[instigatorId] = damagedOverspill[instigatorId] + amount
                end
            end
        end

        -- do damage logic for shield
        if owner ~= instigator then
            local absorbed = self:OnGetDamageAbsorption(instigator, amount, dmgType)

            -- take some damage
            EntityAdjustHealth(self, instigator, -absorbed)

            -- check to spawn impact effect
            if dmgType ~= "ShieldSpill" then
                local liveImpacts = self.LiveImpactEntities
                if liveImpacts <= 10 then
                    ForkTo(self.CreateImpactEffect, self, vector)
                else
                    local r = Random(1, self.Size)
                    local sizeThreshold = 0.2 * self.Size
                    if not (r >= sizeThreshold and r < liveImpacts) then
                        ForkTo(self.CreateImpactEffect, self, vector)
                    end
                end
            end

            -- kill existing regen thread if present
            local regenThread = self.RegenThread
            if regenThread then
                KillThread(regenThread)
                self.RegenThread = nil
            end

            local currentHealth = EntityGetHealth(self)
            if currentHealth <= 0 then
                ChangeState(self, self.DamageRechargeState)
            else
                if self.OffHealth < 0 then
                    if self.RegenRate > 0 then
                        self.RegenThread = self:ForkThread(self.RegenStartThread)
                    end
                else
                    self:UpdateShieldRatio(0)
                end
            end
        end

        -- overspill damage checks
        if doOverspill
            and myShieldType ~= "Personal"
            and IsEntity(instigator)
            and amount > 1
            and dmgType ~= "ShieldSpill"
        then
            local spillAmount = self.SpillOverDmgMod * amount

            -- retrieve shields that overlap with us
            local others, count = self:GetOverlappingShields(tick)

            -- apply overspill damage to neighbour shields
            if count > 0 then
                for k = 1, count do
                    others[k]:ApplyDamage(
                        instigator,
                        spillAmount,
                        nil,
                        "ShieldSpill",
                        false
                    )
                end
            end
        end
    end,

    RegenStartThread = function(self)
		-- cache frequently used values
		local owner = self.Owner
		local regenRate = self.RegenRate
		local dead = self.Dead

		if ScenarioInfo.ShieldDialog then
			LOG("*AI DEBUG Shield Starts Regen Thread on "..repr(owner.BlueprintID).." "..repr(__blueprints[owner.BlueprintID].Description).." - start delay is "..repr(self.RegenStartTime) )

			if not owner.BlueprintID then
				LOG("*AI DEBUG "..repr(self))
			end
		end

		-- shield takes a delay before regen starts
        WaitTicks( 10 + (self.RegenStartTime * 10) )

        -- cache max health once
        local maxHealth = EntityGetMaxHealth(self)

        while not dead and EntityGetHealth(self) < maxHealth do
			-- regen the shield
			if not dead then
				EntityAdjustHealth(self, owner, regenRate)

				SetShieldRatio(owner, EntityGetHealth(self) / maxHealth)

				-- wait one second
				WaitTicks(11)

				-- update dead status
				dead = self.Dead
			end
        end
    end,

    CreateImpactEffect = function(self, vector)
        if IsDestroyed(self) then
            return
        end

        -- keep track of this entity
        self.LiveImpactEntities = self.LiveImpactEntities + 1

        -- cache frequently used values
        local army = self.Army
        local vc = VectorCached
        local impactEffects = self.ImpactEffects
        local impactMeshBp = self.ImpactMeshBp

        -- early exit if no effects to show
        if not impactEffects and impactMeshBp == '' then
            self.LiveImpactEntities = self.LiveImpactEntities - 1
            return
        end

        -- compute distance to offset effect only if needed
        local d = 0
        if vector and impactEffects then
            local x = vector[1] or 0
            local y = vector[2] or 0
            local z = vector[3] or 0
            d = LOUDSQRT(x * x + y * y + z * z)
        end

        -- allocate an entity
        local entity = Entity(self.ImpactEntitySpecs)

        vc[1], vc[2], vc[3] = EntityGetPositionXYZ(self)
        Warp(entity, vc)

        -- set the impact mesh and scale it accordingly
        if impactMeshBp ~= '' then
            EntitySetMesh(entity, impactMeshBp)
            EntitySetDrawScale(entity, self.Size)

            if vector then
                vc[1], vc[2], vc[3] = -vector[1], -vector[2], -vector[3]
                EntitySetOrientation(entity, OrientFromDir(vc), true)
            end
        end

        -- spawn additional effects
        if impactEffects then
            for _, v in impactEffects do
                local effect = CreateEmitterAtBone(entity, -1, army, v)
                if d > 0 then
                    IEffectOffsetEmitter(effect, 0, 0, d)
                end
            end
        end

        -- hold up a bit
        CoroutineYield(20)

        -- take out the entity again
        EntityDestroy(entity)

        self.LiveImpactEntities = self.LiveImpactEntities - 1
    end,

    OnDestroy = function(self)
	
		if ScenarioInfo.ShieldDialog then
			LOG("*AI DEBUG Shield OnDestroy for "..__blueprints[self.Owner.BlueprintID].Description )
		end
	
		self:SetMesh('')
		
		if self.MeshZ != nil then
			self.MeshZ:Destroy()
			self.MeshZ = nil
		end
        
        if self.RegenThread then
           KillThread(self.RegenThread)
           self.RegenThread = nil
        end
		
		self:UpdateShieldRatio(0)
		
		self.Dead = true
		
        ChangeState(self, self.DeadState)
		
    end,

    -- Return true to process this collision, false to ignore it.
    OnCollisionCheck = function(self,other)
	
		-- credit Balthazar and PhilipJFry for diagnosing and repairing
		if categories.SHIELDPIERCING then
			if LOUDENTITY( categories.SHIELDPIERCING, other ) then
				return false
			end
        end
		
		-- for rail guns from 4DC credit Resin_Smoker
		if other.LastImpact then
		
			-- if hit same unit twice
			if other.LastImpact == self.Owner.MyShield:GetEntityId() then
				return false
			end
		end
		
		if other.DamageData.DamageType == 'Railgun' then
			other.LastImpact = self.Owner.MyShield:GetEntityId()
		end
		
		local GetArmy = GetArmy
        return IsEnemy( self.Army, GetArmy(other) )
    end,

    TurnOn = function(self)
        ChangeState(self, self.OnState)
    end,

    TurnOff = function(self)
        ChangeState(self, self.OffState)
    end,

    IsOn = function(self)
        return false
    end,

    -- QCE IsUp function was here
    -- Moved to QUIET Base Repo -- 12/31/2024 -- Azraeelian Angel

    RemoveShield = function(self)
        self._IsUp = false
	
        self:SetCollisionShape('None')

		self:SetMesh('')
		
		if self.MeshZ != nil then
			self.MeshZ:Destroy()
			self.MeshZ = nil
		end

        self.Owner:OnShieldIsDown()
		
    end,

    CreateShieldMesh = function(self)
        local vec = VectorCached
        vec[1] = 0
        vec[2] = self.ShieldVerticalOffset
        vec[3] = 0
		
		self:SetParentOffset( vec )	

		self:SetCollisionShape( 'Sphere', 0, 0, 0, self.Size/2)

		self:SetMesh(self.MeshBp)

		self:SetDrawScale(self.Size)

		if self.MeshZ == nil then
		
			self.MeshZ = Entity { }

            Warp( self.MeshZ, self.Owner:GetPosition() )			

			self.MeshZ:AttachBoneTo(-1,self.Owner,-1)

            vec[1] = 0
            vec[2] = self.ShieldVerticalOffset
            vec[3] = 0
            
			self.MeshZ:SetParentOffset( vec )

			self.MeshZ:SetMesh(self.MeshZBp)

			self.MeshZ:SetDrawScale(self.Size)

			self.MeshZ:SetVizToFocusPlayer('Always')
			self.MeshZ:SetVizToEnemies('Intel')
			self.MeshZ:SetVizToAllies('Always')
			self.MeshZ:SetVizToNeutrals('Intel')
		end
		
        self.Owner:OnShieldIsUp()
        self._IsUp = true
    end,

    -- Basically run a timer, but with a visual bar
	-- The time value is in seconds but the charging up period can be slowed if resources are not available
    ChargingUp = function(self, curProgress, time)
        local owner = self.Owner
        owner:OnShieldIsCharging()

        -- cache the time divisor to avoid repeated division
        local timeInverse = 1.0 / time

        while not self.Dead and curProgress < time do
            curProgress = curProgress + GetResourceConsumed(owner)
			SetShieldRatio(owner, curProgress * timeInverse)
            WaitTicks(11)
        end
    end,

    OnState = State {

        Main = function(self)
			-- cache frequently used values and functions
			local owner = self.Owner
			local aiBrain = owner:GetAIBrain()
			local offHealth = self.OffHealth
			local regenRate = self.RegenRate

            self.Enabled = true

            -- If the shield was turned off; use the recharge time before turning back on
            if offHealth >= 0 then
                owner:SetMaintenanceConsumptionActive()

                self:ChargingUp(0, self.ShieldEnergyDrainRechargeTime)

                -- If the shield has less than full health, allow the shield to begin regening
                local currentHealth = EntityGetHealth(self)
                local maxHealth = EntityGetMaxHealth(self)
                if currentHealth < maxHealth and regenRate > 0 then
                    self.RegenThread = self:ForkThread(self.RegenStartThread)
                end
            end

            -- We are no longer turned off
            self.OffHealth = -1

            -- cache max health for ratio calculations
            local maxHealth = EntityGetMaxHealth(self)
            SetShieldRatio(owner, EntityGetHealth(self) / maxHealth)

            owner:OnShieldEnabled()
			self:CreateShieldMesh()

            WaitTicks(10)

            -- Test in here if we have run out of power
            while true do
				WaitTicks(5)

				SetShieldRatio(owner, EntityGetHealth(self) / maxHealth)

                if GetResourceConsumed(owner) ~= 1 and GetEconomyStored(aiBrain, 'ENERGY') < 1 then
					break
				end
            end

            ChangeState(self, self.EnergyDrainRechargeState)
        end,

        IsOn = function(self)
            return true
        end,
		
    },

    -- When manually turned off
    OffState = State {

        Main = function(self)
            self.Enabled = false

			-- No regen during off state
			if self.RegenThread then
				KillThread(self.RegenThread)
				self.RegenThread = nil
			end

            -- Set the offhealth - this is used basically to let the unit know the unit was manually turned off
      		self.OffHealth = GetHealth(self)

            -- Get rid of the shield bar
            self:UpdateShieldRatio(0)

            self:RemoveShield()
			
    		self.Owner:OnShieldDisabled()

            WaitTicks(10)
			
        end,

        IsOn = function(self)
            return false
        end,
    },

    -- This state happens when the shield has been depleted due to damage
    DamageRechargeState = State {
	
        Main = function(self)
			-- No regen during off state
			if self.RegenThread then
				KillThread(self.RegenThread)
				self.RegenThread = nil
			end
			
            self:RemoveShield()
            
            -- make the unit charge up before gettings its shield back
            self:ChargingUp(0, self.ShieldRechargeTime)
            
            -- Fully charged, get full health
            self:SetHealth(self, GetMaxHealth(self))
            
            ChangeState(self, self.OnState)
			
        end,
		
        IsOn = function(self)
            return false
        end,
    },

    -- This state happens only when the army has run out of power
    EnergyDrainRechargeState = State {
	
        Main = function(self)
			-- No regen during off state
			if self.RegenThread then
				KillThread(self.RegenThread)
				self.RegenThread = nil
			end
			
            self:RemoveShield()
            
            self:ChargingUp(0, self.ShieldEnergyDrainRechargeTime)
            
            -- If the unit is attached to a transport, make sure the shield goes to the off state
            -- so the shield isn't turned on while on a transport
            if not self.Owner:IsUnitState('Attached') then
			
                ChangeState(self, self.OnState)
				
            else
			
                ChangeState(self, self.OffState)
				
            end
			
        end,
        
        IsOn = function(self)
            return false
        end,
		
    },

    DeadState = State {
        Main = function(self)
			self.Dead = true
        end,

        IsOn = function(self)
            return false
        end,
    },
	
}

-- Unit shields typically hug the shape of the unit
UnitShield = ClassShield(Shield){

    RemainEnabledWhenAttached = true,

    OnCreate = function(self,spec)

        self.Trash = TrashBag()
        self.Owner = spec.Owner
        self.ImpactEffects = EffectTemplate[spec.ImpactEffects]        
        self.CollisionSizeX = spec.CollisionSizeX or 1
		self.CollisionSizeY = spec.CollisionSizeY or 1
		self.CollisionSizeZ = spec.CollisionSizeZ or 1
		self.CollisionCenterX = spec.CollisionCenterX or 0
		self.CollisionCenterY = spec.CollisionCenterY or 0
		self.CollisionCenterZ = spec.CollisionCenterZ or 0
		self.OwnerShieldMesh = spec.OwnerShieldMesh or ''

		Shield.OnCreate(self,spec)
        self.MyShieldType = 'Personal'

    end,

    ApplyDamage = function(self, instigator, amount, vector, dmgType, doOverspill)
        -- We want all personal shields to pass overkill damage
        -- Was handled by self.PassOverkillDamage bp value, now defunct
        if self.Owner ~= instigator then
            local overkill = self:GetOverkill(instigator, amount, dmgType)
            if overkill > 0 and self.Owner and IsUnit(self.Owner) then
                self.Owner:DoTakeDamage(instigator, overkill, vector, dmgType)
            end
        end

        Shield.ApplyDamage(self, instigator, amount, vector, dmgType, doOverspill)
    end,

    -- I've turned off impact effects on skin shields simply for performance 
    -- the effect is so small, and only lasts .3 seconds, it seemed an easy choice
    CreateImpactEffect = function(self, vector)
    end,

    CreateShieldMesh = function(self)
        -- Personal shields (unit shields) don't handle collisions anymore.
        -- This is done in the Unit's OnDamage function instead.
  		self:SetCollisionShape('None')
		
		self.Owner:SetMesh(self.OwnerShieldMesh,true)
		
        self.Owner:OnShieldIsUp()
		
    end,
	
    RemoveShield = function(self)
	
        self:SetCollisionShape('None')
		
		self.Owner:SetMesh(self.Owner:GetBlueprint().Display.MeshBlueprint, true)
		
        self.Owner:OnShieldIsDown()
		
    end,

    OnDestroy = function(self)
	
        if not self.Owner.MyShield or self.Owner.MyShield:GetEntityId() == self:GetEntityId() then
		
	        self.Owner:SetMesh(self.Owner:GetBlueprint().Display.MeshBlueprint, true)
			
		end
		
		self:UpdateShieldRatio(0)
        ChangeState(self, self.DeadState)
    end,

}

-- AntiArtillery shields are typical bubbles but only intercept certain projectiles
AntiArtilleryShield = ClassShield(Shield){

    OnCreate = function(self, spec)
        Shield.OnCreate(self, spec)
        self.MyShieldType = 'AntiArtilleryShield'
    end,

    OnCollisionCheckWeapon = function(self, firingWeapon)

        local bp = firingWeapon.bp
		
        if not bp.CollideFriendly then
		
            if self.Army == firingWeapon.unit.Army then
			
                return false
				
            end
			
        end
		
        -- Check DNC list
		if bp.DoNotCollideList then
		
			for _,v in bp.DoNotCollideList do
			
				if LOUDENTITY( LOUDPARSE(v), self) then
				
					return false
					
				end
				
			end
			
		end
		
        if bp.ArtilleryShieldBlocks then
		
            return true
			
        end
		
        return false
		
    end,

    -- Return true to process this collision, false to ignore it.
    OnCollisionCheck = function(self,other)
	
		local otherArmy = GetArmy(other)
	
        if otherArmy == -1 then
            return false
        end
		
        if other.DamageData.ArtilleryShieldBlocks and IsEnemy( self.Army, otherArmy ) then
            return true
        end
		
        if other:GetBlueprint().Physics.CollideFriendlyShield and other.DamageData.ArtilleryShieldBlocks then
            return true
        end
		
        return false
		
    end,
	
}

-- Hunker Shields take no damage while on --
DomeHunkerShield = ClassShield(Shield) {
	
	OnCollisionCheckWeapon = function(self, firingWeapon)
		return true
	end,

	OnCollisionCheck = function(self,other)
		if GetArmy(other) == -1 then
			return true
		end

		return true
	end,
}

-- Hunker Shields are time limited shields that take no damage --
PersonalHunkerShield = ClassShield(Shield) {

    OnCreate = function(self, spec)
        Shield.OnCreate(self, spec)
        self.MyShieldType = 'HunkerPersonal'
    end,


	OnDamage =  function(self,instigator,amount,vector,type)
	end, 

    CreateImpactEffect = function(self, vector)
    end,

    CreateShieldMesh = function(self)
	
		self:SetCollisionShape( 'Box', self.CollisionCenterX, self.CollisionCenterY, self.CollisionCenterZ, self.CollisionSizeX, self.CollisionSizeY, self.CollisionSizeZ)
		
		SetMesh( self.Owner, self.OwnerShieldMesh, true )
    end,

    RemoveShield = function(self)
	
        self:SetCollisionShape('None')
		
		SetMesh( self.Owner, self.Owner:GetBlueprint().Display.MeshBlueprint, true )
    end,

    OnDestroy = function(self)
	
        if not self.Owner.MyShield or self.Owner.MyShield:GetEntityId() == self:GetEntityId() then
		
	        SetMesh( self.Owner, self.Owner:GetBlueprint().Display.MeshBlueprint, true)
		end
		
		self:UpdateShieldRatio(0)
        ChangeState(self, self.DeadState)
    end,

}

ProjectedShield = ClassShield(Shield) {

    OnCreate = function(self, spec)
        Shield.OnCreate(self, spec)
        self.MyShieldType = 'Shield'
    end,

    OnDamage =  function(self,instigator,amount,vector,type)
	
        --Count how many projectors are going to be receiving the damage.
        local pCount = self:CheckProjectors()
		
        --If there are none, then something has happened and we need to kill the shield.
        if pCount == 0 then
            self.Owner:DestroyShield()
        else
            
			ForkThread(self.CreateImpactEffect, self, vector)

            --Calculate the damage now, once, and before we fuck with the numbers.
            self:DistributeDamage(instigator,amount,vector,type)
        end
    end,

    CheckProjectors = function(self)
	
        local pCount = 0
		
        for i, projector in self.Owner.Projectors do
		
            if IsUnit(projector) and projector.MyShield and projector.MyShield:GetHealth() > 0 then
                pCount = pCount + 1
            end
        end
		
        return pCount
    end,

    DistributeDamage = function(self,instigator,amount,vector,type)
	
        local pCount = self:CheckProjectors()
		
        if pCount == 0 and not self.Owner.Dead then
            self.Owner:OnDamage(instigator,amount,vector,type)
        end
		
        local damageToDeal = amount / pCount
        local overKillDamage, ProjectorHealth = 0,0
		
        for i, projector in self.Owner.Projectors do
		
            ProjectorHealth = projector.MyShield:GetHealth()
			
            projector.MyShield:OnDamage(instigator,damageToDeal,vector,type)
			
            --If it looked like too much damage, remove it from the projector list, and count the overkill
            if ProjectorHealth <= damageToDeal then
                overKillDamage = overKillDamage + LOUDMAX(damageToDeal - ProjectorHealth, 0)
                projector.ShieldProjectionEnabled = false
                projector:ClearShieldProjections()
            end
        end
		
        if overKillDamage > 0 then
            self:DistributeDamage(instigator,overKillDamage,vector,type)
        end
		
    end,

    CreateImpactEffect = function(self, vector)

        local AttachBeamEntityToEntity = AttachBeamEntityToEntity
        local CreateEmitterAtBone = CreateEmitterAtBone
        local WaitTicks = coroutine.yield

        if not self.Dead then
        
            local army = self.Army
            
            local OffsetLength = LOUDSQRT( LOUDPOW( vector[1], 2 ) + LOUDPOW( vector[2], 2 ) + LOUDPOW(vector[3], 2 ) )
            
            local ImpactMesh = Entity( self.ImpactEntitySpecs )
		
            Warp( ImpactMesh, self:GetPosition())
		
            if self.ImpactMeshBp then
                
                local vec = VectorCached

                vec[1] = -vector.x
                vec[2] = -vector.y
                vec[3] = -vector.z
                
                ImpactMesh:SetOrientation(OrientFromDir( vec ),true)            

                ImpactMesh:SetMesh(self.ImpactMeshBp)
                ImpactMesh:SetDrawScale(self.Size)

            end
            
            local beams = {}
	
            for i, Pillar in self.Owner.Projectors do

                if self:IsValidBone(0) and Pillar:IsValidBone('Gem') then
                    beams[i] = AttachBeamEntityToEntity(self, 0, Pillar, 'Gem', army, Pillar:GetBlueprint().Defense.Shield.ShieldTargetBeam)
                end
            end
            
            if self.ImpactEffects and not self.Dead then
		
                for k, v in self.ImpactEffects do
                    CreateEmitterAtBone( ImpactMesh, -1, army, v ):OffsetEmitter(0,0,OffsetLength)
                end
            end
		
            WaitTicks(5)
		
            for i, v in beams do
                v:Destroy()
            end
		
            WaitTicks(45)
        
            ImpactMesh:Destroy()
            
        end
        
    end,

    OnCollisionCheck = function(self,other)
    
        if self:CheckProjectors() == 0 then
            return false
        end
        
        return Shield.OnCollisionCheck(self,other)
    end,
}
end -- Do End
