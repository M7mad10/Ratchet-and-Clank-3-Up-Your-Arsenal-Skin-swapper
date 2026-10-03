# Ratchet-and-Clank-3-Up-Your-Arsenal-Skin-swapper
This is a simple script that modifies the North American PS2 copy of UYA to have skins from the Japanese version and going commando.

It takes assets from other game versions and replaces already existing skin assets in the game.
All you need are these ps2 games:
- R&C 3 North America SCUS-97353 (Required) 
- R&C 3 Japan SCPS-15084 (Optional)
- R&C Going commando SCUS-97268 (Optional)

You can just drag and drop the the iso file onto the .bat file and it will open a simple command-line user interface.
You have multiple options. You can just press 1 then Enter to choose the first option which is going to replace all skins, or you could 
choose 8 a Custom option where can choose which skin replaces which ( SourceSlot>NaSlot, e.g.  JP17>13 GC7>8 ).
The Modified ISO should be in the same directory as the NA copy you have.

To be completely transparent here, I have used Claude's Opus 5.5 in creating this to the extent that would be considered vibecoded.
I gave it two RAM dumps from PCSX2 emulator, one with default skin and the other ram dump with the skin I want it trace back to original data on the disc.
It was able to compare both ram dumps and Trace it to which sector the data is held on disc. I did this process with all games.
Then it created the script and asked to also make the .bat file to simplify the process.
