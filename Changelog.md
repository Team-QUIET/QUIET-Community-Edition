---------------------------------------------
# QUIET
# Rebalance Changelog
---------------------------------------------

# 1.37

### T4 Aeon Avernus
(Comparable To King Kraptor)
Meant for dealing with Experimentals only, lacks almost any AOE so it's weak vs larger T3 Armies however deals massive precision DPS vs Experimentals. The bigger and heavier the Experimental, the better. (Except Avalanche lol)

### T4 Cybran Vulture
Receives Rocket Barrage Rework Equal to Madbolo

### Misc
Fix Hardlock on Naval Maps

# 1.36

### T4 Aeon Eliash
Transformed Personal Shield -> Bubble Shield

### T3 Aeon Mobile Artillery
Removed +20% Shield Damage

### T4 Cybran Madbolo
All Weapons Ranges Increases
Rework Primary Weapon Rocket Barrage (High Muzzle Velocity, More Accuracy, More Rockets)

### T3 UEF Brimstone
Yawspeed 27 -> 45
Fix Brimstone Overshooting

### T1 Mayor PD 
Yawspeed 45 -> 90

# 1.35

### T2 MML
Speed 3 -> 2.85

### T3 Mobile Artillery
Fix the unpack rate that was making units stuck in place

### T3 Barrage Artillery (Accouts for Overspill now in balancing)
DamageRadius reduced by 1 on all
FiringRandomness 1.25 -> 2.25

# 1.34

### Removed Roaming Behavior From All Experimentals

### Shields
General Info on shields is that they will take longer to regenerate, many stats have been standardized then redistributed to give a bit more diversity to the shields. 
Integrated Shields received a bit of a hard bonking as their stats were not justified by the current cost. They were all given 20k+ E Cost and around 500-1000 Mass Cost as well as given the regeneration nerfs and etc.
Shields offset were standardized a bit to prevent some of the outrageous shield layering. (Anti Artillery Shield for UEF is untouched by any of these changes as well as Cybran Shields inbetween the final & first upgrade)

All Square Shields have been removed and replaced by significantly buffed BrewLAN Experimental Shields that have been completely reworked to fit into the Experimental Phase of the game.

### T2 Cybran Hoplite
Range 42 -> 37

### T2 UEF Mongoose
Range 34 -> 32

### T3 Pervical | Brick | Harbinger
TurretYawSpeed 35 -> 90 

### T3 UEF Pervical 
Damage 900 -> 1450
RoF 0.5 -> 0.23

### T3 Aeon Harbinger
No Longer Fires two shoots in one Salvo
RoF increased to 2 (2 Shoots 2 Salvos)

### T3 Seraphim Thau Battery
-20% Reduction Against Shields Removed
DamageRadius 2 -> 3.5

### T4 Cybran Megalith
Energy Cost 450000 -> 785500

### Misc
Removed Cybran T3 Sniper

# 1.33

### Weapon States
All Weapon States (Excluding WeaponFiringState) have been rewritten to a cleaner standard and to reduce the amount of unnessacry states many units were going through. This causes latency and delay as well as other strange bugs in units.
This is a extremely deep and fundamental change to the game and I expect some units to be broken. (Please report them in our discord ASAP for hotfixes)

### Misc
Fix T2 UEF Statue rockets
Fix T2 UEF Pillar DPS
Fix T3 Aeon Wraith Pathfinding
Fix T3 Cybran Tripple Threat DPS & Firing States
Fix T3 UEF Brimstone DPS & Firing States
Fix T3 Aeon Mothra DPS & Firing States
Fix T3 Cybran Neolith DPS & Firing States
Fix Seraphim Commander not shooting the correct projectile

# 1.32

### Wraith
Acceleration 1.5 -> 2
BackUpDistance = 10
TurnFacingRate 20 -> 55
TurnRate 22 -> 50
RotateOnSpot = True
Fixed The Pathfinding & Improved the Micro on Wraith (This allows the guns to move more freely)

### Factories
T2 Engineers can now build T2 Factories
T3 Engineers can now build T3 Factories

### T2 Pillar Tank
Health 1250 -> 1500

