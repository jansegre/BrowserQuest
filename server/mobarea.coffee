_ = require("underscore")
Area = require("./area")
Types = require("../common/types")
Utils = require("./utils")

class MobArea extends Area
  constructor: (id, @nb, @kind, x, y, width, height, world) ->
    super id, x, y, width, height, world
    @respawns = []
    @setNumberOfEntities @nb
    # Enable random roaming for monsters
    # (comment this out to disable roaming)
    @initRoaming()

  spawnMobs: ->
    for i in [0...@nb]
      @addToArea @_createMobInsideArea()

  _createMobInsideArea: ->
    k = Types.getKindFromString(@kind)
    Mob = require("./mob")
    pos = @_getRandomPositionInsideArea()
    mob = new Mob("1" + @id + "" + k + "" + @entities.length, k, pos.x, pos.y)
    mob.onMove @world.onMobMoveCallback.bind(@world)
    mob

  respawnMob: (mob, delay) ->
    @removeFromArea mob
    setTimeout (=>
      pos = @_getRandomPositionInsideArea()
      mob.x = pos.x
      mob.y = pos.y
      mob.isDead = false
      @addToArea mob
      @world.addMob mob
    ), delay

  initRoaming: (mob) ->
    setInterval (=>
      _.each @entities, (mob) =>
        canRoam = (Utils.random(20) is 1)
        pos = undefined
        if canRoam
          if not mob.hasTarget() and not mob.isDead
            pos = @_getRandomPositionInsideArea()
            mob.move pos.x, pos.y
    ), 500

  createReward: ->
    pos = @_getRandomPositionInsideArea()
    x: pos.x
    y: pos.y
    kind: Types.Entities.CHEST

module.exports = MobArea
