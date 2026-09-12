local Core = AutoCallboardCore
local L = AutoCallboardLocale
local RT = AutoCallboardRuntime
local Print = RT.Print
local SyncGoldTracker = RT.SyncGoldTracker
local FinalizeTrackedQuestSpend = RT.FinalizeTrackedQuestSpend
local state = RT.state

local ACCEPTED_QUEST_SHARE_TIMEOUT = 8
local ACCEPTED_QUEST_SHARE_RETRY_INTERVAL = 0.35

local Log = RT.Log

local function NormalizeQuestTitle(title)
  title = Core.stripColorCodes(tostring(title or ""):lower())
  title = title:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")

  return title
end

function RT.GetQuestLogEntryInfo(index)
  if not GetQuestLogTitle then
    return nil
  end

  local title, _, _, _, isHeader, _, isComplete, _, questID = GetQuestLogTitle(index)
  if not title then
    return nil
  end

  questID = tonumber(questID)
  if questID and questID <= 0 then
    questID = nil
  end

  return {
    title = title,
    isHeader = isHeader,
    isComplete = isComplete,
    questID = questID,
  }
end

local function GetQuestIdFromLogIndex(index)
  local entry = RT.GetQuestLogEntryInfo(index)
  if entry and tonumber(entry.questID) and tonumber(entry.questID) > 0 then
    return tonumber(entry.questID)
  end

  if GetQuestLogQuestID then
    local questID = GetQuestLogQuestID(index)
    if tonumber(questID) and tonumber(questID) > 0 then
      return tonumber(questID)
    end
  end

  if GetQuestLink then
    local link = GetQuestLink(index)
    local questID = link and link:match("quest:(%d+)")
    if questID then
      return tonumber(questID)
    end
  end

  return nil
end

local function FindSelectedQuestInLog()
  if not RT.GetSelectedQuest() or not GetNumQuestLogEntries or not GetQuestLogTitle then
    return false, false
  end

  local selectedID = tonumber(RT.GetSelectedQuest().questId) or 0
  local selectedTitle = NormalizeQuestTitle(RT.GetSelectedQuest().title)
  local entries = GetNumQuestLogEntries()

  for i = 1, entries do
    local entry = RT.GetQuestLogEntryInfo(i)

    if entry and not entry.isHeader then
      local questID = tonumber(entry.questID) or GetQuestIdFromLogIndex(i)
      local idMatches = selectedID > 0 and questID == selectedID
      local titleMatches = selectedTitle ~= "" and NormalizeQuestTitle(entry.title) == selectedTitle

      if idMatches or titleMatches then
        return true, entry.isComplete == true or entry.isComplete == 1
      end
    end
  end

  return false, false
end

function RT.FindQuestLogIndexByID(questID, preferredIndex)
  questID = tonumber(questID) or 0
  if questID <= 0 or not GetNumQuestLogEntries then
    return nil
  end

  if preferredIndex then
    local preferredEntry = RT.GetQuestLogEntryInfo(preferredIndex)
    if preferredEntry and not preferredEntry.isHeader and tonumber(preferredEntry.questID) == questID then
      return preferredIndex, preferredEntry
    end
  end

  for i = 1, GetNumQuestLogEntries() do
    local entry = RT.GetQuestLogEntryInfo(i)
    if entry and not entry.isHeader and tonumber(entry.questID) == questID then
      return i, entry
    end
  end

  return nil
end

function RT.QuestShareLabel(quest)
  if not quest then
    return L.QUEST_FALLBACK_LABEL
  end

  local questID = tonumber(quest.questID) or tonumber(quest.questId) or 0
  local title = tostring(quest.title or "")
  if title ~= "" and questID > 0 then
    return tostring(questID) .. " " .. title
  end

  if questID > 0 then
    return tostring(questID)
  end

  if title ~= "" then
    return title
  end

  return L.QUEST_FALLBACK_LABEL
end

function RT.GetQuestShareDistribution()
  if GetNumRaidMembers and (tonumber(GetNumRaidMembers()) or 0) > 0 then
    return "RAID"
  end

  if GetNumPartyMembers and (tonumber(GetNumPartyMembers()) or 0) > 0 then
    return "PARTY"
  end

  return nil
end

