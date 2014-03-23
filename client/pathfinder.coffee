_ = require("underscore")
AStar = require("astar-andrea")

class Pathfinder
  constructor: (@width, @height) ->
    @grid = null
    @blankGrid = []
    @initBlankGrid_()
    @ignored = []

  initBlankGrid_: ->
    for i in [0..@height]
      @blankGrid[i] = []
      for j in [0..@width]
        @blankGrid[i][j] = 0

  findPath: (grid, entity, x, y, findIncomplete) ->
    start = [
      entity.gridX
      entity.gridY
    ]
    end = [
      x
      y
    ]
    path = undefined
    @grid = grid
    @applyIgnoreList_ true
    path = AStar(@grid, start, end)

    # If no path was found, try and find an incomplete one
    # to at least get closer to destination.
    path = @findIncompletePath_(start, end)  if path.length is 0 and findIncomplete is true
    path

  ###
  Finds a path which leads the closest possible to an unreachable x, y position.

  Whenever A* returns an empty path, it means that the destination tile is unreachable.
  We would like the entities to move the closest possible to it though, instead of
  staying where they are without moving at all. That's why we have this function which
  returns an incomplete path to the chosen destination.

  @private
  @returns {Array} The incomplete path towards the end position
  ###
  findIncompletePath_: (start, end) ->
    incomplete = []
    perfect = AStar(@blankGrid, start, end)

    for i in [perfect.length - 1..0]
      x = perfect[i][0]
      y = perfect[i][1]
      if @grid[y][x] is 0
        incomplete = AStar(@grid, start, [x, y])
        break

    incomplete

  ###
  Removes colliding tiles corresponding to the given entity's position in the pathing grid.
  ###
  ignoreEntity: (entity) ->
    @ignored.push entity  if entity

  applyIgnoreList_: (ignored) ->
    _.each @ignored, (entity) =>
      x = (if entity.isMoving() then entity.nextGridX else entity.gridX)
      y = (if entity.isMoving() then entity.nextGridY else entity.gridY)
      @grid[y][x] = (if ignored then 0 else 1)  if x >= 0 and y >= 0

  clearIgnoreList: ->
    @applyIgnoreList_ false
    @ignored = []

module.exports = Pathfinder
