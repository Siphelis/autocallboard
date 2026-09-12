local Core = AutoCallboardCore
local Skin = AutoCallboardSkin
local THEME = Skin.THEME
local L = AutoCallboardLocale
local RT = AutoCallboardRuntime
local Print = RT.Print
local Localized = RT.Localized

local Log = RT.Log

RT.echoPrefix = "AAM0x9"
RT.echoOpRefreshPerks = 330
RT.echoOpRefreshBuilds = 340
RT.echoOpBuildList = 540
RT.echoOpBuildActive = 542
RT.echoOpBuildSelect = 344
RT.buildsRefreshDelay = 5
RT.buildsRefreshThrottle = 30

RT.echoMaxChunks = 400
RT.echoStreamTimeout = 20
RT.echoStreams = {}

function RT.SendEchoMessage(opcode, body)
  if not SendAddonMessage or not UnitName then
    return false
  end

  local me = UnitName("player")
  if not me or me == "" then
    return false
  end

  local payload = tostring(opcode)
  if body and body ~= "" then
    payload = payload .. "\t" .. body
  end

  local ok = pcall(SendAddonMessage, RT.echoPrefix, payload, "WHISPER", me)

  return ok
end

function RT.ParseServerBuildList(body)
  if type(body) ~= "string" then
    return nil
  end

  local parsed = { slots = {} }
  local first = true

  for chunk in string.gmatch(body, "[^;]+") do
    if first then
      local active, maxSlots, unlocked = string.match(chunk, "^(%d+)|(%d+)|(%d+)|")

      if not active then
        return nil
      end

      parsed.active = tonumber(active)
      parsed.maxSlots = tonumber(maxSlots)
      parsed.unlocked = tonumber(unlocked)
      first = false
    else

      local slot, name = string.match(chunk, "^(%d+)|([^|]*)|")

      if slot then
        parsed.slots[tonumber(slot)] = { slot = tonumber(slot), name = name }
      end
    end
  end

  return parsed
end

function RT.HandleEchoPayload(opcode, body)
  if opcode == RT.echoOpBuildList then
    local parsed = RT.ParseServerBuildList(body)

    if parsed then
      RT.serverBuilds = parsed
      Log("builds", "liste recue actif=", parsed.active)
      RT.RefreshBuildsWindowIfShown()
      RT.RefreshEchoBar()
    end
  elseif opcode == RT.echoOpBuildActive then

    local slot = tonumber(string.match(tostring(body), "^(%d+)"))

    if slot and RT.serverBuilds then
      RT.serverBuilds.active = slot
      Log("builds", "slot actif = ", slot)
      RT.RefreshBuildsWindowIfShown()
      RT.RefreshEchoBar()
    end
  end
end

function RT.HandleEchoAddonMessage(message)
  if type(message) ~= "string" then
    return
  end

  local opcode, rest = string.match(message, "^(%d+)\t?(.*)$")
  opcode = tonumber(opcode)

  if not opcode then
    return
  end

  local mid, index, total, slice = string.match(rest, "^(@%x+)\t(%x+)/(%x+)\t?(.*)$")

  if not mid then
    RT.HandleEchoPayload(opcode, rest)
    return
  end

  index = tonumber(index, 16)
  total = tonumber(total, 16)

  if not index or not total
      or total < 1 or total > RT.echoMaxChunks
      or index < 1 or index > total then
    return
  end

  local now = GetTime()
  local key = tostring(opcode) .. mid
  local streams = RT.echoStreams

  for otherKey, stream in pairs(streams) do
    if now - stream.at > RT.echoStreamTimeout then
      streams[otherKey] = nil
    end
  end

  local stream = streams[key]
  if not stream then
    stream = { parts = {}, got = 0, total = total }
    streams[key] = stream
  end

  stream.at = now

  if not stream.parts[index] then
    stream.parts[index] = slice or ""
    stream.got = stream.got + 1
  end

  if stream.got >= stream.total then
    streams[key] = nil
    RT.HandleEchoPayload(opcode, table.concat(stream.parts, "", 1, stream.total))
  end
end

function RT.RefreshBuildsWindowIfShown()
  local buildsWindow = RT.buildsWindow

  if buildsWindow and buildsWindow:IsShown() and RT.RefreshBuildsWindow then
    RT.RefreshBuildsWindow()
  end
