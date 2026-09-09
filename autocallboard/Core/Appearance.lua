local Core = AutoCallboardCore

local DEFAULT = { background = 0x050505, accent = 0xB048F8, scale = 1, opacity = 0.96,
  locked = false, goldTotal = true, goldLast = true, goldCurrent = true, goldSession = false, goldMain = false }
local LIMIT = { background = {0, 0xFFFFFF}, accent = {0, 0xFFFFFF}, scale = {0.7, 1.4}, opacity = {0.25, 1} }

function Core.copyAppearance(source)
  local result = {}
  source = type(source) == 'table' and source or {}
  for key, default in pairs(DEFAULT) do
    local value, limit = source[key], LIMIT[key]
    if type(value) ~= type(default) or (limit and (value ~= value or value < limit[1] or value > limit[2])) then value = default end
    result[key] = (key == 'background' or key == 'accent') and math.floor(value) or value
  end
  return result
end

-- This is the order of the existing control-frame buttons, per character.
function Core.copyToolbar(source)
  if type(source) ~= "table" then return {1, 2, 3, 4, 5, 6} end
  local result, seen = {}, {}
  for i = 1, 12 do
    local id = source[i]
    if type(id) == "number" and id == math.floor(id) and id >= 1 and id <= 12 and not seen[id] then
      result[#result + 1], seen[id] = id, true
    end
  end
  return result
end
