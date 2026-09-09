local Skin = AutoCallboardSkin
local THEME = Skin.THEME
local L = AutoCallboardLocale
local RT = AutoCallboardRuntime

local Localized = RT.Localized
local IsCallboardActive = RT.IsCallboardActive
local IsSummonSpellUsable = RT.IsSummonSpellUsable
local GetSummonCooldownRemaining = RT.GetSummonCooldownRemaining
local GetObjectivesService = RT.GetObjectivesService
local CaptureCurrentObjectives = RT.CaptureCurrentObjectives
local TargetCallboard = RT.TargetCallboard
local QueueCallboardFollowup = RT.QueueCallboardFollowup
local UpdateSummonStatus = RT.UpdateSummonStatus
local state = RT.state

local ADDON_TITLE = RT.ADDON_TITLE

local controlFrame
local button
local minimapButton
local minimapText
local summonStatusText
local preClickCooldownRemaining = 0
local preClickWasActive = false
local preClickWasUsable = true

local ApplySummonButtonAttributes
local PositionMinimapButton
local UpdateRollToggleButtons

local Log = RT.Log

local function SetButtonEnabled(target, enabled)
  if not target then
    return
  end

  if enabled then
    target:Enable()
    target:SetAlpha(1)
  else
    target:Disable()
    target:SetAlpha(0.48)
  end

  Skin.SetButtonVisual(target)
end

RT.SetButtonEnabled = SetButtonEnabled

function RT.UpdateShareButtonState()
  local enabled = RT.lastAcceptedQuest ~= nil

  SetButtonEnabled(RT.shareQuestButton, enabled)

  if controlFrame and controlFrame.shareButton then
    SetButtonEnabled(controlFrame.shareButton, enabled)
  end
end


function RT.RefreshCallboardButtonEnabled()
  if not button then
    return
  end

  local blocked = RT.IsSummonBlockedIndoors()
  if blocked == RT.summonBlockedIndoors then
    return
  end

  if InCombatLockdown and InCombatLockdown() then
    return
  end

  RT.summonBlockedIndoors = blocked
  SetButtonEnabled(button, not blocked)
  Log("summon", "bouton callboard ", (blocked and "grise (interieur)" or "actif"))
end

function RT.SyncOverlayFrameLevels()
  local referenceFrame = _G and _G.ObjectivesMainFrame or nil
  local referenceLevel = 20

  if referenceFrame and referenceFrame.GetFrameLevel then
    referenceLevel = referenceFrame:GetFrameLevel() or referenceLevel
  end

  if referenceLevel == RT.lastOverlayReferenceLevel and RT.questWindow == RT.lastOverlayQuestWindow then
    return
  end

  if InCombatLockdown and InCombatLockdown() then
    return
  end

  RT.lastOverlayReferenceLevel = referenceLevel
  RT.lastOverlayQuestWindow = RT.questWindow

  if controlFrame then
    if controlFrame.SetFrameStrata then
      controlFrame:SetFrameStrata("HIGH")
    end
    if controlFrame.SetFrameLevel then
      controlFrame:SetFrameLevel(referenceLevel + 20)
    end
  end

  if RT.questWindow then
    if RT.questWindow.SetFrameStrata then
      RT.questWindow:SetFrameStrata("HIGH")
    end
    if controlFrame and RT.questWindow.SetFrameLevel then
      RT.questWindow:SetFrameLevel((controlFrame:GetFrameLevel() or referenceLevel + 20) + 1)
    end
  end
end

local function RefreshRollButtonMacroState(target)
  if not target or not target._acbRollToggle or not target.SetAttribute then
    return
  end

  if InCombatLockdown and InCombatLockdown() then
    return
  end

  RT.ApplySecureMacroButtonAttributes(target, "", "start")
end

