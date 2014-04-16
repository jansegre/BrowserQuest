###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

class Tile

class AnimatedTile extends Tile
  constructor: (@id, @length, @speed, @index) ->
    @startId = @id
    @lastTime = 0

  tick: ->
    if (@id - @startId) < @length - 1
      @id += 1
    else
      @id = @startId

  animate: (time) ->
    if (time - @lastTime) > @speed
      @tick()
      @lastTime = time
      true
    else
      false

module.exports = AnimatedTile
