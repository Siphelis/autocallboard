local Core = {}
local L = AutoCallboardLocale

local type, tonumber, tostring, pairs, ipairs = type, tonumber, tostring, pairs, ipairs
local string, table, math = string, table, math

local DEFAULTS = {
  targetName = "Callboard",
  summonSpell = "Summon Callboard",
  summonSpellID = 600647,
  summonDuration = 30,
  summonCooldown = 45,
  rerollFrame = "ObjectivesMainFrame.rerollBtn",
  objectivePrefix = "ObjectiveFrame",
  language = "",
  objectiveButtonField = "selectBtn",
  autoAccept = true,
  autoAcceptShared = false,
  autoCurrentInstanceQuest = false,
  maxRerolls = 50,
  rerollDelay = 0.1,
  rerollTimeout = 1.5,
  knownQuests = {},
  desiredQuests = {},
  characterProfiles = {},
  accountProfile = {},
  characterState = {},
  migratedCharacters = {},
  accountListSeeded = false,
  presetsMigrated = false,
  questPanelExpanded = false,
  debug = {
    enabled = false,
    mouseWatch = false,
    sniffer = false,
    maxLog = 120,
  },
  goldTracker = {
    totalSpent = 0,
    trackedQuestCount = 0,
    lastQuestSpent = 0,
  },
  buttonShown = true,
  button = {
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = 0,
  },
  minimap = {
    shown = true,
    angle = 225,
  },
}

local function trim(value)
  if type(value) ~= "string" then
    return ""
  end

  return (value:match("^%s*(.-)%s*$"))
end

local function objectiveTextParts(value)
  local text = trim(value)
  local cleanText, zoneOrSort, questType = string.match(text, "^(.-),%s*(%d+)%s*,%s*(%d+)%s*%.?%s*$")

  if cleanText then
    return trim(cleanText), tonumber(zoneOrSort) or 0, tonumber(questType) or 0
  end

  return text, 0, 0
end

local VALID_QUEST_TYPES = { [1] = true, [2] = true, [3] = true, [4] = true }

function Core.sanitizeQuestType(value)
  value = tonumber(value) or 0
  if VALID_QUEST_TYPES[value] then
    return value
  end

  return 0
end

local function containsAny(value, needles)
  for i = 1, #(needles) do
    if string.find(value, needles[i], 1, true) then
      return true
    end
  end

  return false
end

