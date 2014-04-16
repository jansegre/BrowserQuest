###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

Entity = require("./entity")

class Item extends Entity
  constructor: (id, kind, x, y) ->
    super id, "item", kind, x, y
    @isStatic = false
    @isFromChest = false
    @respawnDelay = 30000

  handleDespawn: (params) ->
    @blinkTimeout = setTimeout(=>
      params.blinkCallback()
      @despawnTimeout = setTimeout(params.despawnCallback, params.blinkingDuration)
    , params.beforeBlinkDelay)

  destroy: ->
    clearTimeout @blinkTimeout if @blinkTimeout
    clearTimeout @despawnTimeout if @despawnTimeout
    @scheduleRespawn @respawnDelay if @isStatic

  scheduleRespawn: (delay) ->
    setTimeout (=> @respawnCallback() if @respawnCallback), delay

  onRespawn: (@respawnCallback) ->

module.exports = Item
