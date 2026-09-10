local Core = AutoCallboardCore
local L = AutoCallboardLocale
local RT = AutoCallboardRuntime
local SecondsRemaining = RT.SecondsRemaining
local Silent = RT.Silent
local GetQuestTypeName = RT.GetQuestTypeName
local NormalizeCopper = RT.NormalizeCopper
local SyncGoldTracker = RT.SyncGoldTracker
local NormalizeQuestTitle = RT.NormalizeQuestTitle
local FindSelectedQuestInLog = RT.FindSelectedQuestInLog
local GetObjectivesService = RT.GetObjectivesService
local GetCurrentObjectives = RT.GetCurrentObjectives
local GetActiveObjective = RT.GetActiveObjective
local state = RT.state

local ROLL_EVAL_INTERVAL = 0.5
local QUEST_REFRESH_INTERVAL = 0.4
local SELECTED_QUEST_SCAN_FLOOR = 0.25

local rolling = false
local rollPausedReason
local rollPauseMessage
local rollCount = 0
local nextRollAt
local pendingReroll = false
local pendingRerollUntil
local lastObjectiveSignature
local lastCapturedSignature
local selectedQuest
local travelWarningKey
local nextSelectedQuestCheckAt
local lastSelectedQuestScanAt
local nextQuestRefreshAt

local SetRollPause
local ClearRollPause
local EvaluateCurrentObjectives
local ResumeRollingAfterCallboardActive
local StopRolling
local StartRolling

local Log = RT.Log

local function UpdateQuestWindow()
  if RT.UpdateQuestWindow then
    RT.UpdateQuestWindow()
  end
end

local function UpdateRollToggleButtons()
  if RT.UpdateRollToggleButtons then
    RT.UpdateRollToggleButtons()
  end
end

local signatureParts = {}
local signatureSource, signatureAt, signatureValue

local function ObjectiveSignature(objectives)
  if type(objectives) ~= "table" then
    return ""
  end

  local now = GetTime()
  if signatureSource == objectives and signatureAt == now then
    return signatureValue
  end

  local count = #(objectives)

  for i = 1, count do
    signatureParts[i] = Core.questKey(objectives[i]) or i
  end

  for i = #(signatureParts), count + 1, -1 do
    signatureParts[i] = nil
  end

  signatureSource = objectives
  signatureAt = now
  signatureValue = table.concat(signatureParts, "|")

  return signatureValue
end

local function CaptureCurrentObjectives()
  if not state then
    return {}
  end

  if not RT.CanReadObjectiveChoices() then
    lastCapturedSignature = nil
    return {}
  end

  local objectives = GetCurrentObjectives()
  local signature = ObjectiveSignature(objectives)

  if signature == lastCapturedSignature then
    return objectives
  end

  lastCapturedSignature = signature
  local previousCount = #(state.knownQuests or {})

  state.knownQuests = Core.captureKnownQuests(state.knownQuests, objectives, rollCount, true)
  RT.TouchState()

  local nextCount = #(state.knownQuests or {})
  if nextCount > previousCount then
    Log("quest-watch", "learned ", nextCount - previousCount, " quest(s); known=", nextCount, " signature=", signature)
  end

  return objectives
end

RT.CaptureCurrentObjectives = CaptureCurrentObjectives

local function CountDesiredQuests()
  return Core.desiredQuestCount(state and state.desiredQuests)
end

function RT.CanRollWithoutWantedQuest()
  return RT.learningQuestList == true
end

local function SetQuestStatus(message)
  if RT.questStatusText then
    RT.questStatusText:SetText(message)
  end

  Log("quest", message)
end

RT.SetQuestStatus = SetQuestStatus

function RT.ConfirmUntargetedRoll()
  SetQuestStatus(L.UNTARGETED_ROLL_CONFIRM_PROMPT)

  AutoCallboardSkin.Dialog({
    title = L.UNTARGETED_ROLL_CONFIRM_PROMPT,
    body = L.UNTARGETED_ROLL_CONFIRM_TEXT,
    acceptText = L.BUTTON_YES,
    cancelText = L.BUTTON_NO,
    onAccept = function()
      StartRolling(true)
      end,
    onCancel = function()
      SetQuestStatus(L.UNTARGETED_ROLL_CANCELED)
      end,
  })
end

