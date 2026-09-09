local Core = AutoCallboardCore
local Skin = AutoCallboardSkin
local THEME = Skin.THEME
local L = AutoCallboardLocale
local RT = AutoCallboardRuntime
local Print = RT.Print
local Localized = RT.Localized
local CompactText = RT.CompactText
local state = RT.state

local dataWindow
local dataEditBox

local Log = RT.Log

local function ShowDebugWindow()
  if RT.ShowDebugWindow then
    RT.ShowDebugWindow()
  end
end

function RT.SetQuestDataSelectionVisible(selected)
  if RT.questDataScrollFrame then
    Skin.ApplyColor(RT.questDataScrollFrame, "SetBackdropColor", selected and THEME.bgSoft or THEME.bg)
    Skin.ApplyColor(RT.questDataScrollFrame, "SetBackdropBorderColor", selected and THEME.buttonHoverBorder or THEME.borderDim)
  end

  if RT.questDataSelectionOverlay then
    if selected then
      RT.questDataSelectionOverlay:Show()
    else
      RT.questDataSelectionOverlay:Hide()
    end
  end

  if RT.questDataSelectionText then
    if selected then
      RT.questDataSelectionText:Show()
    else
      RT.questDataSelectionText:Hide()
    end
  end
end

function RT.SelectQuestDataText(alreadyFocused)
  if not dataEditBox then
    return
  end

  if not alreadyFocused then
    dataEditBox:SetFocus()
  end
  dataEditBox:HighlightText()
  RT.SetQuestDataSelectionVisible(true)
end

local function SetQuestDataText(text)
  if not dataEditBox then
    return
  end

  text = text or ""

  local lineCount = 1
  for _ in string.gmatch(text, "\n") do
    lineCount = lineCount + 1
  end

  dataEditBox:SetHeight(math.max(330, lineCount * 14))
  RT.questDataReadOnlyText = text
  RT.questDataEditBoxUpdating = true
  dataEditBox:SetText(text)
  dataEditBox:SetCursorPosition(0)
  RT.questDataEditBoxUpdating = false
  RT.SetQuestDataSelectionVisible(false)
end

local function ImportQuestDataFromText(text)
  local quests, imported, skipped = Core.importKnownQuestText(text)
  RT.LogQuestImportDiagnostics(text, "button", imported, skipped)

  if imported <= 0 then
    local firstLine = tostring(text or ""):match("([^\r\n]+)") or "empty"
    local preview = CompactText(firstLine)

    Print(string.format(L.IMPORT_NO_DATA, preview))
    Log("import", "failed imported=0 skipped=", skipped, " first=\"", preview, "\"")
    ShowDebugWindow()
    return
  end

  local beforeCount = #(state.knownQuests or {})
  state.knownQuests = Core.mergeKnownQuestLists(state.knownQuests, quests)
  RT.TouchState()

  local afterCount = #(state.knownQuests or {})
  Log("import", "imported=", imported, " skipped=", skipped, " known=", beforeCount, "->", afterCount)

  RT.RefreshQuestWindow()
end

function RT.LogQuestImportDiagnostics(text, source, imported, skipped)
  local info = Core.analyzeQuestImportText(text)

  Log("import-debug", "source=", source or "unknown", " length=", info.textLength, " lines=", info.lineCount, " nonempty=", info.nonEmptyLineCount, " marker=", info.marker or "none", " markerLine=", info.markerLine, " dataLines=", info.dataLineCount, " importableLines=", info.importableLineCount, " invalidLines=", info.invalidLineCount, " imported=", imported or "n/a", " skipped=", skipped or "n/a", " first=\"", CompactText(info.firstLine), "\"")

  for i = 1, #(info.samples or {}) do
    local sample = info.samples[i]
    Log("import-debug", "sample", i, " line=", sample.line, " len=", sample.length, " marker=", sample.marker, " v3Sep=", sample.v3Separators, " v2Sep=", sample.v2Separators, " slashSep=", sample.slashSeparators, " tabSep=", sample.tabSeparators, " v3Fields=", sample.v3Fields, " v2Fields=", sample.v2Fields, " slashFields=", sample.slashFields, " tabFields=", sample.v1Fields, " activeFields=", sample.activeFields, " importable=", sample.importable, " text=\"", CompactText(sample.preview), "\"")
  end

  if info.stoppedAtFence then
    Log("import-debug", "stopped at closing code fence")
  end
