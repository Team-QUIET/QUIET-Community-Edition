# QUIET

Welcome to **QUIET**! This project is a community-driven effort to enhance the gameplay experience of [LOUD Project Mod](https://github.com/LOUD-Project/Git-LOUD) by implementing balance changes, bug fixes, and introducing new features. We aim to create a dynamic, fun, and fair gaming environment for all players.

![QUIET](quietLauncherSplash_1.jpg?raw=true)

# Installation

## QUIET Updater Installation
There is a QUIET updater at [the project releases page](https://github.com/Team-QUIET/quiet-updater/releases/latest).

This will be the preferred way to stay up to date with the QUIET mod, and related mods like M28AI
going forward.  If you are new, installation is relatively simple:

1. Download the latest binary release from above,  QUIET_Updater.exe
2. Find your Supreme Commander: Forged Alliance installation.  For the Steam version, this is typically:
   * ```C:\Program Files (x86)\Steam\steamapps\common\Supreme Commander Forged Alliance\```
   * We will refer to this as the "root" SCFA path (the directory where the SCFA game is installed).
3. Copy the SCFA_Updater.exe to the path above.
  * You should now have QUIET_Updater.exe in same folder as the root SCFA path; so the intended path would be:
    * ```C:\Program Files (x86)\Steam\steamapps\common\Supreme Commander Forged Alliance\QUIET_Updater.exe```
  * You will see other folders like \bin, \gamedata, \maps, \movies, etc. adjacent to where you copied the binary.
4.  Once copied, you can execute the binary by 2x clicking it as with any application.
    * You may recieve a warning on whether to trust this binary from your operating system, or a requirement to run as administrator.
5.  On the first run, the updater will extract its necessary local data, and then open a user interface for managing updating, downloading
    maps, and other helpful features.
    * We highly recommend you opt to have the updater create shortcuts for future refrence: Tools -> Create Shortcuts
    * Future runs should be conveniently accessible from the desktop shortcut.

### Existing QUIET Users (legacy updater)
Installation is identical to the above, except you will have an old version of the updater called SCFA_Updater.exe.
This is no longer necessary going forward; QUIET_Updater.exe is the official version.

## QUIET
The QUIET Updater (installed above), will handle installing QUIET and related  mods.
First time installation and later updating are both accomplished via the ```Update``` button in the user interface.
Once QUIET is installed, all 3rd party mods are installed in the ```usermods``` folder local to QUIET.

Installing will make the following changes:
* QUIET will be installed along your existing SCFA installation, under the root SCFA path, in a ```QUIET``` folder.
* QUIET and related mods will be installed in the default ```usermods``` subdirectory relative to QUIET, e.g.
  *  ```C:\Program Files (x86)\Steam\steamapps\common\Supreme Commander Forged Alliance\QUIET\usermods\QUIET-Community-Edition```
*  The M28AI will be installed into ```usermods\M28AI``` as well.
*  No changes to the base game data will occur; you can still play vanilla SCFA at any time.

Updating a current installation will make the following changes:
* Files in the ```QUIET``` folder will be synchronized (overwritten) if they are out of date with the current release.
* Folders in ```QUIET\usermods``` will be synchronized (overwritten) if their respective mods are out of date:
  * QUIET-Community-Edition
  * M28AI

## usermods
You can conveniently get to this folder through the updater using the top menu:
Tools -> Open Mods Folder

# Usage
After installing the updater, and updating for the first time, all the relevant files for QUIET, QUIET, and M28AI
should be available for use.  At this point, you can launch a game using the updater GUI via ```Run Game```, or click on
the ```QUIET Forged Alliance``` shortcut if you opted to create one earlier.

* On the first launch, you will need to create a new SCFA user profile to use the mods, otherwise errors may occur.

Simply enable the mods you would like from your SCFA installation.
- Globally for the game profile, via Extras -> Mod Manager
- Locally (to a specific game lobby), via Game Options -> Mod Manager

The minimal expected setup would be enabling the "QUIET Standard"" mods button from the Mod Manager.

When creating a game lobby, the QUIET mod changes will be present without any current
user configuration in the lobby.  If you want to use the M28 AI in your game, make
sure to select the M28AI when you add a computer player, from the AI drop down menu.

# Main Changes

View the full list of [changes](https://github.com/Team-QUIET/QUIET-Community-Edition/blob/main/changelog**.

Aside from the plethora of unit changes, rebalancing, economy changes, and the like, the biggest addition is
the inclusion of the M28 AI mod for additional PVE play.  M28 is developed independently, but it works very well with QUIET.
We keep track with the frequent upstream releases.

# Known Issues

## Old Cached Shaders
If you have played a variant of Supreme Commander (other than Forged Alliance: Forever), then you may have
legacy shaders cached on your computer.  This could result in a seemingly random runtime crash, particularly
when someone tries to build any naval units for the first time in game.

QUIET leverages the excellent shader re-work done by FAF community.  To this end, you may need to clear out
your shader cache one time, after which Supreme Commander will re-compile and cache the shaders the next time
it runs (this is trivial to do and is not noticable to the user).

Future versions of the QUIET updater will eliminate this problem by simply cleaning the shader files on update.
Until then, you will need to follow one of the following options:

### Use a script
You can use the convenient [shader_cleaner batch file](https://github.com/FAForever/nomads/blob/develop/shader_cleaner.bat)
from the FAF nomads mod.  This batch file directly accomplishes the manual option that follows.

### Or, Manually Delete the Old Cached Shader Files
Files that need to be deleted are possibly in 2 places:

```
%LOCALAPPDATA%\Gas Powered Games\Supreme Commander Forged Alliance\cache\
%HOMEPATH%\Local Settings\Application Data\Gas Powered Games\Supreme Commander Forged Alliance\cache\
```

which should resolve to:

```
C:\Users\yournamehere\AppData\Local\Gas Powered Games\Supreme Commander Forged Alliance\cache
C:\Users\yournamehere\Local Settings\Application Data\Gas Powered Games\Supreme Commander Forged Alliance\cache
```

The files that need to be deleted are
- mesh.1.5.*
- mesh.1.6.*

(any file beginning with 'mesh' pretty much) ; if they exist.

This is what the batch file linked above does (for convenience). They are
compiled shader files that are built 1x and cached by SCFA. If you delete them,
they are recompiled and cached in the same place.


---

## Contributing to QUIET Project

We welcome all forms of contributions to enhance the QUIET experience! Here’s how you can get involved:

### How to Contribute

Feel free to submit a [new issue](https://github.com/Team-QUIET/QUIET-Community-Edition/issues).