function RT.ShowAutoCurrentInstanceWarning()
  AutoCallboardSkin.Dialog({
    title = L.AUTO_CURRENT_INSTANCE_LABEL,
    body = Core.autoCurrentInstanceWarningText(),
    acceptText = L.BUTTON_OKAY,
  })
end

local function RequireActiveCallboard(action)
  local access = RT.GetBoardAccessState(action)

  if access.ok then
    return true
  end

  local message = access.message or string.format(L.BOARD_ACCESS_FALLBACK, tostring(action))
  SetQuestStatus(message)
  Log("guard", "blocked ", action, " reason=", access.reason, " source=", access.source or "none")

  return false
end

SetRollPause = function(reason, message)
  if rollPausedReason == reason and rollPauseMessage == message then
    return
  end

  rollPausedReason = reason
  rollPauseMessage = message
  pendingReroll = false
  nextRollAt = nil
  RT.nextRollStatePollAt = nil
  pendingRerollUntil = nil

  if message then
    SetQuestStatus(message)
  end

  Log("roll", "paused reason=", reason)
end

RT.SetRollPause = function(...)
  return SetRollPause(...)
end

ClearRollPause = function(reason)
  if reason and rollPausedReason ~= reason then
    return
  end

  if rollPausedReason then
    Log("roll", "resumed from ", rollPausedReason)
  end

  rollPausedReason = nil
  rollPauseMessage = nil
end

RT.ClearRollPause = function(...)
  return ClearRollPause(...)
end

RT.SetManualBoardOpenRequired = function(source)
  RT.manualBoardOpenRequired = true
  RT.objectiveRequestPendingUntil = nil
  RT.nextObjectiveRequestAt = nil
  RT.ClearPendingInteract()
  RT.pendingInteractSource = nil
  SetRollPause("manual_board", L.PAUSED_CLICK_BOARD)
  Log("guard", "board required before rolling source=", source)
end

local function StartSelectedQuestPause(quest, index)
  if RT.LogRollNote then
    RT.LogRollNote("questSelected", quest and quest.questId, Core.questTitle(quest))
  end

  if not rolling or not quest then
    return
  end

  selectedQuest = {
    key = Core.questKey(quest),
    questId = tonumber(quest.questId or quest.id) or 0,
    title = Core.questTitle(quest),
    selectedAt = GetTime(),
    seenInLog = false,
    seenActiveObjective = false,
  }
  rollCount = 0
  nextSelectedQuestCheckAt = nil
  local selectedLabel = string.format(L.STATUS_PAUSED_SELECTED_QUEST, RT.QuestLabel(quest))
  if index then
    selectedLabel = selectedLabel .. string.format(L.STATUS_PAUSED_SELECTED_SLOT_SUFFIX, tostring(index))
  end
  SetRollPause("quest_selected", selectedLabel .. ".")
end

RT.StartSelectedQuestPause = function(quest, index)
  return StartSelectedQuestPause(quest, index)
end

RT.GetSelectedQuest = function()
  return selectedQuest
end

RT.ShouldHoldObjectiveChoices = function()
  return Core.shouldHoldObjectiveChoices(rolling, rollPausedReason, selectedQuest ~= nil)
end

local function IsSelectedQuestDone()
  if not selectedQuest then
    return false
  end

  local questID = tonumber(selectedQuest.questId) or 0
  local activeObjective = GetActiveObjective()
  local activeQuestID = tonumber(activeObjective and activeObjective.questId) or 0

  if activeObjective then
    if (questID > 0 and activeQuestID == questID) or (selectedQuest.title ~= "" and NormalizeQuestTitle(Core.questTitle(activeObjective)) == NormalizeQuestTitle(selectedQuest.title)) then
      selectedQuest.seenActiveObjective = true
      return false
    end

    if selectedQuest.seenActiveObjective then
      return true
    end
  elseif selectedQuest.seenActiveObjective then
    return true
  end

  if questID > 0 and IsQuestFlaggedCompleted and IsQuestFlaggedCompleted(questID) then
    return true
  end

  local found, complete = FindSelectedQuestInLog()
  if found then
    selectedQuest.seenInLog = true
    return complete
  end

  if selectedQuest.seenInLog then
    return true
  end

  return false
end

