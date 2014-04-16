###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

log = require("./log")

class Camera
  constructor: (@renderer) ->
    @x = 0
    @y = 0
    @gridX = 0
    @gridY = 0
    @offset = 0.5
    @rescale()

  rescale: ->
    factor = (if @renderer.mobile then 1 else 2)
    @gridW = 15 * factor
    @gridH = 7 * factor
    log.debug "---------"
    log.debug "Factor:" + factor
    log.debug "W:" + @gridW + " H:" + @gridH

  setPosition: (x, y) ->
    @x = x
    @y = y
    @gridX = Math.floor(x / 16)
    @gridY = Math.floor(y / 16)

  setGridPosition: (x, y) ->
    @gridX = x
    @gridY = y
    @x = @gridX * 16
    @y = @gridY * 16

  lookAt: (entity) ->
    r = @renderer
    x = Math.round(entity.x - (Math.floor(@gridW / 2) * r.tilesize))
    y = Math.round(entity.y - (Math.floor(@gridH / 2) * r.tilesize))
    @setPosition x, y

  forEachVisiblePosition: (callback, extra) ->
    extra = extra or 0
    y = @gridY - extra
    maxY = @gridY + @gridH + (extra * 2)

    while y < maxY
      x = @gridX - extra
      maxX = @gridX + @gridW + (extra * 2)

      while x < maxX
        callback x, y
        x += 1
      y += 1

  isVisible: (entity) ->
    @isVisiblePosition entity.gridX, entity.gridY

  isVisiblePosition: (x, y) ->
    if y >= @gridY and y < @gridY + @gridH and x >= @gridX and x < @gridX + @gridW
      true
    else
      false

  focusEntity: (entity) ->
    w = @gridW - 2
    h = @gridH - 2
    x = Math.floor((entity.gridX - 1) / w) * w
    y = Math.floor((entity.gridY - 1) / h) * h
    @setGridPosition x, y

module.exports = Camera