### Misc
Removed Stun from Dalek, Thug, Anode, Hippo, Ambush Bot
Removed Notha & Vesinee
Fixed DPS & Damage on The T4 PD "Neolith"
Reverted Damage nerf to the T4 PD "Mothra"

# 1.31

### Shield Overspill
- DISCLAIMER: This significantly nerfs shields and SIGNIFICANTLY & FUNDAMENTALLY changes the entire flow of the game. It can not be stressed enough that when playing 1.31 please take this into account.

Shield Overspill is a brand new functionality for the LOUD Project. It introduces the ability for Weapons with AoE to spread the damage out through multiple shields. This effectively nerfs Mobile Shield Stacking, Static Shield Stacking & makes (T2, T3, T4) Artillery as well as any unit that wields a significant weapon with large AoE a massive threat to layered shielding. 

Currently AoE Damage is spread throughout shields by a 15% per Shield.


### T3 Seraphim Oteethka
Stun Duration 1 -> 0.15 (Seconds)
Stun Radius 1 -> 0.5
FiringRandomnessWhileMoving 0.5 -> 0.75

### T2 Cybran Hoptile
Removed Stun from Rockets

# 1.30

### T3 UEF Helltank
Removed AMPHIBIOUS
Removed SUBMERSIBLE
BuildCostEnergy = 15500, -- was 17500
BuildCostMass = 1425,  -- was 1725
-- Riot beams
MaxRadius = 14, -- was 28
Rocket Salvo from 44 MaxRadius to 42 MaxRadius
-- Railgun --
Damage = 875,    -- was 750
MaxRadius = 42,  -- was 40
RateOfFire = 0.225, -- was 0.3
-- Ravager --
Damage = 35, -- was 50
MaxRadius = 16, -- was 36
Health = 2750,  -- was 5150
MaxHealth = 2750, -- was 5150

### T3 UEF Juggernant
Health = 4200,  -- was 3150
MaxHealth = 4200, -- was 3150
BuildCostEnergy = 36000, -- was 24000
BuildCostMass = 3250,  -- was 1950
-- Gauss cannon
MaxRadius = 32, -- was 39
-- Gatling 2x
MaxRadius = 28, -- was 30

### T2 Cybran Mobile Bomb
It receives permanent cloak but has it's stealth removed
It can not be manually attacked into the target and will also cause 1.1k dmg if killed (volatile ability)

### T4 Cybran Basilisk
Basilisk receives a doubled veterancy level increase to account for it's extremely powerful AA capability

### ACU Overcharge Rework:
ACU Overcharge rework applies to all Commanders are a standardized number system.

commandDamage = 400,
energyMult = 0.9,
maxDamage = 25000,
minDamage = 1250,
structureDamage = 800,

This is the number table for all Commanders, CommandDamage and StructureDamage are unique hard values for all (Commanders & Structures)
Damage is calculated base off the Energy aviable in your storage and can use up to 90% of your energy storage.
The maxDamage it can deliver is 25000 however this takes significant amount of storage (the calculated value would be somewhere around 70k e storage)
The cooldown is rapid however takes around 3 seconds for a full recharge of the OC once used. 
-> EnergyDrainPerSecond = 1500,
-> EnergyRequired = 4500,

With around 20k e storage, your commander can now easily demolish his way through a T3.5 Army especially if he's a fully combat vetted and upgrade Commander. He will still struggle with Experimentals as the peak damage is VERY hard to reach.

### Removed Units
T3 UEF Ironfist

# 1.29

### T2 Seraphim Ilsavoh & T2.5 Ilsavoh
YawSpeed increased from 30 -> 90 or 75 (t2.5)

### T2 UEF Rommel
Rommel Tech 3 -> Tech 2
All Stats generally taken from the T2 Banshee

### T4 Mothra
Damage 2950 -> 1475
DamageRadius 2.5 -> 2
Range 100 -> 88

### Unit Removal
UEF: 
T2 Janus, T3 Warhammer, T4 Rampage, T2 Banshee
Cybran:
T2 Cosair
All: 
Experimental Resource Storages

UEF Pillar / Cybran Hoplite / UEF Mongoose
TurretYawSpeed from 45 -> 90

### T2 Cybran Ambush Unit
Removed Stealth
Cloaking is always on now
Health 900 -> 1000
RegenRate 1 -> 7.5
Range increased to 30 from 28

