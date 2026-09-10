local Core = AutoCallboardCore
local Skin = AutoCallboardSkin
local THEME = Skin.THEME
local L = AutoCallboardLocale
local RT = AutoCallboardRuntime

local Localized = RT.Localized
local RegisterSpecialFrame = RT.RegisterSpecialFrame
local GetQuestTypeName = RT.GetQuestTypeName
local FormatSeconds = RT.FormatSeconds
local FormatMoney = RT.FormatMoney
local GetGoldTrackerState = RT.GetGoldTrackerState
local CaptureCurrentObjectives = RT.CaptureCurrentObjectives
local GetCurrentObjectives = RT.GetCurrentObjectives
local GetObjectivesService = RT.GetObjectivesService
local CountDesiredQuests = RT.CountDesiredQuests
local IsCallboardActive = RT.IsCallboardActive
local GetSummonCooldownRemaining = RT.GetSummonCooldownRemaining
local state = RT.state

local function SyncCheckbox(checkbox, value)
  if not checkbox then
    return
  end

  checkbox:SetChecked(value and true or false)
  Skin.SetCheckboxVisual(checkbox)
end

RT.SyncCheckbox = SyncCheckbox

local KNOWN_ROWS = 8
local QUEST_ROW_HEIGHT = 28
local QUEST_WINDOW_WIDTH = 620
local KNOWN_QUEST_ROW_WIDTH = 556

local questWindow
local knownQuestRows = {}
local questStatusText
local knownScrollFrame
local questSearchBox
local questSearchText = ""
local knownScrollOffset = 0
local updatingKnownScrollBar = false

local QuestLabel
local ConfigureKnownQuestRow
local SetKnownScrollOffset
local UpdateQuestWindow
local ShowQuestWindow

function RT.RefreshQuestWindow()
  if questWindow and questWindow:IsShown() and UpdateQuestWindow then
    UpdateQuestWindow()
  end
end

function RT.IsQuestWindowShown()
  return questWindow ~= nil and questWindow:IsShown()
end

QuestLabel = function(quest)
  local title = Core.questTitle(quest)
  local questID = tonumber(quest and quest.questId)

  if title == "" then
    title = L.QUEST_UNKNOWN_TITLE
  end

  if questID and questID > 0 then
    return title .. " (" .. tostring(math.floor(questID)) .. ")"
  end

  return title
end

RT.QuestLabel = function(...)
  return QuestLabel(...)
end

RT.questTypeFilterOptions = {
  { questType = 1, label = L.QUEST_TYPE_NAMES[1] },
  { questType = 2, label = L.QUEST_TYPE_NAMES[2] },
  { questType = 3, label = L.QUEST_TYPE_NAMES[3] },
  { questType = 4, label = L.QUEST_TYPE_NAMES[4] },
  { questType = 0, label = L.QUEST_TYPE_OTHER },
}
RT.knownQuestTypeButtons = RT.knownQuestTypeButtons or {}
RT.knownQuestTypeFilters = RT.knownQuestTypeFilters or {}

RT.questSortTitles = setmetatable({}, { __mode = "k" })

local function QuestSortTitle(quest)
  if not quest then
    return ""
  end

  local cached = RT.questSortTitles[quest]

  if not cached then
    cached = string.lower(Core.questTitle(quest))
    RT.questSortTitles[quest] = cached
  end

  return cached
end

local function CompareKnownQuests(left, right)
  local leftType = tonumber(left and left.questType) or 999
  local rightType = tonumber(right and right.questType) or 999

  if leftType ~= rightType then
    return leftType < rightType
  end

  local leftTitle = QuestSortTitle(left)
  local rightTitle = QuestSortTitle(right)
  if leftTitle ~= rightTitle then
    return leftTitle < rightTitle
  end

  return (tonumber(left and left.questId) or 0) < (tonumber(right and right.questId) or 0)
end

RT.questSearchHaystacks = setmetatable({}, { __mode = "k" })

local function QuestMatchesSearch(quest, query)
  if not query or query == "" then
    return true
  end

  if not quest then
    return false
  end

  local haystack = RT.questSearchHaystacks[quest]

  if haystack then
    return string.find(haystack, query, 1, true) ~= nil
  end

  local questType = tonumber(quest.questType)
  local tooltipParts = {
    tostring(quest.title or ""),
    tostring(quest.objectiveText or ""),
    tostring(quest.questId or ""),
    tostring(quest.zoneOrSort or ""),
    tostring(quest.questType or ""),
    questType and GetQuestTypeName(questType) or "",
    tostring(quest.normalXp or ""),
    tostring(quest.hc1Xp or ""),
    tostring(quest.hc2Xp or ""),
    tostring(quest.hc3Xp or ""),
    tostring(quest.hc4Xp or ""),
    tostring(quest.normalSoulAshes or ""),
    tostring(quest.hc1SoulAshes or ""),
    tostring(quest.hc2SoulAshes or ""),
    tostring(quest.hc3SoulAshes or ""),
    tostring(quest.hc4SoulAshes or ""),
    tostring(quest.seen or ""),
    "xp",
    "soul ash",
    "seen",
  }

  haystack = table.concat(tooltipParts, " "):lower()
  RT.questSearchHaystacks[quest] = haystack

  return string.find(haystack, query, 1, true) ~= nil
end

