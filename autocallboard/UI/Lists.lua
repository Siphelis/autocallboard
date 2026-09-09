local Core = AutoCallboardCore
local Skin = AutoCallboardSkin
local THEME = Skin.THEME
local L = AutoCallboardLocale
local RT = AutoCallboardRuntime
local Print = RT.Print
local IsUnder = RT.IsUnder
local state = RT.state

local LIST_WIDTH = 214
local GROUP_OPEN_WIDTH = 202
local GROUP_BAND_WIDTH = 30
local PANEL_GAP = 4
local WINDOW_EDGE = 10
local TOP_STRIP = 22
local PANEL_HEADER = 26
local ROW_HEIGHT = 24
local ROW_GAP = 2
local VISIBLE_ROWS = 10
local SCROLLBAR_WIDTH = 18
local ANIMATION_SECONDS = 0.3

local DROP_LINE_HEIGHT = 2
local DRAG_SOURCE_ALPHA = 0.4
local DROP_REFUSED_BORDER = { 1, 0.25, 0.25, 1 }
local DROP_REFUSED_FILL = { 0.35, 0.05, 0.05, 0.55 }

local BAND_LABEL_TOP = 22
local BAND_LABEL_BOTTOM = 22
local BAND_STACK_LINE = 11
local BAND_SHORT_CHARS = 3
local BAND_LABEL_BOTTOM_UP = true

local ROWS_HEIGHT = VISIBLE_ROWS * (ROW_HEIGHT + ROW_GAP)
local PANEL_HEIGHT = PANEL_HEADER + ROWS_HEIGHT + 6
local WINDOW_HEIGHT = TOP_STRIP + PANEL_HEIGHT + WINDOW_EDGE
local BAND_LABEL_SPAN = PANEL_HEIGHT - BAND_LABEL_TOP - BAND_LABEL_BOTTOM

local listsWindow
local listPanel
local listBand
local groupPanel
local groupBands = {}
local animation
local drag
local scrollOffsets = { list = 0 }

RT.noneSelectionEntry = { id = nil, name = "", desiredQuests = {} }

local RefreshListsWindow
local BuildSelectionContextMenu

local COLLAPSE_ALL = 0
local LIST_KEY = 0

local function AccountProfile()
  return RT.GetAccountProfile()
end

local function ContainerKeyFor(stored)
  if stored == nil then
    return LIST_KEY
  end

  if stored == COLLAPSE_ALL then
    return nil
  end

  return stored
end

local function OpenContainerKey()
  return ContainerKeyFor(RT.GetOpenGroupId())
end

local function IsListOpen()
  return OpenContainerKey() == LIST_KEY
end

local function OpenGroupId()
  local key = OpenContainerKey()

  if key == nil or key == LIST_KEY then
    return nil
  end

  return key
end

local function ContainerKey(groupId)
  return groupId or "list"
end

local function ScrollOffset(groupId)
  return scrollOffsets[ContainerKey(groupId)] or 0
end

local function SetScrollOffset(groupId, value)
  scrollOffsets[ContainerKey(groupId)] = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
end

function RT.LoadSelectionPreset(entry)
  if not entry then
    return
  end

  RT.SetDesiredQuests(entry.desiredQuests)
  RT.SetActiveSelectionId(entry.id)

  RT.ApplyListDifficulty(entry.difficulty, "chargement liste " .. tostring(entry.name))

  if not RT.IsRolling() then
    RT.EvaluateCurrentObjectives()
  end

  RT.RefreshQuestWindow()
end

function RT.IsSelectionDifficultyLocked(entry)
  if not entry or entry.difficulty == nil then
    return false
  end

  if RT.GetCurrentDifficulty() == entry.difficulty then
    return false
  end

  return not RT.CanApplyDifficulty()
end

function RT.RequestLoadSelection(entry)
  if not entry then
    return
  end

  if RT.IsRolling() then
    Print(L.LISTS_CANNOT_SWITCH_ROLLING)
    return
  end

  if RT.IsSelectionDifficultyLocked(entry) then
    return
  end

  RT.LoadSelectionPreset(entry)
  RefreshListsWindow()
end

function RT.RequestRenameSelection(entry)
  if not entry then
    return
  end

  Skin.Dialog({
    title = string.format(L.LISTS_RENAME_DIALOG_TITLE, entry.name),
    body = "",
    editBox = { default = entry.name, maxLetters = Core.MAX_SELECTION_NAME_LENGTH },
    acceptText = L.BUTTON_ACCEPT,
    cancelText = L.BUTTON_CANCEL,
    onAccept = function(text)
      local nextProfile, ok = Core.renameSelection(AccountProfile(), entry.id, text)
      if not ok then
        return
      end

      RT.SaveAccountProfile(nextProfile)
      RefreshListsWindow()
      end,
  })
end

function RT.RequestOverwriteSelection(entry)
  if not entry then
    return
  end

  Skin.Dialog({
    title = entry.name,
    body = string.format(L.LISTS_OVERWRITE_CONFIRM_TEXT, entry.name),
    acceptText = L.BUTTON_OKAY,
    cancelText = L.BUTTON_CANCEL,
    onAccept = function()
      local nextProfile, ok = Core.updateSelectionContent(AccountProfile(), entry.id, state.desiredQuests)
      if not ok then
        return
      end

      RT.SaveAccountProfile(nextProfile)
      RT.SetActiveSelectionId(entry.id)
      RefreshListsWindow()
      end,
  })
end

function RT.RequestDeleteSelection(entry)
  if not entry then
    return
  end

  Skin.Dialog({
    title = entry.name,
    body = string.format(L.LISTS_DELETE_CONFIRM_TEXT, entry.name),
    acceptText = L.BUTTON_DELETE,
    cancelText = L.BUTTON_CANCEL,
    onAccept = function()
      local nextProfile, ok = Core.deleteSelection(AccountProfile(), entry.id)
      if not ok then
        return
      end

      RT.SaveAccountProfile(nextProfile)

      if RT.GetActiveSelectionId() == entry.id then
        RT.SetActiveSelectionId(nil)
      end

      RefreshListsWindow()
      end,
  })