local function ResumeAfterSelectedQuest(source)
  local title = selectedQuest and selectedQuest.title or L.SELECTED_QUEST_FALLBACK

  if RT.LogRollNote then
    RT.LogRollNote("questGone", selectedQuest and selectedQuest.questId, title)
  end

  selectedQuest = nil
  nextSelectedQuestCheckAt = nil
  rollCount = 0
  ClearRollPause("quest_selected")
  nextRollAt = GetTime() + 0.2
  SetQuestStatus(string.format(L.QUEST_DONE_RESUMING, title))
  Log("quest", "quest done source=", source, " title=", title)
end

local function CheckSelectedQuestProgress(source)
  if not rolling or rollPausedReason ~= "quest_selected" or not selectedQuest then
    return
  end

  local now = GetTime()
  if nextSelectedQuestCheckAt and now < nextSelectedQuestCheckAt then
    return
  end

  nextSelectedQuestCheckAt = now + 1
  lastSelectedQuestScanAt = now

  if IsSelectedQuestDone() then
    ResumeAfterSelectedQuest(source)
  end
end

local function ToggleDesiredQuest(key)
  if type(key) ~= "string" or key == "" then
    return
  end

  local desired = state.desiredQuests
  if desired[key] then
    desired[key] = nil
  else
    desired[key] = true
  end

  local entry = RT.EnsureCharacterState()
  if entry and entry.desiredQuests ~= desired then
    entry.desiredQuests = desired
  end

  RT.TouchState()

  if not rolling then
    EvaluateCurrentObjectives()
  end

  RT.RefreshQuestWindow()
end

function RT.CloseObjectiveBoardAfterSelection(source)
  if GossipFrame then
    if GossipFrame.SetAlpha then
      GossipFrame:SetAlpha(1)
    end

    if GossipFrame.EnableMouse then
      GossipFrame:EnableMouse(true)
    end

    if GossipFrame.ClearAllPoints and GossipFrame.SetPoint then
      GossipFrame:ClearAllPoints()
      GossipFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -116)
    end
  end

  if GossipFrameCloseButton and GossipFrameCloseButton.Click then
    Silent(GossipFrameCloseButton.Click, GossipFrameCloseButton)
  elseif CloseGossip then
    Silent(CloseGossip)
  elseif GossipFrame and HideUIPanel then
    HideUIPanel(GossipFrame)
  end

  if ProjectEbonhold and ProjectEbonhold.ObjectivesUI and ProjectEbonhold.ObjectivesUI.HideObjectives then
    ProjectEbonhold.ObjectivesUI.HideObjectives()
  elseif _G.ObjectivesMainFrame and _G.ObjectivesMainFrame.Hide then
    _G.ObjectivesMainFrame:Hide()
  end

  Log("guard", "closed board after selection source=", source)
end

local function SelectObjectiveIndex(index)
  if not index then
    return false
  end

  if not RequireActiveCallboard(L.ACTION_SELECT_QUEST) then
    return false
  end

  local objective = GetCurrentObjectives()[index]
  local active = GetActiveObjective()

  if active then
    local activeID = tonumber(active.questId) or 0
    local wantedID = tonumber(objective and objective.questId) or 0

    if activeID ~= wantedID then
      Log("quest", "select skipped, objective already active id=", activeID)
      StartSelectedQuestPause(active)
      return false
    end
  end

  local boardWasOpen = RT.IsBoardSessionOpen()
  local selected

  if ProjectEbonhold and ProjectEbonhold.sendToServer and ProjectEbonhold.CS and ProjectEbonhold.CS.REQUEST_SELECT_OBJECTIVE then
    ProjectEbonhold.sendToServer(ProjectEbonhold.CS.REQUEST_SELECT_OBJECTIVE, tostring(index - 1))
    selected = true
  else
    selected = RT.ClickNamedFrame(state.objectivePrefix .. tostring(index) .. "." .. state.objectiveButtonField, string.format(L.OBJECTIVE_LABEL, index))
  end

  if selected then
    SetQuestStatus(string.format(L.OBJECTIVE_SELECTED_SLOT, index))
    StartSelectedQuestPause(objective, index)

    if boardWasOpen then
      RT.CloseObjectiveBoardAfterSelection("selected slot " .. tostring(index))
    end
  end

  return selected
end

