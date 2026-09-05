local Core = AutoCallboardCore
local L = AutoCallboardLocale
local RT = AutoCallboardRuntime
local state = RT.state

local Log = RT.Log

RT.difficultyPollInterval = 0.5
RT.difficultyIdlePollInterval = 2

function RT.GetHardmodeService()
  if ProjectEbonhold and ProjectEbonhold.HardmodeService then
    return ProjectEbonhold.HardmodeService
  end

  return nil
end

function RT.GetCurrentDifficulty()
  local service = RT.GetHardmodeService()

  if service and service.GetCurrentDifficulty then
    local ok, tier = pcall(service.GetCurrentDifficulty)
    if ok then
      local sanitized = Core.sanitizeDifficulty(tier)
      if sanitized then
        return sanitized
      end
    end
  end

  if ProjectEbonhold then
    return Core.sanitizeDifficulty(ProjectEbonhold.currentHardmodeTier)
  end

  return nil
end

function RT.CanApplyDifficulty()
  if UnitAffectingCombat and UnitAffectingCombat("player") then
    return false
  end

  local level = UnitLevel and tonumber(UnitLevel("player")) or 0
  if level <= 10 then
    return true
  end

  return (IsResting and IsResting()) and true or false
end

function RT.GetActiveSelectionDifficulty()
  if not state then
    return nil
  end

  local selection = Core.findSelection(RT.GetAccountProfile(), RT.GetActiveSelectionId())
  if not selection then
    return nil
  end

  return Core.sanitizeDifficulty(selection.difficulty)
end

function RT.ApplyListDifficulty(tier, source)
  tier = Core.sanitizeDifficulty(tier)

  if not tier then
    return
  end

  if RT.GetCurrentDifficulty() == tier then
    return
  end

  local service = RT.GetHardmodeService()
  if not service or not service.SetDifficulty then
    Log("difficulty", "service indisponible source=", source)
    return
  end

  service.SetDifficulty(tier)
  Log("difficulty", "difficulte demandee cible=", Core.difficultyLabel(tier), " source=", source)
end

function RT.WatchDifficultyChange()
  local listsWindow = RT.listsWindow
  local listsShown = listsWindow and listsWindow:IsShown()
  local watched = listsShown or RT.IsQuestWindowShown()
  local delay = watched and RT.difficultyPollInterval or RT.difficultyIdlePollInterval

  local current = RT.GetCurrentDifficulty()
  local difficultyChanged = current ~= RT.lastSeenDifficulty

  local canApplyChanged = false
  if listsShown then
    local canApply = RT.CanApplyDifficulty()
    if canApply ~= RT.lastCanApplyDifficulty then
      canApplyChanged = true
      RT.lastCanApplyDifficulty = canApply
    end
  end

  if not difficultyChanged and not canApplyChanged then
    return delay
  end

  if difficultyChanged then
    local previous = RT.lastSeenDifficulty
    RT.lastSeenDifficulty = current

    if previous ~= nil and current ~= nil then
      Log("difficulty", "changement observe ", Core.difficultyLabel(previous), " -> ", Core.difficultyLabel(current))
    end

    RT.RefreshQuestWindow()
  end

  if listsShown then
    RT.RefreshListsWindow()
  end

  return delay
end

function RT.FormatDifficultyStatus()
  local current = RT.GetCurrentDifficulty()

  if not current then
    return ""
  end

  local text = string.format(L.DIFFICULTY_STATUS_SUFFIX, Core.difficultyLabel(current))
  local wanted = RT.GetActiveSelectionDifficulty()

  if wanted and wanted ~= current then
    text = text .. string.format(L.DIFFICULTY_STATUS_WANTED_SUFFIX, Core.difficultyLabel(wanted))
  end

  return text
end

function RT.RequestSetSelectionDifficulty(entry, tier)
  if not entry or entry.id == nil then
    return
  end

  local nextProfile, ok = Core.setSelectionDifficulty(RT.GetAccountProfile(), entry.id, tier)
  if not ok then
    return
  end

  RT.SaveAccountProfile(nextProfile)
  RT.RefreshListsWindow()

  RT.RefreshQuestWindow()
end