function RT.CountActiveQuestTypeFilters()
  local count = 0
  local lastQuestType = nil

  for i = 1, #(RT.questTypeFilterOptions) do
    local questType = RT.questTypeFilterOptions[i].questType

    if Core.questTypeFilterEnabled(RT.knownQuestTypeFilters, questType) then
      count = count + 1
      lastQuestType = questType
    end
  end

  return count, lastQuestType
end

function RT.GetActiveQuestTypeFilterNames()
  local count = RT.CountActiveQuestTypeFilters()
  local names = {}

  if count == 0 then
    return names
  end

  for i = 1, #(RT.questTypeFilterOptions) do
    local option = RT.questTypeFilterOptions[i]
    if Core.questTypeFilterEnabled(RT.knownQuestTypeFilters, option.questType) then
      table.insert(names, option.label)
    end
  end

  return names
end

function RT.SyncKnownQuestTypeButtons()
  for i = 1, #(RT.knownQuestTypeButtons) do
    local checkbox = RT.knownQuestTypeButtons[i]
    SyncCheckbox(checkbox, Core.questTypeFilterEnabled(RT.knownQuestTypeFilters, checkbox._acbQuestType))
  end
end

function RT.SetKnownQuestTypeFilter(questType)
  RT.knownQuestTypeFilters = RT.knownQuestTypeFilters or {}
  questType = tonumber(questType) or 0

  if Core.questTypeFilterEnabled(RT.knownQuestTypeFilters, questType) then
    RT.knownQuestTypeFilters[questType] = nil
    RT.knownQuestTypeFilters[tostring(questType)] = nil
  else
    RT.knownQuestTypeFilters[questType] = true
    RT.knownQuestTypeFilters[tostring(questType)] = nil
  end

  RT.knownFilterRevision = (RT.knownFilterRevision or 0) + 1
  RT.SyncKnownQuestTypeButtons()
  SetKnownScrollOffset(0, true)
end

local function ActiveSelectionFilter()
  local selection = Core.findSelection(RT.GetAccountProfile(), RT.GetActiveSelectionId())

  if not selection then
    return nil
  end

  local name = type(selection.name) == "string" and selection.name or ""

  return type(selection.desiredQuests) == "table" and selection.desiredQuests or {},
      name ~= "" and name or L.SELECTION_DEFAULT_NAME
end

function RT.GetActiveSelectionFilterName()
  local _, name = ActiveSelectionFilter()
  return name
end

local function FilterKnownQuests()
  local filtered = {}

  local quests = state and state.knownQuests or {}
  local activeTypeCount = RT.CountActiveQuestTypeFilters()
  local useTypeFallback = activeTypeCount > 0 and Core.needsKnownTypeFallback(quests, RT.knownQuestTypeFilters)
  local listScope = ActiveSelectionFilter()
  local searchNeedle = string.lower(questSearchText or "")
  local filterMode

  if useTypeFallback then
    filterMode = "type-fallback"
  elseif activeTypeCount > 0 then
    filterMode = "type"
  elseif listScope then
    filterMode = "list"
  else
    filterMode = "all"
  end

  for i = 1, #(quests) do
    local quest = quests[i]
    local matchesFilter = useTypeFallback or Core.questMatchesTypeFilter(quest, RT.knownQuestTypeFilters)

    if matchesFilter and listScope then
      matchesFilter = Core.questInSelection(quest, listScope)
    end

    if matchesFilter and QuestMatchesSearch(quest, searchNeedle) then
      table.insert(filtered, quest)
    end
  end

  return filtered, filterMode
end

local function BuildKnownQuestEntries()
  local filtered, filterMode = FilterKnownQuests()
  table.sort(filtered, CompareKnownQuests)

  local entries = {}
  local lastTypeName = nil

  for i = 1, #(filtered) do
    local quest = filtered[i]
    local typeName = filterMode == "type-fallback" and L.QUEST_CATEGORY_DATA_MISSING or GetQuestTypeName(quest and quest.questType)

    if typeName ~= lastTypeName then
      table.insert(entries, {
        kind = "header",
        title = typeName,
      })
      lastTypeName = typeName
    end

    table.insert(entries, {
      kind = "quest",
      quest = quest,
    })
  end

  return entries, filtered, filterMode
end

function RT.GetKnownQuestEntries()
  local signature = tostring(RT.stateRevision or 0)
      .. "|" .. tostring(RT.knownFilterRevision or 0)
      .. "|" .. questSearchText

  if RT.knownEntriesSignature == signature then
    return RT.knownEntries,
        RT.knownEntriesFiltered,
        RT.knownEntriesFilterMode
  end

  local entries, filtered, filterMode = BuildKnownQuestEntries()

  RT.knownEntriesSignature = signature
  RT.knownEntries = entries
  RT.knownEntriesFiltered = filtered
  RT.knownEntriesFilterMode = filterMode

  return entries, filtered, filterMode
end

function RT.GetKnownListViewState()
  return questSearchText, knownScrollOffset, KNOWN_ROWS
end

function RT.GetKnownQuestDisplayReason(quests, filtered, entries, filterMode, selectedKnownCount, selectedMissingCount, activeTypeNames)
  if #(quests) == 0 then
    return "no_known_quests"
  end

  if #(entries) > 0 then
    if filterMode == "list" then
      return "showing_list"
    end

    if filterMode == "type-fallback" then
      return "category_metadata_missing_fallback"
    end

    if filterMode == "type" then
      return "showing_type_filter"
    end

    if selectedMissingCount > 0 and selectedKnownCount == 0 then
      return "selected_keys_missing_showing_all"
    end

    return "showing_all_known"
  end

  if questSearchText ~= "" then
    return "search_hides_all"
  end

  if #(activeTypeNames) > 0 and Core.needsKnownTypeFallback(quests, RT.knownQuestTypeFilters) then
    return "category_metadata_missing"
  end

  if #(activeTypeNames) > 0 then
    return "type_filter_hides_all"
  end

  if filterMode == "list" and #(filtered) == 0 then
    return "list_filter_hides_all"
  end

  return "unknown_empty_list"
