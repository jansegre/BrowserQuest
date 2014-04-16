###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

sha1 = require("sha1")
log = require("./log")
Util = require("./util")

class EntryPoint
  constructor: ->
    # "hashedID" ← use tools/sha1_encode.html to generate: function(){} ← action
    @hashes =
      "1c772e7ff575c76274b2ab9f90d82b428029b50b": (aGame) ->
        aGame.player.switchArmor aGame.sprites["firefox"]
        aGame.showNotification "You enter the game as a fox, but not invincible…"

  execute: (game) ->
    res = false
    ID = Util.getUrlVars()["entrance"]
    log.debug "entrance ID is #{ID}"
    if ID?
      hash = sha1(ID)
      if @hashes[hash]?
        @hashes[hash] game
        res = true
      else
        game.showNotification "Nice try little scoundrel… bad code, though"
    res

module.exports = EntryPoint
