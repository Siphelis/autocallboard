local ADDON_NAME = ...
local Core = AutoCallboardCore
local L = AutoCallboardLocale
local RT = AutoCallboardRuntime

local ADDON_TITLE = "AutoCallboard"
local ADDON_PREFIX = "|cffb58cffACB:|r "

RT.ADDON_TITLE = ADDON_TITLE

RT.localizedWidgets = RT.localizedWidgets or setmetatable({}, { __mode = "k" })

local registeredSpecialFrames = {}

local function Print(message)
  DEFAULT_CHAT_FRAME:AddMessage(ADDON_PREFIX .. message)
end

local function Localized(widget, key)
  if not widget or not widget.SetText then
    return widget
  end

  widget:SetText(L[key] or key)
  RT.localizedWidgets[widget] = key

  return widget
end

local function GetQuestTypeName(questType)
  questType = tonumber(questType) or 0
  return L.QUEST_TYPE_NAMES[questType] or L.QUEST_TYPE_OTHER
end

local function GetAddonVersion()
  if GetAddOnMetadata and ADDON_NAME then
    return GetAddOnMetadata(ADDON_NAME, "Version") or "unknown"
  end

  return "unknown"
end

local function NormalizeCopper(value)
  value = tonumber(value) or 0
  if value < 0 then
    value = 0
  end

  return math.floor(value)
end

local function FormatMoney(copper)
  copper = NormalizeCopper(copper)

  local gold = math.floor(copper / 10000)
  local silver = math.floor((copper % 10000) / 100)
  local coin = copper % 100
  local parts = {}

  if gold > 0 then
    table.insert(parts, tostring(gold) .. "g")
  end

  if silver > 0 or gold > 0 then
    table.insert(parts, tostring(silver) .. "s")
  end

  table.insert(parts, tostring(coin) .. "c")

  return table.concat(parts, " ")
end

local function SecondsRemaining(untilTime)
  if not untilTime then
    return 0
  end

  return math.max(0, untilTime - GetTime())
end

local function FormatSeconds(value)
  return tostring(math.floor(math.max(0, value or 0))) .. "s"
end

local function RegisterSpecialFrame(frameName)
  if type(frameName) ~= "string" or frameName == "" or registeredSpecialFrames[frameName] then
    return
  end

  if type(UISpecialFrames) ~= "table" then
    return
  end

  for i = 1, #(UISpecialFrames) do
    if UISpecialFrames[i] == frameName then
      registeredSpecialFrames[frameName] = true
      return
    end
  end

  table.insert(UISpecialFrames, frameName)
  registeredSpecialFrames[frameName] = true
end

local function ResolveFramePath(path)
  if type(path) ~= "string" or path == "" then
    return nil
  end

  local current

  for segment in string.gmatch(path, "[^%.]+") do
    if not current then
      current = _G[segment]
    else
      current = current[segment]
    end

    if not current then
      return nil
    end
  end

  return current
end

local function RunFrameScript(target, scriptName)
  if not target.GetScript then
    return false
  end

  local script = target:GetScript(scriptName)
  if not script then
    return false
  end

  script(target, "LeftButton")
  return true
end

local function CompactText(value)
  if value == nil then
    return "nil"
  end

  value = Core.stripColorCodes(tostring(value))
  value = value:gsub("|", "/")
  value = value:gsub("%s+", " ")

  if value:len() > 80 then
    return value:sub(1, 77) .. "..."
  end

  return value
end

local function FrameName(target)
  if not target then
    return "nil"
  end

  if target.GetName and target:GetName() then
    return target:GetName()
  end

  return tostring(target)
end

local function FrameType(target)
  if target and target.GetObjectType then
    return target:GetObjectType()
  end

  return type(target)
end

local function FrameText(target)
  local texts = {}

  if target and target.GetText then
    local value = target:GetText()
    if value and value ~= "" then
      table.insert(texts, CompactText(value))
    end
  end

  if target and target.GetRegions then
    local regions = { target:GetRegions() }
    for i = 1, #(regions) do
      local region = regions[i]
      if region and region.GetText then
        local value = region:GetText()
        if value and value ~= "" then
          table.insert(texts, CompactText(value))
        end
      end
    end
  end

  if #(texts) == 0 then
    return ""
  end

  return table.concat(texts, " | ")
end

local function FrameSummary(target)
  if not target then
    return "nil"
  end

  local parts = { FrameName(target), FrameType(target) }

  if target.GetID then
    table.insert(parts, "id=" .. tostring(target:GetID()))
  end

  if target.IsShown then
    table.insert(parts, "shown=" .. tostring(target:IsShown() and true or false))
  end

  if target.IsVisible then
    table.insert(parts, "visible=" .. tostring(target:IsVisible() and true or false))
  end

  if target.IsEnabled then
    table.insert(parts, "enabled=" .. tostring(target:IsEnabled() and true or false))
  end

  local text = FrameText(target)
  if text ~= "" then
    table.insert(parts, "text=\"" .. text .. "\"")
  end

  return table.concat(parts, " ")
