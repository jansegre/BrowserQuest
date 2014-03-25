_ = require("underscore")
Character = require("./character")
ChestArea = require("./chestarea")
Messages = require("./message")
MobArea = require("./mobarea")
Properties = require("./properties")
Utils = require("./utils")

class Mob extends Character
  constructor: (id, kind, x, y) ->
    super id, "mob", kind, x, y
    @updateHitPoints()
    @spawningX = x
    @spawningY = y
    @armorLevel = Properties.getArmorLevel(@kind)
    @weaponLevel = Properties.getWeaponLevel(@kind)
    @hatelist = []
    @respawnTimeout = null
    @returnTimeout = null
    @isDead = false
    @hateCount = 0
    @tankerlist = []

  destroy: ->
    @isDead = true
    @hatelist = []
    @tankerlist = []
    @clearTarget()
    @updateHitPoints()
    @resetPosition()
    @handleRespawn()

  #XXX: what is playerId used for??
  receiveDamage: (points, playerId) ->
    @hitPoints -= points

  hates: (playerId) ->
    _.any @hatelist, (obj) ->
      obj.id is playerId

  increaseHateFor: (playerId, points) ->
    if @hates(playerId)
      _.detect(@hatelist, (obj) ->
        obj.id is playerId
      ).hate += points
    else
      @hatelist.push
        id: playerId
        hate: points

    #
    #        log.debug("Hatelist : "+this.id);
    #        _.each(this.hatelist, function(obj) {
    #            log.debug(obj.id + " -> " + obj.hate);
    #        });
    if @returnTimeout
      # Prevent the mob from returning to its spawning position
      # since it has aggroed a new player
      clearTimeout @returnTimeout
      @returnTimeout = null

  addTanker: (playerId) ->
    k = 0
    for i in [0...@tankerlist.length]
      if @tankerlist[i].id is playerId
        @tankerlist[i].points++
        k = i
        break
    if k >= @tankerlist.length
      @tankerlist.push
        id: playerId
        points: 1

  getMainTankerId: ->
    mainTanker = null
    for i in [0...@tankerlist.length]
      unless mainTanker?
        mainTanker = @tankerlist[i]
        continue
      mainTanker = @tankerlist[i] if mainTanker.points < @tankerlist[i].points
    if mainTanker?
      mainTanker.id
    else
      null

  getHatedPlayerId: (hateRank) ->
    i = undefined
    playerId = undefined
    sorted = _.sortBy(@hatelist, (obj) -> obj.hate)
    size = _.size(@hatelist)
    if hateRank and hateRank <= size
      i = size - hateRank
    else
      if size is 1
        i = size - 1
      else
        @hateCount++
        if @hateCount > size * 1.3
          @hateCount = 0
          i = size - 1 - Utils.random(size - 1)
          log.info "CHANGE TARGET: " + i
        else
          return 0
    playerId = sorted[i].id  if sorted and sorted[i]
    playerId

  forgetPlayer: (playerId, duration) ->
    @hatelist = _.reject(@hatelist, (obj) -> obj.id is playerId)
    @tankerlist = _.reject(@tankerlist, (obj) -> obj.id is playerId)
    @returnToSpawningPosition duration  if @hatelist.length is 0

  forgetEveryone: ->
    @hatelist = []
    @tankerlist = []
    @returnToSpawningPosition 1

  drop: (item) ->
    new Messages.Drop(this, item)  if item

  handleRespawn: ->
    delay = 30000
    if @area and @area instanceof MobArea
      # Respawn inside the area if part of a MobArea
      @area.respawnMob this, delay
    else
      @area.removeFromArea this  if @area and @area instanceof ChestArea
      setTimeout (=> @respawnCallback() if @respawnCallback), delay

  onRespawn: (@respawnCallback) ->

  resetPosition: ->
    @setPosition @spawningX, @spawningY

  returnToSpawningPosition: (waitDuration) ->
    delay = waitDuration or 4000
    @clearTarget()
    @returnTimeout = setTimeout(=>
      @resetPosition()
      @move @x, @y
    , delay)

  onMove: (@moveCallback) ->

  move: (x, y) ->
    @setPosition x, y
    @moveCallback @ if @moveCallback

  updateHitPoints: ->
    @resetHitPoints Properties.getHitPoints(@kind)

  distanceToSpawningPoint: (x, y) ->
    Utils.distanceTo x, y, @spawningX, @spawningY

module.exports = Mob
