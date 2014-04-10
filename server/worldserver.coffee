_ = require("underscore")
Log = require("log")
Entity = require("./entity")
Character = require("./character")
Mob = require("./mob")
Map = require("./map")
Npc = require("./npc")
Player = require("./player")
Guild = require("./guild")
Item = require("./item")
MobArea = require("./mobarea")
ChestArea = require("./chestarea")
Chest = require("./chest")
Messages = require("./message")
Properties = require("./properties")
Utils = require("./utils")
Types = require("../common/types")

# ======= GAME SERVER ========
class World
  constructor: (@id, @maxPlayers, @server, @databaseHandler) ->
    @ups = 50
    @map = null
    @entities = {}
    @players = {}
    @guilds = {}
    @mobs = {}
    @attackers = {}
    @items = {}
    @equipping = {}
    @hurt = {}
    @npcs = {}
    @mobAreas = []
    @chestAreas = []
    @groups = {}
    @outgoingQueues = {}
    @itemCount = 0
    @playerCount = 0
    @zoneGroupsReady = false
    @onPlayerConnect (player) =>
      player.onRequestPosition =>
        if player.lastCheckpoint
          player.lastCheckpoint.getRandomPosition()
        else
          @map.getRandomStartingPosition()

    @onPlayerEnter (player) =>
      log.info player.name + "(" + player.connection._connection.remoteAddress + ") has joined " + @id + " in guild " + player.guildId
      @incrementPlayerCount()  unless player.hasEnteredGame

      # Number of players in this world
      @pushToPlayer player, new Messages.Population(@playerCount)
      if player.hasGuild()
        @pushToGuild player.getGuild(), new Messages.Guild(Types.Messages.GUILDACTION.CONNECT, player.name), player
        names = _.without(player.getGuild().memberNames(), player.name)
        @pushToPlayer player, new Messages.Guild(Types.Messages.GUILDACTION.ONLINE, names)  if names.length > 0
      @pushRelevantEntityListTo player
      move_callback = (x, y) =>
        log.debug player.name + " is moving to (" + x + ", " + y + ")."
        isPVP = @map.isPVP(x, y)
        player.flagPVP isPVP
        player.forEachAttacker (mob) =>
          if mob.target is null
            player.removeAttacker mob
            return
          target = @getEntityById(mob.target)
          if target
            pos = @findPositionNextTo(mob, target)
            if mob.distanceToSpawningPoint(pos.x, pos.y) > 50
              mob.clearTarget()
              mob.forgetEveryone()
              player.removeAttacker mob
            else
              @moveEntity mob, pos.x, pos.y

      player.onMove move_callback
      player.onLootMove move_callback
      player.onZone =>
        hasChangedGroups = @handleEntityGroupMembership(player)
        if hasChangedGroups
          @pushToPreviousGroups player, new Messages.Destroy(player)
          @pushRelevantEntityListTo player

      player.onBroadcast (message, ignoreSelf) =>
        @pushToAdjacentGroups player.group, message, (if ignoreSelf then player.id else null)

      player.onBroadcastToZone (message, ignoreSelf) =>
        @pushToGroup player.group, message, (if ignoreSelf then player.id else null)

      player.onExit =>
        log.info player.name + " has left the game."
        @pushToGuild player.getGuild(), new Messages.Guild(Types.Messages.GUILDACTION.DISCONNECT, player.name), player  if player.hasGuild()
        @removePlayer player
        @decrementPlayerCount()
        @removed_callback() if @removed_callback

      @added_callback() if @added_callback

    # Called when an entity is attacked by another entity
    @onEntityAttack (attacker) =>
      target = @getEntityById(attacker.target)
      if target and attacker.type is "mob"
        pos = @findPositionNextTo(attacker, target)
        @moveEntity attacker, pos.x, pos.y

    @onRegenTick =>
      @forEachCharacter (character) =>
        unless character.hasFullHealth()
          character.regenHealthBy Math.floor(character.maxHitPoints / 25)
          @pushToPlayer character, character.regen() if character.type is "player"

  run: (mapFilePath) ->
    @map = new Map(mapFilePath)
    @map.ready =>
      @initZoneGroups()
      @map.generateCollisionGrid()

      # Populate all mob "roaming" areas
      _.each @map.mobAreas, (a) =>
        area = new MobArea(a.id, a.nb, a.type, a.x, a.y, a.width, a.height, @)
        area.spawnMobs()
        area.onEmpty @handleEmptyMobArea.bind(@, area)
        @mobAreas.push area

      # Create all chest areas
      _.each @map.chestAreas, (a) =>
        area = new ChestArea(a.id, a.x, a.y, a.w, a.h, a.tx, a.ty, a.i, @)
        @chestAreas.push area
        area.onEmpty @handleEmptyChestArea.bind(@, area)

      # Spawn static chests
      _.each @map.staticChests, (chest) =>
        c = @createChest(chest.x, chest.y, chest.i)
        @addStaticItem c

      # Spawn static entities
      @spawnStaticEntities()

      # Set maximum number of entities contained in each chest area
      _.each @chestAreas, (area) ->
        area.setNumberOfEntities area.entities.length

    regenCount = @ups * 2
    updateCount = 0
    setInterval (=>
      @processGroups()
      @processQueues()
      if updateCount < regenCount
        updateCount += 1
      else
        @regen_callback()  if @regen_callback
        updateCount = 0
    ), 1000 / @ups

    log.info "" + @id + " created (capacity: " + @maxPlayers + " players)."

  setUpdatesPerSecond: (ups) ->
    @ups = ups
    return

  onInit: (@init_callback) ->

  onPlayerConnect: (@connect_callback) ->

  onPlayerEnter: (@enter_callback) ->

  onPlayerAdded: (@added_callback) ->

  onPlayerRemoved: (@removed_callback) ->

  onRegenTick: (@regen_callback) ->

  pushRelevantEntityListTo: (player) ->
    entities = undefined
    if player and (player.group of @groups)
      entities = _.keys(@groups[player.group].entities)
      entities = _.reject(entities, (id) -> id is player.id)
      entities = _.map(entities, (id) -> parseInt id, 10)
      @pushToPlayer player, new Messages.List(entities)  if entities

  pushSpawnsToPlayer: (player, ids) ->
    _.each ids, (id) =>
      entity = @getEntityById(id)
      @pushToPlayer player, new Messages.Spawn(entity)  if entity

    log.debug "Pushed " + _.size(ids) + " new spawns to " + player.id

  pushToPlayer: (player, message) ->
    if player and player.id of @outgoingQueues
      @outgoingQueues[player.id].push message.serialize()
    else
      log.error "pushToPlayer: player was undefined"

  pushToGuild: (guild, message, except) ->
    if guild
      if typeof except is "undefined"
        guild.forEachMember (player, id) =>
          @pushToPlayer @getEntityById(id), message
      else
        guild.forEachMember (player, id) =>
          @pushToPlayer @getEntityById(id), message  if parseInt(id, 10) isnt except.id
    else
      log.error "pushToGuild: guild was undefined"

  pushToGroup: (groupId, message, ignoredPlayer) ->
    group = @groups[groupId]
    if group
      _.each group.players, (playerId) =>
        @pushToPlayer @getEntityById(playerId), message  unless playerId is ignoredPlayer

    else
      log.error "groupId: " + groupId + " is not a valid group"

  pushToAdjacentGroups: (groupId, message, ignoredPlayer) ->
    @map.forEachAdjacentGroup groupId, (id) =>
      @pushToGroup id, message, ignoredPlayer

  pushToPreviousGroups: (player, message) ->
    # Push this message to all groups which are not going to be updated anymore,
    # since the player left them.
    _.each player.recentlyLeftGroups, (id) =>
      @pushToGroup id, message
    player.recentlyLeftGroups = []

  pushBroadcast: (message, ignoredPlayer) ->
    for id of @outgoingQueues
      @outgoingQueues[id].push message.serialize()  unless id is ignoredPlayer

  processQueues: ->
    connection = undefined
    for id of @outgoingQueues
      if @outgoingQueues[id].length > 0
        connection = @server.getConnection(id)
        if connection?
          connection.send @outgoingQueues[id]
          @outgoingQueues[id] = []
        else
          log.error "Connection id:#{id} was lost..."

  addEntity: (entity) ->
    @entities[entity.id] = entity
    @handleEntityGroupMembership entity

  removeEntity: (entity) ->
    delete @entities[entity.id]  if entity.id of @entities
    delete @mobs[entity.id]  if entity.id of @mobs
    delete @items[entity.id]  if entity.id of @items
    if entity.type is "mob"
      @clearMobAggroLink entity
      @clearMobHateLinks entity
    entity.destroy()
    @removeFromGroups entity
    log.debug "Removed " + Types.getKindAsString(entity.kind) + " : " + entity.id

  joinGuild: (player, guildId, answer) ->
    if typeof @guilds[guildId] is "undefined"
      @pushToPlayer player, new Messages.GuildError(Types.Messages.GUILDERRORTYPE.DOESNOTEXIST, guildId)

    ##guildupdate (guildrules)
    else
      formerGuildId = player.guildId  if player.hasGuild()
      res = @guilds[guildId].addMember(player, answer)
      @guilds[formerGuildId].removeMember player  if res isnt false and typeof formerGuildId isnt "undefined"
      return res
    false

  reloadGuild: (guildId, guildName) ->
    res = false
    lastItem = 0
    res = guildId  if @guilds[guildId].name is guildName  if typeof @guilds[guildId] isnt "undefined"
    if res is false
      _.every @guilds, (guild, key) ->
        if guild.name is guildName
          res = parseInt(key, 10)
          false
        else
          lastItem = key
          true

    if res is false #first connected after reboot.
      guildId = parseInt(lastItem, 10) + 1  if typeof @guilds[guildId] isnt "undefined"
      @guilds[guildId] = new Guild(guildId, guildName, this)
      res = guildId
    res

  addGuild: (guildName) ->
    res = true
    id = 0 #an ID here
    res = _.every @guilds, (guild, key) ->
      id = parseInt(key, 10) + 1
      guild.name isnt guildName
    if res
      @guilds[id] = new Guild(id, guildName, this)
      res = id
    res

  addPlayer: (player, guildId) ->
    @addEntity player
    @players[player.id] = player
    @outgoingQueues[player.id] = []
    res = true
    res = @joinGuild(player, guildId) if guildId?
    res

  removePlayer: (player) ->
    player.broadcast player.despawn()
    @removeEntity player
    player.getGuild().removeMember player if player.hasGuild()
    delete @players[player.id]
    delete @outgoingQueues[player.id]

  loggedInPlayer: (name) ->
    for id of @players
      return true unless @players[id].isDead if @players[id].name is name
    false

  addMob: (mob) ->
    @addEntity mob
    @mobs[mob.id] = mob

  addNpc: (kind, x, y) ->
    npc = new Npc("8" + x + "" + y, kind, x, y)
    @addEntity npc
    @npcs[npc.id] = npc
    npc

  addItem: (item) ->
    @addEntity item
    @items[item.id] = item
    item

  createItem: (kind, x, y) ->
    id = "9" + @itemCount++
    item = null
    if kind is Types.Entities.CHEST
      item = new Chest(id, x, y)
    else
      item = new Item(id, kind, x, y)
    item

  createChest: (x, y, items) ->
    chest = @createItem(Types.Entities.CHEST, x, y)
    chest.setItems items
    chest

  addStaticItem: (item) ->
    item.isStatic = true
    item.onRespawn @addStaticItem.bind(this, item)
    @addItem item

  addItemFromChest: (kind, x, y) ->
    item = @createItem(kind, x, y)
    item.isFromChest = true
    @addItem item

  ###
  The mob will no longer be registered as an attacker of its current target.
  ###
  clearMobAggroLink: (mob) ->
    player = null
    if mob.target
      player = @getEntityById(mob.target)
      player.removeAttacker mob  if player

  clearMobHateLinks: (mob) ->
    if mob
      _.each mob.hatelist, (obj) =>
        player = @getEntityById(obj.id)
        player.removeHater mob  if player

  forEachEntity: (callback) ->
    for id of @entities
      callback @entities[id]

  forEachPlayer: (callback) ->
    for id of @players
      callback @players[id]

  forEachMob: (callback) ->
    for id of @mobs
      callback @mobs[id]

  forEachCharacter: (callback) ->
    @forEachPlayer callback
    @forEachMob callback

  handleMobHate: (mobId, playerId, hatePoints) ->
    mob = @getEntityById(mobId)
    player = @getEntityById(playerId)
    mostHated = undefined
    if player and mob
      mob.increaseHateFor playerId, hatePoints
      player.addHater mob
      # only choose a target if still alive
      @chooseMobTarget mob  if mob.hitPoints > 0

  chooseMobTarget: (mob, hateRank) ->
    player = @getEntityById(mob.getHatedPlayerId(hateRank))

    # If the mob is not already attacking the player, create an attack link between them.
    if player and (mob.id not of player.attackers)
      @clearMobAggroLink mob
      player.addAttacker mob
      mob.setTarget player
      @broadcastAttacker mob
      log.debug mob.id + " is now attacking " + player.id

  onEntityAttack: (@attack_callback) ->

  getEntityById: (id) ->
    if id of @entities
      @entities[id]
    else
      log.error "Unknown entity : " + id

  getPlayerCount: ->
    count = 0
    for p of @players
      count += 1  if @players.hasOwnProperty(p)
    count

  broadcastAttacker: (character) ->
    @pushToAdjacentGroups character.group, character.attack(), character.id  if character
    @attack_callback character  if @attack_callback

  handleHurtEntity: (entity, attacker, damage) ->
    # A player is only aware of his own hitpoints
    @pushToPlayer entity, entity.health()  if entity.type is "player"

    # Let the mob's attacker (player) know how much damage was inflicted
    @pushToPlayer attacker, new Messages.Damage(entity, damage, entity.hitPoints, entity.maxHitPoints)  if entity.type is "mob"

    # If the entity is about to die
    if entity.hitPoints <= 0
      if entity.type is "mob"
        mob = entity
        item = @getDroppedItem(mob)
        mainTanker = @getEntityById(mob.getMainTankerId())
        if mainTanker and mainTanker instanceof Player
          mainTanker.incExp Types.getMobExp(mob.kind)
          @pushToPlayer mainTanker, new Messages.Kill(mob, mainTanker.level, mainTanker.experience)
        else
          attacker.incExp Types.getMobExp(mob.kind)
          @pushToPlayer attacker, new Messages.Kill(mob, attacker.level, attacker.experience)
        @pushToAdjacentGroups mob.group, mob.despawn() # Despawn must be enqueued before the item drop
        if item
          @pushToAdjacentGroups mob.group, mob.drop(item)
          @handleItemDespawn item
      if entity.type is "player"
        @handlePlayerVanish entity
        @pushToAdjacentGroups entity.group, entity.despawn()
      @removeEntity entity

  despawn: (entity) ->
    @pushToAdjacentGroups entity.group, entity.despawn()
    @removeEntity entity if entity.id of @entities

  spawnStaticEntities: ->
    count = 0
    _.each @map.staticEntities, (kindName, tid) =>
      kind = Types.getKindFromString(kindName)
      pos = @map.tileIndexToGridPosition(tid)
      @addNpc kind, pos.x + 1, pos.y  if Types.isNpc(kind)
      if Types.isMob(kind)
        mob = new Mob("7" + kind + count++, kind, pos.x + 1, pos.y)
        mob.onRespawn =>
          mob.isDead = false
          @addMob mob
          mob.area.addToArea mob  if mob.area and mob.area instanceof ChestArea

        mob.onMove @onMobMoveCallback.bind(@)
        @addMob mob
        @tryAddingMobToChestArea mob
      @addStaticItem @createItem(kind, pos.x + 1, pos.y)  if Types.isItem(kind)

  isValidPosition: (x, y) ->
    @map? and _.isNumber(x) and _.isNumber(y) and not @map.isOutOfBounds(x, y) and not @map.isColliding(x, y)

  handlePlayerVanish: (player) ->
    previousAttackers = []

    # When a player dies or teleports, all of his attackers go and attack their second most hated player.
    player.forEachAttacker (mob) =>
      previousAttackers.push mob
      @chooseMobTarget mob, 2

    _.each previousAttackers, (mob) ->
      player.removeAttacker mob
      mob.clearTarget()
      mob.forgetPlayer player.id, 1000

    @handleEntityGroupMembership player

  setPlayerCount: (@playerCount) ->

  incrementPlayerCount: ->
    @setPlayerCount @playerCount + 1

  decrementPlayerCount: ->
    @setPlayerCount @playerCount - 1 if @playerCount > 0

  getDroppedItem: (mob) ->
    kind = Types.getKindAsString(mob.kind)
    drops = Properties[kind].drops
    v = Utils.random(100)
    p = 0
    item = null
    for itemName of drops
      percentage = drops[itemName]
      p += percentage
      if v <= p
        item = @addItem(@createItem(Types.getKindFromString(itemName), mob.x, mob.y))
        break
    item

  onMobMoveCallback: (mob) ->
    @pushToAdjacentGroups mob.group, new Messages.Move(mob)
    @handleEntityGroupMembership mob

  findPositionNextTo: (entity, target) ->
    valid = false
    pos = undefined
    until valid
      pos = entity.getPositionNextTo(target)
      valid = @isValidPosition(pos.x, pos.y)
    pos

  initZoneGroups: ->
    @map.forEachGroup (id) =>
      @groups[id] =
        entities: {}
        players: []
        incoming: []

    @zoneGroupsReady = true

  removeFromGroups: (entity) ->
    oldGroups = []
    if entity and entity.group
      group = @groups[entity.group]

      if entity instanceof Player
        group.players = _.reject(group.players, (id) -> id is entity.id)

      @map.forEachAdjacentGroup entity.group, (id) =>
        if entity.id of @groups[id].entities
          delete @groups[id].entities[entity.id]
          oldGroups.push id

      entity.group = null
    oldGroups

  ###
  Registers an entity as "incoming" into several groups, meaning that it just entered them.
  All players inside these groups will receive a Spawn message when WorldServer.processGroups is called.
  ###
  addAsIncomingToGroup: (entity, groupId) ->
    isChest = entity and entity instanceof Chest
    isItem = entity and entity instanceof Item
    isDroppedItem = entity and isItem and not entity.isStatic and not entity.isFromChest
    if entity and groupId
      @map.forEachAdjacentGroup groupId, (id) =>
        group = @groups[id]

        #  Items dropped off of mobs are handled differently via DROP messages. See handleHurtEntity.
        group.incoming.push entity  if not _.include(group.entities, entity.id) and (not isItem or isChest or (isItem and not isDroppedItem))  if group

  addToGroup: (entity, groupId) ->
    newGroups = []
    if entity and groupId and (groupId of @groups)
      @map.forEachAdjacentGroup groupId, (id) =>
        @groups[id].entities[entity.id] = entity
        newGroups.push id

      entity.group = groupId
      @groups[groupId].players.push entity.id  if entity instanceof Player
    newGroups

  logGroupPlayers: (groupId) ->
    log.debug "Players inside group " + groupId + ":"
    _.each @groups[groupId].players, (id) ->
      log.debug "- player " + id

  handleEntityGroupMembership: (entity) ->
    hasChangedGroups = false
    if entity
      groupId = @map.getGroupIdFromPosition(entity.x, entity.y)
      if not entity.group or (entity.group and entity.group isnt groupId)
        hasChangedGroups = true
        @addAsIncomingToGroup entity, groupId
        oldGroups = @removeFromGroups(entity)
        newGroups = @addToGroup(entity, groupId)
        if _.size(oldGroups) > 0
          entity.recentlyLeftGroups = _.difference(oldGroups, newGroups)
          log.debug "group diff: " + entity.recentlyLeftGroups
    hasChangedGroups

  processGroups: ->
    if @zoneGroupsReady
      @map.forEachGroup (id) =>
        spawns = []
        if @groups[id].incoming.length > 0
          spawns = _.each @groups[id].incoming, (entity) =>
            if entity instanceof Player
              @pushToGroup id, new Messages.Spawn(entity), entity.id
            else
              @pushToGroup id, new Messages.Spawn(entity)
          @groups[id].incoming = []

  moveEntity: (entity, x, y) ->
    if entity?
      entity.setPosition x, y
      @handleEntityGroupMembership entity

  handleItemDespawn: (item) ->
    if item
      item.handleDespawn
        beforeBlinkDelay: 10000
        blinkCallback: =>
          @pushToAdjacentGroups item.group, new Messages.Blink(item)
        blinkingDuration: 4000
        despawnCallback: =>
          @pushToAdjacentGroups item.group, new Messages.Destroy(item)
          @removeEntity item

  handleEmptyMobArea: (area) ->

  handleEmptyChestArea: (area) ->
    if area
      chest = @addItem(@createChest(area.chestX, area.chestY, area.items))
      @handleItemDespawn chest

  handleOpenedChest: (chest, player) ->
    @pushToAdjacentGroups chest.group, chest.despawn()
    @removeEntity chest
    kind = chest.getRandomItem()
    if kind
      item = @addItemFromChest(kind, chest.x, chest.y)
      @handleItemDespawn item

  getPlayerByName: (name) ->
    for id of @players
      return @players[id]  if @players[id].name is name
    null

  tryAddingMobToChestArea: (mob) ->
    _.each @chestAreas, (area) ->
      area.addToArea mob  if area.contains(mob)

  updatePopulation: (totalPlayers) ->
    @pushBroadcast new Messages.Population(@playerCount, (if totalPlayers then totalPlayers else @playerCount))

module.exports = World
