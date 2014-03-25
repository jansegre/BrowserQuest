Entity = require("./entity")
Messages = require("./message")
Utils = require("./utils")

class Character extends Entity
  constructor: (id, type, kind, x, y) ->
    super id, type, kind, x, y
    @orientation = Utils.randomOrientation()
    @attackers = {}
    @target = null
    return

  getState: ->
    basestate = @_getBaseState()
    state = []
    state.push @orientation
    state.push @target  if @target
    basestate.concat state

  resetHitPoints: (maxHitPoints) ->
    @maxHitPoints = maxHitPoints
    @hitPoints = @maxHitPoints
    return

  regenHealthBy: (value) ->
    hp = @hitPoints
    max = @maxHitPoints
    if hp < max
      if hp + value <= max
        @hitPoints += value
      else
        @hitPoints = max
    return

  hasFullHealth: ->
    @hitPoints is @maxHitPoints

  setTarget: (entity) ->
    @target = entity.id
    return

  clearTarget: ->
    @target = null
    return

  hasTarget: ->
    @target isnt null

  attack: ->
    new Messages.Attack(@id, @target)

  health: ->
    new Messages.Health(@hitPoints, false)

  regen: ->
    new Messages.Health(@hitPoints, true)

  addAttacker: (entity) ->
    @attackers[entity.id] = entity  if entity
    return

  removeAttacker: (entity) ->
    if entity and entity.id of @attackers
      delete @attackers[entity.id]

      log.debug @id + " REMOVED ATTACKER " + entity.id
    return

  forEachAttacker: (callback) ->
    id = 0

    while id < @attackers.length
      callback @attackers[id]
      id++
    return

module.exports = Character
