local ADDON_NAME = ...
local Core = AutoCallboardCore
local L = AutoCallboardLocale

local RT = AutoCallboardRuntime
local Print = RT.Print
local ResolveFramePath = RT.ResolveFramePath

local frame = CreateFrame("Frame")
RT.eventFrame = frame
local characterProfileKey
local state = RT.state

local Log = RT.Log

RT.controlCollapsedWidth = 424
RT.controlCollapsedHeight = 84
RT.controlExpandedWidth = 640
RT.controlExpandedHeight = 620
RT.questPanelAnimationSeconds = 0.35
RT.questSharePrefix = "AutoCallboard"
RT.questShareSignalTimeout = 5
RT.statusPollInterval = 0.25
RT.summonVerifyPollInterval = 0.1
RT.pendingCooldownPollInterval = 0.1
RT.rollStatePollInterval = 0.05

RT.rollPendingPollInterval = 0

local UpdateSummonStatus = RT.UpdateSummonStatus
local StartCallboardFlow = RT.StartCallboardFlow
local QueueCallboardFollowup = RT.QueueCallboardFollowup
local MarkCallboardSummoned = RT.MarkCallboardSummoned
local SetQuestStatus = RT.SetQuestStatus
local StopRolling = RT.StopRolling
local StartRolling = RT.StartRolling
local RequireActiveCallboard = RT.RequireActiveCallboard
local BypassRerollConfirm = RT.BypassRerollConfirm

function RT.GetSummonSpellName()
  if not state then
    return ""
  end

  if GetSpellInfo and state.summonSpellID then
    local ok, name = pcall(GetSpellInfo, state.summonSpellID)
    if ok and type(name) == "string" and name ~= "" then
      return name
    end
  end

  return state.summonSpell or ""
end

function RT.GetSummonMacroText()
  local spellName = RT.GetSummonSpellName()

  if spellName ~= "" then
    return "/cast " .. spellName
  end

  return nil
end

function RT.FlushQuestStateBackup()
  AutoCallboardQuestDB = nil
end

local function ApplyState(nextState)
  RT.PersistState(nextState)

  RT.RefreshQuestWindow()

  RT.PositionMinimapButton()

  RT.UpdateMinimapShownControl()
end

function RT.SaveQuestPanelExpanded(expanded)
  if not state or state.questPanelExpanded == expanded then
    return
  end

  state.questPanelExpanded = expanded and true or false
end

function RT.SaveControlFrameShown(shown)
  if not state or state.buttonShown == shown then
    return
  end

  state.buttonShown = shown and true or false
end

local function GetCharacterProfileKey()
  local playerName = UnitName and UnitName("player") or "Unknown"
  local realmName = GetRealmName and GetRealmName() or "UnknownRealm"

  if playerName == "" then
    playerName = "Unknown"
  end

  if realmName == "" then
    realmName = "UnknownRealm"
  end

  return realmName .. "/" .. playerName
end

local function SetUpCharacter()
  characterProfileKey = GetCharacterProfileKey()
  RT.characterProfileKey = characterProfileKey

  RT.RunAccountMigration(characterProfileKey)
  RT.ApplyCharacterState()
end

local function ClickReroll()
  if BypassRerollConfirm() then
    SetQuestStatus(L.REROLL_REQUESTED_SIMPLE)
  else
    SetQuestStatus(L.REROLL_FAILED_CHECK)
  end
end

local function ClickObjective(index)
  if not RequireActiveCallboard(L.ACTION_SELECT_QUEST) then
    return
  end

  local frameName = state.objectivePrefix .. tostring(index) .. "." .. state.objectiveButtonField

  if not ResolveFramePath(frameName) then
    frameName = state.objectivePrefix .. tostring(index)
  end

  RT.ClickNamedFrame(frameName, string.format(L.OBJECTIVE_LABEL, index))
end

local function CommitStateChange()
  RT.TouchState()
  RT.RefreshQuestWindow()
  RT.PositionMinimapButton()
  RT.UpdateMinimapShownControl()
end

function RT.SetField(field, value)
  state[field] = value
  CommitStateChange()

  if field == "targetName" then
    RT.SetCallboardButtonText(value)
  elseif field == "summonSpellID" then
    RT.ApplySummonButtonAttributes()
  elseif field == "travelEnabled" then
    if RT.OnTravelEnabledChanged then
      RT.OnTravelEnabledChanged()
    end
  elseif field == "travelAuto" then
    if RT.OnTravelAutoChanged then
      RT.OnTravelAutoChanged()
    end
  elseif field == "autoCurrentInstanceQuest" then
    RT.currentInstanceQuestSignature = nil

    RT.InvalidateInstanceTarget()
    RT.RefreshCurrentInstanceQuestTarget("setting")
  end
