local Core = AutoCallboardCore
local Skin = AutoCallboardSkin
local THEME = Skin.THEME
local RT = AutoCallboardRuntime
local IsUnder = RT.IsUnder

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

local COLLAPSE_ALL = 0
local LIST_KEY = 0

RT.BROWSER_COLLAPSE_ALL = COLLAPSE_ALL
RT.BROWSER_LIST_WIDTH = LIST_WIDTH
RT.BROWSER_WINDOW_EDGE = WINDOW_EDGE
RT.BROWSER_WINDOW_HEIGHT = WINDOW_HEIGHT

local instances = {}

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
  band.label:SetText(mode == "short" and Core.truncateLetters(name, BAND_SHORT_CHARS) or StackedText(name))
end

function RT.BuildBrowser(spec)
  local B = { spec = spec }
  local names = spec.names

  local window
  local listPanel
  local listBand
  local groupPanel
  local groupBands = {}
  local animation
  local drag
  local highlightedBand
  local scrollOffsets = { list = 0 }

  local function Groups()
    return spec.groups() or {}
  end

  local function FindGroupIndex(id)
    local groups = Groups()

    for i = 1, #(groups) do
      if groups[i].id == id then
        return i, groups[i]
      end
    end

    return nil
  end

  local function ContainerKeyFor(stored)
    if stored == nil then
      return spec.hasList and LIST_KEY or nil
    end

    if stored == COLLAPSE_ALL then
      return nil
    end

    return stored
  end

  local function OpenContainerKey()
    return ContainerKeyFor(spec.getOpen())
  end

  local function IsListOpen()
    return spec.hasList and OpenContainerKey() == LIST_KEY
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

  local function SetAnimating(flag)
    if spec.onAnimating then
      spec.onAnimating(flag)
    end
  end

  local Refresh
  local BeginEntryDrag
  local BeginGroupDrag
  local EndDrag

  local function RefreshRowVisual(row, hovered)
    local entry = row.entry
    if not entry then
      return
    end

    local selected, disabled = spec.rowState(entry)

    Skin.PaintRow(row, selected, hovered and not drag, disabled)

    if drag then
      row:SetAlpha(drag.id == entry.id and DRAG_SOURCE_ALPHA or 1)
    else
      row:SetAlpha(1)
    end
  end

  B.RefreshRowVisual = RefreshRowVisual

  local function RefreshRowVisuals()
    local panels = { listPanel, groupPanel }

    for i = 1, #(panels) do
      local panel = panels[i]

      if panel and panel.rows then
        for j = 1, #(panel.rows) do
          RefreshRowVisual(panel.rows[j], false)
        end
      end
    end
  end

  local function CreateRow(parent, name)
    local row = Skin.Row(parent, names.row .. tostring(name), ROW_HEIGHT, "LeftButtonUp", "RightButtonUp")
    row:RegisterForDrag("LeftButton")

    row:SetScript("OnDragStart", function(self)
      if self.entry and spec.canDrag and spec.canDrag(self.entry) then
        BeginEntryDrag(self.entry)
      end
      end)
    row:SetScript("OnDragStop", function()
      EndDrag()
      end)

    row:SetScript("OnClick", function(self, mouseButton)
      if self.entry then
        spec.onRowClick(self, self.entry, mouseButton)
      end
      end)

    row:SetScript("OnEnter", function(self)
      if drag then
        return
      end

      RefreshRowVisual(self, true)

      if self.entry then
        spec.rowTooltip(self, self.entry)
      end
      end)

    row:SetScript("OnLeave", function(self)
      if drag then
        return
      end

      RefreshRowVisual(self, false)
      GameTooltip:Hide()
      end)

    return row
  end

  local function CreatePanel(name, isList)
    local panel = CreateFrame("Frame", name, window)
    panel:SetHeight(PANEL_HEIGHT)
    Skin.Frame(panel, "soft")

    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    panel.title:SetJustifyH("LEFT")
    panel.title:SetHeight(14)
    if panel.title.SetWordWrap then
      panel.title:SetWordWrap(false)
    end
    Skin.HeadingText(panel.title)

    if spec.onAdd then
      panel.addButton = Skin.MakeButton(panel, {
        width = 20,
        height = 18,
        text = "+",
        points = { { "TOPRIGHT", panel, "TOPRIGHT", -6, -5 } },
        onClick = function()
          spec.onAdd(panel.groupId)
          end,
        tipTitle = spec.addTip and spec.addTip[1],
        tipBody = spec.addTip and spec.addTip[2],
      })
    end

    panel.closeButton = Skin.MakeButton(panel, {
      width = 24,
      height = 18,
      text = ">>",
      points = { { "TOPLEFT", panel, "TOPLEFT", 6, -5 } },
      onClick = function()
        B.SetOpen(COLLAPSE_ALL)
        end,
      tipTitle = "LISTS_CLOSE_GROUP_TITLE",
      tipBody = "LISTS_CLOSE_GROUP_TOOLTIP",
    })
    panel.title:SetPoint("LEFT", panel.closeButton, "RIGHT", 6, 0)

    if panel.addButton then
      panel.title:SetPoint("RIGHT", panel.addButton, "LEFT", -6, 0)
    else
      panel.title:SetPoint("RIGHT", panel, "RIGHT", -6, 0)
    end

    if not isList and (spec.groupMenu or spec.moveGroup) then
      panel.headerHit = CreateFrame("Button", nil, panel)
      panel.headerHit:SetPoint("TOPLEFT", panel.closeButton, "TOPRIGHT", 2, 0)
      panel.headerHit:SetPoint("BOTTOMRIGHT", panel.addButton or panel, panel.addButton and "BOTTOMLEFT" or "TOPRIGHT",
        panel.addButton and -2 or -6, panel.addButton and 0 or -23)
      panel.headerHit:RegisterForClicks("RightButtonUp")
      panel.headerHit:RegisterForDrag("LeftButton")
      panel.headerHit:SetScript("OnClick", function(self)
        if spec.groupMenu then
          spec.groupMenu(self, panel.group)
        end
        end)
      panel.headerHit:SetScript("OnDragStart", function()
        if panel.group and spec.moveGroup then
          BeginGroupDrag(panel.group)
        end
        end)
      panel.headerHit:SetScript("OnDragStop", function()
        EndDrag()
        end)
    end

    local function Step(delta)
      SetScrollOffset(panel.groupId, ScrollOffset(panel.groupId) + delta)
      Refresh()
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
      Refresh()
      end)

    panel.emptyLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    panel.emptyLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -(PANEL_HEADER + 4))
    panel.emptyLabel:SetPoint("RIGHT", panel, "RIGHT", -8, 0)
    panel.emptyLabel:SetJustifyH("LEFT")
    RT.Localized(panel.emptyLabel, spec.emptyKey)
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
      local row = CreateRow(panel, tostring(name) .. i)
      row:SetPoint("TOPLEFT", panel, "TOPLEFT", 6, -(PANEL_HEADER + (i - 1) * (ROW_HEIGHT + ROW_GAP)))
      row:EnableMouseWheel(true)
      row:SetScript("OnMouseWheel", function(_, delta)
        SetScrollOffset(panel.groupId, ScrollOffset(panel.groupId) - delta)
        Refresh()
        end)
      panel.rows[i] = row
    end

    return panel
  end

  local function CreateGroupBand(index, isList)
    local band = CreateFrame("Button", names.band .. tostring(index), window)
    band.isList = isList and true or false
    band:SetWidth(GROUP_BAND_WIDTH)
    band:SetHeight(PANEL_HEIGHT)
    band:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    Skin.Frame(band, "soft")

    if not isList and spec.moveGroup then
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
        if not self.isList and spec.groupMenu then
          spec.groupMenu(self, self.group)
        end

        return
      end

      if self.isList then
        B.SetOpen(nil)
      else
        B.SetOpen(self.group.id)
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
      local title = spec.listTitle and spec.listTitle() or ""

      if not self.isList then
        groupId = self.group.id
        title = self.group.name
      end

      Skin.OpenTip(self, "ANCHOR_LEFT", title)

      for _, line in ipairs(spec.bandLines(groupId)) do
        GameTooltip:AddLine(line[1], line[2], line[3], line[4])
      end

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
    local groups = Groups()
    local widths = {}
    local openKey = OpenContainerKey()

    if spec.hasList then
      widths[LIST_KEY] = (openKey == LIST_KEY) and LIST_WIDTH or GROUP_BAND_WIDTH
    end

    for i = 1, #(groups) do
      local id = groups[i].id
      widths[id] = (id == openKey) and GROUP_OPEN_WIDTH or GROUP_BAND_WIDTH
    end

    if animation then
      local eased = animation.progress

      if animation.openingKey and widths[animation.openingKey] then
        local full = (animation.openingKey == LIST_KEY and spec.hasList) and LIST_WIDTH or GROUP_OPEN_WIDTH
        widths[animation.openingKey] = GROUP_BAND_WIDTH + (full - GROUP_BAND_WIDTH) * eased
      end

      if animation.closingKey and widths[animation.closingKey] then
        local full = (animation.closingKey == LIST_KEY and spec.hasList) and LIST_WIDTH or GROUP_OPEN_WIDTH
        widths[animation.closingKey] = full - (full - GROUP_BAND_WIDTH) * eased
      end
    end

    return widths, openKey
  end

  local function LayoutPanels()
    local groups = Groups()
    local widths, openKey = ContainerWidths()
    local listWidth = spec.hasList and widths[LIST_KEY] or 0
    local total = listWidth + WINDOW_EDGE * 2
    local groupCount = #(groups)

    for i = 1, groupCount do
      total = total + (widths[groups[i].id] or GROUP_BAND_WIDTH) + PANEL_GAP
    end

    if not spec.hasList and groupCount > 0 then
      total = total - PANEL_GAP
    end

    window:SetWidth(math.max(total, spec.minWidth or 0))
    window:SetHeight(WINDOW_HEIGHT)

    local offset = WINDOW_EDGE

    if spec.hasList then
      local listIsOpen = (openKey == LIST_KEY) and not animation

      if listIsOpen then
        listPanel:ClearAllPoints()
        listPanel:SetWidth(listWidth)
        listPanel:SetPoint("TOPRIGHT", window, "TOPRIGHT", -WINDOW_EDGE, -TOP_STRIP)
        listPanel:Show()
        listBand:Hide()
      else
        listPanel:Hide()
        listBand:ClearAllPoints()
        listBand:SetWidth(listWidth)
        listBand:SetPoint("TOPRIGHT", window, "TOPRIGHT", -WINDOW_EDGE, -TOP_STRIP)
        listBand:Show()
      end

      offset = WINDOW_EDGE + listWidth + PANEL_GAP
    end

    for i = 1, groupCount do
      local group = groups[i]
      local width = widths[group.id] or GROUP_BAND_WIDTH

      if group.id == openKey and not animation then
        groupPanel:ClearAllPoints()
        groupPanel:SetWidth(width)
        groupPanel:SetPoint("TOPRIGHT", window, "TOPRIGHT", -offset, -TOP_STRIP)
        groupPanel:Show()
        groupBands[i]:Hide()
      else
        local band = groupBands[i]
        band:ClearAllPoints()
        band:SetWidth(width)
        band:SetPoint("TOPRIGHT", window, "TOPRIGHT", -offset, -TOP_STRIP)
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
        row.title:SetText(spec.rowText(entry))
        RefreshRowVisual(row, false)
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

  Refresh = function()
    if not window then
      return
    end

    if spec.beforeRefresh then
      spec.beforeRefresh()
    end

    LayoutPanels()

    if spec.hasList then
      listPanel.groupId = nil
      listBand.groupId = nil

      local listEntries, listStored = spec.listEntries()

      if IsListOpen() and not animation then
        listPanel.title:SetText(spec.listTitle())
        FillPanel(listPanel, listEntries, listStored)
      end

      ApplyBandLabel(listBand, spec.listTitle())
      listBand.count:SetText(tostring(listStored))
      Skin.ApplyColor(listBand.label, "SetTextColor", THEME.text)
      Skin.Frame(listBand, "soft")
    end

    if window.newGroupButton then
      RT.SetButtonEnabled(window.newGroupButton, spec.newGroup.enabled())
    end

    local openId = OpenGroupId()
    local _, openGroup = FindGroupIndex(openId)

    if openGroup and not animation then
      groupPanel.groupId = openGroup.id
      groupPanel.group = openGroup
      groupPanel.title:SetText(openGroup.name)
      FillPanel(groupPanel, spec.groupEntries(openGroup.id))
    end

    local groups = Groups()

    for i = 1, #(groups) do
      local band = groupBands[i]
      local group = groups[i]

      band.group = group
      band.groupId = group.id
      ApplyBandLabel(band, group.name)
      band.count:SetText(tostring(spec.count(group.id)))
      Skin.ApplyColor(band.label, "SetTextColor", THEME.text)
      Skin.Frame(band, "soft")
    end

    if spec.afterRefresh then
      spec.afterRefresh(window)
    end
  end

  B.Refresh = Refresh

  local function HideDropFeedback(panel)
    if panel then
      panel.dropLine:Hide()
    end
  end

  local function ClearBandHighlights()
    if not highlightedBand then
      return
    end

    Skin.Frame(highlightedBand, "soft")
    highlightedBand = nil
  end

  local function DropTargetUnderCursor()
    if not window then
      return nil
    end

    local scale = window:GetEffectiveScale() or 1
    local x, y = GetCursorPosition()

    if not x then
      return nil
    end

    x, y = x / scale, y / scale

    local panels = { listPanel, groupPanel }

    for i = 1, #(panels) do
      if panels[i] and IsUnder(panels[i], x, y) then
        return panels[i], panels[i]:GetTop() - y, false
      end
    end

    if listBand and IsUnder(listBand, x, y) then
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

    if panel == listPanel and gap < (spec.listReservedRows or 0) then
      gap = spec.listReservedRows
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
    local group = Groups()[index]

    if not group then
      return nil
    end

    if group.id == OpenContainerKey() and not animation then
      return groupPanel
    end

    return groupBands[index]
  end

  local function ResetContainerAlpha()
    if listPanel then
      listPanel:SetAlpha(1)
      listBand:SetAlpha(1)
    end

    groupPanel:SetAlpha(1)

    for i = 1, #(groupBands) do
      groupBands[i]:SetAlpha(1)
    end
  end

  local function GroupIndexAt(x)
    local count = #(Groups())

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
    local windowEdge = window:GetRight()

    if not edge or not windowEdge then
      return
    end

    window.groupDropLine:ClearAllPoints()
    window.groupDropLine:SetPoint("TOP", window, "TOPRIGHT",
        (edge + PANEL_GAP / 2) - windowEdge, -TOP_STRIP)
    window.groupDropLine:SetHeight(PANEL_HEIGHT)
    window.groupDropLine:Show()
  end

  local function TrackGroupDrag()
    local scale = window:GetEffectiveScale() or 1
    local x = GetCursorPosition()

    drag.targetIndex = nil

    if not x then
      return
    end

    x = x / scale

    if not IsUnder(window, x, (window:GetTop() or 0) - 1) then
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
    window.groupDropLine:Hide()

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
    local refused = movingIn and spec.dropRefused(target.groupId)

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

  BeginEntryDrag = function(entry)
    drag = { kind = "entry", id = entry.id, name = entry.name, groupId = spec.entryGroup(entry) }
    GameTooltip:Hide()
    RefreshRowVisuals()
    window:SetScript("OnUpdate", TrackDrag)
    TrackDrag()
  end

  BeginGroupDrag = function(group)
    drag = { kind = "group", id = group.id }
    GameTooltip:Hide()

    local index = FindGroupIndex(group.id)
    local frame = index and GroupFrame(index)

    if frame then
      frame:SetAlpha(DRAG_SOURCE_ALPHA)
    end

    window:SetScript("OnUpdate", TrackDrag)
    TrackDrag()
  end

  EndDrag = function()
    local pending = drag

    drag = nil

    if window then
      window:SetScript("OnUpdate", nil)
      HideDropFeedback(listPanel)
      HideDropFeedback(groupPanel)
      ClearBandHighlights()
      window.groupDropLine:Hide()
      ResetContainerAlpha()
      RefreshRowVisuals()
    end

    if not pending then
      return
    end

    if pending.kind == "group" then
      if pending.targetIndex and spec.moveGroup(pending.id, pending.targetIndex) then
        Refresh()
      end

      return
    end

    if not pending.target or pending.refused then
      return
    end

    if pending.noop and Core.sameContainer(pending.groupId, pending.target.groupId) then
      return
    end

    if spec.moveEntry(pending.id, pending.target.groupId, pending.beforeId) then
      Refresh()
    end
  end

  function B.IsDragging()
    return drag ~= nil
  end

  function B.SetOpen(groupId, immediate)
    local previous = spec.getOpen()

    if previous == groupId then
      return
    end

    spec.setOpen(groupId)

    if spec.onOpenGroup and OpenGroupId() then
      spec.onOpenGroup(OpenGroupId())
    end

    if immediate or not window or not window:IsShown() then
      animation = nil
      SetAnimating(false)
      Refresh()
      return
    end

    SetAnimating(true)
    animation = {
      startedAt = GetTime(),
      progress = 0,
      openingKey = OpenContainerKey(),
      closingKey = ContainerKeyFor(previous),
    }

    Refresh()
  end

  function B.UpdateAnimation()
    if not animation then
      return
    end

    local elapsed = GetTime() - animation.startedAt
    local progress = elapsed / ANIMATION_SECONDS

    if progress >= 1 then
      animation = nil
      SetAnimating(false)
      Refresh()
      return
    end

    animation.progress = 1 - ((1 - progress) * (1 - progress))
    LayoutPanels()
  end

  function B.IsAnimating()
    return animation ~= nil
  end

  function B.Window()
    return window
  end

  function B.IsShown()
    return window ~= nil and window:IsShown()
  end

  function B.Create()
    window = spec.createWindow(LIST_WIDTH + WINDOW_EDGE * 2, WINDOW_HEIGHT)

    window.dropLayer = CreateFrame("Frame", nil, window)
    window.dropLayer:SetAllPoints(window)
    window.dropLayer:SetFrameLevel(window:GetFrameLevel() + 20)

    window.groupDropLine = window.dropLayer:CreateTexture(nil, "OVERLAY")
    window.groupDropLine:SetTexture(Skin.WHITE8X8)
    window.groupDropLine:SetWidth(DROP_LINE_HEIGHT)
    Skin.ApplyColor(window.groupDropLine, "SetVertexColor", THEME.checkboxChecked)
    window.groupDropLine:Hide()

    if spec.newGroup then
      window.newGroupButton = Skin.MakeButton(window, {
        width = 20,
        height = 18,
        text = "+",
        points = { { "TOPLEFT", window, "TOPLEFT", 6, -3 } },
        onClick = spec.newGroup.onClick,
        tipTitle = spec.newGroup.tipTitle,
        tipBody = spec.newGroup.tipBody,
      })
    end

    if spec.hasList then
      listPanel = CreatePanel(names.listPanel, true)
    end

    groupPanel = CreatePanel(names.groupPanel, false)
    groupPanel:Hide()

    if spec.hasList then
      listBand = CreateGroupBand("List", true)
      listBand:Hide()
    end

    for i = 1, spec.maxGroups() do
      groupBands[i] = CreateGroupBand(i)
      groupBands[i]:Hide()
    end

    window:Hide()

    return window
  end

  function B.Toggle()
    if not window then
      B.Create()
    end

    if window:IsShown() then
      window:Hide()
    else
      animation = nil
      SetAnimating(false)
      Refresh()
      window:Show()
      if window.Raise then
        window:Raise()
      end

      if spec.onOpenGroup and OpenGroupId() then
        spec.onOpenGroup(OpenGroupId())
      end
    end
  end

  table.insert(instances, B)

  return B
end

function RT.UpdateBrowserAnimations()
  for i = 1, #(instances) do
    instances[i].UpdateAnimation()
  end
end

function RT.IsAnyBrowserAnimating()
  for i = 1, #(instances) do
    if instances[i].IsAnimating() then
      return true
    end
  end

  return false
end

function RT.RefreshBrowsers()
  for i = 1, #(instances) do
    instances[i].Refresh()
  end
end

function RT.SetBandLabelMode(mode)
  RT.bandLabelMode = mode
  RT.RefreshBrowsers()

  return RT.bandLabelResolved
end
