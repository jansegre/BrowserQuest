###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

Entity = require("./entity")
Types = require("../common/types")

class Chest extends Entity
  getSpriteName: -> "chest"

  isMoving: -> false

  open: -> @open_callback() if @open_callback

  onOpen: (@open_callback) ->

module.exports = Chest
