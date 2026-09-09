local L = AutoCallboardLocale
local Skin = AutoCallboardSkin
local RT = AutoCallboardRuntime
local state = RT.state

function RT.RefreshLocalizedText()
  for widget, key in pairs(RT.localizedWidgets) do
    if widget.SetText then
      widget:SetText(L[key] or key)
    end
  end

  for i = 1, #(RT.questTypeFilterOptions) do
    local option = RT.questTypeFilterOptions[i]
    option.label = option.questType > 0 and L.QUEST_TYPE_NAMES[option.questType] or L.QUEST_TYPE_OTHER

    local checkbox = RT.knownQuestTypeButtons[i]
    if checkbox and checkbox._acbLabel then
      checkbox._acbLabel:SetText(option.label)
    end
  end

  if RT.RefreshEternalLabels then
    RT.RefreshEternalLabels()
  end

  RT.knownEntriesSignature = nil

  if RT.languageButton then
    RT.languageButton:SetText(RT.LanguageInitials(RT.GetLanguage()))
  end

  local controlFrame = RT.controlFrame
  if controlFrame and controlFrame.questButton then
    controlFrame.questButton:SetText(RT.IsQuestWindowShown() and L.BUTTON_HIDE or L.BUTTON_QUESTS)
  end

  RT.UpdateRollToggleButtons()
  RT.UpdateSummonStatus()

  if RT.SyncRollSpeedControl then
    RT.SyncRollSpeedControl()
  end

  RT.RefreshQuestWindow()

  if RT.listsWindow and RT.listsWindow:IsShown() then
    RT.RefreshListsWindow()
  end

  if RT.buildsWindow and RT.buildsWindow:IsShown() then
    RT.RefreshBuildsWindow()
  end

  RT.RefreshBindingNames()
  RT.UpdateEchoBarControls()

  if RT.IsHelpWindowShown() then
    RT.ShowAddonHelp()
  end

  RT.SyncQuestDataControls()
  if RT.RefreshSettingsLanguage then RT.RefreshSettingsLanguage() end
end

function RT.LanguageInitials(code)
  return string.upper(string.sub(tostring(code or "enUS"), 1, 2))
end

function RT.ApplyLanguage(code)
  if not RT.SetLanguage(code) then
    return false
  end

  if state then
    state.language = code
  end

  RT.RefreshLocalizedText()

  return true
end

function RT.ToggleLanguageMenu(anchor)
  if not RT.languageMenu then
    RT.languageMenu = Skin.Menu("AutoCallboardLanguageMenu")
    RT.languageMenu:CloseWhenHidden(RT.questWindow)
    RT.languageMenu:CloseWhenHidden(RT.controlFrame)
  end

  local menu = RT.languageMenu
  if menu:IsShown() then
    menu:Hide()
    return
  end

  local languages = RT.GetAvailableLanguages()
  local active = RT.GetLanguage()

  menu:Reset()
  for i = 1, #(languages) do
    local code = languages[i].code
    menu:AddItem(languages[i].name, {
      checked = code == active,
      onClick = function()
        RT.ApplyLanguage(code)
        end,
    })
  end

  menu:OpenAt(anchor or RT.languageButton, "BOTTOMRIGHT", "TOPRIGHT", 0, 4)
end