### T2.5 UEF Land Unit
FiringRandomness 0.3 -> 0 (Guass Weapons)
FiringRandomnessWhenMoving 0.9 -> 0.35 (Guass Weapons)
FiringRandomness 0.3 -> 0 (Gatling Weapons)
MuzzleVelocity 29 -> 30
TurretYawSpeed 45 -> 60 (Gatling Weapons)

### T1.5 Land Units
All speed reduced from 3.1-3.4 to a generalized 2.65-2.7 MaxSpeed
Acceleration reduced from 1.5 to 1.15 in most cases (this is also generalized)
T1.5 Aeon Unit receives a rocket range reduction from 34 to 28
T1.5 UEF Unit receives 1 DamageRadius & range standardized with other T1.5 units as it's speed is standardized now.

### Misc
Athusil Hitbox is fixed so Laser Units don't miss
Mongoose Snap Behavior and Gatling Gun sometimes locking up completely is now fixed
Slink Cloak now fully works and does not require you to reenable it after it fires

# 1.28

### T1 Shard AA Boat
Shard receives a significant 20 -> 12.5 DPS Nerf as well as AoE Reduction from 2 -> 1.25 to stop it from dominating T2 Torpedo Bombers via spam.

### T2 Submarine Hunters
Projectile Count Reduced from 3 -> 1
Damage reduced by 50%
SalvoDelay increase to 1 Second on all T2 Submarines
Torpedo Defense on Submarine Hunters from 9 -> 23 RoF 
Torpedo Defense Range on Submarine Hunters from 3.2 -> 3.3

### T2 Destroyers
T2 Destroyers receive another Torpedo Defense Buff to combat submarines 

### Overhaul
-- Air Overhaul introduces many fixes to physics of Bombers & Rebalancing of Fighters to many T2 Fighters relevant and T1 Fighters far less effective
T1 Air Fighters:
20 HP Reduction 
5-10% DPS Reduction
T2 Air Fighters:
50% Increase in Dps
3k E Cost Reduction
30 M Cost Reduction
Health: 1300 - 1500 (Depending on Faction)
Misc:
All Bombers physics reworked to allow them to properly be micro'd and bombs dropped significantly better

# 9/15/24

### T3 Seraphim Submarine
Slight Nerf to Seraphim Submarine to prevent the meta where you would shift g 5-6 seraphim subs on top of each other and their torp defense would infinitely be able to defend a SIGNIFICANT amount of torps.

### T2 Destroyers
All Torpedo Defense on Destroyers significantly buffed should be able to crush T1 Subs at a relative similar cost efficiency

### T2 Torpedo Bombers
Torpedo Bombers nerfed to original 800-860 Health Values with a slight increase in E cost & M cost.
Relative Cost increase was 2k more e and 50 more mass

### Bombers
Fixed Bombers not dropping bombs properly also nerfs dodge micro against bombers as well, i.e means early bombers and such are much stronger and harder to dodge

### T2 Static Flak & T3 Static Flak
-- Buff Flak against Gunships & Remove most of it's usefulness against fast flying strategic bombers and fighters (Making sams more useful)
Comparable Values to the Static except higher rank and generally more damage (although of course more cost)

### T2 Cybran Immortal
-- Cybran should NOT be receiving Stealth or Cloak on 99% of their units as they have powerful mobile stealth & cloaking fields in both T2 & T3
Removed Stealth

### Misc
Fix Target Priorities for certain units. They will target Protector Bots properly again.
Evenflow is now integrated into Economy & Flow. It is now strongly recommended to use this version as it goes hand and hand with LCE. 
Additional tweaks into Economy & Flow include Hydrocarbons put into line with T2 Pgen & T3 Pgen cost and production of energy.
Another Additional tweak includes reduction in buildtime on the Enhancements on T3 Factories
Fixed T3 Seraphim SAM Missing ASF & Strategic Bombers
Fixed Czar never catching up to a target when using an attack command

# 9/14/2024 

### Aeon T2 Sniper
Reload Speed 6 -> 7 Seconds
Removed Stealth
MaxSpeed 3.8 -> 3.6

