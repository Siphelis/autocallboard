AutoCallboardLocales = AutoCallboardLocales or {}
AutoCallboardLocale = AutoCallboardLocale or {}
AutoCallboardRuntime = AutoCallboardRuntime or {}
local RT = AutoCallboardRuntime

local BASE_LANGUAGE = "enUS"
local registry = AutoCallboardLocales
local L = AutoCallboardLocale
local activeLanguage = BASE_LANGUAGE

local function fill(code)
  for key in pairs(L) do
    L[key] = nil
  end

  local base = registry[BASE_LANGUAGE] or {}
  for key, value in pairs(base) do
    L[key] = value
  end

  local chosen = code ~= BASE_LANGUAGE and registry[code] or nil
  if chosen then
    for key, value in pairs(chosen) do
      L[key] = value
    end
    activeLanguage = code
  else
    activeLanguage = BASE_LANGUAGE
  end
end

function RT.GetLanguage()
  return activeLanguage
end

function RT.IsLanguageAvailable(code)
  return registry[code] ~= nil
end

function RT.GetAvailableLanguages()
  local list = {}

  for code, data in pairs(registry) do
    table.insert(list, { code = code, name = data.LOCALE_NAME or code })
  end

  table.sort(list, function(a, b) return a.name < b.name end)

  return list
end

function RT.SetLanguage(code)
  if not registry[code] then
    return false
  end

  fill(code)

  return true
end

local clientLanguage = GetLocale and GetLocale() or BASE_LANGUAGE
fill(registry[clientLanguage] and clientLanguage or BASE_LANGUAGE)
