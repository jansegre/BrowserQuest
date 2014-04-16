###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

Utils = require("./utils")

class Checkpoint
  constructor: (@id, @x, @y, @width, @height) ->

  getRandomPosition: ->
    pos = {}
    pos.x = @x + Utils.randomInt(0, @width - 1)
    pos.y = @y + Utils.randomInt(0, @height - 1)
    pos

module.exports = Checkpoint