local function UpdateRollToggleButtonState(target, canStart)
  if not target then
    return
  end

  if RT.IsRolling() then
    target._acbRollState = "stop"
    target:SetText(L.BUTTON_STOP)
    SetButtonEnabled(target, true)
    RefreshRollButtonMacroState(target)
    return
  end

  target._acbRollState = nil
  target:SetText(L.BUTTON_START)
  SetButtonEnabled(target, canStart)
  RefreshRollButtonMacroState(target)
end

RT.UpdateRollToggleButtonState = UpdateRollToggleButtonState

local function IsQuestRollStartAvailable()
  local service = GetObjectivesService()

  return service ~= nil
end

RT.IsQuestRollStartAvailable = IsQuestRollStartAvailable

UpdateRollToggleButtons = function()
  if controlFrame and controlFrame.startButton then
    UpdateRollToggleButtonState(controlFrame.startButton, true)
  end

  UpdateRollToggleButtonState(RT.startRollButton, IsQuestRollStartAvailable())
end

RT.UpdateRollToggleButtons = UpdateRollToggleButtons

function RT.ApplySecureMacroButtonAttributes(target, macroText, label)
  if not target then
    return
  end

  macroText = macroText or ""

  if InCombatLockdown and InCombatLockdown() then
    Log("summon", "deferred secure ", label, " update in combat")
    return
  end

  if target._acbSecureType == "macro" and target._acbSecureMacroText == macroText then
    return
  end

  target:SetAttribute("type", "macro")
  target:SetAttribute("macrotext", macroText)
  target._acbSecureType = "macro"
  target._acbSecureMacroText = macroText
  Log("summon", "secure ", label, " macro set to ", macroText)
end

function RT.ConfigureStartButton(target)
  if not target then
    return
  end

  target._acbRollToggle = true
  RT.ApplySecureMacroButtonAttributes(target, "", "start")
  target:SetScript("PreClick", function()
    if RT.IsRolling() then
      return
    end

    preClickWasActive = IsCallboardActive()
    RT.ApplySecureMacroButtonAttributes(target, "", "start")
    end)
  target:SetScript("PostClick", function()
    if RT.IsRolling() then
      RT.StopRolling(L.ROLL_STOPPED)
      UpdateSummonStatus()
      return
    end

    if not preClickWasActive then
      Log("summon", "start roll requested; summon skipped")
    end

    RT.StartRolling()
    UpdateSummonStatus()
    end)
end

function RT.SetControlFrameSize(width, height)
  if not controlFrame then
    return
  end

  local centerX = controlFrame:GetCenter()
  local top = controlFrame:GetTop()

  controlFrame:SetWidth(width)
  controlFrame:SetHeight(height)

  if centerX and top then
    controlFrame:ClearAllPoints()
    controlFrame:SetPoint("TOP", UIParent, "BOTTOMLEFT", centerX, top)
  end
end

