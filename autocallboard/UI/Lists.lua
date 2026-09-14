local Core = AutoCallboardCore
local Skin = AutoCallboardSkin
local L = AutoCallboardLocale
local RT = AutoCallboardRuntime
local Print = RT.Print
local state = RT.state

RT.noneSelectionEntry = { id = nil, name = "", desiredQuests = {} }

local BuildSelectionContextMenu

local function AccountProfile()
  return RT.GetAccountProfile()
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

function RT.IsSelectionActive(entry)
  return entry ~= nil and entry.id ~= nil and RT.GetActiveSelectionId() == entry.id
end

function RT.IsSelectionDifficultyLocked(entry)
  if not entry or entry.difficulty == nil then
    return false
  end

  if RT.IsSelectionActive(entry) then
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

  if RT.IsSelectionActive(entry) then
    RT.LoadSelectionPreset(RT.noneSelectionEntry)
    RT.RefreshListsWindow()
    return
  end

  if RT.IsSelectionDifficultyLocked(entry) then
    return
  end

  RT.LoadSelectionPreset(entry)
  RT.RefreshListsWindow()
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
      RT.RefreshListsWindow()
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
      RT.RefreshListsWindow()
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

      RT.RefreshListsWindow()
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

      RT.RefreshListsWindow()
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

      RT.RefreshListsWindow()
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
      RT.RefreshListsWindow()
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

      RT.RefreshListsWindow()
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
  RT.RefreshListsWindow()
end

local function BuildDifficultySubmenu(menu, entry)
  menu:Reset()
  menu:AddItem(entry.name, { header = true })
  menu:AddItem("< " .. L.LISTS_MENU_DIFFICULTY, {
    keepOpen = true,
    onClick = function()
      BuildSelectionContextMenu(menu, entry)
      end,
  })

  RT.AddDifficultySlider(menu, entry.difficulty, function(tier)
    RT.RequestSetSelectionDifficulty(entry, tier)
    end)

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
    RT.listsContextMenu:CloseWhenHidden(RT.listsWindow)
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

local function RowTooltip(row, entry)
  Skin.OpenTip(row, "ANCHOR_RIGHT", entry.name)

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
  elseif RT.IsSelectionActive(entry) then
    GameTooltip:AddLine(L.LISTS_ROW_LEFT_CLICK_UNLOAD, 0.8, 0.8, 0.8)
  elseif RT.IsSelectionDifficultyLocked(entry) then
    GameTooltip:AddLine(L.LISTS_ROW_NEED_RESTED, 1, 0.4, 0.4)
  elseif entry.id == nil then
    GameTooltip:AddLine(L.LISTS_ROW_LEFT_CLICK_CLEAR, 0.8, 0.8, 0.8)
  else
    GameTooltip:AddLine(L.LISTS_ROW_LEFT_CLICK_LOAD, 0.8, 0.8, 0.8)
  end

  GameTooltip:Show()
end