end

function RT.BuildLabel(build)
  local name = build and tostring(build.name or "") or ""

  if name == "" then
    return string.format(L.BUILD_SLOT_FALLBACK, tostring(build and build.slot or "?"))
  end

  return name
end

function RT.GetActiveBuild()
  local builds = RT.serverBuilds
  local slot = builds and tonumber(builds.active)

  if not slot or type(builds.slots) ~= "table" then
    return nil, slot
  end

  return builds.slots[slot], slot
end

function RT.GetSortedServerBuilds()
  local builds = RT.serverBuilds
  local sorted = {}

  if not builds or type(builds.slots) ~= "table" then
    return sorted
  end

  for slot, build in pairs(builds.slots) do
    if type(build) == "table" and tonumber(slot) then
      table.insert(sorted, build)
    end
  end

  table.sort(sorted, function(a, b)
    return (tonumber(a.slot) or 0) < (tonumber(b.slot) or 0)
  end)

  return sorted
end

function RT.RequestBuildsRefresh(source)
  local now = GetTime()

  if RT.lastBuildsRequestAt
      and now - RT.lastBuildsRequestAt < RT.buildsRefreshThrottle then
    return false
  end

  RT.lastBuildsRequestAt = now
  RT.SendEchoMessage(RT.echoOpRefreshPerks, "")
  local ok = RT.SendEchoMessage(RT.echoOpRefreshBuilds, "")
  Log("builds", "refresh demande source=", source, " ok=", ok)

  return ok
end

function RT.CanSwitchBuild()
  if UnitAffectingCombat and UnitAffectingCombat("player") then
    return false, L.BUILD_SWITCH_BLOCKED_COMBAT
  end

  return true
end

function RT.SwitchToBuild(slot, source)
  slot = tonumber(slot)

  if not slot then
    return false
  end

  local builds = RT.GetSortedServerBuilds()
  local label = string.format(L.BUILD_SLOT_FALLBACK, tostring(slot))

  for i = 1, #(builds) do
    if tonumber(builds[i].slot) == slot then
      label = RT.BuildLabel(builds[i])
      break
    end
  end

  local _, activeSlot = RT.GetActiveBuild()
  if activeSlot == slot then
    return false
  end

  local allowed, reason = RT.CanSwitchBuild()
  if not allowed then
    Print(reason)
    Log("builds", "bascule refusee slot=", slot, " raison=", reason)
    return false
  end

  if not RT.SendEchoMessage(RT.echoOpBuildSelect, tostring(slot)) then
    Print(L.BUILD_SWITCH_SEND_FAILED)
    Log("builds", "bascule echouee slot=", slot)
    return false
  end

  Log("builds", "bascule emise slot=", slot, " nom=", label, " source=", source)

  return true
end

function RT.RefreshBuildRowVisual(row, hovered)
  if not row.build then
    return
  end

  local _, activeSlot = RT.GetActiveBuild()

  Skin.PaintRow(row,
      activeSlot and tonumber(row.build.slot) == activeSlot,
      hovered,
      not RT.CanSwitchBuild())
end

local function BuildTooltip(owner, build, extraKey)
  local _, activeSlot = RT.GetActiveBuild()
  local allowed, reason = RT.CanSwitchBuild()

  Skin.OpenTip(owner, "ANCHOR_RIGHT", RT.BuildLabel(build))

  if tonumber(build.slot) == activeSlot then
    GameTooltip:AddLine(L.BUILDS_ROW_ACTIVE, 0.8, 0.8, 0.8)
  elseif not allowed then
    GameTooltip:AddLine(reason, 1, 0.4, 0.4)
  else
    GameTooltip:AddLine(L.BUILDS_ROW_LEFT_CLICK_SWITCH, 0.8, 0.8, 0.8)
  end

  if extraKey then
    GameTooltip:AddLine(L[extraKey], 0.8, 0.8, 0.8)
  end

  GameTooltip:Show()
end

