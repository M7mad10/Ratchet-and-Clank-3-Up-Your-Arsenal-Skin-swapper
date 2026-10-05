<#
  SkinSwapper.ps1  -  Ratchet & Clank: Up Your Arsenal (PS2) skin swapper with a window   (v1)
  Start it with "Skin Swapper.bat" (this console window is the log).
  Everything it needs is inside this folder. Your iso files are never changed; a NEW
  "... [modded].iso" is written next to the NA Up Your Arsenal iso.
#>
param([string]$Headless)   # developer test: path to a .json settings file, patches without the window
$ErrorActionPreference = 'Stop'

# ======================= settings you may edit =======================
# Disc versions accepted by the checks (serials). Only these have been tested.
$ACCEPTED = [ordered]@{
    NA = @('SCUS-97353')    # Ratchet & Clank: Up Your Arsenal (North America)
    JP = @('SCPS-15084')    # Ratchet & Clank 3: Totsugeki! Galactic Rangers (Japan)
    GC = @('SCUS-97268')    # Ratchet & Clank: Going Commando (North America)
}
# Names shown in the game's SKINS menu for the extra skins (max 25 characters each,
# descriptions max 110; plain letters/numbers/punctuation, no % sign).
$EXTRA_TEXT = @{
    14 = @('SUMO',        'Play as Ratchet the sumo wrestler.')
    15 = @('NINJA',       'Play as Ratchet in a ninja outfit.')
    16 = @('SANTA',       'Play as Santa Ratchet.')
    17 = @('PIPO-SARU',   'Play as Pipo-Saru from Ape Escape.')
    18 = @('TUX RATCHET', 'A tuxedo from R&C: Going Commando.')
    19 = @('CLOWN',       'Play as Ratchet wearing a goofy clown costume.')
    20 = @('BEACH BOY',   'Hit the beach with Ratchet in swim trunks and booties.')
    21 = @('SNOW DUDE',   'The snowman from R&C: Going Commando.')
}

