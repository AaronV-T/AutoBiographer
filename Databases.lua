AutoBiographer_Databases = {}
function AutoBiographer_Databases.Initialiaze()
  AutoBiographer_Databases.BattlegroundDatabase = {
    [1] = "Alterac Valley",
    [2] = "Warsong Gulch",
    [3] = "Arathi Basin",
  }

  AutoBiographer_Databases.BossDatabase = {
    -- Blackfathom Deeps
    [4887] = "Ghamoo-ra",
    [4831] = "Lady Sarevess",
    [6243] = "Gelihast",
    [12902] = "Lorgus Jett",
    [12876] = "Baron Aquanis",
    [4832] = "Twilight Lord Kelris",
    [4830] = "Old Serra'kis",
    [4829] = "Aku'mai",
    
    -- Blackrock Depths
    [9025] = "Lord Roccor",
    [9016] = "Bael'Gar",
    [9319] = "Houndmaster Grebmar",
    [9018] = "High Interrogator Gerstahn",
    [9027] = "Gorosh the Dervish",
    [9028] = "Grizzle",
    [9029] = "Eviscerator",
    [9030] = "Ok'thor the Breaker",
    [9031] = "Anub'shiah",
    [9032] = "Hedrum the Creeper",
    [9024] = "Pyromancer Loregrain",
    [9033] = "General Angerforge",
    [8983] = "Golem Lord Argelmach",
    [9543] = "Ribbly Screwspigot",
    [9537] = "Hurley Blackbreath",
    [9499] = "Plugger Spazzring",
    [9502] = "Phalanx",
    [9017] = "Lord Incendius",
    [9056] = "Fineous Darkvire",
    [9041] = "Warder Stilgiss",
    [9042] = "Verek",
    [9156] = "Ambassador Flamelash",
    [9938] = "Magmus",
    [8929] = "Princess Moira Bronzebeard",
    [9019] = "Emperor Dagran Thaurissan",
    
    -- Blackrock Spire
    -- Lower
    [9196] = "Highlord Omokk",
    [9236] = "Shadow Hunter Vosh'gajin",
    [9237] = "War Master Voone",
    [10596] = "Mother Smolderweb",
    [10584] = "Urok Doomhowl",
    [9736] = "Quartermaster Zigris",
    [10268] = "Gizrul the Slavener",
    [10220] = "Halycon",
    [9568] = "Overlord Wyrmthalak",
    -- Upper
    [9816] = "Pyroguard Emberseer",
    [10264] = "Solakar Flamewreath",
    [10509] = "Jed Runewatcher",
    [10899] = "Goraluk Anvilcrack",
    [10429] = "Warchief Rend Blackhand",
    [10339] = "Gyth",
    [10430] = "The Beast",
    [10363] = "General Drakkisath",
    
    -- Blackwing Lair
    [12435] = "Razorgore the Untamed",
    [13020] = "Vaelastrasz the Corrupt",
    [12017] = "Broodlord Lashlayer",
    [11983] = "Firemaw",
    [14601] = "Ebonroc",
    [11981] = "Flamegor",
    [14020] = "Chromaggus",
    [11583] = "Nefarian",
  
    -- The Deadmines
    [644] = "Rhahk'Zor",
    [3586] = "Miner Johnson",
    [643] = "Sneed",
    [1763] = "Gilnid",
    [646] = "Mr. Smite",
    [647] = "Captain Greenskin",
    [639] = "Edwin VanCleef",
    [645] = "Cookie",
    
    -- Dire Maul
    -- East
    [11490] = "Zevrim Thornhoof",
    [13280] = "Hydrospawn",
    [14327] = "Lethtendris",
    [11492] = "Alzzin the Wildshaper",
    -- North
    [14326] = "Guard Mol'dar",
    [14322] = "Stomper Kreeg",
    [14321] = "Guard Fengus",
    [14323] = "Guard Slip'kik",
    [14325] = "Captain Kromcrush",
    [11501] = "King Gordok",
    [14324] = "Cho'Rush the Observer",
    --West
    [11489] = "Tendris Warpwood",
    [11488] = "Illyanna Ravenoak",
    [11487] = "Magister Kalendris",
    [11496] = "Immol'thar",
    [11486] = "Prince Tortheldrin",
    
    -- Gnomeregan
    [7361] = "Grubbis",
    [7079] = "Viscous Fallout",
    [6235] = "Electrocutioner 6000",
    [6229] = "Crowd Pummeler 9-60",
    [6228] = "Dark Iron Ambassador",
    [7800] = "Mekgineer Thermaplugg",
    
    -- Maraudon
    -- Orange
    [13282] = "Noxxion",
    [12258] = "Razorlash",
    -- Purple
    [12236] = "Lord Vyletongue",
    -- Poison Falls
    [12237] = "Meshlok the Harvester",
    [12225] = "Celebras the Cursed",
    -- Inner
    [12203] = "Landslide",
    [13601] = "Tinkerer Gizlock",
    [13596] = "Rotgrip",
    [12201] = "Princess Theradras",
    
    -- Molten Core 
    [12118] = "Lucifron",
    [11982] = "Magmadar",
    [12259] = "Gehennas",
    [12057] = "Garr",
    [12264] = "Shazzrah",
    [12056] = "Baron Geddon",
    [11988] = "Golemagg the Incinerator",
    [12098] = "Sulfuron Harbinger",
    [12018] = "Majordomo Executus",
    [11502] = "Ragnaros",
    
    -- Naxxramas
    -- The Arachnid Quarter
    [15956] = "Anub'Rekhan",
    [15953] = "Grand Widow Faerlina",
    [15952] = "Maexxna",
    -- The Plague Quarter
    [15954] = "Noth the Plaguebringer",
    [15936] = "Heigan the Unclean",
    [16011] = "Loatheb",
    -- The Military Quarter
    [16061] = "Instructor Razuvious",
    [16060] = "Gothik the Harvester",
    -- The Construct Quarter
    [16028] = "Patchwerk",
    [15931] = "Grobbulus",
    [15932] = "Gluth",
    [15928] = "Thaddius",
    -- Frostwyrm Lair
    [15989] = "Sapphiron",
    [15990] = "Kel'Thuzad",
    
    -- Onyxia's Lair
    [10184] = "Onyxia",
    
    -- Ragefire Chasm
    [11520] = "Taragaman the Hungerer",
    [11517] = "Oggleflint",
    [11518] = "Jergosh the Invoker",
    [11519] = "Bazzalan",
    
    -- Razorfen Downs
    [7355] = "Tuten'kash",
    [7356] = "Plaguemaw the Rotting",
    [7357] = "Mordresh Fire Eye",
    [7354] = "Ragglesnout",
    [8567] = "Glutton",
    [7358] = "Amnennar the Coldbringer",
    
    -- Razorfen Kraul
    [6168] = "Roogug",
    [4424] = "Aggem Thorncurse",
    [4428] = "Death Speaker Jargba",
    [4420] = "Overlord Ramtusk",
    [4425] = "Blind Hunter",
    [4422] = "Agathelos the Raging",
    [4421] = "Charlga Razorflank",
    
    -- Ruins of Ahn'Qiraj
    [15348] = "Kurinnaxx",
    [15341] = "General Rajaxx",
    [15340] = "Moam",
    [15370] = "Buru the Gorger",
    [15369] = "Ayamiss the Hunter",
    [15339] = "Ossirian the Unscarred",
    
    -- Scarlet Monastery
    -- Graveyard
    [3983] = "Interrogator Vishas",
    [4543] = "Bloodmage Thalnos",
    [6490] = "Azshir the Sleepless",
    [6488] = "Fallen Champion",
    [6489] = "Ironspine",
    -- Library
    [3974] = "Houndmaster Loksey",
    [6487] = "Arcanist Doan",
    -- Armory
    [3975] = "Herod",
    --Cathedral
    [3976] = "Scarlet Commander Mograine",
    [3977] = "High Inquisitor Whitemane",
    [4542] = "High Inquisitor Fairbanks",
    
    -- Scholomance
    [10506] = "Kirtonos the Herald",
    [10503] = "Jandice Barov",
    [11622] = "Rattlegore",
    [10433] = "Marduk Blackpool",
    [10432] = "Vectus",
    [10508] = "Ras Frostwhisper",
    [10505] = "Instructor Malicia",
    [11261] = "Doctor Theolen Krastinov",
    [10901] = "Lorekeeper Polkelt",
    [10507] = "The Ravenian",
    [10504] = "Lord Alexei Barov",
    [10502] = "Lady Illucia Barov",
    [1853] = "Darkmaster Gandling",
    
    -- Shadowfang Keep
    [3914] = "Rethilgore",
    [3886] = "Razorclaw the Butcher",
    [3887] = "Baron Silverlaine",
    [4278] = "Commander Springvale",
    [4279] = "Odo the Blindwatcher",
    [3872] = "Deathsworn Captain",
    [4274] = "Fenrus the Devourer",
    [3927] = "Wolf Master Nandos",
    [4275] = "Archmage Arugal",
    
    -- The Stockade
    [1696] = "Targorr the Dread",
    [1666] = "Kam Deepfury",
    [1717] = "Hamhock",
    [1663] = "Dextren Ward",
    [1716] = "Bazil Thredd",
    [1720] = "Bruegal Ironknuckle",
    
    -- Stratholme
    -- Main Gate (Live)
    [11058] = "Fras Siabi",
    [10393] = "Skul",
    [10558] = "Hearthsinger Forresten",
    [10516] = "The Unforgiven",
    [11143] = "Postmaster Malown",
    [10808] = "Timmy the Cruel",
    [11032] = "Malor the Zealous",
    [10997] = "Cannon Master Willey",
    [11120] = "Crimson Hammersmith",
    [10811] = "Archivist Galford",
    [10813] = "Balnazzar",
    -- Service Gate (Dead)
    [10435] = "Magistrate Barthilas",
    [10809] = "Stonespine",
    [10437] = "Nerub'enkan",
    [11121] = "Black Guard Swordsmith",
    [10438] = "Maleki the Pallid",
    [10436] = "Baroness Anastari",
    [10439] = "Ramstein the Gorger",
    [10440] = "Baron Rivendare",
    
    -- Temple of Ahn'Qiraj
    [15263] = "The Prophet Skeram",
    [15516] = "Battleguard Sartura",
    [15510] = "Fankriss the Unyielding",
    [15509] = "Princess Huhuran",
    [15276] = "Emperor Vek'lor",
    [15275] = "Emperor Vek'nilash",
    [15727] = "C'Thun",
    [15543] = "Princess Yauj",
    [15544] = "Vem",
    [15511] = "Lord Kri",
    [15299] = "Viscidus",
    [15517] = "Ouro",
    
    -- The Temple of Atal'Hakkar
    [5713] = "Gasher",
    [5715] = "Hukku",
    [5714] = "Loro",
    [5717] = "Mijan",
    [5712] = "Zolo",
    [5716] = "Zul'Lor",
    [8580] = "Atal'alarion",
    [5721] = "Dreamscythe",
    [5720] = "Weaver",
    [5710] = "Jammal'an the Prophet",
    [5711] = "Ogom the Wretched",
    [5719] = "Morphaz",
    [5722] = "Hazzas",
    [8443] = "Avatar of Hakkar",
    [5709] = "Shade of Eranikus",
    
    -- Uldaman
    [6910] = "Revelosh",
    [6906] = "Baelog",
    [7228] = "Ironaya",
    [7023] = "Obsidian Sentinel",
    [7206] = "Ancient Stone Keeper",
    [7291] = "Galgann Firehammer",
    [4854] = "Grimlok",
    [2748] = "Archaedas",
    
    -- Wailing Caverns
    [3653] = "Kresh",
    [3671] = "Lady Anacondra",
    [3669] = "Lord Cobrahn",
    [5912] = "Deviate Faerie Dragon",
    [3670] = "Lord Pythas",
    [3674] = "Skum",
    [3673] = "Lord Serpentis",
    [5775] = "Verdan the Everliving",
    [3654] = "Mutanus the Devourer",
  
    -- Zul'Farrak
    [8127] = "Antu'sul",
    [7272] = "Theka the Martyr",
    [7271] = "Witch Doctor Zum'rah",
    [7796] = "Nekrum Gutchewer",
    [7275] = "Shadowpriest Sezz'ziz",
    [7604] = "Sergeant Bly",
    [7795] = "Hydromancer Velratha",
    [10081] = "Dustwraith",
    [7267] = "Chief Ukorz Sandscalp",
    [7797] = "Ruuzlu",
    [10082] = "Zerillis",
    [10080] = "Sandarr Dunereaver",
  
    -- Zul'Gurub
    [14507] = "High Priest Venoxis",
    [14517] = "High Priestess Jeklik",
    [14510] = "High Priestess Mar'li",
    [14509] = "High Priest Thekal",
    [14515] = "High Priestess Arlokk",
    [14834] = "Hakkar",
    [11382] = "Bloodlord Mandokir",
    [14988] = "Ohgan",
    [15083] = "Hazza'rah",
    [15114] = "Gahz'ranka",
    [11380] = "Jin'do the Hexxer",
  }

  AutoBiographer_Databases.InstanceLocationDatabase = {
    [36] = Coordinates.New(0, 1415, 40.69, 79.58),
  }
end

