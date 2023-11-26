AutoBiographer_Databases = {}
function AutoBiographer_Databases.Initialiaze()
  AutoBiographer_Databases.ArenaDatabase = {
    [1] = "Blade's Edge Arena",
    [2] = "Nagrand Arena",
    [3] = "Ruins of Lordaeron",
  }

  AutoBiographer_Databases.BattlegroundDatabase = {
    [1] = "Alterac Valley",
    [2] = "Warsong Gulch",
    [3] = "Arathi Basin",
    [4] = "Eye of the Storm",
  }

  AutoBiographer_Databases.BossDatabase = {
    --
    -- Vanilla Bosses
    --

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

    --
    -- TBC Bosses
    --

    -- Auchindoun
    -- Mana-Tombs
    [18341] = "Pandemonius",
    [18343] = "Tavarok",
    [18344] = "Nexus-Prince Shaffar",
    [22930] = "Yor <Void Hound of Shaffar>",
    -- Auchenai Crypts
    [18371] = "Shirrak the Dead Watcher",
    [18373] = "Exarch Maladaar",
    -- Sethekk Halls
    [18472] = "Darkweaver Syth",
    [18473] = "Talon King Ikiss",
    [23035] = "Anzu",
    -- Shadow Labyrinth
    [18731] = "Ambassador Hellmaw",
    [18667] = "Blackheart the Inciter",
    [18732] = "Grandmaster Vorpil",
    [18708] = "Murmur",

    -- Black Temple
    [22887] = "High Warlord Naj'entus",
    [22898] = "Supremus",
    [22841] = "Shade of Akama",
    [22871] = "Teron Gorefiend",
    [22948] = "Gurtogg Bloodboil",
    [22856] = "Reliquary of the Lost",
    [22947] = "Mother Shahraz",
    [23426] = "The Illidari Council",
    [22917] = "Illidan Stormrage <The Betrayer>",

    -- Caverns of Time
    -- Old Hillsbrad Foothills
    [17848] = "Lieutenant Drake",
    [17862] = "Captain Skarloc",
    [18096] = "Epoch Hunter",
    -- The Black Morass
    [17879] = "Chrono Lord Deja",
    [17880] = "Temporus",
    [17881] = "Aeonus",
    -- Hyjal Summit
    [17767] = "Rage Winterchill",
    [17808] = "Anetheron",
    [17888] = "Kaz'rogal",
    [17842] = "Azgalor",
    [17968] = "Archimonde",

    -- Coilfang Reservoir
    -- The Slave Pens
    [17941] = "Mennu the Betrayer",
    [17991] = "Rokmar the Crackler",
    [17942] = "Quagmirran",
    -- The Underbog
    [17770] = "Hungarfen",
    [18105] = "Ghaz'an",
    [17826] = "Swamplord Musel'ek",
    [17882] = "The Black Stalker",
    -- The Steamvault
    [17797] = "Hydromancer Thespia",
    [17796] = "Mekgineer Steamrigger",
    [17798] = "Warlord Kalithresh",
    -- Serpentshrine Cavern
    [21216] = "Hydross the Unstable <Duke of Currents>",
    [21217] = "The Lurker Below",
    [21215] = "Leotheras the Blind",
    [21214] = "Fathom-Lord Karathress",
    [21213] = "Morogrim Tidewalker",
    [21212] = "Lady Vashj <Coilfang Matron>",

    -- Gruul's Lair
    [18831] = "High King Maulgar <Lord of the Ogres>",
    [19044] = "Gruul the Dragonkiller",

    -- Hellfire Citadel
    -- Hellfire Ramparts
    [17306] = "Watchkeeper Gargolmar",
    [17308] = "Omor the Unscarred",
    [17536] = "Nazan",
    [17537] = "Vazruden",
    -- The Blood Furnace
    [17381] = "The Maker",
    [17380] = "Broggok",
    [17377] = "Keli'dan the Breaker",
    -- The Shattered Halls
    [16807] = "Grand Warlock Nethekurse",
    [20923] = "Blood Guard Porung",
    [16809] = "Warbringer O'mrogg",
    [16808] = "Warchief Kargath Bladefist",
    -- Magtheridon's Lair
    [17257] = "Magtheridon",

    --Karazhan
    [16181] = "Rokad the Ravager",
    [16180] = "Shadikith the Glider",
    [16179] = "Hyakiss the Lurker",
    [16152] = "Attumen the Huntsman",
    [15687] = "Moroes <Tower Steward>",
    [16457] = "Maiden of Virtue",
    [18168] = "The Crone",
    [17521] = "The Big Bad Wolf",
    [17533] = "Romulo",
    [17534] = "Julianne",
    [15691] = "The Curator",
    [15688] = "Terestian Illhoof",
    [16524] = "Shade of Aran",
    [15689] = "Netherspite",
    [17225] = "Nightbane",
    [15690] = "Prince Malchezaar",

    -- Sunwell Plateau
    [24850] = "Kalecgos",
    [24892] = "Sathrovarr the Corruptor",
    [24882] = "Brutallus",
    [25038] = "Felmyst",
    [25166] = "Grand Warlock Alythess",
    [25165] = "Lady Sacrolash",
    [25840] = "Entropius",
    [25315] = "Kil'jaeden <The Deceiver>",

    -- Tempest Keep
    -- The Arcatraz
    [20870] = "Zereketh the Unbound",
    [20885] = "Dalliah the Doomsayer",
    [20886] = "Wrath-Scryer Soccothrates",
    [20912] = "Harbinger Skyriss",
    -- The Botanica
    [17976] = "Commander Sarannis",
    [17975] = "High Botanist Freywinn",
    [17978] = "Thorngrin the Tender",
    [17980] = "Laj",
    [17977] = "Warp Splinter",
    -- The Mechanar
    [19219] = "Mechano-Lord Capacitus",
    [19221] = "Nethermancer Sepethrea",
    [19220] = "Pathaleon the Calculator",
    -- The Eye
    [19516] = "Void Reaver",
    [19514] = "Al'ar <Phoenix God>",
    [18805] = "High Astromancer Solarian",
    [19622] = "Kael'thas Sunstrider <Lord of the Blood Elves>",

    --
    -- WotLK Bosses
    --

    -- Ahn'kahet: The Old Kingdom
    [29309] = "Elder Nadox",
    [29308] = "Prince Taldaram",
    [29310] = "Jedoga Shadowseeker",
    [29311] = "Herald Volazj",
    [30258] = "Amanitar",

    -- Azjol-Nerub
    [28684] = "Krik'thir the Gatewatcher",
    [28921] = "Hadronox",
    [29120] = "Anub'arak",

    -- Drak'Tharon Keep
    [26630] = "Trollgore",
    [26631] = "Novos the Summoner",
    [27483] = "King Dred",
    [26632] = "The Prophet Tharon'ja",

    -- Gundrak
    [29304] = "Slad'ran",
    [29307] = "Drakkari Colossus",
    [29573] = "Drakkari Elemental",
    [29305] = "Moorabi",
    [29306] = "Gal'darah",
    [29932] = "Eck the Ferocious",

    -- Halls of Lightning
    [28586] = "General Bjarngrim",
    [28587] = "Volkhan",
    [28546] = "Ionar",
    [28923] = "Loken",

    -- Halls of Stone
    [27975] = "Maiden of Grief",
    [27977] = "Krystallus",
    [28234] = "Tribunal of the Ages",
    [27978] = "Sjonnir The Ironshaper",

    -- Icecrown Citadel

    -- The Culling of Stratholme
    [26529] = "Meathook",
    [26530] = "Salramm the Fleshcrafter",
    [26532] = "Chrono-Lord Epoch",
    [26533] = "Mal'Ganis",
    [32273] = "Infinite Corruptor",

    -- The Eye of Eternity
    [28859] = "Malygos",

    -- The Nexus
    [26731] = "Grand Magus Telestra",
    [26763] = "Anomalus",
    [26794] = "Ormorok the Tree-Shaper",
    [26723] = "Keristrasza",
    [26796] = "Commander Stoutbeard",
    [26798] = "Commander Kolurg",

    -- The Obsidian Sanctum
    [30452] = "Tenebron",
    [30451] = "Shadron",
    [30449] = "Vesperon",
    [28860] = "Sartharion",

    -- The Oculus
    [27654] = "Drakos the Interrogator",
    [27447] = "Varos Cloudstrider",
    [27655] = "Mage-Lord Urom",
    [27656] = "Ley-Guardian Eregos",

    -- The Violet Hold
    [29315] = "Erekem",
    [29316] = "Moragg",
    [29313] = "Ichoron",
    [29266] = "Xevozz",
    [29312] = "Lavanthor",
    [29314] = "Zuramat the Obliterator",
    [31134] = "Cyanigosa",

    -- Ulduar

    -- Utgarde Keep
    [23953] = "Prince Keleseth",
    [24200] = "Skarvald the Constructor",
    [24201] = "Dalronn the Controller",
    [23954] = "Ingvar the Plunderer",

    -- Utgarde Pinnacle
    [26668] = "Svala Sorrowgrave",
    [26687] = "Gortok Palehoof",
    [26693] = "Skadi the Ruthless",
    [26861] = "King Ymiron",
  }

  AutoBiographer_Databases.InstanceLocationDatabase = {
    [33] = Coordinates.New(0, 1421, 44.82, 67.85), -- Shadowfang Keep
    [34] = Coordinates.New(0, 1453, 39.83, 54.36), -- The Stockade
    [36] = Coordinates.New(0, 1415, 40.69, 79.58), -- The Deadmines
    [43] = Coordinates.New(0, 1414, 52.40, 55.18), -- The Wailing Caverns
    [47] = Coordinates.New(0, 1414, 50.90, 70.37), -- Razorfen Kraul
    [48] = Coordinates.New(0, 1414, 44.36, 34.86), -- Blackfathom Deeps
    [70] = Coordinates.New(0, 1415, 53.85, 57.67), -- Uldaman
    [90] = Coordinates.New(0, 1415, 42.82, 53.82), -- Gnomeregan
    [109] = Coordinates.New(0, 1415, 56.81, 75.18), -- The Temple of Atal'Hakkar
    [129] = Coordinates.New(0, 1414, 53.24, 71.17), -- Razorfen Downs
    [189] = Coordinates.New(0, 1415, 47.76, 19.49), -- Scarlet Monastery
    [209] = Coordinates.New(0, 1446, 38.72, 20.01), -- Zul'Farrak
    [229] = Coordinates.New(0, 1415, 48.94, 63.88), -- Balckrock Spire
    [230] = Coordinates.New(0, 1415, 48.07, 62.41), -- Blackrock Depths
    [269] = Coordinates.New(1, 1446, 57.61, 62.67), -- The Black Morass
    [289] = Coordinates.New(0, 1415, 52.71, 26.39), -- Scholomance
    [309] = Coordinates.New(0, 1434, 53.72, 17.57), -- Zul'Gurub
    [329] = Coordinates.New(0, 1415, 55.12, 17.36), -- Stratholme
    [349] = Coordinates.New(0, 1414, 38.47, 57.97), -- Maraudon
    [409] = Coordinates.New(0, 1415, 48.41, 63.81), -- The Molten Core
    [429] = Coordinates.New(0, 1414, 43.31, 68.33), -- Dire Maul
    [469] = Coordinates.New(0, 1415, 48.92, 64.46), -- Blackwing Lair
    [509] = Coordinates.New(0, 1414, 42.29, 86.48), -- Ruins of Ahn'Qiraj
    [531] = Coordinates.New(0, 1414, 40.96, 85.76), -- Temple of Ahn'Qiraj
    [532] = Coordinates.New(0, 1430, 46.93, 74.81), -- Karazhan
    [533] = Coordinates.New(0, 1423, 39.75, 26.31), -- Naxxramas
    [534] = Coordinates.New(1, 1446, 57.38, 50.07), -- Hyjal Summit
    [542] = Coordinates.New(530, 1944, 46.07, 51.73), -- The Blood Furnace
    [543] = Coordinates.New(530, 1944, 47.68, 53.56), -- Hellfire Ramparts
    [544] = Coordinates.New(530, 1944, 47.50, 52.08), -- Magtheridon's Lair
    [545] = Coordinates.New(530, 1946, 50.48, 33.34), -- The Steamvault
    [546] = Coordinates.New(530, 1946, 54.11, 34.43), -- The Underbog
    [547] = Coordinates.New(530, 1946, 48.96, 35.93), -- The Slave Pens
    [548] = Coordinates.New(530, 1946, 51.90, 33.03), -- Serpentshrine Cavern
    [550] = Coordinates.New(530, 1953, 73.56, 63.72), -- Tempest Keep
    [553] = Coordinates.New(530, 1953, 71.66, 55.14), -- The Botanica
    [554] = Coordinates.New(530, 1953, 70.49, 69.56), -- The Mechanar
    [556] = Coordinates.New(530, 1952, 44.71, 65.61), -- Sethekk Halls
    [557] = Coordinates.New(530, 1952, 39.65, 57.96), -- Mana-Tombs
    [558] = Coordinates.New(530, 1952, 34.71, 65.61), -- Auchenai Crypts
    [560] = Coordinates.New(1, 1446, 55.65, 54.00), -- Old Hillsbrad Foothills
    [564] = Coordinates.New(530, 1948, 71.06, 46.45), -- Black Temple
    [565] = Coordinates.New(530, 1949, 69.19, 24.00), -- Gruul's Lair
    [568] = Coordinates.New(0, 1942, 81.87, 64.34), -- Zul'Aman
    [574] = Coordinates.New(571, 117, 57.34, 47.01), -- Utgarde Keep
    [575] = Coordinates.New(571, 117, 57.72, 46.49), -- Utgarde Pinnacle
    [576] = Coordinates.New(571, 114, 27.5, 26.03), -- The Nexus
    [578] = Coordinates.New(571, 114, 27.52, 26.54), -- The Oculus
    [580] = Coordinates.New(0, 1957, 44.27, 45.62), -- Sunwell Plateau
    [585] = Coordinates.New(0, 1957, 61.14, 30.80), -- Magisters' Terrace
    [595] = Coordinates.New(1, 1446, 61.42, 62.64), -- The Culling of Stratholme
    [599] = Coordinates.New(571, 120, 39.66, 26.93), -- Halls of Stone
    [600] = Coordinates.New(571, 121, 28.64, 86.94), -- Drak'Tharon Keep
    [601] = Coordinates.New(571, 115, 26.01, 50.83), -- Azjol-Nerub
    [602] = Coordinates.New(571, 120, 45.25, 21.61), -- Halls of Lightning
    [604] = Coordinates.New(571, 121, 76.43, 21.43), -- Gundrak
    [608] = Coordinates.New(571, 125, 67.86, 69.43), -- The Violet Hold
    [619] = Coordinates.New(571, 115, 28.46, 51.71), -- Ahn'haket: The Old Kingdom
  }

  AutoBiographer_Databases.NpcDatabase = AutoBiographer_NpcDatabase

  AutoBiographer_Databases.XpPerLevelDatabase = {
    [1] = 400,
    [2] = 900,
    [3] = 1400,
    [4] = 2100,
    [5] = 2800,
    [6] = 3600,
    [7] = 4500,
    [8] = 5400,
    [9] = 6500,
    [10] = 7600,
    [11] = 8800,
    [12] = 10100,
    [13] = 11400,
    [14] = 12900,
    [15] = 14400,
    [16] = 16000,
    [17] = 17700,
    [18] = 19400,
    [19] = 21300,
    [20] = 23200,
    [21] = 25200,
    [22] = 27300,
    [23] = 29400,
    [24] = 31700,
    [25] = 34000,
    [26] = 36400,
    [27] = 38900,
    [28] = 41400,
    [29] = 44300,
    [30] = 47400,
    [31] = 50800,
    [32] = 54500,
    [33] = 58600,
    [34] = 62800,
    [35] = 67100,
    [36] = 71600,
    [37] = 76100,
    [38] = 80800,
    [39] = 85700,
    [40] = 90700,
    [41] = 95800,
    [42] = 101000,
    [43] = 106300,
    [44] = 111800,
    [45] = 117500,
    [46] = 123200,
    [47] = 129100,
    [48] = 135100,
    [49] = 141200,
    [50] = 147500,
    [51] = 153900,
    [52] = 160400,
    [53] = 167100,
    [54] = 173900,
    [55] = 180800,
    [56] = 187900,
    [57] = 195000,
    [58] = 202300,
    [59] = 209800,
    [60] = 217400,
  }
end