### T2 Mobile Flak
-- Buff Flak against Gunships & Remove most of it's usefulness against fast flying strategic bombers and fighters (Making sams more useful)
All Flak:
Normalize Speed to Allow Micro'ing
DamageRadius: 1.5 -> 3
TurretYaw: 360 -> 180
TurretYawSpeed: (A: 45 | C: 30 | U: 60 | S: 40)
Muzzle Velocity: 48 -> 20
FiringRandomness: 0.5 -> 2.5
MaxRadius: 36 -> 40
Significant Buff to TargetPriorities

### T3 Sniper
-- Snipers are all now more nimble to allow micro & also to allow them to be relevant especially in LOUD where there is a lot more Indirect then Vanilla or FAF (Might still need more buffs)
Normalize Speed to Allow Micro'ing
Significant Buff to TargetPriorities
DamageType = 'ShieldMult1.2',  (20% Shield Damage)
FiringTolerance: 0.1 -> 2
Aeon:
ReloadSpeed: 9 -> 6 Seconds
TurretYaw: 360 -> 180
TurretYawSpeed: 30 -> 90
Removed Unpacking Animation
Seraphim: 
-> SniperMode
FiringTolerance: 0.1 -> 3
ReloadSpeed: 19 -> 10 Seconds
TurretYaw: 360 -> 180
TurretYawSpeed: 30 -> 90

# 9/12/2024

### UEF T4 Goliath
Significant Buff to TargetPriorities
Forced the Goliath to turn with it's weapons when not being moved commanded
Reclassed to Breacher Class 
Added Effects to it's Missile Barrage
Health 104000 -> 124000
Missile Barrage:
Firing Randomness 3 -> 5
Damage 600 -> 1000
DamageRadius 3 -> 4
ProjectileLifetimeUsesMultiplier = 1
Missiles now ZigZag and create a random scatter barrage meaning the missiles no longer all hit the targetground perfectly. (This makes it extremely hard for TMD to intercept them)
Missile Health 1 -> 2
MaxSpeed 20 -> 10
Flamerthrower Arms:
DPS: 480 DPS -> 880 DPS
Death Nuke: 
Damage 14,700 -> 32,890
InnerRadius 12 -> 18
OuterRadius 24 -> 38


# 9/10/2024

Fixed Barrage Artillery not being correctly modified
Added Submod called "Economy & Flow" will be added to modlist when you add the full LCE to your usermods folder.
Economy & Flow affects factories cost, mass extractor income & cost and will eventually include a custom version of Evenflow.
Removed AirSpawnWaves from all AIs in LOUD

# 9/8/2024 (V1.22)

### Reclaim
Reclaim that contains 90% of it's mass or higher is reduced to 75% however if the reclaim is lower then 75% on a unit's wreckage it is brought back up to 75%

### T1 & T2 Land
-- T1 & T2 were overperforming especially T1 Land against both T2 & T3, similarly T2 was overperforming vs T3. The intended purpose of this change is to extend the gap between tiers.
Removed 12% Speed & Health Buff given to T1 Land in Blueprints.lua
Removed 6% Speed & Health Buff given to T2 Land in Blueprints.lua

### T3 Barrage Artillery
-- Barrage Artillery is buffed to make it more cost efficient vs building additional T2 Artillery
Aeon: 
Damage 265 -> 530
DamageRadius 2 -> 3
UEF:
Damage 1500 -> 3000
DamageRadius 2 -> 3
Cybran:
Damage 1200 -> 2400
DamageRadius 2.8 -> 3.8
StunRadius 2 -> 3
Seraphim: 
Damage 1300 -> 2600
Damage Radius 2.4 -> 3.4
DamageType Normal -> ShieldMult1.5 (50% More Damage to Shields)
Muzzle Velocity 33 -> 66
(Redid TargetPriorities for All T3 Barrage)

### T4 Eliash Medium Rapid Assault Bot
-- The Eliash receives a small buff to it's personal shield
Shield 21000 -> 26000
ShieldRegenStartTime 1 -> 0.5

# 9/3/2024 (V1.02/V1.021 Release)

### T3 Triseptitron 
Rocket Damage 125 -> 215
Range 80 -> 90 
DamageRadius 2 -> 2.5
FiringRandomness 1.4 -> 4
Fixed issue where it was overshooting it's target always

