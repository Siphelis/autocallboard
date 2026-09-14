
AutoCallboardSkin = {}
local RT = AutoCallboardRuntime

local WHITE8X8 = "Interface\\Buttons\\WHITE8X8"
local BACKDROP = { bgFile = WHITE8X8, edgeFile = WHITE8X8, edgeSize = 1 }
local BUTTON_FONT = "Fonts\\FRIZQT__.TTF"
local function RGB(r, g, b, a)
  return r / 255, g / 255, b / 255, a or 1
end

local INK        = { RGB(5, 5, 5, 1) }
local PLUM       = { RGB(75, 46, 131, 1) }
local ORCHID     = { RGB(176, 72, 248, 1) }
local ICE        = { RGB(209, 246, 246, 1) }
local LILAC      = { RGB(209, 209, 246, 1) }

local THEME = {
  bg = { RGB(5, 5, 5, 0.96) },
  bgSoft = { RGB(5, 5, 5, 0.86) },
  card = { RGB(5, 5, 5, 0.92) },
  debugList = { RGB(18, 18, 18, 0.96) },
  border = PLUM,
  borderDim = { RGB(75, 46, 131, 0.65) },
  selection = { RGB(176, 72, 248, 0.28) },
  button = PLUM,
  buttonBorder = PLUM,
  buttonStop = ICE,
  buttonStopText = { RGB(10, 10, 10, 1) },
  buttonDisabledBorder = { RGB(75, 46, 131, 0) },
  buttonHoverBorder = { RGB(232, 121, 255, 1) },
  buttonText = LILAC,
  buttonDisabledText = { RGB(209, 209, 246, 0.45) },
  checkbox = INK,
  checkboxBorder = PLUM,
  checkboxChecked = ORCHID,
  close = INK,
  closeBorder = INK,
  closeText = ORCHID,
  text = ICE,
  muted = { RGB(209, 227, 246, 0.78) },
  title = LILAC,
  gold = LILAC,
  good = ICE,
  heading = ORCHID,
}

local colors = {}
local bareRoots = setmetatable({}, { __mode = "k" })

local function ApplyColor(target, methodName, color)
  if target and target[methodName] and color then
    local entries = colors[methodName]
    if not entries then
      entries = setmetatable({}, { __mode = "k" })
      colors[methodName] = entries
    end
    entries[target] = color
    target[methodName](target, color[1], color[2], color[3], color[4] or 1)
  end
end

local function tipText(key)
  return (AutoCallboardLocale and AutoCallboardLocale[key]) or key
end

local function OpenTip(owner, anchor, title)
  GameTooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT")

  if GameTooltip.SetBackdropColor then
    GameTooltip:SetBackdropColor(THEME.bg[1], THEME.bg[2], THEME.bg[3], 1)
    GameTooltip:SetBackdropBorderColor(THEME.border[1], THEME.border[2], THEME.border[3], THEME.border[4] or 1)
  end

  if title then
    GameTooltip:AddLine(tipText(title), THEME.heading[1], THEME.heading[2], THEME.heading[3])
  end

  return GameTooltip
end

local function IsMouseOverFrame(target)
  if not target then
    return false
  end

  if target.IsMouseOver and target:IsMouseOver() then
    return true
  end

  return MouseIsOver and MouseIsOver(target) or false
end

local function SetButtonVisual(target, mode)
  if not target then
    return
  end

  local disabled = target.IsEnabled and not target:IsEnabled()
  local visualMode = mode or (IsMouseOverFrame(target) and "hover" or nil)
  local bg = THEME.button
  local isStopState = target._acbRollState == "stop"
  local border = disabled and THEME.buttonDisabledBorder or THEME.buttonBorder
  local text = disabled and THEME.buttonDisabledText or THEME.buttonText
  local glossAlpha = 0.08

  if isStopState then
    bg = THEME.buttonStop
    text = THEME.buttonStopText
  end

  if not disabled and visualMode == "hover" then
    border = THEME.buttonHoverBorder
  elseif not disabled and visualMode == "down" then
    border = THEME.buttonHoverBorder
  end

  ApplyColor(target, "SetBackdropColor", bg)
  ApplyColor(target, "SetBackdropBorderColor", border)

  if target.GetFontString and target:GetFontString() then
    ApplyColor(target:GetFontString(), "SetTextColor", text)
  end

  if target._acbIcon then
    ApplyColor(target._acbIcon, "SetVertexColor", target._acbIconColor or text)
  end

  if target._acbGloss then
    target._acbGloss:SetVertexColor(1, 1, 1, glossAlpha)
  end
end

local BUTTON_ICON_SIZE = 12

local function SetButtonIcon(target, texture, color)
  if not target or not target.CreateTexture then
    return
  end

  if not target._acbIcon then
    local icon = target:CreateTexture(nil, "OVERLAY")
    icon:SetWidth(BUTTON_ICON_SIZE)
    icon:SetHeight(BUTTON_ICON_SIZE)
    icon:SetPoint("CENTER", target, "CENTER", 0, 0)
    target._acbIcon = icon
  end

  target._acbIcon:SetTexture(texture)
  target._acbIconColor = color
  SetButtonVisual(target)
end

local CHROME_SIZE = 18
local CHROME_MARK_SIZE = 12
local GEAR_TEXTURE = "Interface\\WorldMap\\Gear_64Grey"

local function SetChromeVisual(target, visualMode)
  local hovered = visualMode == "hover"

  ApplyColor(target, "SetBackdropBorderColor", hovered and THEME.buttonHoverBorder or THEME.closeBorder)

  if target._acbChromeMark then
    ApplyColor(target._acbChromeMark, target._acbChromeTint, hovered and THEME.buttonHoverBorder or THEME.closeText)
  end
end

