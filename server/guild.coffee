_ = require("underscore")
Messages = require("./message")
Utils = require("./utils")
check = require("./format").check
Types = require("../common/types")

class Guild
  constructor: (@id, @name, @server) ->
    @members = {} #playerid:playername
    @sentInvites = {} #time

  #TODO have a history variable to advise users of what happened while they were offline ? wait for DB…
  #with DB also update structure to make members permanent
  addMember: (player, reply) ->
    if typeof @members[player.id] isnt "undefined"
      log.error "Add to guild: player conflict (" + player.id + " already exists)"
      @deleteInvite player.id
      false
    else

      #When guildRules is created, use here (or in invite)
      proceed = true
      if typeof reply isnt "undefined"
        proceed = @checkInvite(player) and reply
        if reply is false
          @server.pushToGuild this, new Messages.Guild(Types.Messages.GUILDACTION.JOIN, [
            player.name
            false
          ]), player
          @deleteInvite player.id
          return false
      if proceed
        @members[player.id] = player.name
        player.setGuildId @id
        @server.pushToGuild this, new Messages.Guild(Types.Messages.GUILDACTION.POPULATION, [
          this.name
          @onlineMemberCount()
        ])
        if typeof reply isnt "undefined"
          @server.pushToGuild this, new Messages.Guild(Types.Messages.GUILDACTION.JOIN, [
            player.name
            player.id
            this.id
            this.name
          ])
          @deleteInvite player.id
      player.id

  invite: (invitee, invitor) ->
    if typeof @members[invitee.id] isnt "undefined"
      @server.pushToPlayer invitor, new Messages.GuildError(Types.Messages.GUILDERRORTYPE.BADINVITE, invitee.name)
    else
      @sentInvites[invitee.id] = new Date().valueOf()
      @server.pushToPlayer invitee, new Messages.Guild(Types.Messages.GUILDACTION.INVITE, [
        this.id
        this.name
        invitor.name
      ])

  deleteInvite: (inviteeId) ->
    delete @sentInvites[inviteeId]

  checkInvite: (invitee) ->
    now = new Date().valueOf()
    _.each @sentInvites, (time, id) =>
      if now - time > 600000
        belated = @server.getEntityById(id)
        @deleteInvite id
        @server.pushToGuild @, new Messages.Guild(Types.Messages.GUILDACTION.JOIN, belated.name), belated

    typeof @sentInvites[invitee.id] isnt "undefined"

  removeMember: (player) ->
    if @members[player.id]?
      delete @members[player.id]

      @server.pushToGuild this, new Messages.Guild(Types.Messages.GUILDACTION.POPULATION, [
        this.name
        @onlineMemberCount()
      ])
      true
    else
      log.error "Remove from guild: player conflict (" + id + " does not exist)"
      false

  forEachMember: (iterator) ->
    _.each @members, iterator

  memberNames: ->
    _.map @members, (name) -> name


  onlineMemberCount: ->
    _.size @members

module.exports = Guild
