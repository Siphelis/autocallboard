local Core = AutoCallboardCore
local Skin = AutoCallboardSkin
local L = AutoCallboardLocale
local RT = AutoCallboardRuntime
local Print = RT.Print

local WINDOW_WIDTH = 320
local ROW_HEIGHT = 20
local ROW_GAP = 2
local VISIBLE_ROWS = 16
local TOP_STRIP = 26
local TOOLBAR_HEIGHT = 26
local EDGE = 10
local INDENT = 12

local BODY_TOP = TOP_STRIP + TOOLBAR_HEIGHT
local BODY_HEIGHT = VISIBLE_ROWS * (ROW_HEIGHT + ROW_GAP)
local WINDOW_HEIGHT = BODY_TOP + BODY_HEIGHT + EDGE

local WINDOW_NAME = "AutoCallboardRouteWindow"

local COMPACT_WIDTH = 260
local COMPACT_HEIGHT = TOP_STRIP + ROW_HEIGHT + EDGE
local COMPACT_STRATA = "FULLSCREEN_DIALOG"
local FULL_STRATA = "HIGH"

local TRANSPORT_WIDTH = 26
local TRANSPORT_HEIGHT = 20
local TRANSPORT_GAP = 4
local BROWSER_BUTTON_WIDTH = 90
local ICON_RECORD = [[Interface\AddOns\AutoCallboard\Media\Record]]
local ICON_PLAY = [[Interface\AddOns\AutoCallboard\Media\Play]]
local ICON_SKIP = [[Interface\AddOns\AutoCallboard\Media\Skip]]
local ICON_STOP = [[Interface\AddOns\AutoCallboard\Media\Stop]]
local RECORD_RED = { 0.86, 0.16, 0.16, 1 }

local RECORD_TIP = { tipTitle = "ROUTE_BUTTON_RECORD", tipBody = "ROUTE_BUTTON_RECORD_TOOLTIP" }
local RECORD_STOP_TIP = { tipTitle = "ROUTE_BUTTON_RECORD_STOP", tipBody = "ROUTE_BUTTON_RECORD_STOP_TOOLTIP" }
local PLAY_TIP = { tipTitle = "ROUTE_BUTTON_PLAY", tipBody = "ROUTE_BUTTON_PLAY_TOOLTIP" }
local PLAY_STOP_TIP = { tipTitle = "ROUTE_BUTTON_PLAY_STOP", tipBody = "ROUTE_BUTTON_PLAY_STOP_TOOLTIP" }
local SKIP_TIP = { tipTitle = "ROUTE_BUTTON_SKIP", tipBody = "ROUTE_BUTTON_SKIP_TOOLTIP" }

RT.ROUTE_ICONS = { record = ICON_RECORD, play = ICON_PLAY, skip = ICON_SKIP, stop = ICON_STOP }

local routeWindow
local rows = {}
local expanded = {}
local scrollOffset = 0
local entries = {}

local function AccountProfile()
  return RT.GetAccountProfile()
end

local function ExpansionKey(kind, id)
  return kind .. ":" .. tostring(id)
end

local function IsExpanded(kind, id)
  return expanded[ExpansionKey(kind, id)] and true or false
end

local function ToggleExpanded(kind, id)
  local key = ExpansionKey(kind, id)
  expanded[key] = not expanded[key] or nil
end

local function Marker(open)
  return open and "-" or "+"
end

local function AppendLines(list, steps, route)
  for index = 1, #(steps) do
    local step = steps[index]

    table.insert(list, {
      kind = route and "step" or "draftStep",
      route = route,
      stepIndex = index,
      depth = 1,
      step = step,
    })

    if step.actions then
      for actionIndex = 1, #(step.actions) do
        local action = step.actions[actionIndex]

        if Core.routeActionHasLine(action) then
          table.insert(list, {
            kind = route and "action" or "draftAction",
            route = route,
            stepIndex = index,
            actionIndex = actionIndex,
            depth = 2,
            action = action,
          })
        end
      end
    end
  end
end

local function LineText(entry, titles)
  if entry.action then
    return Core.routeActionLine(entry.action, titles)
  end

  return Core.routeStepLine(entry.step, titles)
end

