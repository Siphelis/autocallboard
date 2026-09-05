local Core = AutoCallboardCore
local RT = AutoCallboardRuntime
local GetQuestTypeName = RT.GetQuestTypeName
local state = RT.state

local Log = RT.Log

RT.instanceTargetDirty = true

function RT.InvalidateInstanceTarget()
  RT.instanceTargetDirty = true
end

function RT.ComputeCurrentInstanceQuestTarget()
  if not state or not state.autoCurrentInstanceQuest then
    return nil, "disabled"
  end

  if not IsInInstance then
    return nil, "missing_is_in_instance"
  end

  local ok, inInstance, instanceType = pcall(IsInInstance)
  if not ok then
    return nil, "is_in_instance_failed"
  end

  if not inInstance then
    return nil, "not_in_instance"
  end

  local names = {}
  local function addName(value)
    if type(value) == "string" and value ~= "" then
      table.insert(names, value)
    end
  end

  if GetInstanceInfo then
    local infoOk, instanceName, infoInstanceType = pcall(GetInstanceInfo)
    if infoOk then
      addName(instanceName)
      if (not instanceType or instanceType == "") and type(infoInstanceType) == "string" then
        instanceType = infoInstanceType
      end
    end
  end

  if GetRealZoneText then
    local zoneOk, zoneName = pcall(GetRealZoneText)
    if zoneOk then
      addName(zoneName)
    end
  end

  if GetZoneText then
    local zoneOk, zoneName = pcall(GetZoneText)
    if zoneOk then
      addName(zoneName)
    end
  end

  if GetMinimapZoneText then
    local zoneOk, zoneName = pcall(GetMinimapZoneText)
    if zoneOk then
      addName(zoneName)
    end
  end

  local target = Core.buildCurrentInstanceTarget({
      instanceType = instanceType,
      name = names[1],
      names = names,
    })

  if not target then
    return nil, "unsupported_instance_type:" .. tostring(instanceType)
  end

  return target
end

function RT.GetCurrentInstanceQuestTarget()
  if not RT.instanceTargetDirty then
    return RT.instanceTargetCache, RT.instanceTargetReason
  end

  local target, reason = RT.ComputeCurrentInstanceQuestTarget()

  if target then
    RT.instanceTargetSignature = tostring(target.questType) .. ":"
        .. tostring(target.name) .. ":" .. table.concat(target.aliases or {}, ",")
  else
    RT.instanceTargetSignature = "none:" .. tostring(reason)
  end

  RT.instanceTargetDirty = false
  RT.instanceTargetCache = target
  RT.instanceTargetReason = reason

  return target, reason
end

function RT.RefreshCurrentInstanceQuestTarget(source)
  local target, reason = RT.GetCurrentInstanceQuestTarget()

  local signature = RT.instanceTargetSignature

  if RT.currentInstanceQuestSignature ~= signature then
    RT.currentInstanceQuestSignature = signature
    if target then
      Log("instance", "target source=", source, " type=", GetQuestTypeName(target.questType), " name=", target.name, " aliases=", table.concat(target.aliases or {}, ", "))
    elseif state and state.autoCurrentInstanceQuest then
      Log("instance", "target unavailable source=", source, " reason=", reason)
    end
  end

  return target
end