end

function RT.RequestCreateSelection(groupId)
  local profile = AccountProfile()

  if Core.selectionsFull(profile, groupId) then
    Print(string.format(L.LISTS_MAX_SAVED_REACHED, Core.MAX_SAVED_SELECTIONS))
    return
  end

  Skin.Dialog({
    title = L.LISTS_NEW_DIALOG_TITLE,
    body = "",
    editBox = { default = Core.peekNextSelectionName(profile), maxLetters = Core.MAX_SELECTION_NAME_LENGTH },
    acceptText = L.BUTTON_ACCEPT,
    cancelText = L.BUTTON_CANCEL,
    onAccept = function(text)
      local nextProfile, entry, err = Core.createSelection(AccountProfile(), state.desiredQuests, text, groupId)

      if err == "full" then
        Print(string.format(L.LISTS_MAX_SAVED_REACHED, Core.MAX_SAVED_SELECTIONS))
        return
      end

      RT.SaveAccountProfile(nextProfile)

      if entry then
        RT.SetActiveSelectionId(entry.id)
      end

      RefreshListsWindow()
      end,
  })
end

function RT.RequestCreateGroup()
  local profile = AccountProfile()

  if Core.groupsFull(profile) then
    Print(string.format(L.LISTS_MAX_GROUPS_REACHED, Core.MAX_GROUPS))
    return
  end

  Skin.Dialog({
    title = L.LISTS_NEW_GROUP_TITLE,
    body = "",
    editBox = { default = Core.peekNextGroupName(profile), maxLetters = Core.MAX_SELECTION_NAME_LENGTH },
    acceptText = L.BUTTON_ACCEPT,
    cancelText = L.BUTTON_CANCEL,
    onAccept = function(text)
      local nextProfile, group, err = Core.createGroup(AccountProfile(), text)

      if err == "full" then
        Print(string.format(L.LISTS_MAX_GROUPS_REACHED, Core.MAX_GROUPS))
        return
      end

      RT.SaveAccountProfile(nextProfile)

      if group then
        RT.SetOpenGroup(group.id, true)
      end

      RefreshListsWindow()
      end,
  })
end

function RT.RequestRenameGroup(group)
  if not group then
    return
  end

  Skin.Dialog({
    title = string.format(L.LISTS_RENAME_GROUP_TITLE, group.name),
    body = "",
    editBox = { default = group.name, maxLetters = Core.MAX_SELECTION_NAME_LENGTH },
    acceptText = L.BUTTON_ACCEPT,
    cancelText = L.BUTTON_CANCEL,
    onAccept = function(text)
      local nextProfile, ok = Core.renameGroup(AccountProfile(), group.id, text)
      if not ok then
        return
      end

      RT.SaveAccountProfile(nextProfile)
      RefreshListsWindow()
      end,
  })
end

function RT.RequestDeleteGroup(group)
  if not group then
    return
  end

  local profile = AccountProfile()
  local count = Core.selectionCount(profile, group.id)
  local body

  if count == 0 then
    body = string.format(L.LISTS_DELETE_GROUP_EMPTY_BODY, group.name)
  else
    body = string.format(L.LISTS_DELETE_GROUP_BODY, group.name, RT.DescribeGroupContents(profile, group.id))
  end

  Skin.Dialog({
    title = L.LISTS_DELETE_GROUP_TITLE,
    body = body,
    acceptText = L.BUTTON_DELETE,
    cancelText = L.BUTTON_CANCEL,
    onAccept = function()
      local activeId = RT.GetActiveSelectionId()
      local activeSelection = Core.findSelection(AccountProfile(), activeId)
      local nextProfile, ok = Core.deleteGroup(AccountProfile(), group.id)

      if not ok then
        return
      end

      RT.SaveAccountProfile(nextProfile)

      if activeSelection and Core.sameContainer(activeSelection.groupId, group.id) then
        RT.SetActiveSelectionId(nil)
      end

      if RT.GetOpenGroupId() == group.id then
        RT.SetOpenGroup(nil, true)
      end

      RefreshListsWindow()
      end,
  })
end

function RT.RequestMoveSelection(entry, groupId)
  if not entry then
    return
  end

  local nextProfile, ok, err = Core.setSelectionGroup(AccountProfile(), entry.id, groupId)

  if err == "full" then
    Print(string.format(L.LISTS_MAX_SAVED_REACHED, Core.MAX_SAVED_SELECTIONS))
    return
  end

  if not ok then
    return
  end

  RT.SaveAccountProfile(nextProfile)
  RefreshListsWindow()
end

local DIFFICULTY_TIERS = { false, 1, 2, 3, 4, 5, 6 }

local function BuildDifficultySubmenu(menu, entry)
  menu:Reset()
  menu:AddItem(entry.name, { header = true })
  menu:AddItem("< " .. L.LISTS_MENU_DIFFICULTY, {
    keepOpen = true,
    onClick = function()
      BuildSelectionContextMenu(menu, entry)
      end,
  })

  for i = 1, #(DIFFICULTY_TIERS) do
    local value = (DIFFICULTY_TIERS[i] ~= false) and DIFFICULTY_TIERS[i] or nil
    menu:AddItem(Core.difficultyLabel(value), {
      checked = entry.difficulty == value,
      onClick = function()
        RT.RequestSetSelectionDifficulty(entry, value)
        end,
    })
  end

  menu:Layout()
end

local function BuildMoveSubmenu(menu, entry)
  local profile = AccountProfile()

  menu:Reset()
  menu:AddItem(entry.name, { header = true })
  menu:AddItem("< " .. L.LISTS_MENU_MOVE_TO, {
    keepOpen = true,
    onClick = function()
      BuildSelectionContextMenu(menu, entry)
      end,
  })

  menu:AddItem(L.LISTS_MOVE_TO_LIST, {
    checked = entry.groupId == nil,
    onClick = function()
      RT.RequestMoveSelection(entry, nil)
      end,
  })

  for i = 1, #(profile.groups) do
    local group = profile.groups[i]
    menu:AddItem(group.name, {
      checked = entry.groupId == group.id,
      onClick = function()
        RT.RequestMoveSelection(entry, group.id)
        end,
    })
  end

  menu:Layout()
