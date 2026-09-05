local Skin = AutoCallboardSkin
local THEME = Skin.THEME
local L = AutoCallboardLocale
local RT = AutoCallboardRuntime
local Localized = RT.Localized

local helpWindow

local function HelpName(text)
  return "|cffb048f8" .. tostring(text or "") .. "|r"
end

local function GetHelpText()
  local H = L.HELP_LINES
  local lines = {
    string.format(H[1], HelpName(L.BUTTON_QUESTS)),
    H[2],
    H[3],
    H[4],
    H[5],
    H[6],
    H[7],
    H[8],
    H[9],
    string.format(H[10], HelpName(L.BUTTON_START)),
    H[11],
    H[12],
    H[13],
    string.format(H[14], HelpName("Callboard")),
    H[15],
    H[16],
    H[17],
    H[18],
    H[19],
    H[20],
    H[21],
    string.format(H[22], HelpName(L.BUTTON_STOP)),
    H[23],
    H[24],
    H[25],
    H[26],
    H[27],
    H[28],
    H[29],
    H[30],
    string.format(H[31], HelpName("Callboard")),
    string.format(H[32], HelpName(L.BUTTON_START)),
    string.format(H[33], HelpName(L.AUTO_CURRENT_INSTANCE_LABEL)),
    string.format(H[34], HelpName(L.BUTTON_SHARE)),
    H[35],
    string.format(H[36], HelpName(L.AUTO_ACCEPT_SHARED_LABEL)),
    H[37],
    string.format(H[38], HelpName(L.SEARCH_LABEL)),
    string.format(H[39], HelpName(L.BUTTON_SELECT)),
    string.format(H[40], HelpName(L.BUTTON_EXPORT), HelpName(L.BUTTON_IMPORT)),
    string.format(H[41], HelpName(L.MINIMAP_BUTTON_LABEL)),
    string.format(H[42], HelpName("/acb minimap on"), HelpName("/acb minimap off")),
    string.format(H[43], HelpName("+"), HelpName("<<")),
    string.format(H[44], HelpName(L.ROLL_SPEED_LABEL)),
    string.format(H[45],
        HelpName(L.ROLL_SPEED_PRESET_NAMES.turbo),
        HelpName(L.ROLL_SPEED_PRESET_NAMES.fast),
        HelpName(L.ROLL_SPEED_PRESET_NAMES.normal),
        HelpName(L.ROLL_SPEED_PRESET_NAMES.safe)),
    H[46],
  }

  return table.concat(lines, "\n")
end

local function ShowAddonHelp()
  if not helpWindow then
    helpWindow = Skin.Window("AutoCallboardHelpWindow", {
      width = 430,
      height = 560,
      strata = "FULLSCREEN_DIALOG",
      movable = true,
      titleKey = "HELP_WINDOW_TITLE",
      close = true,
    })
    helpWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    helpWindow.body = helpWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    helpWindow.body:SetPoint("TOPLEFT", helpWindow, "TOPLEFT", 24, -52)
    helpWindow.body:SetPoint("BOTTOMRIGHT", helpWindow, "BOTTOMRIGHT", -24, 44)
    helpWindow.body:SetJustifyH("LEFT")
    helpWindow.body:SetJustifyV("TOP")
    helpWindow.body:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3], THEME.text[4] or 1)

    helpWindow.okButton = Skin.MakeButton(helpWindow, {
      width = 78,
      height = 24,
      textKey = "BUTTON_CLOSE",
      points = { { "BOTTOMRIGHT", helpWindow, "BOTTOMRIGHT", -24, 18 } },
      onClick = function() helpWindow:Hide() end,
    })
  end

  Localized(helpWindow.title, "HELP_WINDOW_TITLE")
  helpWindow.body:SetText(GetHelpText())
  helpWindow:Show()
  if helpWindow.Raise then
    helpWindow:Raise()
  end
end

RT.ShowAddonHelp = ShowAddonHelp

function RT.IsHelpWindowShown()
  return helpWindow ~= nil and helpWindow:IsShown()
end

function RT.HideHelpWindow()
  if helpWindow then
    helpWindow:Hide()
  end
end