StopRolling = function(message)
  if rolling and RT.LogRollNote then
    RT.LogRollNote("stop", nil, message)
  end

  rolling = false
  RT.rolling = false
  rollPausedReason = nil
  rollPauseMessage = nil

  if RT.listsWindow and RT.listsWindow:IsShown() then
    RT.RefreshListsWindow()
  end
  RT.manualBoardOpenRequired = false
  RT.objectiveBoardReadyUntil = nil
  RT.objectiveBoardAccessOpen = false
  RT.objectiveRequestPendingUntil = nil
  RT.nextObjectiveRequestAt = nil
  RT.objectiveRequestAttempts = 0
  pendingReroll = false
  nextRollAt = nil
  pendingRerollUntil = nil
  RT.trackedGoldAt = nil
  RT.trackedQuestSpend = 0
  selectedQuest = nil
  RT.learningQuestList = false
  nextSelectedQuestCheckAt = nil
  RT.blockedMatchKey = nil
  travelWarningKey = nil

  if message then
    SetQuestStatus(message)
  end

  UpdateRollToggleButtons()

  if UpdateQuestWindow then
    UpdateQuestWindow()
  end
end

local function HandleMatch(match)
  pendingReroll = false
  nextRollAt = nil
  pendingRerollUntil = nil

  local title = Core.questTitle(match.quest)
  local matchKey = tostring(match.index) .. ":" .. tostring(match.key)
  local matchLabel = match.label or L.MATCH_LABEL_WANTED

  if RT.CheckQuestTravelBeforeSelection then
    local allowed, reason, message = RT.CheckQuestTravelBeforeSelection(match.quest)
    if not allowed then
      SetRollPause("travel", message)
      nextRollAt = GetTime() + ROLL_EVAL_INTERVAL
      if reason == "unreachable" and travelWarningKey ~= matchKey then
        travelWarningKey = matchKey
        if UIErrorsFrame and UIErrorsFrame.AddMessage then
          UIErrorsFrame:AddMessage(message, 1, 0.1, 0.1, 1)
        end
      end
      UpdateQuestWindow()
      return
    end
    travelWarningKey = nil
  end

  if not RT.IsCallboardReadyForQuestActions() then
    SetRollPause("no_callboard", string.format(L.QUEST_FOUND_WAITING_CALLBOARD, matchLabel, title))
    nextRollAt = GetTime() + ROLL_EVAL_INTERVAL

    if RT.LogRoll then
      RT.LogRoll("blocked", match.index, GetCurrentObjectives())
    end

    if RT.blockedMatchKey ~= matchKey then
      RT.blockedMatchKey = matchKey
      Log("quest", "hard stop on wanted quest slot=", match.index, " key=", match.key, " title=", title)
      Log("quest", "matched wanted quest but callboard ui is not ready")
    end
  else
    if match.source == "currentInstance" and state and state.autoAccept then
      RT.ArmQuestAccept()
      Log("instance", "matched current instance slot=", match.index, " alias=", match.matchedAlias or "none", " title=", title)
    end

    if SelectObjectiveIndex(match.index) then
      RT.blockedMatchKey = nil
      Log("quest", "hard stop on ", match.source or "wanted", " quest slot=", match.index, " key=", match.key, " title=", title)
      SetQuestStatus(string.format(L.QUEST_FOUND_SELECTED, matchLabel, title, match.index))

      if RT.LogRoll then
        RT.LogRoll("select", match.index, GetCurrentObjectives())
      end
    else
      local shouldLogBlockedMatch = RT.blockedMatchKey ~= matchKey
      RT.blockedMatchKey = matchKey
      nextRollAt = GetTime() + ROLL_EVAL_INTERVAL

      if shouldLogBlockedMatch then
        Log("quest", "hard stop on ", match.source or "wanted", " quest slot=", match.index, " key=", match.key, " title=", title)
        Log("quest", matchLabel, " selection failed title=", title)
        SetQuestStatus(string.format(L.QUEST_FOUND_SELECT_FAILED, matchLabel, title, match.index))
      elseif RT.questStatusText then
        RT.questStatusText:SetText(string.format(L.QUEST_FOUND_SELECT_FAILED, matchLabel, title, match.index))
      end

      SetRollPause("no_callboard", string.format(L.QUEST_FOUND_WAITING_SELECTABLE, matchLabel, title))

      if RT.LogRoll then
        RT.LogRoll("selectFailed", match.index, GetCurrentObjectives())
      end
    end
  end

  if UpdateQuestWindow then
    UpdateQuestWindow()
  end
end

