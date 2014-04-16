Entity = require("./entity")
Types = require("../common/types")

class Chest extends Entity
  getSpriteName: -> "chest"

  isMoving: -> false

  open: -> @open_callback() if @open_callback

  onOpen: (@open_callback) ->

module.exports = Chest