local function BuildEntries()
  local list = {}
  local draft = RT.GetRouteDraft()

  if #(draft) > 0 or RT.IsRecordingRoute() then
    local open = IsExpanded("draft", 0)

    table.insert(list, { kind = "draft", depth = 0, open = open })

    if open then
      AppendLines(list, draft)
    end
  end

  local route = RT.GetActiveRoute()

  if route then
    local open = not IsExpanded("folded", route.id)

    table.insert(list, { kind = "route", route = route, depth = 0, open = open })

    if open then
      AppendLines(list, route.steps, route)
    end
  end

  return list
end

local function IsCurrentBlock(entry, activeId, currentBlock)
  return entry.kind == "step" and currentBlock ~= nil and entry.route.id == activeId
    and entry.stepIndex == currentBlock
end

local function RowText(entry, current)
  if current then
    return "> " .. tostring(entry.text or "")
  end

  if entry.kind == "draft" then
    return Marker(entry.open) .. " " .. L.ROUTE_DRAFT_TITLE
  end

  if entry.kind == "route" then
    return Marker(entry.open) .. " " .. Core.routeTitle(entry.route)
  end

  return tostring(entry.text or "")
end

local RequestSaveDraft

local function RequestSaveCategory(name, onCancel)
  local profile = AccountProfile()
  local choices = {}

  for category = 1, Core.routeCategoryCount() do
    choices[category] = {
      text = string.format(L.ROUTE_CATEGORY_CHOICE, Core.routeCategoryName(category),
        tostring(Core.routeCount(profile, category))),
      value = category,
    }
  end

  Skin.Dialog({
    title = L.ROUTE_CATEGORY_TITLE,
    body = string.format(L.ROUTE_CATEGORY_BODY, tostring(name)),
    choices = choices,
    acceptText = L.BUTTON_ACCEPT,
    cancelText = L.BUTTON_CANCEL,
    onAccept = function(category)
      RT.SaveRouteDraftAs(name, category)
      RT.RefreshRouteWindow()
      end,
    onCancel = onCancel,
  })
end

RequestSaveDraft = function(onCancel, name)
  if #(RT.GetRouteDraft()) == 0 then
    Print(L.ROUTE_DRAFT_EMPTY)
    return
  end

  Skin.Dialog({
    title = L.ROUTE_NEW_TITLE,
    body = "",
    editBox = { default = name or Core.peekNextRouteName(AccountProfile()), maxLetters = Core.MAX_SELECTION_NAME_LENGTH },
    acceptText = L.BUTTON_ACCEPT,
    cancelText = L.BUTTON_CANCEL,
    onAccept = function(text)
      RequestSaveCategory(text, function()
        RequestSaveDraft(onCancel, text)
        end)
      end,
    onCancel = onCancel,
  })
end

local RequestNameRecording

