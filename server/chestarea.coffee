Area = require("./area")

class ChestArea extends Area
  constructor: (id, x, y, width, height, @chestX, @chestY, @items, world) ->
    super id, x, y, width, height, world

  contains: (entity) ->
    if entity
      entity.x >= @x and entity.y >= @y and entity.x < @x + @width and entity.y < @y + @height
    else
      false

module.exports = ChestArea