function RT.AnnounceSharedQuest(quest)
  if not SendAddonMessage then
    return false
  end

  local distribution = RT.GetQuestShareDistribution()
  local message = Core.buildSharedQuestAnnouncement(
      quest and (quest.questID or quest.questId),
      quest and quest.title
    )

  if not distribution or not message then
    return false
  end

  local ok = pcall(SendAddonMessage, RT.questSharePrefix, message, distribution)
  if not ok then
    Log("quest", "share announcement failed distribution=", distribution)
    return false
  end

  return true
end

function RT.ShareQuestLogIndex(index, quest, source)
  if not index or not SelectQuestLogEntry then
    Log("quest", "share blocked source=", source, " reason=missing SelectQuestLogEntry")
    return false, L.SHARE_LOG_UNAVAILABLE
  end

  if not QuestLogPushQuest then
    Log("quest", "share blocked source=", source, " reason=missing QuestLogPushQuest")
    return false, L.SHARE_PUSH_UNAVAILABLE
  end

  local previousIndex = GetQuestLogSelection and GetQuestLogSelection() or nil
  SelectQuestLogEntry(index)

  if GetQuestLogPushable and not GetQuestLogPushable() then
    if previousIndex then
      SelectQuestLogEntry(previousIndex)
    end

    Log("quest", "share skipped source=", source, " quest=", RT.QuestShareLabel(quest), " reason=not pushable")
    return false, string.format(L.SHARE_NOT_SHAREABLE, RT.QuestShareLabel(quest))
  end

  RT.AnnounceSharedQuest(quest)
  QuestLogPushQuest()

  if previousIndex then
    SelectQuestLogEntry(previousIndex)
  end

  Log("quest", "shared source=", source, " quest=", RT.QuestShareLabel(quest), " index=", index)
  return true
end

function RT.ShareAcceptedQuest(source, silent)
  if not RT.lastAcceptedQuest then
    if not silent then
      Print(L.SHARE_NO_ACCEPTED_QUEST)
    end
    Log("quest", "share skipped source=", source, " reason=no accepted quest")
    return false
  end

  local lastAcceptedQuest = RT.lastAcceptedQuest
  local index, entry = RT.FindQuestLogIndexByID(lastAcceptedQuest.questID, lastAcceptedQuest.questLogIndex)
  if entry and entry.title and entry.title ~= "" then
    lastAcceptedQuest.title = entry.title
  end

  if not index then
    if not silent then
      Print(string.format(L.SHARE_NOT_IN_LOG_YET, RT.QuestShareLabel(lastAcceptedQuest)))
    end
    Log("quest", "share pending source=", source, " quest=", RT.QuestShareLabel(lastAcceptedQuest))
    return false, "pending"
  end

  local shared, message = RT.ShareQuestLogIndex(index, {
      questID = lastAcceptedQuest.questID,
      title = lastAcceptedQuest.title,
    }, source)

  if shared then
    RT.SetQuestStatus(string.format(L.SHARE_ACCEPTED_QUEST, RT.QuestShareLabel(lastAcceptedQuest)))
  elseif message and not silent then
    Print(message)
  end

  return shared, message
end

function RT.ProcessPendingAcceptedQuestShare(source)
  local pendingAcceptedQuestShare = RT.pendingAcceptedQuestShare
  if not pendingAcceptedQuestShare then
    return
  end

  local now = GetTime()
  if pendingAcceptedQuestShare.nextAttemptAt and now < pendingAcceptedQuestShare.nextAttemptAt then
    return
  end

  if pendingAcceptedQuestShare.expiresAt and now > pendingAcceptedQuestShare.expiresAt then
    Log("quest", "share expired source=", source, " quest=", RT.QuestShareLabel(pendingAcceptedQuestShare))
    RT.pendingAcceptedQuestShare = nil
    return
  end

  pendingAcceptedQuestShare.nextAttemptAt = now + ACCEPTED_QUEST_SHARE_RETRY_INTERVAL
  local shared, message = RT.ShareAcceptedQuest(source, true)

  if shared or message ~= "pending" then
    RT.pendingAcceptedQuestShare = nil
  end
end