local function RequestDiscardRecording()
  Skin.Dialog({
    title = L.ROUTE_DISCARD_TITLE,
    body = string.format(L.ROUTE_DISCARD_TEXT, tostring(#(RT.GetRouteDraft()))),
    acceptText = L.BUTTON_OKAY,
    cancelText = L.BUTTON_CANCEL,
    onAccept = function()
      RT.ClearRouteDraft()
      end,
    onCancel = function()
      RequestNameRecording()
      end,
  })
end

RequestNameRecording = function()
  RequestSaveDraft(RequestDiscardRecording)
end

local function ToggleRecording()
  if not RT.IsRecordingRoute() then
    RT.StartRouteRecording("button")
    return
  end

  RT.StopRouteRecording("button")

  if #(RT.GetRouteDraft()) > 0 then
    RequestNameRecording()
  end
end

local function RequestRenameRoute(route)
  Skin.Dialog({
    title = string.format(L.LISTS_RENAME_DIALOG_TITLE, route.name),
    body = "",
    editBox = { default = route.name, maxLetters = Core.MAX_SELECTION_NAME_LENGTH },
    acceptText = L.BUTTON_ACCEPT,
    cancelText = L.BUTTON_CANCEL,
    onAccept = function(text)
      local nextProfile, ok = Core.renameRoute(AccountProfile(), route.id, text)

      if not ok then
        return
      end

      RT.SaveAccountProfile(nextProfile)
      RT.RefreshRouteWindow()
      end,
  })
end

local function RequestDeleteRoute(route)
  Skin.Dialog({
    title = route.name,
    body = string.format(L.ROUTE_DELETE_CONFIRM_TEXT, route.name),
    acceptText = L.BUTTON_DELETE,
    cancelText = L.BUTTON_CANCEL,
    onAccept = function()
      local nextProfile, ok = Core.deleteRoute(AccountProfile(), route.id)

      if not ok then
        return
      end

      RT.SaveAccountProfile(nextProfile)

      if RT.GetActiveRouteId() == route.id then
        RT.SetActiveRouteId(nil)
      end

      RT.RefreshRouteWindow()
      end,
  })
end

local function RequestOverwriteRoute(route)
  Skin.Dialog({
    title = route.name,
    body = string.format(L.ROUTE_OVERWRITE_CONFIRM_TEXT, route.name),
    acceptText = L.BUTTON_OKAY,
    cancelText = L.BUTTON_CANCEL,
    onAccept = function()
      RT.OverwriteRouteFromDraft(route.id)
      RT.RefreshRouteWindow()
      end,
  })
end

local function EnsureMenu(owner)
  if not RT.routeContextMenu then
    RT.routeContextMenu = Skin.Menu("AutoCallboardRouteContextMenu")
    RT.routeContextMenu:SetAutoClose(true)
  end

  RT.routeContextMenu:CloseWhenHidden(owner or routeWindow)

  return RT.routeContextMenu
end

function RT.ToggleLoadedRoute(id)
  if not RT.CanEditRoutes() then
    return false
  end

  if RT.GetActiveRouteId() == id then
    RT.SetActiveRouteId(nil)
  else
    RT.SetActiveRouteId(id)
  end

  return true
end

local BuildRouteMenu
local BuildRouteDifficultyMenu

local function BuildCategoryMenu(menu, route)
  menu:Reset()
  menu:AddItem(route.name, { header = true })
  menu:AddItem("< " .. L.ROUTE_MENU_CATEGORY, {
    keepOpen = true,
    onClick = function() BuildRouteMenu(menu, route) end,
  })

  for category = 1, Core.routeCategoryCount() do
    menu:AddItem(Core.routeCategoryName(category), {
      checked = route.category == category,
      onClick = function()
        local nextProfile, ok, err = Core.setRouteCategory(AccountProfile(), route.id, category)

        if err == "full" then
          Print(string.format(L.ROUTE_MAX_REACHED, tostring(Core.MAX_SAVED_ROUTES)))
        end

        if ok then
          RT.SaveAccountProfile(nextProfile)
          RT.RefreshRouteWindow()
        end
        end,
    })
  end

  menu:Layout()
end

BuildRouteDifficultyMenu = function(menu, route)
  menu:Reset()
  menu:AddItem(route.name, { header = true })
  menu:AddItem("< " .. L.ROUTE_MENU_START_DIFFICULTY, {
    keepOpen = true,
    onClick = function() BuildRouteMenu(menu, route) end,
  })

  RT.AddDifficultySlider(menu, route.difficulty, function(tier)
    local nextProfile, ok = Core.setRouteDifficulty(AccountProfile(), route.id, tier)

    if ok then
      RT.SaveAccountProfile(nextProfile)
      RT.RefreshRouteWindow()
    end
    end)

  menu:Layout()
end

BuildRouteMenu = function(menu, route)
  local hasDraft = #(RT.GetRouteDraft()) > 0
  local locked = not RT.CanEditRoutes()

  menu:Reset()
  menu:AddItem(route.name, { header = true })
  menu:AddItem(L.ROUTE_MENU_START_DIFFICULTY, {
    arrow = true,
    keepOpen = true,
    disabled = locked,
    onClick = function() BuildRouteDifficultyMenu(menu, route) end,
  })

  menu:AddItem(RT.GetActiveRouteId() == route.id and L.ROUTE_MENU_UNLOAD or L.ROUTE_MENU_LOAD, {
    disabled = locked,
    onClick = function() RT.ToggleLoadedRoute(route.id) end,
  })

  menu:AddItem(L.ROUTE_MENU_CATEGORY, {
    arrow = true,
    keepOpen = true,
    disabled = locked,
    onClick = function() BuildCategoryMenu(menu, route) end,
  })

  local shared = Core.isRouteShared(route)

  menu:AddItem(shared and L.ROUTE_MENU_UNSHARE or L.ROUTE_MENU_SHARE, {
    disabled = locked,
    onClick = function() RT.ShareRoute(route.id, not shared) end,
  })

  menu:AddItem(L.ROUTE_MENU_APPEND, {
    disabled = locked or not hasDraft,
    onClick = function()
      RT.AppendRouteFromDraft(route.id)
      RT.RefreshRouteWindow()
      end,
  })
  menu:AddItem(L.ROUTE_MENU_OVERWRITE, {
    disabled = locked or not hasDraft,
    onClick = function() RequestOverwriteRoute(route) end,
  })
  menu:AddItem(L.LISTS_MENU_RENAME, {
    disabled = locked,
    onClick = function() RequestRenameRoute(route) end,
  })
  menu:AddItem(L.LISTS_MENU_DELETE, {
    disabled = locked,
    onClick = function() RequestDeleteRoute(route) end,
  })

  menu:Layout()
end

function RT.ShowRouteMenu(row, route, owner)
  local menu = EnsureMenu(owner)
  BuildRouteMenu(menu, route)
  menu:OpenAt(row, "TOPLEFT", "TOPRIGHT", 4, 2)
end

local function BuildStepMenu(menu, entry)
  local step = entry.route.steps[entry.stepIndex]
  local locked = not RT.CanEditRoutes()

  menu:Reset()
  menu:AddItem(entry.text or "", { header = true })

  if step and step.resting then
    menu:AddItem(L.LISTS_MENU_DIFFICULTY, {
      arrow = true,
      keepOpen = true,
      disabled = locked,
      onClick = function()
        menu:Reset()
        menu:AddItem(entry.text or "", { header = true })
        menu:AddItem("< " .. L.LISTS_MENU_DIFFICULTY, {
          keepOpen = true,
          onClick = function() BuildStepMenu(menu, entry) end,
        })

        RT.AddDifficultySlider(menu, step.difficulty, function(tier)
          local nextProfile, ok = Core.setRouteStepDifficulty(AccountProfile(), entry.route.id,
            entry.stepIndex, tier)

          if ok then
            RT.SaveAccountProfile(nextProfile)
            RT.RefreshRouteWindow()
          end
          end)

        menu:Layout()
        end,
    })
  else
    menu:AddItem(L.ROUTE_MENU_DIFFICULTY_LOCKED, { disabled = true })
  end

  menu:AddItem(L.ROUTE_MENU_POINT_AT, {
    disabled = not (step and step.map and step.map ~= "" and step.x and step.y),
    onClick = function()
      RT.SetRouteArrowTarget(step, entry.actionIndex and step.actions[entry.actionIndex])
      end,
  })
  menu:AddItem(L.ROUTE_MENU_DELETE_LINE, {
    disabled = locked,
    onClick = function()
      local profile = AccountProfile()
      local nextProfile, ok

      if entry.kind == "action" then
        nextProfile, ok = Core.deleteRouteAction(profile, entry.route.id, entry.stepIndex, entry.actionIndex)
      else
        nextProfile, ok = Core.deleteRouteStep(profile, entry.route.id, entry.stepIndex)
      end

      if ok then
        RT.SaveAccountProfile(nextProfile)
        RT.RefreshRouteWindow()
      end
      end,
  })
  menu:Layout()
end

local function ShowStepMenu(row, entry)
  local menu = EnsureMenu()
  BuildStepMenu(menu, entry)
  menu:OpenAt(row, "TOPLEFT", "TOPRIGHT", 4, 2)
end

local function OnRowClick(row, mouseButton)
  local entry = row.entry

  if not entry then
    return
  end

  if mouseButton == "RightButton" then
    if entry.kind == "route" then
      RT.ShowRouteMenu(row, entry.route)
    elseif entry.kind == "step" or entry.kind == "action" then
      ShowStepMenu(row, entry)
    end

    return
  end

  if entry.kind == "step" or entry.kind == "action" then
    RT.StartRoutePlayback("row", entry.route.id, entry.stepIndex)
    return
  end

  if entry.kind == "route" then
    ToggleExpanded("folded", entry.route.id)
  elseif entry.kind == "draft" then
    ToggleExpanded("draft", 0)
  else
    return
  end

  RT.RefreshRouteWindow()
end

local function Scroll(delta)
  scrollOffset = scrollOffset + delta
  RT.RefreshRouteWindow()
end

local function CreateRow(index)
  local row = Skin.Row(routeWindow, "AutoCallboardRouteRow" .. index, ROW_HEIGHT,
      "LeftButtonUp", "RightButtonUp")

  row:SetScript("OnClick", OnRowClick)
  row:SetScript("OnEnter", function(self)
    Skin.PaintRow(self, self.selected, true)

    if self.entry and self.entry.text and self.entry.text ~= "" then
      Skin.OpenTip(self, "ANCHOR_RIGHT", self.entry.text)

      if self.entry.kind == "step" or self.entry.kind == "action" then
        GameTooltip:AddLine(L.ROUTE_ROW_PLAY_HINT, 1, 1, 1)
      end

      GameTooltip:Show()
    end
    end)
  row:SetScript("OnLeave", function(self)
    Skin.PaintRow(self, self.selected, false)
    GameTooltip:Hide()
    end)
  row:EnableMouseWheel(true)
  row:SetScript("OnMouseWheel", function(_, delta) Scroll(-delta) end)

  return row
end

local Toggle = RT.ShowIf

local function CompactLine()
  if RT.IsPlayingRoute() then
    local route, current = RT.GetActiveRoute(), RT.RouteCurrentBlock()

    if route and current then
      return Core.routeStepLine(route.steps[current])
    end

    return L.ROUTE_COMPACT_END
  end

  local line = RT.LastRecordedRouteLine()

  if line == "" then
    line = RT.IsRecordingRoute() and L.ROUTE_COMPACT_WAITING or L.ROUTE_COMPACT_IDLE
  end

  return line
end

local function SetTransport(button, busy, idleIcon, idleColor, idleTip, busyTip, enabled)
  local tip = busy and busyTip or idleTip

  if busy then
    Skin.SetButtonIcon(button, ICON_STOP)
  else
    Skin.SetButtonIcon(button, idleIcon, idleColor)
  end

  Skin.HoverTip(button, tip.tipTitle, tip.tipBody)
  RT.SetButtonEnabled(button, enabled)
end

local function RefreshCompact()
  local line = CompactLine()

  for i = 2, VISIBLE_ROWS do
    rows[i]:Hide()
    rows[i].entry = nil
  end

  local row = rows[1]
  row.entry = nil
  row.selected = false
  row.title:SetText(line)
  row:ClearAllPoints()
  row:SetPoint("TOPLEFT", routeWindow, "TOPLEFT", EDGE, -TOP_STRIP)
  row:SetPoint("RIGHT", routeWindow, "RIGHT", -EDGE, 0)
  Skin.PaintRow(row, false, false)
  row:Show()

  Toggle(routeWindow.emptyLabel, false)
  Toggle(routeWindow.scrollUp, false)
  Toggle(routeWindow.scrollDown, false)
  Toggle(routeWindow.playButton, false)
  Toggle(routeWindow.skipButton, false)
  Toggle(routeWindow.routesButton, false)
  Toggle(routeWindow.libraryButton, false)
  Toggle(routeWindow.recordButton, false)

  routeWindow:SetWidth(COMPACT_WIDTH)
  routeWindow:SetHeight(COMPACT_HEIGHT)
  routeWindow:SetFrameStrata(COMPACT_STRATA)
end

function RT.RefreshRouteWindow()
  if RT.RefreshRouteBrowsers then
    RT.RefreshRouteBrowsers()
  end

  if not routeWindow or not routeWindow:IsShown() then
    return
  end

  local compact = RT.IsRouteWindowCompact()

  routeWindow.compactButton:SetText(compact and L.ROUTE_BUTTON_EXPAND or L.ROUTE_BUTTON_COMPACT)

  if compact then
    RefreshCompact()
    return
  end

  routeWindow:SetWidth(WINDOW_WIDTH)
  routeWindow:SetHeight(WINDOW_HEIGHT)
  routeWindow:SetFrameStrata(FULL_STRATA)
  Toggle(routeWindow.playButton, true)
  Toggle(routeWindow.skipButton, true)
  Toggle(routeWindow.routesButton, true)
  Toggle(routeWindow.libraryButton, true)
  Toggle(routeWindow.recordButton, true)

  entries = BuildEntries()

  local activeId = RT.GetActiveRouteId()
  local currentBlock = RT.RouteCurrentBlock()

  local maxOffset = math.max(0, #(entries) - VISIBLE_ROWS)

  if scrollOffset > maxOffset then
    scrollOffset = maxOffset
  end

  if scrollOffset < 0 then
    scrollOffset = 0
  end

  local titles

  for i = 1, VISIBLE_ROWS do
    local row = rows[i]
    local entry = entries[i + scrollOffset]

    row.entry = entry

    if not entry then
      row:Hide()
    else
      if (entry.step or entry.action) and not entry.text then
        titles = titles or RT.QuestLogTitles()
        entry.text = LineText(entry, titles)
      end

      local current = IsCurrentBlock(entry, activeId, currentBlock)

      row.selected = current or entry.kind == "route"
      row.title:SetText(RowText(entry, current))
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", routeWindow, "TOPLEFT", EDGE + entry.depth * INDENT,
        -(BODY_TOP + (i - 1) * (ROW_HEIGHT + ROW_GAP)))
      row:SetPoint("RIGHT", routeWindow, "RIGHT", -(EDGE + 4), 0)
      Skin.PaintRow(row, row.selected, false)
      row:Show()
    end
  end

  Toggle(routeWindow.emptyLabel, #(entries) == 0)
  Toggle(routeWindow.scrollUp, scrollOffset > 0)
  Toggle(routeWindow.scrollDown, scrollOffset < maxOffset)

  local recording = RT.IsRecordingRoute()
  local playing = RT.IsPlayingRoute()

  SetTransport(routeWindow.recordButton, recording, ICON_RECORD, RECORD_RED, RECORD_TIP, RECORD_STOP_TIP,
    not playing)
  SetTransport(routeWindow.playButton, playing, ICON_PLAY, nil, PLAY_TIP, PLAY_STOP_TIP,
    playing or (not recording and activeId ~= nil))
  RT.SetButtonEnabled(routeWindow.skipButton, currentBlock ~= nil)
end

function RT.CreateRouteWindow()
  routeWindow = Skin.Window(WINDOW_NAME, {
    width = WINDOW_WIDTH,
    height = WINDOW_HEIGHT,
    titleKey = "ROUTE_WINDOW_TITLE",
    titleFont = "GameFontNormalSmall",
    titleAt = "TOPLEFT",
    titleX = 12,
    titleY = -9,
    close = true,
    noEsc = true,
    movable = true,
  })

  RT.routeWindow = routeWindow

  routeWindow.closeButton:HookScript("OnClick", function()
    RT.SetRouteWindowOpen(false)
    end)

  routeWindow.compactButton = Skin.MakeButton(routeWindow, {
    width = 22,
    height = 18,
    textKey = "ROUTE_BUTTON_COMPACT",
    points = { { "TOPRIGHT", routeWindow, "TOPRIGHT", -26, -5 } },
    onClick = function()
      RT.SetRouteWindowCompact(not RT.IsRouteWindowCompact())
      end,
    tipTitle = "ROUTE_BUTTON_COMPACT",
    tipBody = "ROUTE_BUTTON_COMPACT_TOOLTIP",
  })

  routeWindow.recordButton = Skin.MakeButton(routeWindow, {
    width = TRANSPORT_WIDTH,
    height = TRANSPORT_HEIGHT,
    icon = ICON_RECORD,
    iconColor = RECORD_RED,
    points = { { "TOPLEFT", routeWindow, "TOPLEFT", EDGE, -TOP_STRIP } },
    onClick = ToggleRecording,
    tipTitle = RECORD_TIP.tipTitle,
    tipBody = RECORD_TIP.tipBody,
  })

  routeWindow.playButton = Skin.MakeButton(routeWindow, {
    width = TRANSPORT_WIDTH,
    height = TRANSPORT_HEIGHT,
    icon = ICON_PLAY,
    points = { { "LEFT", routeWindow.recordButton, "RIGHT", TRANSPORT_GAP, 0 } },
    onClick = function() RT.ToggleRoutePlayback() end,
    tipTitle = PLAY_TIP.tipTitle,
    tipBody = PLAY_TIP.tipBody,
  })

  routeWindow.skipButton = Skin.MakeButton(routeWindow, {
    width = TRANSPORT_WIDTH,
    height = TRANSPORT_HEIGHT,
    icon = ICON_SKIP,
    points = { { "LEFT", routeWindow.playButton, "RIGHT", TRANSPORT_GAP, 0 } },
    onClick = function() RT.SkipRouteBlock() end,
    tipTitle = SKIP_TIP.tipTitle,
    tipBody = SKIP_TIP.tipBody,
  })

  routeWindow.libraryButton = Skin.MakeButton(routeWindow, {
    width = BROWSER_BUTTON_WIDTH,
    height = TRANSPORT_HEIGHT,
    textKey = "LIBRARY_BUTTON",
    points = { { "TOPRIGHT", routeWindow, "TOPRIGHT", -EDGE, -TOP_STRIP } },
    onClick = function() RT.ToggleLibraryWindow() end,
    tipTitle = "LIBRARY_WINDOW_TITLE",
    tipBody = "LIBRARY_BUTTON_TOOLTIP",
  })

  routeWindow.routesButton = Skin.MakeButton(routeWindow, {
    width = BROWSER_BUTTON_WIDTH,
    height = TRANSPORT_HEIGHT,
    textKey = "ROUTES_BROWSER_TITLE",
    points = { { "RIGHT", routeWindow.libraryButton, "LEFT", -TRANSPORT_GAP, 0 } },
    onClick = function() RT.ToggleRoutesWindow() end,
    tipTitle = "ROUTES_BROWSER_TITLE",
    tipBody = "ROUTES_BUTTON_TOOLTIP",
  })

  routeWindow.scrollUp = CreateFrame("Button", nil, routeWindow)
  routeWindow.scrollUp:SetPoint("TOPRIGHT", routeWindow, "TOPRIGHT", -5, -BODY_TOP)
  Skin.ScrollButton(routeWindow.scrollUp, "^")
  routeWindow.scrollUp:SetScript("OnClick", function() Scroll(-1) end)
  routeWindow.scrollUp:Hide()

  routeWindow.scrollDown = CreateFrame("Button", nil, routeWindow)
  routeWindow.scrollDown:SetPoint("BOTTOMRIGHT", routeWindow, "BOTTOMRIGHT", -5, EDGE)
  Skin.ScrollButton(routeWindow.scrollDown, "v")
  routeWindow.scrollDown:SetScript("OnClick", function() Scroll(1) end)
  routeWindow.scrollDown:Hide()

  routeWindow.emptyLabel = routeWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  routeWindow.emptyLabel:SetPoint("TOPLEFT", routeWindow, "TOPLEFT", EDGE, -(BODY_TOP + 4))
  routeWindow.emptyLabel:SetPoint("RIGHT", routeWindow, "RIGHT", -EDGE, 0)
  routeWindow.emptyLabel:SetJustifyH("LEFT")
  RT.Localized(routeWindow.emptyLabel, "ROUTE_WINDOW_EMPTY")
  Skin.MutedText(routeWindow.emptyLabel)

  routeWindow:EnableMouseWheel(true)
  routeWindow:SetScript("OnMouseWheel", function(_, delta) Scroll(-delta) end)

  for i = 1, VISIBLE_ROWS do
    rows[i] = CreateRow(i)
    rows[i]:Hide()
  end

  routeWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  routeWindow:Hide()

  return routeWindow
end

function RT.ToggleRouteWindow()
  if routeWindow and routeWindow:IsShown() then
    RT.SetRouteWindowOpen(false)
    routeWindow:Hide()
    return
  end

  RT.ShowRouteWindow()

  if routeWindow.Raise then
    routeWindow:Raise()
  end
end

function RT.ShowRouteWindow()
  if not routeWindow then
    RT.CreateRouteWindow()
  end

  RT.SetRouteWindowOpen(true)
  routeWindow:Show()
  RT.RefreshRouteWindow()
end

function RT.RestoreRouteWindow()
  if RT.IsRouteWindowOpen() then
    RT.ShowRouteWindow()
  end
end
