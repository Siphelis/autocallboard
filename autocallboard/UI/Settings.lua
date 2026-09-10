local RT, Core, Skin, L = AutoCallboardRuntime, AutoCallboardCore, AutoCallboardSkin, AutoCallboardLocale
local settings, pages, buttons, checks
local draft, layoutDraft
local ACTIONS = {
  {"BUTTON_LISTS", "ToggleListsWindow"}, {"BUTTON_BUILDS", "ToggleBuildsWindow"},
  {"ADDON_NAME_TOOLTIP"}, {"BUTTON_START", "StartRolling"},
  {"BUTTON_SHARE", "ShareAcceptedQuest"}, {"BUTTON_QUESTS", "ShowQuestWindow"},
  {"BUTTON_EXPORT", "ShowQuestDataWindow", "export"}, {"BUTTON_IMPORT", "ShowQuestDataWindow", "import"},
  {"UI_ETERNALS", "ShowSettings", 1}, {"UI_HELP", "ShowAddonHelp"},
  {"UI_SETTINGS", "ShowSettings"}, {"AUTO_CURRENT_INSTANCE_LABEL", "ToggleInstanceMode"},
}
local orderRows, colorButtons, sliders = {}, {}, {}

local function Config() return RT.state.appearance end
local function Character()
  local entry = RT.EnsureCharacterState()
  if not entry.toolbar then entry.toolbar = Core.copyToolbar() end
  return entry
end
local function Allowed()
  if InCombatLockdown() or RT.questPanelChanging then RT.Print(L.UI_BUSY); return false end
  return true
end
local function Label(id) return id == 3 and "Callboard" or L[ACTIONS[id][1]] end
local function Invoke(id)
  local action = ACTIONS[id]
  if id == 4 and RT.IsRolling() then RT.StopRolling(L.ROLL_STOPPED)
  elseif action[2] then RT[action[2]](action[3]) end
end
function RT.ToggleInstanceMode()
  RT.SetField("autoCurrentInstanceQuest", not RT.state.autoCurrentInstanceQuest)
  if RT.state.autoCurrentInstanceQuest then RT.ShowAutoCurrentInstanceWarning() end
end

local function Button(parent, label, x, y, width, callback)
  return Skin.MakeButton(parent, {textKey = label, width = width or 140, height = 24,
    point = {"TOPLEFT", parent, "TOPLEFT", x, y}, onClick = callback})
end
local function Check(parent, label, x, y, callback)
  local check = Skin.SettingCheckbox(parent, {labelKey = label,
    point = {"TOPLEFT", parent, "TOPLEFT", x, y}, onClick = callback})
  check._acbLabel:ClearAllPoints()
  check._acbLabel:SetPoint("LEFT", check, "RIGHT", 8, 0)
  return check
end

