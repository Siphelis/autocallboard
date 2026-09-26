AutoCallboardLocales = AutoCallboardLocales or {}
AutoCallboardRuntime = AutoCallboardRuntime or {}
local RT = AutoCallboardRuntime

AutoCallboardLocale = EbonAPI.Locale.register("AutoCallboard", AutoCallboardLocales)

function RT.GetLanguage()
  return EbonAPI:GetLanguage()
end

function RT.IsLanguageAvailable(code)
  return EbonAPI.Locale.isAvailable(code)
end

function RT.GetAvailableLanguages()
  return EbonAPI:GetAvailableLanguages()
end

function RT.SetLanguage(code)
  return EbonAPI:SetLanguage(code)
end
