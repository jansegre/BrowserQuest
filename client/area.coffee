###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

class Area
  constructor: (@x, @y, @width, @height) ->

  contains: (entity) ->
    if entity
      entity.gridX >= @x and entity.gridY >= @y and entity.gridX < @x + @width and entity.gridY < @y + @height
    else
      false

module.exports = Area
