local Core = AutoCallboardCore
local RT = AutoCallboardRuntime
local L = AutoCallboardLocale

local Log = RT.Log

RT.routeSharePrefix = "ACBR"
RT.routeShareChannel = "acbroutes"

local PREFIX = RT.routeSharePrefix
local CHANNEL = RT.routeShareChannel
local TEXT_TAG = "ACBR1:"
local CHUNK_BYTES = 200
local MAX_CHUNKS = 400
local STREAM_TIMEOUT = 30
local START_DELAY = 5
local CHANNEL_CHECK = 10
local HELLO_DELAY = 3
local REPLY_MIN, REPLY_MAX = 1, 5
local WHO_COOLDOWN = 30
local AVAILABILITY_TTL = 600
local FETCH_TIMEOUT = 30
local PURGE_DELAY = 60
local MAX_QUEUE = 500
local SEND_INTERVAL = 0.15
local HASHES_PER_MESSAGE = 15
local REQUEST_COOLDOWN = 10
local DIGEST_CHARS = 8

local share = {
  replies = {},
  queue = {},
  streams = {},
  availability = {},
  asked = {},
  fetching = {},
  recent = {},
  serial = 0,
}

RT.routeShare = share

local function MyName()
  return UnitName and UnitName("player") or ""
end

local function BaseName(name)
  if type(name) ~= "string" then
    return nil
  end

  name = string.match(name, "^([^%-]+)") or name

  return name ~= "" and name or nil
end

local function StripServerMarks(message)
  message = string.gsub(tostring(message or ""), "|c%x%x%x%x%x%x%x%x", "")
  message = string.gsub(message, "|r", "")

  return (string.gsub(message, "^%s*%[[^%]]*%]%s*", ""))
end

function RT.GetRouteLibrary()
  local state = RT.state

  if type(state.routeLibrary) ~= "table" then
    state.routeLibrary = {}
  end

  if type(state.routeLibrary.entries) ~= "table" then
    state.routeLibrary.entries = {}
  end

  return state.routeLibrary
end

function RT.ServerDay()
  if CalendarGetDate then
    local ok, _, month, day, year = pcall(CalendarGetDate)
    local number = ok and Core.dayNumber(year, month, day)

    if number then
      return number
    end
  end

  local now = date and date("*t")

  return now and Core.dayNumber(now.year, now.month, now.day) or 0
end

function RT.RouteShareDelay(low, high)
  return low + math.random() * (high - low)
end

local function RefreshLibrary()
  if RT.RefreshRouteLibrary then
    RT.RefreshRouteLibrary()
  end
end

local function HeldRoutes(category)
  local held = {}

  for _, route in ipairs(RT.GetAccountProfile().savedRoutes or {}) do
    if Core.isRouteShared(route) and (category == nil or route.category == category) then
      held[Core.routeHash(route)] = route
    end
  end

  return held
end

function RT.RefreshHeldLibraryEntries()
  local library, today = RT.GetRouteLibrary(), RT.ServerDay()
  local changed = false

  for hash, route in pairs(HeldRoutes()) do
    if Core.mergeLibraryEntry(library, hash, Core.libraryEntryFromRoute(route, today), today) then
      changed = true
    end
  end

  if changed then
    RT.TouchState()
    RefreshLibrary()
  end

  return changed
end

local function ChannelNameAt(index)
  if not GetChannelName or not index then
    return nil
  end

  local _, name = GetChannelName(index)

  return type(name) == "string" and string.lower(name) or nil
end

local function FindChannel()
  if not GetChannelList then
    return nil
  end

  local list = { GetChannelList() }

  for i = 1, #(list), 2 do
    local index, name = tonumber(list[i]), list[i + 1]

    if index and type(name) == "string" and string.lower(name) == CHANNEL then
      return index
    end
  end

  return nil
end