end

RT.knownEmptyReasonKeys = {
  no_known_quests = "KNOWN_EMPTY_NO_QUESTS",
  search_hides_all = "KNOWN_EMPTY_SEARCH",
  category_metadata_missing = "KNOWN_EMPTY_CATEGORY_DATA",
  type_filter_hides_all = "KNOWN_EMPTY_TYPE_FILTER",
  list_filter_hides_all = "KNOWN_EMPTY_LIST_FILTER",
}

function RT.FormatKnownQuestHeader(quests, filtered, entries, filterMode, activeTypeNames, selectedKnownCount, selectedMissingCount)
  local parts = {}
  local listName = RT.GetActiveSelectionFilterName()

  if listName then
    table.insert(parts, listName)
  end

  if #(activeTypeNames) > 0 then
    table.insert(parts, filterMode == "type-fallback" and L.QUEST_CATEGORY_DATA_MISSING or table.concat(activeTypeNames, ", "))
  end

  local showing = #(parts) > 0 and table.concat(parts, " + ") or L.KNOWN_SHOWING_ALL

  local header = string.format(L.KNOWN_HEADER, #(quests), #(filtered), showing)

  if selectedMissingCount > 0 then
    header = header .. string.format(L.KNOWN_HEADER_MISSING, selectedMissingCount)
  elseif selectedKnownCount > 0 then
    header = header .. string.format(L.KNOWN_HEADER_SELECTED_KNOWN, selectedKnownCount)
  end

  if #(entries) == 0 then
    local reasonKey = RT.knownEmptyReasonKeys[RT.GetKnownQuestDisplayReason(
        quests, filtered, entries, filterMode, selectedKnownCount, selectedMissingCount, activeTypeNames)]

    if reasonKey then
      header = header .. "  |  " .. L[reasonKey]
    end
  end

  return header
end

local function AddRewardLine(label, xp, soulAshes)
  local parts = {}

  if xp and xp > 0 then
    table.insert(parts, string.format(L.REWARD_XP, xp))
  end

  if soulAshes and soulAshes > 0 then
    table.insert(parts, string.format(L.REWARD_SOUL_ASH, soulAshes))
  end

  if #(parts) > 0 then
    GameTooltip:AddDoubleLine(label, table.concat(parts, "  "), 0.85, 0.85, 0.85, 1, 1, 1)
  end
end

local function PositionTooltipNearCursor(owner)
  if not GetCursorPosition or not UIParent or not UIParent.GetEffectiveScale then
    GameTooltip:SetPoint("BOTTOMLEFT", owner or UIParent, "TOPRIGHT", 12, 12)
    return
  end

  local scale = UIParent:GetEffectiveScale() or 1
  local cursorX, cursorY = GetCursorPosition()
  local uiWidth = UIParent:GetWidth() or 0
  local uiHeight = UIParent:GetHeight() or 0
  local tooltipWidth = GameTooltip:GetWidth() or 260
  local tooltipHeight = GameTooltip:GetHeight() or 120
  local x = (cursorX / scale) + 18
  local y = (cursorY / scale) + 18

  if uiWidth > 0 and x + tooltipWidth > uiWidth - 8 then
    x = math.max(8, uiWidth - tooltipWidth - 8)
  end

  if uiHeight > 0 and y + tooltipHeight > uiHeight - 8 then
    y = math.max(8, uiHeight - tooltipHeight - 8)
  end

  GameTooltip:ClearAllPoints()
  GameTooltip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
end

local function AnchorTooltipNearCursor(owner)
  GameTooltip:SetOwner(owner or UIParent, "ANCHOR_NONE")
  PositionTooltipNearCursor(owner)
end

local function ShowQuestTooltip(owner, quest, sourceLabel)
  if not quest then
    return
  end

  AnchorTooltipNearCursor(owner)
  GameTooltip:AddLine(Core.questTitle(quest) ~= "" and Core.questTitle(quest) or L.QUEST_UNKNOWN_TITLE, 1, 0.82, 0)

  if sourceLabel then
    GameTooltip:AddLine(sourceLabel, 0.65, 0.8, 1)
  end

  if tonumber(quest.questId) and tonumber(quest.questId) > 0 then
    GameTooltip:AddDoubleLine(L.QUEST_TOOLTIP_ID, tostring(math.floor(tonumber(quest.questId))), 0.8, 0.8, 0.8, 1, 1, 1)
  end

  local questType = tonumber(quest.questType)
  if questType and questType > 0 then
    GameTooltip:AddDoubleLine(L.QUEST_TOOLTIP_TYPE, GetQuestTypeName(questType), 0.8, 0.8, 0.8, 1, 1, 1)
  end

  if tonumber(quest.zoneOrSort) and tonumber(quest.zoneOrSort) > 0 then
    GameTooltip:AddDoubleLine(L.QUEST_TOOLTIP_ZONE_SORT, tostring(math.floor(tonumber(quest.zoneOrSort))), 0.8, 0.8, 0.8, 1, 1, 1)
  end

  if quest.objectiveText and quest.objectiveText ~= "" then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(quest.objectiveText, 1, 1, 1, true)
  end

  local RL = L.REWARD_DIFFICULTY_LABELS
  AddRewardLine(RL[1], tonumber(quest.normalXp) or 0, tonumber(quest.normalSoulAshes) or 0)
  AddRewardLine(RL[2], tonumber(quest.hc1Xp) or 0, tonumber(quest.hc1SoulAshes) or 0)
  AddRewardLine(RL[3], tonumber(quest.hc2Xp) or 0, tonumber(quest.hc2SoulAshes) or 0)
  AddRewardLine(RL[4], tonumber(quest.hc3Xp) or 0, tonumber(quest.hc3SoulAshes) or 0)
  AddRewardLine(RL[5], tonumber(quest.hc4Xp) or 0, tonumber(quest.hc4SoulAshes) or 0)

  if quest.seen then
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(L.QUEST_TOOLTIP_SEEN, tostring(quest.seen), 0.8, 0.8, 0.8, 1, 1, 1)
  end

  GameTooltip:Show()
  PositionTooltipNearCursor(owner)
end

function RT.UpdateAutoAcceptSharedControl()
  SyncCheckbox(RT.autoAcceptSharedCheckbox, state and state.autoAcceptShared)
end

function RT.SyncRollSpeedControl()
  local slider = RT.rollSpeedSlider
  if not slider or slider._acbDragging then
    return
  end

  slider._acbTooltip = L.ROLL_SPEED_TOOLTIP

  local preset = Core.nearestRollSpeedPreset(state and state.rerollDelay)
  slider:SetDisplayValue(preset and preset.index or 1)
end

function RT.SyncTravelCheckbox()
  SyncCheckbox(RT.travelCheckbox, state and state.travelEnabled)
  SyncCheckbox(RT.travelAutoCheckbox, state and state.travelAuto)

  local auto = RT.travelAutoCheckbox

  if auto then
    if state and state.travelEnabled then
      auto:Enable()
      auto:SetAlpha(1)
    else
      auto:Disable()
      auto:SetAlpha(0.48)
    end

    if Skin.SetCheckboxVisual then
      Skin.SetCheckboxVisual(auto)
    end
  end
end

function RT.UpdateAutoCurrentInstanceControl()
  SyncCheckbox(RT.autoCurrentInstanceCheckbox, state and state.autoCurrentInstanceQuest)
end

function RT.UpdateEchoBarControls()
  SyncCheckbox(RT.echoBarCheckbox, RT.IsEchoBarEnabled())

  local button = RT.echoBarOrientationButton

  if button then
    button:SetText(RT.GetEchoBarOrientation() == "V" and "V" or "H")
    RT.SetButtonEnabled(button, RT.IsEchoBarEnabled())
  end
end

function RT.UpdateMinimapShownControl()
  SyncCheckbox(RT.minimapShownCheckbox, state and state.minimap and state.minimap.shown)
end

function RT.UpdateRemoteRollControl()
  SyncCheckbox(RT.remoteRollCheckbox, state and state.remoteRoll)
end

local function GetKnownMaxScrollOffset()
  local entries = RT.GetKnownQuestEntries()

  return math.max(0, #(entries) - KNOWN_ROWS)
end

SetKnownScrollOffset = function(value, force)
  local maxOffset = GetKnownMaxScrollOffset()
  local nextOffset = math.max(0, math.min(maxOffset, math.floor((tonumber(value) or 0) + 0.5)))

  if nextOffset == knownScrollOffset and not force then
    if knownScrollFrame and knownScrollFrame._acbScrollBar and knownScrollFrame._acbScrollBar.SetValue then
      updatingKnownScrollBar = true
      knownScrollFrame._acbScrollBar:SetValue(nextOffset)
      updatingKnownScrollBar = false
    end
    return
  end

  knownScrollOffset = nextOffset

  if UpdateQuestWindow then
    UpdateQuestWindow()
  end
end

UpdateQuestWindow = function()
  if not questWindow then
    return
  end

  if not questWindow:IsShown() then
    if RT.controlFrame and RT.controlFrame.startButton then
      RT.UpdateRollToggleButtonState(RT.controlFrame.startButton, true)
    end

    return
  end

  if not RT.ShouldHoldObjectiveChoices() then
    CaptureCurrentObjectives()
  end
  local service = GetObjectivesService()
  local desiredCount = CountDesiredQuests()

  local knownEntries, knownFiltered, knownFilterMode = RT.GetKnownQuestEntries()
  local displayCount = #(knownEntries)
  local maxOffset = math.max(0, displayCount - KNOWN_ROWS)

  if knownScrollOffset > maxOffset then
    knownScrollOffset = maxOffset
  elseif knownScrollOffset < 0 then
    knownScrollOffset = 0
  end

  if knownScrollFrame and knownScrollFrame._acbScrollBar then
    local scrollBar = knownScrollFrame._acbScrollBar

    updatingKnownScrollBar = true
    if scrollBar.SetMinMaxValues then
      scrollBar:SetMinMaxValues(0, maxOffset)
    end
    if scrollBar.SetValueStep then
      scrollBar:SetValueStep(1)
    end
    if scrollBar.SetValue then
      scrollBar:SetValue(knownScrollOffset)
    end
    updatingKnownScrollBar = false

    if maxOffset > 0 then
      scrollBar:Show()
    else
      scrollBar:Hide()
    end
  elseif knownScrollFrame and FauxScrollFrame_Update and FauxScrollFrame_GetOffset then
    knownScrollFrame.offset = knownScrollOffset
    FauxScrollFrame_Update(knownScrollFrame, displayCount, KNOWN_ROWS, QUEST_ROW_HEIGHT)
    knownScrollOffset = FauxScrollFrame_GetOffset(knownScrollFrame)
  end

  local offset = knownScrollOffset
  for i = 1, KNOWN_ROWS do
    local row = knownQuestRows[i]
    local entry = knownEntries[offset + i]

    if row then
      ConfigureKnownQuestRow(row, entry)
    end
  end

  if RT.knownPageText then

    local selectedKnownCount, selectedMissingCount =
        Core.countDesiredKnownQuests(state and state.knownQuests, state and state.desiredQuests)

    RT.knownPageText:SetText(RT.FormatKnownQuestHeader(
        state and state.knownQuests or {},
        knownFiltered,
        knownEntries,
        knownFilterMode,
        RT.GetActiveQuestTypeFilterNames(),
        selectedKnownCount,
        selectedMissingCount))
  end

  RT.SyncKnownQuestTypeButtons()

  RT.RefreshGoldDisplay()

  RT.UpdateRollToggleButtonState(RT.startRollButton, service ~= nil)
  RT.UpdateRollToggleButtonState(RT.controlFrame and RT.controlFrame.startButton or nil, true)
  RT.UpdateAutoAcceptSharedControl()
  RT.UpdateAutoCurrentInstanceControl()
  RT.SyncRollSpeedControl()

  if questStatusText then
    local summonSummary = ""
    local cooldownRemaining = GetSummonCooldownRemaining()
    if IsCallboardActive() then
      summonSummary = string.format(L.STATUS_SUFFIX_ACTIVE, FormatSeconds(RT.GetCallboardActiveRemaining()))
    elseif cooldownRemaining > 0 then
      summonSummary = string.format(L.STATUS_SUFFIX_COOLDOWN, FormatSeconds(cooldownRemaining))
    end

    summonSummary = summonSummary .. RT.FormatDifficultyStatus()

    if not service then
      questStatusText:SetText(L.STATUS_OBJECTIVES_UNAVAILABLE)
    elseif RT.IsRolling() and RT.GetRollPauseReason() == "quest_selected" and RT.GetSelectedQuest() then
      questStatusText:SetText(string.format(L.STATUS_PAUSED_SELECTED, tostring(RT.GetSelectedQuest().title or "quest"), summonSummary))
    elseif RT.IsRolling() and RT.GetRollPauseReason() then
      questStatusText:SetText(tostring(RT.GetRollPauseMessage() or string.format(L.STATUS_PAUSED_GENERIC, RT.GetRollPauseReason())) .. summonSummary)
    elseif RT.IsRolling() and RT.learningQuestList then
      questStatusText:SetText(string.format(L.STATUS_LEARNING, RT.GetRollCount(), state.maxRerolls, summonSummary))
    elseif RT.IsRolling() then
      questStatusText:SetText(string.format(L.STATUS_ROLLING, RT.GetRollCount(), state.maxRerolls, desiredCount, summonSummary))
    else
      questStatusText:SetText(string.format(L.STATUS_SELECTED, desiredCount, summonSummary))
    end
  end
end

RT.UpdateQuestWindow = function(...)
  return UpdateQuestWindow(...)
end

local function MakeQuestRow(parent, width)
  local row = CreateFrame("Frame", nil, parent)
  row:SetWidth(width)
  row:SetHeight(24)
  Skin.Frame(row, "soft")
  row:EnableMouse(true)
  row:SetScript("OnEnter", function(self)
    ShowQuestTooltip(self, self.quest, L.TOOLTIP_SOURCE_KNOWN_QUEST)
    end)
  row:SetScript("OnLeave", function()
    GameTooltip:Hide()
    end)

  row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  row.title:SetPoint("LEFT", row, "LEFT", 3, 0)
  row.title:SetWidth(width - 36)
  row.title:SetJustifyH("LEFT")
  Skin.ApplyColor(row.title, "SetTextColor", THEME.gold)

  row:EnableMouseWheel(true)
  row:SetScript("OnMouseWheel", function(_, delta)
    SetKnownScrollOffset(knownScrollOffset - delta)
    end)

  do
    row.checkbox = CreateFrame("CheckButton", nil, row)
    row.checkbox:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    Skin.Checkbox(row.checkbox)
    row.checkbox:SetScript("OnClick", function(self)
      if row.key then
        RT.ToggleDesiredQuest(row.key)
      end
      Skin.SetCheckboxVisual(self)
      end)
    row.checkbox:SetScript("OnEnter", function(self)
      Skin.SetCheckboxVisual(self, "hover")
      ShowQuestTooltip(self, row.quest, L.TOOLTIP_SOURCE_KNOWN_QUEST)
      end)
    row.checkbox:SetScript("OnLeave", function(self)
      Skin.SetCheckboxVisual(self)
      GameTooltip:Hide()
      end)
    row.checkbox:EnableMouseWheel(true)
    row.checkbox:SetScript("OnMouseWheel", function(_, delta)
      SetKnownScrollOffset(knownScrollOffset - delta)
      end)
  end

  return row
end

ConfigureKnownQuestRow = function(row, entry)
  if not row then
    return
  end

  if not entry then
    row.quest = nil
    row.key = nil
    row:Hide()
    return
  end

  if entry.kind == "header" then
    row.quest = nil
    row.key = nil
    row.title:SetWidth(KNOWN_QUEST_ROW_WIDTH - 12)
    row.title:SetText("[" .. tostring(entry.title or L.QUEST_TYPE_OTHER) .. "]")
    Skin.ApplyColor(row.title, "SetTextColor", THEME.heading)
    if row.checkbox then
      row.checkbox:SetChecked(false)
      row.checkbox:Hide()
    end
    row:Show()
    return
  end

  local quest = entry.quest
  if not quest then
    row.quest = nil
    row.key = nil
    row:Hide()
    return
  end

  local wanted = quest.key and state.desiredQuests and state.desiredQuests[quest.key] == true
  row.quest = quest
  row.key = quest.key
  row.title:SetWidth(KNOWN_QUEST_ROW_WIDTH - 36)
  row.title:SetText(QuestLabel(quest))
  Skin.ApplyColor(row.title, "SetTextColor", wanted and THEME.good or THEME.gold)
  if row.checkbox then
    row.checkbox:SetChecked(wanted)
    Skin.SetCheckboxVisual(row.checkbox)
    row.checkbox:Show()
  end
  row:Show()
end

function RT.CreateQuestWindow()
  questWindow = CreateFrame("Frame", "AutoCallboardQuestWindow", RT.controlFrame or UIParent)
  RT.questWindow = questWindow
  RegisterSpecialFrame("AutoCallboardQuestWindow")
  questWindow:SetWidth(QUEST_WINDOW_WIDTH)
  questWindow:SetHeight(526)
  questWindow:SetPoint("TOPLEFT", RT.controlFrame or UIParent, "TOPLEFT", RT.controlFrame and 10 or 0, RT.controlFrame and -82 or 0)
  if RT.controlFrame and questWindow.SetFrameLevel then
    questWindow:SetFrameLevel(RT.controlFrame:GetFrameLevel() + 1)
  end
  RT.SyncOverlayFrameLevels()
  questWindow:EnableMouse(true)
  questWindow:SetClampedToScreen(true)
  Skin.Frame(questWindow)
  questWindow:SetScript("OnHide", function()
    if questSearchBox and questSearchBox.ClearFocus then
      questSearchBox:ClearFocus()
    end

    if RT.controlFrame and not RT.questPanelChanging and not RT.questWindowCreating then
      RT.SetQuestPanelExpanded(false)
    end
    end)

  local title = questWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", questWindow, "TOP", 0, -18)
  Localized(title, "QUEST_WINDOW_TITLE")
  Skin.HeadingText(title)

  RT.autoCurrentInstanceCheckbox = Skin.SettingCheckbox(questWindow, {
    point = { "TOPRIGHT", questWindow, "TOPRIGHT", -24, -52 },
    labelKey = "AUTO_CURRENT_INSTANCE_LABEL",
    tipKey = "AUTO_CURRENT_INSTANCE_TOOLTIP",
    onClick = function(self)
      local enabled = self:GetChecked() and true or false
      RT.SetField("autoCurrentInstanceQuest", enabled)
      if enabled then
        RT.ShowAutoCurrentInstanceWarning()
      end
      end,
  })
  RT.UpdateAutoCurrentInstanceControl()

  RT.echoBarCheckbox = Skin.SettingCheckbox(questWindow, {
    point = { "TOPLEFT", questWindow, "TOPLEFT", 190, -52 },
    labelKey = "ECHO_BAR_LABEL",
    tipKey = "ECHO_BAR_TOOLTIP",
    onClick = function(self)
      RT.SetEchoBarEnabled(self:GetChecked() and true or false)
      end,
  })

  RT.echoBarOrientationButton = Skin.MakeButton(questWindow, {
    width = 22,
    height = 20,
    text = "H",
    points = { { "LEFT", RT.echoBarCheckbox, "RIGHT", 8, 0 } },
    tipTitle = "ECHO_BAR_ORIENTATION_LABEL",
    tipBody = "ECHO_BAR_ORIENTATION_TOOLTIP",
    onClick = function()
      RT.ToggleEchoBarOrientation()
      end,
  })
  RT.UpdateEchoBarControls()

  local searchLabel = questWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  searchLabel:SetPoint("TOPLEFT", questWindow, "TOPLEFT", 24, -52)
  Localized(searchLabel, "SEARCH_LABEL")
  Skin.MutedText(searchLabel)

  questSearchBox = CreateFrame("EditBox", "AutoCallboardQuestSearchBox", questWindow, "InputBoxTemplate")
  questSearchBox:SetWidth(250)
  questSearchBox:SetHeight(24)
  questSearchBox:SetAutoFocus(false)
  questSearchBox:SetPoint("LEFT", searchLabel, "RIGHT", 12, 0)
  Skin.EditBox(questSearchBox)
  questSearchBox:SetScript("OnTextChanged", function(self)
    questSearchText = self:GetText() or ""
    SetKnownScrollOffset(0, true)
    end)
  questSearchBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    end)
  questSearchBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    end)

  Skin.MakeButton(questWindow, {
    width = 54,
    height = 22,
    textKey = "BUTTON_CLEAR",
    points = { { "LEFT", questSearchBox, "RIGHT", 10, 0 } },
    onClick = function()
      questSearchBox:SetText("")
      questSearchBox:ClearFocus()
      end,
  })

  RT.autoAcceptSharedCheckbox = Skin.SettingCheckbox(questWindow, {
    point = { "TOPRIGHT", questWindow, "TOPRIGHT", -24, -84 },
    labelKey = "AUTO_ACCEPT_SHARED_LABEL",
    tipKey = "AUTO_ACCEPT_SHARED_TOOLTIP",
    onClick = function(self)
      RT.SetField("autoAcceptShared", self:GetChecked() and true or false)
      end,
  })
  RT.UpdateAutoAcceptSharedControl()

  RT.minimapShownCheckbox = Skin.SettingCheckbox(questWindow, {
    point = { "TOPRIGHT", questWindow, "TOPRIGHT", -24, -112 },
    labelKey = "MINIMAP_BUTTON_LABEL",
    tipKey = "MINIMAP_BUTTON_TOOLTIP",
    onClick = function(self)
      RT.SetMinimapShown(self:GetChecked() and true or false)
      end,
  })
  RT.UpdateMinimapShownControl()

  RT.travelCheckbox = Skin.SettingCheckbox(questWindow, {
    point = { "TOPRIGHT", questWindow, "TOPRIGHT", -24, -140 },
    labelKey = "TRAVEL_LABEL",
    tipKey = "TRAVEL_TOOLTIP",
    onClick = function(self)
      RT.SetTravelEnabled(self:GetChecked() and true or false)
      end,
  })

  RT.travelAutoCheckbox = Skin.SettingCheckbox(questWindow, {
    point = { "TOPRIGHT", questWindow, "TOPRIGHT", -24, -168 },
    labelKey = "TRAVEL_AUTO_LABEL",
    tipKey = "TRAVEL_AUTO_TOOLTIP",
    onClick = function(self)
      RT.SetTravelAutoEnabled(self:GetChecked() and true or false)
      end,
  })
  RT.SyncTravelCheckbox()

  RT.remoteRollCheckbox = Skin.SettingCheckbox(questWindow, {
    point = { "TOPRIGHT", questWindow, "TOPRIGHT", -24, -196 },
    labelKey = "REMOTE_ROLL_LABEL",
    tipKey = "REMOTE_ROLL_TOOLTIP",
    onClick = function(self)
      RT.SetField("remoteRoll", self:GetChecked() and true or false)
      end,
  })
  RT.UpdateRemoteRollControl()

  local rollSpeedPresets = Core.rollSpeedPresetList()

  local function RollSpeedPresetAt(value)
    local index = math.floor((tonumber(value) or 1) + 0.5)
    if index < 1 then
      index = 1
    elseif index > #(rollSpeedPresets) then
      index = #(rollSpeedPresets)
    end
    return rollSpeedPresets[index]
  end

  RT.rollSpeedSlider = Skin.Slider(questWindow, {
    min = 1,
    max = #(rollSpeedPresets),
    step = 1,
    width = 180,
    title = L.ROLL_SPEED_LABEL,
    tooltip = L.ROLL_SPEED_TOOLTIP,
    format = function(value)
      local preset = RollSpeedPresetAt(value)
      return string.format("%s  -  %s",
          L.ROLL_SPEED_PRESET_NAMES[preset.key] or preset.key,
          string.format(L.ROLL_SPEED_FORMAT, tostring(preset.delay), tostring(preset.timeout)))
      end,
    onCommit = function(value)
      local preset = RollSpeedPresetAt(value)
      if state and state.rerollDelay == preset.delay and state.rerollTimeout == preset.timeout then
        return
      end
      RT.SetRollSpeed(preset.delay, preset.timeout, preset.key)
      end,
  })
  RT.rollSpeedSlider:SetPoint("BOTTOMLEFT", questWindow, "BOTTOMLEFT", 24, 106)
  Localized(RT.rollSpeedSlider.titleText, "ROLL_SPEED_LABEL")
  RT.SyncRollSpeedControl()

  local categoryLabel = questWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  categoryLabel:SetPoint("TOPLEFT", questWindow, "TOPLEFT", 24, -84)
  Localized(categoryLabel, "SHOW_LABEL")
  Skin.MutedText(categoryLabel)

  local previousCategoryLabel = categoryLabel
  RT.knownQuestTypeButtons = {}
  for i = 1, #(RT.questTypeFilterOptions) do
    local option = RT.questTypeFilterOptions[i]
    local checkbox = CreateFrame("CheckButton", nil, questWindow)
    if i == 1 then
      checkbox:SetPoint("LEFT", categoryLabel, "RIGHT", 14, 0)
    else
      checkbox:SetPoint("LEFT", previousCategoryLabel, "RIGHT", 18, 0)
    end
    checkbox._acbQuestType = option.questType
    Skin.Checkbox(checkbox)
    checkbox:SetScript("OnClick", function(self)
      RT.SetKnownQuestTypeFilter(self._acbQuestType)
    end)
    checkbox:SetScript("OnEnter", function(self)
      Skin.SetCheckboxVisual(self, "hover")
    end)
    checkbox:SetScript("OnLeave", function(self)
      Skin.SetCheckboxVisual(self)
    end)

    local checkboxLabel = questWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    checkboxLabel:SetPoint("LEFT", checkbox, "RIGHT", 6, 0)
    checkboxLabel:SetText(option.label)
    Skin.MutedText(checkboxLabel)

    checkbox._acbLabel = checkboxLabel
    table.insert(RT.knownQuestTypeButtons, checkbox)
    previousCategoryLabel = checkboxLabel
  end
  RT.SyncKnownQuestTypeButtons()

  RT.knownPageText = questWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  RT.knownPageText:SetPoint("TOPLEFT", questWindow, "TOPLEFT", 24, -116)
  RT.knownPageText:SetWidth(QUEST_WINDOW_WIDTH - 62)
  RT.knownPageText:SetJustifyH("LEFT")
  RT.knownPageText:SetText(L.QUEST_WINDOW_KNOWN_PAGE_DEFAULT)
  Skin.HeadingText(RT.knownPageText)

  knownScrollFrame = CreateFrame("ScrollFrame", "AutoCallboardKnownQuestScrollFrame", questWindow, "FauxScrollFrameTemplate")
  knownScrollFrame:SetPoint("TOPLEFT", RT.knownPageText, "BOTTOMLEFT", -4, -8)
  knownScrollFrame:SetPoint("BOTTOMRIGHT", questWindow, "BOTTOMRIGHT", -34, 120)
  knownScrollFrame:EnableMouseWheel(true)
  local knownScrollBar = Skin.ScrollBar(knownScrollFrame)
  if knownScrollBar then
    knownScrollBar:SetScript("OnValueChanged", function(_, value)
      if updatingKnownScrollBar then
        return
      end

      SetKnownScrollOffset(value)
      end)

    if knownScrollBar._acbUpButton then
      knownScrollBar._acbUpButton:SetScript("OnClick", function()
        SetKnownScrollOffset(knownScrollOffset - 1)
        end)
    end

    if knownScrollBar._acbDownButton then
      knownScrollBar._acbDownButton:SetScript("OnClick", function()
        SetKnownScrollOffset(knownScrollOffset + 1)
        end)
    end
  end
  knownScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
    SetKnownScrollOffset(offset)
    end)
  knownScrollFrame:SetScript("OnMouseWheel", function(_, delta)
    SetKnownScrollOffset(knownScrollOffset - delta)
    end)

  for i = 1, KNOWN_ROWS do
    knownQuestRows[i] = MakeQuestRow(questWindow, KNOWN_QUEST_ROW_WIDTH)
    knownQuestRows[i]:SetPoint("TOPLEFT", RT.knownPageText, "BOTTOMLEFT", 0, -10 - ((i - 1) * QUEST_ROW_HEIGHT))
  end

  local questToolbarWidth = 72 + 8 + 54 + 8 + 66 + 8 + 66

  RT.startRollButton = CreateFrame("Button", nil, questWindow, "SecureActionButtonTemplate,UIPanelButtonTemplate")
  RT.startRollButton:SetWidth(72)
  RT.startRollButton:SetHeight(24)
  RT.startRollButton:SetText(L.BUTTON_START)
  RT.startRollButton:SetPoint("BOTTOMLEFT", questWindow, "BOTTOM", -(questToolbarWidth / 2), 54)
  Skin.Button(RT.startRollButton)
  RT.ConfigureStartButton(RT.startRollButton)
  RT.UpdateRollToggleButtonState(RT.startRollButton, RT.IsQuestRollStartAvailable())

  RT.shareQuestButton = Skin.MakeButton(questWindow, {
    width = 54,
    height = 24,
    textKey = "BUTTON_SHARE",
    points = { { "LEFT", RT.startRollButton, "RIGHT", 8, 0 } },
    onClick = function()
      RT.ShareAcceptedQuest("quest window button")
      end,
    tipTitle = "BUTTON_SHARE",
    tipBody = "SHARE_BUTTON_TOOLTIP",
  })
  RT.UpdateShareButtonState()

  local exportDataButton = Skin.MakeButton(questWindow, {
    width = 66,
    height = 24,
    textKey = "BUTTON_EXPORT",
    points = { { "LEFT", RT.shareQuestButton, "RIGHT", 8, 0 } },
    onClick = function() RT.ShowQuestDataWindow("export") end,
  })

  Skin.MakeButton(questWindow, {
    width = 66,
    height = 24,
    textKey = "BUTTON_IMPORT",
    points = { { "LEFT", exportDataButton, "RIGHT", 8, 0 } },
    onClick = function() RT.ShowQuestDataWindow("import") end,
  })

  RT.languageButton = Skin.MakeButton(questWindow, {
    width = 46,
    height = 24,
    text = RT.LanguageInitials(RT.GetLanguage()),
    points = { { "BOTTOMRIGHT", questWindow, "BOTTOMRIGHT", -24, 54 } },
    onClick = function(self) RT.ToggleLanguageMenu(self) end,
    tipTitle = "LANGUAGE_LABEL",
    tipBody = "LANGUAGE_TOOLTIP",
  })

  RT.questGoldText = questWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  RT.questGoldText:SetPoint("BOTTOMLEFT", questWindow, "BOTTOMLEFT", 24, 32)
  RT.questGoldText:SetWidth(540)
  RT.questGoldText:SetJustifyH("LEFT")
  Skin.MutedText(RT.questGoldText)

  questStatusText = questWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  RT.questStatusText = questStatusText
  questStatusText:SetPoint("BOTTOMLEFT", questWindow, "BOTTOMLEFT", 24, 16)
  questStatusText:SetWidth(540)
  questStatusText:SetJustifyH("LEFT")
  Skin.MutedText(questStatusText)

  RT.AttachSettingsControls()
  RT.LayoutMainToolbar()
  RT.questWindowCreating = true
  questWindow:Hide()
  RT.questWindowCreating = nil
end

ShowQuestWindow = function()
  if not questWindow then
    RT.CreateQuestWindow()
  end

  RT.SetQuestPanelExpanded(true)
end

RT.QuestLabel = QuestLabel
RT.UpdateQuestWindow = UpdateQuestWindow
RT.ShowQuestWindow = ShowQuestWindow
