local Core = AutoCallboardCore or {}
AutoCallboardCore = Core
local L = AutoCallboardLocale

local type, tonumber, tostring, pairs = type, tonumber, tostring, pairs
local string, table, math = string, table, math

local trim = Core.trim
local normalizeMatchText = Core.normalizeMatchText
local compactMatchText = Core.compactMatchText
local appendUniqueNormalized = Core.appendUniqueNormalized

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