end

function RT.SetRollSpeed(delay, timeout, label)
  state.rerollDelay = Core.clampRollDelay(delay)
  state.rerollTimeout = Core.clampRollTimeout(timeout)
  CommitStateChange()

  local summary = string.format(L.ROLL_SPEED_FORMAT, tostring(RT.RollDelay()), tostring(RT.RollTimeout()))
  Log("roll", "speed ", label, " ", summary)
end

local function HandleSlash(input)
  local parsed = Core.parseSlash(input)

  if parsed.kind == "version" then
    Print(string.format(L.SLASH_VERSION, RT.GetAddonVersion()))
  elseif parsed.kind == "run" then
    if not RT.IsControlFrameShown() then
      RT.ShowControlFrame(true)
    end

    StartCallboardFlow()
  elseif parsed.kind == "settings" then
    RT.ShowSettings()
  elseif parsed.kind == "tools" then
    RT.ShowSettings()
  elseif parsed.kind == "help" then
    RT.ShowAddonHelp()
  elseif parsed.kind == "show" then
    RT.SaveControlFrameShown(true)
    RT.ShowControlFrame(true)
  elseif parsed.kind == "hide" then
    RT.SaveControlFrameShown(false)
    RT.ShowControlFrame(false)
  elseif parsed.kind == "minimap" then
    RT.SetMinimapShown(parsed.shown)
  elseif parsed.kind == "reset" then
    ApplyState(Core.resetSettingsPreservingQuestState(state))
    RT.ApplyCharacterState()
    RT.SetCallboardButtonText(state.targetName)
    RT.ApplySummonButtonAttributes()
    RT.PositionButton()
    RT.ShowControlFrame(true)
  elseif parsed.kind == "set" then
    RT.SetField(parsed.field, parsed.value)
  elseif parsed.kind == "reroll" then
    ClickReroll()
  elseif parsed.kind == "objective" then
    ClickObjective(parsed.index)
  elseif parsed.kind == "quests" then
    RT.ShowQuestWindow()
  elseif parsed.kind == "roll" then
    StartRolling()
  elseif parsed.kind == "stop" then
    StopRolling(L.ROLL_STOPPED)
  elseif parsed.kind == "debug" then
    if RT.HandleDebugAction then
      RT.HandleDebugAction(parsed.action, parsed.value)
    else
      Print(L.DEBUG_MODULE_MISSING)
    end
  elseif parsed.kind == "data" then
    RT.ShowQuestDataWindow(parsed.action)
  else
    Print(parsed.message)
  end
end

local nextTickAt
local ACTIVE_INTERVAL = 0.066
local IDLE_INTERVAL = 0.25

local RunPendingInteract = RT.RunPendingInteract
local UpdateQuestPanelAnimation = RT.UpdateQuestPanelAnimation
local UpdateListsAnimation = RT.UpdateListsAnimation
local ProcessRolling = RT.ProcessRolling
local RefreshQuestWindowIfNeeded = RT.RefreshQuestWindowIfNeeded
local ProcessPendingAcceptedQuestShare = RT.ProcessPendingAcceptedQuestShare
local SyncCallboardActiveFromCooldown = RT.SyncCallboardActiveFromCooldown
local CheckPendingSummonAttempt = RT.CheckPendingSummonAttempt
local SyncPendingSummonCooldown = RT.SyncPendingSummonCooldown
local IsSummonStatusBusy = RT.IsSummonStatusBusy

local indoorTask = { fn = RT.RefreshCallboardButtonEnabled, every = 2 }

local travelTask = {
  fn = function()
    if not RT.WatchTravelSuggestion then
      return 5
    end

    return RT.WatchTravelSuggestion()
  end,
  every = 1,
}

local eternalsTask = {
  fn = function()
    if not RT.WatchEternalSequence then
      return 5
    end

    return RT.WatchEternalSequence()
  end,
  every = 1,
}

local TASKS = {
  { fn = RT.WatchCurrentObjectives, every = 0.5 },
  { fn = RT.WatchDifficultyChange, every = 0.5 },
  { fn = RT.SyncOverlayFrameLevels, every = 0.5 },
  indoorTask,
  eternalsTask,
  travelTask,
}

local function WakeIndoorCheck()
  indoorTask.nextAt = nil
end

local function Busy()
  return RT.rolling
      or RT.questPanelAnimation
      or RT.listsAnimating
      or RT.pendingSummonVerifyUntil
      or RT.pendingCooldownSyncUntil
end

local function Awake()
  return RT.IsQuestWindowShown()
      or (RT.listsWindow and RT.listsWindow:IsShown())
      or IsSummonStatusBusy()
