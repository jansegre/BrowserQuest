_ = require("underscore")
Utils = require("./utils")

class Area
  constructor: (@id, @x, @y, @width, @height, @world) ->
    @entities = []
    @hasCompletelyRespawned = true

  _getRandomPositionInsideArea: ->
    #pos = {}
    #valid = false

    ## this seems a good cap
    #max_retries = 2 * @width * @height

    #k = 0
    #until valid
    #  if k > max_retries
    #    log.error "Could not get random position (area id:#{@id})"
    #    return x: null, y: null
    #  pos.x = @x + Utils.random(@width + 1)
    #  pos.y = @y + Utils.random(@height + 1)
    #  valid = @world.isValidPosition(pos.x, pos.y)
    #  k++
    #pos

    valid_positions = []
    @forEachPosition (pos) =>
      if @world.isValidPosition(pos.x, pos.y)
        valid_positions.push pos

    unless valid_positions.length > 0
      log.error "No valid positions for area id:#{@id}"
      return x: null, y: null

    valid_positions[Utils.random(valid_positions.length)]

  forEachPosition: (iterator) ->
    for i in [@x...@x + @width]
      for j in [@y...@y + @height]
        iterator(x: i, y: j)

  removeFromArea: (entity) ->
    i = _.indexOf(_.pluck(@entities, "id"), entity.id)
    @entities.splice i, 1
    if @isEmpty() and @hasCompletelyRespawned and @emptyCallback
      @hasCompletelyRespawned = false
      @emptyCallback()

  addToArea: (entity) ->
    if entity?
      @entities.push entity
      entity.area = @
      Mob = require("./mob")
      @world.addMob entity if entity instanceof Mob
    @hasCompletelyRespawned = true if @isFull()

  setNumberOfEntities: (@nbEntities) ->

  isEmpty: ->
    not _.any(@entities, (entity) -> not entity.isDead)

  isFull: ->
    not @isEmpty() and (@nbEntities is _.size(@entities))

  onEmpty: (@emptyCallback) ->

module.exports = Area
