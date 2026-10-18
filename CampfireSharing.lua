-- Campfire stories use existing character statistics; nothing here is saved.
AutoBiographer_CampfireSharing = { RecentlyShared = {} }
local Sharing = AutoBiographer_CampfireSharing
local Controller, Api, Enum = AutoBiographer_Controller, AutoBiographer_Api, AutoBiographerEnum

-- All story eligibility, labels and wording live here. Minimums are expressed
-- in the displayed unit (counts, kilometres, hours or gold). Milestone minimums
-- instead come from Milestones.Configuration.Types[Milestone].MajorStart.
-- Fill the two placement lists with spell IDs when they have been identified.
Sharing.Configuration = {
  WelcomingCampfireSpellId = 1229739,
  CampfirePlacementSpellIds = {},
  CampEquipmentPlacementSpellIds = {},
  OfferCount = 3,
  TopCandidateCount = 5,
  RecentCategoryCount = 3,
  Channel = "SAY",
  Types = {
    AquaticTravel = { Label = "Aquatic journeys", Source = "Distance", Metric = "AquaticForm", Class = "DRUID", Minimum = 10, Unit = "Km",
      Message = "I have travelled at least {quantity} kilometres in Aquatic Form. There is another world beneath the waves." },
    AuctionTrading = { Label = "Auction trading", Source = "Money", Metric = "AuctionHouseSale", Minimum = 100, Unit = "Gold",
      Message = "My auction sales have brought in at least {quantity} gold. There is adventure in a good bargain, too." },
    BattleExperience = { Label = "Battle experience", Source = "Milestone", Milestone = "Kills",
      Message = "I have helped bring down {quantity} enemies. There are some battles you never forget." },
    BearForm = { Label = "Life as a bear", Source = "Time", Metric = "BearForm", Class = "DRUID", Milestone = "TimeBearForm", Unit = "Hours",
      Message = "I have spent at least {quantity} hours as a bear. Some problems call for a larger pair of paws." },
    CampEquipment = { Label = "Camp comforts", Source = "Casts", SpellList = "CampEquipmentPlacementSpellIds", Minimum = 25,
      Message = "I have used {name} {quantity} times to furnish campsites. Comfort takes preparation." },
    CampfireBuilding = { Label = "Building campfires", Source = "Casts", SpellList = "CampfirePlacementSpellIds", Combine = true, Minimum = 25,
      Message = "I have lit {quantity} campfires. Wherever the road ends, I bring a little warmth." },
    Camping = { Label = "Nights by the fire", Source = "Milestone", Milestone = "Camped",
      Message = "I have rested at campfires {quantity} times. A warm fire is sometimes the finest treasure in Azeroth." },
    CatForm = { Label = "Life as a cat", Source = "Time", Metric = "CatForm", Class = "DRUID", Milestone = "TimeCatForm", Unit = "Hours",
      Message = "I have spent at least {quantity} hours as a cat. Patience, claws, and the occasional nap." },
    Collecting = { Label = "Collecting", Source = "Items", Minimum = 100,
      Message = "I am something of a collector of {name}. At least {quantity} have passed through my hands." },
    Crafting = { Label = "A crafter's specialty", Source = "Items", Metric = "Create", Minimum = 50,
      Message = "I have crafted at least {quantity} {name}. My hands could probably make them in my sleep." },
    CraftingExperience = { Label = "Crafting experience", Source = "Milestone", Milestone = "ItemsCrafted",
      Message = "I have created {quantity} items. Every masterpiece begins with a crowded bag." },
    DemonCompanionship = { Label = "Demonic company", Source = "Companions", Class = "WARLOCK", Milestone = "CompanionTime", Unit = "Hours",
      Message = "I have spent at least {quantity} hours accompanied by {name}. Our arrangement remains mutually convenient." },
    DestructivePower = { Label = "Destructive power", Source = "Damage", Metric = "DamageDealt", Milestone = "DamageDealt",
      Message = "My enemies have felt {quantity} points of damage. Apparently, they needed convincing." },
    DruidShapeshifting = { Label = "Changing shapes", Source = "Milestone", Class = "DRUID", Milestone = "Shapeshifts",
      Message = "I have changed forms {quantity} times. Choosing just one shape would be terribly limiting." },
    Duelling = { Label = "Friendly challenges", Source = "Milestone", Milestone = "DuelsWon",
      Message = "I have won {quantity} duels. A friendly challenge is still a challenge." },
    Earnings = { Label = "Earning a living", Source = "Milestone", Milestone = "MoneyGained", Unit = "Gold",
      Message = "I have earned at least {quantity} gold on my travels. Keeping it is another matter entirely." },
    FamiliarFaces = { Label = "Familiar faces", Source = "Milestone", Milestone = "UniquePlayersBuffed",
      Message = "I have blessed {quantity} different adventurers outside my party. Perhaps our paths will cross again." },
    FavoriteHaunt = { Label = "A favorite haunt", Source = "Areas", Minimum = 10, Unit = "Hours",
      Message = "I have spent at least {quantity} hours in {name}. I know that place rather well." },
    FlightPaths = { Label = "Views from above", Source = "Distance", Metric = "FlightPath", Minimum = 500, Unit = "Km",
      Message = "I have travelled at least {quantity} kilometres by flight. The views almost make up for the landings." },
    Generosity = { Label = "A little generosity", Source = "Buffs", Milestone = "BuffsGiven",
      Message = "I have given {quantity} buffs to adventurers outside my party. A little magic can make a stranger's road easier." },
    GhostWolfTravel = { Label = "Running with the wind", Source = "Distance", Metric = "GhostWolf", Class = "SHAMAN", Minimum = 100, Unit = "Km",
      Message = "I have travelled at least {quantity} kilometres as a Ghost Wolf. The wind makes excellent company." },
    Healing = { Label = "The healer's path", Source = "Damage", Metric = "HealingDealt", Milestone = "HealingDealt",
      Message = "My healing has restored {quantity} health. Not every victory is won by drawing blood." },
    HunterCompanionship = { Label = "Faithful companions", Source = "Companions", Class = "HUNTER", Milestone = "CompanionTime", Unit = "Hours",
      Message = "I have spent at least {quantity} hours beside my {name} companions. Some friendships need no words." },
    HuntingVariety = { Label = "A varied bestiary", Source = "Milestone", Milestone = "CreatureTypesKilled",
      Message = "{quantity} different kinds of creatures have fallen before me. Azeroth keeps finding new teeth to throw my way." },
    Jumping = { Label = "Taking the scenic leap", Source = "Milestone", Milestone = "Jumps",
      Message = "I have jumped {quantity} times. Roads are merely suggestions." },
    Looting = { Label = "Spoils of adventure", Source = "Items", Metric = "Loot", Minimum = 100,
      Message = "I have looted at least {quantity} {name}. Adventure has a curious way of filling one's pockets." },
    MageConjuring = { Label = "Magical provisions", Source = "Casts", NamePattern = "^Conjure ", Class = "MAGE", Minimum = 100,
      Message = "I have cast {name} {quantity} times. Being prepared is much easier with a little magic." },
    MagePortals = { Label = "Shortcuts through Azeroth", Source = "Casts", NamePattern = "^Portal: ", Class = "MAGE", Minimum = 25,
      Message = "I have cast {name} {quantity} times. Sometimes the best road is no road at all." },
    MonsterHunting = { Label = "Monster hunting", Source = "Kills", Minimum = 50,
      Message = "They call me the bane of {name}. I have personally slain {quantity} of their kind." },
    MoonkinForm = { Label = "Feathers and magic", Source = "Time", Metric = "MoonkinForm", Class = "DRUID", Milestone = "TimeMoonkinForm", Unit = "Hours",
      Message = "I have spent at least {quantity} hours in Moonkin Form. Feathers and formidable magic make a fine combination." },
    OldEnemies = { Label = "Old enemies", Source = "Enemies", Minimum = 5000,
      Message = "Foes called {name} have dealt {quantity} damage to me. We have a complicated relationship." },
    PaladinAuras = { Label = "A constant aura", Source = "SpellTime", Class = "PALADIN", Milestone = "SpellTime", Unit = "Hours",
      SpellIds = { 465, 7294, 19746, 19876, 19888, 19891, 20218 },
      Message = "I have spent at least {quantity} hours bearing {name}. Faith is a constant companion." },
    Questing = { Label = "Doing favours", Source = "Milestone", Milestone = "Quests",
      Message = "I have completed {quantity} quests. Somehow, everyone still has one more favour to ask." },
    Riding = { Label = "Life in the saddle", Source = "Distance", Metric = "Mounted", Minimum = 250, Unit = "Km",
      Message = "I have ridden at least {quantity} kilometres. My mount deserves a share of the glory." },
    Shadowform = { Label = "Embracing the shadows", Source = "Time", Metric = "Shadowform", Class = "PRIEST", Milestone = "TimeShadowform", Unit = "Hours",
      Message = "I have spent at least {quantity} hours in Shadowform. The darkness and I have an understanding." },
    Shopping = { Label = "A merchant's favorite", Source = "Items", Metric = "Merchant", Minimum = 100,
      Message = "I have bought {quantity} {name} from merchants. I suspect they are rather pleased to see me." },
    SignatureAttack = { Label = "A signature attack", Source = "Abilities", Metric = "DamageDealt", Minimum = 10000,
      Message = "{name} is something of a specialty of mine. It has dealt {quantity} damage." },
    SignatureHealing = { Label = "A trusted healing spell", Source = "Abilities", Metric = "HealingDealt", Minimum = 10000,
      Message = "I have restored {quantity} health with {name}. There is comfort in knowing which spell to reach for." },
    Stealth = { Label = "Unseen journeys", Source = "Time", Metric = "Stealthed", Classes = { "ROGUE", "DRUID" }, Milestone = "TimeStealthed", Unit = "Hours",
      Message = "I have spent at least {quantity} hours hidden in the shadows. Not every journey needs an audience." },
    Swimming = { Label = "Beneath the waves", Source = "Distance", Metric = "Swimming", Minimum = 10, Unit = "Km",
      Message = "I have swum at least {quantity} kilometres. Dry socks are a luxury I no longer take for granted." },
    TakingPunishment = { Label = "Taking punishment", Source = "Damage", Metric = "DamageTakenRaw", Minimum = 100000,
      Message = "I have endured {quantity} damage. I am beginning to think armour is a worthwhile investment." },
    TotemCalling = { Label = "Calling the elements", Source = "Casts", NamePattern = " Totem$", Class = "SHAMAN", Minimum = 100,
      Message = "I have called upon {name} {quantity} times. The elements have heard rather a lot from me." },
    TravelFormTravel = { Label = "Four-legged travels", Source = "Distance", Metric = "TravelForm", Class = "DRUID", Minimum = 100, Unit = "Km",
      Message = "I have covered at least {quantity} kilometres in Travel Form. Four legs make light work of a long road." },
    Walking = { Label = "Worn-out boots", Source = "Distance", Metric = "OnFoot", Minimum = 100, Unit = "Km",
      Message = "My boots have carried me at least {quantity} kilometres across Azeroth. Most of the soles are still attached." },
    WarriorStances = { Label = "A warrior's footing", Source = "Casts", Class = "WARRIOR", Minimum = 100,
      SpellIds = { 2457, 71, 2458 },
      Message = "I have entered {name} {quantity} times. There is a proper footing for every fight." },
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
        local message = self:FormatMessage(rule, candidate)
        -- Public chat has a byte limit; do not split a story into automatic sends.
        if (#message <= 255) then
          local offer = { Key = key, Label = rule.Label, Message = message }
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

function Sharing:Dismiss()
  self.Offers = nil
  if (self.Prompt) then self.Prompt:Hide() end
end

function Sharing:FormatMessage(rule, candidate)
  local quantity = HelperFunctions.CommaValue(math.floor(candidate.Amount))
  return (rule.Message:gsub("{quantity}", function() return quantity end):gsub("{name}", function() return candidate.Name or "" end))
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

function Sharing:OnPlayerAuras(baseline)
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
      if (AutoBiographer_Settings.Options["RecommendCampfireMessages"]) then
        self.Pending = true
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
  if (self.Prompt) then self.Prompt:Hide() end
end

function Sharing:Reset()
  self.RemovalGeneration = (self.RemovalGeneration or 0) + 1
  self.Resting, self.Pending, self.RemovalPending = nil, false, false
  self:Dismiss()
end

function Sharing:Resume()
  if (InCombatLockdown() or not self.Pending or self:IsResting() ~= true) then return end
  if (not self.Offers) then self.Offers = self:BuildOffers() end
  if (#self.Offers < self.Configuration.OfferCount) then self.Pending = false; return end
  self:ShowPrompt()
end

function Sharing:Share(index)
  if (InCombatLockdown() or self:IsResting() ~= true) then return end
  local offer = self.Offers and self.Offers[index]
  if (not offer) then return end
  -- This call must remain directly in the button's click handler, not a timer.
  local ok, sent = pcall(Api.SendMilestoneMessage, offer.Message, self.Configuration.Channel)
  if (not ok or not sent) then
    print("[AutoBiographer] Unable to share a campfire story right now. Try again when chat is available.")
    return
  end
  for recentIndex = #self.RecentlyShared, 1, -1 do
    if (self.RecentlyShared[recentIndex] == offer.Key) then table.remove(self.RecentlyShared, recentIndex) end
  end
  table.insert(self.RecentlyShared, offer.Key)
  while (#self.RecentlyShared > self.Configuration.RecentCategoryCount) do table.remove(self.RecentlyShared, 1) end
  self.Pending = false
  self:Dismiss()
end

function Sharing:ShowPrompt()
  if (not self.Prompt) then
    local window = CreateFrame("Frame", "AutoBiographerCampfireSharing", UIParent, "BasicFrameTemplate")
    self.Prompt = window
    window:SetPoint("TOP", UIParent, "TOP", 0, -4)
    window:SetFrameStrata("DIALOG")
    window.TitleText:SetText("AutoBiographer Campfire Tales")
    window.Message = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    window.Message:SetPoint("TOPLEFT", 12, -32)
    window.Message:SetWidth(336)
    window.Message:SetJustifyH("LEFT")
    window.Message:SetText("Choose a tale to share. The story is revealed when you speak.")
    window.Buttons = {}
    for index = 1, self.Configuration.OfferCount do
      local button = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
      button:SetSize(336, 26)
      button:SetPoint("TOPLEFT", 12, -68 - (index - 1) * 32)
      button:SetScript("OnClick", function() self:Share(index) end)
      window.Buttons[index] = button
    end
    local function Skip() self.Pending = false; self:Dismiss() end
    window.Skip = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    window.Skip:SetSize(100, 24)
    window.Skip:SetPoint("BOTTOM", 0, 12)
    window.Skip:SetText("Not now")
    window.Skip:SetScript("OnClick", Skip)
    window.CloseButton:SetScript("OnClick", Skip)
  end
  local window = self.Prompt
  window:SetSize(360, 112 + #self.Offers * 32)
  for index, button in ipairs(window.Buttons) do
    local offer = self.Offers[index]
    button:SetShown(offer ~= nil)
    if (offer) then button:SetText(offer.Label) end
  end
  window:Show()
end