### T4 Galactic Colossus (GC) / T4 Universal Colossus (UC)
Fixed GC/UC Tractor Claws (This makes them SIGNIFICANTLY more powerful)
GC/UC Tractor Claws now crush units over time that have a health over 5000
UC Tractor Claws deal 9999 every 11 Ticks
GC Tractor Claws deal 4999 every 11 Ticks

### T4 Eliash Medium Rapid Assault Bot
Mass Cost 26000 -> 21000
Energy Cost 420000 -> 480000
Health 66500 -> 18500
Shield = 21000
ShieldRegenRate = 240
ShieldRechargeTime = 12
Main Weapon 10000 -> 5000 DPS
EnergyDrainPerSecond = 650,
EnergyRequired = 3250,
AA Weapon 300 -> 400 Damage
Buffed Auto TargetPriorities

### T2 Aeon Sniper
TargetPriorities Readjusted to increase Micro Focus
Remove Shield Ignoring from Projectile
MaintenanceConsumptionPerSecondEnergy 20 -> 50

# 9/2/2024 (V1.0.1 Release)

Hotfix for T2 Aeon Sniper not firing

# 9/2/2024 (V1.0.0 Release)

### Reclaim Changes
-- Reclaim Changes were simple. The Single Goal in Mind was to encourage early aggression but punish late game mistakes i.e losing entire army without delivering significant damage.
All Wrecks have been fixed to prevent permanent disappear of Wreckage/Reclaim
Overkill Ratio on Wreckage disappearing has been changed from 10% to 30% meaning you have to overkill said unit by 30% to not receive the wreckage
Naval Reclaim no lower gives 30% of the energy in the Wreckage

### T3 Penetration Bombers
-- Pen Bombers are very strong, with the ability to easily punch through most AA & having cheap stealth. This change was needed to prevent early Pen Bomber Rushes specifically in Teamgames. Many changes are aimed at some of the first steps towards significantly diversifying units
Aeon:
Mass Cost 4300 -> 5300
Energy Cost 165000 -> 195000
Stealth Energy Cost Upkeep 50 -> 250
MaxAirspeed 19 -> 17
MinAirspeed 15 -> 14
TurnSpeed 1.0 -> 1.1
UEF: 
Mass Cost 4750 -> 5750
Energy Cost 180000 -> 2100000
Stealth Energy Cost Upkeep 50 -> 300
Health 6800 -> 7200
MaxAirspeed 19 -> 18
TurnSpeed 1.0 -> 0.8
Small Yield Nuclear Bomb Damage 1900k -> 1200
Lancer Standoff ASM Barrage Damage 600 -> 1150
Lancer Standoff ASM Barrage DamageRadius 2 -> 3.5
Cybran: 
Mass Cost 4750 -> 5500
Energy Cost 180000 -> 190000
Stealth Energy Cost Upkeep 50 -> 300
Health 4750 -> 4250
RegenRate 10 -> 25
MaxAirspeed 19 -> 20
MinAirspeed 15 -> 16
TurnSpeed 1.0 -> 1.1
Seraphim: 
Mass Cost 4750 -> 5750
Energy Cost 180000 -> 195000
Stealth Energy Cost Upkeep 50 -> 250
Health 6250 -> 5250
MaxAirspeed 19 -> 18
MinAirspeed 15 -> 14
Bombs 3200 -> 4200

### T3 Static Artillery
Revert to the FAF Cost of T3 Static Artillery

### T2 Aeon Sniper
-- The Aeon Sniper was dominating T2, T3, and even early T4 Phase in some games, this called for a immediate nerf. It's main strength lies in its speed and with the reduction, it should allow players to catch them much easier. The cost will also make them less efficient and the EnergyRequired will make the Reload much longer as well by 3 more seconds.
Mass Cost 320 -> 465 
Energy Cost 3850 -> 5050
MaxSpeed 4.0 -> 3.8
EnergyRequired (Recharge - Main Weapon) 880 -> 1320

# T3 Mobile Sensor Arrays
-- Mobile Sensor Arrays Omni was too small combined with the small omni on static radar led to Stealth & Cloak being far too powerful & annoying for players.
Energy Cost Upkeep 850 -> 1500
OmniRadius 56 -> 112