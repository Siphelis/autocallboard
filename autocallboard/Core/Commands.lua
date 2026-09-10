local Core = AutoCallboardCore or {}
AutoCallboardCore = Core
local L = AutoCallboardLocale

local tonumber = tonumber
local tostring = tostring
local math = math

local trim = Core.trim or function(value)
  if type(value) ~= "string" then
    return ""
  end
  return (value:match("^%s*(.-)%s*$"))
end

local BOOLEAN_TRUE_WORDS = { on = true, ["true"] = true, yes = true }
local BOOLEAN_FALSE_WORDS = { off = true, ["false"] = true, no = true }

local function parseBoolean(rest, trueWord, falseWord)
  local lowered = rest:lower()

  if BOOLEAN_TRUE_WORDS[lowered] or (trueWord and lowered == trueWord) then
    return true
  end

  if BOOLEAN_FALSE_WORDS[lowered] or (falseWord and lowered == falseWord) then
    return false
  end

  return nil
end

local BOOLEAN_SETTING_COMMANDS = {
  accept = "autoAccept",
  autoacceptquests = "autoAcceptShared",
  autoacceptquest = "autoAcceptShared",
  shareaccept = "autoAcceptShared",
  sharedaccept = "autoAcceptShared",
  acceptshared = "autoAcceptShared",
  autoinstance = "autoCurrentInstanceQuest",
  currentinstance = "autoCurrentInstanceQuest",
  instancequest = "autoCurrentInstanceQuest",
  travel = "travelEnabled",
  tp = "travelEnabled",
  travelauto = "travelAuto",
  autotravel = "travelAuto",
  tpauto = "travelAuto",
  remote = "remoteRoll",
  remoteroll = "remoteRoll",
  offboard = "remoteRoll",
}

local BOOLEAN_SETTING_USAGE = {
  autoAccept = "USAGE_ACCEPT",
  autoAcceptShared = "USAGE_AUTOACCEPTQUESTS",
  autoCurrentInstanceQuest = "USAGE_AUTOINSTANCE",
  travelEnabled = "USAGE_TRAVEL",
  travelAuto = "USAGE_TRAVELAUTO",
  remoteRoll = "USAGE_REMOTE",
}

local SIMPLE_SLASH_KINDS = {
  help = "help", show = "show", hide = "hide", reset = "reset",
  quests = "quests", quest = "quests", roll = "roll", autoroll = "roll", stop = "stop",
  run = "run", call = "run", version = "version", v = "version",
  settings = "settings", options = "settings", tools = "tools",
}

local SIMPLE_SLASH_RESULTS = {
  export = { kind = "data", action = "export" },
  import = { kind = "data", action = "import" },
  etrace = { kind = "debug", action = "etrace" },
  eventtrace = { kind = "debug", action = "etrace" },
  inspect = { kind = "debug", action = "inspect" },
  dump = { kind = "debug", action = "dump" },
  cooldown = { kind = "debug", action = "cooldown" },
  cd = { kind = "debug", action = "cooldown" },
  log = { kind = "debug", action = "logs" },
  logs = { kind = "debug", action = "logs" },
  clearlogs = { kind = "debug", action = "clearlogs" },
}

function Core.parseSlash(input)
  local message = trim(input)

  if message == "" then
    return { kind = "version" }
  end

  local command, rest = message:match("^(%S+)%s*(.-)$")
  command = command and command:lower() or ""
  rest = trim(rest)

  local simpleKind = SIMPLE_SLASH_KINDS[command]
  if simpleKind then
    return { kind = simpleKind }
  end

  local simpleResult = SIMPLE_SLASH_RESULTS[command]
  if simpleResult then
    return { kind = simpleResult.kind, action = simpleResult.action }
  end

  if command == "minimap" then
    local shown = parseBoolean(rest, "show", "hide")

    if shown == nil then
      return { kind = "invalid", message = L.USAGE_MINIMAP }
    end

    return { kind = "minimap", shown = shown }
  end

  local booleanField = BOOLEAN_SETTING_COMMANDS[command]
  if booleanField then
    local value = parseBoolean(rest)

    if value == nil then
      return { kind = "invalid", message = L[BOOLEAN_SETTING_USAGE[booleanField]] }
    end

    return { kind = "set", field = booleanField, value = value }
  end

  if command == "name" then
    if rest == "" then
      return { kind = "invalid", message = L.USAGE_NAME }
    end

    return { kind = "set", field = "targetName", value = rest }
  end

  if command == "id" or command == "spellid" then
    local spellID = tonumber(rest)

    if not spellID then
      return { kind = "invalid", message = L.USAGE_ID }
    end

    return { kind = "set", field = "summonSpellID", value = spellID }
  end

  if command == "reroll" then
    if rest == "" then
      return { kind = "reroll" }
    end

    return { kind = "set", field = "rerollFrame", value = rest }
  end

  if command == "objective" or command == "obj" or command == "pick" then
    local index = tonumber(rest)

    if not index or index < 1 or index > 3 then
      return { kind = "invalid", message = L.USAGE_OBJECTIVE }
    end

    return { kind = "objective", index = index }
  end

  if command == "1" or command == "2" or command == "3" then
    return { kind = "objective", index = tonumber(command) }
  end

  if command == "buttonfield" then
    if rest == "" then
      return { kind = "invalid", message = L.USAGE_BUTTONFIELD }
    end

    return { kind = "set", field = "objectiveButtonField", value = rest }
  end

  if command == "maxrolls" then
    local value = tonumber(rest)

    if not value or value < 1 then
      return { kind = "invalid", message = L.USAGE_MAXROLLS }
    end

    return { kind = "set", field = "maxRerolls", value = math.floor(value) }
  end

  if command == "debug" then
    if rest == "" then
      return { kind = "debug", action = "open" }
    end

    local value = parseBoolean(rest)
    if value == nil then
      return { kind = "invalid", message = L.USAGE_DEBUG }
    end

    return { kind = "debug", action = "enabled", value = value }
  end

  if command == "watch" then
    local value = parseBoolean(rest)

    if value == nil then
      return { kind = "invalid", message = L.USAGE_WATCH }
    end

    return { kind = "debug", action = "mouseWatch", value = value }
  end

  if command == "sniff" or command == "sniffer" then
    local lowered = rest:lower()

    if rest == "" or lowered == "dump" then
      return { kind = "debug", action = "sniffDump" }
    end

    if lowered == "clear" then
      return { kind = "debug", action = "sniffClear" }
    end

    local value = parseBoolean(rest)
    if value == nil then
      return { kind = "invalid", message = L.USAGE_SNIFF }
    end

    return { kind = "debug", action = "sniffer", value = value }
  end

  return { kind = "unknown", message = L.CORE_UNKNOWN_COMMAND }
end