local function stripColorCodes(value)
  if type(value) ~= "string" then
    return ""
  end

  return (value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

local function normalizeMatchText(value)
  value = stripColorCodes(string.lower(trim(value)))
  value = value:gsub("[^%w]+", " ")
  value = value:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")

  return value
end

local function compactMatchText(value)
  return (normalizeMatchText(value):gsub(" ", ""))
end

local function hasEnabledValue(map)
  if type(map) ~= "table" then
    return false
  end

  for _, enabled in pairs(map) do
    if enabled == true then
      return true
    end
  end

  return false
end

Core.stripColorCodes = stripColorCodes
Core.normalizeMatchText = normalizeMatchText

local function appendUniqueNormalized(values, seen, value)
  value = normalizeMatchText(value)

  if value == "" or seen[value] then
    return
  end

  seen[value] = true
  table.insert(values, value)
end

local PROFESSION_HINTS = {
  "bulk order:",
  "crafting materials:",
  "saronite",
  "cobalt bar",
  "titanium",
  "eternal earth",
  "eternal air",
  "eternal fire",
  "eternal water",
  "eternal shadow",
  "eternal life",
  "icethorn",
  "adder's tongue",
  "lichbloom",
  "frost lotus",
  "borean leather",
  "arctic fur",
  "dragonfin",
  "glacial salmon",
  "constrictor grass",
}

local RAID_HINTS = {
  "malygos",
  "kelthuzad",
  "kel'thuzad",
  "sartharion",
  "naxxramas",
  "obsidian sanctum",
  "eye of eternity",
  "construct quarter",
}

local DUNGEON_HINTS = {
  "keristrasza",
  "ingvar",
  "king ymiron",
  "prophet tharon'ja",
  "tharon'ja",
  "utgarde pinnacle",
  "drak'tharon keep",
  "the nexus.",
  "the nexus ",
}

local CURRENT_INSTANCE_ALIASES = {
  ["utgarde keep"] = { "utgarde keep", "ingvar", "ingvar the plunderer" },
  ["utgarde pinnacle"] = { "utgarde pinnacle", "king ymiron", "ymiron" },
  ["azjol nerub"] = { "azjol nerub", "anub arak" },
  ["oculus"] = { "the oculus", "oculus", "ley guardian eregos", "eregos" },
  ["halls of lightning"] = { "halls of lightning", "loken" },
  ["halls of stone"] = { "halls of stone", "sjonnir", "sjonnir the ironshaper" },
  ["culling of stratholme"] = { "the culling of stratholme", "culling of stratholme", "mal ganis" },
  ["drak tharon keep"] = { "drak tharon keep", "prophet tharon ja", "the prophet tharon ja", "tharon ja" },
  ["gundrak"] = { "gundrak", "gal darah" },
  ["ahn kahet the old kingdom"] = { "ahn kahet", "old kingdom", "herald volazj" },
  ["ahn kahet"] = { "ahn kahet", "old kingdom", "herald volazj" },
  ["violet hold"] = { "the violet hold", "violet hold", "cyanigosa" },
  ["nexus"] = { "the nexus", "keristrasza" },
  ["trial of the champion"] = { "trial of the champion", "the black knight", "black knight" },
  ["forge of souls"] = { "the forge of souls", "forge of souls", "devourer of souls" },
  ["pit of saron"] = { "pit of saron", "overlord tyrannus", "tyrannus" },
  ["halls of reflection"] = { "halls of reflection", "escaped from arthas", "marwyn", "falric" },
  ["naxxramas"] = { "naxxramas", "kel thuzad", "kelthuzad" },
  ["eye of eternity"] = { "the eye of eternity", "eye of eternity", "malygos" },
  ["obsidian sanctum"] = { "the obsidian sanctum", "obsidian sanctum", "sartharion" },
  ["vault of archavon"] = { "vault of archavon", "toravon", "archavon", "emalon", "koralon" },
}

local CURRENT_INSTANCE_COMPACT_ALIASES = {}
for key, mapped in pairs(CURRENT_INSTANCE_ALIASES) do
  CURRENT_INSTANCE_COMPACT_ALIASES[compactMatchText(key)] = mapped
end

local COMPACT_ALIAS_PREFIX_MIN = 5

local function findCompactAliasByPrefix(compact)
  if compact:len() < COMPACT_ALIAS_PREFIX_MIN then
    return nil
  end

  local found

  for key, mapped in pairs(CURRENT_INSTANCE_COMPACT_ALIASES) do
    if key:len() > compact:len() and key:sub(1, compact:len()) == compact then
      if found and found ~= mapped then
        return nil
      end

      found = mapped
    end
  end

  return found
end

local function findInstanceAliases(alias)
  local mapped = CURRENT_INSTANCE_ALIASES[alias]
      or CURRENT_INSTANCE_ALIASES[(alias:gsub("^the ", "", 1))]

  if mapped then
    return mapped
  end

  local compact = compactMatchText(alias)
  if compact == "" then
    return nil
  end

  return CURRENT_INSTANCE_COMPACT_ALIASES[compact]
      or CURRENT_INSTANCE_COMPACT_ALIASES[(compact:gsub("^the", "", 1))]
      or findCompactAliasByPrefix(compact)
end

local OPEN_WORLD_TITLE_PREFIXES = {
  "a growing menace:",
  "clear the roads",
  "no mercy:",
  "pacify ",
  "sweep and clear:",
  "storm peaks trophy",
}

local ROLL_DELAY_MIN = 0
local ROLL_DELAY_MAX = 5
local ROLL_TIMEOUT_MIN = 0.25
local ROLL_TIMEOUT_MAX = 10

local ROLL_SPEED_PRESETS = {
  turbo = { delay = 0, timeout = 1, label = "turbo" },
  fast = { delay = 0.05, timeout = 1.25, label = "fast" },
  normal = { delay = 0.1, timeout = 1.5, label = "normal" },
  safe = { delay = 0.35, timeout = 2.5, label = "safe" },
}

local ROLL_SPEED_PRESET_ORDER = { "turbo", "fast", "normal", "safe" }

local function clampNumber(value, minimum, maximum)
  value = tonumber(value)

  if not value then
    return nil
  end

  if value < minimum then
    return minimum
  end

  if value > maximum then
    return maximum
  end

  return value
end

function Core.clampRollDelay(value)
  return clampNumber(value, ROLL_DELAY_MIN, ROLL_DELAY_MAX) or DEFAULTS.rerollDelay
end

function Core.clampRollTimeout(value)
  return clampNumber(value, ROLL_TIMEOUT_MIN, ROLL_TIMEOUT_MAX) or DEFAULTS.rerollTimeout
end

function Core.rollSpeedPresetList()
  local list = {}

  for i = 1, #(ROLL_SPEED_PRESET_ORDER) do
    local key = ROLL_SPEED_PRESET_ORDER[i]
    local preset = ROLL_SPEED_PRESETS[key]

    if preset then
      list[#(list) + 1] = {
        index = #(list) + 1,
        key = key,
        delay = preset.delay,
        timeout = preset.timeout,
        label = preset.label,
      }
    end
  end

  return list
end

function Core.nearestRollSpeedPreset(delay)
  local list = Core.rollSpeedPresetList()
  local target = tonumber(delay)
  local best, bestDiff

  for i = 1, #(list) do
    local diff = math.abs((target or 0) - list[i].delay)

    if not bestDiff or diff < bestDiff then
      best = list[i]
      bestDiff = diff
    end
  end

  return best or list[1]
end

local function copyDefaults()
  local state = {}

  for key, value in pairs(DEFAULTS) do
    if type(value) == "table" then
      local nested = {}

      for nestedKey, nestedValue in pairs(value) do
        nested[nestedKey] = nestedValue
      end

      state[key] = nested
    else
      state[key] = value
    end
  end

  return state
end

function Core.defaultState()
  return copyDefaults()
end

function Core.autoCurrentInstanceWarningText()
  return L.AUTO_CURRENT_INSTANCE_WARNING
end

local MERGE_NONEMPTY_STRING = { "targetName", "rerollFrame", "objectivePrefix", "objectiveButtonField" }
local MERGE_STRING = { "summonSpell", "language" }
local MERGE_BOOLEAN = {
  "autoAccept", "autoCurrentInstanceQuest",
  "presetsMigrated", "questPanelExpanded", "buttonShown",
  "accountListSeeded",
}
local MERGE_NUMBER_MIN1 = { "summonDuration", "summonCooldown", "maxRerolls" }
local MERGE_COLLECTION = {
  knownQuests = "copyQuestList",
  desiredQuests = "copyDesiredMap",
  characterProfiles = "copyCharacterProfiles",
  accountProfile = "copyAccountProfile",
  characterState = "copyCharacterStateMap",
  migratedCharacters = "copyDesiredMap",
}
local GOLD_TRACKER_KEYS = { "totalSpent", "trackedQuestCount", "lastQuestSpent" }

local function mergeNested(saved, state, spec)
  for key, kind in pairs(spec) do
    if kind == "nonEmptyString" then
      if trim(saved[key]) ~= "" then state[key] = trim(saved[key]) end
    elseif kind == "number" then
      if type(saved[key]) == "number" then state[key] = saved[key] end
    elseif kind == "boolean" then
      if type(saved[key]) == "boolean" then state[key] = saved[key] end
    end
  end
end

function Core.mergeState(saved, adopt)
  local state = copyDefaults()

  if type(saved) ~= "table" then
    return state
  end

  for _, key in ipairs(MERGE_NONEMPTY_STRING) do
    if trim(saved[key]) ~= "" then state[key] = trim(saved[key]) end
  end

  for _, key in ipairs(MERGE_STRING) do
    if type(saved[key]) == "string" then state[key] = trim(saved[key]) end
  end

  for _, key in ipairs(MERGE_BOOLEAN) do
    if type(saved[key]) == "boolean" then state[key] = saved[key] end
  end

  for _, key in ipairs(MERGE_NUMBER_MIN1) do
    if type(saved[key]) == "number" and saved[key] >= 1 then state[key] = saved[key] end
  end

  if type(saved.summonSpellID) == "number" then
    state.summonSpellID = saved.summonSpellID
  end

  if type(saved.rerollDelay) == "number" then
    state.rerollDelay = Core.clampRollDelay(saved.rerollDelay)
  end

  if type(saved.rerollTimeout) == "number" then
    state.rerollTimeout = Core.clampRollTimeout(saved.rerollTimeout)
  end

  if type(saved.autoAcceptShared) == "boolean" then
    state.autoAcceptShared = saved.autoAcceptShared
  elseif type(saved.autoAcceptSharedBoard) == "boolean" then
    state.autoAcceptShared = saved.autoAcceptSharedBoard
  end

  for key, copier in pairs(MERGE_COLLECTION) do
    if type(saved[key]) == "table" then
      state[key] = adopt and saved[key] or Core[copier](saved[key])
    end
  end

  if type(saved.debug) == "table" then
    mergeNested(saved.debug, state.debug, {
      enabled = "boolean", mouseWatch = "boolean", sniffer = "boolean",
    })

    if type(saved.debug.maxLog) == "number" and saved.debug.maxLog >= 20 then
      state.debug.maxLog = saved.debug.maxLog
    end
  end

  if type(saved.goldTracker) == "table" then
    for _, key in ipairs(GOLD_TRACKER_KEYS) do
      local value = saved.goldTracker[key]
      if type(value) == "number" and value >= 0 then
        state.goldTracker[key] = math.floor(value)
      end
    end
  end

  if type(saved.button) == "table" then
    mergeNested(saved.button, state.button, {
      point = "nonEmptyString", relativePoint = "nonEmptyString", x = "number", y = "number",
    })
  end

  if type(saved.minimap) == "table" then
    mergeNested(saved.minimap, state.minimap, { shown = "boolean", angle = "number" })
  end

  if type(state.accountProfile) ~= "table" or type(state.accountProfile.savedSelections) ~= "table"
      or type(state.accountProfile.groups) ~= "table" then
    state.accountProfile = Core.copyAccountProfile(state.accountProfile)
  end

  return state
end

function Core.adoptState(saved)
  return Core.mergeState(saved, true)
end

local BOOLEAN_TRUE_WORDS = { on = true, ["true"] = true, yes = true }
local BOOLEAN_FALSE_WORDS = { off = true, ["false"] = true, no = true }

local function parseBoolean(rest, trueWord, falseWord)
  local lowered = rest:lower()

  if BOOLEAN_TRUE_WORDS[lowered] or (trueWord and lowered == trueWord) then
    return true
  end

  if BOOLEAN_FALSE_WORDS[lowered] or (falseWord and lowered == falseWord) then
    return false
  end

  return nil
end

local BOOLEAN_SETTING_COMMANDS = {
  accept = "autoAccept",
  autoacceptquests = "autoAcceptShared",
  autoacceptquest = "autoAcceptShared",
  shareaccept = "autoAcceptShared",
  sharedaccept = "autoAcceptShared",
  acceptshared = "autoAcceptShared",
  autoinstance = "autoCurrentInstanceQuest",
  currentinstance = "autoCurrentInstanceQuest",
  instancequest = "autoCurrentInstanceQuest",
}

local BOOLEAN_SETTING_USAGE = {
  autoAccept = "USAGE_ACCEPT",
  autoAcceptShared = "USAGE_AUTOACCEPTQUESTS",
  autoCurrentInstanceQuest = "USAGE_AUTOINSTANCE",
}

local SIMPLE_SLASH_KINDS = {
  help = "help", show = "show", hide = "hide", reset = "reset",
  quests = "quests", quest = "quests", roll = "roll", autoroll = "roll", stop = "stop",
}

local SIMPLE_SLASH_RESULTS = {
  export = { kind = "data", action = "export" },
  import = { kind = "data", action = "import" },
  etrace = { kind = "debug", action = "etrace" },
  eventtrace = { kind = "debug", action = "etrace" },
  inspect = { kind = "debug", action = "inspect" },
  dump = { kind = "debug", action = "dump" },
  cooldown = { kind = "debug", action = "cooldown" },
  cd = { kind = "debug", action = "cooldown" },
  log = { kind = "debug", action = "logs" },
  logs = { kind = "debug", action = "logs" },
  clearlogs = { kind = "debug", action = "clearlogs" },
}

function Core.parseSlash(input)
  local message = trim(input)

  if message == "" or message == "run" or message == "call" then
    return { kind = "run" }
  end

  local command, rest = message:match("^(%S+)%s*(.-)$")
  command = command and command:lower() or ""
  rest = trim(rest)

  local simpleKind = SIMPLE_SLASH_KINDS[command]
  if simpleKind then
    return { kind = simpleKind }
  end

  local simpleResult = SIMPLE_SLASH_RESULTS[command]
  if simpleResult then
    return { kind = simpleResult.kind, action = simpleResult.action }
  end

  if command == "minimap" then
    local shown = parseBoolean(rest, "show", "hide")

    if shown == nil then
      return { kind = "invalid", message = L.USAGE_MINIMAP }
    end

    return { kind = "minimap", shown = shown }
  end

  local booleanField = BOOLEAN_SETTING_COMMANDS[command]
  if booleanField then
    local value = parseBoolean(rest)

    if value == nil then
      return { kind = "invalid", message = L[BOOLEAN_SETTING_USAGE[booleanField]] }
    end

    return { kind = "set", field = booleanField, value = value }
  end

  if command == "name" then
    if rest == "" then
      return { kind = "invalid", message = L.USAGE_NAME }
    end

    return { kind = "set", field = "targetName", value = rest }
  end

  if command == "id" or command == "spellid" then
    local spellID = tonumber(rest)

    if not spellID then
      return { kind = "invalid", message = L.USAGE_ID }
    end

    return { kind = "set", field = "summonSpellID", value = spellID }
  end

  if command == "reroll" then
    if rest == "" then
      return { kind = "reroll" }
    end

    return { kind = "set", field = "rerollFrame", value = rest }
  end

  if command == "objective" or command == "obj" or command == "pick" then
    local index = tonumber(rest)

    if not index or index < 1 or index > 3 then
      return { kind = "invalid", message = L.USAGE_OBJECTIVE }
    end

    return { kind = "objective", index = index }
  end

  if command == "1" or command == "2" or command == "3" then
    return { kind = "objective", index = tonumber(command) }
  end

  if command == "buttonfield" then
    if rest == "" then
      return { kind = "invalid", message = L.USAGE_BUTTONFIELD }
    end

    return { kind = "set", field = "objectiveButtonField", value = rest }
  end

  if command == "maxrolls" then
    local value = tonumber(rest)

    if not value or value < 1 then
      return { kind = "invalid", message = L.USAGE_MAXROLLS }
    end

    return { kind = "set", field = "maxRerolls", value = math.floor(value) }
  end

  if command == "debug" then
    if rest == "" then
      return { kind = "debug", action = "open" }
    end

    local value = parseBoolean(rest)
    if value == nil then
      return { kind = "invalid", message = L.USAGE_DEBUG }
    end

    return { kind = "debug", action = "enabled", value = value }
  end

  if command == "watch" then
    local value = parseBoolean(rest)

    if value == nil then
      return { kind = "invalid", message = L.USAGE_WATCH }
    end

    return { kind = "debug", action = "mouseWatch", value = value }
  end

  if command == "sniff" or command == "sniffer" then
    local lowered = rest:lower()

    if rest == "" or lowered == "dump" then
      return { kind = "debug", action = "sniffDump" }
    end

    if lowered == "clear" then
      return { kind = "debug", action = "sniffClear" }
    end

    local value = parseBoolean(rest)
    if value == nil then
      return { kind = "invalid", message = L.USAGE_SNIFF }
    end

    return { kind = "debug", action = "sniffer", value = value }
  end

  return { kind = "unknown", message = L.CORE_UNKNOWN_COMMAND }
end

function Core.questTitle(quest)
  if type(quest) ~= "table" then
    return ""
  end

  return trim(quest.title)
end

function Core.objectiveText(quest)
  if type(quest) ~= "table" then
    return ""
  end

  local cleanText = objectiveTextParts(quest.objectiveText)
  return cleanText
end

local inferTypeCache = {}
local inferTypeCacheCount = 0
local INFER_TYPE_CACHE_MAX = 512

function Core.inferQuestType(quest)
  if type(quest) ~= "table" then
    return 0
  end

  local title = string.lower(Core.questTitle(quest))
  local objective = string.lower(Core.objectiveText(quest))
  local cacheKey = title .. "\1" .. objective
  local cached = inferTypeCache[cacheKey]

  if cached then
    return cached
  end

  local combined = trim(title .. " " .. objective)
  local questType = 0

  if containsAny(combined, PROFESSION_HINTS) then
    questType = 4
  elseif containsAny(combined, RAID_HINTS) then
    questType = 3
  elseif containsAny(combined, DUNGEON_HINTS) then
    questType = 2
  elseif containsAny(title, OPEN_WORLD_TITLE_PREFIXES)
      or string.find(objective, "^kill%s+%d+")
      or string.find(objective, "^collect%s+%d+%s+rare") then
    questType = 1
  end

  if inferTypeCacheCount >= INFER_TYPE_CACHE_MAX then
    inferTypeCache = {}
    inferTypeCacheCount = 0
  end

  inferTypeCache[cacheKey] = questType
  inferTypeCacheCount = inferTypeCacheCount + 1

  return questType
end

function Core.questKey(quest)
  if type(quest) ~= "table" then
    return nil
  end

  local questID = tonumber(quest.questId or quest.id)
  if questID and questID > 0 then
    return "id:" .. tostring(math.floor(questID))
  end

  local title = Core.questTitle(quest)
  if title == "" then
    return nil
  end

  return "title:" .. title:lower()
end

local QUEST_REWARD_FIELDS = {
  "normalSoulAshes",
  "hc1SoulAshes",
  "hc2SoulAshes",
  "hc3SoulAshes",
  "hc4SoulAshes",
  "normalXp",
  "hc1Xp",
  "hc2Xp",
  "hc3Xp",
  "hc4Xp",
}

local function copyRewardFields(target, source)
  for i = 1, #(QUEST_REWARD_FIELDS) do
    local field = QUEST_REWARD_FIELDS[i]
    target[field] = tonumber(source[field]) or 0
  end

  return target
end

local function buildQuestEntry(source, key, title, zoneOrSort, questType, seen, lastSeenRoll)
  return copyRewardFields({
    key = key,
    questId = tonumber(source.questId) or 0,
    title = title,
    objectiveText = Core.objectiveText(source),
    zoneOrSort = zoneOrSort,
    questType = questType,
    seen = seen,
    lastSeenRoll = lastSeenRoll,
  }, source)
end

function Core.copyQuest(quest)
  if type(quest) ~= "table" then
    return nil
  end

  local zoneOrSort, questType = Core.objectiveMetadata(quest)

  return buildQuestEntry(
    quest,
    quest.key,
    trim(quest.title),
    zoneOrSort,
    questType,
    tonumber(quest.seen) or 1,
    tonumber(quest.lastSeenRoll) or 0)
end

function Core.copyQuestList(quests)
  local copy = {}

  if type(quests) ~= "table" then
    return copy
  end

  local count = 0

  for i = 1, #(quests) do
    local entry = Core.copyQuest(quests[i])
    if entry then
      count = count + 1
      copy[count] = entry
    end
  end

  return copy
end

function Core.copyDesiredMap(desired)
  local copy = {}

  if type(desired) ~= "table" then
    return copy
  end

  for key, value in pairs(desired) do
    if type(key) == "string" and value == true then
      copy[key] = true
    end
  end

  return copy
end

function Core.desiredQuestCount(desired)
  local count = 0

  if type(desired) == "table" then
    for _, value in pairs(desired) do
      if value == true then
        count = count + 1
      end
    end
  end

  return count
end

function Core.questMatchesTypeFilter(quest, enabledQuestTypes)
  if not Core.hasEnabledQuestTypeFilter(enabledQuestTypes) then
    return true
  end

  local questType = tonumber(quest and quest.questType) or 0
  return Core.questTypeFilterEnabled(enabledQuestTypes, questType)
end

function Core.questTypeFilterEnabled(enabledQuestTypes, questType)
  if type(enabledQuestTypes) ~= "table" then
    return false
  end

  questType = tonumber(questType) or 0

  return enabledQuestTypes[questType] == true or enabledQuestTypes[tostring(questType)] == true
end

function Core.hasEnabledQuestTypeFilter(enabledQuestTypes)
  return hasEnabledValue(enabledQuestTypes)
end

function Core.hasAllPrimaryQuestTypeFilters(enabledQuestTypes)
  if type(enabledQuestTypes) ~= "table" then
    return false
  end

  return Core.questTypeFilterEnabled(enabledQuestTypes, 1)
      and Core.questTypeFilterEnabled(enabledQuestTypes, 2)
      and Core.questTypeFilterEnabled(enabledQuestTypes, 3)
      and Core.questTypeFilterEnabled(enabledQuestTypes, 4)
end

function Core.needsKnownTypeFallback(quests, enabledQuestTypes)
  if type(quests) ~= "table" or not Core.hasAllPrimaryQuestTypeFilters(enabledQuestTypes) then
    return false
  end

  if #(quests) == 0 then
    return false
  end

  local hasKnownType = false

  for i = 1, #(quests) do
    if Core.questMatchesTypeFilter(quests[i], enabledQuestTypes) then
      return false
    end

    if (tonumber(quests[i] and quests[i].questType) or 0) > 0 then
      hasKnownType = true
    end
  end

  return not hasKnownType
end

function Core.hasDesiredQuests(desired)
  return hasEnabledValue(desired)
end

function Core.countDesiredKnownQuests(quests, desired)
  local knownCount = 0
  local missingCount = 0
  local missingKeys = {}

  if type(desired) ~= "table" then
    return knownCount, missingCount, missingKeys
  end

  local present = {}

  if type(quests) == "table" then
    for i = 1, #(quests) do
      local quest = quests[i]
      local key = type(quest) == "table" and type(quest.key) == "string" and quest.key or Core.questKey(quest)

      if key then
        present[key] = true
      end
    end
  end

  for key, enabled in pairs(desired) do
    if enabled == true then
      if present[key] then
        knownCount = knownCount + 1
      else
        missingCount = missingCount + 1

        if #(missingKeys) < 3 then
          table.insert(missingKeys, tostring(key))
        end
      end
    end
  end

  return knownCount, missingCount, missingKeys
end

function Core.needsUntargetedRollConfirm(desired)
  return not Core.hasDesiredQuests(desired)
end

function Core.questTypeCounts(quests)
  local counts = {}

  if type(quests) ~= "table" then
    return counts
  end

  for i = 1, #(quests) do
    local questType = tonumber(quests[i] and quests[i].questType) or 0
    counts[questType] = (counts[questType] or 0) + 1
  end

  return counts
end

function Core.questInSelection(quest, selectedKeys)
  if type(selectedKeys) ~= "table" then
    return true
  end

  local key = type(quest) == "table" and type(quest.key) == "string" and quest.key or Core.questKey(quest)
  return key ~= nil and selectedKeys[key] == true
end

function Core.copyCharacterProfile(profile)
  local source = type(profile) == "table" and profile or {}
  local nextNumber = tonumber(source.nextSelectionNumber) or 1

  if nextNumber < 1 then
    nextNumber = 1
  end

  return {
    desiredQuests = Core.copyDesiredMap(source.desiredQuests),
    savedSelections = Core.copySelectionList(source.savedSelections),
    nextSelectionNumber = nextNumber,
    activeSelectionId = source.activeSelectionId,
  }
end

function Core.copyCharacterProfiles(profiles)
  local copy = {}

  if type(profiles) ~= "table" then
    return copy
  end

  for profileKey, profile in pairs(profiles) do
    if type(profileKey) == "string" and type(profile) == "table" then
      copy[profileKey] = Core.copyCharacterProfile(profile)
    end
  end

  return copy
end

Core.MIN_DIFFICULTY = 1
Core.MAX_DIFFICULTY = 6

function Core.sanitizeDifficulty(value)
  value = tonumber(value)

  if not value then
    return nil
  end

  value = math.floor(value)

  if value < Core.MIN_DIFFICULTY or value > Core.MAX_DIFFICULTY then
    return nil
  end

  return value
end

function Core.difficultyLabel(tier)
  tier = Core.sanitizeDifficulty(tier)

  if not tier then
    return L.DIFFICULTY_NONE
  end

  return L.DIFFICULTY_LABELS[tier]
end

Core.MAX_SAVED_SELECTIONS = 50
Core.MAX_GROUPS = 10
Core.MAX_SELECTION_NAME_LENGTH = 40

function Core.copySelection(selection)
  if type(selection) ~= "table" then
    return nil
  end

  return {
    id = selection.id,
    name = selection.name or L.SELECTION_DEFAULT_NAME,
    difficulty = Core.sanitizeDifficulty(selection.difficulty),
    groupId = tonumber(selection.groupId),
    desiredQuests = Core.copyDesiredMap(selection.desiredQuests),
  }
end

function Core.copySelectionList(list)
  local copy = {}

  if type(list) == "table" then
    for i = 1, #(list) do
      local entry = Core.copySelection(list[i])

      if entry then
        table.insert(copy, entry)
      end
    end
  end

  return copy
end

function Core.sanitizeSelectionName(name, fallback)
  local cleaned = trim(name)

  if cleaned == "" then
    cleaned = fallback or L.SELECTION_DEFAULT_NAME
  end

  if string.len(cleaned) > Core.MAX_SELECTION_NAME_LENGTH then
    cleaned = string.sub(cleaned, 1, Core.MAX_SELECTION_NAME_LENGTH)
  end

  return cleaned
end

function Core.copyGroup(group)
  if type(group) ~= "table" then
    return nil
  end

  local id = tonumber(group.id)
  if not id then
    return nil
  end

  return {
    id = math.floor(id),
    name = Core.sanitizeSelectionName(group.name, L.GROUP_DEFAULT_NAME),
  }
end

function Core.copyGroupList(list)
  local copy = {}

  if type(list) == "table" then
    for i = 1, #(list) do
      local entry = Core.copyGroup(list[i])

      if entry and #(copy) < Core.MAX_GROUPS then
        table.insert(copy, entry)
      end
    end
  end

  return copy
end

function Core.copyAccountProfile(profile)
  local source = type(profile) == "table" and profile or {}
  local nextSelection = tonumber(source.nextSelectionNumber) or 1
  local nextGroup = tonumber(source.nextGroupNumber) or 1

  if nextSelection < 1 then
    nextSelection = 1
  end

  if nextGroup < 1 then
    nextGroup = 1
  end

  return {
    savedSelections = Core.copySelectionList(source.savedSelections),
    groups = Core.copyGroupList(source.groups),
    nextSelectionNumber = math.floor(nextSelection),
    nextGroupNumber = math.floor(nextGroup),
  }
end

local ECHO_BAR_SLOTS = 3
local ECHO_BAR_DEFAULTS = {
  enabled = false,
  locked = false,
  orientation = "H",
  point = "CENTER",
  relativePoint = "CENTER",
  x = 0,
  y = -200,
}
local ECHO_BAR_SPEC = {
  enabled = "boolean",
  locked = "boolean",
  orientation = "nonEmptyString",
  point = "nonEmptyString",
  relativePoint = "nonEmptyString",
  x = "number",
  y = "number",
}

Core.ECHO_BAR_SLOTS = ECHO_BAR_SLOTS

function Core.copyEchoBar(source)
  local bar = { slots = {} }

  for key, value in pairs(ECHO_BAR_DEFAULTS) do
    bar[key] = value
  end

  if type(source) ~= "table" then
    return bar
  end

  mergeNested(source, bar, ECHO_BAR_SPEC)

  if bar.orientation ~= "V" then
    bar.orientation = "H"
  end

  if type(source.slots) == "table" then
    local seen = {}

    for i = 1, ECHO_BAR_SLOTS do
      local slot = tonumber(source.slots[i])

      if slot and slot >= 1 and not seen[slot] then
        seen[slot] = true
        bar.slots[i] = math.floor(slot)
      end
    end
  end

  return bar
end

function Core.copyCharacterState(entry)
  local source = type(entry) == "table" and entry or {}

  return {
    desiredQuests = Core.copyDesiredMap(source.desiredQuests),
    activeSelectionId = tonumber(source.activeSelectionId),
    openGroupId = tonumber(source.openGroupId),
    echoBar = Core.copyEchoBar(source.echoBar),
  }
end

function Core.copyCharacterStateMap(states)
  local copy = {}

  if type(states) == "table" then
    for key, entry in pairs(states) do
      if type(key) == "string" and type(entry) == "table" then
        copy[key] = Core.copyCharacterState(entry)
      end
    end
  end

  return copy
end

local function sameContainer(selectionGroupId, groupId)
  return (tonumber(selectionGroupId) or 0) == (tonumber(groupId) or 0)
end

Core.sameContainer = sameContainer

function Core.selectionsInContainer(profile, groupId)
  local entries = {}

  if type(profile) ~= "table" or type(profile.savedSelections) ~= "table" then
    return entries
  end

  for i = 1, #(profile.savedSelections) do
    local entry = profile.savedSelections[i]
    if sameContainer(entry.groupId, groupId) then
      table.insert(entries, entry)
    end
  end

  return entries
end

function Core.selectionCount(profile, groupId)
  if type(profile) ~= "table" or type(profile.savedSelections) ~= "table" then
    return 0
  end

  local count = 0

  for i = 1, #(profile.savedSelections) do
    if sameContainer(profile.savedSelections[i].groupId, groupId) then
      count = count + 1
    end
  end

  return count
end

function Core.selectionsFull(profile, groupId)
  return Core.selectionCount(profile, groupId) >= Core.MAX_SAVED_SELECTIONS
end

function Core.peekNextSelectionName(profile)
  local nextNumber = type(profile) == "table" and tonumber(profile.nextSelectionNumber) or 1
  return string.format(L.SELECTION_NUMBERED_NAME, tostring(nextNumber or 1))
end

function Core.findSelectionIndex(profile, id)
  if type(profile) ~= "table" or type(profile.savedSelections) ~= "table" or id == nil then
    return nil
  end

  for i = 1, #(profile.savedSelections) do
    if profile.savedSelections[i].id == id then
      return i
    end
  end

  return nil
end

function Core.findSelection(profile, id)
  local index = Core.findSelectionIndex(profile, id)

  if not index then
    return nil
  end

  return profile.savedSelections[index]
end

function Core.createSelection(profile, desiredQuests, name, groupId)
  local nextProfile = Core.copyAccountProfile(profile)

  if Core.selectionsFull(nextProfile, groupId) then
    return nextProfile, nil, "full"
  end

  local number = nextProfile.nextSelectionNumber
  nextProfile.nextSelectionNumber = number + 1

  local entry = {
    id = number,
    name = Core.sanitizeSelectionName(name, string.format(L.SELECTION_NUMBERED_NAME, tostring(number))),
    groupId = tonumber(groupId),
    desiredQuests = Core.copyDesiredMap(desiredQuests),
  }

  table.insert(nextProfile.savedSelections, entry)

  return nextProfile, entry, nil
end

function Core.renameSelection(profile, id, newName)
  local nextProfile = Core.copyAccountProfile(profile)
  local index = Core.findSelectionIndex(nextProfile, id)

  if not index then
    return nextProfile, false
  end

  nextProfile.savedSelections[index].name = Core.sanitizeSelectionName(newName, nextProfile.savedSelections[index].name)

  return nextProfile, true
end

function Core.setSelectionDifficulty(profile, id, tier)
  local nextProfile = Core.copyAccountProfile(profile)
  local index = Core.findSelectionIndex(nextProfile, id)

  if not index then
    return nextProfile, false
  end

  nextProfile.savedSelections[index].difficulty = Core.sanitizeDifficulty(tier)

  return nextProfile, true
end

function Core.updateSelectionContent(profile, id, desiredQuests)
  local nextProfile = Core.copyAccountProfile(profile)
  local index = Core.findSelectionIndex(nextProfile, id)

  if not index then
    return nextProfile, false
  end

  nextProfile.savedSelections[index].desiredQuests = Core.copyDesiredMap(desiredQuests)

  return nextProfile, true
end

function Core.deleteSelection(profile, id)
  local nextProfile = Core.copyAccountProfile(profile)
  local index = Core.findSelectionIndex(nextProfile, id)

  if not index then
    return nextProfile, false
  end

  table.remove(nextProfile.savedSelections, index)

  return nextProfile, true
end

function Core.setSelectionGroup(profile, id, groupId)
  local nextProfile = Core.copyAccountProfile(profile)
  local index = Core.findSelectionIndex(nextProfile, id)

  if not index then
    return nextProfile, false
  end

  groupId = tonumber(groupId)

  if groupId and not Core.findGroupIndex(nextProfile, groupId) then
    return nextProfile, false
  end

  if sameContainer(nextProfile.savedSelections[index].groupId, groupId) then
    return nextProfile, true
  end

  if Core.selectionsFull(nextProfile, groupId) then
    return nextProfile, false, "full"
  end

  nextProfile.savedSelections[index].groupId = groupId

  return nextProfile, true
end

function Core.moveSelectionTo(profile, id, groupId, beforeId)
  local nextProfile = Core.copyAccountProfile(profile)
  local index = Core.findSelectionIndex(nextProfile, id)

  if not index then
    return nextProfile, false
  end

  if beforeId == id then
    return nextProfile, true
  end

  groupId = tonumber(groupId)

  local entry = nextProfile.savedSelections[index]
  local movingIn = not sameContainer(entry.groupId, groupId)

  if movingIn and Core.selectionsFull(nextProfile, groupId) then
    return nextProfile, false, "full"
  end

  table.remove(nextProfile.savedSelections, index)
  entry.groupId = groupId

  local target

  if beforeId ~= nil then
    target = Core.findSelectionIndex(nextProfile, beforeId)
  end

  if not target then
    target = #(nextProfile.savedSelections) + 1

    for i = #(nextProfile.savedSelections), 1, -1 do
      if sameContainer(nextProfile.savedSelections[i].groupId, groupId) then
        target = i + 1
        break
      end
    end
  end

  table.insert(nextProfile.savedSelections, target, entry)

  return nextProfile, true
end

function Core.findGroupIndex(profile, id)
  if type(profile) ~= "table" or type(profile.groups) ~= "table" or id == nil then
    return nil
  end

  for i = 1, #(profile.groups) do
    if profile.groups[i].id == id then
      return i
    end
  end

  return nil
end

function Core.findGroup(profile, id)
  local index = Core.findGroupIndex(profile, id)

  if not index then
    return nil
  end

  return profile.groups[index]
end

function Core.groupCount(profile)
  if type(profile) ~= "table" or type(profile.groups) ~= "table" then
    return 0
  end

  return #(profile.groups)
end

function Core.groupsFull(profile)
  return Core.groupCount(profile) >= Core.MAX_GROUPS
end

function Core.peekNextGroupName(profile)
  local nextNumber = type(profile) == "table" and tonumber(profile.nextGroupNumber) or 1
  return string.format(L.GROUP_NUMBERED_NAME, tostring(nextNumber or 1))
end

function Core.createGroup(profile, name)
  local nextProfile = Core.copyAccountProfile(profile)

  if Core.groupsFull(nextProfile) then
    return nextProfile, nil, "full"
  end

  local number = nextProfile.nextGroupNumber
  nextProfile.nextGroupNumber = number + 1

  local entry = {
    id = number,
    name = Core.sanitizeSelectionName(name, string.format(L.GROUP_NUMBERED_NAME, tostring(number))),
  }

  table.insert(nextProfile.groups, entry)

  return nextProfile, entry, nil
end

function Core.moveGroupToIndex(profile, id, index)
  local nextProfile = Core.copyAccountProfile(profile)
  local from = Core.findGroupIndex(nextProfile, id)

  if not from then
    return nextProfile, false
  end

  local count = #(nextProfile.groups)
  index = math.floor(tonumber(index) or from)

  if index < 1 then
    index = 1
  end

  if index > count then
    index = count
  end

  if index == from then
    return nextProfile, true
  end

  table.insert(nextProfile.groups, index, table.remove(nextProfile.groups, from))

  return nextProfile, true
end

function Core.renameGroup(profile, id, newName)
  local nextProfile = Core.copyAccountProfile(profile)
  local index = Core.findGroupIndex(nextProfile, id)

  if not index then
    return nextProfile, false
  end

  nextProfile.groups[index].name = Core.sanitizeSelectionName(newName, nextProfile.groups[index].name)

  return nextProfile, true
end

function Core.groupSelectionNames(profile, groupId, limit)
  local entries = Core.selectionsInContainer(profile, groupId)
  local names = {}

  limit = tonumber(limit) or 3

  for i = 1, #(entries) do
    if i > limit then
      break
    end

    table.insert(names, tostring(entries[i].name or ""))
  end

  return names, math.max(0, #(entries) - #(names))
end

function Core.deleteGroup(profile, id)
  local nextProfile = Core.copyAccountProfile(profile)
  local index = Core.findGroupIndex(nextProfile, id)

  if not index then
    return nextProfile, false
  end

  local groupId = nextProfile.groups[index].id
  table.remove(nextProfile.groups, index)

  for i = #(nextProfile.savedSelections), 1, -1 do
    if sameContainer(nextProfile.savedSelections[i].groupId, groupId) then
      table.remove(nextProfile.savedSelections, i)
    end
  end

  return nextProfile, true
end

function Core.characterSelectionCount(characterProfile)
  if type(characterProfile) ~= "table" or type(characterProfile.savedSelections) ~= "table" then
    return 0
  end

  return #(characterProfile.savedSelections)
end

function Core.importSelections(profile, selections, groupId)
  local nextProfile = Core.copyAccountProfile(profile)
  local incoming = Core.copySelectionList(selections)
  local idMap = {}

  groupId = tonumber(groupId)

  for i = 1, #(incoming) do
    local entry = incoming[i]
    local previousId = entry.id
    local number = nextProfile.nextSelectionNumber

    nextProfile.nextSelectionNumber = number + 1
    entry.id = number
    entry.groupId = groupId

    if previousId ~= nil then
      idMap[previousId] = number
    end

    table.insert(nextProfile.savedSelections, entry)
  end

  return nextProfile, idMap
end

function Core.buildMigratedCharacterState(characterProfile, idMap, groupId)
  local source = type(characterProfile) == "table" and characterProfile or {}
  local activeId = source.activeSelectionId

  if activeId ~= nil and type(idMap) == "table" then
    activeId = idMap[activeId]
  else
    activeId = nil
  end

  return {
    desiredQuests = Core.copyDesiredMap(source.desiredQuests),
    activeSelectionId = tonumber(activeId),
    openGroupId = tonumber(groupId),
  }
end

function Core.migrateLegacyPresets(state, legacyDB)
  if type(state) ~= "table" then
    state = Core.defaultState()
  end

  if type(legacyDB) ~= "table" or type(legacyDB.characters) ~= "table" then
    return state
  end

  local nextState = Core.mergeState(state)
  nextState.presetsMigrated = true

  for characterKey, legacyProfile in pairs(legacyDB.characters) do
    if type(characterKey) == "string" and type(legacyProfile) == "table" then
      local profile = Core.copyCharacterProfile(nextState.characterProfiles[characterKey])
      local legacySelections = Core.copySelectionList(legacyProfile.selections)

      if #(legacySelections) > 0 and #(profile.savedSelections) == 0 then
        profile.savedSelections = legacySelections
        profile.nextSelectionNumber = tonumber(legacyProfile.nextNumber) or (#(legacySelections) + 1)
        profile.activeSelectionId = legacyProfile.activeSelectionId
      end

      nextState.characterProfiles[characterKey] = profile
    end
  end

  return nextState
end

function Core.objectiveMetadata(objective)
  local _, parsedZone, parsedType = objectiveTextParts(objective and objective.objectiveText)
  parsedZone = tonumber(parsedZone) or 0
  parsedType = Core.sanitizeQuestType(parsedType)

  local storedZone = tonumber(objective and objective.zoneOrSort) or 0
  local storedType = Core.sanitizeQuestType(objective and objective.questType)

  local zoneOrSort = parsedZone > 0 and parsedZone or storedZone
  local questType = parsedType > 0 and parsedType or storedType

  if questType == 0 then
    questType = Core.inferQuestType(objective)
  end

  return zoneOrSort, questType
end

function Core.describeObjectiveMetadata(objective)
  local cleanText, parsedZone, parsedType = objectiveTextParts(objective and objective.objectiveText)
  local rawType = tonumber(objective and objective.questType) or 0
  local sanitizedRawType = Core.sanitizeQuestType(rawType)
  local finalZone, finalType = Core.objectiveMetadata(objective)

  return {
    rawText = trim(objective and objective.objectiveText),
    cleanText = cleanText,
    rawZone = tonumber(objective and objective.zoneOrSort) or 0,
    rawType = rawType,
    rawTypeRejected = rawType ~= 0 and sanitizedRawType == 0,
    hasSuffix = (tonumber(parsedZone) or 0) > 0 or Core.sanitizeQuestType(parsedType) > 0,
    suffixZone = tonumber(parsedZone) or 0,
    suffixType = Core.sanitizeQuestType(parsedType),
    finalZone = finalZone,
    finalType = finalType,
  }
end

local function byTitle(a, b)
  return (a.title or "") < (b.title or "")
end

function Core.captureKnownQuests(existing, objectives, rollCount, adopt)
  local known = (adopt and type(existing) == "table") and existing or Core.copyQuestList(existing)

  if not Core.isObjectiveChoiceList(objectives) then
    return known
  end

  local indexByKey = {}
  local inserted = false

  for i = 1, #(known) do
    if type(known[i].key) == "string" then
      indexByKey[known[i].key] = i
    end
  end

  for i = 1, #(objectives) do
    local objective = objectives[i]
    local key = Core.questKey(objective)
    local title = Core.questTitle(objective)

    if key and title ~= "" then
      local zoneOrSort, questType = Core.objectiveMetadata(objective)
      local entry = indexByKey[key] and known[indexByKey[key]]

      if entry then
        entry.seen = (entry.seen or 0) + 1
        entry.lastSeenRoll = rollCount or entry.lastSeenRoll or 0
        entry.objectiveText = Core.objectiveText(objective)
        entry.zoneOrSort = zoneOrSort > 0 and zoneOrSort or entry.zoneOrSort or 0
        entry.questType = questType > 0 and questType or entry.questType or 0
        copyRewardFields(entry, objective)
      else
        table.insert(known, buildQuestEntry(
          objective, key, title, zoneOrSort, questType, 1, rollCount or 0))
        indexByKey[key] = #(known)
        inserted = true
      end
    end
  end

  if inserted then
    table.sort(known, byTitle)
  end

  return known
end

function Core.isObjectiveChoiceList(objectives)
  if type(objectives) ~= "table" or #(objectives) < 3 then
    return false
  end

  for i = 1, 3 do
    if Core.questKey(objectives[i]) == nil or Core.questTitle(objectives[i]) == "" then
      return false
    end
  end

  return true
end

local function encodeField(value)
  value = tostring(value or "")
  value = value:gsub("%%", "%%%%")
  value = value:gsub("|", "%%p")
  value = value:gsub("%^", "%%h")
  value = value:gsub("\t", "%%t")
  value = value:gsub("\r", "%%r")
  value = value:gsub("\n", "%%n")

  return value
end

local function decodeField(value)
  value = tostring(value or "")

  return (value:gsub("%%([nrt%%ph])", {
    n = "\n",
    r = "\r",
    t = "\t",
    ["%"] = "%",
    p = "|",
    h = "^",
  }))
end

local function importMarker(line)
  return trim(tostring(line or ""):gsub("^\239\187\191", ""))
end

local function splitPlain(value, separator)
  local fields = {}
  local startIndex = 1

  while true do
    local separatorStart, separatorEnd = string.find(value, separator, startIndex, true)
    if not separatorStart then
      table.insert(fields, string.sub(value, startIndex))
      break
    end

    table.insert(fields, string.sub(value, startIndex, separatorStart - 1))
    startIndex = separatorEnd + 1
  end

  return fields
end

local function countPlain(value, needle)
  local count = 0
  local startIndex = 1

  while true do
    local matchStart, matchEnd = string.find(value, needle, startIndex, true)
    if not matchStart then
      break
    end

    count = count + 1
    startIndex = matchEnd + 1
  end

  return count
end

local QUEST_EXPORT_FIELDS = {
  "key",
  "questId",
  "title",
  "objectiveText",
  "zoneOrSort",
  "questType",
  "normalSoulAshes",
  "hc1SoulAshes",
  "hc2SoulAshes",
  "hc3SoulAshes",
  "hc4SoulAshes",
  "normalXp",
  "hc1Xp",
  "hc2Xp",
  "hc3Xp",
  "hc4Xp",
  "seen",
  "lastSeenRoll",
}

function Core.exportKnownQuestText(quests)
  local lines = { "ACBQUESTS3" }
  local cleanQuests = Core.copyQuestList(quests)

  for i = 1, #(cleanQuests) do
    local quest = cleanQuests[i]
    local fields = {}

    for fieldIndex = 1, #(QUEST_EXPORT_FIELDS) do
      table.insert(fields, encodeField(quest[QUEST_EXPORT_FIELDS[fieldIndex]]))
    end

    table.insert(lines, table.concat(fields, " ^ "))
  end

  return table.concat(lines, "\n")
end

local function decodeFields(fields)
  for i = 1, #(fields) do
    fields[i] = decodeField(fields[i])
  end

  return fields
end

local function splitQuestImportFields(line, marker)
  local fields

  if marker == "ACBQUESTS1" then
    return decodeFields(splitPlain(line, "\t")), "ACBQUESTS1"
  end

  if marker == "ACBQUESTS3" then
    return decodeFields(splitPlain(line, " ^ ")), "ACBQUESTS3"
  end

  fields = splitPlain(line, " | ")
  if marker == "ACBQUESTS2" or #(fields) >= #(QUEST_EXPORT_FIELDS) then
    if #(fields) < #(QUEST_EXPORT_FIELDS) then
      fields = splitPlain(line, " // ")
    end

    return decodeFields(fields), "ACBQUESTS2"
  end

  fields = splitPlain(line, " ^ ")
  if #(fields) >= #(QUEST_EXPORT_FIELDS) then
    return decodeFields(fields), "ACBQUESTS3"
  end

  fields = splitPlain(line, " // ")
  if #(fields) >= #(QUEST_EXPORT_FIELDS) then
    return decodeFields(fields), "ACBQUESTS2"
  end

  fields = splitPlain(line, "\t")
  if #(fields) < #(QUEST_EXPORT_FIELDS) then
    return fields, nil
  end

  return decodeFields(fields), "ACBQUESTS1"
end

function Core.analyzeQuestImportText(text)
  local info = {
    textLength = type(text) == "string" and string.len(text) or 0,
    fieldCount = #(QUEST_EXPORT_FIELDS),
    lineCount = 0,
    nonEmptyLineCount = 0,
    marker = nil,
    markerLine = 0,
    dataLineCount = 0,
    importableLineCount = 0,
    invalidLineCount = 0,
    firstLine = "",
    samples = {},
  }

  if type(text) ~= "string" or trim(text) == "" then
    return info
  end

  local marker = nil
  local stopped = false

  for line in string.gmatch(text .. "\n", "([^\r\n]*)\r?\n") do
    info.lineCount = info.lineCount + 1

    local cleanLine = importMarker(line)
    local trimmedLine = trim(line)
    if info.firstLine == "" and trimmedLine ~= "" then
      info.firstLine = cleanLine
    end

    if cleanLine == "```" and (marker or info.dataLineCount > 0) then
      stopped = true
      break
    elseif cleanLine == "ACBQUESTS1" or cleanLine == "ACBQUESTS2" or cleanLine == "ACBQUESTS3" then
      marker = cleanLine
      info.marker = cleanLine
      info.markerLine = info.lineCount
      info.nonEmptyLineCount = info.nonEmptyLineCount + 1
    elseif trimmedLine ~= "" and string.sub(cleanLine, 1, 3) ~= "```" then
      info.nonEmptyLineCount = info.nonEmptyLineCount + 1
      info.dataLineCount = info.dataLineCount + 1

      local v3Fields = #(splitPlain(line, " ^ "))
      local v2Fields = #(splitPlain(line, " | "))
      local slashFields = #(splitPlain(line, " // "))
      local v1Fields = #(splitPlain(line, "\t"))
      local rawFields, inferredMarker = splitQuestImportFields(line, marker)
      local activeFields = #(rawFields)
      local importable = activeFields >= info.fieldCount

      if importable then
        info.importableLineCount = info.importableLineCount + 1
      else
        info.invalidLineCount = info.invalidLineCount + 1
      end

      if #(info.samples) < 5 then
        table.insert(info.samples, {
          line = info.lineCount,
          length = string.len(line),
          marker = marker or inferredMarker or "none",
          v3Separators = countPlain(line, " ^ "),
          v2Separators = countPlain(line, " | "),
          slashSeparators = countPlain(line, " // "),
          tabSeparators = countPlain(line, "\t"),
          v3Fields = v3Fields,
          v2Fields = v2Fields,
          slashFields = slashFields,
          v1Fields = v1Fields,
          activeFields = activeFields,
          importable = importable,
          preview = cleanLine,
        })
      end
    end
  end

  info.stoppedAtFence = stopped

  return info
end

function Core.importKnownQuestText(text)
  local quests = {}
  local imported = 0
  local skipped = 0

  if type(text) ~= "string" or trim(text) == "" then
    return quests, imported, skipped + 1
  end

  local marker = nil

  for line in string.gmatch(text .. "\n", "([^\r\n]*)\r?\n") do
    local cleanLine = importMarker(line)

    if cleanLine == "```" and (marker or imported > 0) then
      break
    elseif cleanLine == "ACBQUESTS1" or cleanLine == "ACBQUESTS2" or cleanLine == "ACBQUESTS3" then
      marker = cleanLine
    elseif trim(line) ~= "" and string.sub(cleanLine, 1, 3) ~= "```" then
      local rawFields, inferredMarker = splitQuestImportFields(line, marker)

      if #(rawFields) >= #(QUEST_EXPORT_FIELDS) then
        marker = marker or inferredMarker
        local quest = {}

        for fieldIndex = 1, #(QUEST_EXPORT_FIELDS) do
          quest[QUEST_EXPORT_FIELDS[fieldIndex]] = rawFields[fieldIndex]
        end

        local cleanQuest = Core.copyQuest(quest)
        if cleanQuest and Core.questKey(cleanQuest) then
          table.insert(quests, cleanQuest)
          imported = imported + 1
        else
          skipped = skipped + 1
        end
      elseif marker or imported > 0 then
        skipped = skipped + 1
      end
    end
  end

  if not marker and imported == 0 then
    return quests, imported, skipped + 1
  end

  return quests, imported, skipped
end

function Core.mergeKnownQuestLists(existing, incoming)
  local merged = Core.copyQuestList(existing)
  local indexByKey = {}

  for i = 1, #(merged) do
    if type(merged[i].key) == "string" then
      indexByKey[merged[i].key] = i
    end
  end

  local cleanIncoming = Core.copyQuestList(incoming)

  for i = 1, #(cleanIncoming) do
    local quest = cleanIncoming[i]
    local key = type(quest.key) == "string" and quest.key ~= "" and quest.key or Core.questKey(quest)
    local existingIndex = key and indexByKey[key]

    if existingIndex then
      quest.seen = math.max(tonumber(merged[existingIndex].seen) or 0, tonumber(quest.seen) or 0)
      quest.lastSeenRoll = math.max(tonumber(merged[existingIndex].lastSeenRoll) or 0, tonumber(quest.lastSeenRoll) or 0)
      merged[existingIndex] = quest
    elseif key then
      table.insert(merged, quest)
      indexByKey[key] = #(merged)
    end
  end

  table.sort(merged, byTitle)

  return merged
end

function Core.questStateBackup(currentState)
  local state = Core.mergeState(currentState)

  return {
    schemaVersion = 1,
    knownQuests = state.knownQuests,
    desiredQuests = state.desiredQuests,
    characterProfiles = state.characterProfiles,
  }
end

function Core.restoreQuestState(savedState, questBackup)
  local state = Core.mergeState(savedState)

  if type(questBackup) ~= "table" then
    return state
  end

  local backup = Core.questStateBackup(questBackup)
  state.knownQuests = Core.mergeKnownQuestLists(backup.knownQuests, state.knownQuests)

  if not Core.hasDesiredQuests(state.desiredQuests) then
    state.desiredQuests = Core.copyDesiredMap(backup.desiredQuests)
  end

  local currentProfiles = Core.copyCharacterProfiles(state.characterProfiles)
  state.characterProfiles = Core.copyCharacterProfiles(backup.characterProfiles)
  for profileKey, profile in pairs(currentProfiles) do
    state.characterProfiles[profileKey] = Core.copyCharacterProfile(profile)
  end

  return state
end

function Core.resetSettingsPreservingQuestState(currentState)
  local current = Core.mergeState(currentState)
  local reset = Core.defaultState()

  reset.knownQuests = Core.copyQuestList(current.knownQuests)
  reset.desiredQuests = Core.copyDesiredMap(current.desiredQuests)
  reset.characterProfiles = Core.copyCharacterProfiles(current.characterProfiles)
  reset.accountProfile = Core.copyAccountProfile(current.accountProfile)
  reset.characterState = Core.copyCharacterStateMap(current.characterState)
  reset.migratedCharacters = Core.copyDesiredMap(current.migratedCharacters)
  reset.accountListSeeded = current.accountListSeeded == true

  return reset
end

function Core.normalizeSharedQuestPlayerName(name)
  local normalized = string.lower(trim(name))
  normalized = string.gsub(normalized, "%-.*$", "")
  return normalized
end

function Core.normalizeSharedQuestTitle(title)
  return string.gsub(string.lower(trim(title)), "%s+", " ")
end

function Core.buildSharedQuestAnnouncement(questID, title)
  questID = math.floor(tonumber(questID) or 0)
  title = string.gsub(trim(title), "[\r\n\t]", " ")
  title = string.sub(title, 1, 200)

  if questID <= 0 or title == "" then
    return nil
  end

  return "SHARE\t" .. tostring(questID) .. "\t" .. title
end

function Core.parseSharedQuestAnnouncement(message)
  if type(message) ~= "string" then
    return nil
  end

  local questID, title = string.match(message, "^SHARE\t(%d+)\t(.+)$")
  questID = math.floor(tonumber(questID) or 0)
  title = trim(title)

  if questID <= 0 or title == "" then
    return nil
  end

  return questID, title
end

function Core.consumeSharedQuestOffer(offers, title, sourceName, now)
  local remaining = {}
  local matched
  local wantedTitle = Core.normalizeSharedQuestTitle(title)
  local wantedSender = Core.normalizeSharedQuestPlayerName(sourceName)
  now = tonumber(now) or 0

  if type(offers) ~= "table" then
    return remaining, nil
  end

  for i = 1, #(offers) do
    local offer = offers[i]
    if type(offer) == "table" then
      local expiresAt = tonumber(offer.expiresAt) or 0
      local isFresh = expiresAt <= 0 or now <= expiresAt
      local isMatch = not matched
        and isFresh
        and wantedTitle ~= ""
        and wantedSender ~= ""
        and Core.normalizeSharedQuestTitle(offer.title) == wantedTitle
        and Core.normalizeSharedQuestPlayerName(offer.sender) == wantedSender

      if isMatch then
        matched = {
          questID = tonumber(offer.questID) or 0,
          title = trim(offer.title),
          sender = trim(offer.sender),
          expiresAt = expiresAt,
        }
      elseif isFresh then
        table.insert(remaining, {
          questID = tonumber(offer.questID) or 0,
          title = trim(offer.title),
          sender = trim(offer.sender),
          expiresAt = expiresAt,
        })
      end
    end
  end

  return remaining, matched
end

function Core.currentInstanceQuestType(instanceType)
  instanceType = normalizeMatchText(instanceType)

  if instanceType == "party" then
    return 2
  end

  if instanceType == "raid" then
    return 3
  end

  return 0
end

function Core.buildCurrentInstanceTarget(info)
  if type(info) ~= "table" then
    return nil
  end

  if info.builtTarget then
    return info
  end

  local questType = Core.sanitizeQuestType(info.questType)
  if questType == 0 then
    questType = Core.currentInstanceQuestType(info.instanceType)
  end

  if questType ~= 2 and questType ~= 3 then
    return nil
  end

  local aliases = {}
  local seen = {}
  appendUniqueNormalized(aliases, seen, info.name)
  appendUniqueNormalized(aliases, seen, info.realZoneText)
  appendUniqueNormalized(aliases, seen, info.zoneText)
  appendUniqueNormalized(aliases, seen, info.minimapZoneText)

  if type(info.names) == "table" then
    for i = 1, #(info.names) do
      appendUniqueNormalized(aliases, seen, info.names[i])
    end
  end

  if type(info.aliases) == "table" then
    for i = 1, #(info.aliases) do
      appendUniqueNormalized(aliases, seen, info.aliases[i])
    end
  end

  local originalCount = #(aliases)
  for i = 1, originalCount do
    local alias = aliases[i]
    local mappedAliases = findInstanceAliases(alias)
    if type(mappedAliases) == "table" then
      for j = 1, #(mappedAliases) do
        appendUniqueNormalized(aliases, seen, mappedAliases[j])
      end
    end
  end

  if #(aliases) == 0 then
    return nil
  end

  return {
    builtTarget = true,
    instanceType = trim(info.instanceType),
    name = trim(info.name) ~= "" and trim(info.name) or aliases[1],
    questType = questType,
    aliases = aliases,
  }
end

local function aliasMatchesQuestText(alias, combined, compactCombined)
  if alias == "" then
    return false
  end

  if string.find(combined, alias, 1, true) then
    return true
  end

  local isSingleWord = not string.find(alias, " ", 1, true)

  return isSingleWord and string.find(compactCombined, alias, 1, true) ~= nil
end

local function questMatchesBuiltTarget(quest, target)
  if type(quest) ~= "table" or not target then
    return false
  end

  local _, questType = Core.objectiveMetadata(quest)
  if questType ~= target.questType then
    return false
  end

  local combined = normalizeMatchText(Core.questTitle(quest) .. " " .. Core.objectiveText(quest))
  local compactCombined = compactMatchText(combined)

  for i = 1, #(target.aliases) do
    local alias = target.aliases[i]
    if aliasMatchesQuestText(alias, combined, compactCombined) then
      return true, alias
    end
  end

  return false
end

local function findObjectiveForBuiltTarget(objectives, target)
  if not Core.isObjectiveChoiceList(objectives) or not target then
    return nil
  end

  for i = 1, #(objectives) do
    local matched, alias = questMatchesBuiltTarget(objectives[i], target)
    if matched then
      return {
        index = i,
        key = Core.questKey(objectives[i]),
        quest = objectives[i],
        source = "currentInstance",
        label = L.MATCH_LABEL_CURRENT_INSTANCE,
        matchedAlias = alias,
        questType = target.questType,
        target = target,
      }
    end
  end

  return nil
end

function Core.findDesiredObjective(objectives, desired)
  if not Core.isObjectiveChoiceList(objectives) or type(desired) ~= "table" then
    return nil
  end

  for i = 1, #(objectives) do
    local key = Core.questKey(objectives[i])
    if key and desired[key] then
      return {
        index = i,
        key = key,
        quest = objectives[i],
      }
    end
  end

  return nil
end

function Core.findRollObjective(objectives, desired, currentInstanceTarget)
  local target = Core.buildCurrentInstanceTarget(currentInstanceTarget)

  if target then
    return findObjectiveForBuiltTarget(objectives, target)
  end

  return Core.findDesiredObjective(objectives, desired)
end

function Core.shouldHoldObjectiveChoices(isRolling, pauseReason, hasSelectedQuest)
  return isRolling == true and pauseReason == "quest_selected" and hasSelectedQuest == true
end

function Core.shouldPauseForAcceptedQuest(isRolling, questID)
  return isRolling == true and (tonumber(questID) or 0) > 0
end

AutoCallboardCore = Core