# ======================= fixed data =======================
$SECTOR = 2048; $TOC_LBA = 1001; $TOC_SIZE = 0x200000
$HDR_UYA = 0x398; $HDR_GC = 0xF8
$ROLE_NAME = @{ NA = 'NA UYA'; JP = 'JP UYA'; GC = 'NA GC' }
$KNOWN_SERIAL = @{ 'SCUS-97353' = 'NA Up Your Arsenal'; 'SCPS-15084' = 'JP Up Your Arsenal'; 'SCUS-97268' = 'NA Going Commando' }
# SHA-256 of the skin table of each tested disc (detects modified copies)
$HEADER_SHA = @{
    NA = '7b530da509211f8755a388c19e1f0e3cb680d5dc3b01aca1f65261991b9d541a'
    JP = 'be9a4c64eaa2de2a2bce65230f363802668e1593dff044d8a85667050bce4680'
    GC = 'dc072f1419af6bf08c1bbbf9981f1e1e522fafa771a2b6fd33200f35ec8d2135'
}
# Skins you can pick as the source (left box): key = disc:slot
$SOURCES = @(
    @('NA:0','Alpha Combat Suit (NA)'), @('NA:1','Magnaplate Armor (NA)'), @('NA:2','Adamantine Armor (NA)'),
    @('NA:3','Aegis Mark V Armor (NA)'), @('NA:4','Infernox Armor (NA)'), @('NA:5','Old School Ratchet (NA)'),
    @('NA:6','Snowman (NA)'), @('NA:7','Tuxedo Ratchet (NA)'), @('NA:8','Buginoid (NA)'), @('NA:9','Brainius (NA)'),
    @('NA:10','Constructobot (NA)'), @('NA:11','Robo Rooster (NA)'), @('NA:12','Trooper (NA)'), @('NA:13','Robo (NA)'),
    @('NA:14','Old Adamantine Armor (NA)'),
    @('JP:0','Alpha Combat Suit (JP)'), @('JP:1','Magnaplate Armor (JP)'), @('JP:2','Adamantine Armor (JP)'),
    @('JP:3','Aegis Mark V Armor (JP)'), @('JP:4','Infernox Armor (JP)'),
    @('JP:14','Sumo (JP)'), @('JP:15','Ninja (JP)'), @('JP:16','Santa (JP)'), @('JP:17','Pipo-Saru (JP)'),
    @('GC:0','Commando Suit (GC)'), @('GC:1','Tetrafiber Armor (GC)'), @('GC:2','Duraplate Armor (GC)'),
    @('GC:3','Electrosteel Armor (GC)'), @('GC:4','Carbonox Armor (GC)'), @('GC:5','Tux Ratchet (GC)'),
    @('GC:6','Clown (GC)'), @('GC:7','Beach Boy (GC)'), @('GC:8','Snow Dude (GC)')
)
# NA slots you can over-write (right box)
$TARGETS = @(
    @(0,'Alpha Combat Suit (NA 0)'), @(1,'Magnaplate Armor (NA 1)'), @(2,'Adamantine Armor (NA 2)'),
    @(3,'Aegis Mark V Armor (NA 3)'), @(4,'Infernox Armor (NA 4)'), @(5,'Old School Ratchet (NA 5)'),
    @(6,'Snowman (NA 6)'), @(7,'Tuxedo Ratchet (NA 7)'), @(8,'Buginoid (NA 8)'), @(9,'Brainius (NA 9)'),
    @(10,'Constructobot (NA 10)'), @(11,'Robo Rooster (NA 11)'), @(12,'Trooper (NA 12)'), @(13,'Robo (NA 13)')
)
# Extra skins: NA slot <- source
$EXTRA_PLAN = @( @(14,'JP',14), @(15,'JP',15), @(16,'JP',16), @(17,'JP',17), @(18,'GC',5), @(19,'GC',6), @(20,'GC',7), @(21,'GC',8) )
$PH_FIRST = 14; $PH_LAST = 28
$TABLE_OLD = 10; $REGION_LEN = 0x3C0
# The skin unlock check as it is on the original disc (same in every level)
$F2_ORIG = '2c820008 1440000b 3c030014 2484fff8 2c820008 10400005 3c030014 906227a8 821007 3e00008 30420001 3e00008 102d 9062271e 821007 3e00008 30420001 0'
# Skins menu changes for the 34 single-player levels:
# id,codeSize,regionOfs,regionVA,unlockFnOfs | helper code + per-skin data list | fileOfs:old:new ...
$LEVELS = @(
    '1,3484a4,11c250,2f1940,2e1b9c|2c884000 11000003 0 8106068 0 3e00008 801025 0 2efdb0 3f0 2efdb0 3f0 2efdb0 3f0 2efdb0 3f0 2efdb0 3f0 2efdb0 3f0 2f01a0 150 2efdb0 3f0 2f02f0 330 2f0620 300 2f0920 300 2f0c20 300 2f0f20 390 2f12b0 1d0 2f01a0 150 2efdb0 3f0 2f0f20 390 2f12b0 1d0 2efdb0 3f0 2f0620 300 2f02f0 330 2f01a0 150 2f0920 300|24d3bc:24421480:24421a80 2e1e20:ac401cc8:ac4019a8 2e1e2c:24421c60:24421940 2e1e50:2e22000a:2e220012 2e1e68:24631c60:24631940 2e1eec:2ce2000a:2ce20012 2e1f10:3c02002f:3c020024 2e1f18:24421940:244249a0 2e1f1c:24030320:240304e0 2e3af0:24a51c60:24a51940 2ebaf4:24541c60:24541940 2ebb50:c106068:c0bc698 2ebc30:268200a0:26820120 2ebe88:26311c60:26311940 2ebec0:c106068:c0bc698 2ebedc:c106068:c0bc698',
    '2,31864c,119c90,2ef3c0,2b7c3c|2c884000 11000003 0 80fc242 0 3e00008 801025 0 2ed8f0 3f0 2ed8f0 3f0 2ed8f0 3f0 2ed8f0 3f0 2ed8f0 3f0 2ed8f0 3f0 2edce0 150 2ed8f0 3f0 2ede30 330 2ee160 300 2ee460 300 2ee760 300 2eea60 390 2eedf0 1d0 2edce0 150 2ed8f0 3f0 2eea60 390 2eedf0 1d0 2ed8f0 3f0 2ee160 300 2ede30 330 2edce0 150 2ee460 300|2251fc:2442efc0:2442f500 2b7ec0:ac40f748:ac40f428 2b7ecc:2442f6e0:2442f3c0 2b7ef0:2e22000a:2e220012 2b7f08:2463f6e0:2463f3c0 2b7f8c:2ce2000a:2ce20012 2b7fb0:3c02002f:3c020024 2b7fb8:2442f3c0:244219e0 2b7fbc:24030320:240304e0 2b9b90:24a5f6e0:24a5f3c0 2c1b94:2454f6e0:2454f3c0 2c1bf0:c0fc242:c0bbd38 2c1cd0:268200a0:26820120 2c1f28:2631f6e0:2631f3c0 2c1f60:c0fc242:c0bbd38 2c1f7c:c0fc242:c0bbd38',
    '3,335ac0,11b730,2f0e40,2cf1b8|2c884000 11000003 0 8101508 0 3e00008 801025 0 2ef370 3f0 2ef370 3f0 2ef370 3f0 2ef370 3f0 2ef370 3f0 2ef370 3f0 2ef760 150 2ef370 3f0 2ef8b0 330 2efbe0 300 2efee0 300 2f01e0 300 2f04e0 390 2f0870 1d0 2ef760 150 2ef370 3f0 2f04e0 390 2f0870 1d0 2ef370 3f0 2efbe0 300 2ef8b0 330 2ef760 150 2efee0 300|23a9e8:24420a40:24420f80 2cf43c:ac4011c8:ac400ea8 2cf448:24421160:24420e40 2cf46c:2e22000a:2e220012 2cf484:24631160:24630e40 2cf508:2ce2000a:2ce20012 2cf52c:3c02002f:3c020024 2cf534:24420e40:24422ba0 2cf538:24030320:240304e0 2d110c:24a51160:24a50e40 2d9110:24541160:24540e40 2d916c:c101508:c0bc3d8 2d924c:268200a0:26820120 2d94a4:26311160:26310e40 2d94dc:c101508:c0bc3d8 2d94f8:c101508:c0bc3d8',
    '4,352a28,11cb10,2f21c0,2f18f8|2c884000 11000003 0 810a2ae 0 3e00008 801025 0 2f0630 3f0 2f0630 3f0 2f0630 3f0 2f0630 3f0 2f0630 3f0 2f0630 3f0 2f0a20 150 2f0630 3f0 2f0b70 330 2f0ea0 300 2f11a0 300 2f14a0 300 2f17a0 390 2f1b30 1d0 2f0a20 150 2f0630 3f0 2f17a0 390 2f1b30 1d0 2f0630 3f0 2f0ea0 300 2f0b70 330 2f0a20 150 2f11a0 300|25c810:24421d00:24422300 2f1b7c:ac402548:ac402228 2f1b88:244224e0:244221c0 2f1bac:2e22000a:2e220012 2f1bc4:246324e0:246321c0 2f1c48:2ce2000a:2ce20012 2f1c6c:3c02002f:3c020024 2f1c74:244221c0:24423520 2f1c78:24030320:240304e0 2f384c:24a524e0:24a521c0 2fb850:245424e0:245421c0 2fb8ac:c10a2ae:c0bc8b8 2fb98c:268200a0:26820120 2fbbe4:263124e0:263121c0 2fbc1c:c10a2ae:c0bc8b8 2fbc38:c10a2ae:c0bc8b8',
    '5,3411e8,11ec60,2f4340,2da930|2c884000 11000003 0 8104636 0 3e00008 801025 0 2f2870 3f0 2f2870 3f0 2f2870 3f0 2f2870 3f0 2f2870 3f0 2f2870 3f0 2f2c60 150 2f2870 3f0 2f2db0 330 2f30e0 300 2f33e0 300 2f36e0 300 2f39e0 390 2f3d70 1d0 2f2c60 150 2f2870 3f0 2f39e0 390 2f3d70 1d0 2f2870 3f0 2f30e0 300 2f2db0 330 2f2c60 150 2f33e0 300|2462a0:24423f40:24424480 2dabb4:ac4046c8:ac4043a8 2dabc0:24424660:24424340 2dabe4:2e22000a:2e220012 2dabfc:24634660:24634340 2dac80:2ce2000a:2ce20012 2daca4:3c02002f:3c020024 2dacac:24424340:24424060 2dacb0:24030320:240304e0 2dc884:24a54660:24a54340 2e4888:24544660:24544340 2e48e4:c104636:c0bd118 2e49c4:268200a0:26820120 2e4c1c:26314660:26314340 2e4c54:c104636:c0bd118 2e4c70:c104636:c0bd118',
    '6,32be5c,11a2c0,2ef980,2c55f4|2c884000 11000003 0 80ff35c 0 3e00008 801025 0 2edeb0 3f0 2edeb0 3f0 2edeb0 3f0 2edeb0 3f0 2edeb0 3f0 2edeb0 3f0 2ee2a0 150 2edeb0 3f0 2ee3f0 330 2ee720 300 2eea20 300 2eed20 300 2ef020 390 2ef3b0 1d0 2ee2a0 150 2edeb0 3f0 2ef020 390 2ef3b0 1d0 2edeb0 3f0 2ee720 300 2ee3f0 330 2ee2a0 150 2eea20 300|230aec:2442f580:2442fac0 2c5878:ac40fd08:ac40f9e8 2c5884:2442fca0:2442f980 2c58a8:2e22000a:2e220012 2c58c0:2463fca0:2463f980 2c5944:2ce2000a:2ce20012 2c5968:3c02002f:3c020024 2c5970:2442f980:24421d60 2c5974:24030320:240304e0 2c7548:24a5fca0:24a5f980 2cf54c:2454fca0:2454f980 2cf5a8:c0ff35c:c0bbea8 2cf688:268200a0:26820120 2cf8e0:2631fca0:2631f980 2cf918:c0ff35c:c0bbea8 2cf934:c0ff35c:c0bbea8',
    '7,347254,11e090,2f3740,2e09ec|2c884000 11000003 0 81062ac 0 3e00008 801025 0 2f1c70 3f0 2f1c70 3f0 2f1c70 3f0 2f1c70 3f0 2f1c70 3f0 2f1c70 3f0 2f2060 150 2f1c70 3f0 2f21b0 330 2f24e0 300 2f27e0 300 2f2ae0 300 2f2de0 390 2f3170 1d0 2f2060 150 2f1c70 3f0 2f2de0 390 2f3170 1d0 2f1c70 3f0 2f24e0 300 2f21b0 330 2f2060 150 2f27e0 300|24dc94:24423340:24423880 2e0c70:ac403ac8:ac4037a8 2e0c7c:24423a60:24423740 2e0ca0:2e22000a:2e220012 2e0cb8:24633a60:24633740 2e0d3c:2ce2000a:2ce20012 2e0d60:3c02002f:3c020024 2e0d68:24423740:24422520 2e0d6c:24030320:240304e0 2e2940:24a53a60:24a53740 2ea944:24543a60:24543740 2ea9a0:c1062ac:c0bce18 2eaa80:268200a0:26820120 2eacd8:26313a60:26313740 2ead10:c1062ac:c0bce18 2ead2c:c1062ac:c0bce18',
    '8,3223ac,11b9c0,2f1040,2c3adc|2c884000 11000003 0 80fed2c 0 3e00008 801025 0 2ef570 3f0 2ef570 3f0 2ef570 3f0 2ef570 3f0 2ef570 3f0 2ef570 3f0 2ef960 150 2ef570 3f0 2efab0 330 2efde0 300 2f00e0 300 2f03e0 300 2f06e0 390 2f0a70 1d0 2ef960 150 2ef570 3f0 2f06e0 390 2f0a70 1d0 2ef570 3f0 2efde0 300 2efab0 330 2ef960 150 2f00e0 300|22fb24:24420c40:24421180 2c3d60:ac4013c8:ac4010a8 2c3d6c:24421360:24421040 2c3d90:2e22000a:2e220012 2c3da8:24631360:24631040 2c3e2c:2ce2000a:2ce20012 2c3e50:3c02002f:3c020024 2c3e58:24421040:244223a0 2c3e5c:24030320:240304e0 2c5a30:24a51360:24a51040 2cda34:24541360:24541040 2cda90:c0fed2c:c0bc458 2cdb70:268200a0:26820120 2cddc8:26311360:26311040 2cde00:c0fed2c:c0bc458 2cde1c:c0fed2c:c0bc458',
    '9,35b3f8,11cb10,2f21c0,2fba98|2c884000 11000003 0 810c4f0 0 3e00008 801025 0 2f0630 3f0 2f0630 3f0 2f0630 3f0 2f0630 3f0 2f0630 3f0 2f0630 3f0 2f0a20 150 2f0630 3f0 2f0b70 330 2f0ea0 300 2f11a0 300 2f14a0 300 2f17a0 390 2f1b30 1d0 2f0a20 150 2f0630 3f0 2f17a0 390 2f1b30 1d0 2f0630 3f0 2f0ea0 300 2f0b70 330 2f0a20 150 2f11a0 300|266a70:24421d00:24422300 2fbd1c:ac402548:ac402228 2fbd28:244224e0:244221c0 2fbd4c:2e22000a:2e220012 2fbd64:246324e0:246321c0 2fbde8:2ce2000a:2ce20012 2fbe0c:3c02002f:3c020024 2fbe14:244221c0:24423920 2fbe18:24030320:240304e0 2fd9ec:24a524e0:24a521c0 3059f0:245424e0:245421c0 305a4c:c10c4f0:c0bc8b8 305b2c:268200a0:26820120 305d84:263124e0:263121c0 305dbc:c10c4f0:c0bc8b8 305dd8:c10c4f0:c0bc8b8',
    '10,32b03c,11a330,2efa00,2c4744|2c884000 11000003 0 80fec90 0 3e00008 801025 0 2edf30 3f0 2edf30 3f0 2edf30 3f0 2edf30 3f0 2edf30 3f0 2edf30 3f0 2ee320 150 2edf30 3f0 2ee470 330 2ee7a0 300 2eeaa0 300 2eeda0 300 2ef0a0 390 2ef430 1d0 2ee320 150 2edf30 3f0 2ef0a0 390 2ef430 1d0 2edf30 3f0 2ee7a0 300 2ee470 330 2ee320 150 2eeaa0 300|230564:2442f600:2442fb40 2c49c8:ac40fd88:ac40fa68 2c49d4:2442fd20:2442fa00 2c49f8:2e22000a:2e220012 2c4a10:2463fd20:2463fa00 2c4a94:2ce2000a:2ce20012 2c4ab8:3c02002f:3c020024 2c4ac0:2442fa00:244224a0 2c4ac4:24030320:240304e0 2c6698:24a5fd20:24a5fa00 2ce69c:2454fd20:2454fa00 2ce6f8:c0fec90:c0bbec8 2ce7d8:268200a0:26820120 2cea30:2631fd20:2631fa00 2cea68:c0fec90:c0bbec8 2cea84:c0fec90:c0bbec8',
    '11,31e4ac,11f020,2f4700,2b7bf4|2c884000 11000003 0 80fc62e 0 3e00008 801025 0 2f2c30 3f0 2f2c30 3f0 2f2c30 3f0 2f2c30 3f0 2f2c30 3f0 2f2c30 3f0 2f3020 150 2f2c30 3f0 2f3170 330 2f34a0 300 2f37a0 300 2f3aa0 300 2f3da0 390 2f4130 1d0 2f3020 150 2f2c30 3f0 2f3da0 390 2f4130 1d0 2f2c30 3f0 2f34a0 300 2f3170 330 2f3020 150 2f37a0 300|22581c:24424300:24424840 2b7e78:ac404a88:ac404768 2b7e84:24424a20:24424700 2b7ea8:2e22000a:2e220012 2b7ec0:24634a20:24634700 2b7f44:2ce2000a:2ce20012 2b7f68:3c02002f:3c020024 2b7f70:24424700:24421de0 2b7f74:24030320:240304e0 2b9b48:24a54a20:24a54700 2c1b4c:24544a20:24544700 2c1ba8:c0fc62e:c0bd208 2c1c88:268200a0:26820120 2c1ee0:26314a20:26314700 2c1f18:c0fc62e:c0bd208 2c1f34:c0fc62e:c0bd208',
    '12,349abc,11c2b0,2f1940,2e311c|2c884000 11000003 0 810668a 0 3e00008 801025 0 2efdb0 3f0 2efdb0 3f0 2efdb0 3f0 2efdb0 3f0 2efdb0 3f0 2efdb0 3f0 2f01a0 150 2efdb0 3f0 2f02f0 330 2f0620 300 2f0920 300 2f0c20 300 2f0f20 390 2f12b0 1d0 2f01a0 150 2efdb0 3f0 2f0f20 390 2f12b0 1d0 2efdb0 3f0 2f0620 300 2f02f0 330 2f01a0 150 2f0920 300|24e564:24421480:24421a80 2e33a0:ac401cc8:ac4019a8 2e33ac:24421c60:24421940 2e33d0:2e22000a:2e220012 2e33e8:24631c60:24631940 2e346c:2ce2000a:2ce20012 2e3490:3c02002f:3c020024 2e3498:24421940:244246e0 2e349c:24030320:240304e0 2e5070:24a51c60:24a51940 2ed074:24541c60:24541940 2ed0d0:c10668a:c0bc698 2ed1b0:268200a0:26820120 2ed408:26311c60:26311940 2ed440:c10668a:c0bc698 2ed45c:c10668a:c0bc698',
    '13,328104,11aae0,2f0180,2c184c|2c884000 11000003 0 80fe540 0 3e00008 801025 0 2ee6b0 3f0 2ee6b0 3f0 2ee6b0 3f0 2ee6b0 3f0 2ee6b0 3f0 2ee6b0 3f0 2eeaa0 150 2ee6b0 3f0 2eebf0 330 2eef20 300 2ef220 300 2ef520 300 2ef820 390 2efbb0 1d0 2eeaa0 150 2ee6b0 3f0 2ef820 390 2efbb0 1d0 2ee6b0 3f0 2eef20 300 2eebf0 330 2eeaa0 150 2ef220 300|22dc14:2442fd80:244202c0 2c1ad0:ac400508:ac4001e8 2c1adc:244204a0:24420180 2c1b00:2e22000a:2e220012 2c1b18:246304a0:24630180 2c1b9c:2ce2000a:2ce20012 2c1bc0:3c02002f:3c020024 2c1bc8:24420180:24422820 2c1bcc:24030320:240304e0 2c37a0:24a504a0:24a50180 2cb7a4:245404a0:24540180 2cb800:c0fe540:c0bc0a8 2cb8e0:268200a0:26820120 2cbb38:263104a0:26310180 2cbb70:c0fe540:c0bc0a8 2cbb8c:c0fe540:c0bc0a8',
    '14,332d1c,11df50,2f35c0,2cc464|2c884000 11000003 0 8100b0c 0 3e00008 801025 0 2f1af0 3f0 2f1af0 3f0 2f1af0 3f0 2f1af0 3f0 2f1af0 3f0 2f1af0 3f0 2f1ee0 150 2f1af0 3f0 2f2030 330 2f2360 300 2f2660 300 2f2960 300 2f2c60 390 2f2ff0 1d0 2f1ee0 150 2f1af0 3f0 2f2c60 390 2f2ff0 1d0 2f1af0 3f0 2f2360 300 2f2030 330 2f1ee0 150 2f2660 300|237f74:244231c0:24423700 2cc6e8:ac403948:ac403628 2cc6f4:244238e0:244235c0 2cc718:2e22000a:2e220012 2cc730:246338e0:246335c0 2cc7b4:2ce2000a:2ce20012 2cc7d8:3c02002f:3c020024 2cc7e0:244235c0:244231e0 2cc7e4:24030320:240304e0 2ce3b8:24a538e0:24a535c0 2d63bc:245438e0:245435c0 2d6418:c100b0c:c0bcdb8 2d64f8:268200a0:26820120 2d6750:263138e0:263135c0 2d6788:c100b0c:c0bcdb8 2d67a4:c100b0c:c0bcdb8',
    '16,359a04,127c60,2fd300,2f30ec|2c884000 11000003 0 8109ef4 0 3e00008 801025 0 2fb770 3f0 2fb770 3f0 2fb770 3f0 2fb770 3f0 2fb770 3f0 2fb770 3f0 2fbb60 150 2fb770 3f0 2fbcb0 330 2fbfe0 300 2fc2e0 300 2fc5e0 300 2fc8e0 390 2fcc70 1d0 2fbb60 150 2fb770 3f0 2fc8e0 390 2fcc70 1d0 2fb770 3f0 2fbfe0 300 2fbcb0 330 2fbb60 150 2fc2e0 300|25dc34:2442ce40:2442d440 2f3370:ac40d688:ac40d368 2f337c:2442d620:2442d300 2f33a0:2e22000a:2e220012 2f33b8:2463d620:2463d300 2f343c:2ce2000a:2ce20012 2f3460:3c020030:3c020024 2f3468:2442d300:24423f60 2f346c:24030320:240304e0 2f5040:24a5d620:24a5d300 2fd044:2454d620:2454d300 2fd0a0:c109ef4:c0bf508 2fd180:268200a0:26820120 2fd3d8:2631d620:2631d300 2fd410:c109ef4:c0bf508 2fd42c:c109ef4:c0bf508',
    '17,32174c,123af0,2f9180,2baee4|2c884000 11000003 0 80fcea4 0 3e00008 801025 0 2f76b0 3f0 2f76b0 3f0 2f76b0 3f0 2f76b0 3f0 2f76b0 3f0 2f76b0 3f0 2f7aa0 150 2f76b0 3f0 2f7bf0 330 2f7f20 300 2f8220 300 2f8520 300 2f8820 390 2f8bb0 1d0 2f7aa0 150 2f76b0 3f0 2f8820 390 2f8bb0 1d0 2f76b0 3f0 2f7f20 300 2f7bf0 330 2f7aa0 150 2f8220 300|2283ec:24428d80:244292c0 2bb168:ac409508:ac4091e8 2bb174:244294a0:24429180 2bb198:2e22000a:2e220012 2bb1b0:246394a0:24639180 2bb234:2ce2000a:2ce20012 2bb258:3c020030:3c020024 2bb260:24429180:24421fe0 2bb264:24030320:240304e0 2bce38:24a594a0:24a59180 2c4e3c:245494a0:24549180 2c4e98:c0fcea4:c0be4a8 2c4f78:268200a0:26820120 2c51d0:263194a0:26319180 2c5208:c0fcea4:c0be4a8 2c5224:c0fcea4:c0be4a8',
    '18,35adb4,11ca90,2f2180,2f4414|2c884000 11000003 0 810ac2a 0 3e00008 801025 0 2f05f0 3f0 2f05f0 3f0 2f05f0 3f0 2f05f0 3f0 2f05f0 3f0 2f05f0 3f0 2f09e0 150 2f05f0 3f0 2f0b30 330 2f0e60 300 2f1160 300 2f1460 300 2f1760 390 2f1af0 1d0 2f09e0 150 2f05f0 3f0 2f1760 390 2f1af0 1d0 2f05f0 3f0 2f0e60 300 2f0b30 330 2f09e0 150 2f1160 300|25f514:24421cc0:244222c0 2f4698:ac402508:ac4021e8 2f46a4:244224a0:24422180 2f46c8:2e22000a:2e220012 2f46e0:246324a0:24632180 2f4764:2ce2000a:2ce20012 2f4788:3c02002f:3c020024 2f4790:24422180:24424a20 2f4794:24030320:240304e0 2f6368:24a524a0:24a52180 2fe36c:245424a0:24542180 2fe3c8:c10ac2a:c0bc8a8 2fe4a8:268200a0:26820120 2fe700:263124a0:26312180 2fe738:c10ac2a:c0bc8a8 2fe754:c10ac2a:c0bc8a8',
    '19,33996c,11eb70,2f4200,2d6044|2c884000 11000003 0 81033b6 0 3e00008 801025 0 2f2730 3f0 2f2730 3f0 2f2730 3f0 2f2730 3f0 2f2730 3f0 2f2730 3f0 2f2b20 150 2f2730 3f0 2f2c70 330 2f2fa0 300 2f32a0 300 2f35a0 300 2f38a0 390 2f3c30 1d0 2f2b20 150 2f2730 3f0 2f38a0 390 2f3c30 1d0 2f2730 3f0 2f2fa0 300 2f2c70 330 2f2b20 150 2f32a0 300|24161c:24423e00:24424340 2d62c8:ac404588:ac404268 2d62d4:24424520:24424200 2d62f8:2e22000a:2e220012 2d6310:24634520:24634200 2d6394:2ce2000a:2ce20012 2d63b8:3c02002f:3c020024 2d63c0:24424200:24422760 2d63c4:24030320:240304e0 2d7f98:24a54520:24a54200 2dff9c:24544520:24544200 2dfff8:c1033b6:c0bd0c8 2e00d8:268200a0:26820120 2e0330:26314520:26314200 2e0368:c1033b6:c0bd0c8 2e0384:c1033b6:c0bd0c8',
    '20,367f68,125ea0,2fb580,301660|2c884000 11000003 0 810d95c 0 3e00008 801025 0 2f99f0 3f0 2f99f0 3f0 2f99f0 3f0 2f99f0 3f0 2f99f0 3f0 2f99f0 3f0 2f9de0 150 2f99f0 3f0 2f9f30 330 2fa260 300 2fa560 300 2fa860 300 2fab60 390 2faef0 1d0 2f9de0 150 2f99f0 3f0 2fab60 390 2faef0 1d0 2f99f0 3f0 2fa260 300 2f9f30 330 2f9de0 150 2fa560 300|26c8c0:2442b0c0:2442b6c0 3018e4:ac40b908:ac40b5e8 3018f0:2442b8a0:2442b580 301914:2e22000a:2e220012 30192c:2463b8a0:2463b580 3019b0:2ce2000a:2ce20012 3019d4:3c020030:3c020024 3019dc:2442b580:24423ae0 3019e0:24030320:240304e0 3035b4:24a5b8a0:24a5b580 30b5b8:2454b8a0:2454b580 30b614:c10d95c:c0beda8 30b6f4:268200a0:26820120 30b94c:2631b8a0:2631b580 30b984:c10d95c:c0beda8 30b9a0:c10d95c:c0beda8',
    '21,31f318,124d00,2fa3c0,2b8a60|2c884000 11000003 0 80fc380 0 3e00008 801025 0 2f88f0 3f0 2f88f0 3f0 2f88f0 3f0 2f88f0 3f0 2f88f0 3f0 2f88f0 3f0 2f8ce0 150 2f88f0 3f0 2f8e30 330 2f9160 300 2f9460 300 2f9760 300 2f9a60 390 2f9df0 1d0 2f8ce0 150 2f88f0 3f0 2f9a60 390 2f9df0 1d0 2f88f0 3f0 2f9160 300 2f8e30 330 2f8ce0 150 2f9460 300|226748:24429fc0:2442a500 2b8ce4:ac40a748:ac40a428 2b8cf0:2442a6e0:2442a3c0 2b8d14:2e22000a:2e220012 2b8d2c:2463a6e0:2463a3c0 2b8db0:2ce2000a:2ce20012 2b8dd4:3c020030:3c020024 2b8ddc:2442a3c0:24421de0 2b8de0:24030320:240304e0 2ba9b4:24a5a6e0:24a5a3c0 2c29b8:2454a6e0:2454a3c0 2c2a14:c0fc380:c0be938 2c2af4:268200a0:26820120 2c2d4c:2631a6e0:2631a3c0 2c2d84:c0fc380:c0be938 2c2da0:c0fc380:c0be938',
    '22,34f068,11dce0,2f3340,2e8760|2c884000 11000003 0 81075ea 0 3e00008 801025 0 2f17b0 3f0 2f17b0 3f0 2f17b0 3f0 2f17b0 3f0 2f17b0 3f0 2f17b0 3f0 2f1ba0 150 2f17b0 3f0 2f1cf0 330 2f2020 300 2f2320 300 2f2620 300 2f2920 390 2f2cb0 1d0 2f1ba0 150 2f17b0 3f0 2f2920 390 2f2cb0 1d0 2f17b0 3f0 2f2020 300 2f1cf0 330 2f1ba0 150 2f2320 300|252560:24422e80:24423480 2e89e4:ac4036c8:ac4033a8 2e89f0:24423660:24423340 2e8a14:2e22000a:2e220012 2e8a2c:24633660:24633340 2e8ab0:2ce2000a:2ce20012 2e8ad4:3c02002f:3c020024 2e8adc:24423340:24423760 2e8ae0:24030320:240304e0 2ea6b4:24a53660:24a53340 2f26b8:24543660:24543340 2f2714:c1075ea:c0bcd18 2f27f4:268200a0:26820120 2f2a4c:26313660:26313340 2f2a84:c1075ea:c0bcd18 2f2aa0:c1075ea:c0bcd18',
    '23,32c2f0,11d2a0,2f2980,2c3560|2c884000 11000003 0 80fec1e 0 3e00008 801025 0 2f0eb0 3f0 2f0eb0 3f0 2f0eb0 3f0 2f0eb0 3f0 2f0eb0 3f0 2f0eb0 3f0 2f12a0 150 2f0eb0 3f0 2f13f0 330 2f1720 300 2f1a20 300 2f1d20 300 2f2020 390 2f23b0 1d0 2f12a0 150 2f0eb0 3f0 2f2020 390 2f23b0 1d0 2f0eb0 3f0 2f1720 300 2f13f0 330 2f12a0 150 2f1a20 300|230468:24422580:24422ac0 2c37e4:ac402d08:ac4029e8 2c37f0:24422ca0:24422980 2c3814:2e22000a:2e220012 2c382c:24632ca0:24632980 2c38b0:2ce2000a:2ce20012 2c38d4:3c02002f:3c020024 2c38dc:24422980:24422660 2c38e0:24030320:240304e0 2c54b4:24a52ca0:24a52980 2cd4b8:24542ca0:24542980 2cd514:c0fec1e:c0bcaa8 2cd5f4:268200a0:26820120 2cd84c:26312ca0:26312980 2cd884:c0fec1e:c0bcaa8 2cd8a0:c0fec1e:c0bcaa8',
    '24,32d2c8,11a070,2ef700,2c69f8|2c884000 11000003 0 81000e0 0 3e00008 801025 0 2edc30 3f0 2edc30 3f0 2edc30 3f0 2edc30 3f0 2edc30 3f0 2edc30 3f0 2ee020 150 2edc30 3f0 2ee170 330 2ee4a0 300 2ee7a0 300 2eeaa0 300 2eeda0 390 2ef130 1d0 2ee020 150 2edc30 3f0 2eeda0 390 2ef130 1d0 2edc30 3f0 2ee4a0 300 2ee170 330 2ee020 150 2ee7a0 300|234108:2442f300:2442f840 2c6c7c:ac40fa88:ac40f768 2c6c88:2442fa20:2442f700 2c6cac:2e22000a:2e220012 2c6cc4:2463fa20:2463f700 2c6d48:2ce2000a:2ce20012 2c6d6c:3c02002f:3c020024 2c6d74:2442f700:24422860 2c6d78:24030320:240304e0 2c894c:24a5fa20:24a5f700 2d0950:2454fa20:2454f700 2d09ac:c1000e0:c0bbe08 2d0a8c:268200a0:26820120 2d0ce4:2631fa20:2631f700 2d0d1c:c1000e0:c0bbe08 2d0d38:c1000e0:c0bbe08',
    '26,350ff4,11c090,2f1780,2ea654|2c884000 11000003 0 8108740 0 3e00008 801025 0 2efbf0 3f0 2efbf0 3f0 2efbf0 3f0 2efbf0 3f0 2efbf0 3f0 2efbf0 3f0 2effe0 150 2efbf0 3f0 2f0130 330 2f0460 300 2f0760 300 2f0a60 300 2f0d60 390 2f10f0 1d0 2effe0 150 2efbf0 3f0 2f0d60 390 2f10f0 1d0 2efbf0 3f0 2f0460 300 2f0130 330 2effe0 150 2f0760 300|255a34:244212c0:244218c0 2ea8d8:ac401b08:ac4017e8 2ea8e4:24421aa0:24421780 2ea908:2e22000a:2e220012 2ea920:24631aa0:24631780 2ea9a4:2ce2000a:2ce20012 2ea9c8:3c02002f:3c020024 2ea9d0:24421780:244247a0 2ea9d4:24030320:240304e0 2ec5a8:24a51aa0:24a51780 2f45ac:24541aa0:24541780 2f4608:c108740:c0bc628 2f46e8:268200a0:26820120 2f4940:26311aa0:26311780 2f4978:c108740:c0bc628 2f4994:c108740:c0bc628',
    '27,316fb4,11e9a0,2f4040,2b8344|2c884000 11000003 0 80fc688 0 3e00008 801025 0 2f2570 3f0 2f2570 3f0 2f2570 3f0 2f2570 3f0 2f2570 3f0 2f2570 3f0 2f2960 150 2f2570 3f0 2f2ab0 330 2f2de0 300 2f30e0 300 2f33e0 300 2f36e0 390 2f3a70 1d0 2f2960 150 2f2570 3f0 2f36e0 390 2f3a70 1d0 2f2570 3f0 2f2de0 300 2f2ab0 330 2f2960 150 2f30e0 300|225bdc:24423c40:24424180 2b85c8:ac4043c8:ac4040a8 2b85d4:24424360:24424040 2b85f8:2e22000a:2e220012 2b8610:24634360:24634040 2b8694:2ce2000a:2ce20012 2b86b8:3c02002f:3c020024 2b86c0:24424040:24421ce0 2b86c4:24030320:240304e0 2ba298:24a54360:24a54040 2c229c:24544360:24544040 2c22f8:c0fc688:c0bd058 2c23d8:268200a0:26820120 2c2630:26314360:26314040 2c2668:c0fc688:c0bd058 2c2684:c0fc688:c0bd058',
    '28,30fd28,119460,2eeac0,2a9470|2c884000 11000003 0 80f8fac 0 3e00008 801025 0 2ecff0 3f0 2ecff0 3f0 2ecff0 3f0 2ecff0 3f0 2ecff0 3f0 2ecff0 3f0 2ed3e0 150 2ecff0 3f0 2ed530 330 2ed860 300 2edb60 300 2ede60 300 2ee160 390 2ee4f0 1d0 2ed3e0 150 2ecff0 3f0 2ee160 390 2ee4f0 1d0 2ecff0 3f0 2ed860 300 2ed530 330 2ed3e0 150 2edb60 300|217d78:2442e6c0:2442ec00 2a96f4:ac40ee48:ac40eb28 2a9700:2442ede0:2442eac0 2a9724:2e22000a:2e220012 2a973c:2463ede0:2463eac0 2a97c0:2ce2000a:2ce20012 2a97e4:3c02002f:3c020024 2a97ec:2442eac0:24421ba0 2a97f0:24030320:240304e0 2ab3c4:24a5ede0:24a5eac0 2b33c8:2454ede0:2454eac0 2b3424:c0f8fac:c0bbaf8 2b3504:268200a0:26820120 2b375c:2631ede0:2631eac0 2b3794:c0f8fac:c0bbaf8 2b37b0:c0f8fac:c0bbaf8',
    '29,3539cc,11c3a0,2f1a00,2ed0c4|2c884000 11000003 0 81091ea 0 3e00008 801025 0 2efe70 3f0 2efe70 3f0 2efe70 3f0 2efe70 3f0 2efe70 3f0 2efe70 3f0 2f0260 150 2efe70 3f0 2f03b0 330 2f06e0 300 2f09e0 300 2f0ce0 300 2f0fe0 390 2f1370 1d0 2f0260 150 2efe70 3f0 2f0fe0 390 2f1370 1d0 2efe70 3f0 2f06e0 300 2f03b0 330 2f0260 150 2f09e0 300|25857c:24421540:24421b40 2ed348:ac401d88:ac401a68 2ed354:24421d20:24421a00 2ed378:2e22000a:2e220012 2ed390:24631d20:24631a00 2ed414:2ce2000a:2ce20012 2ed438:3c02002f:3c020024 2ed440:24421a00:24424460 2ed444:24030320:240304e0 2ef018:24a51d20:24a51a00 2f701c:24541d20:24541a00 2f7078:c1091ea:c0bc6c8 2f7158:268200a0:26820120 2f73b0:26311d20:26311a00 2f73e8:c1091ea:c0bc6c8 2f7404:c1091ea:c0bc6c8',
    '30,31b160,11a940,2effc0,2af8c0|2c884000 11000003 0 80faf08 0 3e00008 801025 0 2ee4f0 3f0 2ee4f0 3f0 2ee4f0 3f0 2ee4f0 3f0 2ee4f0 3f0 2ee4f0 3f0 2ee8e0 150 2ee4f0 3f0 2eea30 330 2eed60 300 2ef060 300 2ef360 300 2ef660 390 2ef9f0 1d0 2ee8e0 150 2ee4f0 3f0 2ef660 390 2ef9f0 1d0 2ee4f0 3f0 2eed60 300 2eea30 330 2ee8e0 150 2ef060 300|21f988:2442fbc0:24420100 2afb44:ac400348:ac400028 2afb50:244202e0:2442ffc0 2afb74:2e22000a:2e220012 2afb8c:246302e0:2463ffc0 2afc10:2ce2000a:2ce20012 2afc34:3c02002f:3c020024 2afc3c:2442ffc0:24422920 2afc40:24030320:240304e0 2b1814:24a502e0:24a5ffc0 2b9818:245402e0:2454ffc0 2b9874:c0faf08:c0bc038 2b9954:268200a0:26820120 2b9bac:263102e0:2631ffc0 2b9be4:c0faf08:c0bc038 2b9c00:c0faf08:c0bc038',
    '31,31a8fc,11c100,2f17c0,2af05c|2c884000 11000003 0 80fc088 0 3e00008 801025 0 2efcf0 3f0 2efcf0 3f0 2efcf0 3f0 2efcf0 3f0 2efcf0 3f0 2efcf0 3f0 2f00e0 150 2efcf0 3f0 2f0230 330 2f0560 300 2f0860 300 2f0b60 300 2f0e60 390 2f11f0 1d0 2f00e0 150 2efcf0 3f0 2f0e60 390 2f11f0 1d0 2efcf0 3f0 2f0560 300 2f0230 330 2f00e0 150 2f0860 300|223f6c:244213c0:24421900 2af2e0:ac401b48:ac401828 2af2ec:24421ae0:244217c0 2af310:2e22000a:2e220012 2af328:24631ae0:246317c0 2af3ac:2ce2000a:2ce20012 2af3d0:3c02002f:3c020024 2af3d8:244217c0:24422a20 2af3dc:24030320:240304e0 2b0fb0:24a51ae0:24a517c0 2b8fb4:24541ae0:245417c0 2b9010:c0fc088:c0bc638 2b90f0:268200a0:26820120 2b9348:26311ae0:263117c0 2b9380:c0fc088:c0bc638 2b939c:c0fc088:c0bc638',
    '32,323cc8,11c8e0,2f1fc0,2b8428|2c884000 11000003 0 80fe278 0 3e00008 801025 0 2f04f0 3f0 2f04f0 3f0 2f04f0 3f0 2f04f0 3f0 2f04f0 3f0 2f04f0 3f0 2f08e0 150 2f04f0 3f0 2f0a30 330 2f0d60 300 2f1060 300 2f1360 300 2f1660 390 2f19f0 1d0 2f08e0 150 2f04f0 3f0 2f1660 390 2f19f0 1d0 2f04f0 3f0 2f0d60 300 2f0a30 330 2f08e0 150 2f1060 300|22c6c8:24421bc0:24422100 2b86ac:ac402348:ac402028 2b86b8:244222e0:24421fc0 2b86dc:2e22000a:2e220012 2b86f4:246322e0:24631fc0 2b8778:2ce2000a:2ce20012 2b879c:3c02002f:3c020024 2b87a4:24421fc0:244231a0 2b87a8:24030320:240304e0 2ba37c:24a522e0:24a51fc0 2c2380:245422e0:24541fc0 2c23dc:c0fe278:c0bc838 2c24bc:268200a0:26820120 2c2714:263122e0:26311fc0 2c274c:c0fe278:c0bc838 2c2768:c0fe278:c0bc838',
    '33,31c490,11be90,2f1540,2b0bf0|2c884000 11000003 0 80fc3a6 0 3e00008 801025 0 2efa70 3f0 2efa70 3f0 2efa70 3f0 2efa70 3f0 2efa70 3f0 2efa70 3f0 2efe60 150 2efa70 3f0 2effb0 330 2f02e0 300 2f05e0 300 2f08e0 300 2f0be0 390 2f0f70 1d0 2efe60 150 2efa70 3f0 2f0be0 390 2f0f70 1d0 2efa70 3f0 2f02e0 300 2effb0 330 2efe60 150 2f05e0 300|224c00:24421140:24421680 2b0e74:ac4018c8:ac4015a8 2b0e80:24421860:24421540 2b0ea4:2e22000a:2e220012 2b0ebc:24631860:24631540 2b0f40:2ce2000a:2ce20012 2b0f64:3c02002f:3c020024 2b0f6c:24421540:24422ea0 2b0f70:24030320:240304e0 2b2b44:24a51860:24a51540 2bab48:24541860:24541540 2baba4:c0fc3a6:c0bc598 2bac84:268200a0:26820120 2baedc:26311860:26311540 2baf14:c0fc3a6:c0bc598 2baf30:c0fc3a6:c0bc598',
    '34,3217ec,11c5f0,2f1cc0,2b5f4c|2c884000 11000003 0 80fc932 0 3e00008 801025 0 2f01f0 3f0 2f01f0 3f0 2f01f0 3f0 2f01f0 3f0 2f01f0 3f0 2f01f0 3f0 2f05e0 150 2f01f0 3f0 2f0730 330 2f0a60 300 2f0d60 300 2f1060 300 2f1360 390 2f16f0 1d0 2f05e0 150 2f01f0 3f0 2f1360 390 2f16f0 1d0 2f01f0 3f0 2f0a60 300 2f0730 330 2f05e0 150 2f0d60 300|2261e4:244218c0:24421e00 2b61d0:ac402048:ac401d28 2b61dc:24421fe0:24421cc0 2b6200:2e22000a:2e220012 2b6218:24631fe0:24631cc0 2b629c:2ce2000a:2ce20012 2b62c0:3c02002f:3c020024 2b62c8:24421cc0:24422b20 2b62cc:24030320:240304e0 2b7ea0:24a51fe0:24a51cc0 2bfea4:24541fe0:24541cc0 2bff00:c0fc932:c0bc778 2bffe0:268200a0:26820120 2c0238:26311fe0:26311cc0 2c0270:c0fc932:c0bc778 2c028c:c0fc932:c0bc778',
    '35,31ba88,11c660,2f1d80,2b01e8|2c884000 11000003 0 80fc552 0 3e00008 801025 0 2f02b0 3f0 2f02b0 3f0 2f02b0 3f0 2f02b0 3f0 2f02b0 3f0 2f02b0 3f0 2f06a0 150 2f02b0 3f0 2f07f0 330 2f0b20 300 2f0e20 300 2f1120 300 2f1420 390 2f17b0 1d0 2f06a0 150 2f02b0 3f0 2f1420 390 2f17b0 1d0 2f02b0 3f0 2f0b20 300 2f07f0 330 2f06a0 150 2f0e20 300|225280:24421980:24421ec0 2b046c:ac402108:ac401de8 2b0478:244220a0:24421d80 2b049c:2e22000a:2e220012 2b04b4:246320a0:24631d80 2b0538:2ce2000a:2ce20012 2b055c:3c02002f:3c020024 2b0564:24421d80:24422b60 2b0568:24030320:240304e0 2b213c:24a520a0:24a51d80 2ba140:245420a0:24541d80 2ba19c:c0fc552:c0bc7a8 2ba27c:268200a0:26820120 2ba4d4:263120a0:26311d80 2ba50c:c0fc552:c0bc7a8 2ba528:c0fc552:c0bc7a8',
    '36,3215d0,11c800,2f1ec0,2b5d30|2c884000 11000003 0 80fdbc8 0 3e00008 801025 0 2f03f0 3f0 2f03f0 3f0 2f03f0 3f0 2f03f0 3f0 2f03f0 3f0 2f03f0 3f0 2f07e0 150 2f03f0 3f0 2f0930 330 2f0c60 300 2f0f60 300 2f1260 300 2f1560 390 2f18f0 1d0 2f07e0 150 2f03f0 3f0 2f1560 390 2f18f0 1d0 2f03f0 3f0 2f0c60 300 2f0930 330 2f07e0 150 2f0f60 300|22ac40:24421ac0:24422000 2b5fb4:ac402248:ac401f28 2b5fc0:244221e0:24421ec0 2b5fe4:2e22000a:2e220012 2b5ffc:246321e0:24631ec0 2b6080:2ce2000a:2ce20012 2b60a4:3c02002f:3c020024 2b60ac:24421ec0:24422d60 2b60b0:24030320:240304e0 2b7c84:24a521e0:24a51ec0 2bfc88:245421e0:24541ec0 2bfce4:c0fdbc8:c0bc7f8 2bfdc4:268200a0:26820120 2c001c:263121e0:26311ec0 2c0054:c0fdbc8:c0bc7f8 2c0070:c0fdbc8:c0bc7f8'
)

