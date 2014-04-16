###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

Character = require("./character")

class Mob extends Character
  constructor: (id, kind) ->
    super id, kind
    @aggroRange = 1
    @isAggressive = true

module.exports = Mob