local browser = RT.BuildBrowser({
  names = {
    listPanel = "AutoCallboardListPanel",
    groupPanel = "AutoCallboardGroupPanel",
    band = "AutoCallboardGroupBand",
    row = "AutoCallboardListRow",
  },
  hasList = true,
  listReservedRows = 1,
  emptyKey = "LISTS_WINDOW_EMPTY",
  maxGroups = function() return Core.MAX_GROUPS end,
  groups = function() return AccountProfile().groups end,
  getOpen = function() return RT.GetOpenGroupId() end,
  setOpen = function(value) RT.SetOpenGroupId(value) end,
  listTitle = function() return L.LISTS_WINDOW_TITLE end,
  listEntries = function()
    RT.noneSelectionEntry.name = L.LISTS_NONE_ENTRY

    local stored = Core.selectionsInContainer(AccountProfile(), nil)
    local entries = { RT.noneSelectionEntry }

    for i = 1, #(stored) do
      entries[#(entries) + 1] = stored[i]
    end

    return entries, #(stored)
  end,
  groupEntries = function(groupId) return Core.selectionsInContainer(AccountProfile(), groupId) end,
  count = function(groupId) return Core.selectionCount(AccountProfile(), groupId) end,
  rowText = function(entry)
    if entry.difficulty then
      return entry.name .. " " .. Skin.AccentCode() .. "[" .. Core.difficultyLabel(entry.difficulty) .. "]|r"
    end

    return entry.name
  end,
  rowState = function(entry)
    return RT.IsSelectionActive(entry), RT.IsRolling() or RT.IsSelectionDifficultyLocked(entry)
  end,
  rowTooltip = RowTooltip,
  onRowClick = function(row, entry, mouseButton)
    if mouseButton == "RightButton" then
      if entry.id ~= nil then
        RT.ShowSelectionContextMenu(row, entry)
      end
    else
      RT.RequestLoadSelection(entry)
    end
  end,
  canDrag = function(entry) return entry.id ~= nil end,
  entryGroup = function(entry) return entry.groupId end,
  dropRefused = function(groupId) return Core.selectionsFull(AccountProfile(), groupId) end,
  moveEntry = function(id, groupId, beforeId)
    local nextProfile, ok = Core.moveSelectionTo(AccountProfile(), id, groupId, beforeId)

    if ok then
      RT.SaveAccountProfile(nextProfile)
    end

    return ok
  end,
  moveGroup = function(id, index)
    local nextProfile, moved = Core.moveGroupToIndex(AccountProfile(), id, index)

    if moved then
      RT.SaveAccountProfile(nextProfile)
    end

    return moved
  end,
  groupMenu = function(anchor, group) RT.ShowGroupContextMenu(anchor, group) end,
  bandLines = function(groupId)
    return {
      { string.format(L.LISTS_ROW_QUEST_COUNT_GROUP, Core.selectionCount(AccountProfile(), groupId)), 1, 1, 1 },
      { L.LISTS_OPEN_GROUP_TOOLTIP, 0.8, 0.8, 0.8 },
    }
  end,
  onAdd = function(groupId) RT.RequestCreateSelection(groupId) end,
  addTip = { "LISTS_ADD_SELECTION_TITLE", "LISTS_ADD_SELECTION_TOOLTIP" },
  newGroup = {
    onClick = function() RT.RequestCreateGroup() end,
    tipTitle = "LISTS_NEW_GROUP_TITLE_SHORT",
    tipBody = "LISTS_NEW_GROUP_TOOLTIP",
    enabled = function() return not Core.groupsFull(AccountProfile()) end,
  },
  onAnimating = function(flag) RT.listsAnimating = flag end,
  createWindow = function(width, height)
    local window = CreateFrame("Frame", "AutoCallboardListsWindow", UIParent)
    RT.listsWindow = window
    window:SetWidth(width)
    window:SetHeight(height)
    window:SetFrameStrata("HIGH")
    if window.SetToplevel then
      window:SetToplevel(true)
    end
    window:EnableMouse(true)
    Skin.Frame(window)
    RT.RegisterSpecialFrame("AutoCallboardListsWindow")
    window:SetPoint("TOPRIGHT", RT.controlFrame, "TOPLEFT", -8, 0)

    window.closeButton = CreateFrame("Button", nil, window)
    window.closeButton:SetPoint("TOPRIGHT", window, "TOPRIGHT", -4, -3)
    Skin.CloseButton(window.closeButton, window)

    return window
  end,
})

RT.listsBrowser = browser
RT.CreateListsWindow = browser.Create
RT.RefreshListsWindow = browser.Refresh
RT.ToggleListsWindow = browser.Toggle
RT.SetOpenGroup = browser.SetOpen
RT.UpdateListsAnimation = browser.UpdateAnimation
RT.IsListsAnimating = browser.IsAnimating
RT.IsDraggingSelection = browser.IsDragging
RT.RefreshListRowVisual = browser.RefreshRowVisual
