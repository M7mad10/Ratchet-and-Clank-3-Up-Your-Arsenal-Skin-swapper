# Ratchet-and-Clank-3-Up-Your-Arsenal-Skin-swapper
This is a simple script that modifies the North American PS2 copy of UYA to have skins from the Japanese version, going commando and Multiplayer Mode.

Skin Swapper 2.0 - Ratchet & Clank: Up Your Arsenal (PS2)
=========================================================

Replaces any of the 29 skin slots of the North American Up Your Arsenal with a skin
from the NA disc, the Japanese UYA disc, Going Commando or the UYA multiplayer
characters (in 8 team colours), adds up to 15 new entries to the SKINS menu, and can
change the helmet of any slot.
It writes a NEW iso; your original iso files are never changed.


WHAT YOU NEED
  - Windows (the tool uses PowerShell, which is part of Windows; nothing to install)
  - Your own disc images as plain .iso files:
       NA UYA   Ratchet & Clank: Up Your Arsenal (North America)        SCUS-97353   required
       JP UYA   Ratchet & Clank 3: Totsugeki! Galactic Rangers (Japan)  SCPS-15084   optional
       NA GC    Ratchet & Clank: Going Commando (North America)         SCUS-97268   optional
    Only these exact versions are accepted. The NA UYA iso must be unmodified.
    The multiplayer skins and MP Ratchet are taken from the NA UYA disc itself.


FILES
  Skin Swapper 2.bat   Double-click this to start.
  SkinSwapper2.ps1     The tool itself (the .bat runs it).
  README.txt           This file.
  Keep the .bat and the .ps1 in the same folder. Nothing outside this folder is used;
  the folder can be moved or copied anywhere.


HOW TO USE
  1. Double-click "Skin Swapper 2.bat".
     A black LOG window opens, then the Skin Swapper 2.0 window.
  2. Pick your iso files with the Browse buttons (or type/paste the path).
     A green check means the disc is correct. A red cross means it is not; the log
     window says why (wrong game, unsupported version, modified copy, file not found...).
     Everything is greyed out until NA UYA has a green check.
  3. Choose your options and skins (see below).
  4. Press "Patch Rom". Progress is shown in the log window (copying takes 1-3 minutes).
  5. When it is done, a green "successful:" line shows where the new iso is.
     Click it to open that folder. If something is wrong, a red "failed:" line explains
     why, and no iso is left behind.
  The new iso is saved next to the NA UYA iso as  "... [modded].iso"
  (or "... [modded] (2).iso" and so on if that name already exists).
  When you close the window, the log stays open until you press a key.


OPTIONS
  Unlock all Unlockable skins
    Off: the game's own rules. Skins in the SKINS menu are bought with titanium bolts,
         Old School Ratchet stays hidden until you earn it, and Constructobot needs the
         trophies for the Starship Phoenix trophy room.
    On:  every skin in the SKINS menu is owned from the start, including
         "Old School Ratchet" and "Constructobot".
    New menu entries (slots 14-28) are always unlocked, with or without this option.

  Skin slots Custom-Overwrites
    One row per skin slot of the game (0-28). In each row, choose the skin that should
    over-write that slot in the box to the right of the arrow:
       - "(keep original)" leaves the slot as it is.
       - The list only shows skins from the discs that have a green check, in the
         order NA, JP, GC, MP. The tag after each name says where it comes from.
       - If you remove a disc later, rows that used its skins go back to
         "(keep original)".

    The slots:
       0-4    the armors: Alpha Combat Suit, Magnaplate, Adamantine, Aegis Mark V,
              Infernox. Wear that armor in the game to get the new skin.
       5-13   the SKINS menu: Old School Ratchet, Snowman, Tuxedo Ratchet, Buginoid,
              Brainius, Constructobot, Robo Rooster, Trooper, Robo. The menu shows the
              new skin's name and description; price and unlock rule stay those of the
              slot.
       14-28  unused slots (each holds a copy of the unused "Old Adamantine Armor").
              A slot from 14-28 is added to the SKINS menu only if it is over-written.

    Colour (MP skins only)
       The second box picks the team colour of a multiplayer (MP) skin:
       Blue (default), Red, Green, Orange, Yellow, Purple, Aqua, Pink.
       It is greyed out for other skins.

    Helmet Override
       Tick it to choose the helmet for that slot: No helmet, Orange (Alpha),
       Blue (Magnaplate), Red (Adamantine) or Green (Aegis).
       Works on any slot, also when the skin itself is kept.

    "Over-writing a skin with itself gives no results."
       This yellow note appears when a slot is given its own skin (or, for slots 14-28,
       the Old Adamantine Armor). It is only a note; you can still patch.

  Disc space
    All 29 slots share 2,887 sectors of the disc. The bar shows how much your choices
    use. If it turns red, the choices don't fit (mainly the big Going Commando armors);
    Patch Rom is disabled until you choose smaller skins or keep some originals.


SKINS YOU CAN CHOOSE
  NA UYA:  the 5 armors, the 9 menu skins, Old Adamantine Armor (unused)
  JP UYA:  the 5 armors (JP versions), Sumo, Ninja, Santa, Pipo-Saru
  NA GC:   Commando Suit, Tetrafiber, Duraplate, Electrosteel, Carbonox,
           Tux Ratchet, Clown, Beach Boy, Snow Dude
  MP:      Ratchet, Robo, Thug, Tyhrranoid, Blarg, Ninja, Snow Man, Bruiser, Gray,
           Hotbot, Gladiola, Evil Clown, Beach Bunny, Robo Rooster, Buginoid,
           Brainius, Skrunch, Bones, Nefarious, Trooper, Constructobot, Dan Johnson


KNOWN ISSUES
  - The Going Commando "Commando Suit" and "Tetrafiber Armor" give bare feet with shoe
    textures in UYA, and the "Duraplate Armor" gives bare feet with feet textures.
  - A save made while wearing a new skin expects the modded disc. If you load that save
    on an unpatched copy (or a copy patched differently), a placeholder skin may show
    until you pick another skin.


GOOD TO KNOW
  - The Japanese versions of the Alpha Combat Suit, Magnaplate, Adamantine and Aegis
    Mark V armors have a slightly different face (thicker eyebrows, different eyes).
  - Tested in the PCSX2 emulator.

    
CHANGING THINGS (optional, open SkinSwapper.ps1 in Notepad)
  - Names/descriptions of the extra skins in the SKINS menu: $EXTRA_TEXT near the top
    (names up to 25 characters, descriptions up to 110, no % sign).
  - Accepted disc versions: $ACCEPTED near the top. A new version should only be added
    after it has been checked, because skin positions and game code can differ.




To be completely transparent here, I have used Claude's Opus 5.5 in creating this to the extent that would be considered vibecoded.
I gave it two RAM dumps from PCSX2 emulator, one with default skin and the other ram dump with the skin I want it trace back to original data on the disc.
It was able to compare both ram dumps and Trace it to which sector the data is held on disc. I did this process with all games.
Then it created the original script and asked to also make the .bat file to simplify the process. Later I decided to add more feature and the Command line interface became inefficient, I then designed a GUI with help of the AI assistant to make the process a lot easier.

Full conversation:
https://claude.ai/share/775e435e-30c9-40b9-a77c-2aebcf69ab10

https://claude.ai/share/7ed5e069-a12f-4ae8-801c-9ad87c56a154
