###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

Messages = require("./message")
Utils = require("./utils")

class Entity
  constructor: (id, @type, @kind, @x, @y) ->
    @id = parseInt(id, 10)

  destroy: ->

  _getBaseState: ->
    [
      parseInt(@id, 10)
      @kind
      @x
      @y
    ]

  getState: -> @_getBaseState()

  spawn: -> new Messages.Spawn(@)

  despawn: -> new Messages.Despawn(@id)

  setPosition: (@x, @y) ->

  getPositionNextTo: (entity) ->
    pos = null
    if entity
      pos = {}

      # This is a quick & dirty way to give mobs a random position
      # close to another entity.
      r = Utils.random(4)
      pos.x = entity.x
      pos.y = entity.y
      pos.y -= 1  if r is 0
      pos.y += 1  if r is 1
      pos.x -= 1  if r is 2
      pos.x += 1  if r is 3
    pos

module.exports = Entity