end

frame:SetScript("OnUpdate", function()
  local now = GetTime()

  if Busy() then
    nextTickAt = nil
  else
    if nextTickAt and now < nextTickAt then
      return
    end

    nextTickAt = now + (Awake() and ACTIVE_INTERVAL or IDLE_INTERVAL)
  end

  RunPendingInteract(now)
  UpdateQuestPanelAnimation()
  UpdateListsAnimation()
  ProcessRolling()
  RefreshQuestWindowIfNeeded()
  ProcessPendingAcceptedQuestShare("poll")
  SyncCallboardActiveFromCooldown("cooldown inference")
  CheckPendingSummonAttempt()
  SyncPendingSummonCooldown()

  for i = 1, #(TASKS) do
    local task = TASKS[i]

    if not task.nextAt or now >= task.nextAt then
      task.nextAt = now + (task.fn(now) or task.every)
    end
  end

  if IsSummonStatusBusy() then
    if not RT.nextStatusUpdateAt or now >= RT.nextStatusUpdateAt then
      RT.nextStatusUpdateAt = now + RT.statusPollInterval
      UpdateSummonStatus()
    end
    RT.summonStatusWasBusy = true
  elseif RT.summonStatusWasBusy then
    SyncCallboardActiveFromCooldown("status settle")
    RT.nextStatusUpdateAt = nil
    UpdateSummonStatus()
    RT.summonStatusWasBusy = IsSummonStatusBusy()
  end

  if RT.buildsRefreshAt and now >= RT.buildsRefreshAt then
    RT.buildsRefreshAt = nil
    RT.RequestBuildsRefresh("post-connexion")
  end

  if RT.DebugTick then
    RT.DebugTick(now)
  end
  end)

local EVENTS = {}

EVENTS.ADDON_LOADED = function(arg1)
  if arg1 ~= ADDON_NAME then
    return
  end

  frame:UnregisterEvent("ADDON_LOADED")
  EVENTS.ADDON_LOADED = nil

  ApplyState(Core.restoreQuestState(AutoCallboardDB, AutoCallboardQuestDB))

  if state.language ~= "" and RT.IsLanguageAvailable(state.language) then
    RT.SetLanguage(state.language)
  end

  RT.RepairKnownQuestState()
  RT.PersistState(Core.migrateLegacyPresets(state, AutoCallboardPresetsDB))
  SetUpCharacter()

  if RegisterAddonMessagePrefix then
    pcall(RegisterAddonMessagePrefix, RT.questSharePrefix)
  end
  RT.InstallSharedQuestAutoAcceptHook()
  RT.InitAppearance()
  RT.CreateCallboardButton()
  RT.CreateMinimapButton()
  RT.RefreshBindingNames()
  RT.ApplyEchoBar()
  RT.InitSettingsAccess()

  RT.buildsRefreshAt = GetTime() + RT.buildsRefreshDelay

  SLASH_AUTOCALLBOARD1 = "/acb"
  SLASH_AUTOCALLBOARD2 = "/autocallboard"
  SlashCmdList.AUTOCALLBOARD = HandleSlash

  Log("load", "AutoCallboard loaded")
end

EVENTS.PLAYER_REGEN_DISABLED = function()
  RT.RefreshEchoBar()
end

EVENTS.PLAYER_REGEN_ENABLED = EVENTS.PLAYER_REGEN_DISABLED

EVENTS.PLAYER_LOGOUT = function()
  RT.FlushQuestStateBackup()
end

EVENTS.CHAT_MSG_ADDON = function(arg1, arg2, arg3, arg4)
  if arg1 == RT.questSharePrefix then
    RT.RecordSharedQuestAnnouncement(arg2, arg3, arg4)
  elseif arg1 == RT.echoPrefix then
    RT.HandleEchoAddonMessage(arg2)
  end
end

EVENTS.GOSSIP_SHOW = function()
  local npcName = GossipFrameNpcNameText and GossipFrameNpcNameText:GetText()
  local npcBoard = RT.GetNpcBoardInfo and RT.GetNpcBoardInfo() or nil

  if RT.IsObjectiveBoardName(npcName) or npcBoard then
    RT.MarkObjectiveBoardOpened("GOSSIP_SHOW:" .. tostring(npcName)
        .. ":" .. tostring(npcBoard and npcBoard.objectId or "no-id"))
  end
end

EVENTS.GOSSIP_CLOSED = function()
  RT.MarkObjectiveBoardClosed("GOSSIP_CLOSED")
end