# ======================= log (this console window) =======================
function Log([string]$msg, [string]$color = 'Gray') { Write-Host $msg -ForegroundColor $color }

# ======================= disc helpers =======================
function I32([byte[]]$b, [int]$o) { return [BitConverter]::ToInt32($b, $o) }
function U32([byte[]]$b, [int]$o) { return [BitConverter]::ToUInt32($b, $o) }
function Hex([string]$s) { return [Convert]::ToUInt32($s, 16) }
function Sha([byte[]]$b) {
    $h = [System.Security.Cryptography.SHA256]::Create()
    try { return (($h.ComputeHash($b) | ForEach-Object { $_.ToString('x2') }) -join '') } finally { $h.Dispose() }
}
function Read-At([System.IO.FileStream]$fs, [long]$offset, [int]$count) {
    $buf = New-Object byte[] $count
    [void]$fs.Seek($offset, [System.IO.SeekOrigin]::Begin)
    $got = 0
    while ($got -lt $count) {
        $n = $fs.Read($buf, $got, $count - $got)
        if ($n -le 0) { throw "Unexpected end of file at offset $offset." }
        $got += $n
    }
    return ,$buf
}
function Write-At([System.IO.FileStream]$fs, [long]$offset, [byte[]]$data) {
    [void]$fs.Seek($offset, [System.IO.SeekOrigin]::Begin)
    $fs.Write($data, 0, $data.Length)
}
function Open-Read([string]$path) {
    return [System.IO.File]::Open($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
}
function Get-Serial([System.IO.FileStream]$fs) {
    try {
        $pvd = Read-At $fs (16 * $SECTOR) $SECTOR
        $rootLba = I32 $pvd 158; $rootLen = I32 $pvd 166
        $dir = Read-At $fs ([long]$rootLba * $SECTOR) ([Math]::Min([Math]::Max($rootLen, $SECTOR), 65536))
        $p = 0
        while ($p -lt $dir.Length - 34) {
            $len = [int]$dir[$p]
            if ($len -eq 0) { $p = ([int][Math]::Floor($p / $SECTOR) + 1) * $SECTOR; continue }
            $nl = [int]$dir[$p + 32]
            if ($p + 33 + $nl -gt $dir.Length) { break }
            $name = [System.Text.Encoding]::ASCII.GetString($dir, $p + 33, $nl)
            if ($name -like 'SYSTEM.CNF*') {
                $lba = I32 $dir ($p + 2); $size = I32 $dir ($p + 10)
                $cnf = [System.Text.Encoding]::ASCII.GetString((Read-At $fs ([long]$lba * $SECTOR) ([Math]::Min([Math]::Max($size, 1), $SECTOR))))
                if ($cnf -match '(S[A-Z]{3})_(\d{3})\.(\d{2})') { return ('{0}-{1}{2}' -f $Matches[1], $Matches[2], $Matches[3]) }
                return $null
            }
            $p += $len
        }
    } catch { }
    return $null
}
# Reads the hidden table of contents: the ARMOR (skins) table and where each level's code is.
function Read-Disc([System.IO.FileStream]$fs) {
    $toc = Read-At $fs ([long]$TOC_LBA * $SECTOR) $TOC_SIZE
    $ofs = 0; $armor = -1; $hsA = 0
    while ($ofs + 8 -le $toc.Length) {
        $hs = I32 $toc $ofs
        if ($hs -lt 8 -or $hs -gt 0xFFFF) { break }
        if (($hs -eq $HDR_UYA -or $hs -eq $HDR_GC) -and $armor -lt 0) { $armor = $ofs; $hsA = $hs }
        $ofs += $hs
    }
    if ($armor -lt 0) { throw 'no skin table found' }
    $game = if ($hsA -eq $HDR_UYA) { 'UYA' } else { 'GC' }
    $count = if ($game -eq 'UYA') { 29 } else { 9 }
    $hdr = New-Object byte[] $hsA
    [Array]::Copy($toc, $armor, $hdr, 0, $hsA)
    $slots = @()
    for ($s = 0; $s -lt $count; $s++) {
        $p = 8 + 16 * $s
        $slots += ,@((I32 $hdr $p), (I32 $hdr ($p + 4)), (I32 $hdr ($p + 8)), (I32 $hdr ($p + 12)))
    }
    $offs = New-Object System.Collections.Generic.List[int]
    for ($p = 8; $p + 8 -le $hsA; $p += 8) { if ((I32 $hdr ($p + 4)) -gt 0) { $offs.Add((I32 $hdr $p)) } }
    $offs.Sort()
    $lvmap = @{}
    if ($game -eq 'UYA') {
        for ($i = 0; $i -lt 100; $i++) {
            $e = $ofs + $i * 24
            if ($e + 24 -gt $toc.Length) { break }
            for ($j = 0; $j -lt 3; $j++) {
                $lba = I32 $toc ($e + 8 * $j)
                $ho = ([long]$lba - $TOC_LBA) * $SECTOR
                if ($lba -le $TOC_LBA -or $ho + 0x60 -gt $toc.Length) { continue }
                if ((I32 $toc ([int]$ho)) -ne 0x60) { continue }
                $wad = I32 $toc ([int]$ho + 4); $id = I32 $toc ([int]$ho + 8); $dOfs = I32 $toc ([int]$ho + 0x10)
                $dataPos = ([long]$wad + $dOfs) * $SECTOR
                if ($dataPos + 0x60 -gt $fs.Length) { continue }
                $dh = Read-At $fs $dataPos 0x60
                $lvmap[$id] = [pscustomobject]@{ Pos = $dataPos + (I32 $dh 0); Size = (I32 $dh 4) }
            }
        }
    }
    return [pscustomobject]@{
        Game = $game; Header = $hdr; Levels = $lvmap; Slots = $slots; Offs = $offs
        WadPos = [long](I32 $hdr 4) * $SECTOR; TocPos = [long]$TOC_LBA * $SECTOR + $armor
    }
}
function Read-Slot([System.IO.FileStream]$fs, $disc, [int]$s) {
    $e = $disc.Slots[$s]
    return ,@((Read-At $fs ($disc.WadPos + [long]$e[0] * $SECTOR) ($e[1] * $SECTOR)), (Read-At $fs ($disc.WadPos + [long]$e[2] * $SECTOR) ($e[3] * $SECTOR)))
}
function Slot-Hash([System.IO.FileStream]$fs, $disc, [int]$s) {
    $d = Read-Slot $fs $disc $s
    return (Sha $d[0]) + (Sha $d[1])
}
function Get-Cap($disc, [int]$o, [int]$size) {
    foreach ($x in $disc.Offs) { if ($x -gt $o) { return [Math]::Max($x - $o, $size) } }
    return $size
}
function Entry-Bytes([int]$mo, [int]$ms, [int]$to, [int]$ts) {
    $b = New-Object byte[] 16
    [Array]::Copy([BitConverter]::GetBytes($mo), 0, $b, 0, 4)
    [Array]::Copy([BitConverter]::GetBytes($ms), 0, $b, 4, 4)
    [Array]::Copy([BitConverter]::GetBytes($to), 0, $b, 8, 4)
    [Array]::Copy([BitConverter]::GetBytes($ts), 0, $b, 12, 4)
    return ,$b
}
function Pad([byte[]]$data, [int]$sectors) {
    if ($data.Length -ge $sectors * $SECTOR) { return ,$data }
    $b = New-Object byte[] ($sectors * $SECTOR); [Array]::Copy($data, $b, $data.Length); return ,$b
}
function Unique-Path([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return $path }
    $dir = Split-Path -Parent $path; $name = [System.IO.Path]::GetFileNameWithoutExtension($path)
    for ($n = 2; $n -lt 1000; $n++) {
        $p = Join-Path $dir ("{0} ({1}).iso" -f $name, $n)
        if (-not (Test-Path -LiteralPath $p)) { return $p }
    }
    throw 'Could not find a free output file name.'
}

# Checks one disc box. Returns @{ Ok; Reason }.
function Test-Disc([string]$path, [string]$role) {
    $label = $ROLE_NAME[$role]
    $path = $path.Trim().Trim('"').Trim()
    if (-not $path) { return @{ Ok = $false; Empty = $true; Reason = '' } }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return @{ Ok = $false; Reason = "${label}: file not found: $path" } }
    $fs = $null
    try {
        try { $fs = Open-Read $path } catch { return @{ Ok = $false; Reason = "${label}: the file can't be opened (is it in use?): $path" } }
        if ($fs.Length -lt 17 * $SECTOR) { return @{ Ok = $false; Reason = "${label}: not a plain .iso disc image (the file is too small)." } }
        $pvd = Read-At $fs (16 * $SECTOR) $SECTOR
        if ([System.Text.Encoding]::ASCII.GetString($pvd, 1, 5) -ne 'CD001') { return @{ Ok = $false; Reason = "${label}: not a plain .iso disc image (convert .chd/.cso/.bin to .iso first)." } }
        $serial = Get-Serial $fs
        if (-not $serial) { return @{ Ok = $false; Reason = "${label}: no PS2 game serial found on this disc." } }
        if ($ACCEPTED[$role] -notcontains $serial) {
            if ($KNOWN_SERIAL.ContainsKey($serial)) { return @{ Ok = $false; Reason = "${label}: this is $($KNOWN_SERIAL[$serial]) ($serial), not $label." } }
            return @{ Ok = $false; Reason = "${label}: version $serial isn't supported yet (supported: $($ACCEPTED[$role] -join ', '))." }
        }
        try { $d = Read-Disc $fs } catch { return @{ Ok = $false; Reason = "${label}: can't read the game's file table ($($_.Exception.Message))." } }
        if ((Sha $d.Header) -ne $HEADER_SHA[$role]) {
            return @{ Ok = $false; Reason = "${label}: this copy's skin table is different from the original disc (already modified?). Use an unmodified $serial iso." }
        }
        return @{ Ok = $true; Reason = "${label}: OK ($serial)"; Serial = $serial }
    } catch {
        return @{ Ok = $false; Reason = "${label}: can't read this file ($($_.Exception.Message))." }
    } finally { if ($fs) { $fs.Close() } }
}