function RT.TrackAcceptedQuest(arg1, arg2)
  SyncGoldTracker()
  local first = tonumber(arg1)
  local second = tonumber(arg2)
  local questLogIndex = second and first or nil
  local questID = second
  local entry

  if questLogIndex then
    entry = RT.GetQuestLogEntryInfo(questLogIndex)
  elseif first then
    local possibleEntry = RT.GetQuestLogEntryInfo(first)
    if possibleEntry and tonumber(possibleEntry.questID) and tonumber(possibleEntry.questID) ~= first then
      questLogIndex = first
      questID = tonumber(possibleEntry.questID)
      entry = possibleEntry
    else
      questID = first
    end
  end

  if (not questID or questID <= 0) and entry and tonumber(entry.questID) then
    questID = tonumber(entry.questID)
  end

  if not questID or questID <= 0 then
    Log("quest", "accepted quest id unavailable arg1=", arg1, " arg2=", arg2)
    return
  end

  if RT.LogRollNote then
    RT.LogRollNote("questAccepted", questID, nil)
  end

  RT.lastAcceptedQuest = {
    questID = questID,
    questLogIndex = questLogIndex,
    title = entry and entry.title or "",
    acceptedAt = GetTime(),
  }

  if RT.NoteQuestAccepted then
    RT.NoteQuestAccepted(questID, RT.lastAcceptedQuest.title)
  end
  RT.pendingAcceptedQuestShare = {
    questID = questID,
    title = RT.lastAcceptedQuest.title,
    questLogIndex = questLogIndex,
    expiresAt = GetTime() + ACCEPTED_QUEST_SHARE_TIMEOUT,
    nextAttemptAt = nil,
  }

  if Core.shouldPauseForAcceptedQuest(RT.IsRolling(), questID) then
    local selectedID = tonumber(RT.GetSelectedQuest() and RT.GetSelectedQuest().questId) or 0
    if selectedID ~= questID then
      RT.StartSelectedQuestPause({
          questId = questID,
          title = RT.lastAcceptedQuest.title,
        })
    end
  end

  local spent = FinalizeTrackedQuestSpend()
  RT.trackedGoldAt = nil
  Log("quest", "accepted ", RT.QuestShareLabel(RT.lastAcceptedQuest), " index=", questLogIndex or "unknown", " spent=", spent)
  if RT.UpdateShareButtonState then
    RT.UpdateShareButtonState()
  end
  RT.ProcessPendingAcceptedQuestShare("QUEST_ACCEPTED")

  if RT.HandleEternalQuest then
    RT.HandleEternalQuest()
  end
end

function RT.RefreshLastAcceptedQuest()
  local accepted = RT.lastAcceptedQuest
  if not accepted or accepted.title ~= "" or not RT.FindQuestLogIndexByID then
    return
  end

  local index, entry = RT.FindQuestLogIndexByID(accepted.questID, accepted.questLogIndex)
  if not entry then
    return
  end

  accepted.questLogIndex = index
  accepted.title = entry.title or ""
  if RT.NoteQuestAccepted then
    RT.NoteQuestAccepted(accepted.questID, accepted.title)
  end
end

function RT.GetQuestOfferTitle()
  if GetTitleText then
    local ok, value = pcall(GetTitleText)
    if ok and type(value) == "string" and value ~= "" then
      return value
    end
  end

  if QuestTitleText and QuestTitleText.GetText then
    return QuestTitleText:GetText() or ""
  end

  return ""
end

function RT.GetQuestOfferSourceName()
  if QuestFrameNpcNameText and QuestFrameNpcNameText.GetText then
    return QuestFrameNpcNameText:GetText()
  end

  return nil
end


function RT.SafeUnitCheck(checker, unit)
  if not unit or unit == "" then
    return false
  end

  return RT.SafeCall(checker, unit) or false
end

function RT.IsQuestOfferFromGroupPlayer()
  local sourceName = RT.GetQuestOfferSourceName()
  if not sourceName or sourceName == "" then
    return false, sourceName
  end

  local isPlayer = RT.SafeUnitCheck(UnitIsPlayer, "questnpc")
      or RT.SafeUnitCheck(UnitIsPlayer, sourceName)
  local inGroup = RT.SafeUnitCheck(UnitInParty, "questnpc")
      or RT.SafeUnitCheck(UnitInRaid, "questnpc")
      or RT.SafeUnitCheck(UnitInParty, sourceName)
      or RT.SafeUnitCheck(UnitInRaid, sourceName)

  return isPlayer and inGroup, sourceName
end