EVENTS.QUEST_DETAIL = function()
  local acceptUntil = RT.GetPendingAcceptUntil()

  if state and state.autoAccept and acceptUntil and GetTime() <= acceptUntil then
    RT.ClearPendingAcceptUntil()
    RT.AcceptCurrentQuestOffer("QUEST_DETAIL")
  else
    RT.TryAutoAcceptSharedQuest("QUEST_DETAIL")
  end
end

EVENTS.QUEST_ACCEPT_CONFIRM = function()
  RT.ConfirmSharedQuestAccept("QUEST_ACCEPT_CONFIRM")
end

local function CheckEternalQuest(source, force)
  if RT.CheckEternalQuestStillActive then
    RT.CheckEternalQuestStillActive(source, force)
  end
end

EVENTS.QUEST_TURNED_IN = function(arg1)
  local questID = tonumber(arg1) or 0
  local selected = RT.GetSelectedQuest()

  CheckEternalQuest("QUEST_TURNED_IN", true)

  if selected and questID > 0 and tonumber(selected.questId) == questID then
    RT.ResumeAfterSelectedQuest("QUEST_TURNED_IN")
  else
    RT.ResetSelectedQuestCheck()
    RT.CheckSelectedQuestProgress("QUEST_TURNED_IN")
  end
end

EVENTS.QUEST_REMOVED = function()
  CheckEternalQuest("QUEST_REMOVED", true)
end

EVENTS.QUEST_ACCEPTED = function(arg1, arg2)
  RT.TrackAcceptedQuest(arg1, arg2)
  RT.ResetSelectedQuestCheck()
  RT.CheckSelectedQuestProgress("QUEST_ACCEPTED")
end

EVENTS.QUEST_LOG_UPDATE = function()
  RT.ProcessPendingAcceptedQuestShare("QUEST_LOG_UPDATE")
  RT.ResetSelectedQuestCheck()
  RT.CheckSelectedQuestProgress("QUEST_LOG_UPDATE")
  CheckEternalQuest("QUEST_LOG_UPDATE")
end

EVENTS.QUEST_FINISHED = function()
  RT.ResetSelectedQuestCheck()
  RT.CheckSelectedQuestProgress("QUEST_FINISHED")
  CheckEternalQuest("QUEST_FINISHED")
end

EVENTS.UNIT_SPELLCAST_SUCCEEDED = function(arg1, arg2, arg3, arg4, arg5)
  if arg1 ~= "player" then
    return
  end

  local spellID = tonumber(arg5) or tonumber(arg4) or tonumber(arg3)
  local summonName = RT.GetSummonSpellName()

  if (summonName ~= "" and arg2 == summonName)
      or (state.summonSpellID and spellID == state.summonSpellID) then
    MarkCallboardSummoned("spellcast event")
    QueueCallboardFollowup("spellcast event")
  end
end

EVENTS.SPELL_UPDATE_COOLDOWN = function()
  if RT.StartCallboardTimersFromCooldown("SPELL_UPDATE_COOLDOWN") then
    UpdateSummonStatus()
  end
end

EVENTS.ZONE_CHANGED_NEW_AREA = function()
  RT.InvalidateInstanceTarget()
  WakeIndoorCheck()
end

EVENTS.PLAYER_ENTERING_WORLD = EVENTS.ZONE_CHANGED_NEW_AREA

EVENTS.ZONE_CHANGED = function()
  WakeIndoorCheck()
end

EVENTS.ZONE_CHANGED_INDOORS = EVENTS.ZONE_CHANGED

frame:SetScript("OnEvent", function(_, event, arg1, arg2, arg3, arg4, arg5)
  if RT.DebugEvent then
    RT.DebugEvent(event, arg1, arg2, arg3, arg4, arg5)
  end

  local handler = EVENTS[event]
  if handler then
    handler(arg1, arg2, arg3, arg4, arg5)
  end
  end)

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("QUEST_DETAIL")
frame:RegisterEvent("QUEST_ACCEPT_CONFIRM")
frame:RegisterEvent("QUEST_ACCEPTED")
frame:RegisterEvent("QUEST_LOG_UPDATE")
frame:RegisterEvent("QUEST_FINISHED")
frame:RegisterEvent("GOSSIP_SHOW")
frame:RegisterEvent("GOSSIP_CLOSED")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED")
pcall(frame.RegisterEvent, frame, "ZONE_CHANGED_INDOORS")
pcall(frame.RegisterEvent, frame, "QUEST_TURNED_IN")
pcall(frame.RegisterEvent, frame, "QUEST_REMOVED")
pcall(frame.RegisterEvent, frame, "UNIT_SPELLCAST_SUCCEEDED")
pcall(frame.RegisterEvent, frame, "SPELL_UPDATE_COOLDOWN")