local function SkinChromeButton(target, glyph, texture, tipKey, hides)
  if not target then
    return
  end

  target:SetWidth(CHROME_SIZE)
  target:SetHeight(CHROME_SIZE)

  if target.SetBackdrop then
    target:SetBackdrop(BACKDROP)
    ApplyColor(target, "SetBackdropColor", THEME.close)
  end

  if texture then
    target._acbChromeMark = target:CreateTexture(nil, "OVERLAY")
    target._acbChromeMark:SetTexture(texture)
    target._acbChromeMark:SetWidth(CHROME_MARK_SIZE)
    target._acbChromeMark:SetHeight(CHROME_MARK_SIZE)
    target._acbChromeTint = "SetVertexColor"
  else
    target._acbChromeMark = target:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    target._acbChromeMark:SetText(glyph)
    target._acbChromeTint = "SetTextColor"
  end

  target._acbChromeMark:SetPoint("CENTER", target, "CENTER", 0, 0)
  SetChromeVisual(target)

  if hides then
    target:SetScript("OnClick", function()
      hides:Hide()
      end)
  end

  target:SetScript("OnEnter", function(self)
    SetChromeVisual(self, "hover")
    OpenTip(self, "ANCHOR_RIGHT", tipKey)
    GameTooltip:Show()
    end)
  target:SetScript("OnLeave", function(self)
    SetChromeVisual(self)
    GameTooltip:Hide()
    end)

  return target
end

local function SkinCloseButton(target, parent)
  return SkinChromeButton(target, "X", nil, "BUTTON_CLOSE", parent)
end

local function SkinHelpButton(target)
  return SkinChromeButton(target, "?", nil, "UI_HELP")
end

local function SkinGearButton(target, tipKey)
  return SkinChromeButton(target, nil, GEAR_TEXTURE, tipKey or "UI_SETTINGS")
end

local function FollowInterfaceScale(target)
  if target:GetParent() == UIParent and RT.state and RT.state.appearance then
    target:SetScale(RT.state.appearance.scale)
  end
end

local function SkinFrame(target, variant)
  if not target or not target.SetBackdrop then
    return
  end

  if not target._acbBackdrop then
    target:SetBackdrop(BACKDROP)
    target._acbBackdrop = true
    FollowInterfaceScale(target)
  end

  local soft = variant == "soft"
  ApplyColor(target, "SetBackdropColor", soft and THEME.card or THEME.bg)
  ApplyColor(target, "SetBackdropBorderColor", soft and THEME.borderDim or THEME.border)
end

local function HideTextureRegions(target, except)
  if not target or not target.GetRegions then
    return
  end

  local regions = { target:GetRegions() }

  for i = 1, #(regions) do
    local region = regions[i]

    if region and region.GetObjectType and region:GetObjectType() == "Texture"
        and region ~= except then
      if region.SetTexture then
        region:SetTexture(nil)
      end

      if region.SetAlpha then
        region:SetAlpha(0)
      end

      if region.Hide then
        region:Hide()
      end
    end
  end
end

local function StripButtonChrome(target)
  if not target then
    return
  end

  if target.SetNormalTexture then
    target:SetNormalTexture("")
  end
  if target.SetHighlightTexture then
    target:SetHighlightTexture("")
  end
  if target.SetPushedTexture then
    target:SetPushedTexture("")
  end
  if target.SetDisabledTexture then
    target:SetDisabledTexture("")
  end

  HideTextureRegions(target, target._acbGloss)
end

local function StripFrameTextures(target)
  HideTextureRegions(target)
end

local function SkinButton(target)
  if not target then
    return
  end

  StripButtonChrome(target)

  if target.SetBackdrop then
    target:SetBackdrop(BACKDROP)
    ApplyColor(target, "SetBackdropColor", THEME.button)
    ApplyColor(target, "SetBackdropBorderColor", THEME.buttonBorder)
  end

  if target.SetNormalFontObject then
    target:SetNormalFontObject(GameFontNormalSmall)
  end

  if target.SetHighlightFontObject then
    target:SetHighlightFontObject(GameFontHighlightSmall)
  end

  if target.SetDisabledTextColor then
    target:SetDisabledTextColor(THEME.buttonDisabledText[1], THEME.buttonDisabledText[2], THEME.buttonDisabledText[3])
  end

  if target.GetFontString and target:GetFontString() then
    local fontString = target:GetFontString()
    fontString:ClearAllPoints()
    fontString:SetPoint("CENTER", target, "CENTER", 0, 0)
    fontString:SetJustifyH("CENTER")
    fontString:SetJustifyV("MIDDLE")
    fontString:SetFont(BUTTON_FONT, 10, "OUTLINE")
  end

  if not target._acbGloss and target.CreateTexture then
    local gloss = target:CreateTexture(nil, "OVERLAY")
    gloss:SetTexture(WHITE8X8)
    gloss:SetHeight(1)
    gloss:SetPoint("TOPLEFT", target, "TOPLEFT", 1, -1)
    gloss:SetPoint("TOPRIGHT", target, "TOPRIGHT", -1, -1)
    target._acbGloss = gloss
  end

  SetButtonVisual(target)

  if not target._acbButtonHooks and target.HookScript then
    target:HookScript("OnEnter", function(self)
      SetButtonVisual(self, "hover")
      end)
    target:HookScript("OnLeave", function(self)
      SetButtonVisual(self)
      end)
    target:HookScript("OnMouseDown", function(self)
      SetButtonVisual(self, "down")
      end)
    target:HookScript("OnMouseUp", function(self)
      SetButtonVisual(self)
      end)
    target:HookScript("OnEnable", function(self)
      SetButtonVisual(self)
      end)
    target:HookScript("OnDisable", function(self)
      SetButtonVisual(self)
      end)
    target._acbButtonHooks = true
  end
end

local function SetScrollButtonVisual(target, mode)
  if not target then
    return
  end

  local visualMode = mode or (IsMouseOverFrame(target) and "hover" or nil)

  ApplyColor(target, "SetBackdropColor", THEME.button)
  ApplyColor(target, "SetBackdropBorderColor", visualMode == "hover" and THEME.buttonHoverBorder or THEME.buttonBorder)

  if target._acbScrollGlyph then
    ApplyColor(target._acbScrollGlyph, "SetTextColor", THEME.buttonText)
  end
end

local function SkinSmallBox(target)
  if not target then
    return false
  end

  StripButtonChrome(target)
  target:SetWidth(18)
  target:SetHeight(18)

  if target.SetBackdrop then
    target:SetBackdrop(BACKDROP)
  end

  return true
