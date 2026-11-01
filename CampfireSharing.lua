-- Automatic tales use existing statistics; personal tales live in the character's library.
AutoBiographer_CampfireSharing = { RecentlyShared = {} }
local Sharing = AutoBiographer_CampfireSharing
local Controller, Api, Enum = AutoBiographer_Controller, AutoBiographer_Api, AutoBiographerEnum

-- All story eligibility, labels and wording live here. Minimums are expressed
-- in configuration units (counts, kilometers, hours or gold), independent of
-- the player's distance display preference. Milestone minimums
-- instead come from Milestones.Configuration.Types[Milestone].MajorStart.
-- {qualifier} varies the lower-bound wording; {Qualifier} capitalizes it.
-- Fill the two placement lists with spell IDs when they have been identified.
Sharing.Configuration = {
  WelcomingCampfireSpellId = 1229739,
  CampfirePlacementSpellIds = {},
  CampEquipmentPlacementSpellIds = {},
  OfferCount = 3,
  TopCandidateCount = 5,
  RecentCategoryCount = 3,
  InitialHideSeconds = 3600,
  Channel = "SAY",
  Qualifiers = {
    { Text = "at least" },
    { Text = "no fewer than" },
    { Text = "over", Strict = true },
    { Text = "more than", Strict = true },
  },
  Types = {
    AquaticTravel = { Label = "Aquatic journeys", Source = "Distance", Metric = "AquaticForm", Class = "DRUID", Minimum = 10, Unit = "Km",
      Messages = {
        "I have travelled {qualifier} {quantity} {distanceUnit} in Aquatic Form. There is another world beneath the waves.",
        "{Qualifier} {quantity} {distanceUnit} of my travels have been in Aquatic Form. The fish are starting to recognize me.",
        "I have covered {qualifier} {quantity} {distanceUnit} in Aquatic Form. A road is useful, but so is a good current.",
      } },
    AuctionTrading = { Label = "Auction trading", Source = "Money", Metric = "AuctionHouseSale", Minimum = 100, Unit = "Gold",
      Messages = {
        "My auction sales have brought in {qualifier} {quantity} gold. There is adventure in a good bargain, too.",
        "I have made {qualifier} {quantity} gold from auction sales. Sometimes the fiercest competition is over a price tag.",
        "{Qualifier} {quantity} gold has come my way through auctions. One adventurer's spare loot is another's treasure.",
      } },
    BattleExperience = { Label = "Battle experience", Source = "Milestone", Milestone = "Kills",
      Messages = {
        "{Qualifier} {quantity} enemies killed, and I still check behind me before making camp.",
        "I have had a hand in slaying {qualifier} {quantity} foes. There's a reason I keep my weapons close.",
        "{Qualifier} {quantity} enemies have fallen with my help. Some put up more of a fight than others.",
      } },
    BattlegroundVictories = { Label = "Battleground victories", Source = "Milestone", Milestone = "BattlegroundsWon",
      Messages = {
        "I have won {qualifier} {quantity} battlegrounds. Some victories are earned one stubborn stand at a time.",
        "{Qualifier} {quantity} battleground victories are behind me. The best ones started with someone refusing to give up.",
        "I have been on the winning side of {qualifier} {quantity} battlegrounds. A plan helps; friends who follow it help more.",
      } },
    BearForm = { Label = "Life as a bear", Source = "Time", Metric = "BearForm", Class = "DRUID", Milestone = "TimeBearForm", Unit = "Hours",
      Messages = {
        "I have spent {qualifier} {quantity} hours as a bear. Some problems call for a larger pair of paws.",
        "{Qualifier} {quantity} hours in Bear Form have taught me one thing: few arguments survive a good growl.",
        "I have worn a bear's shape for {qualifier} {quantity} hours. Fur is excellent armour against a cold night.",
      } },
    CampEquipment = { Label = "Camp comforts", Source = "Casts", SpellList = "CampEquipmentPlacementSpellIds", Minimum = 25,
      Messages = {
        "I have used {name} {qualifier} {quantity} times to furnish campsites. Comfort takes preparation.",
        "{Qualifier} {quantity} times, {name} has helped me make camp. Even a weary adventurer deserves a little comfort.",
        "I have set up {name} {qualifier} {quantity} times. A campsite starts feeling like home when you unpack the right things.",
      } },
    CampfireBuilding = { Label = "Building campfires", Source = "Casts", SpellList = "CampfirePlacementSpellIds", Combine = true, Minimum = 25,
      Messages = {
        "I have lit {qualifier} {quantity} campfires. Wherever the road ends, I bring a little warmth.",
        "{Qualifier} {quantity} campfires have started by my hand. A spark and some company can improve almost any evening.",
        "I have built {qualifier} {quantity} campfires along the way. Finding dry wood is an adventure of its own.",
      } },
    Camping = { Label = "Nights by the fire", Source = "Milestone", Milestone = "Camped",
      Messages = {
        "I have rested at campfires {qualifier} {quantity} times. A warm fire is sometimes the finest treasure in Azeroth.",
        "{Qualifier} {quantity} rests beside a campfire, and the crackle of burning wood still sounds like a welcome.",
        "I have stopped to rest by a fire {qualifier} {quantity} times. The road can wait until my boots are warm.",
      } },
    CatForm = { Label = "Life as a cat", Source = "Time", Metric = "CatForm", Class = "DRUID", Milestone = "TimeCatForm", Unit = "Hours",
      Messages = {
        "I have spent {qualifier} {quantity} hours as a cat. Patience, claws, and the occasional nap.",
        "{Qualifier} {quantity} hours in Cat Form have sharpened my instincts. My interest in dangling string is unrelated.",
        "I have prowled about as a cat for {qualifier} {quantity} hours. Soft paws can carry you into surprising trouble.",
      } },
    Collecting = { Label = "Collecting", Source = "Items", Minimum = 100,
      Messages = {
        "I am something of a collector of {name}. {Qualifier} {quantity} have passed through my hands.",
        "{Qualifier} {quantity} {name} have found their way into my bags. I keep telling myself there is room for one more.",
        "I have acquired {qualifier} {quantity} {name} on my travels. Every collection begins with something you cannot leave behind.",
      } },
    Crafting = { Label = "A crafter's specialty", Source = "Items", Metric = "Create", Minimum = 50,
      Messages = {
        "I have crafted {qualifier} {quantity} {name}. My hands could probably make them in my sleep.",
        "{Qualifier} {quantity} {name} have come from my own handiwork. Practice leaves its mark on the tools.",
        "I have made {qualifier} {quantity} {name}. There is a particular satisfaction in turning supplies into something useful.",
      } },
    CraftingExperience = { Label = "Crafting experience", Source = "Milestone", Milestone = "ItemsCrafted",
      Messages = {
        "I have created {qualifier} {quantity} items. Every masterpiece begins with a crowded bag.",
        "{Qualifier} {quantity} crafted items bear the work of my hands. Some even turned out exactly as planned.",
        "I have made {qualifier} {quantity} items over the years. The tools grow familiar, but the work never quite gets old.",
      } },
    Deaths = { Label = "Lessons from the grave", Source = "Milestone", Milestone = "Deaths",
      Messages = {
        "I have died {qualifier} {quantity} times. Each return has taught me something, though apparently not quite enough.",
        "{Qualifier} {quantity} deaths, and I am still here to tell the tale. Persistence may be my strongest talent.",
        "I have made {qualifier} {quantity} trips beyond the veil. You would think I would know the way back by now.",
      } },
    DemonCompanionship = { Label = "Demonic company", Source = "Companions", Class = "WARLOCK", Milestone = "CompanionTime", Unit = "Hours",
      Messages = {
        "I have spent {qualifier} {quantity} hours accompanied by {name}. Our arrangement remains mutually convenient.",
        "{Qualifier} {quantity} hours in the company of {name}. We agree on very little, except which way the enemies are.",
        "I have kept {name} company for {qualifier} {quantity} hours. I prefer not to ask what they think of the arrangement.",
      } },
    DestructivePower = { Label = "Destructive power", Source = "Damage", Metric = "DamageDealt", Milestone = "DamageDealt",
      Messages = {
        "My enemies have felt {qualifier} {quantity} points of damage. Apparently, they needed convincing.",
        "I have dealt {qualifier} {quantity} damage in my travels. Some obstacles require a very firm introduction.",
        "{Qualifier} {quantity} damage dealt, and there always seems to be another fight around the bend.",
      } },
    DruidShapeshifting = { Label = "Changing shapes", Source = "Milestone", Class = "DRUID", Milestone = "Shapeshifts",
      Messages = {
        "I have changed forms {qualifier} {quantity} times. Choosing just one shape would be terribly limiting.",
        "{Qualifier} {quantity} changes of shape, and I still occasionally forget which feet I am standing on.",
        "I have shapeshifted {qualifier} {quantity} times. It pays to have the right paws for the occasion.",
      } },
    Duelling = { Label = "Friendly challenges", Source = "Milestone", Milestone = "DuelsWon",
      Messages = {
        "I have won {qualifier} {quantity} duels. There's always someone eager to try their luck.",
        "{Qualifier} {quantity} duels have ended in my favour. A bow afterward matters just as much as the opening move.",
        "I have claimed victory in {qualifier} {quantity} duels. The best opponents teach you something before they yield.",
      } },
    Earnings = { Label = "Earning a living", Source = "Milestone", Milestone = "MoneyGained", Unit = "Gold",
      Messages = {
        "I have earned {qualifier} {quantity} gold on my travels. Keeping it is another matter entirely.",
        "My travels have earned me {qualifier} {quantity} gold. Adventure pays well enough, until the repair bill arrives.",
        "My adventures have brought me {qualifier} {quantity} gold. Somehow, the next journey always needs funding.",
      } },
    FamiliarFaces = { Label = "Familiar faces", Source = "Milestone", Milestone = "UniquePlayersBuffed",
      Messages = {
        "I have buffed {qualifier} {quantity} different adventurers outside my party. Perhaps our paths will cross again.",
        "{Qualifier} {quantity} different adventurers outside my party have received a buff from me. A small kindness travels far.",
        "I have shared buffs with {qualifier} {quantity} different adventurers beyond my party. Strangers need looking after, too.",
      } },
    FamiliarRegion = { Label = "A familiar region", Source = "Zones", Minimum = 10, Unit = "Hours",
      Messages = {
        "I have spent {qualifier} {quantity} hours across {name}. There is more to a region than any single stop along the way.",
        "{Qualifier} {quantity} hours of my travels have been spent in {name}. Its roads and landmarks are becoming old friends.",
        "I have called {name} my surroundings for {qualifier} {quantity} hours. The whole region is beginning to feel familiar.",
      } },
    FamiliarSpot = { Label = "A favorite spot", Source = "Areas", Minimum = 10, Unit = "Hours",
      Messages = {
        "I have spent {qualifier} {quantity} hours in {name}. I know that place rather well.",
        "{Qualifier} {quantity} hours of my life have been spent in {name}. Some places have a way of keeping you around.",
        "I have lingered in {name} for {qualifier} {quantity} hours. By now, even the familiar turns have stories attached.",
      } },
    FishingCatches = { Label = "A patient angler", Source = "Milestone", Milestone = "FishingCatches",
      Messages = {
        "I have reeled in {qualifier} {quantity} successful catches. The fish insist most of them were a misunderstanding.",
        "{Qualifier} {quantity} successful catches have come up on my line. The secret is patience, or so I tell anyone watching.",
        "I have landed {qualifier} {quantity} successful fishing catches. Every bobber hides the promise of a good story.",
      } },
    FishingTime = { Label = "Waiting for a bite", Source = "Time", Metric = "Fishing", Milestone = "TimeFishing", Unit = "Hours",
      Messages = {
        "I have spent {qualifier} {quantity} hours fishing. Patience is a virtue, and apparently one of my most practiced professions.",
        "{Qualifier} {quantity} hours with a fishing line in the water. There are worse ways to watch the world go by.",
        "I have fished for {qualifier} {quantity} hours. A quiet bank can be every bit as memorable as a battlefield.",
      } },
    FlightPaths = { Label = "Views from above", Source = "Distance", Metric = "FlightPath", Minimum = 500, Unit = "Km",
      Messages = {
        "I have travelled {qualifier} {quantity} {distanceUnit} by flight. The views almost make up for the landings.",
        "{Qualifier} {quantity} {distanceUnit} of flight paths have carried me over Azeroth. The world looks kinder from up there.",
        "I have flown {qualifier} {quantity} {distanceUnit} on flight paths. I still check that my bags are fastened before takeoff.",
      } },
    Generosity = { Label = "A little generosity", Source = "Buffs", Milestone = "BuffsGiven",
      Messages = {
        "I have given {qualifier} {quantity} buffs to adventurers outside my party. A little magic can make a stranger's road easier.",
        "{Qualifier} {quantity} buffs have gone to adventurers beyond my party. Good fortune is better when you can share it.",
        "I have offered {qualifier} {quantity} buffs to people outside my party. It is a simple way to wish someone safe travels.",
      } },
    GhostWolfTravel = { Label = "Running with the wind", Source = "Distance", Metric = "GhostWolf", Class = "SHAMAN", Minimum = 100, Unit = "Km",
      Messages = {
        "I have travelled {qualifier} {quantity} {distanceUnit} as a Ghost Wolf. The wind makes excellent company.",
        "I have covered {qualifier} {quantity} {distanceUnit} in Ghost Wolf form. The road feels different on four paws.",
        "I have covered {qualifier} {quantity} {distanceUnit} as a Ghost Wolf. The spirits know a thing or two about travelling light.",
      } },
    Healing = { Label = "The healer's path", Source = "Damage", Metric = "HealingDealt", Milestone = "HealingDealt",
      Messages = {
        "My healing has restored {qualifier} {quantity} health. Not every victory is won by drawing blood.",
        "I have healed {qualifier} {quantity} health on my travels. Sometimes the bravest thing is keeping someone else standing.",
        "{Qualifier} {quantity} health restored, and I still breathe easier when everyone makes it out together.",
      } },
    HunterCompanionship = { Label = "Faithful companions", Source = "Companions", Class = "HUNTER", Milestone = "CompanionTime", Unit = "Hours",
      Messages = {
        "I have spent {qualifier} {quantity} hours beside my {name} companions. Some friendships need no words.",
        "{Qualifier} {quantity} hours with my {name} companions have taught me the value of a friend with sharper teeth.",
        "My {name} companions and I have travelled together for {qualifier} {quantity} hours. They always know when it is time to eat.",
      } },
    HuntingVariety = { Label = "A varied bestiary", Source = "Milestone", Milestone = "CreatureTypesKilled",
      Messages = {
        "{Qualifier} {quantity} different kinds of creatures have fallen before me. Azeroth keeps finding new teeth to throw my way.",
        "I have defeated {qualifier} {quantity} different kinds of creatures. My field guide could use a few more pages.",
        "{Qualifier} {quantity} kinds of creatures have met their end on my travels. There is always something unfamiliar in the next thicket.",
      } },
    Jumping = { Label = "Taking the scenic leap", Source = "Milestone", Milestone = "Jumps",
      Messages = {
        "I have jumped {qualifier} {quantity} times. Roads are merely suggestions.",
        "{Qualifier} {quantity} jumps, and I still cannot leave a low wall untested.",
        "I have leapt {qualifier} {quantity} times on my travels. Walking in a straight line lacks a certain flair.",
      } },
    Looting = { Label = "Spoils of adventure", Source = "Items", Metric = "Loot", Minimum = 100,
      Messages = {
        "I have looted {qualifier} {quantity} {name}. Adventure has a curious way of filling one's pockets.",
        "{Qualifier} {quantity} {name} have ended up among my spoils. Leaving things behind has never been my strongest skill.",
        "I have gathered {qualifier} {quantity} {name} as loot. There is a reason I keep looking for larger bags.",
      } },
    MageConjuring = { Label = "Magical provisions", Source = "Casts", NamePattern = "^Conjure ", Class = "MAGE", Minimum = 100,
      Messages = {
        "I have cast {name} {qualifier} {quantity} times. Being prepared is much easier with a little magic.",
        "{Qualifier} {quantity} casts of {name}, and nobody can accuse me of arriving empty-handed.",
        "I have used {name} {qualifier} {quantity} times. Provisioning is easier when the supplies come out of thin air.",
      } },
    MagePortals = { Label = "Shortcuts through Azeroth", Source = "Casts", NamePattern = "^Portal: ", Class = "MAGE", Minimum = 25,
      Messages = {
        "I have cast {name} {qualifier} {quantity} times. Sometimes the best road is no road at all.",
        "{Qualifier} {quantity} casts of {name} have saved someone a long walk. I do hope they remembered everything.",
        "I have opened {name} {qualifier} {quantity} times. The journey is much shorter when you fold the distance.",
      } },
    MonsterHunting = { Label = "Monster hunting", Source = "Kills", Minimum = 50,
      Messages = {
        "They call me the bane of {name}. I have personally slain {qualifier} {quantity} of their kind.",
        "I have personally slain {qualifier} {quantity} of the creatures known as {name}. We have crossed paths rather often.",
        "{Qualifier} {quantity} of the creatures called {name} have fallen by my hand. I have learned to recognize their approach.",
      } },
    MoonkinForm = { Label = "Feathers and magic", Source = "Time", Metric = "MoonkinForm", Class = "DRUID", Milestone = "TimeMoonkinForm", Unit = "Hours",
      Messages = {
        "I have spent {qualifier} {quantity} hours in Moonkin Form. Feathers and formidable magic make a fine combination.",
        "{Qualifier} {quantity} hours as a moonkin have taught me to allow extra room when passing through a doorway.",
        "I have worn Moonkin Form for {qualifier} {quantity} hours. There is wisdom in the stars, and warmth in all these feathers.",
      } },
    OldEnemies = { Label = "Old enemies", Source = "Enemies", Minimum = 5000,
      Messages = {
        "Foes called {name} have dealt {qualifier} {quantity} damage to me. We have a complicated relationship.",
        "I have taken {qualifier} {quantity} damage from enemies known as {name}. Familiarity has done little for their manners.",
        "{Qualifier} {quantity} damage from {name}, and somehow we keep meeting. I would prefer a less painful reunion.",
      } },
    PaladinAuras = { Label = "A constant aura", Source = "SpellTime", Class = "PALADIN", Milestone = "SpellTime", Unit = "Hours",
      SpellIds = { 465, 7294, 19746, 19876, 19888, 19891, 20218 },
      Messages = {
        "I have spent {qualifier} {quantity} hours bearing {name}. Faith is a constant companion.",
        "{Qualifier} {quantity} hours with {name} have accompanied my travels. Conviction need not be loud to be felt.",
        "I have carried {name} for {qualifier} {quantity} hours. A steady presence can be a comfort on a dangerous road.",
      } },
    Questing = { Label = "Doing favours", Source = "Milestone", Milestone = "Quests",
      Messages = {
        "I have completed {qualifier} {quantity} quests. Somehow, everyone still has one more favour to ask.",
        "{Qualifier} {quantity} quests finished, and there is always another worried face waiting down the road.",
        "I have seen {qualifier} {quantity} quests through to the end. A simple errand rarely stays simple for long.",
      } },
    Riding = { Label = "Life in the saddle", Source = "Distance", Metric = "Mounted", Minimum = 250, Unit = "Km",
      Messages = {
        "I have ridden {qualifier} {quantity} {distanceUnit}. My mount deserves a share of the glory.",
        "{Qualifier} {quantity} {distanceUnit} have passed beneath me in the saddle. Good company makes a long road shorter.",
        "I have covered {qualifier} {quantity} {distanceUnit} while mounted. I owe my mount more than a few quiet evenings.",
      } },
    Shadowform = { Label = "Embracing the shadows", Source = "Time", Metric = "Shadowform", Class = "PRIEST", Milestone = "TimeShadowform", Unit = "Hours",
      Messages = {
        "I have spent {qualifier} {quantity} hours in Shadowform. The darkness and I have an understanding.",
        "{Qualifier} {quantity} hours in Shadowform have made bright sunshine feel rather insistent.",
        "I have embraced Shadowform for {qualifier} {quantity} hours. Some truths are easier to hear in the dark.",
      } },
    Shopping = { Label = "A merchant's favorite", Source = "Items", Metric = "Merchant", Minimum = 100,
      Messages = {
        "I have bought {qualifier} {quantity} {name} from merchants. I suspect they are rather pleased to see me.",
        "{Qualifier} {quantity} {name} have come to me over a merchant's counter. A familiar customer ought to earn a discount.",
        "I have purchased {qualifier} {quantity} {name} from merchants. Apparently, I know what I like.",
      } },
    SignatureAttack = { Label = "A signature attack", Source = "Abilities", Metric = "DamageDealt", Minimum = 10000,
      Messages = {
        "{name} is something of a specialty of mine. It has dealt {qualifier} {quantity} damage.",
        "I have dealt {qualifier} {quantity} damage with {name}. There is comfort in having a reliable answer to trouble.",
        "{Qualifier} {quantity} damage has come from my use of {name}. My enemies may recognize it by now.",
      } },
    SignatureHealing = { Label = "A trusted healing spell", Source = "Abilities", Metric = "HealingDealt", Minimum = 10000,
      Messages = {
        "I have restored {qualifier} {quantity} health with {name}. There is comfort in knowing which spell to reach for.",
        "{Qualifier} {quantity} health restored with {name}. A familiar spell can steady your hands when things look grim.",
        "My use of {name} has healed {qualifier} {quantity} health. I am always glad to have it ready.",
      } },
    Stealth = { Label = "Unseen journeys", Source = "Time", Metric = "Stealthed", Classes = { "ROGUE", "DRUID" }, Milestone = "TimeStealthed", Unit = "Hours",
      Messages = {
        "I have spent {qualifier} {quantity} hours hidden in the shadows. Not every journey needs an audience.",
        "{Qualifier} {quantity} hours in stealth have taught me how much people say when they think nobody is listening.",
        "I have kept out of sight for {qualifier} {quantity} hours. Sometimes the safest path is the one nobody sees you take.",
      } },
    Swimming = { Label = "Beneath the waves", Source = "Distance", Metric = "Swimming", Minimum = 10, Unit = "Km",
      Messages = {
        "I have swum {qualifier} {quantity} {distanceUnit}. Dry socks are a luxury I no longer take for granted.",
        "{Qualifier} {quantity} {distanceUnit} of swimming have carried me across Azeroth's waters. The shore always looks closer at first.",
        "I have covered {qualifier} {quantity} {distanceUnit} by swimming. I have learned to appreciate a well-placed bridge.",
      } },
    TakingPunishment = { Label = "Taking punishment", Source = "Damage", Metric = "DamageTakenRaw", Minimum = 100000,
      Messages = {
        "I have endured {qualifier} {quantity} damage. I am beginning to think armour is a worthwhile investment.",
        "{Qualifier} {quantity} damage has come my way. I would rather be counting coins, but here we are.",
        "I have weathered {qualifier} {quantity} damage on my travels. Some lessons arrive with rather more force than others.",
      } },
    TimeInCombat = { Label = "Time in battle", Source = "Time", Metric = "InCombat", Milestone = "TimeCombat", Unit = "Hours",
      Messages = {
        "I have spent {qualifier} {quantity} hours in combat. Peace and quiet are beginning to sound rather adventurous.",
        "{Qualifier} {quantity} hours of fighting have brought me here. The sound of a quiet campfire is a welcome change.",
        "I have been in combat for {qualifier} {quantity} hours. A peaceful meal is never something I take for granted.",
      } },
    TotemCalling = { Label = "Calling the elements", Source = "Casts", NamePattern = " Totem$", Class = "SHAMAN", Minimum = 100,
      Messages = {
        "I have called upon {name} {qualifier} {quantity} times. The elements have heard rather a lot from me.",
        "{Qualifier} {quantity} times, I have set down {name}. A little help from the elements goes a long way.",
        "I have summoned {name} {qualifier} {quantity} times. It is reassuring to know just where the elements are standing.",
      } },
    TravelFormTravel = { Label = "Four-legged travels", Source = "Distance", Metric = "TravelForm", Class = "DRUID", Minimum = 100, Unit = "Km",
      Messages = {
        "I have covered {qualifier} {quantity} {distanceUnit} in Travel Form. Four legs make light work of a long road.",
        "{Qualifier} {quantity} {distanceUnit} have passed beneath my feet in Travel Form. The open road is a fine place to stretch your legs.",
        "I have travelled {qualifier} {quantity} {distanceUnit} in Travel Form. Nature has a shape for every journey.",
      } },
    Walking = { Label = "Worn-out boots", Source = "Distance", Metric = "OnFoot", Minimum = 100, Unit = "Km",
      Messages = {
        "My boots have carried me {qualifier} {quantity} {distanceUnit} across Azeroth. Most of the soles are still attached.",
        "I have travelled {qualifier} {quantity} {distanceUnit} on foot. You notice more of the world when you take it step by step.",
        "{Qualifier} {quantity} {distanceUnit} on foot, and every worn patch on my boots has a story behind it.",
      } },
    WarriorStances = { Label = "A warrior's footing", Source = "Casts", Class = "WARRIOR", Minimum = 100,
      SpellIds = { 2457, 71, 2458 },
      Messages = {
        "I have entered {name} {qualifier} {quantity} times. There is a proper footing for every fight.",
        "{Qualifier} {quantity} times, I have taken up {name}. A battle can turn on where you plant your feet.",
        "I have switched to {name} {qualifier} {quantity} times. The right stance is the beginning of a good answer.",
      } },
  },
}