end

function RT.ExportQuestDataText(source)
  RT.CaptureCurrentObjectives()

  local text = Core.exportKnownQuestText(state.knownQuests)
  local info = Core.analyzeQuestImportText(text)

  Log("export-debug", "source=", source or "unknown", " known=", #(state.knownQuests or {}), " length=", string.len(text), " lines=", info.lineCount, " marker=", info.marker or "none", " dataLines=", info.dataLineCount, " importableLines=", info.importableLineCount, " invalidLines=", info.invalidLineCount)

  for i = 1, #(info.samples or {}) do
    local sample = info.samples[i]
    Log("export-debug", "sample", i, " line=", sample.line, " len=", sample.length, " v3Sep=", sample.v3Separators, " v2Sep=", sample.v2Separators, " slashSep=", sample.slashSeparators, " tabSep=", sample.tabSeparators, " activeFields=", sample.activeFields, " importable=", sample.importable, " text=\"", CompactText(sample.preview), "\"")
  end

  return text
end

function RT.SyncQuestDataControls()
  local mode = RT.questDataMode
  local leftButton = mode == "export" and RT.questDataExportButton or RT.questDataImportButton
  local rightButton = mode == "export" and RT.questDataSelectButton or RT.questDataClearButton

  if RT.questDataExportButton then
    if mode == "export" then
      RT.questDataExportButton:Show()
    else
      RT.questDataExportButton:Hide()
    end
  end

  if RT.questDataImportButton then
    if mode == "import" then
      RT.questDataImportButton:Show()
    else
      RT.questDataImportButton:Hide()
    end
  end

  if RT.questDataSelectButton then
    if mode == "export" then
      RT.questDataSelectButton:Show()
    else
      RT.questDataSelectButton:Hide()
    end
  end

  if RT.questDataClearButton then
    if mode == "import" then
      RT.questDataClearButton:Show()
    else
      RT.questDataClearButton:Hide()
    end
  end

  if leftButton and leftButton.ClearAllPoints then
    leftButton:ClearAllPoints()
    leftButton:SetPoint("BOTTOMLEFT", dataWindow, "BOTTOMLEFT", 24, 22)
  end

  if rightButton and rightButton.ClearAllPoints and leftButton then
    rightButton:ClearAllPoints()
    rightButton:SetPoint("LEFT", leftButton, "RIGHT", 8, 0)
  end

  if RT.questDataSelectionText and RT.questDataSelectionText.ClearAllPoints then
    RT.questDataSelectionText:ClearAllPoints()
    RT.questDataSelectionText:SetPoint("LEFT", rightButton or leftButton, "RIGHT", 12, 0)
  end
end

local function ShowQuestDataWindow(mode)
  if not dataWindow then
    dataWindow = Skin.Window("AutoCallboardQuestDataWindow", {
      width = 720,
      height = 430,
      strata = "FULLSCREEN_DIALOG",
      movable = true,
      titleKey = "QUESTDATA_WINDOW_TITLE",
      titlePlain = true,
      close = true,
    })
    dataWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    local scrollFrame = CreateFrame("ScrollFrame", "AutoCallboardQuestDataScrollFrame", dataWindow, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", dataWindow, "TOPLEFT", 24, -48)
    scrollFrame:SetPoint("BOTTOMRIGHT", dataWindow, "BOTTOMRIGHT", -36, 54)
    Skin.ScrollPanel(scrollFrame)
    Skin.ScrollBar(scrollFrame)
    RT.questDataScrollFrame = scrollFrame
    RT.questDataSelectionOverlay = scrollFrame:CreateTexture(nil, "ARTWORK")
    RT.questDataSelectionOverlay:SetTexture(Skin.WHITE8X8)
    RT.questDataSelectionOverlay:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 3, -3)
    RT.questDataSelectionOverlay:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -22, 3)
    Skin.ApplyColor(RT.questDataSelectionOverlay, "SetVertexColor", THEME.selection)
    RT.questDataSelectionOverlay:Hide()

    dataEditBox = CreateFrame("EditBox", "AutoCallboardQuestDataEditBox", scrollFrame)
    dataEditBox:SetMultiLine(true)
    dataEditBox:SetAutoFocus(false)
    dataEditBox:SetFontObject(ChatFontNormal)
    dataEditBox:SetWidth(650)
    dataEditBox:SetHeight(330)
    if dataEditBox.SetTextInsets then
      dataEditBox:SetTextInsets(3, 3, 3, 3)
    end
    Skin.StripFrameTextures(dataEditBox)
    if dataEditBox.SetTextColor then
      Skin.ApplyColor(dataEditBox, "SetTextColor", THEME.text)
    end
    if dataEditBox.SetBackdrop then
      dataEditBox:SetBackdrop(nil)
    end
    dataEditBox:SetScript("OnTextChanged", function(self)
      if RT.questDataEditBoxUpdating then
        return
      end

      if RT.questDataMode == "export" then
        RT.questDataEditBoxUpdating = true
        self:SetText(RT.questDataReadOnlyText or "")
        self:HighlightText()
        RT.questDataEditBoxUpdating = false
        RT.SetQuestDataSelectionVisible(true)
      else
        RT.SetQuestDataSelectionVisible(false)
      end
      end)
    dataEditBox:SetScript("OnEditFocusGained", function()
      if RT.questDataMode == "export" then
        RT.SelectQuestDataText(true)
      end
      end)
    dataEditBox:SetScript("OnMouseUp", function()
      if RT.questDataMode == "export" then
        RT.SelectQuestDataText()
      end
      end)
    dataEditBox:SetScript("OnEscapePressed", function(self)
      self:ClearFocus()
      dataWindow:Hide()
      end)
    scrollFrame:SetScrollChild(dataEditBox)

    local exportButton = Skin.MakeButton(dataWindow, {
      width = 76,
      height = 24,
      textKey = "BUTTON_EXPORT",
      points = { { "BOTTOMLEFT", dataWindow, "BOTTOMLEFT", 24, 22 } },
      onClick = function()
        RT.questDataMode = "export"
        RT.SyncQuestDataControls()
        SetQuestDataText(RT.ExportQuestDataText("button"))
        RT.SelectQuestDataText()
        end,
    })
    RT.questDataExportButton = exportButton

    local importButton = Skin.MakeButton(dataWindow, {
      width = 76,
      height = 24,
      textKey = "BUTTON_IMPORT",
      points = { { "LEFT", exportButton, "RIGHT", 8, 0 } },
      onClick = function()
        ImportQuestDataFromText(dataEditBox:GetText() or "")
        end,
    })
    RT.questDataImportButton = importButton

    local selectButton = Skin.MakeButton(dataWindow, {
      width = 84,
      height = 24,
      textKey = "BUTTON_SELECT_ALL",
      points = { { "LEFT", importButton, "RIGHT", 8, 0 } },
      onClick = function()
        if RT.questDataMode == "export" then
          SetQuestDataText(RT.ExportQuestDataText("select-all"))
        end
        RT.SelectQuestDataText()
        end,
    })
    RT.questDataSelectButton = selectButton

    local clearButton = Skin.MakeButton(dataWindow, {
      width = 64,
      height = 24,
      textKey = "BUTTON_CLEAR",
      points = { { "LEFT", selectButton, "RIGHT", 8, 0 } },
      onClick = function()
        RT.questDataMode = "import"
        RT.SyncQuestDataControls()
        SetQuestDataText("")
        dataEditBox:SetFocus()
        end,
    })
    RT.questDataClearButton = clearButton

    RT.questDataSelectionText = dataWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    RT.questDataSelectionText:SetPoint("LEFT", clearButton, "RIGHT", 12, 0)
    Localized(RT.questDataSelectionText, "QUESTDATA_SELECTED_HINT")
    Skin.HeadingText(RT.questDataSelectionText)
    RT.questDataSelectionText:Hide()
  end

  RT.questDataMode = mode
  RT.SyncQuestDataControls()
  if mode == "export" then
    SetQuestDataText(RT.ExportQuestDataText("open"))
  elseif mode == "import" then
    SetQuestDataText("")
  end

  dataWindow:Show()
  if dataWindow.Raise then
    dataWindow:Raise()
  end
  dataEditBox:SetFocus()

  if mode == "export" then
    RT.SelectQuestDataText()
  end
end

RT.ShowQuestDataWindow = ShowQuestDataWindow