function RT.CreateBuildRow(index)
  local row = Skin.Row(RT.buildsWindow,
      "AutoCallboardBuildRow" .. tostring(index), 24)

  row:RegisterForDrag("LeftButton")

  row:SetScript("OnClick", function(self)
    if not self.build then
      return
    end

    if RT.SwitchToBuild(self.build.slot, "fenetre") then
      RT.buildsWindow:Hide()
    end
    end)

  row:SetScript("OnDragStart", function(self)
    if self.build then
      RT.BeginEchoAssign(tonumber(self.build.slot))
    end
    end)

  row:SetScript("OnDragStop", function()
    RT.EndEchoAssign()
    end)

  row:SetScript("OnEnter", function(self)
    RT.RefreshBuildRowVisual(self, true)

    if self.build then
      BuildTooltip(self, self.build, "ECHO_BAR_DRAG_TIP")
    end
    end)

  row:SetScript("OnLeave", function(self)
    RT.RefreshBuildRowVisual(self, false)
    GameTooltip:Hide()
    end)

  return row
end

function RT.RefreshBuildsWindow()
  local buildsWindow = RT.buildsWindow

  if not buildsWindow then
    return
  end

  local builds = RT.GetSortedServerBuilds()
  local count = #(builds)
  local rows = RT.buildRows

  for i = 1, math.max(count, #(rows)) do
    local row = rows[i]

    if not row and i <= count then
      row = RT.CreateBuildRow(i)
      rows[i] = row
    end

    if row then
      local build = builds[i]

      if build then
        row.build = build
        row.title:SetText(RT.BuildLabel(build))
        row:ClearAllPoints()
        local y = -(36 + (i - 1) * 26)
        row:SetPoint("TOPLEFT", buildsWindow, "TOPLEFT", 12, y)
        row:SetPoint("TOPRIGHT", buildsWindow, "TOPRIGHT", -12, y)
        row:Show()
        RT.RefreshBuildRowVisual(row, false)
      else
        row.build = nil
        row:Hide()
      end
    end
  end

  if buildsWindow.emptyLabel then
    if count == 0 then
      buildsWindow.emptyLabel:Show()
    else
      buildsWindow.emptyLabel:Hide()
    end
  end

  buildsWindow:SetHeight(36 + (math.max(count, 1) * 26) + 40)
end

function RT.CreateBuildsWindow()
  local buildsWindow = Skin.Window("AutoCallboardBuildsWindow", {
    width = 220,
    height = 120,
    titleKey = "BUILDS_WINDOW_TITLE",
    titleFont = "GameFontNormalSmall",
    titleAt = "TOPLEFT",
    titleX = 12,
    titleY = -10,
    close = true,
  })
  RT.buildsWindow = buildsWindow
  RT.buildRows = RT.buildRows or {}

  local anchor = RT.controlFrame and RT.controlFrame.buildsButton
  if anchor then
    buildsWindow:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -6)
  else
    buildsWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  end

  buildsWindow:Hide()

  buildsWindow.emptyLabel = buildsWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  buildsWindow.emptyLabel:SetPoint("TOPLEFT", buildsWindow, "TOPLEFT", 12, -36)
  buildsWindow.emptyLabel:SetPoint("RIGHT", buildsWindow, "RIGHT", -12, 0)
  buildsWindow.emptyLabel:SetJustifyH("LEFT")
  Localized(buildsWindow.emptyLabel, "BUILDS_WINDOW_EMPTY")
  Skin.MutedText(buildsWindow.emptyLabel)

  buildsWindow.refreshButton = Skin.MakeButton(buildsWindow, {
    height = 22,
    textKey = "BUILDS_WINDOW_REFRESH_BUTTON",
    points = {
      { "BOTTOMLEFT", buildsWindow, "BOTTOMLEFT", 12, 10 },
      { "BOTTOMRIGHT", buildsWindow, "BOTTOMRIGHT", -12, 10 },
    },
    onClick = function()
      RT.lastBuildsRequestAt = nil
      RT.RequestBuildsRefresh("bouton")
      end,
  })
end

function RT.ToggleBuildsWindow()
  if not RT.buildsWindow then
    RT.CreateBuildsWindow()
  end

  local buildsWindow = RT.buildsWindow

  if buildsWindow:IsShown() then
    buildsWindow:Hide()
    return
  end

  RT.RequestBuildsRefresh("ouverture de la fenetre")
  RT.RefreshBuildsWindow()
  buildsWindow:Show()

  if buildsWindow.Raise then
    buildsWindow:Raise()
  end