local function IsSecret(value)
  return issecretvalue and issecretvalue(value)
end

local function DisplayValue(value, unit)
  if (unit == "Km") then return value * 0.0009144 end
  if (unit == "Hours") then return value / 3600 end
  if (unit == "Gold") then return value / 10000 end
  return value
end

local function Effective(breakdown)
  return math.max(0, (breakdown.Amount or 0) - (breakdown.Over or 0))
end

local function MatchesClass(rule, class)
  if (rule.Class) then return class == rule.Class end
  if (rule.Classes) then
    for _, allowed in ipairs(rule.Classes) do if (class == allowed) then return true end end
    return false
  end
  return true
end

-- Resolve names from IDs so rank variants can be combined without hardcoding
-- localized spell names. Placement lists intentionally have no guessed IDs.
local function SpellFilter(rule)
  local ids, names = {}, {}
  for _, id in ipairs(rule.SpellIds or Sharing.Configuration[rule.SpellList] or {}) do
    ids[id] = true
    local name = Api.GetSpellInfo(id)
    if (not IsSecret(name) and name) then names[name] = true end
  end
  return function(id, name)
    return ids[id] or names[name] or (rule.NamePattern and name:match(rule.NamePattern))
  end
end

-- Aggregates are lazy and cached for one offer, never rebuilt on every aura tick.
local function Context()
  local context = { MaxLevel = Controller:GetCurrentLevelNum(), Catalogs = Controller.CharacterData.Catalogs }
  function context:Get(method)
    if (not self[method]) then self[method] = Controller[method](Controller, 1, self.MaxLevel) end
    return self[method]
  end
  return context
