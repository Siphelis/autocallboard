local Core = AutoCallboardCore or {}
AutoCallboardCore = Core
local L = AutoCallboardLocale

local type, tonumber, tostring, pairs = type, tonumber, tostring, pairs
local string, table, math = string, table, math

local trim = Core.trim or function(value)
  if type(value) ~= "string" then
    return ""
  end
  return (value:match("^%s*(.-)%s*$"))
end

local mergeNested = Core.mergeNested or function(saved, state, spec)
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
    toolbar = Core.copyToolbar and Core.copyToolbar(source.toolbar) or nil,
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