end

local ECHO_SLOTS = Core.ECHO_BAR_SLOTS
local ECHO_CELL_W = 96
local ECHO_CELL_H = 22
local ECHO_GAP = 2
local ECHO_PAD = 2
local ECHO_DOT = 18
local ECHO_DOT_TEXTURE = [[Interface\Buttons\UI-RadioButton]]

local echoBar
local echoCells
local echoDotButton
local echoDotTexture
local echoDrag
local echoDropIndex
local echoCombatWatched = false

local function EchoBarState()
  local entry = RT.EnsureCharacterState and RT.EnsureCharacterState()

  if not entry then
    return nil
  end

  if type(entry.echoBar) ~= "table" then
    entry.echoBar = Core.copyEchoBar(nil)
  end

  return entry.echoBar
end

local function BuildBySlot(slot)
  local builds = RT.serverBuilds

  if not slot or not builds or type(builds.slots) ~= "table" then
    return nil
  end

  return builds.slots[slot]
end

local function PaintEchoCell(cell, hovered)
  local _, activeSlot = RT.GetActiveBuild()

  Skin.PaintRow(cell,
      cell.slot ~= nil and activeSlot == cell.slot,
      hovered,
      not RT.CanSwitchBuild())
end

local function SetEchoDropIndex(index)
  if index == echoDropIndex then
    return
  end

  if echoDropIndex and echoCells[echoDropIndex] then
    PaintEchoCell(echoCells[echoDropIndex], false)
  end

  echoDropIndex = index

  if index then
    PaintEchoCell(echoCells[index], true)
  end
end

local function EchoCellUnderCursor()
  if not echoBar or not echoBar:IsShown() or not GetCursorPosition then
    return nil
  end

  local scale = echoBar:GetEffectiveScale() or 1
  local x, y = GetCursorPosition()

  if not x then
    return nil
  end

  x = x / scale
  y = y / scale

  for i = 1, ECHO_SLOTS do
    if RT.IsUnder(echoCells[i], x, y) then
      return i
    end
  end

  return nil
end

local function TrackEchoDrop()
  SetEchoDropIndex(EchoCellUnderCursor())
end

local function ApplyEchoDrop(drag, target)
  local bar = EchoBarState()

  if not bar or bar.locked then
    return
  end

  if drag.fromIndex then
    if target == drag.fromIndex then
      return
    end

    local moved = bar.slots[drag.fromIndex]
    bar.slots[drag.fromIndex] = target and bar.slots[target] or nil

    if target then
      bar.slots[target] = moved
    end
  elseif target then
    for i = 1, ECHO_SLOTS do
      if bar.slots[i] == drag.slot then
        bar.slots[i] = nil
      end
    end

    bar.slots[target] = drag.slot
  else
    return
  end

  RT.TouchState()
  RT.RefreshEchoBar()
end

local function BeginEchoDrag(drag)
  echoDrag = drag
  GameTooltip:Hide()
  echoBar:SetScript("OnUpdate", TrackEchoDrop)
  TrackEchoDrop()
end

local function EndEchoDrag()
  echoBar:SetScript("OnUpdate", nil)

  local drag = echoDrag
  echoDrag = nil
  SetEchoDropIndex(nil)

  if drag then
    ApplyEchoDrop(drag, EchoCellUnderCursor())
  end
end

function RT.BeginEchoAssign(slot)
  local bar = EchoBarState()

  if not slot or not echoBar or not echoBar:IsShown() or not bar or bar.locked then
    return
  end

  BeginEchoDrag({ slot = slot })
end

function RT.EndEchoAssign()
  if echoDrag then
    EndEchoDrag()
  end
end

local function PaintEchoDot(locked)
  local color = locked and THEME.border or THEME.checkboxChecked
  echoDotTexture:SetVertexColor(color[1], color[2], color[3], 1)
end

local function ApplyEchoLock(locked)
  echoBar:SetMovable(not locked)

  for i = 1, ECHO_SLOTS do
    if locked then
      echoCells[i]:RegisterForDrag()
    else
      echoCells[i]:RegisterForDrag("LeftButton")
    end
  end

  PaintEchoDot(locked)