# ---- MIPS helpers for the unlock check ----
function Enc-I([int]$op, [int]$rs, [int]$rt, [int]$imm) { return [uint32](([long]$op -shl 26) -bor ([long]$rs -shl 21) -bor ([long]$rt -shl 16) -bor ([long]$imm -band 0xFFFF)) }
function Enc-R([int]$rs, [int]$rt, [int]$rd, [int]$fn) { return [uint32](([long]$rs -shl 21) -bor ([long]$rt -shl 16) -bor ([long]$rd -shl 11) -bor $fn) }
# New unlock check: slots 14+ unlocked by $mask bit (slot-14), slot $cslot always unlocked, others as the game saves them.
function Build-UnlockFn([int]$mask, [int]$cslot) {
    $V0 = 2; $V1 = 3; $A0 = 4; $T0 = 8; $RA = 31
    return @(
        (Enc-I 0x0b $A0 $V0 14), (Enc-I 0x05 $V0 0 3), (Enc-I 0x0d 0 $V1 $mask), (Enc-I 0x04 0 0 9), (Enc-I 0x09 $A0 $A0 -14),
        (Enc-I 0x09 0 $V0 $cslot), (Enc-I 0x04 $A0 $V0 9), (Enc-I 0x0b $A0 $V0 8), (Enc-I 0x0f 0 $T0 0x14), (Enc-I 0x05 $V0 0 3),
        (Enc-I 0x24 $T0 $V1 0x271e), (Enc-I 0x24 $T0 $V1 0x27a8), (Enc-I 0x09 $A0 $A0 -8), (Enc-R $A0 $V1 $V1 0x07),
        (Enc-R $RA 0 0 0x08), (Enc-I 0x0c $V1 $V0 1), (Enc-R $RA 0 0 0x08), (Enc-I 0x09 0 $V0 1)
    )
}
function Get-LevelData {
    $out = @()
    foreach ($row in $LEVELS) {
        $p = $row.Split('|'); $h = $p[0].Split(',')
        $out += [pscustomobject]@{
            Id = [int]$h[0]; Size = (Hex $h[1]); RegionOfs = (Hex $h[2]); RegionVA = (Hex $h[3]); UnlockOfs = (Hex $h[4])
            Helper = @($p[1].Split(' ') | ForEach-Object { Hex $_ })
            Patches = @($p[2].Split(' ') | ForEach-Object { $q = $_.Split(':'); ,@((Hex $q[0]), (Hex $q[1]), (Hex $q[2])) })
        }
    }
    return $out
}
# The 0x3C0-byte block for one level: new 18-entry skins list, helper, per-skin data list, names.
function Build-Region($lv, [byte[]]$oldList) {
    $r = New-Object byte[] $REGION_LEN
    [Array]::Copy($oldList, 0, $r, 0, $TABLE_OLD * 16)
    for ($i = 0; $i -lt $lv.Helper.Count; $i++) { [Array]::Copy([BitConverter]::GetBytes([uint32]$lv.Helper[$i]), 0, $r, 0x120 + 4 * $i, 4) }
    $pos = 0x1F8; $k = $TABLE_OLD
    foreach ($s in 14..21) {
        $ptrs = @()
        foreach ($txt in $EXTRA_TEXT[$s]) {
            $bytes = [System.Text.Encoding]::ASCII.GetBytes($txt)
            if ($pos + $bytes.Length + 1 -gt $REGION_LEN) { throw 'The extra skin names/descriptions are too long in total (max 456 bytes).' }
            [Array]::Copy($bytes, 0, $r, $pos, $bytes.Length)
            $ptrs += [uint32]($lv.RegionVA + $pos)
            $pos += $bytes.Length + 1
        }
        $e = 16 * $k
        [Array]::Copy([BitConverter]::GetBytes([uint32]$ptrs[0]), 0, $r, $e, 4)
        [Array]::Copy([BitConverter]::GetBytes([uint32]$ptrs[1]), 0, $r, $e + 4, 4)
        [Array]::Copy([BitConverter]::GetBytes([int]255), 0, $r, $e + 8, 4)    # hidden unless unlocked
        [Array]::Copy([BitConverter]::GetBytes([int]$s), 0, $r, $e + 12, 4)
        $k++
    }
    return ,$r
}
function Source-Label([string]$key) { foreach ($s in $SOURCES) { if ($s[0] -eq $key) { return $s[1] } }; return $key }
function Target-Label([int]$slot) { foreach ($t in $TARGETS) { if ($t[0] -eq $slot) { return $t[1] } }; return "NA $slot" }

