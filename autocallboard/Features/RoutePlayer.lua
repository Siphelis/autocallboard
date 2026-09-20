local Core = AutoCallboardCore
local RT = AutoCallboardRuntime
local L = AutoCallboardLocale

local Log = RT.Log

local ACTION_INTERVAL = 0.35
local BLOCK_TIMEOUT = 12
local DIFFICULTY_GRACE = 3

local queue = {}
local queueAt
local blockDeadline
local consumed = {}
local cursor = 0
local runStart = 1
local pendingDifficulty
local pendingDifficultyUntil

local function Reset()
  queue = {}
  queueAt = nil
  blockDeadline = nil
  pendingDifficulty = nil
  pendingDifficultyUntil = nil
end

function RT.ResetRoutePlayback()
  Reset()
  consumed = {}
  cursor = 0
  runStart = 1
end

function RT.ClearRouteProgress()
  RT.ResetRoutePlayback()

  if RT.StoreRouteCursor then
    RT.StoreRouteCursor(0)
  end
end

function RT.RouteLiveSignature(source, title)
  title = title or RT.RouteWindowTitle(source)

  if title then
    return Core.routeSignature({ kind = "quest", title = title })
  end

  local guid = UnitGUID and UnitGUID("npc") or nil
  local npcId = RT.ExtractBoardObjectIdFromGuid(guid)

  local available, active = RT.ReadLiveGossipQuests()

  return Core.routeSignature({
    kind = "npc",
    npcId = npcId,
    available = available,
    active = active,
  }), npcId
end

function RT.PlayerFaction()
  if not UnitFactionGroup then
    return nil
  end

  return (UnitFactionGroup("player"))
end

local function SignatureMatches(stepSignature, signature)
  if stepSignature == signature then
    return true
  end

  return stepSignature == Core.ROUTE_WINDOW_SIGNATURE and string.sub(signature, 1, 6) == "quest:"
end

function RT.MatchRouteStep(route, signature)
  if type(route) ~= "table" or type(route.steps) ~= "table" or signature == "" then
    return nil
  end

  local fallback

  for index = 1, #(route.steps) do
    local step = route.steps[index]
    local stepSignature = Core.routeSignature(step)
    local taken = stepSignature == Core.ROUTE_WINDOW_SIGNATURE and RT.FindQuestLogIndexByID(step.questId)

    if SignatureMatches(stepSignature, signature) and not consumed[index] and not taken then
      if index > cursor then
        return index
      end

      if not fallback then
        fallback = index
      end
    end
  end

  return fallback
end

local function ApplyTier(tier)
  tier = Core.sanitizeDifficulty(tier)

  if not tier then
    return
  end

  if RT.GetCurrentDifficulty() == tier then
    return
  end

  if not RT.CanApplyDifficulty() then
    RT.Error(L.ROUTE_DIFFICULTY_REFUSED)
    return
  end

  RT.ApplyListDifficulty(tier, "route")
  pendingDifficulty = tier
  pendingDifficultyUntil = GetTime() + DIFFICULTY_GRACE
end

local function ApplyStepDifficulty(step)
  ApplyTier(step and step.difficulty)
end

RT.ApplyRouteTier = ApplyTier

local function CheckPendingDifficulty()
  if not pendingDifficulty then
    return
  end

  if RT.GetCurrentDifficulty() == pendingDifficulty then
    pendingDifficulty = nil
    pendingDifficultyUntil = nil
    return
  end

  if GetTime() > (pendingDifficultyUntil or 0) then
    RT.Error(L.ROUTE_DIFFICULTY_REFUSED)
    pendingDifficulty = nil
    pendingDifficultyUntil = nil
  end
end

local ACTION_CALLS = {
  gossip = { GossipFrame = "SelectGossipOption" },
  available = { GossipFrame = "SelectGossipAvailableQuest", QuestFrameGreetingPanel = "SelectAvailableQuest" },
  active = { GossipFrame = "SelectGossipActiveQuest", QuestFrameGreetingPanel = "SelectActiveQuest" },
  accept = { QuestFrameDetailPanel = "AcceptQuest" },
  complete = { QuestFrameProgressPanel = "CompleteQuest" },
  turnin = { QuestFrameRewardPanel = "GetQuestReward" },
}

