$ = require("jquery")
_ = require("underscore")
BISON = require("bison")
log = require("./log")
Player = require("./player")
EntityFactory = require("./entityfactory")
Types = require("../common/types")

class GameClient
  constructor: (@host, @port) ->
    @connection = null
    @connected_callback = null
    @spawn_callback = null
    @movement_callback = null
    @fail_callback = null
    @notify_callback = null
    @handlers = []
    @handlers[Types.Messages.WELCOME] = @receiveWelcome
    @handlers[Types.Messages.MOVE] = @receiveMove
    @handlers[Types.Messages.LOOTMOVE] = @receiveLootMove
    @handlers[Types.Messages.ATTACK] = @receiveAttack
    @handlers[Types.Messages.SPAWN] = @receiveSpawn
    @handlers[Types.Messages.DESPAWN] = @receiveDespawn
    @handlers[Types.Messages.SPAWN_BATCH] = @receiveSpawnBatch
    @handlers[Types.Messages.HEALTH] = @receiveHealth
    @handlers[Types.Messages.CHAT] = @receiveChat
    @handlers[Types.Messages.EQUIP] = @receiveEquipItem
    @handlers[Types.Messages.DROP] = @receiveDrop
    @handlers[Types.Messages.TELEPORT] = @receiveTeleport
    @handlers[Types.Messages.DAMAGE] = @receiveDamage
    @handlers[Types.Messages.POPULATION] = @receivePopulation
    @handlers[Types.Messages.LIST] = @receiveList
    @handlers[Types.Messages.DESTROY] = @receiveDestroy
    @handlers[Types.Messages.KILL] = @receiveKill
    @handlers[Types.Messages.HP] = @receiveHitPoints
    @handlers[Types.Messages.BLINK] = @receiveBlink
    @handlers[Types.Messages.GUILDERROR] = @receiveGuildError
    @handlers[Types.Messages.GUILD] = @receiveGuild
    @handlers[Types.Messages.PVP] = @receivePVP
    @useBison = false
    @enable()

  enable: ->
    @isListening = true

  disable: ->
    @isListening = false

  connect: (dispatcherMode) ->
    url = "ws://" + @host + ":" + @port + "/"
    log.info "Trying to connect to server : " + url
    if window.MozWebSocket
      @connection = new MozWebSocket(url)
    else
      @connection = new WebSocket(url)
    if dispatcherMode
      @connection.onmessage = (e) =>
        reply = JSON.parse(e.data)
        if reply.status is "OK"
          @dispatched_callback reply.host, reply.port
        else if reply.status is "FULL"
          alert "BrowserQuest is currently at maximum player population. Please retry later."
        else
          alert "Unknown error while connecting to BrowserQuest."
        return
    else
      @connection.onopen = (e) =>
        log.info "Connected to server " + @host + ":" + @port
        return

      @connection.onmessage = (e) =>
        if e.data is "go"
          @connected_callback()  if @connected_callback
          return
        if e.data is "timeout"
          @isTimeout = true
          return
        if e.data is "invalidlogin" or e.data is "userexists" or e.data is "loggedin" or e.data is "invalidusername"
          @fail_callback e.data  if @fail_callback
          return
        @receiveMessage e.data
        return

      @connection.onerror = (e) ->
        log.error e, true

      @connection.onclose = =>
        log.debug "Connection closed"
        $("#container").addClass "error"
        if @disconnected_callback
          if @isTimeout
            @disconnected_callback "You have been disconnected for being inactive for too long"
          else
            @disconnected_callback "The connection to BrowserQuest has been lost"

  sendMessage: (json) ->
    data = undefined
    if @connection.readyState is 1
      if @useBison
        data = BISON.encode(json)
      else
        data = JSON.stringify(json)
      @connection.send data

  receiveMessage: (message) ->
    data = undefined
    action = undefined
    if @isListening
      if @useBison
        data = BISON.decode(message)
      else
        data = JSON.parse(message)
      log.debug "data: #{message}"
      if data instanceof Array
        if data[0] instanceof Array

          # Multiple actions received
          @receiveActionBatch data
        else

          # Only one action received
          @receiveAction data

  receiveAction: (data) ->
    action = data[0]
    if @handlers[action] and _.isFunction(@handlers[action])
      @handlers[action].call this, data
    else
      log.error "Unknown action: #{action}"

  receiveActionBatch: (actions) ->
    _.each actions, (action) =>
      @receiveAction action

  receiveWelcome: (data) ->
    id = data[1]
    name = data[2]
    x = data[3]
    y = data[4]
    hp = data[5]
    armor = data[6]
    weapon = data[7]
    avatar = data[8]
    weaponAvatar = data[9]
    experience = data[10]
    @welcome_callback id, name, x, y, hp, armor, weapon, avatar, weaponAvatar, experience if @welcome_callback

  receiveMove: (data) ->
    id = data[1]
    x = data[2]
    y = data[3]
    @move_callback id, x, y if @move_callback

  receiveLootMove: (data) ->
    id = data[1]
    item = data[2]
    @lootmove_callback id, item if @lootmove_callback

  receiveAttack: (data) ->
    attacker = data[1]
    target = data[2]
    @attack_callback attacker, target if @attack_callback

  receiveSpawn: (data) ->
    id = data[1]
    kind = data[2]
    x = data[3]
    y = data[4]
    if Types.isItem(kind)
      item = EntityFactory.createEntity(kind, id)
      @spawn_item_callback item, x, y  if @spawn_item_callback
    else if Types.isChest(kind)
      item = EntityFactory.createEntity(kind, id)
      @spawn_chest_callback item, x, y  if @spawn_chest_callback
    else
      name = undefined
      orientation = undefined
      target = undefined
      weapon = undefined
      armor = undefined
      level = undefined
      if Types.isPlayer(kind)
        name = data[5]
        orientation = data[6]
        armor = data[7]
        weapon = data[8]
        target = data[9]  if data.length > 9
      else if Types.isMob(kind)
        orientation = data[5]
        target = data[6]  if data.length > 6
      character = EntityFactory.createEntity(kind, id, name)
      if character instanceof Player
        character.weaponName = Types.getKindAsString(weapon)
        character.spriteName = Types.getKindAsString(armor)
      @spawn_character_callback character, x, y, orientation, target  if @spawn_character_callback

  receiveDespawn: (data) ->
    id = data[1]
    @despawn_callback id if @despawn_callback

  receiveHealth: (data) ->
    points = data[1]
    isRegen = false
    isRegen = true  if data[2]
    @health_callback points, isRegen if @health_callback

  receiveChat: (data) ->
    id = data[1]
    text = data[2]
    @chat_callback id, text if @chat_callback

  receiveEquipItem: (data) ->
    id = data[1]
    itemKind = data[2]
    @equip_callback id, itemKind if @equip_callback

  receiveDrop: (data) ->
    mobId = data[1]
    id = data[2]
    kind = data[3]
    item = EntityFactory.createEntity(kind, id)
    item.wasDropped = true
    item.playersInvolved = data[4]
    @drop_callback item, mobId if @drop_callback

  receiveTeleport: (data) ->
    id = data[1]
    x = data[2]
    y = data[3]
    @teleport_callback id, x, y if @teleport_callback

  receiveDamage: (data) ->
    id = data[1]
    dmg = data[2]
    hp = parseInt(data[3])
    maxHp = parseInt(data[4])
    @dmg_callback id, dmg, hp, maxHp if @dmg_callback

  receivePopulation: (data) ->
    worldPlayers = data[1]
    totalPlayers = data[2]
    @population_callback worldPlayers, totalPlayers if @population_callback

  receiveKill: (data) ->
    mobKind = data[1]
    level = data[2]
    exp = data[3]
    @kill_callback mobKind, level, exp if @kill_callback

  receiveList: (data) ->
    data.shift()
    @list_callback data if @list_callback

  receiveDestroy: (data) ->
    id = data[1]
    @destroy_callback id if @destroy_callback

  receiveHitPoints: (data) ->
    maxHp = data[1]
    @hp_callback maxHp if @hp_callback

  receiveBlink: (data) ->
    id = data[1]
    @blink_callback id if @blink_callback

  receivePVP: (data) ->
    pvp = data[1]
    @pvp_callback pvp if @pvp_callback

  receiveGuildError: (data) ->
    errorType = data[1]
    guildName = data[2]
    @guilderror_callback errorType, guildName if @guilderror_callback

  receiveGuild: (data) ->
    if (data[1] is Types.Messages.GUILDACTION.CONNECT) and @guildmemberconnect_callback
      @guildmemberconnect_callback data[2] #member name
    else if (data[1] is Types.Messages.GUILDACTION.DISCONNECT) and @guildmemberdisconnect_callback
      @guildmemberdisconnect_callback data[2] #member name
    else if (data[1] is Types.Messages.GUILDACTION.ONLINE) and @guildonlinemembers_callback
      data.splice 0, 2
      @guildonlinemembers_callback data #member names
    else if (data[1] is Types.Messages.GUILDACTION.CREATE) and @guildcreate_callback
      @guildcreate_callback data[2], data[3] #id, name
    else if (data[1] is Types.Messages.GUILDACTION.INVITE) and @guildinvite_callback
      @guildinvite_callback data[2], data[3], data[4] #id, name, invitor name
    else if (data[1] is Types.Messages.GUILDACTION.POPULATION) and @guildpopulation_callback
      @guildpopulation_callback data[2], data[3] #name, count
    else if (data[1] is Types.Messages.GUILDACTION.JOIN) and @guildjoin_callback
      @guildjoin_callback data[2], data[3], data[4], data[5] #name, (id, (guildId, guildName))
    else if (data[1] is Types.Messages.GUILDACTION.LEAVE) and @guildleave_callback
      @guildleave_callback data[2], data[3], data[4] #name, id, guildname
    else @guildtalk_callback data[2], data[3], data[4]  if (data[1] is Types.Messages.GUILDACTION.TALK) and @guildtalk_callback #name, id, message

  onDispatched: (callback) ->
    @dispatched_callback = callback

  onConnected: (callback) ->
    @connected_callback = callback

  onDisconnected: (callback) ->
    @disconnected_callback = callback

  onWelcome: (callback) ->
    @welcome_callback = callback

  onSpawnCharacter: (callback) ->
    @spawn_character_callback = callback

  onSpawnItem: (callback) ->
    @spawn_item_callback = callback

  onSpawnChest: (callback) ->
    @spawn_chest_callback = callback

  onDespawnEntity: (callback) ->
    @despawn_callback = callback

  onEntityMove: (callback) ->
    @move_callback = callback

  onEntityAttack: (callback) ->
    @attack_callback = callback

  onPlayerChangeHealth: (callback) ->
    @health_callback = callback

  onPlayerEquipItem: (callback) ->
    @equip_callback = callback

  onPlayerMoveToItem: (callback) ->
    @lootmove_callback = callback

  onPlayerTeleport: (callback) ->
    @teleport_callback = callback

  onChatMessage: (callback) ->
    @chat_callback = callback

  onDropItem: (callback) ->
    @drop_callback = callback

  onPlayerDamageMob: (callback) ->
    @dmg_callback = callback

  onPlayerKillMob: (callback) ->
    @kill_callback = callback

  onPopulationChange: (callback) ->
    @population_callback = callback

  onEntityList: (callback) ->
    @list_callback = callback

  onEntityDestroy: (callback) ->
    @destroy_callback = callback

  onPlayerChangeMaxHitPoints: (callback) ->
    @hp_callback = callback

  onItemBlink: (callback) ->
    @blink_callback = callback

  onPVPChange: (callback) ->
    @pvp_callback = callback

  onGuildError: (callback) ->
    @guilderror_callback = callback

  onGuildCreate: (callback) ->
    @guildcreate_callback = callback

  onGuildInvite: (callback) ->
    @guildinvite_callback = callback

  onGuildJoin: (callback) ->
    @guildjoin_callback = callback

  onGuildLeave: (callback) ->
    @guildleave_callback = callback

  onGuildTalk: (callback) ->
    @guildtalk_callback = callback

  onMemberConnect: (callback) ->
    @guildmemberconnect_callback = callback

  onMemberDisconnect: (callback) ->
    @guildmemberdisconnect_callback = callback

  onReceiveGuildMembers: (callback) ->
    @guildonlinemembers_callback = callback

  onGuildPopulation: (callback) ->
    @guildpopulation_callback = callback

  sendCreate: (player) ->
    @sendMessage [
      Types.Messages.CREATE
      player.name
      player.pw
      player.email
    ]

  sendLogin: (player) ->
    @sendMessage [
      Types.Messages.LOGIN
      player.name
      player.pw
    ]

  #  sendHello: function(player) {
  #if(player.hasGuild()){
  #	this.sendMessage([Types.Messages.HELLO,
  #					  player.name,
  #            player.pw,
  #           player.email,
  #					  Types.getKindFromString(player.getSpriteName()),
  #					  Types.getKindFromString(player.getWeaponName()),
  #					  player.guild.id, player.guild.name]);
  #}
  #else{
  #this.sendMessage([Types.Messages.HELLO,
  #player.name,
  #player.pw,
  #player.email,
  #Types.getKindFromString(player.getSpriteName()),
  #Types.getKindFromString(player.getWeaponName())]);
  #}
  # },

  sendMove: (x, y) ->
    @sendMessage [
      Types.Messages.MOVE
      x
      y
    ]

  sendLootMove: (item, x, y) ->
    @sendMessage [
      Types.Messages.LOOTMOVE
      x
      y
      item.id
    ]

  sendAggro: (mob) ->
    @sendMessage [
      Types.Messages.AGGRO
      mob.id
    ]

  sendAttack: (mob) ->
    @sendMessage [
      Types.Messages.ATTACK
      mob.id
    ]

  sendHit: (mob) ->
    @sendMessage [
      Types.Messages.HIT
      mob.id
    ]

  sendHurt: (mob) ->
    @sendMessage [
      Types.Messages.HURT
      mob.id
    ]

  sendChat: (text) ->
    @sendMessage [
      Types.Messages.CHAT
      text
    ]

  sendLoot: (item) ->
    @sendMessage [
      Types.Messages.LOOT
      item.id
    ]

  sendTeleport: (x, y) ->
    @sendMessage [
      Types.Messages.TELEPORT
      x
      y
    ]

  sendZone: ->
    @sendMessage [Types.Messages.ZONE]

  sendOpen: (chest) ->
    @sendMessage [
      Types.Messages.OPEN
      chest.id
    ]

  sendCheck: (id) ->
    @sendMessage [
      Types.Messages.CHECK
      id
    ]

  sendWho: (ids) ->
    ids.unshift Types.Messages.WHO
    @sendMessage ids

  sendNewGuild: (name) ->
    @sendMessage [
      Types.Messages.GUILD
      Types.Messages.GUILDACTION.CREATE
      name
    ]

  sendGuildInvite: (invitee) ->
    @sendMessage [
      Types.Messages.GUILD
      Types.Messages.GUILDACTION.INVITE
      invitee
    ]

  sendGuildInviteReply: (guild, answer) ->
    @sendMessage [
      Types.Messages.GUILD
      Types.Messages.GUILDACTION.JOIN
      guild
      answer
    ]

  talkToGuild: (message) ->
    @sendMessage [
      Types.Messages.GUILD
      Types.Messages.GUILDACTION.TALK
      message
    ]

  sendLeaveGuild: ->
    @sendMessage [
      Types.Messages.GUILD
      Types.Messages.GUILDACTION.LEAVE
    ]

module.exports = GameClient