EvaluateCurrentObjectives = function()
  if not RT.HasCurrentObjectiveData() then
    Log("quest", "skipped objective evaluation because objective choices are not available")
    return false
  end

  local objectives = GetCurrentObjectives()
  local currentInstanceTarget = RT.RefreshCurrentInstanceQuestTarget("evaluate")
  local match = Core.findRollObjective(objectives, state.desiredQuests, currentInstanceTarget)

  if match then
    HandleMatch(match)
    return true
  end

  return false
end

RT.EvaluateCurrentObjectives = function()
  return EvaluateCurrentObjectives()
end

ResumeRollingAfterCallboardActive = function(source)
  if not rolling then
    return
  end

  if not RT.IsCallboardDataAvailable() then
    SetRollPause("no_callboard", L.PAUSED_WAITING_CALLBOARD_UI)
    Log("roll", "resume blocked until live quest data is available source=", source)
    return
  end

  if rollPausedReason == "quest_selected" then
    return
  end

  if rollPausedReason == "no_callboard" or rollPausedReason == "no_wanted" then
    ClearRollPause()
  end

  pendingReroll = false
  pendingRerollUntil = nil
  nextRollAt = GetTime() + 0.2
  lastObjectiveSignature = ObjectiveSignature(CaptureCurrentObjectives())
  SetQuestStatus(L.CALLBOARD_ACTIVE_RESUMING)
  Log("roll", "callboard active resume source=", source)

  EvaluateCurrentObjectives()
end

RT.ResumeRollingAfterCallboardActive = function(...)
  return ResumeRollingAfterCallboardActive(...)
end

function RT.RollDelay()
  return Core.clampRollDelay(state and state.rerollDelay)
end

function RT.RollTimeout()
  return Core.clampRollTimeout(state and state.rerollTimeout)
end

local function RequestObjectiveReroll()
  local service = GetObjectivesService()

  if service and service.RequestRerollObjectives then
    if service.CanAffordReroll and not service.CanAffordReroll() then
      return false
    end

    Silent(service.RequestRerollObjectives)
    return true
  end

  return RT.ClickNamedFrame(state.rerollFrame, "Reroll")
end

local function ConfirmRerollPopupIfVisible()
  if StaticPopup_Visible and not StaticPopup_Visible("EBONHOLD_CONFIRM_REROLL") then
    return false
  end

  for i = 1, 4 do
    local popup = _G["StaticPopup" .. tostring(i)]
    if popup and popup:IsShown() and popup.which == "EBONHOLD_CONFIRM_REROLL" then
      local confirmButton = _G["StaticPopup" .. tostring(i) .. "Button1"]
      if confirmButton and confirmButton.Click then
        Silent(confirmButton.Click, confirmButton)
        Log("reroll", "confirmed EBONHOLD_CONFIRM_REROLL via StaticPopup", i, "Button1")
        return true
      end
    end
  end

  return false
end

local function BypassRerollConfirm()
  local service = GetObjectivesService()

  if service and service.RequestRerollObjectives then
    if RequestObjectiveReroll() then
      Log("reroll", "requested reroll through ObjectivesService")
      ConfirmRerollPopupIfVisible()
      return true
    end

    return false
  end

  if RequestObjectiveReroll() then
    ConfirmRerollPopupIfVisible()
    return true
  end

  if RT.ClickNamedFrame(state.rerollFrame, "Reroll") then
    ConfirmRerollPopupIfVisible()
    return true
  end

  return false
end