local function ReadyCall(action)
  if action.kind == "confirm" then
    return StaticPopup_Visible and StaticPopup_Visible("QUEST_ACCEPT") and "ConfirmAcceptQuest" or nil
  end

  for frameName, call in pairs(ACTION_CALLS[action.kind] or {}) do
    if RT.FrameIsVisibleOrShown(_G[frameName]) then
      return call
    end
  end

  return nil
end

local function AlreadyDone(action)
  if action.kind ~= "accept" and action.kind ~= "confirm" then
    return false
  end

  return RT.RouteQuestIdByTitle(action.title) ~= nil
    or (action.questId ~= nil and RT.FindQuestLogIndexByID(action.questId) ~= nil)
end

local function RunAction(action, call)
  local argument = action.kind == "turnin" and (action.reward or 0) or action.index
  local ok = pcall(_G[call], argument)

  Log("route", "played ", tostring(action.kind), " ", tostring(argument), " ok=", tostring(ok))

  return ok
end

function RT.QueueRouteBlock(route, index)
  local step = route.steps[index]

  if not step or Core.routeSignature(step) == "" then
    return false
  end

  if #(step.actions) > 0 then
    Reset()
  end

  ApplyStepDifficulty(step)

  for i = 1, #(step.actions) do
    local queued = Core.copyRouteAction(step.actions[i])

    if queued then
      queued.step = index
      table.insert(queue, queued)
    end
  end

  local last = RT.QueueTravelRun(route, index + 1)

  consumed[index] = true
  cursor = math.max(cursor, index, last)
  RT.RememberRouteCursor()
  queueAt = GetTime()
  blockDeadline = GetTime() + BLOCK_TIMEOUT

  RT.PointRouteArrowAtNextStep(route, index)
  Log("route", "block ", tostring(index), " queued with ", tostring(#(queue)), " actions")
  RT.RefreshRoutePanel()

  return true
end

function RT.QueueTravelRun(route, from)
  local index = tonumber(from) or 1
  local last = index - 1

  while true do
    local step = route.steps[index]

    if not step or step.kind ~= "travel" then
      break
    end

    table.insert(queue, {
      kind = "travel",
      checkpoint = step.checkpoint,
      difficulty = step.difficulty,
      step = index,
    })

    consumed[index] = true
    last = index
    index = index + 1
  end

  if #(queue) > 0 then
    queueAt = queueAt or GetTime()
    blockDeadline = blockDeadline or (GetTime() + BLOCK_TIMEOUT)
  end

  return last
end

function RT.BeginRoutePlaybackRun(route, from)
  if type(route) ~= "table" or type(route.steps) ~= "table" then
    return
  end

  local start = math.max(1, math.floor(tonumber(from) or 1))

  RT.SetRouteCursor(start - 1, start)
  Reset()

  if runStart == 1 then
    ApplyTier(route.difficulty)
  end

  cursor = math.max(cursor, RT.QueueTravelRun(route, runStart))
  RT.RememberRouteCursor()
  RT.PointRouteArrowAtNextStep(route, cursor)
end

function RT.RouteCurrentBlock()
  local route = RT.IsPlayingRoute() and RT.GetActiveRoute()

  if not route then
    return nil
  end

  local index = queue[1] and queue[1].step or (cursor + 1)

  if index > #(route.steps) then
    return nil
  end

  return index
end

function RT.SkipRouteBlock()
  local current = RT.RouteCurrentBlock()

  if not current then
    return false
  end

  return RT.StartRoutePlayback("skip", nil, current + 1)
end

function RT.PointRouteArrowAtNextStep(route, index)
  if type(route) ~= "table" or type(route.steps) ~= "table" then
    return
  end

  for i = (tonumber(index) or 0) + 1, #(route.steps) do
    local step = route.steps[i]

    if step.kind ~= "travel" and not consumed[i] and step.map and step.map ~= "" and step.x and step.y then
      RT.SetRouteArrowTarget(step)
      return
    end
  end

  RT.ClearRouteArrowTarget()
end

function RT.PlayRouteQuestChange(change)
  local route = RT.GetActiveRoute()
  local index = route and RT.MatchRouteStep(route, Core.routeSignature(change))

  if index then
    RT.QueueRouteBlock(route, index)
  end
end

function RT.OnRouteDialogueOpened(source, title)
  if not RT.IsPlayingRoute() then
    return
  end

  if #(queue) > 0 then
    return
  end

  local route = RT.GetActiveRoute()

  if not route then
    return
  end

  local signature = RT.RouteLiveSignature(source, title)
  local index = RT.MatchRouteStep(route, signature)

  if not index then
    Log("route", "ignored, no block matches ", tostring(signature), " source=", tostring(source))
    return
  end

  RT.QueueRouteBlock(route, index)
end

function RT.ProcessRoutePlayback()
  if not RT.IsPlayingRoute() then
    return 1
  end

  CheckPendingDifficulty()

  if #(queue) == 0 then
    return 0.5
  end

  local now = GetTime()

  if blockDeadline and now > blockDeadline then
    Log("route", "block timed out with ", tostring(#(queue)), " actions left")
    RT.Error(L.ROUTE_BLOCK_TIMEOUT)
    Reset()
    RT.StopRoutePlayback("timeout")
    return 1
  end

  if queueAt and now < queueAt then
    return ACTION_INTERVAL
  end

  local action = queue[1]
  local call = action.kind == "travel" or ReadyCall(action)

  if not call and not AlreadyDone(action) then
    return ACTION_INTERVAL
  end

  table.remove(queue, 1)
  queueAt = now + ACTION_INTERVAL

  if action.kind == "travel" then
    ApplyTier(action.difficulty)
    RT.UseRouteCheckpoint(action.checkpoint)
  elseif call then
    RunAction(action, call)
  end

  if #(queue) == 0 then
    blockDeadline = nil
  else
    blockDeadline = now + BLOCK_TIMEOUT
  end

  if RT.RouteCurrentBlock() ~= action.step then
    RT.RefreshRoutePanel()
  end

  return ACTION_INTERVAL
end

function RT.UseRouteCheckpoint(checkpointId)
  checkpointId = tonumber(checkpointId)

  local service = ProjectEbonhold and ProjectEbonhold.CheckpointService

  if not checkpointId or not service or type(service.UseCheckpoint) ~= "function" then
    return false
  end

  local known, checkpoint = pcall(service.GetCheckpoints)

  if known and type(checkpoint) == "table" and Core.countUnlockedCheckpoints(checkpoint) > 0 then
    for i = 1, #(checkpoint) do
      if tonumber(checkpoint[i].id) == checkpointId and not Core.travelCheckpointUsable(checkpoint[i]) then
        RT.Error(string.format(L.ROUTE_CHECKPOINT_LOCKED, Core.routeCheckpointName(checkpointId)))
        RT.StopRoutePlayback("checkpoint")
        return false
      end
    end
  end

  local ok = pcall(service.UseCheckpoint, checkpointId)

  Log("route", "checkpoint ", tostring(checkpointId), " ok=", tostring(ok))

  return ok
end

function RT.RouteCursor()
  return cursor
end

function RT.SetRouteCursor(index, start)
  cursor = tonumber(index) or 0
  runStart = math.max(1, math.floor(tonumber(start) or 1))
  consumed = {}

  for skipped = 1, runStart - 1 do
    consumed[skipped] = true
  end
end

local function RememberCursor()
  if RT.StoreRouteCursor then
    RT.StoreRouteCursor(cursor, runStart)
  end
end

RT.RememberRouteCursor = RememberCursor