end

BuildSelectionContextMenu = function(menu, entry)
  menu:Reset()
  menu:AddItem(entry.name, { header = true })

  if Core.groupCount(AccountProfile()) > 0 then
    menu:AddItem(L.LISTS_MENU_MOVE_TO, {
      arrow = true,
      keepOpen = true,
      onClick = function() BuildMoveSubmenu(menu, entry) end,
    })
  end

  menu:AddItem(L.LISTS_MENU_DIFFICULTY, {
    arrow = true,
    keepOpen = true,
    onClick = function() BuildDifficultySubmenu(menu, entry) end,
  })
  menu:AddItem(L.LISTS_MENU_UPDATE, {
    onClick = function() RT.RequestOverwriteSelection(entry) end,
  })
  menu:AddItem(L.LISTS_MENU_RENAME, {
    onClick = function() RT.RequestRenameSelection(entry) end,
  })
  menu:AddItem(L.LISTS_MENU_DELETE, {
    onClick = function() RT.RequestDeleteSelection(entry) end,
  })

  menu:Layout()
end

local function EnsureContextMenu()
  if not RT.listsContextMenu then
    RT.listsContextMenu = Skin.Menu("AutoCallboardListsContextMenu")
    RT.listsContextMenu:SetAutoClose(true)
    RT.listsContextMenu:CloseWhenHidden(listsWindow)
  end

  return RT.listsContextMenu
end

function RT.ShowSelectionContextMenu(row, entry)
  if not entry or entry.id == nil then
    return
  end

  local menu = EnsureContextMenu()
  BuildSelectionContextMenu(menu, entry)
  menu:OpenAt(row, "TOPLEFT", "TOPRIGHT", 4, 2)
end

function RT.ShowGroupContextMenu(anchor, group)
  if not group then
    return
  end

  local menu = EnsureContextMenu()
  menu:Reset()
  menu:AddItem(group.name, { header = true })
  menu:AddItem(L.LISTS_MENU_RENAME, {
    onClick = function() RT.RequestRenameGroup(group) end,
  })
  menu:AddItem(L.LISTS_MENU_DELETE, {
    onClick = function() RT.RequestDeleteGroup(group) end,
  })
  menu:Layout()
  menu:OpenAt(anchor, "TOPLEFT", "BOTTOMLEFT", 0, -2)
end

function RT.RefreshListRowVisual(row, hovered)
  local entry = row.entry
  if not entry then
    return
  end

  Skin.PaintRow(row,
      entry.id ~= nil and RT.GetActiveSelectionId() == entry.id,
      hovered and not drag,
      RT.IsRolling() or RT.IsSelectionDifficultyLocked(entry))

  if drag then
    row:SetAlpha(drag.id == entry.id and DRAG_SOURCE_ALPHA or 1)
  else
    row:SetAlpha(1)
  end
end

local function RefreshRowVisuals()
  local panels = { listPanel, groupPanel }

  for i = 1, #(panels) do
    local panel = panels[i]

    if panel and panel.rows then
      for j = 1, #(panel.rows) do
        RT.RefreshListRowVisual(panel.rows[j], false)
      end
    end
  end
end

local BeginSelectionDrag
local BeginGroupDrag
local EndDrag

local function CreateListRow(parent, name)
  local row = Skin.Row(parent, "AutoCallboardListRow" .. tostring(name), ROW_HEIGHT,
      "LeftButtonUp", "RightButtonUp")
  row:RegisterForDrag("LeftButton")

  row:SetScript("OnDragStart", function(self)
    if self.entry and self.entry.id ~= nil then
      BeginSelectionDrag(self.entry)
    end
    end)
  row:SetScript("OnDragStop", function()
    EndDrag()
    end)

  row:SetScript("OnClick", function(self, mouseButton)
    local entry = self.entry
    if not entry then
      return
    end

    if mouseButton == "RightButton" then
      if entry.id ~= nil then
        RT.ShowSelectionContextMenu(self, entry)
      end
    else
      RT.RequestLoadSelection(entry)
    end
    end)

  row:SetScript("OnEnter", function(self)
    if drag then
      return
    end

    RT.RefreshListRowVisual(self, true)

    local entry = self.entry
    if not entry then
      return
    end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(entry.name, THEME.heading[1], THEME.heading[2], THEME.heading[3])

    if entry.id == nil then
      GameTooltip:AddLine(L.LISTS_ROW_CLEAR_ENTRY, 1, 1, 1)
    else
      GameTooltip:AddLine(string.format(L.LISTS_ROW_QUEST_COUNT, Core.desiredQuestCount(entry.desiredQuests)), 1, 1, 1)

      if entry.difficulty then
        GameTooltip:AddLine(string.format(L.LISTS_ROW_TARGET_DIFFICULTY, Core.difficultyLabel(entry.difficulty)), 0.85, 0.78, 1)
      end
    end

    if RT.IsRolling() then
      GameTooltip:AddLine(L.LISTS_ROW_STOP_TO_SWITCH, 1, 0.4, 0.4)
    elseif RT.IsSelectionDifficultyLocked(entry) then
      GameTooltip:AddLine(L.LISTS_ROW_NEED_RESTED, 1, 0.4, 0.4)
    elseif entry.id == nil then
      GameTooltip:AddLine(L.LISTS_ROW_LEFT_CLICK_CLEAR, 0.8, 0.8, 0.8)
    else
      GameTooltip:AddLine(L.LISTS_ROW_LEFT_CLICK_LOAD, 0.8, 0.8, 0.8)
    end

    GameTooltip:Show()
    end)

  row:SetScript("OnLeave", function(self)
    if drag then
      return
    end

    RT.RefreshListRowVisual(self, false)
    GameTooltip:Hide()
    end)

  return row
end

