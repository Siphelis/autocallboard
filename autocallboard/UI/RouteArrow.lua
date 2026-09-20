local Core = AutoCallboardCore
local Skin = AutoCallboardSkin
local THEME = Skin.THEME
local L = AutoCallboardLocale
local RT = AutoCallboardRuntime

local WINDOW_NAME = "AutoCallboardRouteArrow"
local ARROW_TEXTURE = [[Interface\AddOns\AutoCallboard\Media\Arrow]]

local SHEET_W = 2048
local SHEET_H = 1024
local COLUMNS = 10
local CELL_W = 200
local CELL_H = 152
local STORED_FRAMES = 60
local ARROW_W = 100
local ARROW_H = 76

local MODEL_W = 142
local MODEL_H = 134

local WIDGET_W = 176
local TEXT_BLOCK = 32
local BASELINE_HEIGHT = 768
local MIN_SCALE = 1
local MAX_SCALE = 2.2
local REFRESH_INTERVAL = 0.05
local ARRIVED_YARDS = 12
local ARRIVED_FLYING_YARDS = 45
local TWO_PI = math.pi * 2

local CurrentSkin

local arrowFrame
local target
local activeTile
local elapsedSince = 0

CurrentSkin = function()
  local appearance = RT.state and RT.state.appearance

  return Core.findArrowSkin(appearance and appearance.arrowSkin or Core.ARROW_SKIN_DEFAULT)
end

RT.CurrentArrowSkin = CurrentSkin

function RT.ScreenPixelHeight()
  local resolution = GetCVar and GetCVar("gxResolution")
  local height = resolution and tonumber(string.match(tostring(resolution), "%d+%s*[xX]%s*(%d+)"))

  if height and height > 0 then
    return height
  end

  if GetScreenHeight and UIParent and UIParent.GetEffectiveScale then
    local scaled = GetScreenHeight() * (UIParent:GetEffectiveScale() or 1)

    if scaled and scaled > 0 then
      return scaled
    end
  end

  return BASELINE_HEIGHT
end

function RT.RouteArrowScale(pixelHeight)
  local height = tonumber(pixelHeight) or RT.ScreenPixelHeight()

  if height <= 0 then
    return MIN_SCALE
  end

  local factor = height / BASELINE_HEIGHT

  if factor < MIN_SCALE then
    return MIN_SCALE
  end

  if factor > MAX_SCALE then
    return MAX_SCALE
  end

  return factor
end

function RT.ArrowScaleFactor(appearance)
  appearance = appearance or (RT.state and RT.state.appearance)

  if type(appearance) ~= "table" then
    return 1
  end

  return (tonumber(appearance.scale) or 1) * (tonumber(appearance.arrowScale) or 1)
end

function RT.RefreshRouteArrowScale()
  if not arrowFrame then
    return false
  end

  arrowFrame:SetScale(RT.ArrowScaleFactor())

  return true
end

function RT.IsRouteArrowOverhead(yards, flying)
  local limit = flying and ARRIVED_FLYING_YARDS or ARRIVED_YARDS

  return (tonumber(yards) or 0) <= limit
end

function RT.RouteArrowRotation(bearing, facing)
  local angle = (bearing or 0) + (facing or 0)

  angle = math.fmod(angle, TWO_PI)

  if angle < 0 then
    angle = angle + TWO_PI
  end

  return angle
end

function RT.RouteArrowFrame(angle)
  local turn = math.fmod(angle or 0, TWO_PI)

  if turn < 0 then
    turn = turn + TWO_PI
  end

  local mirrored = turn > math.pi
  local half = mirrored and (TWO_PI - turn) or turn
  local cell = math.floor(half / math.pi * (STORED_FRAMES - 1) + 0.5)

  if cell < 0 then
    cell = 0
  end

  if cell > STORED_FRAMES - 1 then
    cell = STORED_FRAMES - 1
  end

  return cell, mirrored
end