# Copies a big file in chunks, keeping the window responsive and logging progress.
function Copy-WithProgress([string]$src, [string]$dst) {
    $in = Open-Read $src
    $out = [System.IO.File]::Open($dst, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
    try {
        $buf = New-Object byte[] (8MB); $total = $in.Length; $done = [long]0; $next = 10
        while ($true) {
            $n = $in.Read($buf, 0, $buf.Length)
            if ($n -le 0) { break }
            $out.Write($buf, 0, $n); $done += $n
            if ($script:UiPump) { & $script:UiPump }
            $pct = [int](100 * $done / $total)
            if ($pct -ge $next) { Log ("  copying... {0}%" -f $pct) 'DarkGray'; $next = $pct - ($pct % 10) + 10 }
        }
    } finally { $out.Close(); $in.Close() }
}

# ======================= the patch =======================
# $cfg: NA, JP, GC (paths or ''), Extra (bool), Constructo (bool), Rows (list of @(sourceKey, targetSlot) ; $null = not chosen)
# Returns @{ Ok; Out; Error }
function Invoke-Patch($cfg) {
    $streams = @{}; $paths = @{}
    try {
        foreach ($role in 'NA', 'JP', 'GC') {
            $p = [string]$cfg.$role
            if (-not $p) { continue }
            $t = Test-Disc $p $role
            if (-not $t.Ok) { if ($role -eq 'NA') { throw $t.Reason } else { Log "  $($t.Reason) - skipped" 'Yellow'; continue } }
            $paths[$role] = [System.IO.Path]::GetFullPath($p.Trim().Trim('"').Trim())
            $streams[$role] = Open-Read $paths[$role]
        }
        if (-not $streams.ContainsKey('NA')) { throw 'Select a valid NA UYA iso first.' }
        $discs = @{}
        foreach ($k in $streams.Keys) { $discs[$k] = Read-Disc $streams[$k] }
        $NA = $discs['NA']; $naFs = $streams['NA']

        # --- free space: the identical placeholder skins in NA slots 14-28 (slot 28's copy is kept) ---
        $ph = Slot-Hash $naFs $NA $PH_LAST
        $regionStart = [int]::MaxValue
        for ($i = $PH_FIRST; $i -le $PH_LAST; $i++) {
            $e = $NA.Slots[$i]
            if ((Slot-Hash $naFs $NA $i) -ne $ph -or $e[2] -ne $e[0] + $e[1]) { throw "NA slot $i is not the original placeholder skin. Use an unmodified NA UYA iso." }
            $regionStart = [Math]::Min($regionStart, $e[0])
        }
        $limit = $NA.Slots[$PH_LAST][0]
        $script:alloc = $regionStart
        $writes = New-Object System.Collections.ArrayList     # @(armorSector, bytes)
        $entries = @{}                                        # slot -> @(mo,ms,to,ts)
        $expect = @{}                                         # slot -> hash
        $origHash = @{}
        for ($i = 0; $i -lt $PH_FIRST; $i++) { $origHash[$i] = Slot-Hash $naFs $NA $i }

        # --- extra skins ---
        $added = @()
        if ($cfg.Extra) {
            foreach ($pl in $EXTRA_PLAN) {
                if (-not $discs.ContainsKey($pl[1])) { continue }
                $d = $discs[$pl[1]]; $se = $d.Slots[$pl[2]]
                $data = Read-Slot $streams[$pl[1]] $d $pl[2]
                $mo = $script:alloc; $script:alloc += $se[1]; $to = $script:alloc; $script:alloc += $se[3]
                if ($script:alloc -gt $limit) { throw 'The extra skins do not fit (unexpected).' }
                [void]$writes.Add(@($mo, $data[0])); [void]$writes.Add(@($to, $data[1]))
                $entries[$pl[0]] = @($mo, $se[1], $to, $se[3]); $expect[$pl[0]] = (Sha $data[0]) + (Sha $data[1])
                $added += $pl[0]
                Log ("  extra skin: {0} -> NA slot {1}" -f $EXTRA_TEXT[$pl[0]][0], $pl[0])
            }
        }

        # --- custom over-writes ---
        $n = 0; $used = @{}
        foreach ($row in @($cfg.Rows)) {
            $n++
            $srcKey = [string]$row[0]; $tgt = $row[1]
            if (-not $srcKey -or $null -eq $tgt -or "$tgt" -eq '') { throw "Row ${n}: choose both the skin you want and the skin to over-write (or remove the row)." }
            $tgt = [int]$tgt
            $desc = "Row $n ($(Source-Label $srcKey) -> $(Target-Label $tgt))"
            if ($used.ContainsKey($tgt)) { throw "${desc}: that skin is already over-written by row $($used[$tgt])." }
            $used[$tgt] = $n
            if ($srcKey -eq "NA:$tgt") { Log "  ${desc}: same skin, nothing to change." 'Yellow'; continue }
            $sd = $srcKey.Split(':'); $role = $sd[0]; $ss = [int]$sd[1]
            if (-not $discs.ContainsKey($role)) { throw "${desc}: the $($ROLE_NAME[$role]) disc is not selected or not valid." }
            $d = $discs[$role]; $se = $d.Slots[$ss]
            $data = Read-Slot $streams[$role] $d $ss
            $te = $NA.Slots[$tgt]
            $meshCap = Get-Cap $NA $te[0] $te[1]; $texCap = Get-Cap $NA $te[2] $te[3]
            $need = 0
            if ($se[1] -gt $meshCap) { $need += $se[1] }
            if ($se[3] -gt $texCap)  { $need += $se[3] }
            if ($script:alloc + $need -gt $limit) {
                throw ("{0}: not enough free disc space. This skin needs {1} sectors of free space and only {2} are left. Remove or change a row, or untick ""Add Extra skins""." -f $desc, $need, ($limit - $script:alloc))
            }
            if ($se[1] -le $meshCap) { $mo = $te[0]; [void]$writes.Add(@($mo, (Pad $data[0] $meshCap))) }
            else { $mo = $script:alloc; $script:alloc += $se[1]; [void]$writes.Add(@($mo, $data[0])) }
            if ($se[3] -le $texCap) { $to = $te[2]; [void]$writes.Add(@($to, (Pad $data[1] $texCap))) }
            else { $to = $script:alloc; $script:alloc += $se[3]; [void]$writes.Add(@($to, $data[1])) }
            $entries[$tgt] = @($mo, $se[1], $to, $se[3]); $expect[$tgt] = (Sha $data[0]) + (Sha $data[1])
            Log "  $desc"
        }
        # placeholder slots whose own copy got used now point at slot 28's copy
        $donor = $NA.Slots[$PH_LAST]
        for ($i = $PH_FIRST; $i -lt $PH_LAST; $i++) {
            if ($added -contains $i) { continue }
            if ($NA.Slots[$i][0] -lt $script:alloc) { $entries[$i] = @($donor[0], $donor[1], $donor[2], $donor[3]) }
        }

        # --- skins menu / unlock check ---
        $mask = 0; foreach ($s in $added) { $mask = $mask -bor (1 -shl ($s - 14)) }
        $doMenu = $added.Count -gt 0
        $doUnlock = $doMenu -or [bool]$cfg.Constructo
        $plan = @()
        if ($doUnlock) {
            $cslot = if ($cfg.Constructo) { 10 } else { -1 }
            $fnWords = Build-UnlockFn $mask $cslot
            $fnOrig = @($F2_ORIG.Split(' ') | ForEach-Object { Hex $_ })
            foreach ($lv in (Get-LevelData)) {
                if (-not $NA.Levels.ContainsKey($lv.Id)) { throw "Level $($lv.Id) not found on the NA disc." }
                $L = $NA.Levels[$lv.Id]
                if ($L.Size -ne $lv.Size) { throw "Level $($lv.Id): game code size differs. Use an unmodified NA UYA iso." }
                $cur = Read-At $naFs ($L.Pos + $lv.UnlockOfs) 72
                for ($i = 0; $i -lt 18; $i++) { if ((U32 $cur (4 * $i)) -ne $fnOrig[$i]) { throw "Level $($lv.Id): game code differs from the original. Use an unmodified NA UYA iso." } }
                $region = $null
                if ($doMenu) {
                    foreach ($pt in $lv.Patches) { if ((U32 (Read-At $naFs ($L.Pos + $pt[0]) 4) 0) -ne $pt[1]) { throw "Level $($lv.Id): game code differs from the original. Use an unmodified NA UYA iso." } }
                    $old = Read-At $naFs ($L.Pos + $lv.RegionOfs) $REGION_LEN
                    for ($i = 0; $i -lt 0x320; $i++) { if ($old[$i] -ne 0) { throw "Level $($lv.Id): unexpected data in the skins menu area. Use an unmodified NA UYA iso." } }
                    $list = New-Object byte[] ($TABLE_OLD * 16); [Array]::Copy($old, 0x320, $list, 0, $list.Length)
                    if ((I32 $list 0) -ne 6012 -or (I32 $list 16) -ne 5026 -or (I32 $list 156) -ne 13) { throw "Level $($lv.Id): skins list not found." }
                    $region = Build-Region $lv $list
                }
                $plan += [pscustomobject]@{ Lv = $lv; Pos = $L.Pos; Region = $region }
            }
            Log ("  skins menu: {0} single-player levels checked." -f $plan.Count)
        }

        if ($writes.Count -eq 0 -and -not $doUnlock -and $entries.Count -eq 0) {
            throw 'Nothing to change: tick an option or add a custom over-write row.'
        }

        # --- output ---
        $naPath = $paths['NA']; $tgtLen = $naFs.Length
        foreach ($k in @($streams.Keys)) { $streams[$k].Close() }
        $streams = @{}
        $base = [System.IO.Path]::GetFileNameWithoutExtension($naPath)
        $out = Unique-Path (Join-Path (Split-Path -Parent $naPath) ("{0} [modded].iso" -f $base))
        try {
            $drive = New-Object System.IO.DriveInfo ([System.IO.Path]::GetPathRoot($out))
            if ($drive.AvailableFreeSpace -lt $tgtLen + 50MB) { throw ("Not enough free space on drive {0} (need about {1:N1} GB)." -f $drive.Name, ($tgtLen / 1GB)) }
        } catch [System.ArgumentException] { }
        Log "  copying the NA iso -> $out"
        try { Copy-WithProgress $naPath $out }
        catch { try { Remove-Item -LiteralPath $out -Force } catch { }; throw "Copying the iso failed: $($_.Exception.Message)" }

        $dst = [System.IO.File]::Open($out, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        try {
            foreach ($w in $writes) { Write-At $dst ($NA.WadPos + [long]$w[0] * $SECTOR) $w[1] }
            foreach ($tableBase in @($NA.TocPos, $NA.WadPos)) {
                foreach ($s in $entries.Keys) { $e = $entries[$s]; Write-At $dst ($tableBase + 8 + 16 * $s) (Entry-Bytes $e[0] $e[1] $e[2] $e[3]) }
            }
            $fnBytes = New-Object byte[] 72
            if ($doUnlock) { for ($i = 0; $i -lt 18; $i++) { [Array]::Copy([BitConverter]::GetBytes([uint32]$fnWords[$i]), 0, $fnBytes, 4 * $i, 4) } }
            foreach ($p in $plan) {
                Write-At $dst ($p.Pos + $p.Lv.UnlockOfs) $fnBytes
                if ($p.Region) {
                    Write-At $dst ($p.Pos + $p.Lv.RegionOfs) $p.Region
                    foreach ($pt in $p.Lv.Patches) { Write-At $dst ($p.Pos + $pt[0]) ([BitConverter]::GetBytes([uint32]$pt[2])) }
                }
            }
            $dst.Flush()

            # --- verify ---
            Log '  checking the new iso...'
            $V = Read-Disc $dst
            for ($i = 0; $i -lt $PH_FIRST; $i++) {
                $want = if ($expect.ContainsKey($i)) { $expect[$i] } else { $origHash[$i] }
                if ((Slot-Hash $dst $V $i) -ne $want) { throw "Check failed: NA slot $i does not hold the expected skin." }
            }
            for ($i = $PH_FIRST; $i -le $PH_LAST; $i++) {
                $want = if ($expect.ContainsKey($i)) { $expect[$i] } else { $ph }
                if ((Slot-Hash $dst $V $i) -ne $want) { throw "Check failed: NA slot $i is wrong." }
            }
            $copyHdr = Read-At $dst $V.WadPos $HDR_UYA
            for ($j = 8; $j -lt $HDR_UYA; $j++) { if ($copyHdr[$j] -ne $V.Header[$j]) { throw 'Check failed: the two skin tables differ.' } }
            foreach ($p in $plan) {
                if ((Sha (Read-At $dst ($p.Pos + $p.Lv.UnlockOfs) 72)) -ne (Sha $fnBytes)) { throw "Check failed in level $($p.Lv.Id) (unlock check)." }
                if ($p.Region) {
                    if ((Sha (Read-At $dst ($p.Pos + $p.Lv.RegionOfs) $REGION_LEN)) -ne (Sha $p.Region)) { throw "Check failed in level $($p.Lv.Id) (skins list)." }
                    foreach ($pt in $p.Lv.Patches) { if ((U32 (Read-At $dst ($p.Pos + $pt[0]) 4) 0) -ne $pt[2]) { throw "Check failed in level $($p.Lv.Id) (game code)." } }
                }
            }
        } catch {
            $dst.Close(); $dst = $null
            try { Remove-Item -LiteralPath $out -Force } catch { }
            throw
        } finally { if ($dst) { $dst.Close() } }
        return @{ Ok = $true; Out = $out }
    } catch {
        return @{ Ok = $false; Error = $_.Exception.Message }
    } finally {
        foreach ($k in @($streams.Keys)) { try { $streams[$k].Close() } catch { } }
    }
}

# ======================= developer test mode (no window) =======================
if ($Headless) {
    $c = Get-Content -Raw -LiteralPath $Headless | ConvertFrom-Json
    $rows = @(); foreach ($r in @($c.Rows)) { $rows += ,@($r[0], $r[1]) }
    $res = Invoke-Patch @{ NA = $c.NA; JP = $c.JP; GC = $c.GC; Extra = [bool]$c.Extra; Constructo = [bool]$c.Constructo; Rows = $rows }
    if ($res.Ok) { Log "successful: $($res.Out)" 'Green'; exit 0 } else { Log "failed: $($res.Error)" 'Red'; exit 1 }
}

# ======================= the window =======================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$script:UiPump = { [System.Windows.Forms.Application]::DoEvents() }

$C_BG     = [System.Drawing.Color]::FromArgb(32, 32, 36)
$C_CTRL   = [System.Drawing.Color]::FromArgb(52, 52, 58)
$C_BORDER = [System.Drawing.Color]::FromArgb(85, 85, 92)
$C_TEXT   = [System.Drawing.Color]::FromArgb(235, 235, 235)
$C_DIM    = [System.Drawing.Color]::FromArgb(125, 125, 130)
$C_RED    = [System.Drawing.Color]::FromArgb(240, 85, 85)
$C_GREEN  = [System.Drawing.Color]::FromArgb(95, 210, 115)
$C_YELLOW = [System.Drawing.Color]::FromArgb(240, 200, 60)
$C_BLUE   = [System.Drawing.Color]::FromArgb(40, 120, 215)
$C_REMOVE = [System.Drawing.Color]::FromArgb(78, 78, 84)
$F_TEXT   = New-Object System.Drawing.Font('Segoe UI', 10)
$F_SMALL  = New-Object System.Drawing.Font('Segoe UI', 9)
$F_TITLE  = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
$F_BIG    = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
$F_MARK   = New-Object System.Drawing.Font('Segoe UI Symbol', 14, [System.Drawing.FontStyle]::Bold)
$F_PLUS   = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Bold)
$CHECK = [string][char]0x2714; $CROSS = [string][char]0x2716

$UIW = 900                  # content width
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Skin Swapper'
$form.BackColor = $C_BG; $form.ForeColor = $C_TEXT; $form.Font = $F_TEXT
$form.StartPosition = 'CenterScreen'
$form.ClientSize = New-Object System.Drawing.Size(($UIW + 20), 820)
$form.MinimumSize = New-Object System.Drawing.Size(($UIW + 40), 400)
$panel = New-Object System.Windows.Forms.Panel
$panel.Dock = 'Fill'; $panel.AutoScroll = $true; $panel.BackColor = $C_BG
$form.Controls.Add($panel)

function New-Label([string]$text, $font = $F_TEXT, $color = $C_TEXT) {
    $lbl0 = New-Object System.Windows.Forms.Label
    $lbl0.Text = $text; $lbl0.Font = $font; $lbl0.ForeColor = $color; $lbl0.BackColor = $C_BG; $lbl0.AutoSize = $true
    $panel.Controls.Add($lbl0); return $lbl0
}
function New-Button([string]$text, $back = $C_CTRL, $font = $F_TEXT) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text; $b.Font = $font; $b.FlatStyle = 'Flat'; $b.BackColor = $back; $b.ForeColor = $C_TEXT
    $b.FlatAppearance.BorderColor = $C_BORDER; $b.UseVisualStyleBackColor = $false
    $panel.Controls.Add($b); return $b
}
function Place($ctrl, [int]$x, [int]$y) { $ctrl.Location = New-Object System.Drawing.Point($x, ($y + $panel.AutoScrollPosition.Y)) }
function Center-X($ctrl) {
    $cw = if ($ctrl -is [System.Windows.Forms.Label]) { $ctrl.PreferredWidth } else { $ctrl.Width }
    return [int](($UIW - $cw) / 2)
}