end

function Sharing:BuildCandidates(rule, context)
  local values, maxLevel, catalogs = {}, context.MaxLevel, context.Catalogs
  local function Add(amount, name, key)
    values[#values + 1] = { Amount = DisplayValue(amount, rule.Unit), Name = name, Key = tostring(key or name or "") }
  end
  if (rule.Source == "Milestone") then
    local definition = AutoBiographer_Milestones.Definitions and AutoBiographer_Milestones.Definitions[rule.Milestone]
    if (definition) then Add(definition.GetTotal()) end
  elseif (rule.Source == "Distance") then
    Add(Controller:GetDistanceByDistanceTrackingType(Enum.DistanceTrackingType[rule.Metric], 1, maxLevel))
  elseif (rule.Source == "Time") then
    Add(Controller:GetTimeForTimeTrackingType(Enum.TimeTrackingType[rule.Metric], 1, maxLevel))
  elseif (rule.Source == "Money") then
    Add(Controller:GetMoneyForAcquisitionMethod(Enum.MoneyAcquisitionMethod[rule.Metric], 1, maxLevel))
  elseif (rule.Source == "Buffs") then
    Add(Controller:GetOtherPlayerStatByOtherPlayerTrackingType(Enum.OtherPlayerTrackingType.BuffsGivenToPlayerNotGrouped, 1, maxLevel))
  elseif (rule.Source == "Damage") then
    local amount, over = Controller:GetDamageOrHealing(Enum.DamageOrHealingCategory[rule.Metric], 1, maxLevel)
    Add(math.max(0, amount - over))
  elseif (rule.Source == "Kills") then
    for id, stats in pairs(context:Get("GetAggregatedKillStatisticsDictionary")) do
      local unit = catalogs.UnitCatalog[id]
      if (unit and unit.Name and unit.UType == Enum.UnitType.Creature) then
        Add((stats[Enum.KillTrackingType.TaggedKillingBlow] or 0) + (stats[Enum.KillTrackingType.UntaggedKillingBlow] or 0), unit.Name, id)
      end
    end
  elseif (rule.Source == "Items") then
    for id, stats in pairs(context:Get("GetAggregatedItemStatisticsDictionary")) do
      local item, amount = catalogs.ItemCatalog[id], 0
      if (rule.Metric) then amount = stats[Enum.ItemAcquisitionMethod[rule.Metric]] or 0
      else for _, value in pairs(stats) do amount = amount + value end end
      if (item and item.Name) then Add(amount, item.Name, id) end
    end
  elseif (rule.Source == "Abilities") then
    -- Aggregate by catalog display name: ranks merge but pet/totem names remain.
    local totals = {}
    for id, breakdown in pairs(Controller:GetAggregatedDamageMeterAbilities({ Enum.DamageOrHealingCategory[rule.Metric] }, 1, maxLevel, false)) do
      local spell = catalogs.SpellCatalog[id]
      if (spell and spell.Name) then
        local name = CatalogSpell.GetDamageMeterDisplayName(spell, id)
        totals[name] = (totals[name] or 0) + Effective(breakdown)
      end
    end
    for name, amount in pairs(totals) do Add(amount, name) end
  elseif (rule.Source == "Enemies") then
    for name, breakdown in pairs(Controller:GetAggregatedDamageTakenByUnit({ Enum.DamageOrHealingCategory.DamageTaken }, 1, maxLevel)) do
      if (name ~= "" and name ~= "Unknown") then Add(Effective(breakdown), name) end
    end
  elseif (rule.Source == "Areas") then
    for area, stats in pairs(context:Get("GetAggregatedTimeStatisticsDictionary")) do
      local zone, subzone = area:match("^(.-)%-(.*)$")
      local name = subzone and subzone ~= "" and subzone or zone or area
      if (name ~= "") then Add(stats[Enum.TimeTrackingType.LoggedIn] or 0, name, area) end
    end
  elseif (rule.Source == "Zones") then
    local totals = {}
    for area, stats in pairs(context:Get("GetAggregatedTimeStatisticsDictionary")) do
      local zone = area:match("^(.-)%-(.*)$") or area
      if (zone ~= "") then totals[zone] = (totals[zone] or 0) + (stats[Enum.TimeTrackingType.LoggedIn] or 0) end
    end
    for zone, amount in pairs(totals) do Add(amount, zone, zone) end
  elseif (rule.Source == "Companions") then
    for id, amount in pairs(context:Get("GetAggregatedCompanionFamilyTime")) do
      local name = catalogs.CompanionFamilyCatalog and catalogs.CompanionFamilyCatalog[id]
      if (name) then Add(amount, name, id) end
    end
  elseif (rule.Source == "Casts" or rule.Source == "SpellTime") then
    local matches, totals = SpellFilter(rule), {}
    local dictionary = context:Get(rule.Source == "Casts" and "GetAggregatedSpellStatisticsDictionary" or "GetAggregatedSpellTime")
    for id, stats in pairs(dictionary) do
      local spell = catalogs.SpellCatalog[id]
      if (spell and spell.Name and matches(id, spell.Name)) then
        local amount = rule.Source == "Casts" and (stats[Enum.SpellTrackingType.SuccessfullyCast] or 0) or stats
        local name = rule.Combine and "" or spell.Name
        totals[name] = (totals[name] or 0) + amount
      end
    end
    for name, amount in pairs(totals) do Add(amount, name) end
  end
  return values
end

function Sharing:BuildOffers()
  local context, eligible, fresh, recent = Context(), {}, {}, {}
  local _, class = UnitClass("player")
  if (IsSecret(class)) then return {} end
  for _, key in ipairs(self.RecentlyShared) do recent[key] = true end
  for key, rule in pairs(self.Configuration.Types) do
    if (MatchesClass(rule, class)) then
      local candidate = self:ChooseCandidate(self:BuildCandidates(rule, context), self:GetMinimum(rule))
      if (candidate) then
        local messages = {}
        for _, template in ipairs(rule.Messages) do
          local message = self:FormatMessage(rule, candidate, template)
          -- Public chat has a byte limit; do not split a story into automatic sends.
          if (#message <= 255) then messages[#messages + 1] = message end
        end
        if (#messages > 0) then
          local offer = { Key = key, Label = rule.Label, Messages = messages }
          eligible[#eligible + 1] = offer
          if (not recent[key]) then fresh[#fresh + 1] = offer end
        end
      end
    end
  end
  local pool = #fresh >= math.min(self.Configuration.OfferCount, #eligible) and fresh or eligible
  table.sort(pool, function(a, b) return a.Key < b.Key end)
  local offers = {}
  for index = 1, math.min(self.Configuration.OfferCount, #pool) do
    offers[index] = table.remove(pool, math.random(#pool))
  end
  return offers
end

function Sharing:ChooseCandidate(candidates, minimum)
  local eligible = {}
  if (not minimum) then return nil end
  for _, candidate in ipairs(candidates) do
    if (candidate.Amount >= minimum) then eligible[#eligible + 1] = candidate end
  end
  table.sort(eligible, function(a, b)
    if (a.Amount ~= b.Amount) then return a.Amount > b.Amount end
    return a.Key < b.Key
  end)
  if (#eligible == 0) then return nil end
  return eligible[math.random(math.min(self.Configuration.TopCandidateCount, #eligible))]
end

function Sharing:BuildPersonalOffers()
  local eligible, fresh, recent = {}, {}, {}
  for _, key in ipairs(self.RecentlyShared) do recent[key] = true end
  for _, tale in ipairs(Controller:GetCampfireTales().Items) do
    local values = CampfireTales.Validate(tale.Title, tale.Text)
    if (values) then
      local offer = { Key = "Personal:" .. tale.Id, Label = values.Title, Messages = { values.Text }, Tale = tale }
      eligible[#eligible + 1] = offer
      if (not recent[offer.Key]) then fresh[#fresh + 1] = offer end
    end
  end
  local pool = #fresh >= math.min(self.Configuration.OfferCount, #eligible) and fresh or eligible
  local offers = {}
  for index = 1, math.min(self.Configuration.OfferCount, #pool) do offers[index] = table.remove(pool, math.random(#pool)) end
  return offers
end

function Sharing:BuildSuggestions()
  local personal, automatic, suggestions = {}, {}, {}
  for index, offer in ipairs(self.PersonalOffers) do personal[#personal + 1] = { Offer = offer, Index = index, Personal = true } end
  for index, offer in ipairs(self.Offers) do automatic[#automatic + 1] = { Offer = offer, Index = index, Personal = false } end
  local function Pick(pool) suggestions[#suggestions + 1] = table.remove(pool, math.random(#pool)) end
  -- Reserve one of each kind before filling the remaining slot at random.
  if (#personal > 0 and #automatic > 0) then Pick(personal); Pick(automatic) end
  local remaining = {}
  for _, pool in ipairs({ personal, automatic }) do
    for _, suggestion in ipairs(pool) do remaining[#remaining + 1] = suggestion end
  end
  while (#suggestions < self.Configuration.OfferCount and #remaining > 0) do Pick(remaining) end
  for index = #suggestions, 2, -1 do
    local other = math.random(index)
    suggestions[index], suggestions[other] = suggestions[other], suggestions[index]
  end
  return suggestions
end

function Sharing:Dismiss()
  self.Offers, self.PersonalOffers, self.Suggestions, self.TestMode, self.AutomaticPending = nil, nil, nil, nil, nil
  if (self.Prompt) then self.Prompt:Hide() end
  if (AutoBiographer_CampfireTalesPanel.ReturnButton and not self:CanUseCampfire()) then
    AutoBiographer_CampfireTalesPanel.ReturnButton:SetEnabled(false)
  end
end

function Sharing:FormatMessage(rule, candidate, template)
  local amount, distanceUnit = candidate.Amount, ""
  if (rule.Unit == "Km") then
    local _, name, factor = HelperFunctions.GetDistanceUnit()
    amount, distanceUnit = amount * (factor / 0.0009144), name
  end
  -- Round down in the displayed unit: 47 -> 40, 382 -> 380, 4,821 -> 4,800.
  -- Avoid logarithms so exact powers of ten keep their correct magnitude.
  local magnitude = amount >= 10 and 10 or 1
  while (amount >= magnitude * 100) do magnitude = magnitude * 10 end
  local rounded = math.floor(amount / magnitude) * magnitude
  local quantity = HelperFunctions.CommaValue(rounded)
  local qualifiers = {}
  for _, qualifier in ipairs(self.Configuration.Qualifiers) do
    if (not qualifier.Strict or amount > rounded) then qualifiers[#qualifiers + 1] = qualifier.Text end
  end
  local qualifier = qualifiers[math.random(#qualifiers)]
  return (template:gsub("{[Qq]ualifier}", function(token)
      return token == "{Qualifier}" and qualifier:gsub("^%l", string.upper) or qualifier
    end):gsub("{quantity}", function() return quantity end):gsub("{name}", function() return candidate.Name or "" end)
    :gsub("{distanceUnit}", function() return distanceUnit end))
end

function Sharing:GetMinimum(rule)
  if (not rule.Milestone) then return rule.Minimum end
  local milestone = AutoBiographer_Milestones.Configuration.Types[rule.Milestone]
  return milestone and milestone.MajorStart and DisplayValue(milestone.MajorStart, rule.Unit)
end

function Sharing:IsResting()
  local unreadable = false
  for index = 1, 255 do
    local ok, aura = pcall(Api.GetAuraDataByIndex, "player", index, "HELPFUL")
    if (not ok or IsSecret(aura)) then return nil end
    if (not aura) then break end
    local spellId = aura.spellId
    if (IsSecret(spellId)) then unreadable = true
    elseif (spellId == self.Configuration.WelcomingCampfireSpellId) then return true end
  end
  if (unreadable) then return nil end
  return false
end

function Sharing:UpdateHiddenTime()
  local library = Controller:GetCampfireTales()
  if (self.PlayedAt) then
    local now = GetTime()
    local elapsed = math.max(0, now - self.PlayedAt)
    self.PlayedAt = now
    if (library.HideRemaining) then library.HideRemaining = math.max(0, library.HideRemaining - elapsed) end
  end
  if (library.HideRemaining == 0) then library.HideRemaining = nil end
  return library.HideRemaining or 0
end

function Sharing:ShouldOpenAutomatically()
  return self:UpdateHiddenTime() == 0 and AutoBiographer_Settings.Options.RecommendCampfireMessages
end

function Sharing:ScheduleHiddenTime()
  self.HideGeneration = (self.HideGeneration or 0) + 1
  local generation = self.HideGeneration
  local remaining = self:UpdateHiddenTime()
  if (remaining <= 0 or not self.PlayedAt) then return end
  C_Timer.After(remaining, function()
    if (generation ~= self.HideGeneration or not self.PlayedAt) then return end
    if (self:UpdateHiddenTime() > 0) then self:ScheduleHiddenTime(); return end
    if (self:ShouldOpenAutomatically() and self:IsResting() == true) then
      self.Resting, self.Pending, self.AutomaticPending = true, true, true
      self:Resume()
    end
  end)
end

function Sharing:HideSuggestions()
  self:UpdateHiddenTime()
  local library = Controller:GetCampfireTales()
  library.HideDuration = library.HideDuration and library.HideDuration * 2 or self.Configuration.InitialHideSeconds
  library.HideRemaining = library.HideDuration
  self.PlayedAt = GetTime()
  self.Pending = false
  self:Dismiss()
  self:ScheduleHiddenTime()
end

function Sharing:ResetHiddenTime()
  local library = Controller:GetCampfireTales()
  library.HideDuration, library.HideRemaining = nil, nil
  self.HideGeneration = (self.HideGeneration or 0) + 1
end

function Sharing:OnEnteringWorld()
  -- The saved remainder carries between sessions; the clock runs only in-world.
  Controller:GetCampfireTales().PausedUntilLogin = nil -- Retire the old login-based pause.
  self.PlayedAt = GetTime()
  self:ScheduleHiddenTime()
end

function Sharing:OnLeavingWorld()
  self:UpdateHiddenTime()
  self.PlayedAt = nil
  self.HideGeneration = (self.HideGeneration or 0) + 1
  self:Reset()
end

function Sharing:OnPlayerAuras(baseline)
  if (self.TestMode) then
    if (not baseline) then return end
    self:Reset()
  end
  local resting = self:IsResting()
  if (resting == nil) then return end -- Secret aura data is not a removal.
  if (baseline) then
    self:Reset()
    self.Resting = resting
  elseif (resting) then
    self.RemovalGeneration = (self.RemovalGeneration or 0) + 1
    self.RemovalPending = false
    if (self.Resting == nil) then self.Resting = true; return end
    if (not self.Resting) then
      self.Resting = true
      if (self:ShouldOpenAutomatically()) then
        self.Pending, self.AutomaticPending = true, true
        self:Resume()
      end
    end
  elseif (self.Resting and not self.RemovalPending) then
    -- Welcoming Campfire can be removed/re-added while continuously sitting.
    self.RemovalPending = true
    local generation = self.RemovalGeneration or 0
    C_Timer.After(0.25, function()
      if (generation ~= (self.RemovalGeneration or 0)) then return end
      self.RemovalPending = false
      if (self:IsResting() == false) then
        self.Resting, self.Pending = false, false
        self:Dismiss()
      end
    end)
  end
end

function Sharing:Pause()
  self.Pausing = true
  if (self.Prompt) then self.Prompt:Hide() end
  self.Pausing = nil
  if (AutoBiographer_CampfireTalesPanel.ReturnButton) then AutoBiographer_CampfireTalesPanel.ReturnButton:SetEnabled(false) end
end

function Sharing:Reset()
  self.RemovalGeneration = (self.RemovalGeneration or 0) + 1
  self.Resting, self.Pending, self.RemovalPending = nil, false, false
  self:Dismiss()
end

function Sharing:CanUseCampfire()
  return not InCombatLockdown() and (self.TestMode == true or self:IsResting() == true)
end

function Sharing:Resume()
  if (self.AutomaticPending and not self:ShouldOpenAutomatically()) then
    self.Pending = false
    self:Dismiss()
    return
  end
  local available = self:CanUseCampfire()
  local editor = AutoBiographer_CampfireTalesPanel
  if (editor.ReturnButton) then editor.ReturnButton:SetEnabled(available) end
  if (not self.Pending or not available or editor:IsVisible()) then return end
  local refresh = not self.Offers or not self.PersonalOffers or not self.Suggestions
  if (not self.Offers) then self.Offers = self:BuildOffers() end
  if (not self.PersonalOffers) then self.PersonalOffers = self:BuildPersonalOffers() end
  if (refresh) then self.Suggestions = self:BuildSuggestions() end
  self:ShowPrompt()
end

function Sharing:ShareSuggestion(index)
  local suggestion = self.Suggestions and self.Suggestions[index]
  if (suggestion) then self:Share(suggestion.Index, suggestion.Personal) end
end

function Sharing:Share(index, personal)
  if (not self:CanUseCampfire()) then return end
  local offers = self.Offers
  if (personal) then offers = self.PersonalOffers end
  local offer = offers and offers[index]
  if (not offer) then return end
  if (personal) then
    local tale = offer.Tale
    local values = CampfireTales.Contains(Controller:GetCampfireTales(), tale) and CampfireTales.Validate(tale.Title, tale.Text)
    if (not values) then self.PersonalOffers = nil; self:Resume(); return end
    offer.Messages = { values.Text }
  end
  local message = offer.Messages[math.random(#offer.Messages)]
  -- This call must remain directly in the button's click handler, not a timer.
  local ok, sent = pcall(Api.SendMilestoneMessage, message, self.Configuration.Channel)
  if (not ok or not sent) then
    print("[AutoBiographer] Unable to share a campfire story right now. Try again when chat is available.")
    return
  end
  Controller:OnCampfireTaleShared()
  self:ResetHiddenTime()
  if (personal) then offer.Tale.LastSharedTimestamp = time() end
  for recentIndex = #self.RecentlyShared, 1, -1 do
    if (self.RecentlyShared[recentIndex] == offer.Key) then table.remove(self.RecentlyShared, recentIndex) end
  end
  table.insert(self.RecentlyShared, offer.Key)
  while (#self.RecentlyShared > self.Configuration.RecentCategoryCount) do table.remove(self.RecentlyShared, 1) end
  self.Pending = false
  self:Dismiss()
end

function Sharing:OpenCrafting()
  if (not self:CanUseCampfire()) then return end
  self:Pause()
  AutoBiographer_MainWindow:ShowSection("CampfireTales")
end

function Sharing:ShowPrompt()
  if (not self.Prompt) then
    local window = CreateFrame("Frame", "AutoBiographerCampfireSharing", UIParent, "BasicFrameTemplate")
    self.Prompt = window
    local position = Controller:GetCampfireTales().WindowPosition
    if (position) then window:SetPoint(position.Point, UIParent, position.RelativePoint, position.X, position.Y)
    else window:SetPoint("TOP", UIParent, "TOP", 0, -4) end
    window:SetFrameStrata("DIALOG")
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    local function StopDragging()
      if (not window.IsMoving) then return end
      window:StopMovingOrSizing()
      window.IsMoving = false
      local point, _, relativePoint, x, y = window:GetPoint()
      Controller:GetCampfireTales().WindowPosition = { Point = point, RelativePoint = relativePoint, X = x, Y = y }
    end
    window.DragBar = CreateFrame("Frame", nil, window)
    window.DragBar:SetPoint("TOPLEFT")
    window.DragBar:SetPoint("TOPRIGHT", -26, 0)
    window.DragBar:SetHeight(22)
    window.DragBar:EnableMouse(true)
    window.DragBar:RegisterForDrag("LeftButton")
    window.DragBar:SetScript("OnDragStart", function()
      if (window.IsMoving) then return end
      window.IsMoving = true
      window:StartMoving()
    end)
    window.DragBar:SetScript("OnDragStop", StopDragging)
    window.Message = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    window.Message:SetPoint("TOPLEFT", 12, -32)
    window.Message:SetWidth(232)
    window.Message:SetJustifyH("LEFT")
    window.Message:SetText("Choose a tale to share.")
    window.Buttons = {}
    for index = 1, self.Configuration.OfferCount do
      local button = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
      button:SetSize(356, 26)
      button:SetPoint("TOPLEFT", 12, -58 - (index - 1) * 32)
      button:SetNormalFontObject("GameFontNormalSmall")
      button:SetText("")
      button:GetFontString():SetWidth(336)
      button:GetFontString():SetWordWrap(false)
      button:SetScript("OnClick", function() self:ShareSuggestion(index) end)
      button:SetScript("OnEnter", function()
        local suggestion = self.Suggestions and self.Suggestions[index]
        if (not suggestion) then return end
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText(suggestion.Offer.Label)
        GameTooltip:AddLine(suggestion.Personal and "Your saved tale" or "Automatic tale", 1, 0.82, 0)
        if (suggestion.Personal) then GameTooltip:AddLine(suggestion.Offer.Messages[1], 1, 1, 1, true) end
        GameTooltip:Show()
      end)
      button:SetScript("OnLeave", function() GameTooltip:Hide() end)
      window.Buttons[index] = button
    end
    window.Empty = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    window.Empty:SetPoint("TOPLEFT", 12, -64)
    window.Empty:SetText("No tales to suggest yet. Craft your first one.")
    window.Craft = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    window.Craft:SetSize(110, 24)
    window.Craft:SetPoint("TOPRIGHT", -12, -28)
    window.Craft:SetText("Craft a tale")
    window.Craft:SetScript("OnClick", function() self:OpenCrafting() end)
    window.Craft:SetScript("OnEnter", function(button)
      GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
      GameTooltip:SetText("Craft a tale")
      GameTooltip:AddLine("Use your recorded events for inspiration, write and edit your own story, and save it to share at a campfire.", 1, 1, 1, true)
      GameTooltip:Show()
    end)
    window.Craft:SetScript("OnLeave", function() GameTooltip:Hide() end)
    window.HideSuggestions = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    window.HideSuggestions:SetSize(170, 24)
    window.HideSuggestions:SetPoint("BOTTOMRIGHT", -12, 12)
    window.HideSuggestions:SetText("Hide for a while")
    window.HideSuggestions:SetScript("OnClick", function() self:HideSuggestions() end)
    window.HideSuggestions:SetScript("OnEnter", function(button)
      GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
      GameTooltip:SetText("Hide for a while")
      GameTooltip:AddLine("Close the Campfire Tales window and temporarily prevent it from opening automatically. You can still open it manually.", 1, 1, 1, true)
      GameTooltip:Show()
    end)
    window.HideSuggestions:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local function Skip() self.Pending = false; self:Dismiss() end
    window.Skip = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    window.Skip:SetSize(100, 24)
    window.Skip:SetPoint("BOTTOMLEFT", 12, 12)
    window.Skip:SetText("Close")
    window.Skip:SetScript("OnClick", Skip)
    window.Skip:SetScript("OnEnter", function(button)
      GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
      GameTooltip:SetText("Close")
      GameTooltip:AddLine("Close the Campfire Tales window. It may open again the next time you rest at a campfire.", 1, 1, 1, true)
      GameTooltip:Show()
    end)
    window.Skip:SetScript("OnLeave", function() GameTooltip:Hide() end)
    window.CloseButton:SetScript("OnClick", Skip)
    window:EnableKeyboard(true)
    window:SetScript("OnKeyDown", function(frame, key)
      frame:SetPropagateKeyboardInput(key ~= "ESCAPE")
      if (key == "ESCAPE") then Skip() end
    end)
    -- Escape hides special frames directly. Treat that as dismissing the picker,
    -- while Pause (combat or opening the editor) retains the current choices.
    table.insert(UISpecialFrames, "AutoBiographerCampfireSharing")
    window:SetScript("OnHide", function()
      StopDragging()
      if (not self.Pausing and self.Pending) then Skip() end
    end)
  end
  local window = self.Prompt
  window.TitleText:SetText("AutoBiographer Campfire Tales" .. (self.TestMode and " (Test)" or ""))
  for index, button in ipairs(window.Buttons) do
    local suggestion = self.Suggestions[index]
    button:SetShown(suggestion ~= nil)
    if (suggestion) then button:SetText((suggestion.Personal and "Your tale: " or "") .. suggestion.Offer.Label) end
  end
  window.Empty:SetShown(#self.Suggestions == 0)
  window:SetSize(380, 102 + math.max(1, #self.Suggestions) * 32)
  window:Show()
end
