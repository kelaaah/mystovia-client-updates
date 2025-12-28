local context = G.botContext
local Panels = context.Panels

Panels.TradeMessage = function(parent)
  context.macro(60000, "Send message on trade", nil, function()
    local trade = context.getChannelId("advertising")
    if not trade then
      trade = context.getChannelId("trade")
    end
    if context.storage.autoTradeMessage:len() > 0 and trade then    
      context.sayChannel(trade, context.storage.autoTradeMessage)
    end
  end, parent)
  -- ensure old default messages are replaced so UI shows desired text even if storage contains old value
  if type(context.storage.autoTradeMessage) == "string" then
    if context.storage.autoTradeMessage:find("OTClientV8") or context.storage.autoTradeMessage:find("OTCv8") then
      context.storage.autoTradeMessage = "I play Mystovia!"
    end
  end
  context.addTextEdit("autoTradeMessage", context.storage.autoTradeMessage or "I play Mystovia!", function(widget, text)    
    context.storage.autoTradeMessage = text
  end, parent)
end

Panels.AutoStackItems = function(parent)
  context.macro(500, "Auto stacking items", nil, function()
    local containers = context.getContainers()
    for i, container in pairs(containers) do
      local toStack = {}
      for j, item in ipairs(container:getItems()) do
        if item:isStackable() and item:getCount() ~= 100 then
          local otherItem = toStack[item:getId()]
          if otherItem then
            g_game.move(item, otherItem, item:getCount())
            return
          end
          toStack[item:getId()] = container:getSlotPosition(j - 1)
        end
      end
    end
  end, parent)
end