end

function RT.SafeCall(fn, ...)
  if not fn then
    return nil
  end

  local ok, value = pcall(fn, ...)
  if ok then
    return value
  end

  return nil
end

function RT.Log(kind, ...)
  local sink = RT.AppendDebugLog
  if not sink then
    return
  end

  local count = select("#", ...)
  local message = count > 0 and tostring((select(1, ...))) or ""

  for i = 2, count do
    message = message .. tostring((select(i, ...)))
  end

  return sink(kind, message)
end

local Log = RT.Log

local silenceDepth = 0
local savedPlaySound, savedPlaySoundFile

local function MuteSound() end

local function BeginSilence()
  silenceDepth = silenceDepth + 1

  if silenceDepth > 1 then
    return
  end

  savedPlaySound = PlaySound
  savedPlaySoundFile = PlaySoundFile
  PlaySound = MuteSound
  PlaySoundFile = MuteSound
end

local function EndSilence()
  silenceDepth = silenceDepth - 1

  if silenceDepth > 0 then
    return
  end

  silenceDepth = 0
  PlaySound = savedPlaySound
  PlaySoundFile = savedPlaySoundFile
  savedPlaySound = nil
  savedPlaySoundFile = nil
end

function RT.Silent(fn, ...)
  if not fn then
    return nil
  end

  BeginSilence()
  local ok, first, second = pcall(fn, ...)
  EndSilence()

  if not ok then
    return nil
  end

  return first, second
end

local Silent = RT.Silent

local function ClickNamedFrame(frameName, label)
  local target = ResolveFramePath(frameName)

  if not target then
    Log("click", label, " missing ", frameName)
    Print(string.format(L.FRAME_NOT_FOUND, label, frameName))
    return false
  end

  if target.IsShown and not target:IsShown() then
    Log("click", label, " hidden ", FrameSummary(target))
    Print(string.format(L.FRAME_NOT_SHOWN, label, frameName))
    return false
  end

  Log("click", label, " ", FrameSummary(target))

  BeginSilence()
  local ok, clicked = pcall(function()
        if target.Click then
          target:Click()
          return true
        end

        if RunFrameScript(target, "OnClick") then
          return true
        end

        if RunFrameScript(target, "OnMouseDown") then
          RunFrameScript(target, "OnMouseUp")
          return true
        end

        if RunFrameScript(target, "OnMouseUp") then
          return true
        end

        return false
    end)
  EndSilence()

  if not ok then
    Log("click", label, " error ", frameName)
    Print(string.format(L.FRAME_CLICK_FAILED, label, frameName))
    return false
  end

  if not clicked then
    Log("click", label, " no script ", FrameSummary(target))
    Print(string.format(L.FRAME_NO_CLICK_SCRIPT, label, frameName))
    return false
  end

  return true
end

RT.ClickNamedFrame = ClickNamedFrame

function RT.SavePoint(frame, store)
  if not frame or type(store) ~= "table" then
    return
  end

  local point, _, relativePoint, x, y = frame:GetPoint(1)

  store.point = point or "CENTER"
  store.relativePoint = relativePoint or "CENTER"
  store.x = x or 0
  store.y = y or 0
end

function RT.RestorePoint(frame, store)
  if not frame or type(store) ~= "table" then
    return
  end

  frame:ClearAllPoints()
  frame:SetPoint(store.point or "CENTER", UIParent,
      store.relativePoint or "CENTER", store.x or 0, store.y or 0)
end

function RT.IsUnder(frame, x, y)
  if not frame or not frame:IsShown() then
    return false
  end

  local left, right = frame:GetLeft(), frame:GetRight()
  local top, bottom = frame:GetTop(), frame:GetBottom()

  return left and right and top and bottom
      and x >= left and x <= right and y >= bottom and y <= top
end

RT.Print = Print
RT.Localized = Localized
RT.GetQuestTypeName = GetQuestTypeName
RT.GetAddonVersion = GetAddonVersion
RT.NormalizeCopper = NormalizeCopper
RT.FormatMoney = FormatMoney
RT.SecondsRemaining = SecondsRemaining
RT.FormatSeconds = FormatSeconds
RT.RegisterSpecialFrame = RegisterSpecialFrame
RT.ResolveFramePath = ResolveFramePath
RT.CompactText = CompactText
RT.FrameName = FrameName
RT.FrameType = FrameType
RT.FrameSummary = FrameSummary