# ---- top: discs ----
$lblMust = New-Label 'You must have at least NA UYA before you start'
$script:disc = @{}
foreach ($role in 'NA', 'JP', 'GC') {
    $cap = switch ($role) { 'NA' { 'NA UYA  (required)' } 'JP' { 'JP UYA  (optional)' } 'GC' { 'NA GC   (optional)' } }
    $lbl = New-Label $cap
    $btn = New-Button 'Browse'; $btn.Size = New-Object System.Drawing.Size(80, 28); $btn.Tag = $role
    $tb = New-Object System.Windows.Forms.TextBox
    $tb.BackColor = $C_CTRL; $tb.ForeColor = $C_TEXT; $tb.BorderStyle = 'FixedSingle'; $tb.Font = $F_TEXT
    $tb.Size = New-Object System.Drawing.Size(560, 28); $tb.Tag = $role
    $panel.Controls.Add($tb)
    $mark = New-Label '' $F_MARK $C_GREEN
    $script:disc[$role] = @{ Label = $lbl; Browse = $btn; Box = $tb; Mark = $mark; Ok = $false; Checked = '' }
}

# ---- options ----
$lblExtraWarn = New-Label 'Only available if you Have GC or JP UYA' $F_SMALL $C_RED
function New-Check([string]$text) {
    $c = New-Object System.Windows.Forms.CheckBox
    $c.Text = $text; $c.Font = $F_TEXT; $c.ForeColor = $C_TEXT; $c.BackColor = $C_BG; $c.AutoSize = $true
    $c.FlatStyle = 'Flat'; $c.FlatAppearance.BorderColor = $C_BORDER; $c.FlatAppearance.CheckedBackColor = $C_CTRL
    $panel.Controls.Add($c); return $c
}
$chkExtra = New-Check 'Add Extra skins'
$lblExtraDesc = New-Label '(Adds extra skins from other games in the skins menu without over-writing any in-game skins)' $F_SMALL
$chkCons = New-Check 'Unlock Constructobot'
$lblConsDesc = New-Label '(Unlocks the skin without needing to collect all Trophies for the Starship Phoenix trophy room)' $F_SMALL
$script:extraWanted = $true
$script:setting = $false