function RT.PositionControlHeader()
  if not controlFrame or not button then
    return
  end

  local listsButton = controlFrame.listsButton
  local buildsButton = controlFrame.buildsButton
  local frameWidth = controlFrame:GetWidth()
  local leftOffset = 10
  local buttonRowWidth = button:GetWidth() or 88

  if listsButton then
    buttonRowWidth = buttonRowWidth + 5 + (listsButton:GetWidth() or 50)
  end

  if buildsButton then
    buttonRowWidth = buttonRowWidth + 5 + (buildsButton:GetWidth() or 56)
  end

  if controlFrame.startButton then
    buttonRowWidth = buttonRowWidth + 5 + (controlFrame.startButton:GetWidth() or 72)
  end

  if controlFrame.shareButton then
    buttonRowWidth = buttonRowWidth + 4 + (controlFrame.shareButton:GetWidth() or 54)
  end

  if controlFrame.questButton then
    buttonRowWidth = buttonRowWidth + 4 + (controlFrame.questButton:GetWidth() or 50)
  end

  if frameWidth and frameWidth > buttonRowWidth then
    leftOffset = (frameWidth - buttonRowWidth) / 2
  end

  if controlFrame.title then
    controlFrame.title:ClearAllPoints()
    controlFrame.title:SetPoint("TOP", controlFrame, "TOP", 0, -8)
  end

  local rowAnchor = button

  if listsButton then
    listsButton:ClearAllPoints()
    listsButton:SetPoint("TOPLEFT", controlFrame, "TOPLEFT", leftOffset, -30)

    if buildsButton then
      buildsButton:ClearAllPoints()
      buildsButton:SetPoint("LEFT", listsButton, "RIGHT", 5, 0)
    end

    button:ClearAllPoints()
    button:SetPoint("LEFT", buildsButton or listsButton, "RIGHT", 5, 0)
    rowAnchor = listsButton
  else
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", controlFrame, "TOPLEFT", leftOffset, -30)
  end

  if summonStatusText then
    summonStatusText:ClearAllPoints()
    summonStatusText:SetPoint("TOPLEFT", rowAnchor, "BOTTOMLEFT", 0, -5)
    summonStatusText:SetWidth(math.max(180, (frameWidth or RT.controlCollapsedWidth) - 20))
  end
end

function RT.AnimateControlFrameSize(width, height, onComplete)
  if not controlFrame then
    if onComplete then
      onComplete()
    end
    return
  end

  local startWidth = controlFrame:GetWidth()
  local startHeight = controlFrame:GetHeight()
  local startedAt = GetTime()

  if RT.questPanelAnimation then
    RT.questPanelAnimation.finished = true
  end

  RT.questPanelAnimation = {
    finished = false,
    onComplete = onComplete,
    startHeight = startHeight,
    startWidth = startWidth,
    startedAt = startedAt,
    targetHeight = height,
    targetWidth = width,
  }
end

function RT.UpdateQuestPanelAnimation()
  local animation = RT.questPanelAnimation

  if not animation or animation.finished then
    return
  end

  local elapsed = GetTime() - animation.startedAt
  local progress = elapsed / RT.questPanelAnimationSeconds

  if progress >= 1 then
    progress = 1
    animation.finished = true
  end

  local eased = 1 - ((1 - progress) * (1 - progress))
  local width = animation.startWidth + ((animation.targetWidth - animation.startWidth) * eased)
  local height = animation.startHeight + ((animation.targetHeight - animation.startHeight) * eased)

  RT.SetControlFrameSize(width, height)
  RT.PositionControlHeader()

  if animation.finished then
    RT.SetControlFrameSize(animation.targetWidth, animation.targetHeight)
    RT.PositionControlHeader()
    RT.questPanelAnimation = nil

    if animation.onComplete then
      animation.onComplete()
    end
  end
end

function RT.SetQuestPanelExpanded(expanded)
  if not controlFrame then
    return
  end

  expanded = expanded and true or false
  RT.SaveQuestPanelExpanded(expanded)

  if RT.questPanelChanging then
    return
  end

  RT.questPanelChanging = true

  if expanded then
    if not RT.questWindow then
      RT.CreateQuestWindow()
    end

    if summonStatusText then
      summonStatusText:SetWidth(256)
    end

    if controlFrame.questButton then
      controlFrame.questButton:SetText(L.BUTTON_HIDE)
    end

    CaptureCurrentObjectives()
    RT.UpdateQuestWindow()
    RT.AnimateControlFrameSize(RT.controlExpandedWidth, RT.controlExpandedHeight, function()
        if RT.questWindow then
          RT.questWindow:Show()
        end

        RT.questPanelChanging = false
    end)
  else
    if RT.IsQuestWindowShown() then
      RT.questWindow:Hide()
    end

    if summonStatusText then
      summonStatusText:SetWidth(256)
    end

    if controlFrame.questButton then
      controlFrame.questButton:SetText(L.BUTTON_QUESTS)
    end

    RT.AnimateControlFrameSize(RT.controlCollapsedWidth, RT.controlCollapsedHeight, function()
        RT.PositionControlHeader()
        RT.questPanelChanging = false
    end)
  end
