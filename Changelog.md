QUIET
===============	
Rebalance Changelog
---------------

# 1.58

### T2 Gunships
- Health: 1400 -> 1100

### ACU
- Removed AirLayer Targetting

### ACU (Cybran)
- Fix Cybran ACU Laser

### Misc
- Fix A Few Blueprint Variables 
- Fix Amphorak Blueprint

# 1.57

### Misc
- Fix UEF ACU Firing when reclaiming
- Fix Gunships having bad Yaw & Pitch Rates
- Fix Cybran Engineers being unkillable

# 1.56

### ACU
- Main Gun Rate Of Fire: 2 -> 1

### Misc
- Fix T2 UEF Tactical Bomber Dropping Bomb Too Early
- Fix AoE Applying 1 Tick Too Late
- Fix T2 Fighters Not Being Able To Hit T2 Tactical Bombers
- Fix T2 Sniper YawRate

# 1.55

### Misc
- YawRates have been increased on many PDs 
- Fixed Bone Issue on the Mastodon Rocket Pods causing them to miss
- Fixed Many Audio Issues on Total Mayhem Units

# 1.54

### Air
- Removed Debuffs to Speed when Aircraft is Damaged
- Removed Debuffs to FuelRatio from all `flak/maa/staticaa` when Aircraft is Damaged

### T4 UEF Star Adder
- Fixed Star Adder Lasers Missing 
- Reworked Lasers to be two seperate weapons
- PPC Cannons Damage: 1000 -> 2000
- Beam Laser Damage: 350 -> 175
- Beam Lasers Now Rapid Fire To Balance Out Damage Decrease
- Fixed Walking Animation To Make Him Not `Slide`

### T2 MML 
- All Speed Nerfed By 0.05
- Many Other Stats Standardized Across The Board
- MMLs should all be around the Same Strength with `Cybran Viper` being the best

### T3 Cybran Leviathan
- Torp Defense Rate of Fire: 8 -> 20 `**Twenty Would Mean Lower In This Case**`

### Misc
- Removed Variable Transport Speeds Due To Multiple Bugs
- Fixed Penetrator Bombers Not Dropping Bombs Reliably
- Fixed QCE not being enabled properly

# 1.53

### T3 Pen Bombers
- Fix Pen Bombers sometimes not dropping when they should

### T3 Cybran Sub Hunter
- Nerf Torpedo Defense Rate Of Fire from 8 to 20

# 1.52

### ACU Engineer Upgrades
- Buildtime, Mass, and Energy Reduced by 25%

### Bombers
- All Bomber Projectiles have been returned to Vanilla Physics
- All Bomber Projectiles no longer home-in on targets

- Too compensate for this, all bombers receive `large AoE Buffs`, T2 Bombers also receive `Damage Buff`

### T3 UEF Brimstone
- Fixed Brimstone MuzzleBones not existing `(Causing massive LOG Spam)`

# 1.51

### Misc
- Fixed TransportSpeedReduction NIL
- Fixed SSL0311 Shield Not Stopping AoE

# 1.50

### Transports
The movement speed of transports now changes based on how many and which types of units they have loaded.
- Units slow down transports based on their `TransportSpeedReduction` stat. If a unit has a `TransportSpeedReduction` of 1, each instance of this unit will slow down the transport's `MaxAirspeed` by 1. The primary implication of this change is that the effectiveness of the later T2/T3 Transport Drops are significantly reduced in an intuitive way. Although this adds an additional mechanic to the game that encourages more micro and strategic thinking when placing units on a transport.
- TransportSpeedReduction: 0.15 (Tech 1 land units)
- TransportSpeedReduction: 0.3 (Tech 2 land units)
- TransportSpeedReduction: 0.6 (Tech 3 land units)
- TransportSpeedReduction: 1 (ACUs and SACUs)
- TransportSpeedReduction: 1 (Tech 4 land units)

### Misc
Fixed Miasma Artillery Overshooting `2nd Fix`
All LOUD Standard Mods are now required to run QUIET to prevent crashing if you were not loading all the LOUD Standard Mods by accident

# 1.49

