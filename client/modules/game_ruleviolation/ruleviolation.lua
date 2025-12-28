rvreasons = {}
rvreasons[1] = tr("Section 1 - Main Rules")
rvreasons[2] = tr("Section 2 - Cheating")
rvreasons[3] = tr("Section 3 - Messages and Statements")
rvreasons[4] = tr("Section 4 - PvP Balance")
rvreasons[5] = tr("Section 5 - Sales and Advertising")

rvactions = {}
rvactions[0] = tr("Notation")
rvactions[1] = tr("Name Report")
rvactions[2] = tr("Banishment")
rvactions[3] = tr("Name Report + Banishment")
rvactions[4] = tr("Banishment + Final Warning")
rvactions[5] = tr("Name Report + Banishment + Final Warning")
rvactions[6] = tr("Statement Report")

ruleViolationWindow = nil
reasonsTextList = nil
actionsTextList = nil

function init()
  connect(g_game, { onGMActions = loadReasons })

  ruleViolationWindow = g_ui.displayUI('ruleviolation')
  ruleViolationWindow:setVisible(false)

  reasonsTextList = ruleViolationWindow:getChildById('reasonList')
  actionsTextList = ruleViolationWindow:getChildById('actionList')

  g_keyboard.bindKeyDown('Ctrl+Y', function() show() end)

  if g_game.isOnline() then
    loadReasons()
  end
end

function terminate()
  disconnect(g_game, { onGMActions = loadReasons })
  g_keyboard.unbindKeyDown('Ctrl+Y')

  ruleViolationWindow:destroy()
end

function hasWindowAccess()
  return reasonsTextList:getChildCount() > 0
end

function loadReasons()
  reasonsTextList:destroyChildren()
  actionsTextList:destroyChildren()

  local actions = g_game.getGMActions()
  for reason, actionFlags in pairs(actions) do
    local label = g_ui.createWidget('RVListLabel', reasonsTextList)
    label.onFocusChange = onSelectReason
    label:setText(rvreasons[reason])
    label.reasonId = reason
    label.actionFlags = actionFlags
  end

  if not hasWindowAccess() and ruleViolationWindow:isVisible() then hide() end
end

function show(target, statement)
  if g_game.isOnline() and hasWindowAccess() then
    if target then
      ruleViolationWindow:getChildById('nameText'):setText(target)
    end

    if statement then
      ruleViolationWindow:getChildById('statementText'):setText(statement)
    end

    ruleViolationWindow:show()
    ruleViolationWindow:raise()
    ruleViolationWindow:focus()
    ruleViolationWindow:getChildById('commentText'):focus()
  end
end

function hide()
  ruleViolationWindow:hide()
  clearForm()
end

function onSelectReason(reasonLabel, focused)
  if reasonLabel.actionFlags and focused then
    actionsTextList:destroyChildren()
    for actionBaseFlag = 0, #rvactions do
      local actionFlagString = rvactions[actionBaseFlag]
      if bit32.band(reasonLabel.actionFlags, math.pow(2, actionBaseFlag)) > 0 then
        local label = g_ui.createWidget('RVListLabel', actionsTextList)
        label:setText(actionFlagString)
        label.actionId = actionBaseFlag
      end
    end
  end
end

function report()
  local reasonLabel = reasonsTextList:getFocusedChild()
  if not reasonLabel then
    displayErrorBox(tr("Error"), tr("You must select a reason."))
    return
  end

  local actionLabel = actionsTextList:getFocusedChild()
  if not actionLabel then
    displayErrorBox(tr("Error"), tr("You must select an action."))
    return
  end

  local target = ruleViolationWindow:getChildById('nameText'):getText()
  local reason = reasonLabel.reasonId
  local action = actionLabel.actionId
  local comment = ruleViolationWindow:getChildById('commentText'):getText()
  local statement = ruleViolationWindow:getChildById('statementText'):getText()
  local statementId = 0 -- TODO: message unique id ?
  local ipBanishment = ruleViolationWindow:getChildById('ipBanCheckBox'):isChecked()
  if action == 6 and statement == "" then
    displayErrorBox(tr("Error"), tr("No statement has been selected."))
  elseif comment == "" then
    displayErrorBox(tr("Error"), tr("You must enter a comment."))
  else
    g_game.reportRuleViolation(target, reason, action, comment, statement, statementId, ipBanishment)
    hide()
  end
end

function clearForm()
  ruleViolationWindow:getChildById('nameText'):clearText()
  ruleViolationWindow:getChildById('commentText'):clearText()
  ruleViolationWindow:getChildById('statementText'):clearText()
  ruleViolationWindow:getChildById('ipBanCheckBox'):setChecked(false)
end