# ---- custom over-write ----
$lblCowTitle = New-Label 'custom over-write' $F_TITLE
$lblCowText = New-Label 'Here you can choose which skin you want to have and which skin you want to over-write'
$lblCowHead = New-Label '[Skin you want]   ------>   [Skin you want to Over-write]'
$lblAdd = New-Label 'Add custom over-write'
$btnPlus = New-Button '+' $C_BLUE $F_PLUS
$btnPlus.Size = New-Object System.Drawing.Size(44, 44); $btnPlus.FlatAppearance.BorderSize = 0
$gp = New-Object System.Drawing.Drawing2D.GraphicsPath; $gp.AddEllipse(0, 0, 44, 44)
$btnPlus.Region = New-Object System.Drawing.Region($gp)
$script:rows = New-Object System.Collections.ArrayList

# ---- bottom ----
$btnPatch = New-Button 'Patch Rom' $C_CTRL $F_BIG
$btnPatch.Size = New-Object System.Drawing.Size(240, 52)
$lnkResult = New-Object System.Windows.Forms.LinkLabel
$lnkResult.Font = $F_SMALL; $lnkResult.BackColor = $C_BG; $lnkResult.AutoSize = $false; $lnkResult.TextAlign = 'TopCenter'
$lnkResult.LinkColor = $C_GREEN; $lnkResult.ActiveLinkColor = $C_GREEN; $lnkResult.VisitedLinkColor = $C_GREEN
$lnkResult.Visible = $false
$panel.Controls.Add($lnkResult)
$lblFail = New-Label '' $F_SMALL $C_RED
$lblFail.AutoSize = $false; $lblFail.TextAlign = 'TopCenter'; $lblFail.Visible = $false
$script:resultPath = $null
$script:warnOn = $true; $script:okOn = $false; $script:failOn = $false

