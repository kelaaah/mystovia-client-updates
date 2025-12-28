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

  connect(g_game, { onGameStart = hide })
  connect(g_game, { onGameEnd = show })
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