function RT.PaintArrowSheet(texture, angle)
  local cell, mirrored = RT.RouteArrowFrame(angle)
  local column = math.fmod(cell, COLUMNS)
  local row = math.floor(cell / COLUMNS)

  local left = (column * CELL_W) / SHEET_W
  local right = ((column + 1) * CELL_W) / SHEET_W
  local top = (row * CELL_H) / SHEET_H
  local bottom = ((row + 1) * CELL_H) / SHEET_H

  if mirrored then
    left, right = right, left
  end

  texture:SetTexCoord(left, right, top, bottom)
end

function RT.ArrowSheetTexture()
  return ARROW_TEXTURE
end

function RT.ArrowSheetSize(boxWidth)
  local ratio = (tonumber(boxWidth) or MODEL_W) / MODEL_W

  return ARROW_W * ratio, ARROW_H * ratio
end

function RT.RouteArrowBearing(fromX, fromY, toX, toY)
  local dx, dy = toX - fromX, toY - fromY

  if dx == 0 and dy == 0 then
    return nil, 0
  end

  local distance = math.sqrt(dx * dx + dy * dy)

  return math.atan2(-dx, dy), distance
end

function RT.DressArrowModel(model, skin)
  if not model or type(skin) ~= "table" or skin.kind ~= "model" then
    return false
  end

  pcall(model.ClearModel, model)
  pcall(model.SetModel, model, skin.path)
  pcall(model.SetModelScale, model, Core.arrowModelScale(skin))

  return true
end

function RT.RouteArrowPreviewAngle()
  local facing = GetPlayerFacing and GetPlayerFacing() or 0

  if not target then
    return RT.RouteArrowRotation(0, facing)
  end

  local map, x, y = RT.ReadPlayerMapPoint()
  local here = map and RT.WorldPointFor(map, x, y)
  local there = RT.WorldPointFor(target.map, target.x, target.y)

  if not here or not there or here.map ~= there.map then
    return RT.RouteArrowRotation(0, facing)
  end

  local bearing = RT.RouteArrowBearing(here.x, here.y, there.x, there.y)

  if not bearing then
    return RT.RouteArrowRotation(0, facing)
  end

  return RT.RouteArrowRotation(bearing, facing)
end

function RT.RouteArrowTile()
  return activeTile
end

function RT.HideRouteArrowShape()
  if activeTile then
    activeTile:Hide()
  end
end

function RT.ShowRouteArrowTile(skin)
  if not arrowFrame or type(skin) ~= "table" or not RT.BuildArrowTile then
    return nil
  end

  arrowFrame.tiles = arrowFrame.tiles or {}

  local tile = arrowFrame.tiles[skin.id]

  if not tile then
    tile = RT.BuildArrowTile(arrowFrame, skin, { bare = true, boxWidth = MODEL_W, boxHeight = MODEL_H })
    tile:SetPoint("TOP", arrowFrame, "TOP", 0, 0)
    arrowFrame.tiles[skin.id] = tile
  end

  if activeTile and activeTile ~= tile then
    activeTile:Hide()
  end

  activeTile = tile
  tile:Show()

  return tile
end

function RT.OnArrowSkinChanged()
  if arrowFrame and arrowFrame.tiles then
    for _, tile in pairs(arrowFrame.tiles) do
      tile:Hide()
    end
  end

  activeTile = nil

  if arrowFrame and RT.GetRouteArrowTarget() then
    RT.UpdateRouteArrow(true)
  end
end

function RT.GetRouteArrowTarget()
  return target
end

function RT.ClearRouteArrowTarget()
  target = nil

  if arrowFrame then
    arrowFrame:Hide()
  end
end

function RT.SetRouteArrowTarget(step, action)
  if type(step) ~= "table" or not step.map or step.map == "" or not step.x or not step.y then
    RT.ClearRouteArrowTarget()
    RT.Error(L.ROUTE_ARROW_NO_SPOT)
    return false
  end

  local point = RT.WorldPointFor(step.map, step.x, step.y)

  if not point then
    RT.ClearRouteArrowTarget()
    RT.Error(L.ROUTE_ARROW_UNKNOWN_ZONE)
    return false
  end

  target = {
    map = step.map,
    x = step.x,
    y = step.y,
    step = step,
    action = action,
  }

  RT.CreateRouteArrow()
  RT.RefreshRouteArrowLabel()
  RT.UpdateRouteArrow(true)
  arrowFrame:Show()

  return true