end

local function LayoutEchoBar(orientation)
  local horizontal = orientation ~= "V"

  if horizontal then
    echoBar:SetWidth(ECHO_PAD * 2 + ECHO_SLOTS * ECHO_CELL_W + (ECHO_SLOTS - 1) * ECHO_GAP)
    echoBar:SetHeight(ECHO_PAD * 2 + ECHO_CELL_H)
  else
    echoBar:SetWidth(ECHO_PAD * 2 + ECHO_CELL_W)
    echoBar:SetHeight(ECHO_PAD * 2 + ECHO_SLOTS * ECHO_CELL_H + (ECHO_SLOTS - 1) * ECHO_GAP)
  end

  for i = 1, ECHO_SLOTS do
    local cell = echoCells[i]
    cell:ClearAllPoints()
    cell:SetWidth(ECHO_CELL_W)

    if horizontal then
      cell:SetPoint("TOPLEFT", echoBar, "TOPLEFT",
          ECHO_PAD + (i - 1) * (ECHO_CELL_W + ECHO_GAP), -ECHO_PAD)
    else
      cell:SetPoint("TOPLEFT", echoBar, "TOPLEFT",
          ECHO_PAD, -(ECHO_PAD + (i - 1) * (ECHO_CELL_H + ECHO_GAP)))
    end
  end
end

