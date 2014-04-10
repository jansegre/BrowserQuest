$ = require("jquery")
_ = require("underscore")
Area = require("./area")
Util = require("./util")
Types = require("../common/types")
log = require("./log")

class Map
  constructor: (@loadMultiTilesheets, @game) ->
    @data = []
    @isLoaded = false
    @tilesetsLoaded = false
    @mapLoaded = false
    useWorker = not (@game.renderer.mobile or @game.renderer.tablet)
    @_loadMap useWorker
    @_initTilesets()

  _checkReady: ->
    if @tilesetsLoaded and @mapLoaded
      @isLoaded = true
      @ready_func()  if @ready_func

  _loadMap: (useWorker) ->
    if useWorker
      log.info "Loading map with web worker."
      worker = new Worker("js/mapworker.js")
      #worker = new Worker("./mapworker.coffee")
      worker.postMessage 1
      worker.onmessage = (event) =>
        map = event.data
        @_initMap map
        @grid = map.grid
        @plateauGrid = map.plateauGrid
        @mapLoaded = true
        @_checkReady()
    else
      log.info "Loading map via Ajax."
      $.get "maps/world_client.json", ((data) =>
        @_initMap data
        @_generateCollisionGrid()
        @_generatePlateauGrid()
        @mapLoaded = true
        @_checkReady()
      ), "json"

  _initTilesets: ->
    tileset1 = undefined
    tileset2 = undefined
    tileset3 = undefined
    unless @loadMultiTilesheets
      @tilesetCount = 1
      tileset1 = @_loadTileset("img/1/tilesheet.png")
    else
      if @game.renderer.mobile or @game.renderer.tablet
        @tilesetCount = 1
        tileset2 = @_loadTileset("img/2/tilesheet.png")
      else
        @tilesetCount = 2
        tileset2 = @_loadTileset("img/2/tilesheet.png")
        tileset3 = @_loadTileset("img/3/tilesheet.png")
    @tilesets = [
      tileset1
      tileset2
      tileset3
    ]

  _initMap: (map) ->
    @width = map.width
    @height = map.height
    @tilesize = map.tilesize
    @data = map.data
    @blocking = map.blocking or []
    @plateau = map.plateau or []
    @musicAreas = map.musicAreas or []
    @collisions = map.collisions
    @high = map.high
    @animated = map.animated
    @doors = @_getDoors(map)
    @checkpoints = @_getCheckpoints(map)

  _getDoors: (map) ->
    doors = {}
    _.each map.doors, (door) =>
      o = undefined
      switch door.to
        when "u"
          o = Types.Orientations.UP
        when "d"
          o = Types.Orientations.DOWN
        when "l"
          o = Types.Orientations.LEFT
        when "r"
          o = Types.Orientations.RIGHT
        else
          o = Types.Orientations.DOWN
      doors[@GridPositionToTileIndex(door.x, door.y)] =
        x: door.tx
        y: door.ty
        orientation: o
        cameraX: door.tcx
        cameraY: door.tcy
        portal: door.p is 1
    doors

  _loadTileset: (filepath) ->
    tileset = new Image()
    tileset.crossOrigin = "Anonymous"
    tileset.src = filepath
    log.info "Loading tileset: #{filepath}"
    tileset.onload = =>
      throw Error("Tileset size should be a multiple of #{@tilesize}")  if tileset.width % @tilesize > 0
      log.info "Map tileset loaded."
      @tilesetCount -= 1
      if @tilesetCount is 0
        log.debug "All map tilesets loaded."
        @tilesetsLoaded = true
        @_checkReady()
    tileset

  ready: (f) ->
    @ready_func = f

  tileIndexToGridPosition: (tileNum) ->
    x = 0
    y = 0
    getX = (num, w) ->
      return 0  if num is 0
      (if (num % w is 0) then w - 1 else (num % w) - 1)

    tileNum -= 1
    x = getX(tileNum + 1, @width)
    y = Math.floor(tileNum / @width)
    x: x
    y: y

  GridPositionToTileIndex: (x, y) ->
    (y * @width) + x + 1

  isColliding: (x, y) ->
    return false  if @isOutOfBounds(x, y) or not @grid
    @grid[y][x] is 1

  isPlateau: (x, y) ->
    return false  if @isOutOfBounds(x, y) or not @plateauGrid
    @plateauGrid[y][x] is 1

  _generateCollisionGrid: ->
    @grid = []

    for i in [0...@height]
      @grid[i] = []
      for j in [0...@width]
        @grid[i][j] = 0

    _.each @collisions, (tileIndex) =>
      pos = @tileIndexToGridPosition(tileIndex + 1)
      @grid[pos.y][pos.x] = 1

    _.each @blocking, (tileIndex) =>
      pos = @tileIndexToGridPosition(tileIndex + 1)
      @grid[pos.y][pos.x] = 1  if @grid[pos.y]?

    log.debug "Collision grid generated."

  _generatePlateauGrid: ->
    tileIndex = 0
    @plateauGrid = []

    for i in [0...@height]
      @plateauGrid[i] = []
      for j in [0...@width]
        if _.include(@plateau, tileIndex)
          @plateauGrid[i][j] = 1
        else
          @plateauGrid[i][j] = 0
        tileIndex += 1

    log.info "Plateau grid generated."

  ###
  Returns true if the given position is located within the dimensions of the map.

  @returns {Boolean} Whether the position is out of bounds.
  ###
  isOutOfBounds: (x, y) ->
    Util.isInt(x) and Util.isInt(y) and (x < 0 or x >= @width or y < 0 or y >= @height)

  ###
  Returns true if the given tile id is "high", i.e. above all entities.
  Used by the renderer to know which tiles to draw after all the entities
  have been drawn.

  @param {Number} id The tile id in the tileset
  @see Renderer.drawHighTiles
  ###
  isHighTile: (id) ->
    _.indexOf(@high, id + 1) >= 0

  ###
  Returns true if the tile is animated. Used by the renderer.
  @param {Number} id The tile id in the tileset
  ###
  isAnimatedTile: (id) ->
    id + 1 of @animated

  getTileAnimationLength: (id) ->
    @animated[id + 1].l

  getTileAnimationDelay: (id) ->
    animProperties = @animated[id + 1]
    if animProperties.d
      animProperties.d
    else
      100

  isDoor: (x, y) ->
    @doors[@GridPositionToTileIndex(x, y)]?

  getDoorDestination: (x, y) ->
    @doors[@GridPositionToTileIndex(x, y)]

  _getCheckpoints: (map) ->
    checkpoints = []
    _.each map.checkpoints, (cp) ->
      area = new Area(cp.x, cp.y, cp.w, cp.h)
      area.id = cp.id
      checkpoints.push area
    checkpoints

  getCurrentCheckpoint: (entity) ->
    _.detect @checkpoints, (checkpoint) ->
      checkpoint.contains entity

module.exports = Map
