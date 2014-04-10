Entity = require("./entity")
Types = require("../common/types")

class Chest extends Entity
  getSpriteName: -> "chest"

  isMoving: -> false

  open: -> @open_callback() if @open_callback

  onOpen: (callback) -> @open_callback = callback

module.exports = Chest