local goldTotal, goldLast, goldCurrent, goldSession, goldConfig
function RT.RefreshGoldDisplay()
  local text = RT.questGoldText
  if not text then return end
  local config, tracker = Config(), RT.GetGoldTrackerState()
  local current, session = RT.trackedQuestSpend or 0, RT.sessionGoldSpent or 0
  if goldTotal == tracker.totalSpent and goldLast == tracker.lastQuestSpent and goldCurrent == current
      and goldSession == session and goldConfig == config then return end
  goldTotal, goldLast, goldCurrent, goldSession, goldConfig = tracker.totalSpent, tracker.lastQuestSpent, current, session, config
  local parts = {}
  for _, item in ipairs({{"goldTotal", "UI_TOTAL", tracker.totalSpent}, {"goldLast", "UI_LAST", tracker.lastQuestSpent},
    {"goldCurrent", "UI_CURRENT", RT.trackedQuestSpend or 0}, {"goldSession", "UI_SESSION", RT.sessionGoldSpent or 0}}) do
    if config[item[1]] then parts[#parts + 1] = L[item[2]] .. ": " .. RT.FormatMoney(item[3]) end
  end
  text:SetText(table.concat(parts, "  |  "))
end

local function PlaceGold()
  local text, frame = RT.questGoldText, RT.controlFrame
  if not text then return end
  text:SetParent(Config().goldMain and frame or RT.questWindow)
  text:ClearAllPoints()
  text:SetPoint("BOTTOMLEFT", text:GetParent(), "BOTTOMLEFT", Config().goldMain and 10 or 24, Config().goldMain and 9 or 32)
  text:SetWidth(Config().goldMain and frame:GetWidth() - 20 or 540)
  RT.RefreshGoldDisplay()
end

function RT.LayoutMainToolbar()
  local frame = RT.controlFrame
  if not buttons or InCombatLockdown() then return end
  local order = Character().toolbar
  local width, x, row = 424, 10, 0
  local function PlaceButton(button)
    local label = button:GetFontString()
    local size = math.min(240, math.max(54, (label and label:GetStringWidth() or 50) + 18))
    if x + size > 630 then row, x = row + 1, 10 end
    button:SetWidth(size)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -30 - row * 29)
    button:Show()
    x = x + size + 5
    width = math.max(width, x + 5)
  end
  for _, button in pairs(buttons) do button:Hide() end
  for _, id in ipairs(order) do
    local button = buttons[id]
    if not button then
      button = Skin.MakeButton(frame, {height = 24, textKey = ACTIONS[id][1], onClick = function() Invoke(id) end})
      buttons[id] = button
    end
    PlaceButton(button)
  end
  if frame.settingsButton and not frame.settingsButton:IsShown() then PlaceButton(frame.settingsButton) end
  local extra = row * 29 + (Config().goldMain and 22 or 0)
  RT.controlCollapsedWidth, RT.controlCollapsedHeight = width, 84 + extra
  RT.controlExpandedHeight = 620 + extra
  RT.summonStatusText:ClearAllPoints()
  RT.summonStatusText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -59 - row * 29)
  RT.summonStatusText:SetWidth(frame:GetWidth() - 20)
  if RT.questWindow then
    RT.questWindow:ClearAllPoints()
    RT.questWindow:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -82 - row * 29)
  end
  if not RT.questPanelChanging then
    local expanded = RT.IsQuestWindowShown() and not RT.questWindowCreating
    RT.SetControlFrameSize(expanded and RT.controlExpandedWidth or width, expanded and RT.controlExpandedHeight or RT.controlCollapsedHeight)
  end
  PlaceGold()
end

