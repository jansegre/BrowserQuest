###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

_ = require("underscore")
Types = require("../common/types")

class Message

Messages = {}

class Messages.Spawn
  constructor: (@entity) ->

  serialize: ->
    spawn = [Types.Messages.SPAWN]
    spawn.concat @entity.getState()

class Messages.Despawn
  constructor: (@entityId) ->

  serialize: ->
    [
      Types.Messages.DESPAWN
      this.entityId
    ]

class Messages.Move
  constructor: (@entity) ->

  serialize: ->
    [
      Types.Messages.MOVE
      @entity.id
      @entity.x
      @entity.y
    ]

class Messages.LootMove
  constructor: (@entity, @item) ->

  serialize: ->
    [
      Types.Messages.LOOTMOVE
      @entity.id
      @item.id
    ]

class Messages.Attack
  constructor: (attackerId, targetId) ->
    @attackerId = attackerId
    @targetId = targetId
    return

  serialize: ->
    [
      Types.Messages.ATTACK
      this.attackerId
      this.targetId
    ]

class Messages.Health
  constructor: (@points, @isRegen) ->

  serialize: ->
    health = [
      Types.Messages.HEALTH
      this.points
    ]
    #XXX: is this logic supposed to be here???
    health.push 1 if @isRegen
    health

class Messages.HitPoints
  constructor: (@maxHitPoints) ->

  serialize: ->
    [
      Types.Messages.HP
      this.maxHitPoints
    ]

class Messages.EquipItem
  constructor: (@player, @itemKind) ->

  serialize: ->
    [
      Types.Messages.EQUIP
      this.playerId
      this.itemKind
    ]

class Messages.Drop
  constructor: (@mob, @item) ->

  serialize: ->
    [
      Types.Messages.DROP
      @mob.id
      @item.id
      @item.kind
      _.pluck(@mob.hatelist, "id")
    ]

class Messages.Chat
  constructor: (player, @message) ->
    @playerId = player.id

  serialize: ->
    [
      Types.Messages.CHAT
      this.playerId
      this.message
    ]

class Messages.Teleport
  constructor: (@entity) ->

  serialize: ->
    [
      Types.Messages.TELEPORT
      @entity.id
      @entity.x
      @entity.y
    ]

class Messages.Damage
  constructor: (@entity, @points, @hp, @maxHp) ->

  serialize: ->
    [
      Types.Messages.DAMAGE
      @entity.id
      this.points
      this.hp
      this.maxHitPoints
    ]

class Messages.Population
  constructor: (@world, @total) ->

  serialize: ->
    [
      Types.Messages.POPULATION
      this.world
      this.total
    ]

class Messages.Kill
  constructor: (@mob, @level, @exp) ->

  serialize: ->
    [
      Types.Messages.KILL
      @mob.kind
      this.level
      this.exp
    ]

class Messages.List
  constructor: (@ids) ->

  serialize: ->
    list = @ids
    list.unshift Types.Messages.LIST
    list

class Messages.Destroy
  constructor: (@entity) ->

  serialize: ->
    [
      Types.Messages.DESTROY
      @entity.id
    ]

class Messages.Blink
  constructor: (@item) ->

  serialize: ->
    [
      Types.Messages.BLINK
      @item.id
    ]

class Messages.GuildError
  constructor: (@errorType, @guildName) ->

  serialize: ->
    [
      Types.Messages.GUILDERROR
      this.errorType
      this.guildName
    ]

class Messages.Guild
  constructor: (@action, @info) ->

  serialize: ->
    [
      Types.Messages.GUILD
      this.action
    ].concat @info

class Messages.PVP
  constructor: (@isPVP) ->

  serialize: ->
    [
      Types.Messages.PVP
      this.isPVP
    ]

module.exports = Messages