local function ProcessRolling()
  if not rolling then
    return
  end

  local now = GetTime()
  if RT.nextRollStatePollAt and now < RT.nextRollStatePollAt then
    return
  end

  RT.nextRollStatePollAt = now + RT.rollStatePollInterval

  if rollPausedReason == "quest_selected" then
    CheckSelectedQuestProgress("poll")
    return
  end

  local activeObjective = GetActiveObjective()
  if activeObjective then
    StartSelectedQuestPause(activeObjective)
    return
  end

  if nextRollAt and now < nextRollAt then
    return
  end

  if pendingReroll then
    nextRollAt = now + RT.rollPendingPollInterval
  else
    nextRollAt = now + ROLL_EVAL_INTERVAL
  end

  local currentInstanceTarget = RT.RefreshCurrentInstanceQuestTarget("roll")
  if CountDesiredQuests() == 0 and not currentInstanceTarget and not RT.CanRollWithoutWantedQuest() then
    if state and state.autoCurrentInstanceQuest then
      SetRollPause("no_wanted", L.PAUSED_ENTER_INSTANCE_OR_PICK)
    else
      SetRollPause("no_wanted", L.PAUSED_PICK_QUEST)
    end
    return
  end

  if RT.objectiveRequestPendingUntil and GetTime() >= RT.objectiveRequestPendingUntil and not RT.HasCurrentObjectiveData() then
    RT.objectiveRequestPendingUntil = nil
  end

  if not RT.HasCurrentObjectiveData() then
    RT.RequestObjectiveBoardData("roll data refresh")
  end

  if rollPausedReason == "no_wanted" then
    ClearRollPause()
  end

  SyncGoldTracker()
  local objectives = GetCurrentObjectives()
  local signature = ObjectiveSignature(objectives)

  if pendingReroll then

    if signature == lastObjectiveSignature and now < pendingRerollUntil then
      return
    end

    pendingReroll = false
    lastObjectiveSignature = signature

    if EvaluateCurrentObjectives() then
      return
    end

    nextRollAt = now + RT.RollDelay()
    UpdateQuestWindow()
    return
  end

  if EvaluateCurrentObjectives() then
    return
  end

  local boardSessionOpen = RT.IsBoardSessionOpen()

  if not boardSessionOpen and not RT.IsRemoteRollEnabled() then
    if not rollPausedReason then
      SetRollPause("no_callboard", L.PAUSED_WAITING_CALLBOARD_UI)
    end

    nextRollAt = now + ROLL_EVAL_INTERVAL
    return
  end

  if not boardSessionOpen and not RT.HasCurrentObjectiveData() then
    if not rollPausedReason then
      SetRollPause("no_callboard", L.BOARD_ACCESS_DATA_MISSING)
    end

    nextRollAt = now + ROLL_EVAL_INTERVAL
    return
  end

  if rollCount >= state.maxRerolls then
    if RT.learningQuestList then
      StopRolling(string.format(L.ROLL_STOPPED_LEARNED, rollCount, #(state.knownQuests or {})))
    else
      StopRolling(string.format(L.ROLL_STOPPED_NOT_FOUND, rollCount))
    end
    return
  end

  lastObjectiveSignature = signature

  if BypassRerollConfirm() then
    rollCount = rollCount + 1
    pendingReroll = true
    pendingRerollUntil = now + RT.RollTimeout()
    nextRollAt = now + RT.rollPendingPollInterval
    SetQuestStatus(string.format(L.REROLL_REQUESTED, rollCount, state.maxRerolls))

    if RT.LogRoll then
      RT.LogRoll("reroll", rollCount, objectives)
    end
  else
    StopRolling(L.REROLL_FAILED_CHECK)
  end
end

local function RefreshQuestWindowIfNeeded(now)
  if not RT.IsQuestWindowShown() then
    return
  end

  now = now or GetTime()
  if nextQuestRefreshAt and now < nextQuestRefreshAt then
    return
  end

  nextQuestRefreshAt = now + QUEST_REFRESH_INTERVAL

  if not RT.CanReadObjectiveChoices() then
    return
  end

  local signature = ObjectiveSignature(GetCurrentObjectives())
  if signature ~= lastCapturedSignature then
    if not RT.ShouldHoldObjectiveChoices() then
      CaptureCurrentObjectives()
    end

    if rolling and not RT.ShouldHoldObjectiveChoices() and EvaluateCurrentObjectives() then
      return
    end

    UpdateQuestWindow()
  end
end

local function WatchCurrentObjectives()
  if not state or not GetObjectivesService() then
    return
  end

  if RT.ShouldHoldObjectiveChoices() then
    return
  end

  local beforeSignature = lastCapturedSignature
  local beforeCount = #(state.knownQuests or {})
  CaptureCurrentObjectives()
  local afterCount = #(state.knownQuests or {})

  if RT.IsQuestWindowShown()
      and (lastCapturedSignature ~= beforeSignature or afterCount ~= beforeCount) then
    UpdateQuestWindow()
  end
end

StartRolling = function(confirmedUntargeted)
  local desiredCount = CountDesiredQuests()
  local currentInstanceTarget = RT.RefreshCurrentInstanceQuestTarget("start")
  local autoCurrentInstanceEnabled = state and state.autoCurrentInstanceQuest

  if Core.needsUntargetedRollConfirm(state and state.desiredQuests)
      and not currentInstanceTarget
      and not autoCurrentInstanceEnabled
      and not confirmedUntargeted then
    RT.ConfirmUntargetedRoll()
    return
  end

  rollCount = 0
  RT.trackedQuestSpend = 0
  RT.trackedGoldAt = GetMoney and NormalizeCopper(GetMoney()) or nil
  selectedQuest = nil
  rollPausedReason = nil
  rollPauseMessage = nil
  local activeBoardSession = RT.IsCallboardUiPresent()
      or (RT.objectiveBoardAccessOpen
      and SecondsRemaining(RT.objectiveBoardReadyUntil) > 0)
  RT.manualBoardOpenRequired = false
  if not activeBoardSession then
    RT.objectiveBoardReadyUntil = nil
    RT.objectiveBoardAccessOpen = false
  end
  RT.objectiveRequestPendingUntil = nil
  RT.nextObjectiveRequestAt = nil
  RT.objectiveRequestAttempts = 0
  RT.ClearPendingInteract()
  RT.pendingInteractSource = nil
  nextSelectedQuestCheckAt = nil
  RT.nextRollStatePollAt = nil
  pendingReroll = false
  RT.blockedMatchKey = nil
  RT.learningQuestList = desiredCount == 0 and not autoCurrentInstanceEnabled
  rolling = true
  RT.rolling = true

  if RT.listsWindow and RT.listsWindow:IsShown() then
    RT.RefreshListsWindow()
  end

  nextRollAt = GetTime()
  lastObjectiveSignature = ObjectiveSignature(CaptureCurrentObjectives())

  local activeObjective = GetActiveObjective()
  if activeObjective then
    StartSelectedQuestPause(activeObjective)
    return
  end

  if not RT.HasCurrentObjectiveData() then
    RT.RequestObjectiveBoardData("start data refresh")
  end

  if autoCurrentInstanceEnabled and not currentInstanceTarget and desiredCount == 0 then
    SetRollPause("no_wanted", L.PAUSED_ENTER_INSTANCE_OR_PICK)
  elseif RT.learningQuestList then
    SetQuestStatus(L.ROLLING_TO_LEARN)
  elseif currentInstanceTarget and not EvaluateCurrentObjectives() then
    SetQuestStatus(string.format(L.ROLLING_CURRENT_INSTANCE, GetQuestTypeName(currentInstanceTarget.questType), tostring(currentInstanceTarget.name)))
  elseif not EvaluateCurrentObjectives() then
    SetQuestStatus(string.format(L.ROLLING_WANTED_QUESTS, desiredCount))
  end

  UpdateRollToggleButtons()
end

function RT.IsRolling()
  return rolling
end

function RT.GetRollPauseReason()
  return rollPausedReason
end

function RT.GetRollPauseMessage()
  return rollPauseMessage
end

function RT.GetRollCount()
  return rollCount
end

function RT.SetNextRollAt(value)
  nextRollAt = value
end

function RT.GetSelectedQuest()
  return selectedQuest
end

function RT.ResetSelectedQuestCheck()
  local soonest = (lastSelectedQuestScanAt or 0) + SELECTED_QUEST_SCAN_FLOOR

  if GetTime() >= soonest then
    nextSelectedQuestCheckAt = nil
  else
    nextSelectedQuestCheckAt = soonest
  end
end

RT.ObjectiveSignature = ObjectiveSignature
RT.CaptureCurrentObjectives = CaptureCurrentObjectives
RT.CountDesiredQuests = CountDesiredQuests
RT.SetQuestStatus = SetQuestStatus
RT.SetRollPause = SetRollPause
RT.ClearRollPause = ClearRollPause
RT.StartSelectedQuestPause = StartSelectedQuestPause
RT.EvaluateCurrentObjectives = EvaluateCurrentObjectives
RT.ResumeRollingAfterCallboardActive = ResumeRollingAfterCallboardActive
RT.ToggleDesiredQuest = ToggleDesiredQuest
RT.StopRolling = StopRolling
RT.StartRolling = StartRolling
RT.ProcessRolling = ProcessRolling
RT.RefreshQuestWindowIfNeeded = RefreshQuestWindowIfNeeded
RT.WatchCurrentObjectives = WatchCurrentObjectives
RT.CheckSelectedQuestProgress = CheckSelectedQuestProgress
RT.ResumeAfterSelectedQuest = ResumeAfterSelectedQuest
RT.RequireActiveCallboard = RequireActiveCallboard
RT.BypassRerollConfirm = BypassRerollConfirm