local function RefreshOrder()
  local sequence, selected = {}, {}
  for _, id in ipairs(layoutDraft) do sequence[#sequence + 1], selected[id] = id, true end
  for id = 1, #ACTIONS do if not selected[id] then sequence[#sequence + 1] = id end end
  for index, id in ipairs(sequence) do
    local row = orderRows[index]
    row.id = id
    row.check:SetChecked(selected[id])
    row.check._acbLabel:SetText(Label(id))
    RT.SetButtonEnabled(row.up, selected[id] and index > 1)
    RT.SetButtonEnabled(row.down, selected[id] and index < #layoutDraft)
  end
end
local function Move(index, delta)
  local nextIndex = index + delta
  if layoutDraft[index] and layoutDraft[nextIndex] then
    layoutDraft[index], layoutDraft[nextIndex] = layoutDraft[nextIndex], layoutDraft[index]
    RefreshOrder()
  end
end
local function RefreshDraft()
  for key, check in pairs(checks) do check:SetChecked(draft[key]) end
  for key, slider in pairs(sliders) do slider:SetDisplayValue(draft[key]) end
  for key, button in pairs(colorButtons) do
    button:SetText(L[key == "background" and "UI_BACKGROUND" or "UI_ACCENT"] .. string.format("  #%06X", draft[key]))
  end
  RefreshOrder()
end
local function PickColor(key)
  if not Allowed() then return end
  local picker, before = ColorPickerFrame, draft[key]
  if not picker then return end
  picker:Hide()
  picker.func, picker.opacityFunc, picker.cancelFunc = nil, nil, nil
  picker.hasOpacity = false
  picker:SetColorRGB(Skin.UnpackColor(before))
  picker.func = function()
    local r, g, b = picker:GetColorRGB()
    draft[key] = math.floor(r * 255 + 0.5) * 65536 + math.floor(g * 255 + 0.5) * 256 + math.floor(b * 255 + 0.5)
    RefreshDraft()
  end
  picker.cancelFunc = function() draft[key] = before; RefreshDraft() end
  picker:Show()
end
local function SelectPage(index)
  for i, page in ipairs(pages) do if i == index then page:Show() else page:Hide() end end
end

local function CreateSettings()
  if settings then return end
  settings = Skin.Window("AutoCallboardSettings", {width = 580, height = 560, movable = true,
    titleKey = "UI_SETTINGS", close = true})
  RT.settingsWindow = settings
  settings:SetPoint("CENTER", UIParent, "CENTER")
  settings:Hide()
  pages, checks = {}, {}
  for i, key in ipairs({"UI_GENERAL", "UI_APPEARANCE", "UI_TOOLBAR", "UI_GOLD"}) do
    local index = i
    Button(settings, key, 18 + (i - 1) * 137, -40, 130, function() SelectPage(index) end)
    local page = CreateFrame("Frame", nil, settings)
    page:SetPoint("TOPLEFT", 18, -85); page:SetPoint("BOTTOMRIGHT", -18, 62)
    pages[i] = page
  end
  for i, key in ipairs({"background", "accent"}) do
    local field = key
    colorButtons[key] = Button(pages[2], i == 1 and "UI_BACKGROUND" or "UI_ACCENT", 0, -(i - 1) * 42, 260, function() PickColor(field) end)
  end
  for i, spec in ipairs({{"scale", "UI_SCALE", 0.2, 1.4}, {"opacity", "UI_OPACITY", 0.25, 1}}) do
    local key = spec[1]
    sliders[key] = Skin.Slider(pages[2], {width = 250, min = spec[3], max = spec[4], step = 0.05,
      title = L[spec[2]], format = function(value) return string.format("%d%%", value * 100 + 0.5) end,
      onCommit = function(value) draft[key] = value end})
    RT.Localized(sliders[key].titleText, spec[2])
    sliders[key]:SetPoint("TOPLEFT", pages[2], "TOPLEFT", 0, -125 - (i - 1) * 75)
  end
  checks.locked = Check(pages[2], "UI_LOCK", 0, -265, function(self) draft.locked = self:GetChecked() and true or false end)
  for index = 1, #ACTIONS do
    local row = {}
    orderRows[index] = row
    row.check = Check(pages[3], "UI_TOOLBAR", 0, -(index - 1) * 29, function(self)
      local id = row.id
      for i, value in ipairs(layoutDraft) do if value == id then table.remove(layoutDraft, i); RefreshOrder(); return end end
      layoutDraft[#layoutDraft + 1] = id
      RefreshOrder()
    end)
    row.up = Button(pages[3], "UI_UP", 400, -(index - 1) * 29, 60, function() Move(index, -1) end)
    row.down = Button(pages[3], "UI_DOWN", 465, -(index - 1) * 29, 60, function() Move(index, 1) end)
  end
  for i, spec in ipairs({{"goldMain", "UI_GOLD_MAIN"}, {"goldTotal", "UI_TOTAL"}, {"goldLast", "UI_LAST"},
    {"goldCurrent", "UI_CURRENT"}, {"goldSession", "UI_SESSION"}}) do
    local key = spec[1]
    checks[key] = Check(pages[4], spec[2], 0, -(i - 1) * 38, function(self) draft[key] = self:GetChecked() and true or false end)
  end
  Button(settings, "UI_DEFAULTS", 18, -512, 160, function()
    draft, layoutDraft = Core.copyAppearance(), Core.copyToolbar()
    RefreshDraft()
  end)
  Button(settings, "UI_APPLY", 392, -512, 160, function()
    if not Allowed() then return end
    if ColorPickerFrame and ColorPickerFrame:IsShown() then ColorPickerFrame:Hide() end
    RT.state.appearance = Core.copyAppearance(draft)
    Character().toolbar = Core.copyToolbar(layoutDraft)
    Skin.ApplyAppearance(Config())
    RT.ApplyWindowScale()
    RT.LayoutMainToolbar()
    RT.TouchState()
    if RT.IsHelpWindowShown() then RT.ShowAddonHelp() end
  end)
  settings:HookScript("OnHide", function()
    if ColorPickerFrame and ColorPickerFrame.func and ColorPickerFrame:IsShown() then ColorPickerFrame:Hide() end
  end)
  SelectPage(1)
end

function RT.AttachSettingsControls()
  CreateSettings()
  local page = pages[1]
  for i, name in ipairs({"autoCurrentInstanceCheckbox", "echoBarCheckbox", "autoAcceptSharedCheckbox", "minimapShownCheckbox", "travelCheckbox", "travelAutoCheckbox", "remoteRollCheckbox"}) do
    local widget = RT[name]
    widget:SetParent(page)
    widget:ClearAllPoints(); widget:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -(i - 1) * 30)
    widget._acbLabel:SetParent(page)
    widget._acbLabel:ClearAllPoints(); widget._acbLabel:SetPoint("LEFT", widget, "RIGHT", 8, 0)
  end
  RT.echoBarOrientationButton:SetParent(page)
  RT.echoBarOrientationButton:ClearAllPoints(); RT.echoBarOrientationButton:SetPoint("TOPLEFT", page, "TOPLEFT", 400, -30)
  RT.rollSpeedSlider:SetParent(page)
  RT.rollSpeedSlider:ClearAllPoints(); RT.rollSpeedSlider:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -280)
  RT.rollSpeedSlider:SetWidth(480)
  RT.rollSpeedSlider.valueText:SetWidth(520)
  RT.languageButton:SetParent(page)
  RT.languageButton:ClearAllPoints(); RT.languageButton:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -355)
  local accept = Check(page, "UI_AUTO_ACCEPT", 0, -210, function(self) RT.SetField("autoAccept", self:GetChecked() and true or false) end)
  local eternals = Check(page, "UI_ETERNALS", 0, -240, function(self)
    if SlashCmdList.AUTOCALLBOARDETERNALS then SlashCmdList.AUTOCALLBOARDETERNALS(self:GetChecked() and "on" or "off") end
  end)
  page:SetScript("OnShow", function()
    accept:SetChecked(RT.state.autoAccept)
    eternals:SetChecked(not AutoCallboardEternalsDB or AutoCallboardEternalsDB.enabled ~= false)
  end)