# Mavor & RFSAC
**Included Additional Units That Had RackSalvoFiresAfterCharge Within QCE** <br>
**Mavor now has RackSalvoFiresAfterCharge set to true to provide it with accurate Rate of Fire** <br>

# T2 Destroyers
RackSalvoReloadTime: 3.5 Seconds

# T3 UEF Juggernaut
Shield: 2250 -> 4400

# T3 Aeon Armillary
Rate Of Fire: 30/10 -> 13/10

# 1.48

### Global 
**All Units Guard Radius are now all santized and standardize. This will heavily improve usage of Patrol & Attack Move.** <br>
**Units now no longer walk into enemy when on Attack Move and Engineer Attack Move when reclaiming will perform significantly better** <br>

**All Units now have significantly more accurate Overlays for different Weapon Ranges. Any Unit that was missing Weapon Ranges will now have them displayed properly and accurately.** <br>

**All Units now have accurate speeds that cooperate better with their collision box and collision sphere size. This will enable Gunships & Beam Weapons to hit significantly more often** <br>

**All Units now have an AverageDensity based on HP which allows the Engine determine who pushes who in a collision event. This allows heavier units to move through lighter units with ease and heavily improves Pathfinding in certain situations.** <br>

**All Weapons [Units] now have a standardized and santized TargetCheckInterval based on their weapon type. Weapons also all have a standardized TrackingRadius and Variables included [AlwaysRecheckTarget] are now also standardized and will significantly improve Weapon Behavior** <br>

**Props now have a much larger visual display and should appear much easier and at a higher camera angle then previously** <br>

### Seraphim ACU
**Lower Number is Buff** <br>
ACU Lambda Rate of Fire: 9 -> 7 <br>

### T3 Mobile Artillery
Mass Cost: 500 -> 800

### Seraphim TMD
Rate of Fire: 1.05 -> 1.3

### Misc
Fix T4 Cybran Monkeylord Weapons being Broken <br>
Remove T3 UEF Walrus <br>

# 1.47

Fixed 7.13 WeaponState Issue <br>
A Long Term Fix is being worked on for future releases <br>

# 1.46

### Physics Reworks 
**Physics Reworks allow them to be more microable and able to drop bombs more reliably** <br>
Penetrator Bombers T3 <br>
Gunships T3 (Including Penetrator Gunships) <br>

### ACUs
[Main-Gun]
Damage: 120 -> 100

### T2 Destroyers
[Torpedo-Defense]
MuzzleSalvoDelay: 0 -> 0.2

### Misc
All Units now have the DRAGBUILD Category <br>
Removed T4 UEF Ivan  <br>

# 1.45

### Yaw Rate Increase
Many units have received a 2 second~ Yaw Rate now and should be microable this applies to most units in the game currently

### T3 UEF Banisher
ROF: 25/10 -> 18/10 <br>
AA Missile Denations at 10 Height Now <br>

### T3 Aeon Armillary
Damage: 75 -> 65

### T3 Cybran Hailfire
FiringRandomnessWhileMoving: 0.7 -> 0.5

