local Skin = AutoCallboardSkin
local L = AutoCallboardLocale
local RT = AutoCallboardRuntime

local SECTIONS = { "about", "callboard", "routes", "builds", "display" }
local TAB_KEYS = {
  "HELP_TAB_ABOUT",
  "HELP_TAB_CALLBOARD",
  "HELP_TAB_ROUTES",
  "HELP_TAB_BUILDS",
  "HELP_TAB_DISPLAY",
}

local WINDOW_WIDTH = 580
local WINDOW_HEIGHT = 560
local PAGE_WIDTH = WINDOW_WIDTH - 36
local TEXT_WIDTH = PAGE_WIDTH - 32

local helpWindow, tabs

local function SectionIndex(name)
  for i = 1, #SECTIONS do
    if SECTIONS[i] == name then
      return i
    end
  end

  return nil
end

local MARKERS = { ["# "] = "heading", ["! "] = "note" }

local LINKS = {
  update = function()
    return RT.updateUrl
  end,
  license = function()
    return RT.licenseUrl
  end,
}

local DYNAMIC = {
  targetName = function()
    return RT.state and RT.state.targetName
  end,
  version = function()
    return RT.GetAddonVersion and RT.GetAddonVersion()
  end,
  latest = function()
    return RT.GetAvailableUpdate and (RT.GetAvailableUpdate())
  end,
}

local function Resolve(text, plain)
  local missing = false
  local resolved = string.gsub(text, "{([%w_]+)}", function(key)
    local dynamic = DYNAMIC[key]
    local value

    if dynamic then
      value = dynamic()
    else
      value = L[key]
    end

    if value == nil or value == "" then
      if dynamic then missing = true end
      return "{" .. key .. "}"
    end

    value = tostring(value)

    if plain then
      return value
    end

    return Skin.AccentCode() .. value .. "|r"
    end)

  return resolved, missing
end

local function ParseLine(line)
  local target, rest = string.match(line, "^@(%a+) (.+)$")

  if target then
    return "link", rest, target
  end

  target, rest = string.match(line, "^%[(%a+)%] (.+)$")

  if target then
    return "button", rest, target
  end

  local style = MARKERS[string.sub(line, 1, 2)]

  if style then
    return style, string.sub(line, 3)
  end

  return "body", line
end

local function LinkBlock(style, text, target)
  local url = LINKS[target] and LINKS[target]()

  if not url then
    return { style = "body", text = text }
  end

  if not RT.LinkMethod() then
    return { style = "body", text = text .. " " .. url }
  end

  return {
    style = style,
    text = text,
    tip = RT.LinkTip(),
    onClick = function() RT.OpenLink(url) end,
  }
end

local function RenderSection(name)
  local sections = L.HELP_SECTIONS
  local lines = sections and sections[name]
  local blocks = {}

  if not lines then
    return blocks
  end

  for i = 1, #lines do
    local line = lines[i]

    if line == "" then
      blocks[#blocks + 1] = { style = "gap" }
    else
      local style, source, target = ParseLine(line)
      local text, missing = Resolve(source, style ~= "body" and style ~= "note")

      if not missing and target then
        blocks[#blocks + 1] = LinkBlock(style, text, target)
      elseif not missing then
        blocks[#blocks + 1] = { style = style, text = text }
      end
    end
  end

  return blocks
end

local function Refresh()
  for i = 1, #SECTIONS do
    helpWindow.scrolls[i]:SetBlocks(RenderSection(SECTIONS[i]))
  end
end

local function CreateHelpWindow()
  if helpWindow then
    return
  end

  helpWindow = Skin.Window("AutoCallboardHelpWindow", {
    width = WINDOW_WIDTH,
    height = WINDOW_HEIGHT,
    strata = "FULLSCREEN_DIALOG",
    movable = true,
    titleKey = "HELP_WINDOW_TITLE",
    close = true,
  })
  helpWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

  tabs = Skin.Tabs(helpWindow, {
    keys = TAB_KEYS,
    x = 18,
    y = -40,
    width = 104,
    step = 110,
    pageInset = { 18, -85, -18, 52 },
  })

  helpWindow.tabs = tabs
  helpWindow.scrolls = {}

  for i = 1, #SECTIONS do
    local page = tabs.pages[i]

    helpWindow.scrolls[i] = Skin.ScrollText(page, {
      name = "AutoCallboardHelpScroll" .. i,
      textWidth = TEXT_WIDTH,
      points = {
        { "TOPLEFT", page, "TOPLEFT", 0, 0 },
        { "BOTTOMRIGHT", page, "BOTTOMRIGHT", -26, 0 },
      },
    })
  end

  helpWindow.closeTextButton = Skin.MakeButton(helpWindow, {
    width = 78,
    height = 24,
    textKey = "BUTTON_CLOSE",
    points = { { "BOTTOMRIGHT", helpWindow, "BOTTOMRIGHT", -18, 18 } },
    onClick = function() helpWindow:Hide() end,
  })

  RT.helpWindow = helpWindow
end

local function ShowAddonHelp(section)
  CreateHelpWindow()

  local index = tabs.index

  if section then
    index = SectionIndex(section) or 1
  end

  if index < 1 then
    index = 1
  end

  Refresh()
  tabs.Select(index)
  helpWindow:Show()

  if helpWindow.Raise then
    helpWindow:Raise()
  end
end

RT.ShowAddonHelp = ShowAddonHelp

function RT.HelpSections()
  return SECTIONS
end

function RT.IsHelpWindowShown()
  return helpWindow ~= nil and helpWindow:IsShown()
end

function RT.HideHelpWindow()
  if helpWindow then
    helpWindow:Hide()
  end
end