end

local function SkinScrollButton(target, glyph)
  if not SkinSmallBox(target) then
    return
  end

  if not target._acbScrollGlyph and target.CreateFontString then
    local label = target:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER", target, "CENTER", 0, 0)
    label:SetFont(BUTTON_FONT, 9, "OUTLINE")
    target._acbScrollGlyph = label
  end

  if target._acbScrollGlyph then
    target._acbScrollGlyph:SetText(glyph or "")
  end

  SetScrollButtonVisual(target)

  if not target._acbScrollHooks and target.HookScript then
    target:HookScript("OnEnter", function(self)
      SetScrollButtonVisual(self, "hover")
      end)
    target:HookScript("OnLeave", function(self)
      SetScrollButtonVisual(self)
      end)
    target:HookScript("OnMouseDown", function(self)
      SetScrollButtonVisual(self, "hover")
      end)
    target:HookScript("OnMouseUp", function(self)
      SetScrollButtonVisual(self)
      end)
    target._acbScrollHooks = true
  end
end

local function SkinScrollBar(scrollFrame)
  if not scrollFrame or not scrollFrame.GetName then
    return
  end

  local frameName = scrollFrame:GetName()
  local scrollBar = _G[frameName .. "ScrollBar"] or scrollFrame.ScrollBar

  if not scrollBar then
    return
  end

  local scrollBarName = scrollBar.GetName and scrollBar:GetName() or frameName .. "ScrollBar"
  local upButton = _G[scrollBarName .. "ScrollUpButton"] or _G[frameName .. "ScrollUpButton"]
  local downButton = _G[scrollBarName .. "ScrollDownButton"] or _G[frameName .. "ScrollDownButton"]

  StripFrameTextures(scrollBar)
  scrollBar:SetWidth(18)

  if scrollBar.SetBackdrop then
    scrollBar:SetBackdrop(BACKDROP)
    ApplyColor(scrollBar, "SetBackdropColor", THEME.bg)
    ApplyColor(scrollBar, "SetBackdropBorderColor", THEME.borderDim)
  end

  SkinScrollButton(upButton, "^")
  SkinScrollButton(downButton, "v")

  if scrollBar.GetThumbTexture then
    local thumb = scrollBar:GetThumbTexture()
    if thumb then
      thumb:SetTexture(WHITE8X8)
      ApplyColor(thumb, "SetVertexColor", THEME.button)
      thumb:Show()
    end
  end

  scrollBar._acbUpButton = upButton
  scrollBar._acbDownButton = downButton
  scrollFrame._acbScrollBar = scrollBar

  return scrollBar
end

local function SetCheckboxVisual(target, mode)
  if not target then
    return
  end

  local visualMode = mode or (IsMouseOverFrame(target) and "hover" or nil)

  ApplyColor(target, "SetBackdropColor", THEME.checkbox)
  ApplyColor(target, "SetBackdropBorderColor", visualMode == "hover" and THEME.buttonHoverBorder or THEME.checkboxBorder)

  if target._acbCheck then
    if target.GetChecked and target:GetChecked() then
      target._acbCheck:Show()
    else
      target._acbCheck:Hide()
    end
  end
end

local function SkinCheckbox(target)
  if not SkinSmallBox(target) then
    return
  end

  if not target._acbCheck and target.CreateTexture then
    local check = target:CreateTexture(nil, "OVERLAY")
    check:SetTexture(WHITE8X8)
    check:SetPoint("TOPLEFT", target, "TOPLEFT", 4, -4)
    check:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", -4, 4)
    ApplyColor(check, "SetVertexColor", THEME.checkboxChecked)
    target._acbCheck = check
  end

  if not target._acbSetChecked and target.SetChecked then
    target._acbSetChecked = target.SetChecked
    target.SetChecked = function(self, value)
      self._acbSetChecked(self, value)
      SetCheckboxVisual(self)
    end
  end

  SetCheckboxVisual(target)

  if not target._acbCheckboxHooks and target.HookScript then
    target:HookScript("OnEnter", function(self)
      SetCheckboxVisual(self, "hover")
      end)
    target:HookScript("OnLeave", function(self)
      SetCheckboxVisual(self)
      end)
    target:HookScript("OnClick", function(self)
      SetCheckboxVisual(self)
      end)
    target._acbCheckboxHooks = true
  end
end

local function SkinEditBox(target)
  if not target then
    return
  end

  StripFrameTextures(target)

  if target.SetTextColor then
    ApplyColor(target, "SetTextColor", THEME.text)
  end

  if target.SetBackdrop then
    target:SetBackdrop(BACKDROP)
    ApplyColor(target, "SetBackdropColor", THEME.bgSoft)
    ApplyColor(target, "SetBackdropBorderColor", THEME.borderDim)
  end
end

local function SkinScrollPanel(target)
  if not target then
    return
  end

  StripFrameTextures(target)

  if target.SetBackdrop then
    target:SetBackdrop(BACKDROP)
    ApplyColor(target, "SetBackdropColor", THEME.bg)
    ApplyColor(target, "SetBackdropBorderColor", THEME.borderDim)
  end
end

local function SkinTitleText(target)
  if target and target.SetTextColor then
    ApplyColor(target, "SetTextColor", THEME.title)
  end
end

local function SkinHeadingText(target)
  if target and target.SetTextColor then
    ApplyColor(target, "SetTextColor", THEME.heading)
  end
end

local function SkinMutedText(target)
  if target and target.SetTextColor then
    ApplyColor(target, "SetTextColor", THEME.muted)
  end
end

local MENU_EDGE = 8
local MENU_PAD_TOP = 8
local MENU_PAD_BOTTOM = 8
local MENU_ITEM_HEIGHT = 22
local MENU_ITEM_GAP = 2
local MENU_MIN_WIDTH = 132