function RT.RecordSharedQuestAnnouncement(message, distribution, sender)
  if not state
      or not state.autoAcceptShared
      or (distribution ~= "PARTY" and distribution ~= "RAID")
      or Core.normalizeSharedQuestPlayerName(sender) == "" then
    return false
  end

  local questID, title = Core.parseSharedQuestAnnouncement(message)
  if not questID then
    return false
  end

  local now = GetTime()
  local pending = Core.consumeSharedQuestOffer(
      RT.pendingSharedQuestOffers,
      "",
      "",
      now
    )
  while #(pending) >= 10 do
    table.remove(pending, 1)
  end
  table.insert(pending, {
      questID = questID,
      title = title,
      sender = sender,
      expiresAt = now + RT.questShareSignalTimeout,
    })
  RT.pendingSharedQuestOffers = pending
  Log("quest", "received ACB share quest=", questID, " sender=", sender)

  if QuestFrame and QuestFrame.IsShown and QuestFrame:IsShown() then
    RT.TryAutoAcceptSharedQuest("CHAT_MSG_ADDON")
  end

  return true
end

function RT.AcceptCurrentQuestOffer(source)
  if AcceptQuest then
    AcceptQuest()
  elseif QuestFrameAcceptButton then
    QuestFrameAcceptButton:Click()
  else
    Log("quest", "auto accept blocked source=", source, " reason=no accept API")
    return false
  end

  return true
end

function RT.TryAutoAcceptSharedQuest(source)
  if not state or not state.autoAcceptShared then
    return false
  end

  local now = GetTime()
  if RT.lastSharedAutoAcceptAt and now - RT.lastSharedAutoAcceptAt < 0.5 then
    return false
  end

  local fromGroupPlayer, sourceName = RT.IsQuestOfferFromGroupPlayer()
  if not fromGroupPlayer then
    Log("quest", "shared auto accept skipped source=", source, " giver=", sourceName or "none")
    return false
  end

  local title = RT.GetQuestOfferTitle()
  local remaining, matched = Core.consumeSharedQuestOffer(
      RT.pendingSharedQuestOffers,
      title,
      sourceName,
      now
    )
  RT.pendingSharedQuestOffers = remaining

  if not matched then
    Log("quest", "shared auto accept skipped source=", source, " reason=no ACB share giver=", sourceName or "none", " title=", title)
    return false
  end

  RT.pendingSharedQuestConfirmUntil = now + RT.questShareSignalTimeout
  if RT.AcceptCurrentQuestOffer(source) then
    RT.lastSharedAutoAcceptAt = now
    Log("quest", "accepted shared quest source=", source, " giver=", sourceName or "unknown", " title=", title)
    return true
  end

  RT.pendingSharedQuestConfirmUntil = nil
  return false
end

function RT.InstallSharedQuestAutoAcceptHook()
  if RT.sharedQuestAutoAcceptHooked or not QuestFrame then
    return
  end

  RT.sharedQuestAutoAcceptHooked = true

  if QuestFrame.HookScript then
    QuestFrame:HookScript("OnShow", function()
      RT.TryAutoAcceptSharedQuest("QuestFrame OnShow")
      end)
    return
  end

  if QuestFrame.GetScript and QuestFrame.SetScript then
    local previousOnShow = QuestFrame:GetScript("OnShow")
    QuestFrame:SetScript("OnShow", function(self, ...)
      if previousOnShow then
        previousOnShow(self, ...)
      end

      RT.TryAutoAcceptSharedQuest("QuestFrame OnShow")
      end)
  end
end

function RT.ConfirmSharedQuestAccept(source)
  local now = GetTime()
  if not state
      or not state.autoAcceptShared
      or not RT.pendingSharedQuestConfirmUntil
      or now > RT.pendingSharedQuestConfirmUntil then
    return false
  end

  RT.pendingSharedQuestConfirmUntil = nil

  if StaticPopup_Visible and StaticPopup_Visible("QUEST_ACCEPT") and StaticPopup_Hide then
    StaticPopup_Hide("QUEST_ACCEPT")
  end

  if ConfirmAcceptQuest then
    ConfirmAcceptQuest()
    Log("quest", "confirmed shared quest source=", source)
    return true
  end

  return false
end

RT.NormalizeQuestTitle = NormalizeQuestTitle
RT.FindSelectedQuestInLog = FindSelectedQuestInLog
