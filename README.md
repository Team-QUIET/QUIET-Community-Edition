# LOUD Community Edition (LCE)

Welcome to the **LOUD Community Edition**! This project is a community-driven effort to enhance the gameplay experience of [LOUD Project Mod](https://github.com/LOUD-Project/Git-LOUD) by implementing balance changes, bug fixes, and introducing new features. We aim to create a dynamic, fun, and fair gaming environment for all players.

# Installation

## LOUD Community Edition Updater Installation
There is a LOUD Community Edition updater that is identical in form to the original LOUD updater, to be found at 
[the latest release download link](https://github.com/LOUD-Community-Edition/loud-electron/releases/latest).

This will be the preferred way to stay up to date with LOUD, the LOUD Community Edition, and related mods like M28AI
going forward.  If you are new to LOUD in general, installation is relatively simple: 

1. Download the latest binary release,  SCFA_Updater.exe
2. Find your Supreme Commander: Forged Alliance installation.  For the Steam version, this is typically:
   * ```C:\Program Files (x86)\Steam\steamapps\common\Supreme Commander Forged Alliance\```
   * We will refer to this as the "root" SCFA path (the directory where the SCFA game is installed).
3. Copy the SCFA_Updater.exe to the path above.
  * You should now have SCFA_Updater.exe in same folder as the root SCFA path; so the intended path would be: 
    * ```C:\Program Files (x86)\Steam\steamapps\common\Supreme Commander Forged Alliance\SCFA_Updater.exe```
  * You will see other folders like \bin, \gamedata, \maps, \movies, etc. adjacent to where you copied the binary.
4.  Once copied, you can execute the binary by 2x clicking it as with any application.
    * You may recieve a warning on whether to trust this binary from your operating system, or a requirement to run as administrator.
5.  On the first run, the updater will extract its necessary local data, and then open a user interface for managing updating, downloading
    maps, and other helpful features.
    * We highly recommend you opt to have the updater create shortcuts for future refrence: Tools -> Create Shortcuts
    * Future runs should be conveniently accessible from the desktop shortcut.
### Existing LOUD Users
Installation is identical to the above, except you will already have a version of the SCFA_Updater.exe.  
You will need to either delete or rename this binary, and the copy the SCFA_Updater.exe from the LOUD-Community-Edition into its place.  All shortcuts should continue to work as before.

## LOUD 
Since LOUD Community Edition (LCE) exists as a set of changes on top of the broader LOUD project, you will need to have LOUD installed.
The LCE Updater (installed above), will handle installing and updating LOUD mod files, as well as installing LCE and related user mods.
First time installation and later updating are both accomplished via the ```Update``` button in the user interface.
Once LOUD is installed, all 3rd party mods are installed in the ```usermods``` folder local to LOUD.

Installing will make the following changes:
* LOUD will be installed along your existing SCFA installation, under the root SCFA path, in a ```LOUD``` folder.
* LOUD Community Edition and related mods will be installed in the default ```usermods``` subdirectory relative to LOUD, e.g.
  *  ```C:\Program Files (x86)\Steam\steamapps\common\Supreme Commander Forged Alliance\LOUD\usermods\LOUD-Community-Edition```
*  The M28AI will be installed into ```usermods\M28AI``` as well.
*  No changes to the base game data will occur; you can still play vanilla SCFA at any time.

Updating a current installation will make the following changes:
* Files in the ```LOUD``` folder will be synchronized (overwritten) if they are out of date with the current release.
* Folders in ```LOUD\usermods``` will be synchronized (overwritten) if their respective mods are out of date:
  * LOUD-Community-Edition
  * M28AI

## usermods
You can conveniently get to this folder through the LOUD updater using the top menu: 
Tools -> Open Mods Folder

## Manual Installation
* LOUD can be manually installed from the [onedrive linke](https://1drv.ms/u/s!AubmcwAIEAlzn2TwHzibrMTRySVj?e=MCevjP).  You will place the files in the ```LOUD`` subfolder as the updater would.

* LCE versions can be acquired from the [releases](https://github.com/Azraeel/LOUD-Community-Edition/releases/) link, 
or more simply, directly download the [current release](https://github.com/Azraeel/LOUD-Community-Edition/releases/latest/download/LOUD-Community-Edition.zip) 
as needed.
If you download the [current release](https://github.com/Azraeel/LOUD-Community-Edition/releases/latest/download/LOUD-Community-Edition.zip), simply extract
the zip archive into the ```usermods``` folder shown earlier.  NOTE: it is advisable (for manual installation), to delete any prior version of the LOUD-Community-Edition folder in the usermods folder, since newer releases may move or delete files in the mod, and simply extracting could keep older files around).

* M28AI You can download M28 in a similar fashion to LCE from [here]([https://github.com/maudlin27/M28AI/](https://github.com/LOUD-Community-Edition/LOUD-Community-Edition/releases/latest).  Once downloaded, extract the zip file into ```usermods```.
* 
# Usage
After installing the updater, and updating for the first time, all the relevant files for LOUD, LCE, and M28AI
should be available for use.  At this point, you can launch a game using the updater GUI via ```Run Game```, or click on
the ```LOUD Forged Alliance``` shortcut if you opted to create one earlier.

* On the first launch, you will need to create a new SCFA user profile to use the mods, otherwise errors may occur.

Simply enable the mods you would like from your SCFA installation.  
- Globally for the game profile, via Extras -> Mod Manager
- Locally (to a specific game lobby), via Game Options -> Mod Manager

The minimal expected setup would be enabling the Loud Standard mods toggle from the Mod Manager, 
and LOUD Community Edition (found at the bottom of the mod list among user mods).

You can similarly enable M28AI as a usermod.

When creating a game lobby, the LCE mod changes will be present without any current
user configuration in the lobby.  If you want to use the M28 AI in your game, make
sure to select the M28AI when you add a computer player, from the AI drop down menu (default
is LOUD).

# Main Changes

View the full list of [changes](https://github.com/Azraeel/LOUD-Community-Edition/blob/main/Changelog.txt).

---

## Contributing to the LOUD Community Edition

We welcome all forms of contributions to enhance the LOUD experience! Here’s how you can get involved:

### How to Contribute

Feel free to submit a [new issue](https://github.com/Azraeel/LOUD-Community-Edition/issues).
