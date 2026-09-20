local Core = AutoCallboardCore
local L = AutoCallboardLocale
local RT = AutoCallboardRuntime
local Log = RT.Log
local Print = RT.Print
local state = RT.state

RT.updateUrl = "https://github.com/Siphelis/autocallboard/releases/latest"

local ANNOUNCE_DELAY = 10
local SESSION_GAP = 600
local PARKED = 3600

local ownText
local own
local isRelease
local newSession
local announced
local notified
local startAt

local function UpdateState()
  if type(state.update) ~= "table" then
    state.update = { latest = "", sessionAt = 0 }
  end

  return state.update
end

function RT.GetAvailableUpdate()
  if not own then
    return nil
  end

  local latest = UpdateState().latest

  if Core.isNewerVersion(latest, ownText) then
    return latest, ownText
  end

  return nil
end

local function RefreshNotice()
  if RT.RefreshUpdateNotice then
    RT.RefreshUpdateNotice()
  end
end

local function Notify()
  local version, installed = RT.GetAvailableUpdate()

  if not version or notified == version then
    return false
  end

  notified = version
  Print(string.format(L.UPDATE_CHAT, version, installed) .. " " .. RT.updateUrl)
  RefreshNotice()

  return true
end

function RT.NoteHeardVersion(sender, text)
  if not own or not Core.isNewerVersion(text, ownText) then
    return false
  end

  local update = UpdateState()

  if update.latest == "" or Core.isNewerVersion(text, update.latest) then
    update.latest = text
    RT.TouchState()
    Log("update", "heard ", tostring(sender), " running ", text)
  end

  Notify()

  return true
end

function RT.ProcessVersionAnnounce(now)
  if announced or not newSession or not isRelease then
    return PARKED
  end

  if not startAt then
    startAt = now + ANNOUNCE_DELAY
  end

  if now < startAt then
    return 1
  end

  if not RT.SendShareChannel or not RT.SendShareChannel("V:" .. ownText) then
    return 1
  end

  announced = true
  Log("update", "announced ", ownText)

  return PARKED
end

function RT.ShowUpdateLink()
  local version, installed = RT.GetAvailableUpdate()

  if not version then
    return false
  end

  AutoCallboardSkin.Dialog({
    title = L.UPDATE_TITLE,
    body = string.format(L.UPDATE_BODY, version, installed),
    acceptText = L.BUTTON_OKAY,
    editBox = { default = RT.updateUrl, maxLetters = 0 },
  })

  return true
end

function RT.InitVersionWatch()
  ownText = RT.GetAddonVersion()
  own, isRelease = Core.parseVersion(ownText)

  if not own then
    return false
  end

  local update = UpdateState()

  if update.latest ~= "" and not Core.isNewerVersion(update.latest, ownText) then
    update.latest = ""
    RT.TouchState()
  end

  local stamp = type(time) == "function" and time() or 0
  newSession = stamp <= 0 or update.sessionAt <= 0 or stamp - update.sessionAt >= SESSION_GAP

  if newSession then
    if stamp > 0 then
      update.sessionAt = stamp
      RT.TouchState()
    end

    Notify()
  else
    notified = RT.GetAvailableUpdate()
  end

  RefreshNotice()

  return true
end