end

function RT.UpdateRouteArrow(force)
  if not arrowFrame or not target then
    return
  end

  if IsInInstance and IsInInstance() then
    arrowFrame.status:SetText(L.ROUTE_ARROW_INSTANCE)
    RT.HideRouteArrowShape()
    return
  end

  local map, x, y = RT.ReadPlayerMapPoint()

  if not map then
    arrowFrame.status:SetText(L.ROUTE_ARROW_NO_POSITION)
    RT.HideRouteArrowShape()
    return
  end

  local here = RT.WorldPointFor(map, x, y)
  local there = RT.WorldPointFor(target.map, target.x, target.y)

  if not here or not there or here.map ~= there.map then
    arrowFrame.status:SetText(L.ROUTE_ARROW_FAR)
    RT.HideRouteArrowShape()
    return
  end

  local bearing, distance = RT.RouteArrowBearing(here.x, here.y, there.x, there.y)
  local yards = math.floor(distance + 0.5)
  local flying = IsFlying and IsFlying() and true or false
  local overhead = RT.IsRouteArrowOverhead(yards, flying)

  if overhead and not flying then
    arrowFrame.status:SetText(L.ROUTE_ARROW_ARRIVED)
    RT.HideRouteArrowShape()
    return
  end

  local facing = GetPlayerFacing and GetPlayerFacing() or nil

  if not facing or not bearing then
    arrowFrame.status:SetText(flying and string.format(L.ROUTE_ARROW_DESCEND, tostring(yards))
      or L.ROUTE_ARROW_NO_FACING)
    RT.HideRouteArrowShape()
    return
  end

  arrowFrame.status:SetText(overhead
    and string.format(L.ROUTE_ARROW_DESCEND, tostring(yards))
    or string.format(L.ROUTE_ARROW_DISTANCE, tostring(yards)))

  local tile = RT.ShowRouteArrowTile(CurrentSkin())

  if tile then
    RT.PaintArrowTile(tile, RT.RouteArrowRotation(bearing, facing))
  end
end

function RT.CreateRouteArrow()
  if arrowFrame then
    return arrowFrame
  end

  arrowFrame = Skin.Window(WINDOW_NAME, {
    width = WIDGET_W,
    height = MODEL_H + TEXT_BLOCK,
    movable = true,
    noEsc = true,
    strata = "HIGH",
    bare = true,
  })

  RT.routeArrow = arrowFrame

  local function Line(offset, paint)
    local line = arrowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    line:SetPoint("TOPLEFT", arrowFrame, "TOPLEFT", 0, -offset)
    line:SetPoint("RIGHT", arrowFrame, "RIGHT", 0, 0)
    line:SetJustifyH("CENTER")
    line:SetFont(Skin.BUTTON_FONT, 10, "OUTLINE")
    paint(line)

    return line
  end

  arrowFrame.status = Line(MODEL_H + 2, Skin.HeadingText)
  arrowFrame.label = Line(MODEL_H + 18, Skin.MutedText)

  arrowFrame:SetScript("OnUpdate", function(_, delta)
    elapsedSince = elapsedSince + (delta or 0)

    if elapsedSince < REFRESH_INTERVAL then
      return
    end

    elapsedSince = 0
    RT.UpdateRouteArrow()
    end)

  arrowFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -160)
  RT.RefreshRouteArrowScale()
  RT.RefreshRouteArrowLock()
  arrowFrame:Hide()

  return arrowFrame
end

function RT.RefreshRouteArrowLock()
  local appearance = RT.state and RT.state.appearance

  if arrowFrame then
    arrowFrame:EnableMouse(not (appearance and appearance.locked))
  end
end

function RT.RefreshRouteArrowLabel()
  if arrowFrame and target then
    arrowFrame.label:SetText(target.action and Core.routeActionLine(target.action) or Core.routeStepLine(target.step))
  end
end
