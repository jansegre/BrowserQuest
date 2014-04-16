###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

Area = require("./area")

class ChestArea extends Area
  constructor: (id, x, y, width, height, @chestX, @chestY, @items, world) ->
    super id, x, y, width, height, world

  contains: (entity) ->
    if entity
      entity.x >= @x and entity.y >= @y and entity.x < @x + @width and entity.y < @y + @height
    else
      false

module.exports = ChestArea