local function CreatePanel(name, isList)
  local panel = CreateFrame("Frame", name, listsWindow)
  panel:SetHeight(PANEL_HEIGHT)
  Skin.Frame(panel, "soft")

  panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  panel.title:SetJustifyH("LEFT")
  panel.title:SetHeight(14)
  if panel.title.SetWordWrap then
    panel.title:SetWordWrap(false)
  end
  Skin.HeadingText(panel.title)

  panel.addButton = Skin.MakeButton(panel, {
    width = 20,
    height = 18,
    text = "+",
    points = { { "TOPRIGHT", panel, "TOPRIGHT", -6, -5 } },
    onClick = function()
      RT.RequestCreateSelection(panel.groupId)
      end,
    tipTitle = "LISTS_ADD_SELECTION_TITLE",
    tipBody = "LISTS_ADD_SELECTION_TOOLTIP",
  })

  panel.closeButton = Skin.MakeButton(panel, {
    width = 24,
    height = 18,
    text = ">>",
    points = { { "TOPLEFT", panel, "TOPLEFT", 6, -5 } },
    onClick = function()
      RT.SetOpenGroup(COLLAPSE_ALL)
      end,
    tipTitle = "LISTS_CLOSE_GROUP_TITLE",
    tipBody = "LISTS_CLOSE_GROUP_TOOLTIP",
  })
  panel.title:SetPoint("LEFT", panel.closeButton, "RIGHT", 6, 0)
  panel.title:SetPoint("RIGHT", panel.addButton, "LEFT", -6, 0)

  if not isList then
    panel.headerHit = CreateFrame("Button", nil, panel)
    panel.headerHit:SetPoint("TOPLEFT", panel.closeButton, "TOPRIGHT", 2, 0)
    panel.headerHit:SetPoint("BOTTOMRIGHT", panel.addButton, "BOTTOMLEFT", -2, 0)
    panel.headerHit:RegisterForClicks("RightButtonUp")
    panel.headerHit:RegisterForDrag("LeftButton")
    panel.headerHit:SetScript("OnClick", function(self)
      RT.ShowGroupContextMenu(self, panel.group)
      end)
    panel.headerHit:SetScript("OnDragStart", function()
      if panel.group then
        BeginGroupDrag(panel.group)
      end
      end)
    panel.headerHit:SetScript("OnDragStop", function()
      EndDrag()
      end)
  end

  local function Step(delta)
    SetScrollOffset(panel.groupId, ScrollOffset(panel.groupId) + delta)
    RefreshListsWindow()
  end

  panel.scrollUp = CreateFrame("Button", nil, panel)
  panel.scrollUp:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -5, -(PANEL_HEADER))
  Skin.ScrollButton(panel.scrollUp, "^")
  panel.scrollUp:SetScript("OnClick", function() Step(-1) end)
  panel.scrollUp:Hide()

  panel.scrollDown = CreateFrame("Button", nil, panel)
  panel.scrollDown:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -5, 6)
  Skin.ScrollButton(panel.scrollDown, "v")
  panel.scrollDown:SetScript("OnClick", function() Step(1) end)
  panel.scrollDown:Hide()

  panel.scrollText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  panel.scrollText:SetPoint("RIGHT", panel.scrollUp, "RIGHT", 0, 0)
  panel.scrollText:SetPoint("TOP", panel.scrollUp, "BOTTOM", 0, -4)
  panel.scrollText:SetWidth(SCROLLBAR_WIDTH)
  panel.scrollText:SetJustifyH("CENTER")
  Skin.MutedText(panel.scrollText)
  panel.scrollText:Hide()

  panel:EnableMouseWheel(true)
  panel:SetScript("OnMouseWheel", function(_, delta)
    SetScrollOffset(panel.groupId, ScrollOffset(panel.groupId) - delta)
    RefreshListsWindow()
    end)

  panel.emptyLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  panel.emptyLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -(PANEL_HEADER + 4))
  panel.emptyLabel:SetPoint("RIGHT", panel, "RIGHT", -8, 0)
  panel.emptyLabel:SetJustifyH("LEFT")
  RT.Localized(panel.emptyLabel, "LISTS_WINDOW_EMPTY")
  Skin.MutedText(panel.emptyLabel)

  panel.dropLayer = CreateFrame("Frame", nil, panel)
  panel.dropLayer:SetAllPoints(panel)
  panel.dropLayer:SetFrameLevel(panel:GetFrameLevel() + 10)

  panel.dropLine = panel.dropLayer:CreateTexture(nil, "OVERLAY")
  panel.dropLine:SetTexture(Skin.WHITE8X8)
  panel.dropLine:SetHeight(DROP_LINE_HEIGHT)
  panel.dropLine:Hide()

  panel.rows = {}
  for i = 1, VISIBLE_ROWS do
    local row = CreateListRow(panel, tostring(name) .. i)
    row:SetPoint("TOPLEFT", panel, "TOPLEFT", 6, -(PANEL_HEADER + (i - 1) * (ROW_HEIGHT + ROW_GAP)))
    row:EnableMouseWheel(true)
    row:SetScript("OnMouseWheel", function(_, delta)
      SetScrollOffset(panel.groupId, ScrollOffset(panel.groupId) - delta)
      RefreshListsWindow()
      end)
    panel.rows[i] = row
  end

  return panel
end