local function MenuItemVisual(item, hovered)
  SkinFrame(item, "soft")

  if item._acbChecked then
    ApplyColor(item, "SetBackdropColor", THEME.selection)
    ApplyColor(item, "SetBackdropBorderColor", THEME.border)
  end

  if hovered and not item._acbDisabled and not item._acbHeader then
    ApplyColor(item, "SetBackdropBorderColor", THEME.buttonHoverBorder)
  end

  local color = THEME.text
  if item._acbDisabled then
    color = THEME.buttonDisabledText
  elseif item._acbHeader then
    color = THEME.heading
  end

  ApplyColor(item.label, "SetTextColor", color)
end

local function CreateMenuItem(menu)
  local item = CreateFrame("Button", nil, menu)
  item:SetHeight(MENU_ITEM_HEIGHT)
  item:RegisterForClicks("LeftButtonUp")
  SkinFrame(item, "soft")

  item.marker = item:CreateTexture(nil, "OVERLAY")
  item.marker:SetTexture(WHITE8X8)
  item.marker:SetWidth(3)
  item.marker:SetPoint("TOPLEFT", item, "TOPLEFT", 4, -4)
  item.marker:SetPoint("BOTTOMLEFT", item, "BOTTOMLEFT", 4, 4)
  ApplyColor(item.marker, "SetVertexColor", THEME.checkboxChecked)
  item.marker:Hide()

  item.arrow = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  item.arrow:SetPoint("RIGHT", item, "RIGHT", -5, 0)
  item.arrow:SetFont(BUTTON_FONT, 9, "OUTLINE")
  item.arrow:SetText(">")
  ApplyColor(item.arrow, "SetTextColor", THEME.text)
  item.arrow:Hide()

  item.label = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  item.label:SetPoint("LEFT", item, "LEFT", 13, 0)
  item.label:SetPoint("RIGHT", item, "RIGHT", -14, 0)
  item.label:SetJustifyH("LEFT")

  item:SetScript("OnEnter", function(self)
    MenuItemVisual(self, true)
    end)
  item:SetScript("OnLeave", function(self)
    MenuItemVisual(self, false)
    end)
  item:SetScript("OnClick", function(self)
    if self._acbDisabled or self._acbHeader then
      return
    end

    local handler = self._acbOnClick

    if not self._acbKeepOpen then
      menu:Hide()
    end

    if handler then
      handler()
    end
    end)

  return item
end

local SkinSlider

local MENU_SLIDER_HEIGHT = 48

local function CreateMenuSlider(menu, options)
  local holder = CreateFrame("Frame", nil, menu)
  holder:SetHeight(MENU_SLIDER_HEIGHT)
  holder._acbKind = "slider"
  holder._acbHeight = MENU_SLIDER_HEIGHT

  holder.slider = SkinSlider(holder, options)
  holder.slider:ClearAllPoints()
  holder.slider:SetPoint("TOPLEFT", holder, "TOPLEFT", 13, -16)

  return holder
end

local function ClaimMenuRow(menu, kind, index, create)
  local pool = menu._acbPools[kind]
  local row = pool[index] or create()

  pool[index] = row
  menu._acbItems[index] = row

  return row
end

local function SkinMenu(frameName)
  local menu = CreateFrame("Frame", frameName, UIParent)
  menu:SetFrameStrata("FULLSCREEN_DIALOG")
  if menu.SetToplevel then
    menu:SetToplevel(true)
  end
  menu:EnableMouse(true)
  SkinFrame(menu)
  menu:Hide()

  menu:SetScript("OnHide", function(self)
    if self._acbCloser then
      self._acbCloser:Hide()
    end
    end)

  local register = AutoCallboardRuntime and RT.RegisterSpecialFrame
  if register and frameName then
    register(frameName)
  end

  menu._acbItems = {}
  menu._acbPools = { item = {}, slider = {} }
  menu._acbCount = 0

  function menu:Reset()
    self._acbCount = 0
    for _, pool in pairs(self._acbPools) do
      for _, row in pairs(pool) do
        row:Hide()
      end
    end
  end

  function menu:AddSlider(options)
    options = options or {}

    local index = self._acbCount + 1
    self._acbCount = index

    local holder = ClaimMenuRow(self, "slider", index, function()
      return CreateMenuSlider(self, options)
    end)

    holder._acbHeader = false
    holder._acbDisabled = false
    holder._acbHasArrow = false
    holder.slider:SetSliderRange(options.min, options.max)
    holder.slider:SetLabel(options.title)
    holder.slider:SetCommit(options.onCommit)
    holder.slider:SetFormatter(options.format)
    holder.slider:SetDisplayValue(options.value)
    holder:Show()

    return holder
  end

  function menu:AddItem(text, options)
    options = options or {}

    local index = self._acbCount + 1
    self._acbCount = index

    local item = ClaimMenuRow(self, "item", index, function()
      return CreateMenuItem(self)
    end)

    item._acbHeader = options.header and true or false
    item._acbDisabled = options.disabled and true or false
    item._acbChecked = options.checked and true or false
    item._acbKeepOpen = options.keepOpen and true or false
    item._acbHasArrow = options.arrow and true or false
    item._acbOnClick = options.onClick

    item.label:SetText(text or "")
    item:EnableMouse(not item._acbHeader)

    if item._acbChecked then
      item.marker:Show()
    else
      item.marker:Hide()
    end

    if item._acbHasArrow then
      item.arrow:Show()
    else
      item.arrow:Hide()
    end

    MenuItemVisual(item, false)

    return item
  end

  function menu:SetAutoClose(enabled)
    self._acbAutoClose = enabled and true or false

    if self._acbAutoClose and not self._acbCloser then
      self._acbCloser = CreateFrame("Frame", nil, UIParent)
      self._acbCloser:SetFrameStrata("DIALOG")
      self._acbCloser:SetAllPoints(UIParent)
      self._acbCloser:EnableMouse(true)
      self._acbCloser:Hide()
      self._acbCloser:SetScript("OnMouseUp", function()
        self:Hide()
        end)
    end
  end

  function menu:Layout()
    local count = self._acbCount
    local widest = 0

    for i = 1, count do
      local item = self._acbItems[i]
      local textWidth

      if item._acbKind == "slider" then
        textWidth = item.slider:GetWidth() or 0
      else
        textWidth = item.label:GetStringWidth() or 0

        if item._acbHasArrow then
          textWidth = textWidth + 12
        end
      end

      if textWidth > widest then
        widest = textWidth
      end
    end

    local width = widest + 27 + MENU_EDGE * 2 + 6
    if width < MENU_MIN_WIDTH then
      width = MENU_MIN_WIDTH
    end

    local y = -MENU_PAD_TOP
    local stack = 0
    for i = 1, count do
      local item = self._acbItems[i]
      local rowHeight = item._acbHeight or MENU_ITEM_HEIGHT
      item:ClearAllPoints()
      item:SetPoint("TOPLEFT", self, "TOPLEFT", MENU_EDGE, y)
      item:SetPoint("TOPRIGHT", self, "TOPRIGHT", -MENU_EDGE, y)
      item:Show()
      y = y - rowHeight - MENU_ITEM_GAP
      stack = stack + rowHeight
    end

    local height = MENU_PAD_TOP + MENU_PAD_BOTTOM + stack
    if count > 1 then
      height = height + (count - 1) * MENU_ITEM_GAP
    end

    self:SetWidth(width)
    self:SetHeight(height)
  end

  function menu:OpenAt(anchor, point, relativePoint, x, y)
    self:Layout()
    self:ClearAllPoints()

    if anchor then
      self:SetPoint(point or "TOPLEFT", anchor, relativePoint or "BOTTOMLEFT", x or 0, y or -2)
    else
      self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    if self._acbAutoClose and self._acbCloser then
      self._acbCloser:Show()
    end

    self:Show()

    if self.Raise then
      self:Raise()
    end
  end

  function menu:CloseWhenHidden(frame)
    if not frame or not frame.HookScript then
      return
    end

    self._acbHideHooked = self._acbHideHooked or {}
    if self._acbHideHooked[frame] then
      return
    end

    self._acbHideHooked[frame] = true
    frame:HookScript("OnHide", function()
      if menu:IsShown() then
        menu:Hide()
      end
      end)
  end

  return menu
