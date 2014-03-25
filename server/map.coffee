_ = require("underscore")
fs = require("fs")
file = require("../shared/js/file")
path = require("path")
Utils = require("./utils")
Checkpoint = require("./checkpoint")

pos = (x, y) ->
  x: x
  y: y

getX = (num, w) ->
  return 0 if num is 0
  (if (num % w is 0) then w - 1 else (num % w) - 1)

equalPositions = (pos1, pos2) ->
  pos1.x is pos2.x and pos2.y is pos2.y

class Map
  constructor: (filepath) ->
    @isLoaded = false
    file.exists filepath, (exists) =>
      unless exists
        log.error "#{filepath} doesn't exist."
        return
      fs.readFile filepath, (err, file) =>
        json = JSON.parse(file.toString())
        @initMap json

  initMap: (thismap) ->
    @width = thismap.width
    @height = thismap.height
    @collisions = thismap.collisions
    @mobAreas = thismap.roamingAreas
    @chestAreas = thismap.chestAreas
    @staticChests = thismap.staticChests
    @staticEntities = thismap.staticEntities
    @isLoaded = true

    # zone groups
    @zoneWidth = 28
    @zoneHeight = 12
    @groupWidth = Math.floor(@width / @zoneWidth)
    @groupHeight = Math.floor(@height / @zoneHeight)
    @initConnectedGroups thismap.doors
    @initCheckpoints thismap.checkpoints
    @initPVPAreas thismap.pvpAreas
    @readyFunc() if @readyFunc

  ready: (@readyFunc) ->

  tileIndexToGridPosition: (tileNum) ->
    tileNum -= 1
    x: getX(tileNum + 1, @width)
    y: Math.floor(tileNum / @width)

  GridPositionToTileIndex: (x, y) ->
    (y * @width) + x + 1

  generateCollisionGrid: ->
    @grid = []
    if @isLoaded
      tileIndex = 0
      for i in [0...@height]
        @grid[i] = []
        for j in [0...@width]
          @grid[i][j] = if _.include(@collisions, tileIndex) then 1 else 0
          tileIndex += 1
      #XXX: for debugging only:
      #fs = require('fs')
      #fs.writeFileSync('./_colgrid.json', JSON.stringify(@grid))
      log.debug "Collision grid generated."

  isOutOfBounds: (x, y) ->
    x <= 0 or x >= @width or y <= 0 or y >= @height

  isColliding: (x, y) ->
    not @isOutOfBounds(x, y) and @grid[y][x] is 1

  isPVP: (x, y) ->
    !!(_.detect(@pvpAreas, (area) -> area.contains(x, y)))

  GroupIdToGroupPosition: (id) ->
    posArray = id.split("-")
    pos parseInt(posArray[0], 10), parseInt(posArray[1], 10)

  forEachGroup: (callback) ->
    for x in [0...@groupWidth]
      for y in [0...@groupHeight]
        callback "#{x}-#{y}"

  getGroupIdFromPosition: (x, y) ->
    w = @zoneWidth
    h = @zoneHeight
    gx = Math.floor((x - 1) / w)
    gy = Math.floor((y - 1) / h)
    gx + "-" + gy

  getAdjacentGroupPositions: (id) ->
    position = @GroupIdToGroupPosition(id)
    x = position.x
    y = position.y

    # surrounding groups
    list = [
      pos(x - 1, y - 1)
      pos(x, y - 1)
      pos(x + 1, y - 1)
      pos(x - 1, y)
      pos(x, y)
      pos(x + 1, y)
      pos(x - 1, y + 1)
      pos(x, y + 1)
      pos(x + 1, y + 1)
    ]

    # groups connected via doors
    _.each @connectedGroups[id], (position) ->
      # don't add a connected group if it's already part of the surrounding ones.
      list.push position  unless _.any(list, (groupPos) ->
        equalPositions groupPos, position
      )

    _.reject list, (pos) =>
      pos.x < 0 or pos.y < 0 or pos.x >= @groupWidth or pos.y >= @groupHeight


  forEachAdjacentGroup: (groupId, callback) ->
    if groupId
      _.each @getAdjacentGroupPositions(groupId), (pos) ->
        callback pos.x + "-" + pos.y

  initConnectedGroups: (doors) ->
    @connectedGroups = {}
    _.each doors, (door) =>
      groupId = @getGroupIdFromPosition(door.x, door.y)
      connectedGroupId = @getGroupIdFromPosition(door.tx, door.ty)
      connectedPosition = @GroupIdToGroupPosition(connectedGroupId)
      if groupId of @connectedGroups
        @connectedGroups[groupId].push connectedPosition
      else
        @connectedGroups[groupId] = [connectedPosition]

  initCheckpoints: (cpList) ->
    @checkpoints = {}
    @startingAreas = []
    _.each cpList, (cp) =>
      checkpoint = new Checkpoint(cp.id, cp.x, cp.y, cp.w, cp.h)
      @checkpoints[checkpoint.id] = checkpoint
      @startingAreas.push checkpoint  if cp.s is 1

  getCheckpoint: (id) ->
    @checkpoints[id]

  getRandomStartingPosition: ->
    nbAreas = _.size(@startingAreas)
    i = Utils.randomInt(0, nbAreas - 1)
    area = @startingAreas[i]
    area.getRandomPosition()

  initPVPAreas: (pvpList) ->
    @pvpAreas = []
    _.each pvpList, (pvp) =>
      pvpArea = new Area(pvp.id, pvp.x, pvp.y, pvp.w, pvp.h, null)
      @pvpAreas.push pvpArea

module.exports = Map
