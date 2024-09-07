# LOUD Community Edition (LCE)

Welcome to the **LOUD Community Edition**! This project is a community-driven effort to enhance the gameplay experience of [LOUD Project Mod](https://github.com/LOUD-Project/Git-LOUD) by implementing balance changes, bug fixes, and introducing new features. We aim to create a dynamic, fun, and fair gaming environment for all players.

# Installation
## LOUD
Since LOUD Community Edition (LCE) exists as a set of changes on top of the broader LOUD project, you will need to have LOUD installed.
We have plans to simplify managing both LOUD and LCE, but for now, you will need the LOUD updater and/or a valid installation of
LOUD.

[LOUD Project On MODDB](https://www.moddb.com/mods/loud-ai-supreme-commander-forged-alliance)
## usermods
Once LOUD is installed, all 3rd party mods are installed in the _usermods_ folder local to LOUD.
For example, on a stock Windows system with a default steam installation: 
- C:\Program Files (x86)\Steam\steamapps\common\Supreme Commander Forged Alliance\LOUD\usermods

You can conveniently get to this folder through the LOUD updater using the top menu: 
Tools -> Open Mods Folder

Once you can navigate to the usermods folder, you can populate it with this mod and others.
## LCE Current Release
For now, we manually install and update our mod as a usermod (there are plans to simpilify setup and updating).  
We use a tagged release model for simple distribution on github.  

This means you can navigate to a specific (even prior) version of the mod, from the [releases](https://github.com/Azraeel/LOUD-Community-Edition/releases/) link, 
or more simply, directly download the [current release](https://github.com/Azraeel/LOUD-Community-Edition/releases/latest/download/LOUD-Community-Edition.zip) 
as needed.

If you download the [current release](https://github.com/Azraeel/LOUD-Community-Edition/releases/latest/download/LOUD-Community-Edition.zip), simply extract
the zip archive into the _usermods_ folder shown earlier.  NOTE: it is advisable (for manual installation), to delete any prior version of the LOUD-Community-Edition folder
in the usermods folder, since newer releases may move or delete files in the mod, and simply extracting could keep older files around).

## M28 AI
The recently ported M28 AI expands the LOUD mod's PVE AI options.  You can download M28 in a similar fashion to LCE (although the code repository does not use a
tagged release model).  The entire mod folder for the current version can be downloaded as a zip file [from here](https://github.com/maudlin27/M28AI/archive/refs/heads/main.zip) or by using the github interface in the [repository](https://github.com/maudlin27/M28AI/), Code -> Download Zip.

Once downloaded, extract the zip file into _usermods_.

# Usage
Simply enable the mods you would like from your SCFA installation.  
- Globally for the game profile, via Extras -> Mod Manager
- Locally (to a specific game lobby), via Game Options -> Mod Manager

The minimal expected setup would be enabling the Loud Standard mods toggle from the Mod Manager, 
and LOUD Community Edition (found at the bottom of the mod list among user mods).

You can similarly enable M28 as a usermod.

When creating a game lobby, the LCE mod changes will be present without any current
user configuration in the lobby.  If you want to use the M28 AI in your game, make
sure to select the M28AI when you add a computer player, from the AI drop down menu (default
is LOUD).

# Main Changes

View the full list of [changes](https://github.com/Azraeel/LOUD-Community-Edition/blob/main/Changelog.txt).

## What's New in V1.0.0?

### Reclaim Changes
- **Goal**: Encourage early-game aggression while punishing late-game mistakes.
- **Key Changes**:
  - All wrecks now remain, preventing permanent disappearance of wreckage/reclaim.
  - Overkill ratio for wreckage disappearance adjusted from 10% to 30%.
  - Naval reclaim no longer gives 30% of the energy from wreckage.

### T3 Penetration Bombers Adjustments
- **Objective**: Prevent early Pen Bomber rushes and diversify unit utility.
- **Changes by Faction**:
  - **Aeon**: Increased costs, reduced max airspeed, increased stealth upkeep.
  - **UEF**: Adjusted mass/energy costs, changed max airspeed, balanced damage output.
  - **Cybran**: Health and mass cost adjustments, increased regen rate.
  - **Seraphim**: Increased bomb damage, adjusted health, speed, and costs.

### T3 Static Artillery Reversion
- Reverted to FAF costs to balance late-game artillery impact.

### T2 Aeon Sniper Nerf
- **Reason**: The unit was too dominant across multiple phases.
- **Adjustments**: Increased costs, reduced speed, longer reload time.

### T3 Mobile Sensor Arrays Enhancement
- **Focus**: Improve detection range to balance stealth and cloak effectiveness.
- **Changes**: Increased upkeep and Omni radius.

---

## Contributing to the LOUD Community Edition

We welcome all forms of contributions to enhance the LOUD experience! Here’s how you can get involved:

### How to Contribute

Feel free to submit a [new issue](https://github.com/Azraeel/LOUD-Community-Edition/issues).