local function CreateEchoCell(index)
  local cell = Skin.Row(echoBar, "AutoCallboardEchoCell" .. tostring(index),
      ECHO_CELL_H, "LeftButtonUp", "RightButtonUp")

  cell.index = index
  cell.title:SetJustifyH("CENTER")

  cell:SetScript("OnClick", function(self, button)
    local bar = EchoBarState()

    if not bar then
      return
    end

    if button == "RightButton" then
      if bar.locked or not self.slot then
        return
      end

      bar.slots[self.index] = nil
      RT.TouchState()
      RT.RefreshEchoBar()
      return
    end

    if self.slot then
      RT.SwitchToBuild(self.slot, "barre echo")
    end
    end)

  cell:SetScript("OnDragStart", function(self)
    local bar = EchoBarState()

    if not bar or bar.locked or not self.slot then
      return
    end

    BeginEchoDrag({ fromIndex = self.index })
    end)

  cell:SetScript("OnDragStop", function()
    if echoDrag then
      EndEchoDrag()
    end
    end)

  cell:SetScript("OnEnter", function(self)
    if echoDrag then
      return
    end

    PaintEchoCell(self, true)

    if self.slot then
      BuildTooltip(self, self.build or { slot = self.slot }, "ECHO_BAR_CLEAR_TIP")
    else
      Skin.OpenTip(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine(L.ECHO_BAR_EMPTY_TIP, 0.8, 0.8, 0.8)
      GameTooltip:Show()
    end
    end)

  cell:SetScript("OnLeave", function(self)
    if not echoDrag then
      PaintEchoCell(self, false)
    end

    GameTooltip:Hide()
    end)

  return cell
end

local function CreateEchoBar()
  if echoBar then
    return
  end

  echoBar = CreateFrame("Frame", "AutoCallboardEchoBar", UIParent)
  echoBar:SetFrameStrata("MEDIUM")
  echoBar:SetClampedToScreen(true)
  echoBar:EnableMouse(true)
  Skin.Frame(echoBar)

  echoCells = {}
  for i = 1, ECHO_SLOTS do
    echoCells[i] = CreateEchoCell(i)
  end

  echoDotButton = CreateFrame("Button", nil, echoBar)
  echoDotButton:SetWidth(ECHO_DOT)
  echoDotButton:SetHeight(ECHO_DOT)
  echoDotButton:SetPoint("CENTER", echoBar, "TOPLEFT", 0, 0)
  echoDotButton:RegisterForClicks("LeftButtonUp")
  echoDotButton:RegisterForDrag("LeftButton")

  echoDotTexture = echoDotButton:CreateTexture(nil, "OVERLAY")
  echoDotTexture:SetAllPoints(echoDotButton)
  echoDotTexture:SetTexture(ECHO_DOT_TEXTURE)
  echoDotTexture:SetTexCoord(0.25, 0.5, 0, 1)

  echoDotButton:SetScript("OnClick", function()
    local bar = EchoBarState()

    if not bar then
      return
    end

    bar.locked = not bar.locked
    ApplyEchoLock(bar.locked)
    RT.TouchState()
    end)

  echoDotButton:SetScript("OnDragStart", function()
    local bar = EchoBarState()

    if bar and not bar.locked and not InCombatLockdown() and not RT.state.appearance.locked then
      echoBar:StartMoving()
    end
    end)

  echoDotButton:SetScript("OnDragStop", function()
    echoBar:StopMovingOrSizing()

    local bar = EchoBarState()

    if bar then
      RT.SavePoint(echoBar, bar)
      RT.TouchState()
    end
    end)

  echoDotButton:SetScript("OnEnter", function(self)
    local bar = EchoBarState()

    Skin.OpenTip(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(bar and bar.locked and L.ECHO_BAR_LOCKED_TIP or L.ECHO_BAR_UNLOCKED_TIP,
        0.8, 0.8, 0.8)
    GameTooltip:Show()
    end)

  echoDotButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
    end)
end

local function WatchEchoCombat(enabled)
  local frame = RT.eventFrame

  if not frame or echoCombatWatched == enabled then
    return
  end

  echoCombatWatched = enabled
  local method = enabled and frame.RegisterEvent or frame.UnregisterEvent

  pcall(method, frame, "PLAYER_REGEN_DISABLED")
  pcall(method, frame, "PLAYER_REGEN_ENABLED")
end

function RT.RefreshEchoBar()
  if not echoBar or not echoBar:IsShown() then
    return
  end

  local bar = EchoBarState()

  if not bar then
    return
  end

  for i = 1, ECHO_SLOTS do
    local cell = echoCells[i]
    local slot = bar.slots[i]
    local build = BuildBySlot(slot)

    cell.slot = slot
    cell.build = build

    if slot then
      cell.title:SetText(build and RT.BuildLabel(build)
          or string.format(L.BUILD_SLOT_FALLBACK, tostring(slot)))
    else
      cell.title:SetText("")
    end

    PaintEchoCell(cell, echoDropIndex == i)
  end
end

function RT.ApplyEchoBar()
  local bar = EchoBarState()

  if not bar or not bar.enabled then
    if echoBar then
      echoBar:Hide()
    end

    WatchEchoCombat(false)
    return
  end

  CreateEchoBar()
  RT.RestorePoint(echoBar, bar)
  LayoutEchoBar(bar.orientation)
  ApplyEchoLock(bar.locked)
  echoBar:Show()
  RT.RefreshEchoBar()
  WatchEchoCombat(true)
end

function RT.IsEchoBarEnabled()
  local bar = EchoBarState()
  return bar ~= nil and bar.enabled == true
end

function RT.GetEchoBarOrientation()
  local bar = EchoBarState()
  return bar and bar.orientation or "H"
end

function RT.SetEchoBarEnabled(enabled)
  local bar = EchoBarState()

  if not bar then
    return
  end

  bar.enabled = enabled and true or false
  RT.TouchState()
  RT.ApplyEchoBar()
  RT.UpdateEchoBarControls()
end

function RT.ToggleEchoBarOrientation()
  local bar = EchoBarState()

  if not bar then
    return
  end

  bar.orientation = bar.orientation == "V" and "H" or "V"
  RT.TouchState()

  if echoBar then
    LayoutEchoBar(bar.orientation)
  end

  RT.UpdateEchoBarControls()
end

function RT.TriggerEchoSlot(index)
  index = tonumber(index)

  if not index or index < 1 or index > ECHO_SLOTS then
    return
  end

  local bar = EchoBarState()
  local slot = bar and bar.slots[index]

  if slot then
    RT.SwitchToBuild(slot, "raccourci")
  end
end

function RT.RefreshBindingNames()
  for i = 1, ECHO_SLOTS do
    _G["BINDING_NAME_AUTOCALLBOARD_ECHO" .. tostring(i)] =
        string.format(L.ECHO_BAR_BINDING_NAME, i)
  end
end

BINDING_HEADER_AutoCallboard = "AutoCallboard"
RT.RefreshBindingNames()