end

function SkinSlider(parent, options)
  options = options or {}

  local step = options.step or 1

  local slider = CreateFrame("Slider", nil, parent)
  slider:EnableMouse(true)
  slider:SetWidth(options.width or 160)
  slider:SetHeight(16)
  slider:SetOrientation("HORIZONTAL")
  slider:SetMinMaxValues(options.min or 0, options.max or 1)
  slider:SetValueStep(step)
  slider:SetValue(options.min or 0)

  local track = slider:CreateTexture(nil, "BACKGROUND")
  track:SetTexture(WHITE8X8)
  track:SetHeight(4)
  track:SetPoint("LEFT", slider, "LEFT", 0, 0)
  track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
  ApplyColor(track, "SetVertexColor", THEME.borderDim)

  slider:SetThumbTexture(WHITE8X8)
  local thumb = slider:GetThumbTexture()
  if thumb then
    thumb:SetWidth(10)
    thumb:SetHeight(16)
    ApplyColor(thumb, "SetVertexColor", THEME.button)
  end

  slider._acbTooltip = options.tooltip

  slider.titleText = slider:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  slider.titleText:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 5)
  slider.titleText:SetText(options.title or "")
  ApplyColor(slider.titleText, "SetTextColor", THEME.muted)

  slider.valueText = slider:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  slider.valueText:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -5)
  slider.valueText:SetWidth((options.width or 160) + 160)
  slider.valueText:SetJustifyH("LEFT")
  ApplyColor(slider.valueText, "SetTextColor", THEME.text)

  local function renderValue()
    local value = slider:GetValue()
    slider.valueText:SetText(options.format and options.format(value) or tostring(value))
  end

  slider:SetScript("OnValueChanged", function(self)
    renderValue()
    if not self._acbSyncing and not self._acbDragging and options.onCommit then
      options.onCommit(self:GetValue())
    end
    end)
  slider:SetScript("OnMouseDown", function(self)
    self._acbDragging = true
    self._acbDragStart = self:GetValue()
    end)
  slider:SetScript("OnMouseUp", function(self)
    if not self._acbDragging then
      return
    end

    self._acbDragging = false

    local value = self:GetValue()
    if value ~= self._acbDragStart and options.onCommit then
      options.onCommit(value)
    end
    end)
  slider:EnableMouseWheel(true)
  slider:SetScript("OnMouseWheel", function(self, delta)
    self:SetValue(self:GetValue() + (delta > 0 and step or -step))
    end)
  slider:SetScript("OnEnter", function(self)
    if thumb then
      ApplyColor(thumb, "SetVertexColor", THEME.buttonHoverBorder)
    end
    if self._acbTooltip then
      OpenTip(self, "ANCHOR_RIGHT", self.titleText:GetText() or "")
      GameTooltip:AddLine(self._acbTooltip, 1, 1, 1)
      GameTooltip:Show()
    end
    end)
  slider:SetScript("OnLeave", function(self)
    if thumb then
      ApplyColor(thumb, "SetVertexColor", THEME.button)
    end
    GameTooltip:Hide()
    end)

  function slider:SetDisplayValue(value)
    self._acbSyncing = true
    self:SetValue(tonumber(value) or options.min or 0)
    self._acbSyncing = false
    renderValue()
  end

  function slider:SetSliderRange(minValue, maxValue)
    options.min = tonumber(minValue) or options.min
    options.max = tonumber(maxValue) or options.max
    self:SetMinMaxValues(options.min, options.max)
  end

  function slider:SetLabel(text)
    options.title = text or ""
    self.titleText:SetText(options.title)
  end

  function slider:SetCommit(fn)
    options.onCommit = fn
  end

  function slider:SetFormatter(fn)
    options.format = fn
    renderValue()
  end

  renderValue()

  return slider
end

local function localize(widget, key)
  local fn = AutoCallboardRuntime and RT.Localized
  if fn then
    fn(widget, key)
  elseif widget.SetText then
    widget:SetText((AutoCallboardLocale and AutoCallboardLocale[key]) or key)
  end
end