end

function RT.ToggleQuestPanel()
  RT.SetQuestPanelExpanded(not RT.IsQuestWindowShown())
end

local function SaveButtonPosition()
  if not controlFrame or not state then
    return
  end

  RT.SavePoint(controlFrame, state.button)
end

local function PositionButton()
  RT.RestorePoint(controlFrame, state.button)
end

local function SaveMinimapPosition(angle)
  if not state then
    return
  end

  state.minimap.angle = angle

  if not state.minimap.shown then
    state.minimap.shown = true
    RT.UpdateMinimapShownControl()
  end
end

PositionMinimapButton = function()
  if not minimapButton or not state then
    return
  end

  if not state.minimap.shown then
    minimapButton:Hide()
    return
  end

  local parent = Minimap or UIParent
  local angle = math.rad(state.minimap.angle or 225)
  local radius = 82
  local x = math.cos(angle) * radius
  local y = math.sin(angle) * radius

  minimapButton:ClearAllPoints()
  minimapButton:SetPoint("CENTER", parent, "CENTER", x, y)
  minimapButton:Show()
end

function RT.SetMinimapShown(shown)
  if not state then
    return
  end

  state.minimap.shown = shown and true or false
  PositionMinimapButton()
  RT.UpdateMinimapShownControl()
end

local function UpdateMinimapDragPosition()
  if not minimapButton or not Minimap or not GetCursorPosition then
    return
  end

  local scale = Minimap:GetEffectiveScale() or 1
  local cursorX, cursorY = GetCursorPosition()
  local centerX, centerY = Minimap:GetCenter()

  cursorX = cursorX / scale
  cursorY = cursorY / scale

  local angle = math.deg(math.atan2(cursorY - centerY, cursorX - centerX))
  SaveMinimapPosition(angle)
  PositionMinimapButton()
end

local function CreateMinimapButton()
  if minimapButton then
    PositionMinimapButton()
    return
  end

  minimapButton = CreateFrame("Button", "AutoCallboardMinimapButton", Minimap or UIParent)
  minimapButton:SetWidth(28)
  minimapButton:SetHeight(28)
  minimapButton:SetFrameStrata("MEDIUM")
  minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  minimapButton:RegisterForDrag("LeftButton")
  Skin.StripButtonChrome(minimapButton)
  local disc = minimapButton:CreateTexture(nil, "BACKGROUND")
  disc:SetAllPoints(minimapButton)
  disc:SetTexture("Interface\\Buttons\\UI-RadioButton")
  disc:SetTexCoord(0.25, 0.5, 0, 1)
  Skin.ApplyColor(disc, "SetVertexColor", THEME.heading)
  minimapText = minimapButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  minimapText:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
  minimapText:SetText("ACB")
  minimapText:SetFont(Skin.BUTTON_FONT, 8)
  Skin.ApplyColor(minimapText, "SetTextColor", THEME.buttonText)

  minimapButton:SetScript("OnDragStart", function()
    if not state.appearance.locked then minimapButton:SetScript("OnUpdate", UpdateMinimapDragPosition) end
    end)
  minimapButton:SetScript("OnDragStop", function()
    minimapButton:SetScript("OnUpdate", nil)
    UpdateMinimapDragPosition()
    end)
  minimapButton:SetScript("OnClick", function(_, mouseButton)
    if mouseButton == "RightButton" then
      RT.ShowSettings()
      return
    end

    if controlFrame and controlFrame:IsShown() then
      controlFrame:Hide()
    elseif controlFrame then
      RT.SaveControlFrameShown(true)
      controlFrame:Show()
    end
    end)
  minimapButton:SetScript("OnEnter", function(self)
    Skin.ApplyColor(disc, "SetVertexColor", THEME.buttonHoverBorder)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(L.ADDON_NAME_TOOLTIP)
    GameTooltip:AddLine(L.MINIMAP_TOOLTIP_LEFT_CLICK, 1, 1, 1)
    GameTooltip:AddLine(L.MINIMAP_TOOLTIP_RIGHT_CLICK, 1, 1, 1)
    GameTooltip:AddLine(L.MINIMAP_TOOLTIP_DRAG, 0.8, 0.8, 0.8)
    GameTooltip:Show()
    end)
  minimapButton:SetScript("OnLeave", function(self)
    Skin.ApplyColor(disc, "SetVertexColor", THEME.heading)
    GameTooltip:Hide()
    end)

  PositionMinimapButton()