local function StackedText(value)
  local chars = {}
  local limit = math.floor(BAND_LABEL_SPAN / BAND_STACK_LINE)

  for character in string.gmatch(tostring(value or ""), "[\1-\127\194-\244][\128-\191]*") do
    chars[#(chars) + 1] = character

    if #(chars) >= limit then
      break
    end
  end

  return table.concat(chars, "\n")
end

local function EnsureBandRotator(band)
  if band.rotator ~= nil then
    return band.rotator
  end

  band.rotator = false

  if type(band.labelHolder.CreateAnimationGroup) ~= "function" then
    return false
  end

  local ok, group = pcall(band.labelHolder.CreateAnimationGroup, band.labelHolder)
  if not ok or not group then
    return false
  end

  local created, rotation = pcall(group.CreateAnimation, group, "Rotation")
  if not created or not rotation then
    return false
  end

  local applied = pcall(function()
    rotation:SetDegrees(BAND_LABEL_BOTTOM_UP and 90 or -90)
    rotation:SetDuration(0)
    rotation:SetOrigin("CENTER", 0, 0)
    group:SetLooping("REPEAT")
    group:Play()
    end)

  if not applied then
    return false
  end

  band.rotator = group

  return group
end

local function ResolveBandLabelMode(fontString)
  local mode = RT.bandLabelMode or "auto"

  if mode ~= "auto" then
    return mode
  end

  if type(fontString.SetRotation) == "function" then
    return "rotate"
  end

  return "stack"
end

local function ApplyBandLabel(band, name)
  local mode = ResolveBandLabelMode(band.label)

  if mode == "anim" and not EnsureBandRotator(band) then
    mode = "stack"
  end

  RT.bandLabelResolved = mode

  band.label:ClearAllPoints()

  if mode == "rotate" or mode == "anim" then
    band.label:SetWidth(BAND_LABEL_SPAN)
    band.label:SetHeight(14)
    band.label:SetJustifyH("CENTER")
    band.label:SetJustifyV("MIDDLE")
    band.label:SetPoint("CENTER", band.labelHolder, "CENTER", 0, 0)
    band.label:SetText(name)

    if mode == "rotate" then
      band.label:SetRotation(BAND_LABEL_BOTTOM_UP and (math.pi / 2) or -(math.pi / 2))
    end

    return
  end

  band.label:SetWidth(GROUP_BAND_WIDTH - 6)
  band.label:SetHeight(BAND_LABEL_SPAN)
  band.label:SetJustifyH("CENTER")
  band.label:SetJustifyV("MIDDLE")
  band.label:SetPoint("CENTER", band.labelHolder, "CENTER", 0, 0)
  band.label:SetText(mode == "short" and string.sub(name, 1, BAND_SHORT_CHARS) or StackedText(name))
end

function RT.SetBandLabelMode(mode)
  RT.bandLabelMode = mode
  RefreshListsWindow()

  return RT.bandLabelResolved
end

local function CreateGroupBand(index, isList)
  local band = CreateFrame("Button", "AutoCallboardGroupBand" .. tostring(index), listsWindow)
  band.isList = isList and true or false
  band:SetWidth(GROUP_BAND_WIDTH)
  band:SetHeight(PANEL_HEIGHT)
  band:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  Skin.Frame(band, "soft")

  if not isList then
    band:RegisterForDrag("LeftButton")
    band:SetScript("OnDragStart", function(self)
      if self.group then
        BeginGroupDrag(self.group)
      end
      end)
    band:SetScript("OnDragStop", function()
      EndDrag()
      end)
  end

  band.arrow = band:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  band.arrow:SetPoint("TOP", band, "TOP", 0, -6)
  band.arrow:SetText("<<")
  Skin.ApplyColor(band.arrow, "SetTextColor", THEME.heading)

  band.labelHolder = CreateFrame("Frame", nil, band)
  band.labelHolder:SetPoint("TOPLEFT", band, "TOPLEFT", 3, -BAND_LABEL_TOP)
  band.labelHolder:SetPoint("BOTTOMRIGHT", band, "BOTTOMRIGHT", -3, BAND_LABEL_BOTTOM)

  band.label = band.labelHolder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  band.label:SetJustifyH("CENTER")

  band.count = band:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  band.count:SetPoint("BOTTOM", band, "BOTTOM", 0, 6)
  band.count:SetWidth(GROUP_BAND_WIDTH - 6)
  band.count:SetJustifyH("CENTER")
  Skin.MutedText(band.count)

  band:SetScript("OnClick", function(self, mouseButton)
    if not self.isList and not self.group then
      return
    end

    if mouseButton == "RightButton" then
      if not self.isList then
        RT.ShowGroupContextMenu(self, self.group)
      end

      return
    end

    if self.isList then
      RT.SetOpenGroup(nil)
    else
      RT.SetOpenGroup(self.group.id)
    end
    end)

  band:SetScript("OnEnter", function(self)
    if drag then
      return
    end

    Skin.ApplyColor(self, "SetBackdropBorderColor", THEME.buttonHoverBorder)

    if not self.isList and not self.group then
      return
    end

    local groupId
    local title = L.LISTS_WINDOW_TITLE

    if not self.isList then
      groupId = self.group.id
      title = self.group.name
    end

    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(title, THEME.heading[1], THEME.heading[2], THEME.heading[3])
    GameTooltip:AddLine(string.format(L.LISTS_ROW_QUEST_COUNT_GROUP,
        Core.selectionCount(AccountProfile(), groupId)), 1, 1, 1)
    GameTooltip:AddLine(L.LISTS_OPEN_GROUP_TOOLTIP, 0.8, 0.8, 0.8)
    GameTooltip:Show()
    end)

  band:SetScript("OnLeave", function(self)
    if drag then
      return
    end

    Skin.Frame(self, "soft")
    GameTooltip:Hide()
    end)

  return band
end

local function ContainerWidths()
  local profile = AccountProfile()
  local widths = {}
  local openKey = OpenContainerKey()

  widths[LIST_KEY] = (openKey == LIST_KEY) and LIST_WIDTH or GROUP_BAND_WIDTH

  for i = 1, #(profile.groups) do
    local id = profile.groups[i].id
    widths[id] = (id == openKey) and GROUP_OPEN_WIDTH or GROUP_BAND_WIDTH
  end

  if animation then
    local eased = animation.progress

    if animation.openingKey and widths[animation.openingKey] then
      local full = (animation.openingKey == LIST_KEY) and LIST_WIDTH or GROUP_OPEN_WIDTH
      widths[animation.openingKey] = GROUP_BAND_WIDTH + (full - GROUP_BAND_WIDTH) * eased
    end

    if animation.closingKey and widths[animation.closingKey] then
      local full = (animation.closingKey == LIST_KEY) and LIST_WIDTH or GROUP_OPEN_WIDTH
      widths[animation.closingKey] = full - (full - GROUP_BAND_WIDTH) * eased
    end
  end

  return widths, openKey
end

local function LayoutPanels()
  local profile = AccountProfile()
  local widths, openKey = ContainerWidths()
  local listWidth = widths[LIST_KEY]
  local total = listWidth + WINDOW_EDGE * 2
  local groupCount = #(profile.groups)

  for i = 1, groupCount do
    total = total + (widths[profile.groups[i].id] or GROUP_BAND_WIDTH) + PANEL_GAP
  end

  listsWindow:SetWidth(total)
  listsWindow:SetHeight(WINDOW_HEIGHT)

  local listIsOpen = (openKey == LIST_KEY) and not animation

  if listIsOpen then
    listPanel:ClearAllPoints()
    listPanel:SetWidth(listWidth)
    listPanel:SetPoint("TOPRIGHT", listsWindow, "TOPRIGHT", -WINDOW_EDGE, -TOP_STRIP)
    listPanel:Show()
    listBand:Hide()
  else
    listPanel:Hide()
    listBand:ClearAllPoints()
    listBand:SetWidth(listWidth)
    listBand:SetPoint("TOPRIGHT", listsWindow, "TOPRIGHT", -WINDOW_EDGE, -TOP_STRIP)
    listBand:Show()
  end

  local offset = WINDOW_EDGE + listWidth + PANEL_GAP

  for i = 1, groupCount do
    local group = profile.groups[i]
    local width = widths[group.id] or GROUP_BAND_WIDTH

    if group.id == openKey and not animation then
      groupPanel:ClearAllPoints()
      groupPanel:SetWidth(width)
      groupPanel:SetPoint("TOPRIGHT", listsWindow, "TOPRIGHT", -offset, -TOP_STRIP)
      groupPanel:Show()
      groupBands[i]:Hide()
    else
      local band = groupBands[i]
      band:ClearAllPoints()
      band:SetWidth(width)
      band:SetPoint("TOPRIGHT", listsWindow, "TOPRIGHT", -offset, -TOP_STRIP)
      band:Show()
    end

    offset = offset + width + PANEL_GAP
  end

  for i = groupCount + 1, #(groupBands) do
    groupBands[i]:Hide()
  end

  if animation or openKey == nil or openKey == LIST_KEY then
    groupPanel:Hide()
  end
end

local function FillPanel(panel, entries, storedCount)
  panel.entries = entries
  panel.storedCount = storedCount or #(entries)

  local maxOffset = math.max(0, #(entries) - VISIBLE_ROWS)
  local offset = math.min(ScrollOffset(panel.groupId), maxOffset)

  SetScrollOffset(panel.groupId, offset)

  if maxOffset > 0 then
    panel.scrollUp:Show()
    panel.scrollDown:Show()
    panel.scrollText:SetText(tostring(offset + 1) .. "-" .. tostring(math.min(#(entries), offset + VISIBLE_ROWS)))
    panel.scrollText:Show()
  else
    panel.scrollUp:Hide()
    panel.scrollDown:Hide()
    panel.scrollText:Hide()
  end

  local rowWidth = maxOffset > 0 and -(SCROLLBAR_WIDTH + 10) or -6

  local shownRows = 0

  for i = 1, VISIBLE_ROWS do
    local row = panel.rows[i]
    local entry = entries[offset + i]

    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", panel, "TOPLEFT", 6, -(PANEL_HEADER + (i - 1) * (ROW_HEIGHT + ROW_GAP)))
    row:SetPoint("RIGHT", panel, "RIGHT", rowWidth, 0)

    if entry then
      shownRows = shownRows + 1
      row.entry = entry

      if entry.difficulty then
        row.title:SetText(entry.name .. " " .. Skin.AccentCode() .. "[" .. Core.difficultyLabel(entry.difficulty) .. "]|r")
      else
        row.title:SetText(entry.name)
      end

      RT.RefreshListRowVisual(row, false)
      row:Show()
    else
      row.entry = nil
      row:Hide()
    end
  end

  if (storedCount or #(entries)) == 0 then
    panel.emptyLabel:ClearAllPoints()
    panel.emptyLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 8,
        -(PANEL_HEADER + shownRows * (ROW_HEIGHT + ROW_GAP) + 4))
    panel.emptyLabel:SetPoint("RIGHT", panel, "RIGHT", -8, 0)
    panel.emptyLabel:Show()
  else
    panel.emptyLabel:Hide()
  end
end

RefreshListsWindow = function()
  if not listsWindow then
    return
  end

  local profile = AccountProfile()

  RT.noneSelectionEntry.name = L.LISTS_NONE_ENTRY

  LayoutPanels()

  listPanel.groupId = nil
  listBand.groupId = nil

  local listStored = Core.selectionsInContainer(profile, nil)

  if IsListOpen() and not animation then
    listPanel.title:SetText(L.LISTS_WINDOW_TITLE)

    local listEntries = { RT.noneSelectionEntry }
    for i = 1, #(listStored) do
      table.insert(listEntries, listStored[i])
    end

    FillPanel(listPanel, listEntries, #(listStored))
  end

  ApplyBandLabel(listBand, L.LISTS_WINDOW_TITLE)
  listBand.count:SetText(tostring(#(listStored)))
  Skin.ApplyColor(listBand.label, "SetTextColor", THEME.text)
  Skin.Frame(listBand, "soft")

  if listsWindow.newGroupButton then
    RT.SetButtonEnabled(listsWindow.newGroupButton, not Core.groupsFull(profile))
  end

  local openId = OpenGroupId()
  local openGroup = openId and Core.findGroup(profile, openId) or nil

  if openGroup and not animation then
    groupPanel.groupId = openGroup.id
    groupPanel.group = openGroup
    groupPanel.title:SetText(openGroup.name)
    FillPanel(groupPanel, Core.selectionsInContainer(profile, openGroup.id))
  end

  for i = 1, #(profile.groups) do
    local band = groupBands[i]
    local group = profile.groups[i]

    band.group = group
    band.groupId = group.id
    ApplyBandLabel(band, group.name)
    band.count:SetText(tostring(Core.selectionCount(profile, group.id)))
    Skin.ApplyColor(band.label, "SetTextColor", THEME.text)
    Skin.Frame(band, "soft")
  end
end

RT.RefreshListsWindow = function()
  return RefreshListsWindow()
end

local function HideDropFeedback(panel)
  if panel then
    panel.dropLine:Hide()
  end
end

local highlightedBand

local function ClearBandHighlights()
  if not highlightedBand then
    return
  end

  Skin.Frame(highlightedBand, "soft")
  highlightedBand = nil
end

local function DropTargetUnderCursor()
  if not listsWindow then
    return nil
  end

  local scale = listsWindow:GetEffectiveScale() or 1
  local x, y = GetCursorPosition()

  if not x then
    return nil
  end

  x, y = x / scale, y / scale

  local panels = { listPanel, groupPanel }

  for i = 1, #(panels) do
    if IsUnder(panels[i], x, y) then
      return panels[i], panels[i]:GetTop() - y, false
    end
  end

  if IsUnder(listBand, x, y) then
    return listBand, 0, true
  end

  for i = 1, #(groupBands) do
    if IsUnder(groupBands[i], x, y) then
      return groupBands[i], 0, true
    end
  end

  return nil
end

local function GapUnderCursor(panel, depth)
  local entries = panel.entries or {}
  local offset = ScrollOffset(panel.groupId)
  local slot = math.floor((depth - PANEL_HEADER) / (ROW_HEIGHT + ROW_GAP) + 0.5)

  if slot < 0 then
    slot = 0
  elseif slot > VISIBLE_ROWS then
    slot = VISIBLE_ROWS
  end

  local gap = offset + slot

  if gap > #(entries) then
    gap = #(entries)
  end

  if panel == listPanel and gap < 1 then
    gap = 1
  end

  return gap, gap - offset
end

local function ShowDropFeedback(panel, gap, visibleSlot, refused)
  local rowWidth = (panel.storedCount or 0) > VISIBLE_ROWS and -(SCROLLBAR_WIDTH + 10) or -6

  panel.dropLine:ClearAllPoints()
  panel.dropLine:SetPoint("TOPLEFT", panel, "TOPLEFT", 6,
      -(PANEL_HEADER + visibleSlot * (ROW_HEIGHT + ROW_GAP)) + 1)
  panel.dropLine:SetPoint("RIGHT", panel, "RIGHT", rowWidth, 0)

  if refused then
    panel.dropLine:SetVertexColor(DROP_REFUSED_BORDER[1], DROP_REFUSED_BORDER[2],
        DROP_REFUSED_BORDER[3], 1)
  else
    Skin.ApplyColor(panel.dropLine, "SetVertexColor", THEME.checkboxChecked)
  end

  panel.dropLine:Show()
end

local function GroupFrame(index)
  local profile = AccountProfile()
  local group = profile.groups[index]

  if not group then
    return nil
  end

  if group.id == OpenContainerKey() and not animation then
    return groupPanel
  end

  return groupBands[index]
end

local function ResetContainerAlpha()
  listPanel:SetAlpha(1)
  listBand:SetAlpha(1)
  groupPanel:SetAlpha(1)

  for i = 1, #(groupBands) do
    groupBands[i]:SetAlpha(1)
  end
end

local function GroupIndexAt(x)
  local count = Core.groupCount(AccountProfile())

  if count == 0 then
    return nil
  end

  for i = 1, count do
    local frame = GroupFrame(i)
    local left = frame and frame:GetLeft()
    local right = frame and frame:GetRight()

    if left and right and x > (left + right) / 2 then
      return i
    end
  end

  return count
end

local function ShowGroupDropLine(index)
  local frame = GroupFrame(index)
  local edge = frame and frame:GetRight()
  local windowEdge = listsWindow:GetRight()

  if not edge or not windowEdge then
    return
  end

  listsWindow.groupDropLine:ClearAllPoints()
  listsWindow.groupDropLine:SetPoint("TOP", listsWindow, "TOPRIGHT",
      (edge + PANEL_GAP / 2) - windowEdge, -TOP_STRIP)
  listsWindow.groupDropLine:SetHeight(PANEL_HEIGHT)
  listsWindow.groupDropLine:Show()
end

local function TrackGroupDrag()
  local scale = listsWindow:GetEffectiveScale() or 1
  local x = GetCursorPosition()

  drag.targetIndex = nil

  if not x then
    return
  end

  x = x / scale

  if not IsUnder(listsWindow, x, (listsWindow:GetTop() or 0) - 1) then
    return
  end

  local index = GroupIndexAt(x)

  if not index then
    return
  end

  drag.targetIndex = index
  ShowGroupDropLine(index)
end

local function TrackDrag()
  if not drag then
    return
  end

  HideDropFeedback(listPanel)
  HideDropFeedback(groupPanel)
  ClearBandHighlights()
  listsWindow.groupDropLine:Hide()

  if drag.kind == "group" then
    TrackGroupDrag()
    return
  end

  drag.target = nil
  drag.beforeId = nil
  drag.noop = false
  drag.refused = false

  local target, depth, isBand = DropTargetUnderCursor()

  if not target then
    return
  end

  local movingIn = not Core.sameContainer(drag.groupId, target.groupId)
  local refused = movingIn and Core.selectionsFull(AccountProfile(), target.groupId)

  drag.target = target
  drag.refused = refused

  if isBand then
    highlightedBand = target

    if refused then
      Skin.ApplyColor(target, "SetBackdropColor", DROP_REFUSED_FILL)
      Skin.ApplyColor(target, "SetBackdropBorderColor", DROP_REFUSED_BORDER)
    else
      Skin.ApplyColor(target, "SetBackdropColor", THEME.selection)
      Skin.ApplyColor(target, "SetBackdropBorderColor", THEME.checkboxChecked)
    end

    drag.noop = not movingIn
    return
  end

  local gap, visibleSlot = GapUnderCursor(target, depth)
  local entries = target.entries or {}
  local nextEntry = entries[gap + 1]
  local beforeId = nextEntry and nextEntry.id or nil

  if beforeId == drag.id then
    beforeId = nil
    drag.noop = true
  end

  drag.beforeId = beforeId

  ShowDropFeedback(target, gap, visibleSlot, refused)
end

BeginSelectionDrag = function(entry)
  drag = { kind = "selection", id = entry.id, name = entry.name, groupId = entry.groupId }
  GameTooltip:Hide()
  RefreshRowVisuals()
  listsWindow:SetScript("OnUpdate", TrackDrag)
  TrackDrag()
end

BeginGroupDrag = function(group)
  drag = { kind = "group", id = group.id }
  GameTooltip:Hide()

  local index = Core.findGroupIndex(AccountProfile(), group.id)
  local frame = index and GroupFrame(index)

  if frame then
    frame:SetAlpha(DRAG_SOURCE_ALPHA)
  end

  listsWindow:SetScript("OnUpdate", TrackDrag)
  TrackDrag()
end

EndDrag = function()
  local pending = drag

  drag = nil

  if listsWindow then
    listsWindow:SetScript("OnUpdate", nil)
    HideDropFeedback(listPanel)
    HideDropFeedback(groupPanel)
    ClearBandHighlights()
    listsWindow.groupDropLine:Hide()
    ResetContainerAlpha()
    RefreshRowVisuals()
  end

  if not pending then
    return
  end

  if pending.kind == "group" then
    if not pending.targetIndex then
      return
    end

    local nextProfile, moved = Core.moveGroupToIndex(
        AccountProfile(), pending.id, pending.targetIndex)

    if moved then
      RT.SaveAccountProfile(nextProfile)
      RefreshListsWindow()
    end

    return
  end

  if not pending.target or pending.refused then
    return
  end

  if pending.noop and Core.sameContainer(pending.groupId, pending.target.groupId) then
    return
  end

  local nextProfile, ok = Core.moveSelectionTo(
      AccountProfile(), pending.id, pending.target.groupId, pending.beforeId)

  if ok then
    RT.SaveAccountProfile(nextProfile)
    RefreshListsWindow()
  end
end

RT.IsDraggingSelection = function()
  return drag ~= nil
end

function RT.SetOpenGroup(groupId, immediate)
  local previous = RT.GetOpenGroupId()

  if previous == groupId then
    return
  end

  RT.SetOpenGroupId(groupId)

  if immediate or not listsWindow or not listsWindow:IsShown() then
    animation = nil
    RT.listsAnimating = false
    RefreshListsWindow()
    return
  end

  RT.listsAnimating = true
  animation = {
    startedAt = GetTime(),
    progress = 0,
    openingKey = OpenContainerKey(),
    closingKey = ContainerKeyFor(previous),
  }

  RefreshListsWindow()
end

function RT.UpdateListsAnimation()
  if not animation then
    return
  end

  local elapsed = GetTime() - animation.startedAt
  local progress = elapsed / ANIMATION_SECONDS

  if progress >= 1 then
    animation = nil
    RT.listsAnimating = false
    RefreshListsWindow()
    return
  end

  animation.progress = 1 - ((1 - progress) * (1 - progress))
  LayoutPanels()
end

function RT.IsListsAnimating()
  return animation ~= nil
end

function RT.CreateListsWindow()
  listsWindow = CreateFrame("Frame", "AutoCallboardListsWindow", UIParent)
  RT.listsWindow = listsWindow
  listsWindow:SetWidth(LIST_WIDTH + WINDOW_EDGE * 2)
  listsWindow:SetHeight(WINDOW_HEIGHT)
  listsWindow:SetFrameStrata("HIGH")
  if listsWindow.SetToplevel then
    listsWindow:SetToplevel(true)
  end
  listsWindow:EnableMouse(true)
  Skin.Frame(listsWindow)
  RT.RegisterSpecialFrame("AutoCallboardListsWindow")
  listsWindow:SetPoint("TOPRIGHT", RT.controlFrame, "TOPLEFT", -8, 0)

  listsWindow.closeButton = CreateFrame("Button", nil, listsWindow)
  listsWindow.closeButton:SetPoint("TOPRIGHT", listsWindow, "TOPRIGHT", -4, -3)
  Skin.CloseButton(listsWindow.closeButton, listsWindow)

  listsWindow.dropLayer = CreateFrame("Frame", nil, listsWindow)
  listsWindow.dropLayer:SetAllPoints(listsWindow)
  listsWindow.dropLayer:SetFrameLevel(listsWindow:GetFrameLevel() + 20)

  listsWindow.groupDropLine = listsWindow.dropLayer:CreateTexture(nil, "OVERLAY")
  listsWindow.groupDropLine:SetTexture(Skin.WHITE8X8)
  listsWindow.groupDropLine:SetWidth(DROP_LINE_HEIGHT)
  Skin.ApplyColor(listsWindow.groupDropLine, "SetVertexColor", THEME.checkboxChecked)
  listsWindow.groupDropLine:Hide()

  listsWindow.newGroupButton = Skin.MakeButton(listsWindow, {
    width = 20,
    height = 18,
    text = "+",
    points = { { "TOPLEFT", listsWindow, "TOPLEFT", 6, -3 } },
    onClick = RT.RequestCreateGroup,
    tipTitle = "LISTS_NEW_GROUP_TITLE_SHORT",
    tipBody = "LISTS_NEW_GROUP_TOOLTIP",
  })

  listPanel = CreatePanel("AutoCallboardListPanel", true)
  groupPanel = CreatePanel("AutoCallboardGroupPanel", false)
  groupPanel:Hide()

  listBand = CreateGroupBand("List", true)
  listBand:Hide()

  for i = 1, Core.MAX_GROUPS do
    groupBands[i] = CreateGroupBand(i)
    groupBands[i]:Hide()
  end

  listsWindow:Hide()
end

function RT.ToggleListsWindow()
  if not listsWindow then
    RT.CreateListsWindow()
  end

  if listsWindow:IsShown() then
    listsWindow:Hide()
  else
    animation = nil
    RT.listsAnimating = false
    RefreshListsWindow()
    listsWindow:Show()
    if listsWindow.Raise then
      listsWindow:Raise()
    end
  end
end