local function applyPoints(widget, one, many)
  if one then
    widget:SetPoint(one[1], one[2], one[3], one[4], one[5])
  end
  if many then
    for i = 1, #(many) do
      local p = many[i]
      widget:SetPoint(p[1], p[2], p[3], p[4], p[5])
    end
  end
end

local function AttachHoverTip(widget, titleKey, bodyKey, kind, extra)
  if not widget then
    return widget
  end

  local visual = (kind == "checkbox") and SetCheckboxVisual or SetButtonVisual
  local hasTip = titleKey or bodyKey or extra

  widget:SetScript("OnEnter", function(self)
    visual(self, "hover")
    if hasTip then
      OpenTip(self, "ANCHOR_RIGHT", titleKey)
      if bodyKey then GameTooltip:AddLine(tipText(bodyKey), 1, 1, 1) end
      if extra then extra(self) end
      GameTooltip:Show()
    end
    end)
  widget:SetScript("OnLeave", function(self)
    visual(self)
    if hasTip then GameTooltip:Hide() end
    end)

  return widget
end

local function BuildWindow(name, opts)
  opts = opts or {}
  local frame = CreateFrame("Frame", name, opts.parent or UIParent)

  local register = AutoCallboardRuntime and RT.RegisterSpecialFrame
  if name and not opts.noEsc and register then register(name) end

  if opts.width then frame:SetWidth(opts.width) end
  if opts.height then frame:SetHeight(opts.height) end
  frame:SetFrameStrata(opts.strata or "HIGH")
  if not opts.notToplevel and frame.SetToplevel then frame:SetToplevel(true) end
  if not opts.notClamped then frame:SetClampedToScreen(true) end
  frame:EnableMouse(true)

  if opts.bare then
    bareRoots[frame] = true
    FollowInterfaceScale(frame)
  else
    SkinFrame(frame)
  end

  if opts.movable then
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
      if not InCombatLockdown() and not RT.state.appearance.locked then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
      self:StopMovingOrSizing()
      if name then
        RT.state.windowPositions = RT.state.windowPositions or {}
        local point = RT.state.windowPositions[name] or {}
        RT.state.windowPositions[name] = point
        RT.SavePoint(self, point)
      end
    end)
    if name then frame:HookScript("OnShow", function(self)
      local point = RT.state.windowPositions and RT.state.windowPositions[name]
      if point then RT.RestorePoint(self, point) end
    end) end
  end

  if opts.titleKey then
    frame.title = frame:CreateFontString(nil, "OVERLAY", opts.titleFont or "GameFontNormalLarge")
    frame.title:SetPoint(opts.titleAt or "TOP", frame, opts.titleAt or "TOP", opts.titleX or 0, opts.titleY or -18)
    ;(opts.titlePlain and SkinTitleText or SkinHeadingText)(frame.title)
    localize(frame.title, opts.titleKey)
  end

  if opts.close then
    frame.closeButton = CreateFrame("Button", nil, frame)
    frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    SkinCloseButton(frame.closeButton, opts.close == true and frame or opts.close)
  end

  return frame
end

local function BuildButton(parent, opts)
  local button = CreateFrame("Button", opts.name, parent, opts.template or "UIPanelButtonTemplate")
  if opts.width then button:SetWidth(opts.width) end
  if opts.height then button:SetHeight(opts.height) end
  if opts.textKey then localize(button, opts.textKey)
  elseif opts.text then button:SetText(opts.text) end
  applyPoints(button, opts.point, opts.points)
  SkinButton(button)
  if opts.icon then SetButtonIcon(button, opts.icon, opts.iconColor) end
  if opts.onClick then button:SetScript("OnClick", opts.onClick) end
  if opts.tipTitle or opts.tipBody or opts.tipExtra then
    AttachHoverTip(button, opts.tipTitle, opts.tipBody, "button", opts.tipExtra)
  end
  return button
end

local DIALOG_WIDTH = 380
local DIALOG_CHOICE_HEIGHT = 22
local DIALOG_MAX_CHOICES = 12

local dialogFrame

local function DialogClose(frame, accepted)
  frame._acbAccepted = accepted and true or false
  frame:Hide()
end

local function DialogChoiceVisual(row)
  SkinFrame(row, "soft")

  if row._acbSelected then
    ApplyColor(row, "SetBackdropColor", THEME.selection)
    ApplyColor(row, "SetBackdropBorderColor", THEME.border)
  elseif IsMouseOverFrame(row) then
    ApplyColor(row, "SetBackdropBorderColor", THEME.buttonHoverBorder)
  end
end