end

local function StartMovingButton(self)
  if IsShiftKeyDown() and not InCombatLockdown() and not state.appearance.locked then
    controlFrame:StartMoving()
  end
end

local function StopMovingButton(self)
  controlFrame:StopMovingOrSizing()
  SaveButtonPosition()
end

local function MakeActionButton(name, text, width, height, point, relativeTo, relativePoint, x, y, onClick, template)
  local actionButton = CreateFrame("Button", name, controlFrame, template or "UIPanelButtonTemplate")
  actionButton:SetWidth(width)
  actionButton:SetHeight(height)
  actionButton:SetText(text)
  actionButton:SetPoint(point, relativeTo, relativePoint, x, y)
  actionButton:RegisterForDrag("LeftButton")
  if template and template:find("SecureActionButtonTemplate", 1, true) then
    actionButton:RegisterForClicks("AnyUp")
  end
  if onClick then
    actionButton:SetScript("OnClick", onClick)
  end
  actionButton:SetScript("OnDragStart", StartMovingButton)
  actionButton:SetScript("OnDragStop", StopMovingButton)
  Skin.Button(actionButton)

  return actionButton
end

ApplySummonButtonAttributes = function()
  if not button then
    return
  end

  if InCombatLockdown and InCombatLockdown() then
    Log("summon", "deferred secure button update in combat")
    return
  end

  RT.ApplySecureMacroButtonAttributes(button, RT.GetSummonMacroText(), "callboard")

  if RT.startRollButton then
    RT.ConfigureStartButton(RT.startRollButton)
  end

  if controlFrame and controlFrame.startButton then
    RT.ConfigureStartButton(controlFrame.startButton)
  end

  UpdateRollToggleButtonState(RT.startRollButton, IsQuestRollStartAvailable())
  UpdateRollToggleButtonState(controlFrame and controlFrame.startButton or nil, true)

  button:SetText(state.targetName)
end

