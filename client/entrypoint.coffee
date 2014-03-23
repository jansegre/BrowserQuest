sha1 = require("sha1")
Util = require("./util")

class EntryPoint
  constructor: ->
    # "hashedID" ← use tools/sha1_encode.html to generate: function(){} ← action
    @hashes = "Obda3tBpL9VXsXsSsv5xB4QKNo4=": (aGame) ->
      aGame.player.switchArmor aGame.sprites["firefox"]
      aGame.showNotification "You enter the game as a fox, but not invincible…"
      return

    return

  execute: (game) ->
    res = false
    ID = Util.getUrlVars()["entrance"]
    if ID?
      hash = sha1(ID)
      if @hashes[hash]?
        @hashes[hash] game
        res = true
      else
        game.showNotification "Nice try little scoundrel… bad code, though"
    res

module.exports = EntryPoint