local function BuildDialog()
  local frame = CreateFrame("Frame", "AutoCallboardDialog", UIParent)
  frame:SetWidth(DIALOG_WIDTH)
  frame:SetHeight(160)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
  frame:SetFrameStrata("FULLSCREEN_DIALOG")
  if frame.SetToplevel then
    frame:SetToplevel(true)
  end
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
  frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
  SkinFrame(frame)
  frame:Hide()

  local register = AutoCallboardRuntime and RT.RegisterSpecialFrame
  if register then
    register("AutoCallboardDialog")
  end

  frame.blocker = CreateFrame("Frame", nil, UIParent)
  frame.blocker:SetFrameStrata("DIALOG")
  frame.blocker:SetAllPoints(UIParent)
  frame.blocker:EnableMouse(true)
  frame.blocker:Hide()

  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -16)
  frame.title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -16)
  frame.title:SetJustifyH("LEFT")
  SkinHeadingText(frame.title)

  frame.body = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  frame.body:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -10)
  frame.body:SetWidth(DIALOG_WIDTH - 36)
  frame.body:SetJustifyH("LEFT")
  frame.body:SetJustifyV("TOP")
  ApplyColor(frame.body, "SetTextColor", THEME.text)

  frame.editBox = CreateFrame("EditBox", "AutoCallboardDialogEditBox", frame, "InputBoxTemplate")
  frame.editBox:SetWidth(DIALOG_WIDTH - 44)
  frame.editBox:SetHeight(24)
  frame.editBox:SetAutoFocus(false)
  SkinEditBox(frame.editBox)
  frame.editBox:SetScript("OnEscapePressed", function()
    DialogClose(frame, false)
    end)
  frame.editBox:SetScript("OnEnterPressed", function()
    if frame._acbAcceptButton and frame._acbAcceptButton:IsEnabled() then
      frame._acbAcceptButton:Click()
    end
    end)
  frame.editBox:Hide()

  frame._acbChoiceRows = {}

  frame.acceptButton = BuildButton(frame, {
    width = 96,
    height = 24,
    text = "",
    point = { "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 16 },
    onClick = function()
      local handler = frame._acbOnAccept
      local value = frame._acbValue

      if frame._acbHasEditBox then
        value = frame.editBox:GetText()
      end

      DialogClose(frame, true)

      if handler then
        handler(value)
      end
      end,
  })
  frame._acbAcceptButton = frame.acceptButton

  frame.cancelButton = BuildButton(frame, {
    width = 96,
    height = 24,
    text = "",
    point = { "RIGHT", frame.acceptButton, "LEFT", -8, 0 },
    onClick = function()
      DialogClose(frame, false)
      end,
  })

  frame:SetScript("OnHide", function(self)
    self.blocker:Hide()
    self.editBox:ClearFocus()

    local handler = not self._acbAccepted and self._acbOnCancel or nil

    self._acbOnAccept = nil
    self._acbOnCancel = nil

    if handler then
      handler()
    end
    end)

  return frame
end

local function DialogChoiceRow(frame, index)
  local row = frame._acbChoiceRows[index]

  if row then
    return row
  end

  row = CreateFrame("Button", nil, frame)
  row:SetHeight(DIALOG_CHOICE_HEIGHT)
  row:RegisterForClicks("LeftButtonUp")
  SkinFrame(row, "soft")

  row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  row.label:SetPoint("LEFT", row, "LEFT", 8, 0)
  row.label:SetPoint("RIGHT", row, "RIGHT", -8, 0)
  row.label:SetJustifyH("LEFT")
  ApplyColor(row.label, "SetTextColor", THEME.text)

  row:SetScript("OnEnter", function(self) DialogChoiceVisual(self) end)
  row:SetScript("OnLeave", function(self) DialogChoiceVisual(self) end)
  row:SetScript("OnClick", function(self)
    for i = 1, #(frame._acbChoiceRows) do
      local other = frame._acbChoiceRows[i]
      other._acbSelected = other == self
      DialogChoiceVisual(other)
    end

    frame._acbValue = self._acbValue

    if frame._acbAcceptButton then
      frame._acbAcceptButton:Enable()
      SetButtonVisual(frame._acbAcceptButton)
    end
    end)

  frame._acbChoiceRows[index] = row

  return row
end

local function ShowDialog(opts)
  opts = opts or {}

  if not dialogFrame then
    dialogFrame = BuildDialog()
  end

  local frame = dialogFrame

  frame._acbOnCancel = nil
  frame._acbAccepted = true
  frame:Hide()

  frame._acbAccepted = false
  frame._acbOnAccept = opts.onAccept
  frame._acbOnCancel = opts.onCancel
  frame._acbValue = opts.value
  frame._acbHasEditBox = opts.editBox ~= nil

  frame.title:SetText(opts.title or "")
  frame.body:SetText(opts.body or "")

  local y = -16 - (frame.title:GetStringHeight() or 14) - 10
  y = y - (frame.body:GetStringHeight() or 0)

  local choices = opts.choices
  local choiceCount = 0

  for i = 1, #(frame._acbChoiceRows) do
    frame._acbChoiceRows[i]:Hide()
    frame._acbChoiceRows[i]._acbSelected = false
  end

  if type(choices) == "table" and #(choices) > 0 then
    choiceCount = math.min(#(choices), DIALOG_MAX_CHOICES)
    y = y - 8

    for i = 1, choiceCount do
      local row = DialogChoiceRow(frame, i)
      row._acbValue = choices[i].value
      row.label:SetText(tostring(choices[i].text or ""))
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, y)
      row:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, y)
      DialogChoiceVisual(row)
      row:Show()
      y = y - DIALOG_CHOICE_HEIGHT - 2
    end
  end

  if opts.editBox then
    frame.editBox:ClearAllPoints()
    frame.editBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, y - 10)
    frame.editBox:SetMaxLetters(tonumber(opts.editBox.maxLetters) or 0)
    frame.editBox:SetText(tostring(opts.editBox.default or ""))
    frame.editBox:Show()
    y = y - 10 - 24
  else
    frame.editBox:Hide()
  end

  frame:SetHeight(math.max(120, -y + 20 + 24 + 16))

  frame.acceptButton:SetText(opts.acceptText or "")
  if choiceCount > 0 and opts.value == nil then
    frame.acceptButton:Disable()
  else
    frame.acceptButton:Enable()
  end
  SetButtonVisual(frame.acceptButton)

  if opts.cancelText then
    frame.cancelButton:SetText(opts.cancelText)
    frame.cancelButton:Show()
    SetButtonVisual(frame.cancelButton)
  else
    frame.cancelButton:Hide()
  end

  frame.blocker:Show()
  frame:Show()

  if frame.Raise then
    frame:Raise()
  end

  if opts.editBox then
    frame.editBox:SetFocus()
    frame.editBox:HighlightText()
  end

  return frame
end

local function BuildRow(parent, name, height, ...)
  local row = CreateFrame("Button", name, parent)
  row:SetHeight(height)

  if select("#", ...) > 0 then
    row:RegisterForClicks(...)
  else
    row:RegisterForClicks("LeftButtonUp")
  end

  SkinFrame(row, "soft")

  row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  row.title:SetPoint("LEFT", row, "LEFT", 6, 0)
  row.title:SetPoint("RIGHT", row, "RIGHT", -6, 0)
  row.title:SetJustifyH("LEFT")

  return row
end

local function PaintRow(row, selected, hovered, disabled)
  SkinFrame(row, "soft")

  if selected then
    ApplyColor(row, "SetBackdropColor", THEME.selection)
    ApplyColor(row, "SetBackdropBorderColor", THEME.border)
  end

  if hovered then
    ApplyColor(row, "SetBackdropBorderColor", THEME.buttonHoverBorder)
  end

  local color = disabled and THEME.buttonDisabledText or THEME.text
  ApplyColor(row.title, "SetTextColor", color)
