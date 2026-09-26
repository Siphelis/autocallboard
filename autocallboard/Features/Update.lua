local RT = AutoCallboardRuntime

RT.updateUrl = "https://github.com/Siphelis/autocallboard/releases/latest"
RT.licenseUrl = "https://github.com/Siphelis/autocallboard/blob/main/LICENSE"

local function RefreshNotice()
  if RT.RefreshUpdateNotice then
    RT.RefreshUpdateNotice()
  end
end

function RT.GetAvailableUpdate()
  if not RT.api then
    return nil
  end

  return RT.api:AvailableUpdate()
end

function RT.OpenUpdatePage()
  if RT.OpenLink(RT.updateUrl) then
    return true
  end

  RT.ShowAddonHelp("about")

  return false
end

local function OnUpdateAvailable(_, name)
  if name == "AutoCallboard" and RT.api:IsReady() then
    RefreshNotice()
  end
end

function RT.InitVersionWatch()
  if not RT.api then
    return false
  end

  RT.api:Version(RT.GetAddonVersion(), RT.updateUrl)
  RT.api:On("UPDATE_AVAILABLE", OnUpdateAvailable)
  RT.api:On("READY", RefreshNotice)

  return true
end