# ======================= layout =======================
function Relayout {
    $panel.SuspendLayout()
    $y = 16
    Place $lblMust 20 $y; $y += 34
    foreach ($role in 'NA', 'JP', 'GC') {
        $d = $script:disc[$role]
        Place $d.Label 20 ($y + 4); Place $d.Browse 170 $y; Place $d.Box 258 ($y + 1); Place $d.Mark 826 ($y - 2)
        $y += 38
    }
    $y += 10
    if ($script:warnOn) { Place $lblExtraWarn 40 $y; $y += 20 }
    Place $chkExtra 20 $y; $y += 26
    Place $lblExtraDesc 40 $y; $y += 32
    Place $chkCons 20 $y; $y += 26
    Place $lblConsDesc 40 $y; $y += 46
    Place $lblCowTitle 20 $y; $y += 34
    Place $lblCowText 20 $y; $y += 38
    Place $lblCowHead (Center-X $lblCowHead) $y; $y += 38
    $boxW = 240; $gap = 40
    foreach ($r in $script:rows) {
        if ($r.NoteOn) { Place $r.Note (Center-X $r.Note) $y; $y += 22 }
        Place $r.Src ([int]($UIW / 2 - $gap - $boxW)) $y
        Place $r.Arrow (Center-X $r.Arrow) ($y + 3)
        Place $r.Tgt ([int]($UIW / 2 + $gap)) $y
        Place $r.Remove ([int]($UIW / 2 + $gap + $boxW + 12)) $y
        $y += 40
    }
    $y += 10
    Place $lblAdd (Center-X $lblAdd) $y; $y += 26
    Place $btnPlus (Center-X $btnPlus) $y; $y += 70
    Place $btnPatch (Center-X $btnPatch) $y; $y += 68
    foreach ($lab in @($lnkResult, $lblFail)) {
        if (($lab -eq $lnkResult -and $script:okOn) -or ($lab -eq $lblFail -and $script:failOn)) {
            $sz = [System.Windows.Forms.TextRenderer]::MeasureText($lab.Text, $lab.Font, (New-Object System.Drawing.Size(($UIW - 40), 2000)), [System.Windows.Forms.TextFormatFlags]::WordBreak)
            $lab.Size = New-Object System.Drawing.Size(($UIW - 40), ($sz.Height + 6))
            Place $lab 20 $y; $y += $lab.Height + 8
        }
    }
    $spacer = $script:spacer
    Place $spacer 0 ($y + 10)
    $panel.ResumeLayout()
}
$script:spacer = New-Label ' '

# ======================= state =======================
function Source-Items {
    $items = @()
    foreach ($s in $SOURCES) {
        $role = $s[0].Split(':')[0]
        if ($script:disc[$role].Ok) { $items += $s[1] }
    }
    return $items
}
function Key-Of-Source([string]$label) { foreach ($s in $SOURCES) { if ($s[1] -eq $label) { return $s[0] } }; return $null }
function Slot-Of-Target([string]$label) { foreach ($t in $TARGETS) { if ($t[1] -eq $label) { return $t[0] } }; return $null }

function Refresh-Rows {
    $script:setting = $true
    try {
        $srcItems = Source-Items
        foreach ($r in $script:rows) {
            $cur = [string]$r.Src.SelectedItem
            $r.Src.Items.Clear(); foreach ($i in $srcItems) { [void]$r.Src.Items.Add($i) }
            if ($cur -and $srcItems -contains $cur) { $r.Src.SelectedItem = $cur }
        }
        foreach ($r in $script:rows) {
            $taken = @()
            foreach ($o in $script:rows) { if ($o -ne $r -and $o.Tgt.SelectedItem) { $taken += [string]$o.Tgt.SelectedItem } }
            $cur = [string]$r.Tgt.SelectedItem
            $r.Tgt.Items.Clear()
            foreach ($t in $TARGETS) { if ($taken -notcontains $t[1]) { [void]$r.Tgt.Items.Add($t[1]) } }
            if ($cur) { $r.Tgt.SelectedItem = $cur }
        }
        foreach ($r in $script:rows) {
            $sk = Key-Of-Source ([string]$r.Src.SelectedItem); $ts = Slot-Of-Target ([string]$r.Tgt.SelectedItem)
            $r.NoteOn = [bool]($sk -and $null -ne $ts -and $sk -eq "NA:$ts")
            $r.Note.Visible = $r.NoteOn
        }
    } finally { $script:setting = $false }
    Relayout
}

function Update-State {
    $naOk = $script:disc['NA'].Ok
    $extraOk = $naOk -and ($script:disc['JP'].Ok -or $script:disc['GC'].Ok)
    $script:setting = $true
    try {
        $script:warnOn = -not $extraOk
        $lblExtraWarn.Visible = $script:warnOn
        if ($extraOk) { $chkExtra.Enabled = $true; $chkExtra.Checked = $script:extraWanted }
        else { $chkExtra.Checked = $true; $chkExtra.Enabled = $false }
    } finally { $script:setting = $false }
    $chkCons.Enabled = $naOk
    foreach ($c in @($lblExtraDesc, $lblConsDesc, $lblCowTitle, $lblCowText, $lblCowHead, $lblAdd)) { $c.ForeColor = if ($naOk) { $C_TEXT } else { $C_DIM } }
    $lblExtraDesc.ForeColor = if ($extraOk) { $C_TEXT } else { $C_DIM }
    $btnPlus.Enabled = $naOk; $btnPlus.BackColor = if ($naOk) { $C_BLUE } else { $C_REMOVE }
    $btnPatch.Enabled = $naOk
    foreach ($r in $script:rows) { $r.Src.Enabled = $naOk; $r.Tgt.Enabled = $naOk; $r.Remove.Enabled = $naOk }
    Refresh-Rows
}

function Check-Disc([string]$role) {
    $d = $script:disc[$role]
    $path = $d.Box.Text
    if ($path -eq $d.Checked) { return }
    $d.Checked = $path
    $t = Test-Disc $path $role
    $d.Ok = [bool]$t.Ok
    if ($t.Empty) { $d.Mark.Text = '' }
    elseif ($t.Ok) { $d.Mark.Text = $CHECK; $d.Mark.ForeColor = $C_GREEN; Log $t.Reason 'Green' }
    else { $d.Mark.Text = $CROSS; $d.Mark.ForeColor = $C_RED; Log $t.Reason 'Red' }
    Update-State
}

# debounce typing in the path boxes
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 600
$timer.Add_Tick({ $timer.Stop(); foreach ($role in 'NA', 'JP', 'GC') { Check-Disc $role } })
foreach ($role in 'NA', 'JP', 'GC') {
    $d = $script:disc[$role]
    $d.Box.Add_TextChanged({ $timer.Stop(); $timer.Start() })
    $d.Browse.Add_Click({
        param($sender, $e)
        $r = [string]$sender.Tag
        $dlg = New-Object System.Windows.Forms.OpenFileDialog
        $dlg.Filter = 'PS2 disc image (*.iso)|*.iso|All files (*.*)|*.*'
        $dlg.Title = "Select the $($ROLE_NAME[$r]) iso"
        $cur = $script:disc[$r].Box.Text.Trim().Trim('"')
        try { if ($cur) { $dir = Split-Path -Parent $cur; if ($dir -and (Test-Path -LiteralPath $dir)) { $dlg.InitialDirectory = $dir } } } catch { }
        if ($dlg.ShowDialog($form) -eq 'OK') { $script:disc[$r].Box.Text = $dlg.FileName; $timer.Stop(); Check-Disc $r }
    })
}
$chkExtra.Add_CheckedChanged({ if (-not $script:setting -and $chkExtra.Enabled) { $script:extraWanted = $chkExtra.Checked } })

function Style-Combo($cb) {
    $cb.DropDownStyle = 'DropDownList'; $cb.FlatStyle = 'Flat'; $cb.BackColor = $C_CTRL; $cb.ForeColor = $C_TEXT
    $cb.Font = $F_SMALL; $cb.Size = New-Object System.Drawing.Size(240, 28); $cb.DropDownWidth = 260; $cb.MaxDropDownItems = 20
}
function Add-Row {
    $note = New-Label 'Over-writing a skin with itself gives no results.' $F_SMALL $C_YELLOW
    $note.Visible = $false
    $src = New-Object System.Windows.Forms.ComboBox; Style-Combo $src; $panel.Controls.Add($src)
    $arrow = New-Label '------>'
    $tgt = New-Object System.Windows.Forms.ComboBox; Style-Combo $tgt; $panel.Controls.Add($tgt)
    $rem = New-Button 'Remove' $C_REMOVE $F_SMALL; $rem.Size = New-Object System.Drawing.Size(80, 28)
    $row = [pscustomobject]@{ Note = $note; NoteOn = $false; Src = $src; Arrow = $arrow; Tgt = $tgt; Remove = $rem }
    $rem.Tag = $row
    $src.Add_SelectedIndexChanged({ if (-not $script:setting) { Refresh-Rows } })
    $tgt.Add_SelectedIndexChanged({ if (-not $script:setting) { Refresh-Rows } })
    $rem.Add_Click({
        param($sender, $e)
        $r = $sender.Tag
        foreach ($c in @($r.Note, $r.Src, $r.Arrow, $r.Tgt, $r.Remove)) { $panel.Controls.Remove($c); $c.Dispose() }
        [void]$script:rows.Remove($r)
        Refresh-Rows
    })
    [void]$script:rows.Add($row)
    Update-State
}
$btnPlus.Add_Click({ Add-Row })

function Show-Result([bool]$ok, [string]$text) {
    $script:okOn = $ok; $script:failOn = -not $ok
    if ($ok) { $lnkResult.Text = $text } else { $lblFail.Text = $text }
    $lnkResult.Visible = $script:okOn; $lblFail.Visible = $script:failOn
    Relayout
}
$lnkResult.Add_LinkClicked({ if ($script:resultPath) { Start-Process explorer.exe "/select,`"$($script:resultPath)`"" } })

$btnPatch.Add_Click({
    foreach ($role in 'NA', 'JP', 'GC') { $script:disc[$role].Checked = $null; Check-Disc $role }
    if (-not $script:disc['NA'].Ok) { return }
    $script:okOn = $false; $script:failOn = $false
    $lnkResult.Visible = $false; $lblFail.Visible = $false; Relayout
    $rows = @()
    foreach ($r in $script:rows) { $rows += ,@((Key-Of-Source ([string]$r.Src.SelectedItem)), (Slot-Of-Target ([string]$r.Tgt.SelectedItem))) }
    $cfg = @{
        NA = $script:disc['NA'].Box.Text
        JP = if ($script:disc['JP'].Ok) { $script:disc['JP'].Box.Text } else { '' }
        GC = if ($script:disc['GC'].Ok) { $script:disc['GC'].Box.Text } else { '' }
        Extra = ($chkExtra.Enabled -and $chkExtra.Checked); Constructo = $chkCons.Checked; Rows = $rows
    }
    Log ''
    Log '=== Patching ===' 'Cyan'
    Log ("  Add Extra skins: {0}   Unlock Constructobot: {1}   custom over-writes: {2}" -f $cfg.Extra, $cfg.Constructo, $rows.Count)
    $panel.Enabled = $false; $form.Cursor = 'WaitCursor'; $script:busy = $true
    try { $res = Invoke-Patch $cfg }
    finally { $panel.Enabled = $true; $form.Cursor = 'Default'; $script:busy = $false }
    if ($res.Ok) {
        $script:resultPath = $res.Out
        Log "successful: $($res.Out)" 'Green'
        Show-Result $true "successful: $($res.Out)"
    } else {
        Log "failed: $($res.Error)" 'Red'
        Show-Result $false "failed: $($res.Error)"
    }
})

$script:busy = $false
$form.Add_FormClosing({ param($sender, $e) if ($script:busy) { $e.Cancel = $true; Log 'Please wait until patching has finished.' 'Yellow' } })

# ======================= start =======================
Log 'Skin Swapper - log window' 'Cyan'
Log 'Select your iso files in the Skin Swapper window. Everything that happens is shown here.'
Log ''
Update-State
[void]$form.ShowDialog()
Log ''
Log 'Window closed.'
