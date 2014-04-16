###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

Entity = require("./entity")

class Npc extends Entity
  constructor: (id, kind, x, y) ->
    super id, "npc", kind, x, y

module.exports = Npc
