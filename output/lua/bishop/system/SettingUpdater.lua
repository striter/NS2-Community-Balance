Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.SettingUpdater = {}

local Log = Bishop.debug.SettingsLog

local kDebug = Bishop.debug.settings -- Settings debug flag.

--------------------------------------------------------------------------------
-- Setting metadata.
--------------------------------------------------------------------------------
-- NOTE: Names MUST be less than 20 characters.

local kMetadata = {
  {
    name = "botManager",
    variables = {
      {
        name = "manage",
        type = "boolean"
      },
      {
        name = "forceGame",
        type = "boolean"
      },
      {
        name = "continueGame",
        type = "boolean"
      },
      {
        name = "marineCommander",
        type = "boolean"
      },
      {
        name = "alienCommander",
        type = "boolean"
      },
      {
        name = "marines",
        type = "boolean"
      },
      {
        name = "aliens",
        type = "boolean"
      },
      {
        name = "marineTeamSize",
        type = "integer",
        min = 0,
        max = 25
      },
      {
        name = "alienTeamSize",
        type = "integer",
        min = 0,
        max = 25
      }
    }
  },
  {
    name = "customization",
    variables = {
      {
        name = "botChat",
        type = "boolean"
      },
      {
        name = "botChatCom",
        type = "boolean"
      }
    }
  },
  {
    name = "marineCom",
    variables = {
      {
        name = "offensivePhase",
        type = "boolean"
      },
      {
        name = "offensivePhaseArm",
        type = "boolean"
      }
    }
  },
  {
    name = "marine",
    variables = {
      {
        name = "jetpackLmg",
        type = "boolean"
      }
    }
  }
}

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

local function GetContainerMetadata(name)
  for _, container in ipairs(kMetadata) do
    if container.name == name then
      return container
    end
  end
  return nil
end

local function GetSettingMetadata(containerName, variableName)
  local container = GetContainerMetadata(containerName)
  if not container then
    return nil
  end

  for _, setting in ipairs(container.variables) do
    if setting.name == variableName then
      return setting
    end
  end
  return nil
end

local function DestringSetting(value, toType, min, max)
  if toType == "boolean" then
    if value == "true" then
      return true
    end
    return false

  elseif toType == "integer" then
    local number = tonumber(value)
    if not number then
      return nil
    end
    if min and max then
      return Clamp(math.round(number), min, max)
    end
    return number
  end

  return nil
end

local function VerifySetting(container, variable, value, fromServer)
  if kDebug then Log("VerifySetting %s %s %s", container, variable, value) end
  local metadata = GetSettingMetadata(container, variable)
  if not metadata then
    if kDebug then Log("  No metadata found.") end
    return false
  end

  if Server and not fromServer and metadata.readOnly then
    Bishop.Error("Client attempted to alter read-only variable: %s %s.",
      container, variable)
    return false
  end

  if metadata.type == "boolean" then
    if kDebug then Log("  Boolean found.") end
    return true, DestringSetting(value, "boolean")

  elseif metadata.type == "integer" then
    if kDebug then Log("  Integer found.") end
    local number = DestringSetting(value, "integer", metadata.min, metadata.max)
    if not number then
      if kDebug then Log("  Integer was bad.") end
      return false
    end
    return true, number

  elseif metadata.type == "string" then
    return true, value
  end

  return false
end

-- This function assumes the values are valid, check them first. The .json file
-- is updated immediately.
local function WriteConfig(Plugin, container, variable, value)
  if not Plugin.Config[container] then
    Plugin.Config[container] = {}
  end
  Plugin.Config[container][variable] = value
  Plugin:SaveConfig()
end

--------------------------------------------------------------------------------
-- Handle network messages involving settings changes or updates.
--------------------------------------------------------------------------------

function Bishop.SettingUpdater.UpdateSetting(Plugin, container, variable, value)
  if Server then
    -- This block runs when a client attempts to change a setting through the UI
    -- or directly via console command.
    local success, actualValue = VerifySetting(container, variable, value)

    if not success then
      Bishop.Error("Received bad setting from client: %s %s %s", container,
        variable, value)
      return
    end

    -- The setting was successfully verified - the new value needs to be
    -- broadcast to all connected clients.
    if kDebug then
      Log("UpdateSetting (Server): %s %s %s", container, variable, value)
    end
    Bishop.settings[container][variable] = actualValue
    Plugin:SendNetworkMessage(nil, "Bishop_Setting",
      {
        Container = container,
        Setting = variable,
        Value = value
      }, true)

    -- Write out the new setting to the config.
    WriteConfig(Plugin, container, variable, value)
  else
    -- The client received a setting update from the server. After verification,
    -- throw it directly into the settings table.
    if kDebug then
      Log("UpdateSetting (Client): %s %s %s", container, variable, value)
    end
    local success, actualValue = VerifySetting(container, variable, value, true)

    if not success then
      Bishop.Error("Received bad setting from server: %s %s %s", container,
        variable, value)
      return
    end

    Bishop.settings[container][variable] = actualValue

    -- Update the UI directly if it's already open.
    Shine.Hook.Broadcast("OnBishopSettingsChanged")
  end
end

--------------------------------------------------------------------------------
-- Respond to a client's request for settings.
--------------------------------------------------------------------------------

function Bishop.SettingUpdater.GetSetting(Plugin, client, container, variable)
  if not GetSettingMetadata(container, variable) then
    Bishop.Error("Client attempted to get invalid setting %s %s.", container,
      variable)
    return
  end

  if kDebug then
    Log("Transmitting setting %s %s to client.", container, variable)
  end
  Plugin:SendNetworkMessage(client, "Bishop_Setting",
    {
      Container = container,
      Setting = variable,
      Value = tostring(Bishop.settings[container][variable])
    }, true)
end

function Bishop.SettingUpdater.Broadcast(Plugin, client)
  -- The first time a client opens the Bishop UI, it sends the GetAllSettings
  -- message to the server. Mass broadcast the entire settings array to this
  -- client.
  if kDebug then Log("Broadcasting all settings to client.") end
  for _, container in ipairs(kMetadata) do
    for _, setting in ipairs(container.variables) do
      Plugin:SendNetworkMessage(client, "Bishop_Setting",
        {
          Container = container.name,
          Setting = setting.name,
          Value = tostring(Bishop.settings[container.name][setting.name])
        }, true)
    end
  end
end

--------------------------------------------------------------------------------
-- Set a read-only variable and broadcast the update to clients.
--------------------------------------------------------------------------------

function Bishop.SettingUpdater.SetVariable(container, variable, value)
  local success, actualValue = VerifySetting(container, variable, value, true)

  if not success then
    Bishop.Error("Attempt to set bad variable: %s %s %s", container, variable,
      value)
    return
  end

  -- Update the table and transmit the new value to all clients.
  if kDebug then Log("SetVariable: %s %s %s", container, variable, value) end
  Bishop.settings[container][variable] = actualValue
  BishopS.Plugin:SendNetworkMessage(nil, "Bishop_Setting",
    {
      Container = container,
      Setting = variable,
      Value = value
    }, true)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