local function HideChannel()
  if not ChatFrame_RemoveChannel then
    return
  end

  for i = 1, (NUM_CHAT_WINDOWS or 10) do
    local frame = _G["ChatFrame" .. i]

    if frame then
      pcall(ChatFrame_RemoveChannel, frame, CHANNEL)
    end
  end
end

local function EnsureChannel(now)
  local index = FindChannel()

  if index then
    if share.channel ~= index then
      share.channel = index
      HideChannel()
    end

    return index
  end

  share.channel = nil

  if JoinChannelByName and (not share.joinedAt or now >= share.joinedAt + CHANNEL_CHECK) then
    share.joinedAt = now
    pcall(JoinChannelByName, CHANNEL)
  end

  return nil
end

local function SendChannel(text)
  local index = share.channel

  if not index or ChannelNameAt(index) ~= CHANNEL or not SendChatMessage then
    return false
  end

  return pcall(SendChatMessage, TEXT_TAG .. text, "CHANNEL", nil, index)
end

local function Whisper(target, payload)
  if not target or target == "" or #(share.queue) >= MAX_QUEUE then
    return false
  end

  share.queue[#(share.queue) + 1] = { target = target, payload = payload }

  return true
end

local function SplitUtf8(data)
  local chunks, start, length = {}, 1, #(data)

  while start <= length do
    local stop = math.min(start + CHUNK_BYTES - 1, length)

    while stop < length and stop > start do
      local nextByte = string.byte(data, stop + 1)

      if nextByte < 128 or nextByte > 191 then
        break
      end

      stop = stop - 1
    end

    chunks[#(chunks) + 1] = string.sub(data, start, stop)
    start = stop + 1
  end

  if #(chunks) == 0 then
    chunks[1] = ""
  end

  return chunks
end

local function SendStream(target, op, id, data)
  local chunks = SplitUtf8(data)

  if #(chunks) > MAX_CHUNKS or #(share.queue) + #(chunks) > MAX_QUEUE then
    return false
  end

  if not id then
    share.serial = share.serial % 1048575 + 1
    id = string.format("%x", share.serial)
  end

  for i = 1, #(chunks) do
    Whisper(target, op .. ":" .. id .. ":" .. i .. ":" .. #(chunks) .. ":" .. chunks[i])
  end

  return true
end

local function ReceiveStream(sender, op, id, index, total, data, now)
  index, total = tonumber(index), tonumber(total)

  if not index or not total or total < 1 or total > MAX_CHUNKS or index < 1 or index > total then
    return nil
  end

  local key = sender .. ":" .. op .. ":" .. id
  local stream = share.streams[key]

  if not stream or stream.total ~= total then
    stream = { total = total, got = 0, parts = {} }
    share.streams[key] = stream
  end

  stream.at = now

  local progressed = not stream.parts[index]

  if progressed then
    stream.parts[index] = data
    stream.got = stream.got + 1
  end

  if stream.got < total then
    return nil, progressed
  end

  share.streams[key] = nil

  return table.concat(stream.parts, "", 1, total), progressed
end

local function Throttled(sender, kind, now)
  local key = sender .. ":" .. kind
  local last = share.recent[key]

  if last and now - last < REQUEST_COOLDOWN then
    return true
  end

  share.recent[key] = now

  return false
end

local function SendHello(now)
  if not SendChannel("H:" .. table.concat(Core.libraryDigests(RT.GetRouteLibrary()), ",")) then
    return false
  end

  share.helloSent = true
  share.served = false
  share.purgeAt = now + PURGE_DELAY
  Log("share", "hello sent")

  return true
end

local function SendEntries(target, category, buckets)
  local parts = {}

  for _, item in ipairs(Core.libraryEntriesIn(RT.GetRouteLibrary(), category, buckets)) do
    parts[#(parts) + 1] = Core.serializeLibraryEntry(item.hash, item.entry)
  end

  if #(parts) > 0 then
    SendStream(target, "E", nil, table.concat(parts, ";"))
  end
end

local function OnHello(sender, payload, now)
  local theirs = {}

  for digest in string.gmatch(payload, "[^,]+") do
    theirs[#(theirs) + 1] = digest
  end

  if #(theirs) ~= Core.routeCategoryCount() then
    return
  end

  local mine = Core.libraryDigests(RT.GetRouteLibrary())
  local differing = {}

  for category = 1, #(mine) do
    if mine[category] ~= theirs[category] then
      differing[#(differing) + 1] = category
    end
  end

  if #(differing) == 0 then
    share.replies[sender] = nil
    return
  end

  share.replies[sender] = { at = now + RT.RouteShareDelay(REPLY_MIN, REPLY_MAX), categories = differing }
end

local function OnBuckets(sender, payload)
  local category, digests = string.match(payload, "^(%d+):(.+)$")
  category = tonumber(category)

  if not Core.isRouteCategory(category) or #(digests or "") ~= Core.ROUTE_LIBRARY_BUCKETS * DIGEST_CHARS then
    return
  end

  if share.helloSent and not share.served then
    share.served = true
    SendChannel("S")
  end

  local mine = Core.libraryBucketDigests(RT.GetRouteLibrary(), category)
  local wanted, list = {}, {}

  for bucket = 0, Core.ROUTE_LIBRARY_BUCKETS - 1 do
    local theirs = string.sub(digests, bucket * DIGEST_CHARS + 1, (bucket + 1) * DIGEST_CHARS)

    if theirs ~= mine[bucket + 1] then
      wanted[bucket] = true
      list[#(list) + 1] = string.format("%x", bucket)
    end
  end

  if #(list) == 0 then
    return
  end

  Whisper(sender, "R:" .. category .. ":" .. table.concat(list))
  SendEntries(sender, category, wanted)
end

local function OnRequest(sender, payload, now)
  local category, list = string.match(payload, "^(%d+):(%x+)$")
  category = tonumber(category)

  if not Core.isRouteCategory(category) or Throttled(sender, "R" .. category, now) then
    return
  end

  local buckets = {}

  for digit in string.gmatch(list, "%x") do
    buckets[tonumber(digit, 16)] = true
  end

  SendEntries(sender, category, buckets)
end

local function MergeEntries(texts)
  local items = {}

  for _, text in ipairs(texts) do
    local hash, entry = Core.parseLibraryEntry(text)

    if hash then
      items[#(items) + 1] = { hash = hash, entry = entry }
    end
  end

  local changed = Core.mergeLibraryEntries(RT.GetRouteLibrary(), items, RT.ServerDay())

  if changed > 0 then
    RT.TouchState()
    RefreshLibrary()
  end

  return changed
end

local function OnEntries(data)
  local texts = {}

  for text in string.gmatch(data, "[^;]+") do
    texts[#(texts) + 1] = text
  end

  MergeEntries(texts)
end

local function OnWho(sender, payload, now)
  local category = tonumber(payload)

  if not Core.isRouteCategory(category) or Throttled(sender, "W" .. category, now) then
    return
  end

  local hashes = {}

  for hash in pairs(HeldRoutes(category)) do
    hashes[#(hashes) + 1] = hash
  end

  table.sort(hashes)

  for i = 1, #(hashes), HASHES_PER_MESSAGE do
    Whisper(sender, "A:" .. category .. ":" .. table.concat(hashes, "", i, math.min(i + HASHES_PER_MESSAGE - 1, #(hashes))))
  end
end

local function OnAvailable(sender, payload, now)
  local list = string.match(payload, "^%d+:(.+)$") or ""

  for i = 1, #(list), Core.ROUTE_HASH_LENGTH do
    local hash = Core.sanitizeRouteHash(string.sub(list, i, i + Core.ROUTE_HASH_LENGTH - 1))

    if hash then
      share.availability[hash] = share.availability[hash] or {}
      share.availability[hash][sender] = now + AVAILABILITY_TTL
    end
  end

  RefreshLibrary()
end

function RT.RouteHolders(hash, now)
  now = now or GetTime()

  local holders = {}

  for name, expires in pairs(share.availability[hash] or {}) do
    if expires > now then
      holders[#(holders) + 1] = name
    end
  end

  table.sort(holders, function(a, b)
    return share.availability[hash][a] > share.availability[hash][b]
  end)

  return holders
end

function RT.IsRouteAvailable(hash)
  local now = GetTime()

  for _, expires in pairs(share.availability[hash] or {}) do
    if expires > now then
      return true
    end
  end

  return false
end

function RT.RequestRouteAvailability(category, force)
  local now = GetTime()

  if not Core.isRouteCategory(category) then
    return false
  end

  if not force and share.asked[category] and now - share.asked[category] < WHO_COOLDOWN then
    return false
  end

  if not SendChannel("W:" .. category) then
    return false
  end

  share.asked[category] = now

  local entries = RT.GetRouteLibrary().entries

  for hash in pairs(share.availability) do
    if entries[hash] and entries[hash].category == category then
      share.availability[hash] = nil
    end
  end

  RefreshLibrary()

  return true
end

local function EntryName(hash)
  local entry = RT.GetRouteLibrary().entries[hash]

  return entry and entry.name or tostring(hash)
end

function RT.FetchLibraryRoute(hash)
  hash = Core.sanitizeRouteHash(hash)

  if not hash then
    return false
  end

  if Core.findRouteByHash(RT.GetAccountProfile(), hash, RT.GetRouteLibrary().entries[hash]) then
    RT.Print(string.format(L.LIBRARY_ALREADY_OWNED, EntryName(hash)))
    return false
  end

  local fetch = share.fetching[hash]
  local first = fetch == nil

  fetch = fetch or { tried = {} }

  local holder

  for _, name in ipairs(RT.RouteHolders(hash)) do
    if not fetch.tried[name] then
      holder = name
      break
    end
  end

  if not holder then
    share.fetching[hash] = nil
    RT.Print(string.format(L.LIBRARY_FETCH_FAILED, EntryName(hash)))
    return false
  end

  fetch.tried[holder] = true
  fetch.holder = holder
  fetch.at = GetTime()
  share.fetching[hash] = fetch
  Whisper(holder, "G:" .. hash)

  if first then
    RT.Print(string.format(L.LIBRARY_FETCH_STARTED, EntryName(hash)))
  end

  return true
end

function RT.ImportLibraryRoute(code, hash)
  share.fetching[hash] = nil

  local route = Core.decodeRoute(code)
  local profile = RT.GetAccountProfile()

  if not route or Core.codeHash(code) ~= hash then
    RT.Print(string.format(L.LIBRARY_FETCH_FAILED, EntryName(hash)))
    return nil
  end

  if Core.findRouteByHash(profile, hash, { category = route.category, steps = #(route.steps) }) then
    RT.Print(string.format(L.LIBRARY_ALREADY_OWNED, route.name))
    return nil
  end

  local nextProfile, entry, err = Core.createRoute(profile, route.steps, route.name, route.category,
    { difficulty = route.difficulty, shared = true, sharedHash = hash })

  if err == "full" then
    RT.Print(string.format(L.ROUTE_MAX_REACHED, tostring(Core.MAX_SAVED_ROUTES)))
    return nil
  end

  if not entry then
    RT.Print(string.format(L.LIBRARY_FETCH_FAILED, route.name))
    return nil
  end

  RT.SaveAccountProfile(nextProfile)

  local saved = Core.findRoute(nextProfile, entry.id)
  local today = RT.ServerDay()

  Core.mergeLibraryEntry(RT.GetRouteLibrary(), hash, Core.libraryEntryFromRoute(saved, today), today)
  RT.TouchState()
  RT.Print(string.format(L.LIBRARY_FETCH_DONE, saved.name, Core.routeCategoryName(saved.category)))
  Log("share", "imported ", hash, " from the library")

  if RT.RefreshRouteWindow then
    RT.RefreshRouteWindow()
  end

  RefreshLibrary()

  return saved
end

local function OnGet(sender, payload, now)
  local hash = Core.sanitizeRouteHash(payload)

  if not hash or Throttled(sender, "G" .. hash, now) then
    return
  end

  local route = HeldRoutes()[hash]
  local code = route and Core.encodeRoute(route)

  if not (code and Core.codeHash(code) == hash and SendStream(sender, "C", hash, code)) then
    Whisper(sender, "X:" .. hash)
  end
end

local function OnCode(sender, hash, code)
  local fetch = share.fetching[hash]

  if not fetch or fetch.holder ~= sender then
    return
  end

  RT.ImportLibraryRoute(code, hash)
end

local function OnMissing(sender, payload)
  local hash = Core.sanitizeRouteHash(payload)

  if not hash then
    return
  end

  if share.availability[hash] then
    share.availability[hash][sender] = nil
  end

  local fetch = share.fetching[hash]

  if fetch and fetch.holder == sender then
    RT.FetchLibraryRoute(hash)
  end

  RefreshLibrary()
end

function RT.SyncSharedRoutes()
  local profile = RT.GetAccountProfile()
  local library, today
  local nextProfile, announced = profile, false

  for _, route in ipairs(profile.savedRoutes or {}) do
    if Core.routeNeedsAnnounce(route) then
      library, today = library or RT.GetRouteLibrary(), today or RT.ServerDay()

      local hash = Core.routeHash(route)
      local entry = Core.libraryEntryFromRoute(route, today)

      if Core.mergeLibraryEntry(library, hash, entry, today) then
        RefreshLibrary()
      end

      if SendChannel("N:" .. Core.serializeLibraryEntry(hash, entry)) then
        nextProfile = (Core.routeContainer.update(nextProfile, route.id, { sharedHash = hash }))
        announced = true
      end
    end
  end

  if announced then
    RT.SaveAccountProfile(nextProfile)
    RT.TouchState()
  end

  return announced
end

function RT.ShareRoute(id, shared)
  local nextProfile, ok = Core.setRouteShared(RT.GetAccountProfile(), id, shared)

  if not ok then
    return false
  end

  RT.SaveAccountProfile(nextProfile)

  if shared then
    RT.SyncSharedRoutes()
  end

  RT.TouchState()
  RefreshLibrary()

  if RT.RefreshRouteWindow then
    RT.RefreshRouteWindow()
  end

  return true
end

local offlineTemplate, offlinePattern

local function OfflinePlayer(message)
  local template = ERR_CHAT_PLAYER_NOT_FOUND_S

  if type(template) ~= "string" or type(message) ~= "string" or not string.find(template, "%s", 1, true) then
    return nil
  end

  if template ~= offlineTemplate then
    local escaped = string.gsub(template, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")

    offlineTemplate, offlinePattern = template, (string.gsub(escaped, "%%%%s", "(.+)"))
  end

  return string.match(message, offlinePattern)
end

function RT.HandleRouteShareSystem(message)
  local name = BaseName(OfflinePlayer(message))

  if not name then
    return false
  end

  for i = #(share.queue), 1, -1 do
    if share.queue[i].target == name then
      table.remove(share.queue, i)
    end
  end

  share.replies[name] = nil

  for hash, holders in pairs(share.availability) do
    holders[name] = nil

    local fetch = share.fetching[hash]

    if fetch and fetch.holder == name then
      RT.FetchLibraryRoute(hash)
    end
  end

  RefreshLibrary()

  return true
end

function RT.HandleRouteShareChannel(message, sender, channelString)
  if type(channelString) ~= "string" or not string.find(string.lower(channelString), CHANNEL, 1, true) then
    return false
  end

  sender = BaseName(sender)

  if not sender or sender == MyName() then
    return false
  end

  local body = string.match(StripServerMarks(message), TEXT_TAG .. "(.*)$")
  local op, rest = string.match(body or "", "^(%a):?(.*)$")
  local now = GetTime()

  if op == "H" then
    OnHello(sender, rest, now)
  elseif op == "S" then
    share.replies[sender] = nil
  elseif op == "N" then
    MergeEntries({ rest })
  elseif op == "W" then
    OnWho(sender, rest, now)
  else
    return false
  end

  return true
end

function RT.HandleRouteShareWhisper(message, distribution, sender)
  if distribution ~= "WHISPER" then
    return false
  end

  sender = BaseName(sender)

  if not sender or sender == MyName() then
    return false
  end

  local op, rest = string.match(StripServerMarks(message), "^(%a):(.*)$")
  local now = GetTime()

  if op == "B" then
    OnBuckets(sender, rest)
  elseif op == "R" then
    OnRequest(sender, rest, now)
  elseif op == "A" then
    OnAvailable(sender, rest, now)
  elseif op == "G" then
    OnGet(sender, rest, now)
  elseif op == "X" then
    OnMissing(sender, rest)
  elseif op == "E" or op == "C" then
    local id, index, total, data = string.match(rest or "", "^([^:]+):(%d+):(%d+):(.*)$")
    local whole, progressed

    if id then
      whole, progressed = ReceiveStream(sender, op, id, index, total, data, now)
    end

    local fetch = progressed and op == "C" and share.fetching[id]

    if fetch and fetch.holder == sender then
      fetch.at = now
    end

    if whole and op == "E" then
      OnEntries(whole)
    elseif whole then
      OnCode(sender, id, whole)
    end
  else
    return false
  end

  return true
end

local function Expire(now)
  for key, stream in pairs(share.streams) do
    if now - (stream.at or now) > STREAM_TIMEOUT then
      share.streams[key] = nil
    end
  end

  for key, at in pairs(share.recent) do
    if now - at > REQUEST_COOLDOWN then
      share.recent[key] = nil
    end
  end

  for hash, holders in pairs(share.availability) do
    for name, expires in pairs(holders) do
      if expires <= now then
        holders[name] = nil
      end
    end

    if next(holders) == nil then
      share.availability[hash] = nil
    end
  end

  for hash, fetch in pairs(share.fetching) do
    if now - fetch.at > FETCH_TIMEOUT then
      share.fetching[hash] = nil
      RT.Print(string.format(L.LIBRARY_FETCH_FAILED, EntryName(hash)))
    end
  end
end

function RT.ProcessRouteShare(now)
  now = now or GetTime()

  if not share.startAt then
    share.startAt = now + START_DELAY
    RT.RefreshHeldLibraryEntries()
  end

  if now < share.startAt then
    return 1
  end

  if not share.channel or not share.checkedAt or now >= share.checkedAt + CHANNEL_CHECK then
    share.checkedAt = now
    EnsureChannel(now)
  end

  RT.SyncSharedRoutes()

  if share.channel and not share.helloSent then
    share.helloAt = share.helloAt or now + HELLO_DELAY

    if now >= share.helloAt and SendHello(now) then
      share.helloAt = nil
    end
  end

  for sender, reply in pairs(share.replies) do
    if now >= reply.at then
      share.replies[sender] = nil

      for _, category in ipairs(reply.categories) do
        Whisper(sender, "B:" .. category .. ":" .. table.concat(Core.libraryBucketDigests(RT.GetRouteLibrary(), category)))
      end
    end
  end

  if share.purgeAt and now >= share.purgeAt then
    share.purgeAt = nil

    local held = {}

    for hash in pairs(HeldRoutes()) do
      held[hash] = true
    end

    if Core.purgeRouteLibrary(RT.GetRouteLibrary(), RT.ServerDay(), held) > 0 then
      RT.TouchState()
      RefreshLibrary()
    end
  end

  Expire(now)

  local item = table.remove(share.queue, 1)

  if item then
    if SendAddonMessage then
      pcall(SendAddonMessage, PREFIX, item.payload, "WHISPER", item.target)
    end

    return SEND_INTERVAL
  end

  return 1
end
