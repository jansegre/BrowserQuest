Utils = require("./utils")

class Checkpoint
  constructor: (@id, @x, @y, @width, @height) ->

  getRandomPosition: ->
    pos = {}
    pos.x = @x + Utils.randomInt(0, @width - 1)
    pos.y = @y + Utils.randomInt(0, @height - 1)
    pos

module.exports = Checkpoint
