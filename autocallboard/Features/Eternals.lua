local Core = AutoCallboardCore
local L = AutoCallboardLocale
local RT = AutoCallboardRuntime
local Print = RT.Print

local BUTTON_NAME = "AutoCallboardEternalButton"
local DEFAULT_BINDING = "CTRL-W"

local ETERNAL_MAP = {
  {
    keyword = "eternal water", label = L.ETERNAL_LABEL_WATER, itemName = L.ETERNAL_ITEM_WATER,
    crystalItem = 37705, eternalItem = 35622,
    toEternalSpell = 49245, toCrystalSpell = 56040,
  },
  {
    keyword = "eternal fire", label = L.ETERNAL_LABEL_FIRE, itemName = L.ETERNAL_ITEM_FIRE,
    crystalItem = 37702, eternalItem = 36860,
    toEternalSpell = 49244, toCrystalSpell = 56042,
  },
  {
    keyword = "eternal earth", label = L.ETERNAL_LABEL_EARTH, itemName = L.ETERNAL_ITEM_EARTH,
    crystalItem = 37701, eternalItem = 35624,
    toEternalSpell = 49248, toCrystalSpell = 56041,
  },
  {
    keyword = "eternal air", label = L.ETERNAL_LABEL_AIR, itemName = L.ETERNAL_ITEM_AIR,
    crystalItem = 37700, eternalItem = 35623,
    toEternalSpell = 49234, toCrystalSpell = 56045,
  },
  {
    keyword = "eternal shadow", label = L.ETERNAL_LABEL_SHADOW, itemName = L.ETERNAL_ITEM_SHADOW,
    crystalItem = 37703, eternalItem = 35627,
    toEternalSpell = 49246, toCrystalSpell = 56044,
  },
}

local SPELL_LOOKUP = {}
for i = 1, #(ETERNAL_MAP) do
  local entry = ETERNAL_MAP[i]
  SPELL_LOOKUP[entry.toEternalSpell] = { entry = entry, step = 1 }
  SPELL_LOOKUP[entry.toCrystalSpell] = { entry = entry, step = 2 }
end

local pending
local button
local statusText
local pendingConfig
local eventFrame
local sequenceWatched = false

local function Log(message)
  local append = RT.AppendDebugLog

  if append then
    append("eternals", message)
  end
end

local function IsEnabled()
  if type(AutoCallboardEternalsDB) ~= "table" then
    return true
  end

  return AutoCallboardEternalsDB.enabled ~= false
end

local function GetBinding()
  if type(AutoCallboardEternalsDB) == "table" and type(AutoCallboardEternalsDB.binding) == "string" and AutoCallboardEternalsDB.binding ~= "" then
    return AutoCallboardEternalsDB.binding
  end

  return DEFAULT_BINDING
end

local function FindEntryInText(text)
  local normalized = Core.normalizeMatchText(text)
  if normalized == "" then
    return nil
  end

  for i = 1, #(ETERNAL_MAP) do
    local entry = ETERNAL_MAP[i]
    if string.find(normalized, entry.keyword, 1, true) then
      return entry
    end
  end

  return nil
end

local function ItemCount(itemID)
  if not GetItemCount then
    return 0
  end

  return tonumber(GetItemCount(itemID)) or 0
end

local function CreateButton()
  if button then
    return button
  end

  button = CreateFrame("Button", BUTTON_NAME, UIParent, "SecureActionButtonTemplate")
  button:SetWidth(150)
  button:SetHeight(34)
  button:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
  button:SetMovable(true)
  button:EnableMouse(true)
  button:RegisterForDrag("LeftButton")
  button:RegisterForClicks("AnyUp")
  button:SetAttribute("type", "item")

  if button.SetBackdrop then
    button:SetBackdrop(AutoCallboardSkin.BACKDROP)
    button:SetBackdropColor(0.09, 0.05, 0.14, 0.92)
    button:SetBackdropBorderColor(0.71, 0.55, 1, 1)
  end

  statusText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  statusText:SetPoint("CENTER", button, "CENTER", 0, 0)
  statusText:SetTextColor(0.85, 0.78, 1, 1)

  button:SetScript("OnDragStart", function() button:StartMoving() end)
  button:SetScript("OnDragStop", function() button:StopMovingOrSizing() end)

  button:Hide()

  return button
end

local function ClearBinding()
  if ClearOverrideBindings and button then
    ClearOverrideBindings(button)
  end
end

local function ApplyBinding()
  if not button then
    return
  end

  if SetOverrideBindingClick then
    SetOverrideBindingClick(button, true, GetBinding(), BUTTON_NAME, "LeftButton")
  end
end

local function HideButton()
  ClearBinding()

  if button then
    button:Hide()
  end
end

local function ConfigureButton(entry, step)
  CreateButton()

  if InCombatLockdown and InCombatLockdown() then
    pendingConfig = { entry = entry, step = step }
    Log("config reportee (combat) element=" .. entry.label .. " step=" .. tostring(step))
    Print(string.format(L.ETERNALS_CONVERSION_WAITING_COMBAT, entry.itemName))
    return false
  end

  pendingConfig = nil

  local itemID = (step == 1) and entry.crystalItem or entry.eternalItem
  button:SetAttribute("type", "item")
  button:SetAttribute("item", "item:" .. tostring(itemID))

  if statusText then
    statusText:SetText(string.format(L.ETERNALS_BUTTON_STATUS, GetBinding(), entry.label, step))
  end

  button:Show()
  ApplyBinding()

  Log("bouton arme element=" .. entry.label .. " step=" .. tostring(step) .. " item=" .. tostring(itemID))

  return true
end

