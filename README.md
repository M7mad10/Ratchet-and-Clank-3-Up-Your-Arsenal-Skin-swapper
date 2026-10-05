# Ratchet-and-Clank-3-Up-Your-Arsenal-Skin-swapper
This is a simple script that modifies the North American PS2 copy of UYA to have skins from the Japanese version and going commando.

It takes assets from other game versions and replaces already existing skin assets in the game.
All you need are these ps2 games:
- R&C 3 North America SCUS-97353 (Required) 
- R&C 3 Japan SCPS-15084 (Optional)
- R&C Going commando SCUS-97268 (Optional)

Skin Swapper - Ratchet & Clank: Up Your Arsenal (PS2)
=====================================================

Adds skins from the Japanese Up Your Arsenal and from Going Commando to the North
American Up Your Arsenal, and lets you replace any armor or skin with another one.
It writes a NEW iso; your original iso files are never changed.


WHAT YOU NEED
  - Windows (the tool uses PowerShell, which is part of Windows; nothing to install)
  - Your own disc images as plain .iso files:
       NA UYA   Ratchet & Clank: Up Your Arsenal (North America)        SCUS-97353   required
       JP UYA   Ratchet & Clank 3: Totsugeki! Galactic Rangers (Japan)  SCPS-15084   optional
       NA GC    Ratchet & Clank: Going Commando (North America)         SCUS-97268   optional
    Only these exact versions are accepted. The NA UYA iso must be unmodified.


FILES
  Skin Swapper.bat   Double-click this to start.
  SkinSwapper.ps1    The tool itself (the .bat runs it).
  README.txt         This file.
  Keep the .bat and the .ps1 in the same folder. Nothing outside this folder is used.


HOW TO USE
  1. Double-click "Skin Swapper.bat".
     A black LOG window opens, then the Skin Swapper window.
  2. Pick your iso files with the Browse buttons (or type/paste the path).
     A green check means the disc is correct. A red cross means it is not; the log
     window says why (wrong game, unsupported version, modified copy, file not found...).
     Everything is greyed out until NA UYA has a green check.
  3. Choose what you want (see below).
  4. Press "Patch Rom". Progress is shown in the log window (copying takes 1-3 minutes).
  5. When it is done, a green "successful:" line shows where the new iso is.
     Click it to open that folder. If something is wrong, a red "failed:" line explains
     why (and which custom over-write row caused it), and no iso is left behind.
  The new iso is saved next to the NA UYA iso as  "... [modded].iso"
  (or "... [modded] (2).iso" and so on if that name already exists).
  When you close the window, the log stays open until you press a key.


OPTIONS
  Add Extra skins
    Adds new skins to the game's SKINS menu without replacing any existing skin.
    Only available if JP UYA and/or NA GC has a green check.
       from JP UYA:  Sumo, Ninja, Santa, Pipo-Saru
       from NA GC:   Tux Ratchet, Clown, Beach Boy, Snow Dude
    Only the skins from the discs you selected are added and shown in the menu.
    They are unlocked from the start.

  Unlock Constructobot
    Shows the Constructobot skin in the SKINS menu straight away. Normally the game
    unlocks it once you have collected the trophies for the Starship Phoenix trophy room.
    Off by default.

  custom over-write
    Replaces an armor or skin of the NA game with another one.
    Press "+" to add a row, then choose:
       left box:   the skin you want (from every disc that has a green check, including
                   the unused "Old Adamantine Armor" that the NA disc contains)
       right box:  the NA armor or skin it replaces (the 5 armors and the 9 menu skins)
    Each NA armor/skin can only be replaced once; a slot used in one row disappears from
    the other rows. "Remove" deletes only that row.
    Choosing a skin over itself is allowed but does nothing (a yellow note says so).
    In the game, pick the replaced armor or skin to get the new one.

  Free disc space
    New skins that are bigger than the one they replace, and the extra skins, are stored
    in free space on the disc. If too many big skins are chosen (mainly the Going Commando
    armors), Patch Rom stops and names the row that does not fit. Remove or change a row,
    or untick "Add Extra skins".


GOOD TO KNOW
  - The Japanese versions of the Alpha Combat Suit, Magnaplate, Adamantine and Aegis
    Mark V armors have a slightly different face (thicker eyebrows, different eyes).
  - The Going Commando "Commando Suit" and "Tetrafiber Armor" give you bare feet with shoes textures in-game. The "Duraplate Armor" give actual bare feet with feet textures in-game
  - If you save the game while wearing a new skin and later load that save on an
    unpatched copy, a placeholder skin may show until you pick another skin.
  - Tested in the PCSX2 emulator.


CHANGING THINGS (optional, open SkinSwapper.ps1 in Notepad)
  - Names/descriptions of the extra skins in the SKINS menu: $EXTRA_TEXT near the top
    (names up to 25 characters, descriptions up to 110, no % sign).
  - Accepted disc versions: $ACCEPTED near the top. A new version should only be added
    after it has been checked, because skin positions and game code can differ.


Inside the North American copy of UYA slots 14-28 (18-28 in japanese version) are Place holders, but they are not empty. They all contain an older version of Adamantine Armor.



To be completely transparent here, I have used Claude's Opus 5.5 in creating this to the extent that would be considered vibecoded.
I gave it two RAM dumps from PCSX2 emulator, one with default skin and the other ram dump with the skin I want it trace back to original data on the disc.
It was able to compare both ram dumps and Trace it to which sector the data is held on disc. I did this process with all games.
Then it created the original script and asked to also make the .bat file to simplify the process. Later I decided to add more feature and the Command line interface became inefficient, I then designed a GUI with help of the AI assistant to make the process a lot easier.

Full conversation:
https://claude.ai/share/775e435e-30c9-40b9-a77c-2aebcf69ab10
