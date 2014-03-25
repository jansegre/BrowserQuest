Entity = require("./entity")

class Item extends Entity
  constructor: (id, kind, x, y) ->
    super id, "item", kind, x, y
    @isStatic = false
    @isFromChest = false

  handleDespawn: (params) ->
    @blinkTimeout = setTimeout(=>
      params.blinkCallback()
      @despawnTimeout = setTimeout(params.despawnCallback, params.blinkingDuration)
    , params.beforeBlinkDelay)

  destroy: ->
    clearTimeout @blinkTimeout  if @blinkTimeout
    clearTimeout @despawnTimeout  if @despawnTimeout
    @scheduleRespawn 30000  if @isStatic

  scheduleRespawn: (delay) ->
    setTimeout (=> @respawnCallback() if @respawnCallback), delay

  onRespawn: (@respawnCallback) ->

module.exports = Item