local function WatchSequenceEvents(enabled)
  if not eventFrame or sequenceWatched == enabled then
    return
  end

  sequenceWatched = enabled
  local method = enabled and eventFrame.RegisterEvent or eventFrame.UnregisterEvent

  method(eventFrame, "BAG_UPDATE")
  method(eventFrame, "PLAYER_REGEN_ENABLED")
  pcall(method, eventFrame, "UNIT_SPELLCAST_SUCCEEDED")
end

local function StopPending(reason)
  if pending then
    Log("sequence terminee element=" .. pending.entry.label .. " raison=" .. tostring(reason))
  end

  pending = nil
  pendingConfig = nil
  WatchSequenceEvents(false)
  HideButton()
end

local function AdvanceToStepTwo(entry)
  if not pending or pending.entry ~= entry then
    return
  end

  if ItemCount(entry.eternalItem) < 1 then
    Print(string.format(L.ETERNALS_NONE_IN_INVENTORY, entry.itemName))
    StopPending("eternel absent")
    return
  end

  pending.step = 2
  ConfigureButton(entry, 2)
end

function RT.RefreshEternalLabels()
  local keys = {
    { "ETERNAL_LABEL_WATER", "ETERNAL_ITEM_WATER" },
    { "ETERNAL_LABEL_FIRE", "ETERNAL_ITEM_FIRE" },
    { "ETERNAL_LABEL_EARTH", "ETERNAL_ITEM_EARTH" },
    { "ETERNAL_LABEL_AIR", "ETERNAL_ITEM_AIR" },
    { "ETERNAL_LABEL_SHADOW", "ETERNAL_ITEM_SHADOW" },
  }

  for i = 1, #(ETERNAL_MAP) do
    ETERNAL_MAP[i].label = L[keys[i][1]]
    ETERNAL_MAP[i].itemName = L[keys[i][2]]
  end

  if pending and statusText then
    statusText:SetText(string.format(L.ETERNALS_BUTTON_STATUS, GetBinding(), pending.entry.label, pending.step))
  end
end

function RT.HandleEternalQuest()
  if not IsEnabled() then
    return
  end

  local accepted = RT.lastAcceptedQuest
  if type(accepted) ~= "table" then
    return
  end

  local text = accepted.title or ""

  if text == "" and accepted.questLogIndex and RT.GetQuestLogEntryInfo then
    local info = RT.GetQuestLogEntryInfo(accepted.questLogIndex)
    if type(info) == "table" then
      text = info.title or ""
    end
  end

  if text == "" and accepted.questLogIndex and GetQuestLogTitle then
    text = GetQuestLogTitle(accepted.questLogIndex) or ""
  end

  local entry = FindEntryInText(text)
  if not entry then
    return
  end

  if ItemCount(entry.crystalItem) < 1 then
    Print(string.format(L.ETERNALS_QUEST_NO_CRYSTAL, entry.itemName))
    Log("quete detectee sans cristal element=" .. entry.label)
    return
  end

  pending = { entry = entry, step = 1 }
  WatchSequenceEvents(true)
  ConfigureButton(entry, 1)
end

eventFrame = CreateFrame("Frame")

eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2, arg3, arg4, arg5)
  if event == "ADDON_LOADED" then
    if arg1 == "AutoCallboard" then
      if type(AutoCallboardEternalsDB) ~= "table" then
        AutoCallboardEternalsDB = { enabled = true, binding = DEFAULT_BINDING }
      end

      CreateButton()

      SLASH_AUTOCALLBOARDETERNALS1 = "/acbe"
      SlashCmdList.AUTOCALLBOARDETERNALS = function(input)
        local command = string.lower(input or "")
        command = command:gsub("^%s+", ""):gsub("%s+$", "")

        if command == "on" then
          AutoCallboardEternalsDB.enabled = true
        elseif command == "off" then
          AutoCallboardEternalsDB.enabled = false
          StopPending("desactive")
        elseif command == "stop" then
          StopPending("arret manuel")
        elseif string.find(command, "^bind ") then
          local key = string.upper(command:gsub("^bind%s+", ""))
          if key ~= "" then
            AutoCallboardEternalsDB.binding = key
            if pending then
              ConfigureButton(pending.entry, pending.step)
            end
          end
        elseif command == "reset" then
          if button then
            button:ClearAllPoints()
            button:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
          end
        else
          Print(string.format(L.ETERNALS_STATUS, IsEnabled() and L.STATE_ACTIVE or L.STATE_INACTIVE, GetBinding()))
          Print(L.ETERNALS_USAGE)
        end
      end
    end

    return
  end

  if not pending then
    return
  end

  if event == "UNIT_SPELLCAST_SUCCEEDED" then
    if arg1 ~= "player" then
      return
    end

    local spellID = tonumber(arg5) or tonumber(arg4) or tonumber(arg3)
    local match = spellID and SPELL_LOOKUP[spellID]

    if not match or match.entry ~= pending.entry then
      return
    end

    if match.step == 1 and pending.step == 1 then
      AdvanceToStepTwo(pending.entry)
    elseif match.step == 2 and pending.step == 2 then
      StopPending("succes")
    end

    return
  end

  if event == "BAG_UPDATE" then
    if pending.step == 1 and ItemCount(pending.entry.eternalItem) >= 1 then
      AdvanceToStepTwo(pending.entry)
    end

    return
  end

  if event == "PLAYER_REGEN_ENABLED" then
    if pendingConfig then
      local config = pendingConfig
      pendingConfig = nil
      ConfigureButton(config.entry, config.step)
    end

    return
  end
end)

eventFrame:RegisterEvent("ADDON_LOADED")