end

function RT.ShowSettings(page)
  if not Allowed() then return end
  if not RT.questWindow then RT.CreateQuestWindow() end
  draft, layoutDraft = Core.copyAppearance(Config()), Core.copyToolbar(Character().toolbar)
  RefreshDraft()
  SelectPage(page or 1)
  settings:Show()
end

function RT.ApplyWindowScale()
  Skin.ScaleRoots(Config().scale)
end
function RT.InitAppearance()
  RT.state.appearance = Core.copyAppearance(RT.state.appearance)
  Skin.ApplyAppearance(Config())
end
function RT.InitSettingsAccess()
  local frame = RT.controlFrame
  buttons = {frame.listsButton, frame.buildsButton, AutoCallboardButton, frame.startButton, frame.shareButton, frame.questButton}
  frame.settingsButton = Button(frame, "UI_SETTINGS", 10, -30, 90, function() RT.ShowSettings() end)
  buttons[11] = frame.settingsButton
  RT.PositionControlHeader = function()
    RT.summonStatusText:SetWidth(frame:GetWidth() - 20)
    if RT.questGoldText and Config().goldMain then RT.questGoldText:SetWidth(frame:GetWidth() - 20) end
  end
  RT.LayoutMainToolbar()
  if InterfaceOptions_AddCategory then
    local panel = CreateFrame("Frame", "AutoCallboardOptions", UIParent)
    panel.name = "AutoCallboard"
    Button(panel, "UI_SETTINGS", 20, -30, 200, function()
      if not Allowed() then return end
      if InterfaceOptionsFrame then InterfaceOptionsFrame:Hide() end
      if GameMenuFrame then GameMenuFrame:Hide() end
      RT.ShowSettings()
    end)
    InterfaceOptions_AddCategory(panel)
  end
end

function RT.RefreshSettingsLanguage()
  goldConfig = nil
  RT.RefreshGoldDisplay()
  if settings and settings:IsShown() then RefreshDraft() end
  if buttons then
    for id, button in pairs(buttons) do
      if id ~= 3 and id ~= 4 and id ~= 6 then button:SetText(Label(id)) end
    end
    if not InCombatLockdown() then RT.LayoutMainToolbar() end
  end
end