end

local function BuildSettingCheckbox(parent, opts)
  local checkbox = CreateFrame("CheckButton", nil, parent)
  applyPoints(checkbox, opts.point)
  SkinCheckbox(checkbox)
  if opts.onClick then
    checkbox:SetScript("OnClick", opts.onClick)
    checkbox:HookScript("OnClick", function(self)
      SetCheckboxVisual(self)
      end)
  end
  AttachHoverTip(checkbox, opts.labelKey, opts.tipKey, "checkbox")

  local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("RIGHT", checkbox, "LEFT", -8, 0)
  localize(label, opts.labelKey)
  SkinMutedText(label)
  checkbox._acbLabel = label
  return checkbox
end

AutoCallboardSkin.HoverTip = AttachHoverTip
AutoCallboardSkin.OpenTip = OpenTip
AutoCallboardSkin.Window = BuildWindow
AutoCallboardSkin.MakeButton = BuildButton
AutoCallboardSkin.SettingCheckbox = BuildSettingCheckbox
AutoCallboardSkin.Row = BuildRow
AutoCallboardSkin.PaintRow = PaintRow
AutoCallboardSkin.Dialog = ShowDialog

AutoCallboardSkin.THEME = THEME
AutoCallboardSkin.WHITE8X8              = WHITE8X8
AutoCallboardSkin.BACKDROP = BACKDROP
AutoCallboardSkin.BUTTON_FONT = BUTTON_FONT
AutoCallboardSkin.ApplyColor = ApplyColor
AutoCallboardSkin.SetButtonVisual = SetButtonVisual
AutoCallboardSkin.SetButtonIcon = SetButtonIcon
AutoCallboardSkin.SetCheckboxVisual = SetCheckboxVisual
AutoCallboardSkin.CloseButton = SkinCloseButton
AutoCallboardSkin.Frame = SkinFrame
AutoCallboardSkin.StripButtonChrome = StripButtonChrome
AutoCallboardSkin.StripFrameTextures = StripFrameTextures
AutoCallboardSkin.Button = SkinButton
AutoCallboardSkin.ScrollButton = SkinScrollButton
AutoCallboardSkin.ScrollBar = SkinScrollBar
AutoCallboardSkin.Checkbox = SkinCheckbox
AutoCallboardSkin.EditBox = SkinEditBox
AutoCallboardSkin.ScrollPanel = SkinScrollPanel
AutoCallboardSkin.TitleText = SkinTitleText
AutoCallboardSkin.HeadingText = SkinHeadingText
AutoCallboardSkin.MutedText = SkinMutedText
AutoCallboardSkin.HelpButton = SkinHelpButton
AutoCallboardSkin.GearButton = SkinGearButton
AutoCallboardSkin.Menu = SkinMenu
AutoCallboardSkin.Slider = SkinSlider

local originals = {}
for key, value in pairs(THEME) do
  originals[key] = {unpack(value)}
  THEME[key] = {unpack(value)}
end

function AutoCallboardSkin.UnpackColor(value)
  return math.floor(value / 65536) / 255, math.floor(value / 256) % 256 / 255, value % 256 / 255
end

local function luminance(r, g, b)
  local function linear(v) return v <= 0.04045 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
  return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
end

function AutoCallboardSkin.ApplyAppearance(config)
  local br, bg, bb = AutoCallboardSkin.UnpackColor(config.background)
  local ar, ag, ab = AutoCallboardSkin.UnpackColor(config.accent)
  local neutral = luminance(br, bg, bb) > 0.179 and 0.04 or 0.96
  local background = {bg = true, bgSoft = true, card = true, debugList = true,
    checkbox = true, close = true, closeBorder = true}
  local foreground = {text = true, muted = true, title = true, gold = true, good = true}
  for key, value in pairs(THEME) do
    local original = originals[key]
    for i = 1, 4 do value[i] = original[i] end
    if background[key] then
      if config.background ~= 0x050505 then value[1], value[2], value[3] = br, bg, bb end
      if key == "bg" or key == "bgSoft" or key == "card" or key == "debugList" then
        value[4] = original[4] * config.opacity / 0.96
      end
    elseif foreground[key] then
      if config.background ~= 0x050505 then value[1], value[2], value[3] = neutral, neutral, neutral end
    elseif key ~= "buttonText" and key ~= "buttonDisabledText" and key ~= "buttonStop" and key ~= "buttonStopText" then
      if config.accent ~= 0xB048F8 then
        local brightness = math.max(original[1], original[2], original[3]) / (248 / 255)
        value[1], value[2], value[3] = math.min(1, ar * brightness), math.min(1, ag * brightness), math.min(1, ab * brightness)
      end
    end
  end
  if config.accent ~= 0xB048F8 then
    local text = luminance(unpack(THEME.button)) > 0.179 and 0.04 or 0.96
    for _, key in ipairs({"buttonText", "buttonDisabledText"}) do
      THEME[key][1], THEME[key][2], THEME[key][3] = text, text, text
    end
  end
  if config.background ~= 0x050505 or config.accent ~= 0xB048F8 then
    for _, key in ipairs({"heading", "closeText"}) do
      local value, base = THEME[key], luminance(br, bg, bb)
      for step = 1, 20 do
        local lum = luminance(unpack(value))
        if (math.max(lum, base) + 0.05) / (math.min(lum, base) + 0.05) >= 4.5 then break end
        for i = 1, 3 do value[i] = value[i] + (neutral - value[i]) * 0.2 end
      end
    end
  end
  for method, entries in pairs(colors) do
    for widget, value in pairs(entries) do widget[method](widget, unpack(value)) end
  end
end

function AutoCallboardSkin.ScaleRoots(scale)
  for _, roots in ipairs({colors.SetBackdropColor or {}, bareRoots}) do
    for widget in pairs(roots) do
      if widget.GetParent and widget:GetParent() == UIParent then widget:SetScale(scale) end
    end
  end
end

function AutoCallboardSkin.AccentCode()
  local c = THEME.heading
  return string.format("|cff%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255)
end