### T4 Aeon Pillar of Prominence
ShieldRegenRate: 230 -> 520 (Allows it's shields on other units to be healed more quickly)

### T3 Cybran Dervish
Dervish Rockets receive the same rework as Madbolo & Vulture

### T3 UEF Bull
[Rockets] <br>
MuzzleChargeDelay: 0.6 -> 0.3 <br>
MaxRadius: 48 -> 44 <br>

### T3 Cybran Mastodon
[Rockets]
FiringRandomnessWhileMoving: 3.5 -> 1.5

### T1 Aeon Wavecrest
MuzzleSalvoDelay: 0.3 -> 0.2

# 1.44

### T1 Cybran Sky Slammer
FiringTolerance 0.6 -> 3 <br>
YawTurretSpeed 36 -> 135 <br>

### T1 Aeon Artos
Health 210 -> 140 <br>
(Missile) Range 32 -> 30 <br>

### T1 Scouts
Stealth Removed

### T4 Aeon Eliash
Mass Cost 21000 -> 26000

### T4 Cybran Vulture
Please refer to PR #220 for the extensives changelog

### Misc
Fixed Evenflow not applying to all units if one unit contained "IgnoreEvenflow" Value. <br>
Fixed T3 Cybran PD "Hades" <br>

# 1.43

### ACU
TurretYawSpeed [Main Weapon] 48 -> 90  <br>
Main Weapon Damage 70 -> 120 <br>
Range Equalized to OverCharge Range of 30 <br>
Speed from 1.45 -> 1.7 <br>

### T1.5
All T1.5 now are the first users of the ability to ignore Evenflow <br>
They now follow guidelines of a much heavier buildtime with some slight reductions in cost and some factional diversity increase (this is an ongoing effort) <br>
Please Review PR #219 for the stat changes <br>

### Misc
Fix Thau Battery Projectiles disappearing before hitting the ground

# 1.42

### T4 Cybran Madbolo
MassCost 21750 -> 30000
EnergyCost 300000 -> 475000

### Misc
Fix Thug being unbuildable (2nd try)
Fix Scorpion having Stealth

# 1.41 

Many Units have received YawTurretSpeed Buffs to allow them to be microable if you are interested in what units please check PR #209 for reference

### T2 Aeon Amphorak
Damage is brought in line with other T2.5 (Around 120DPS) <br>
No longer cost energy to fire <br>

### T2 Cybran Hoplite
RoF = 10/40 <br>
Damage reduced from 75 -> 65 <br>

### Misc
Fixed AI not being able to Overcharge <br>
Introduce Various new economic rebalances in our Submod called QCE Economy & Flow, please refer to commit # 707be96325bcbae0951caf29d76962611acad45a for reference <br>
Fixed Avernus Shoulder Cannon Projectile being extremely small <br>
Fixed Eliash not actually having a visual shield on the unit  <br>
Fixed Thug PD not being buildable <br>
Fixed Pegasus ShieldIsUp (AoE can not splash through the Pegasus Personal Shield) <br>

# 1.40

### T2 UEF Mongoose

Grenade Launcher: Damage 62 -> 49  <br>
RoF for Gatling Gun 1 Second -> 1.2 Second <br>

### Overcharge

Energy Ratio 6 -> 9 (TLDR It takes more energy to do more damage)

### T3 Barrage Artillery

Nerfed FiringRandomness 1.25 -> 2.25 <br>
AoF nerfed from by a universal number of 1 <br>

### Misc
Fixed Dragonite Shield Not Actually Protecting It <br>
Fixed Eliash Shiled Not Actually Protecting It <br>

# 1.39

### T1, T2, T3 Aeon Artillery

Fix Artillery Overshooting for Aeon

# 1.38

### Torpedo Defenses

All vanilla torpedo defenses have been 'altered' so that they are now targetable by surface weapons

# 1.37

### T4 Aeon Avernus
**Comparable To King Kraptor** <br>
Meant for dealing with Experimentals only, lacks almost any AOE so it's weak vs larger T3 Armies however deals massive precision DPS vs Experimentals. The bigger and heavier the Experimental, the better. (Except Avalanche lol) <br>

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

All Weapons Ranges Increases <br>
Rework Primary Weapon Rocket Barrage (High Muzzle Velocity, More Accuracy, More Rockets) <br>

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

DamageRadius reduced by 1 on all <br>
FiringRandomness 1.25 -> 2.25 <br>

# 1.34

### Removed Roaming Behavior From All Experimentals

### Shields

General Info on shields is that they will take longer to regenerate, many stats have been standardized then redistributed to give a bit more diversity to the shields. <br>
Integrated Shields received a bit of a hard bonking as their stats were not justified by the current cost. They were all given 20k+ E Cost and around 500-1000 Mass Cost as well as given the regeneration nerfs and etc. <br>
Shields offset were standardized a bit to prevent some of the outrageous shield layering. (Anti Artillery Shield for UEF is untouched by any of these changes as well as Cybran Shields inbetween the final & first upgrade) <br>

All Square Shields have been removed and replaced by significantly buffed BrewLAN Experimental Shields that have been completely reworked to fit into the Experimental Phase of the game. <br>

### T2 Cybran Hoplite

Range 42 -> 37

### T2 UEF Mongoose

Range 34 -> 32

### T3 Pervical | Brick | Harbinger

TurretYawSpeed 35 -> 90

### T3 UEF Pervical

Damage 900 -> 1450 <br>
RoF 0.5 -> 0.23 <br>

### T3 Aeon Harbinger

No Longer Fires two shoots in one Salvo <br>
RoF increased to 2 (2 Shoots 2 Salvos) <br>

### T3 Seraphim Thau Battery

-20% Reduction Against Shields Removed
DamageRadius 2 -> 3.5

### T4 Cybran Megalith

Energy Cost 450000 -> 785500

### Misc

Removed Cybran T3 Sniper

# 1.33

### Weapon States

All Weapon States (Excluding WeaponFiringState) have been rewritten to a cleaner standard and to reduce the amount of unnessacry states many units were going through. This causes latency and delay as well as other strange bugs in units. <br>
This is a extremely deep and fundamental change to the game and I expect some units to be broken. (Please report them in our discord ASAP for hotfixes) <br>

### Misc

Fix T2 UEF Statue rockets <br>
Fix T2 UEF Pillar DPS <br>
Fix T3 Aeon Wraith Pathfinding <br>
Fix T3 Cybran Tripple Threat DPS & Firing States <br>
Fix T3 UEF Brimstone DPS & Firing States <br>
Fix T3 Aeon Mothra DPS & Firing States <br>
Fix T3 Cybran Neolith DPS & Firing States <br>
Fix Seraphim Commander not shooting the correct projectile <br>

# 1.32

### Wraith

Acceleration 1.5 -> 2 <br>
BackUpDistance = 10 <br>
TurnFacingRate 20 -> 55 <br>
TurnRate 22 -> 50 <br>
RotateOnSpot = True <br>
Fixed The Pathfinding & Improved the Micro on Wraith (This allows the guns to move more freely) <br>

### Factories

T2 Engineers can now build T2 Factories <br>
T3 Engineers can now build T3 Factories <br>

### T2 Pillar Tank

Health 1250 -> 1500

### Misc

Removed Stun from Dalek, Thug, Anode, Hippo, Ambush Bot <br>
Removed Notha & Vesinee <br>
Fixed DPS & Damage on The T4 PD "Neolith" <br>
Reverted Damage nerf to the T4 PD "Mothra" <br>

# 1.31

### Shield Overspill

- DISCLAIMER: This significantly nerfs shields and SIGNIFICANTLY & FUNDAMENTALLY changes the entire flow of the game. It can not be stressed enough that when playing 1.31 please take this into account. <br>

Shield Overspill is a brand new functionality for the LOUD Project. It introduces the ability for Weapons with AoE to spread the damage out through multiple shields. This effectively nerfs Mobile Shield Stacking, Static Shield Stacking & makes (T2, T3, T4) <br> Artillery as well as any unit that wields a significant weapon with large AoE a massive threat to layered shielding. <br>

Currently AoE Damage is spread throughout shields by a 15% per Shield. <br>

### T3 Seraphim Oteethka

Stun Duration 1 -> 0.15 (Seconds) <br>
Stun Radius 1 -> 0.5 <br>
FiringRandomnessWhileMoving 0.5 -> 0.75 <br>

### T2 Cybran Hoptile

Removed Stun from Rockets

# 1.30

### T3 UEF Helltank

Removed AMPHIBIOUS <br>
Removed SUBMERSIBLE <br>
BuildCostEnergy = 15500, -- was 17500 <br>
BuildCostMass = 1425, -- was 1725 <br>
-- Riot beams <br>
MaxRadius = 14, -- was 28 <br>
Rocket Salvo from 44 MaxRadius to 42 MaxRadius <br>
-- Railgun -- <br>
Damage = 875, -- was 750 <br>
MaxRadius = 42, -- was 40 <br>
RateOfFire = 0.225, -- was 0.3 <br>
-- Ravager -- <br>
Damage = 35, -- was 50 <br>
MaxRadius = 16, -- was 36 <br>
Health = 2750, -- was 5150 <br>
MaxHealth = 2750, -- was 5150 <br>

### T3 UEF Juggernant

Health = 4200, -- was 3150 <br>
MaxHealth = 4200, -- was 3150 <br>
BuildCostEnergy = 36000, -- was 24000 <br>
BuildCostMass = 3250, -- was 1950 <br>
-- Gauss cannon <br>
MaxRadius = 32, -- was 39 <br>
-- Gatling 2x <br>
MaxRadius = 28, -- was 30 <br>

### T2 Cybran Mobile Bomb

It receives permanent cloak but has it's stealth removed <br>
It can not be manually attacked into the target and will also cause 1.1k dmg if killed (volatile ability) <br>

### T4 Cybran Basilisk

Basilisk receives a doubled veterancy level increase to account for it's extremely powerful AA capability

### ACU Overcharge Rework:

ACU Overcharge rework applies to all Commanders are a standardized number system. <br>

commandDamage = 400, <br>
energyMult = 0.9, <br>
maxDamage = 25000, <br>
minDamage = 1250, <br>
structureDamage = 800, <br>

This is the number table for all Commanders, CommandDamage and StructureDamage are unique hard values for all (Commanders & Structures) <br>
Damage is calculated base off the Energy aviable in your storage and can use up to 90% of your energy storage. <br>
The maxDamage it can deliver is 25000 however this takes significant amount of storage (the calculated value would be somewhere around 70k e storage) <br>
The cooldown is rapid however takes around 3 seconds for a full recharge of the OC once used. <br>
-> EnergyDrainPerSecond = 1500, <br>
-> EnergyRequired = 4500, <br>

With around 20k e storage, your commander can now easily demolish his way through a T3.5 Army especially if he's a fully combat vetted and upgrade Commander. He will still struggle with Experimentals as the peak damage is VERY hard to reach. <br>

### Removed Units

T3 UEF Ironfist

# 1.29

### T2 Seraphim Ilsavoh & T2.5 Ilsavoh

YawSpeed increased from 30 -> 90 or 75 (t2.5)

### T2 UEF Rommel

Rommel Tech 3 -> Tech 2 <br>
All Stats generally taken from the T2 Banshee <br>

### T4 Mothra

Damage 2950 -> 1475 <br>
DamageRadius 2.5 -> 2 <br>
Range 100 -> 88 <br>

### Unit Removal

UEF: <br>
T2 Janus, T3 Warhammer, T4 Rampage, T2 Banshee <br>
Cybran: <br>
T2 Cosair <br>
All: <br>
Experimental Resource Storages <br>

UEF Pillar / Cybran Hoplite / UEF Mongoose <br>
TurretYawSpeed from 45 -> 90 <br>

### T2 Cybran Ambush Unit

Removed Stealth <br>
Cloaking is always on now <br>
Health 900 -> 1000 <br>
RegenRate 1 -> 7.5 <br>
Range increased to 30 from 28 <br>

### T2.5 UEF Land Unit

FiringRandomness 0.3 -> 0 (Guass Weapons) <br>
FiringRandomnessWhenMoving 0.9 -> 0.35 (Guass Weapons) <br>
FiringRandomness 0.3 -> 0 (Gatling Weapons) <br>
MuzzleVelocity 29 -> 30 <br>
TurretYawSpeed 45 -> 60 (Gatling Weapons) <br>

### T1.5 Land Units

All speed reduced from 3.1-3.4 to a generalized 2.65-2.7 MaxSpeed <br>
Acceleration reduced from 1.5 to 1.15 in most cases (this is also generalized) <br>
T1.5 Aeon Unit receives a rocket range reduction from 34 to 28 <br>
T1.5 UEF Unit receives 1 DamageRadius & range standardized with other T1.5 units as it's speed is standardized now. <br>

### Misc

Athusil Hitbox is fixed so Laser Units don't miss <br>
Mongoose Snap Behavior and Gatling Gun sometimes locking up completely is now fixed <br>
Slink Cloak now fully works and does not require you to reenable it after it fires <br>

# 1.28

### T1 Shard AA Boat

Shard receives a significant 20 -> 12.5 DPS Nerf as well as AoE Reduction from 2 -> 1.25 to stop it from dominating T2 Torpedo Bombers via spam.

### T2 Submarine Hunters

Projectile Count Reduced from 3 -> 1 <br>
Damage reduced by 50% <br>
SalvoDelay increase to 1 Second on all T2 Submarines <br>
Torpedo Defense on Submarine Hunters from 9 -> 23 RoF <br>
Torpedo Defense Range on Submarine Hunters from 3.2 -> 3.3 <br>

### T2 Destroyers

T2 Destroyers receive another Torpedo Defense Buff to combat submarines

### Overhaul

-- Air Overhaul introduces many fixes to physics of Bombers & Rebalancing of Fighters to many T2 Fighters relevant and T1 Fighters far less effective <br>
T1 Air Fighters: <br>
20 HP Reduction <br>
5-10% DPS Reduction <br>
T2 Air Fighters: <br>
50% Increase in Dps <br>
3k E Cost Reduction <br>
30 M Cost Reduction <br>
Health: 1300 - 1500 (Depending on Faction) <br>
Misc: <br>
All Bombers physics reworked to allow them to properly be micro'd and bombs dropped significantly better <br>

# 9/15/24

### T3 Seraphim Submarine

Slight Nerf to Seraphim Submarine to prevent the meta where you would shift g 5-6 seraphim subs on top of each other and their torp defense would infinitely be able to defend a SIGNIFICANT amount of torps.

### T2 Destroyers

All Torpedo Defense on Destroyers significantly buffed should be able to crush T1 Subs at a relative similar cost efficiency

### T2 Torpedo Bombers

Torpedo Bombers nerfed to original 800-860 Health Values with a slight increase in E cost & M cost. <br>
Relative Cost increase was 2k more e and 50 more mass <br>

### Bombers

Fixed Bombers not dropping bombs properly also nerfs dodge micro against bombers as well, i.e means early bombers and such are much stronger and harder to dodge

### T2 Static Flak & T3 Static Flak

-- Buff Flak against Gunships & Remove most of it's usefulness against fast flying strategic bombers and fighters (Making sams more useful) <br>
Comparable Values to the Static except higher rank and generally more damage (although of course more cost) <br>

### T2 Cybran Immortal

-- Cybran should NOT be receiving Stealth or Cloak on 99% of their units as they have powerful mobile stealth & cloaking fields in both T2 & T3
Removed Stealth

### Misc

Fix Target Priorities for certain units. They will target Protector Bots properly again. <br>
Evenflow is now integrated into Economy & Flow. It is now strongly recommended to use this version as it goes hand and hand with LCE. <br>
Additional tweaks into Economy & Flow include Hydrocarbons put into line with T2 Pgen & T3 Pgen cost and production of energy. <br>
Another Additional tweak includes reduction in buildtime on the Enhancements on T3 Factories <br>
Fixed T3 Seraphim SAM Missing ASF & Strategic Bombers <br>
Fixed Czar never catching up to a target when using an attack command <br>

# 9/14/2024

### Aeon T2 Sniper

Reload Speed 6 -> 7 Seconds <br>
Removed Stealth <br>
MaxSpeed 3.8 -> 3.6 <br>

### T2 Mobile Flak

-- Buff Flak against Gunships & Remove most of it's usefulness against fast flying strategic bombers and fighters (Making sams more useful) <br>
All Flak: <br>
Normalize Speed to Allow Micro'ing <br>
DamageRadius: 1.5 -> 3 <br>
TurretYaw: 360 -> 180 <br>
TurretYawSpeed: (A: 45 | C: 30 | U: 60 | S: 40) <br>
Muzzle Velocity: 48 -> 20 <br>
FiringRandomness: 0.5 -> 2.5 <br>
MaxRadius: 36 -> 40 <br>
Significant Buff to TargetPriorities <br>

### T3 Sniper

-- Snipers are all now more nimble to allow micro & also to allow them to be relevant especially in LOUD where there is a lot more Indirect then Vanilla or FAF (Might still need more buffs) <br>
Normalize Speed to Allow Micro'ing <br>
Significant Buff to TargetPriorities <br>
DamageType = 'ShieldMult1.2', (20% Shield Damage) <br>
FiringTolerance: 0.1 -> 2 <br>
Aeon: <br>
ReloadSpeed: 9 -> 6 Seconds <br>
TurretYaw: 360 -> 180 <br>
TurretYawSpeed: 30 -> 90 <br>
Removed Unpacking Animation <br>
Seraphim: <br>
-> SniperMode <br>
FiringTolerance: 0.1 -> 3 <br>
ReloadSpeed: 19 -> 10 Seconds <br>
TurretYaw: 360 -> 180 <br>
TurretYawSpeed: 30 -> 90 <br>

# 9/12/2024

### UEF T4 Goliath

Significant Buff to TargetPriorities <br>
Forced the Goliath to turn with it's weapons when not being moved commanded <br>
Reclassed to Breacher Class <br>
Added Effects to it's Missile Barrage <br>
Health 104000 -> 124000 <br>
Missile Barrage: <br>
Firing Randomness 3 -> 5 <br>
Damage 600 -> 1000 <br>
DamageRadius 3 -> 4 <br>
ProjectileLifetimeUsesMultiplier = 1 <br>
Missiles now ZigZag and create a random scatter barrage meaning the missiles no longer all hit the targetground perfectly. (This makes it extremely hard for TMD to intercept them) <br>
Missile Health 1 -> 2 <br>
MaxSpeed 20 -> 10 <br>
Flamerthrower Arms: <br>
DPS: 480 DPS -> 880 DPS <br>
Death Nuke: <br>
Damage 14,700 -> 32,890 <br>
InnerRadius 12 -> 18 <br>
OuterRadius 24 -> 38 <br>

# 9/10/2024

Fixed Barrage Artillery not being correctly modified <br>
Added Submod called "Economy & Flow" will be added to modlist when you add the full LCE to your usermods folder. <br>
Economy & Flow affects factories cost, mass extractor income & cost and will eventually include a custom version of Evenflow. <br>
Removed AirSpawnWaves from all AIs in LOUD <br>

# 9/8/2024 (V1.22)

### Reclaim

Reclaim that contains 90% of it's mass or higher is reduced to 75% however if the reclaim is lower then 75% on a unit's wreckage it is brought back up to 75% <br>

### T1 & T2 Land

-- T1 & T2 were overperforming especially T1 Land against both T2 & T3, similarly T2 was overperforming vs T3. The intended purpose of this change is to extend the gap between tiers. <br>
Removed 12% Speed & Health Buff given to T1 Land in Blueprints.lua <br>
Removed 6% Speed & Health Buff given to T2 Land in Blueprints.lua <br>

### T3 Barrage Artillery

-- Barrage Artillery is buffed to make it more cost efficient vs building additional T2 Artillery <br>
Aeon: <br>
Damage 265 -> 530 <br>
DamageRadius 2 -> 3 <br>
UEF: <br>
Damage 1500 -> 3000 <br>
DamageRadius 2 -> 3 <br>
Cybran: <br>
Damage 1200 -> 2400 <br>
DamageRadius 2.8 -> 3.8 <br>
StunRadius 2 -> 3 <br>
Seraphim: <br>
Damage 1300 -> 2600 <br>
Damage Radius 2.4 -> 3.4 <br>
DamageType Normal -> ShieldMult1.5 (50% More Damage to Shields) <br>
Muzzle Velocity 33 -> 66 <br>
(Redid TargetPriorities for All T3 Barrage) <br>

### T4 Eliash Medium Rapid Assault Bot

-- The Eliash receives a small buff to it's personal shield <br>
Shield 21000 -> 26000 <br>
ShieldRegenStartTime 1 -> 0.5 <br>

# 9/3/2024 (V1.02/V1.021 Release)

### T3 Triseptitron

Rocket Damage 125 -> 215 <br>
Range 80 -> 90 <br>
DamageRadius 2 -> 2.5 <br>
FiringRandomness 1.4 -> 4 <br>
Fixed issue where it was overshooting it's target always <br>

### T4 Galactic Colossus (GC) / T4 Universal Colossus (UC)

Fixed GC/UC Tractor Claws (This makes them SIGNIFICANTLY more powerful) <br>
GC/UC Tractor Claws now crush units over time that have a health over 5000 <br>
UC Tractor Claws deal 9999 every 11 Ticks <br>
GC Tractor Claws deal 4999 every 11 Ticks <br>

### T4 Eliash Medium Rapid Assault Bot

Mass Cost 26000 -> 21000 <br>
Energy Cost 420000 -> 480000 <br>
Health 66500 -> 18500 <br>
Shield = 21000 <br>
ShieldRegenRate = 240 <br>
ShieldRechargeTime = 12 <br>
Main Weapon 10000 -> 5000 DPS <br>
EnergyDrainPerSecond = 650, <br>
EnergyRequired = 3250, <br>
AA Weapon 300 -> 400 Damage <br>
Buffed Auto TargetPriorities <br>

### T2 Aeon Sniper

TargetPriorities Readjusted to increase Micro Focus <br>
Remove Shield Ignoring from Projectile <br>
MaintenanceConsumptionPerSecondEnergy 20 -> 50 <br>

# 9/2/2024 (V1.0.1 Release)

Hotfix for T2 Aeon Sniper not firing

# 9/2/2024 (V1.0.0 Release)

### Reclaim Changes

-- Reclaim Changes were simple. The Single Goal in Mind was to encourage early aggression but punish late game mistakes i.e losing entire army without delivering significant damage. <br>
All Wrecks have been fixed to prevent permanent disappear of Wreckage/Reclaim <br>
Overkill Ratio on Wreckage disappearing has been changed from 10% to 30% meaning you have to overkill said unit by 30% to not receive the wreckage <br>
Naval Reclaim no lower gives 30% of the energy in the Wreckage <br>

### T3 Penetration Bombers

-- Pen Bombers are very strong, with the ability to easily punch through most AA & having cheap stealth. This change was needed to prevent early Pen Bomber Rushes specifically in Teamgames. Many changes are aimed at some of the first steps towards significantly <br> diversifying units
Aeon: <br>
Mass Cost 4300 -> 5300 <br>
Energy Cost 165000 -> 195000 <br>
Stealth Energy Cost Upkeep 50 -> 250 <br>
MaxAirspeed 19 -> 17 <br>
MinAirspeed 15 -> 14 <br>
TurnSpeed 1.0 -> 1.1 <br>
UEF: <br>
Mass Cost 4750 -> 5750
Energy Cost 180000 -> 2100000 <br>
Stealth Energy Cost Upkeep 50 -> 300 <br>
Health 6800 -> 7200 <br>
MaxAirspeed 19 -> 18 <br>
TurnSpeed 1.0 -> 0.8 <br>
Small Yield Nuclear Bomb Damage 1900k -> 1200 <br>
Lancer Standoff ASM Barrage Damage 600 -> 1150 <br>
Lancer Standoff ASM Barrage DamageRadius 2 -> 3.5 <br>
Cybran: <br>
Mass Cost 4750 -> 5500 <br>
Energy Cost 180000 -> 190000 <br>
Stealth Energy Cost Upkeep 50 -> 300 <br>
Health 4750 -> 4250 <br>
RegenRate 10 -> 25 <br>
MaxAirspeed 19 -> 20 <br>
MinAirspeed 15 -> 16 <br>
TurnSpeed 1.0 -> 1.1 <br>
Seraphim: <br>
Mass Cost 4750 -> 5750 <br>
Energy Cost 180000 -> 195000 <br>
Stealth Energy Cost Upkeep 50 -> 250 <br>
Health 6250 -> 5250 <br>
MaxAirspeed 19 -> 18 <br>
MinAirspeed 15 -> 14 <br>
Bombs 3200 -> 4200 <br>

### T3 Static Artillery

Revert to the FAF Cost of T3 Static Artillery

### T2 Aeon Sniper

-- The Aeon Sniper was dominating T2, T3, and even early T4 Phase in some games, this called for a immediate nerf. It's main strength lies in its speed and with the reduction, it should allow players to catch them much easier. The cost will also make them less efficient and the EnergyRequired will make the Reload much longer as well by 3 more seconds. <br>
Mass Cost 320 -> 465 <br>
Energy Cost 3850 -> 5050 <br>
MaxSpeed 4.0 -> 3.8 <br>
EnergyRequired (Recharge - Main Weapon) 880 -> 1320 <br>

# T3 Mobile Sensor Arrays

-- Mobile Sensor Arrays Omni was too small combined with the small omni on static radar led to Stealth & Cloak being far too powerful & annoying for players. <br>
Energy Cost Upkeep 850 -> 1500 <br>
OmniRadius 56 -> 112 <br>
