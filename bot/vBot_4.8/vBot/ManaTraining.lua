setDefaultTab('main')

local panelName = "ManaTraining"

-- Initialize config if not exists
if not storage[panelName] then
  storage[panelName] = {
    enabled = false,
    spell = "exura",
    interval = 2
  }
end

local config = storage[panelName]

-- Create UI panel (main button)
local ui = UI.createWidget("ManaTrainingPanel")

-- Create settings window
local mainWindow = UI.createWindow("ManaTrainingWindow")
mainWindow:hide()

-- Title button (on/off switch)
ui.title.onClick = function(widget)
  config.enabled = not config.enabled
  widget:setOn(config.enabled)
end
ui.title:setOn(config.enabled)

-- Setup button opens window
ui.settings.onClick = function(widget)
  mainWindow:show()
  mainWindow:raise()
  mainWindow:focus()
end

-- Close button
mainWindow.closeButton.onClick = function()
  mainWindow:hide()
end

-- Load saved values into window
mainWindow.spellName:setText(config.spell)
mainWindow.interval:setValue(config.interval)

-- Save on change
mainWindow.spellName.onTextChange = function(widget, text)
  config.spell = text
end

mainWindow.interval.onValueChange = function(widget, value)
  config.interval = value
end

-- Main macro - runs every 100ms
local lastCastTime = 0

macro(100, function()
  if not config.enabled then return end
  if not g_game.isOnline() then return end

  local player = g_game.getLocalPlayer()
  if not player then return end

  -- Don't cast if in protection zone
  if isInPz() then return end

  -- Check interval (convert seconds to milliseconds)
  local intervalMs = config.interval * 1000
  local currentTime = now

  if currentTime - lastCastTime >= intervalMs then
    -- Try to cast the spell
    local spell = config.spell
    if spell and spell:len() > 0 then
      say(spell)
      lastCastTime = currentTime
    end
  end
end)