local function CreateCallboardButton()
  controlFrame = CreateFrame("Frame", "AutoCallboardFrame", UIParent)
  RT.controlFrame = controlFrame
  controlFrame:SetWidth(RT.controlCollapsedWidth)
  controlFrame:SetHeight(RT.controlCollapsedHeight)
  controlFrame:SetFrameStrata("HIGH")
  RT.SyncOverlayFrameLevels()
  controlFrame:SetMovable(true)
  controlFrame:EnableMouse(true)
  controlFrame:RegisterForDrag("LeftButton")
  controlFrame:SetClampedToScreen(true)
  Skin.Frame(controlFrame)
  controlFrame:SetScript("OnDragStart", function(self)
    if not InCombatLockdown() and not state.appearance.locked then self:StartMoving() end
    end)
  controlFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveButtonPosition()
    end)
  controlFrame:SetScript("OnShow", function()
    RT.SaveControlFrameShown(true)
    RT.SyncOverlayFrameLevels()
    end)
  controlFrame:SetScript("OnHide", function()
    RT.SaveControlFrameShown(false)

    if RT.IsQuestWindowShown() then
      RT.SaveQuestPanelExpanded(false)
      RT.questWindow:Hide()
    end

    if RT.HideDebugWindow then
      RT.HideDebugWindow()
    end

    RT.HideHelpWindow()

    if RT.listsWindow and RT.listsWindow:IsShown() then
      RT.listsWindow:Hide()
    end
    end)

  controlFrame.closeButton = CreateFrame("Button", nil, controlFrame)
  controlFrame.closeButton:SetPoint("TOPRIGHT", controlFrame, "TOPRIGHT", -4, -4)
  Skin.CloseButton(controlFrame.closeButton)
  controlFrame.closeButton:SetScript("OnClick", function()
    if RT.IsQuestWindowShown() then
      RT.SetQuestPanelExpanded(false)
    else
      controlFrame:Hide()
    end
    end)

  controlFrame.helpButton = CreateFrame("Button", nil, controlFrame)
  controlFrame.helpButton:SetPoint("RIGHT", controlFrame.closeButton, "LEFT", -4, 0)
  Skin.HelpButton(controlFrame.helpButton)
  controlFrame.helpButton:SetScript("OnClick", function()
    RT.ShowAddonHelp()
    end)

  local title = controlFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  title:SetPoint("TOPLEFT", controlFrame, "TOPLEFT", 10, -8)
  title:SetText(ADDON_TITLE)
  Skin.TitleText(title)
  controlFrame.title = title

  local listsButton = Skin.MakeButton(controlFrame, {
    name = "AutoCallboardListsButton",
    width = 50,
    height = 24,
    textKey = "BUTTON_LISTS",
    points = { { "TOPLEFT", controlFrame, "TOPLEFT", 10, -30 } },
    onClick = RT.ToggleListsWindow,
    tipTitle = "BUTTON_LISTS",
    tipBody = "LISTS_BUTTON_TOOLTIP",
  })
  controlFrame.listsButton = listsButton

  local buildsButton = Skin.MakeButton(controlFrame, {
    name = "AutoCallboardBuildsButton",
    width = 56,
    height = 24,
    textKey = "BUTTON_BUILDS",
    points = { { "LEFT", listsButton, "RIGHT", 5, 0 } },
    onClick = function() RT.ToggleBuildsWindow() end,
    tipTitle = "BUTTON_BUILDS",
    tipBody = "BUILDS_BUTTON_TOOLTIP",
    tipExtra = function()
      local activeBuild = RT.GetActiveBuild()
      if activeBuild then
        GameTooltip:AddLine(string.format(L.BUILDS_BUTTON_ACTIVE, RT.BuildLabel(activeBuild)), 1, 1, 1)
      end
      end,
  })
  controlFrame.buildsButton = buildsButton

  button = CreateFrame("Button", "AutoCallboardButton", controlFrame, "SecureActionButtonTemplate,UIPanelButtonTemplate")
  button:SetWidth(88)
  button:SetHeight(24)
  button:SetText(state.targetName)
  button:SetPoint("LEFT", controlFrame.buildsButton or listsButton, "RIGHT", 5, 0)
  button:RegisterForClicks("AnyUp")
  button:RegisterForDrag("LeftButton")
  Skin.Button(button)
  ApplySummonButtonAttributes()
  button:SetScript("PreClick", function()
    preClickCooldownRemaining = GetSummonCooldownRemaining()
    preClickWasActive = IsCallboardActive()
    preClickWasUsable = IsSummonSpellUsable()

    if preClickWasActive then
      RT.ApplySecureMacroButtonAttributes(button, "", "callboard active")
    else
      ApplySummonButtonAttributes()
    end
    end)
  button:SetScript("PostClick", function()
    if preClickWasActive then
      RT.ResumeRollingAfterCallboardActive("secure button active")
      QueueCallboardFollowup("secure button active")
    elseif preClickCooldownRemaining and preClickCooldownRemaining > 0 then
      Log("summon", "blocked secure click cooldown=", preClickCooldownRemaining)
    elseif not preClickWasUsable then
      if TargetCallboard() then
        Log("summon", "button using summoned callboard")
        QueueCallboardFollowup("button summoned callboard")
      else
        Log("summon", "blocked secure click unusable")
      end
    else
      RT.BeginSummonAttempt("secure button")
    end

    ApplySummonButtonAttributes()
    UpdateSummonStatus()
    end)
  button:SetScript("OnDragStart", StartMovingButton)
  button:SetScript("OnDragStop", StopMovingButton)
  Skin.HoverTip(button, "ADDON_NAME_TOOLTIP", nil, "button", function()
    if RT.IsSummonBlockedIndoors() then
      GameTooltip:AddLine(L.SUMMON_BLOCKED_INDOORS, 1, 0.3, 0.3)
    else
      GameTooltip:AddLine(L.SUMMON_BUTTON_CLICK_HINT, 1, 1, 1)
    end
    GameTooltip:AddLine(L.SUMMON_BUTTON_DRAG_HINT, 0.8, 0.8, 0.8)
    end)

  PositionButton()

  local mainStartButton = MakeActionButton("AutoCallboardStartButton", L.BUTTON_START, 72, 24, "LEFT", button, "RIGHT", 5, 0, nil, "SecureActionButtonTemplate,UIPanelButtonTemplate")
  controlFrame.startButton = mainStartButton
  RT.ConfigureStartButton(mainStartButton)
  UpdateRollToggleButtonState(mainStartButton, true)
  controlFrame.shareButton = MakeActionButton(
      "AutoCallboardShareButton",
      L.BUTTON_SHARE,
      54,
      24,
      "LEFT",
      mainStartButton,
      "RIGHT",
      4,
      0,
      function()
        RT.ShareAcceptedQuest("main button")
      end
    )
  Localized(controlFrame.shareButton, "BUTTON_SHARE")
  Skin.HoverTip(controlFrame.shareButton, "BUTTON_SHARE", "SHARE_BUTTON_TOOLTIP")
  controlFrame.questButton = MakeActionButton(
      "AutoCallboardQuestsButton",
      L.BUTTON_QUESTS,
      50,
      24,
      "LEFT",
      controlFrame.shareButton,
      "RIGHT",
      4,
      0,
      RT.ToggleQuestPanel
    )
  RT.UpdateShareButtonState()

  summonStatusText = controlFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  RT.summonStatusText = summonStatusText
  summonStatusText:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -5)
  summonStatusText:SetWidth(256)
  summonStatusText:SetJustifyH("LEFT")
  Skin.MutedText(summonStatusText)
  RT.PositionControlHeader(false)
  UpdateSummonStatus()

  if state.buttonShown then
    controlFrame:Show()
  else
    controlFrame:Hide()
  end

  if state.buttonShown and state.questPanelExpanded then
    RT.SetQuestPanelExpanded(true)
  end
end

RT.SetButtonEnabled = SetButtonEnabled
RT.UpdateRollToggleButtonState = UpdateRollToggleButtonState
RT.IsQuestRollStartAvailable = IsQuestRollStartAvailable
RT.UpdateRollToggleButtons = UpdateRollToggleButtons
RT.PositionButton = PositionButton
RT.CreateCallboardButton = CreateCallboardButton
RT.CreateMinimapButton = CreateMinimapButton

RT.ApplySummonButtonAttributes = function(...)
  return ApplySummonButtonAttributes(...)
end

RT.PositionMinimapButton = function(...)
  return PositionMinimapButton(...)
end

RT.SetCallboardButtonText = function(text)
  if button then
    button:SetText(text)
  end
end

RT.ShowControlFrame = function(shown)
  if not controlFrame then
    return
  end

  if shown then
    controlFrame:Show()
  else
    controlFrame:Hide()
  end
end

RT.IsControlFrameShown = function()
  return controlFrame ~= nil and controlFrame:IsShown()
end
