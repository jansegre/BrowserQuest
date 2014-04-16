###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

class Timer
  constructor: (@duration, startTime) ->
    @lastTime = startTime or 0

  isOver: (time) ->
    over = false
    if (time - @lastTime) > @duration
      over = true
      @lastTime = time
    over

module.exports = Timer
