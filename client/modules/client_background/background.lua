-- private variables
local background
local clientVersionLabel
local miniAudioButton
local audioMuted = false
local previousVolume = 0.6

-- public functions
function init()
  background = g_ui.displayUI('background')
  background:lower()

  clientVersionLabel = background:getChildById('clientVersionLabel')
  clientVersionLabel:setText('OTClientV8 ' .. g_app.getVersion() .. '\nrev ' .. g_app.getBuildRevision() .. '\nMade by:\n' .. g_app.getAuthor())

  miniAudioButton = background:getChildById('miniAudioButton')

  -- Set initial volume to 60%
  if g_sounds then
    pcall(function()
      local musicChannel = g_sounds.getChannel(SoundChannels.Music)
      if musicChannel then
        musicChannel:setGain(0.6)
      end
      local botChannel = g_sounds.getChannel(SoundChannels.Bot)
      if botChannel then
        botChannel:setGain(0.6)
      end
    end)
  end

  updateAudioButton()

  if not g_game.isOnline() then
    addEvent(function() g_effects.fadeIn(clientVersionLabel, 1500) end)
  end

  connect(g_game, { onGameStart = function()
    fadeOutMusic()
    hide()
  end })
  connect(g_game, { onGameEnd = function()
    fadeInMusic()
    show()
  end })
end

function terminate()
  disconnect(g_game, { onGameStart = hide })
  disconnect(g_game, { onGameEnd = show })

  g_effects.cancelFade(clientVersionLabel)
  background:destroy()

  background = nil
end

function hide()
  background:hide()
end

function show()
  background:show()
end

function hideVersionLabel()
  clientVersionLabel:hide()
end

function setVersionText(text)
  clientVersionLabel:setText(text)
end

function getBackground()
  return background
end

-- Fade out music when entering game
function fadeOutMusic()
  if g_sounds then
    pcall(function()
      local musicChannel = g_sounds.getChannel(SoundChannels.Music)
      if musicChannel then
        local currentGain = musicChannel:getGain()
        if currentGain > 0 then
          -- Gradual fade from current volume to 0 over 10 seconds
          local delays = {
            {time = 1000, gain = 0.5},
            {time = 2000, gain = 0.4},
            {time = 3000, gain = 0.3},
            {time = 4000, gain = 0.2},
            {time = 5000, gain = 0.1},
            {time = 6000, gain = 0.08},
            {time = 7000, gain = 0.06},
            {time = 8000, gain = 0.04},
            {time = 9000, gain = 0.02},
            {time = 10000, gain = 0}
          }

          for _, step in ipairs(delays) do
            scheduleEvent(function()
              local chan = g_sounds.getChannel(SoundChannels.Music)
              if chan then
                chan:setGain(step.gain)
              end
            end, step.time)
          end
        end
      end
    end)
  end
end

-- Fade in music when returning to menu
function fadeInMusic()
  if g_sounds then
    pcall(function()
      local musicChannel = g_sounds.getChannel(SoundChannels.Music)
      if musicChannel then
        musicChannel:setGain(0.6)
      end
    end)
  end
end

-- Toggle audio mute/unmute (only affects music, not bot alarms)
function toggleAudio()
  audioMuted = not audioMuted

  if g_sounds then
    pcall(function()
      local musicChannel = g_sounds.getChannel(SoundChannels.Music)

      if audioMuted then
        if musicChannel then
          previousVolume = musicChannel:getGain()
          if previousVolume == 0 then
            previousVolume = 0.6
          end
          musicChannel:setGain(0)
        end
      else
        if musicChannel then
          musicChannel:setGain(previousVolume)
        end
      end
    end)
  end

  updateAudioButton()
end

-- Update the button's icon and tooltip
function updateAudioButton()
  if not miniAudioButton then return end

  if audioMuted then
    miniAudioButton:setImageSource('/layouts/retro/images/topbuttons/audio_mute')
    miniAudioButton:setImageClip('0 0 20 20')
    miniAudioButton:setTooltip('Audio Muted - Click to Unmute')
    print("Audio button updated: MUTED")
  else
    miniAudioButton:setImageSource('/layouts/retro/images/topbuttons/audio')
    miniAudioButton:setImageClip('0 0 20 20')
    miniAudioButton:setTooltip('Audio On - Click to Mute')
    print("Audio button updated: ON")
  end
end
