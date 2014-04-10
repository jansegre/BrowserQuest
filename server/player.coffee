bcrypt = require("bcrypt")
_ = require("underscore")
check = require("./format").check
Character = require("./character")
Chest = require("./chest")
Messages = require("./message")
Utils = require("./utils")
Properties = require("./properties")
Formulas = require("./formulas")
Types = require("../common/types")

class Player extends Character
  constructor: (@connection, @server, @databaseHandler) ->
    super @connection.id, "player", Types.Entities.WARRIOR, 0, 0, ""
    @hasEnteredGame = false
    @isDead = false
    @haters = {}
    @lastCheckpoint = null
    @disconnectTimeout = null
    @pvpFlag = false
    @bannedTime = 0
    @banUseTime = 0
    @experience = 0
    @level = 0
    @lastWorldChatMinutes = 99
    @inventory = []
    @inventoryCount = []
    @achievement = []
    @chatBanEndTime = 0
    @connection.listen (message) =>
      action = parseInt(message[0])
      log.debug "Received: #{message}"

      unless check(message)
        @connection.close "Invalid #{Types.getMessageTypeAsString(action)} message format: #{message}"
        return

      if not @hasEnteredGame and action isnt Types.Messages.CREATE and action isnt Types.Messages.LOGIN # CREATE or LOGIN must be the first message
        @connection.close "Invalid handshake message: #{message}"
        return

      if @hasEnteredGame and not @isDead and (action is Types.Messages.CREATE or action is Types.Messages.LOGIN) # CREATE/LOGIN can be sent only once
        @connection.close "Cannot initiate handshake twice: #{message}"
        return

      @resetTimeout()
      if action is Types.Messages.CREATE or action is Types.Messages.LOGIN
        name = Utils.sanitize(message[1])
        pw = Utils.sanitize(message[2])

        # Always ensure that the name is not longer than a maximum length.
        # (also enforced by the maxlength attribute of the name input element).
        @name = name.substr(0, 12).trim()

        # Validate the username
        unless @checkName(@name)
          @connection.sendUTF8 "invalidusername"
          @connection.close "Invalid name #{@name}"
          return

        @pw = pw.substr(0, 15)
        if action is Types.Messages.CREATE
          bcrypt.genSalt 10, (err, salt) =>
            bcrypt.hash @pw, salt, (err, hash) =>
              log.info "CREATE: #{@name}"
              @email = Utils.sanitize(message[3])
              @pw = hash
              @databaseHandler.createPlayer @

        else
          log.info "LOGIN: #{@name}"
          if @server.loggedInPlayer(@name)
            @connection.sendUTF8 "loggedin"
            @connection.close "Already logged in #{@name}"
          @databaseHandler.checkBan @
          @databaseHandler.loadPlayer @

      # @kind = Types.Entities.WARRIOR;
      # @equipArmor(message[2]);
      # @equipWeapon(message[3]);
      # if(typeof message[4] !== 'undefined') {
      #     var aGuildId = @server.reloadGuild(message[4],message[5]);
      #     if( aGuildId !== message[4]) {
      #         @server.pushToPlayer(@, new Messages.GuildError(Types.Messages.GUILDERRORTYPE.IDWARNING,message[5]));
      #     }
      # }
      # @orientation = Utils.randomOrientation();
      # @updateHitPoints();
      # @updatePosition();
      #
      # @server.addPlayer(@, aGuildId);
      # @server.enter_callback(@);
      #
      # @send([Types.Messages.WELCOME, @id, @name, @x, @y, @hitPoints]);
      # @hasEnteredGame = true;
      # @isDead = false;
      else if action is Types.Messages.WHO
        log.info "WHO: #{@name}"
        message.shift()
        @server.pushSpawnsToPlayer @, message

      else if action is Types.Messages.ZONE
        log.info "ZONE: #{@name}"
        @zone_callback()

      else if action is Types.Messages.CHAT
        msg = Utils.sanitize(message[1])
        log.info "CHAT: #{@name}: #{msg}"

        # Sanitized messages may become empty. No need to broadcast empty chat messages.
        if msg and msg isnt ""
          msg = msg.substr(0, 60) # Enforce maxlength of chat input
          # CHAD COMMAND HANDLING IN ASKY VERSION HAPPENS HERE!
          @broadcastToZone new Messages.Chat(@, msg), false

      else if action is Types.Messages.MOVE
        log.info "MOVE: #{@name}(#{message[1]}, #{message[2]})"
        if @move_callback
          x = message[1]
          y = message[2]
          if @server.isValidPosition(x, y)
            @setPosition x, y
            @clearTarget()
            @broadcast new Messages.Move(@)
            @move_callback @x, @y

      else if action is Types.Messages.LOOTMOVE
        log.info "LOOTMOVE: #{@name}(#{message[1]}, #{message[2]})"
        if @lootmove_callback
          @setPosition message[1], message[2]
          item = @server.getEntityById(message[3])
          if item
            @clearTarget()
            @broadcast new Messages.LootMove(@, item)
            @lootmove_callback @x, @y

      else if action is Types.Messages.AGGRO
        log.info "AGGRO: #{@name} #{message[1]}"
        @server.handleMobHate message[1], @id, 5  if @move_callback

      else if action is Types.Messages.ATTACK
        log.info "ATTACK: #{@name} #{message[1]}"
        mob = @server.getEntityById(message[1])
        if mob
          @setTarget mob
          @server.broadcastAttacker @

      else if action is Types.Messages.HIT
        log.info "HIT: #{@name} #{message[1]}"
        mob = @server.getEntityById(message[1])
        if mob
          dmg = Formulas.dmg(@weaponLevel, mob.armorLevel)
          if dmg > 0
            if mob.type isnt "player"
              mob.receiveDamage dmg, @id
              @server.handleMobHate mob.id, @id, dmg
              @server.handleHurtEntity mob, @, dmg
          else
            mob.hitPoints -= dmg
            mob.server.handleHurtEntity mob
            if mob.hitPoints <= 0
              mob.isDead = true
              @server.pushBroadcast new Messages.Chat(@, "#{@name} M-M-M-MONSTER KILLED #{mob.name}")

      else if action is Types.Messages.HURT
        log.info "HURT: #{@name} #{message[1]}"
        mob = @server.getEntityById(message[1])
        if mob and @hitPoints > 0
          @hitPoints -= Formulas.dmg(mob.weaponLevel, @armorLevel)
          @server.handleHurtEntity @
          if @hitPoints <= 0
            @isDead = true
            clearTimeout @firepotionTimeout  if @firepotionTimeout

      else if action is Types.Messages.LOOT
        log.info "LOOT: #{@name} #{message[1]}"
        item = @server.getEntityById(message[1])
        if item
          kind = item.kind
          if Types.isItem(kind)
            @broadcast item.despawn()
            @server.removeEntity item
            if kind is Types.Entities.FIREPOTION
              @updateHitPoints()
              @broadcast @equip(Types.Entities.FIREFOX)
              @firepotionTimeout = setTimeout(=>
                @broadcast @equip(@armor) # return to normal after 15 sec
                @firepotionTimeout = null
              , 15000)
              @send new Messages.HitPoints(@maxHitPoints).serialize()
            else if Types.isHealingItem(kind)
              amount = switch kind
                when Types.Entities.FLASK then 40
                when Types.Entities.BURGER then 100
              unless @hasFullHealth()
                @regenHealthBy amount
                @server.pushToPlayer @, @health()
            else if Types.isArmor(kind) or Types.isWeapon(kind)
              @equipItem item.kind
              @broadcast @equip(kind)

      else if action is Types.Messages.TELEPORT
        log.info "TELEPORT: #{@name}(#{message[1]}, #{message[2]})"
        x = message[1]
        y = message[2]
        if @server.isValidPosition(x, y)
          @setPosition x, y
          @clearTarget()
          @broadcast new Messages.Teleport(@)
          @server.handlePlayerVanish @
          @server.pushRelevantEntityListTo @

      else if action is Types.Messages.OPEN
        log.info "OPEN: #{@name} #{message[1]}"
        chest = @server.getEntityById(message[1])
        @server.handleOpenedChest chest, @  if chest and chest instanceof Chest

      else if action is Types.Messages.CHECK
        log.info "CHECK: #{@name} #{message[1]}"
        checkpoint = @server.map.getCheckpoint(message[1])
        if checkpoint
          @lastCheckpoint = checkpoint
          @databaseHandler.setCheckpoint @name, @x, @y

      else if action is Types.Messages.INVENTORY
        log.info "INVENTORY: #{@name} #{message[1]} #{message[2]} #{message[3]}"
        inventoryNumber = message[2]
        count = message[3]
        return if inventoryNumber isnt 0 and inventoryNumber isnt 1

        itemKind = @inventory[inventoryNumber]
        if itemKind
          if message[1] is "avatar" or message[1] is "armor"
            if message[1] is "avatar"
              @inventory[inventoryNumber] = null
              @databaseHandler.makeEmptyInventory @name, inventoryNumber
              @equipItem itemKind, true
            else
              @inventory[inventoryNumber] = @armor
              @databaseHandler.setInventory @name, @armor, inventoryNumber, 1
              @equipItem itemKind, false
            @broadcast @equip(itemKind)

          else if message[1] is "empty"
            #var item = @server.addItem(@server.createItem(itemKind, @x, @y));
            item = @server.addItemFromChest(itemKind, @x, @y)
            if Types.isHealingItem(item.kind)
              if count < 0
                count = 0
              else count = @inventoryCount[inventoryNumber]  if count > @inventoryCount[inventoryNumber]
              item.count = count
            if item.count > 0
              @server.handleItemDespawn item
              if Types.isHealingItem(item.kind)
                if item.count is @inventoryCount[inventoryNumber]
                  @inventory[inventoryNumber] = null
                  @databaseHandler.makeEmptyInventory @name, inventoryNumber
                else
                  @inventoryCount[inventoryNumber] -= item.count
                  @databaseHandler.setInventory @name, @inventory[inventoryNumber], inventoryNumber, @inventoryCount[inventoryNumber]
              else
                @inventory[inventoryNumber] = null
                @databaseHandler.makeEmptyInventory @name, inventoryNumber

          else if message[1] is "eat"
            amount = switch itemKind
              when Types.Entities.FLASK then 80
              when Types.Entities.BURGER then 200
            unless @hasFullHealth()
              @regenHealthBy amount
              @server.pushToPlayer @, @health()
            @inventoryCount[inventoryNumber] -= 1
            @inventory[inventoryNumber] = null  if @inventoryCount[inventoryNumber] <= 0
            @databaseHandler.setInventory @name, @inventory[inventoryNumber], inventoryNumber, @inventoryCount[inventoryNumber]

      else if action is Types.Messages.ACHIEVEMENT
        log.info "ACHIEVEMENT: " + @name + " " + message[1] + " " + message[2]
        if message[2] is "found"
          @achievement[message[1]].found = true
          @databaseHandler.foundAchievement @name, message[1]

      else if action is Types.Messages.GUILD
        if message[1] is Types.Messages.GUILDACTION.CREATE
          guildname = Utils.sanitize(message[2])
          if guildname is "" #inaccurate name
            @server.pushToPlayer @, new Messages.GuildError(Types.Messages.GUILDERRORTYPE.BADNAME, message[2])
          else
            guildId = @server.addGuild(guildname)
            if guildId is false
              @server.pushToPlayer @, new Messages.GuildError(Types.Messages.GUILDERRORTYPE.ALREADYEXISTS, guildname)
            else
              @server.joinGuild @, guildId
              @server.pushToPlayer @, new Messages.Guild(Types.Messages.GUILDACTION.CREATE, [guildId, guildname])

        else if message[1] is Types.Messages.GUILDACTION.INVITE
          userName = message[2]
          invitee = undefined
          if @group of @server.groups
            invitee = _.find @server.groups[@group].entities, (entity, key) ->
              (if (entity instanceof Player and entity.name is userName) then entity else false)
            @getGuild().invite invitee, @  if invitee

        else if message[1] is Types.Messages.GUILDACTION.JOIN
          @server.joinGuild @, message[2], message[3]

        else if message[1] is Types.Messages.GUILDACTION.LEAVE
          @leaveGuild()

        else if message[1] is Types.Messages.GUILDACTION.TALK
          @server.pushToGuild @getGuild(), new Messages.Guild(Types.Messages.GUILDACTION.TALK, [
            @name
            @id
            message[2]
          ])

      else
        @message_callback message if @message_callback

    @connection.onClose =>
      clearTimeout @firepotionTimeout if @firepotionTimeout
      clearTimeout @disconnectTimeout
      @exit_callback() if @exit_callback

    @connection.sendUTF8 "go" # Notify client that the HELLO/WELCOME handshake can start

  destroy: ->
    @forEachAttacker (mob) -> mob.clearTarget()
    @attackers = {}
    @forEachHater (mob) -> mob.forgetPlayer @id
    @haters = {}

  getState: ->
    basestate = @_getBaseState()
    state = [
      this.name
      this.orientation
      this.armor
      this.weapon
      this.level
    ]
    state.push @target  if @target
    basestate.concat state

  send: (message) ->
    @connection.send message

  flagPVP: (pvpFlag) ->
    unless @pvpFlag is pvpFlag
      @pvpFlag = pvpFlag
      @send new Messages.PVP(@pvpFlag).serialize()

  broadcast: (message, ignoreSelf) ->
    @broadcast_callback message, (if ignoreSelf? then ignoreSelf else true)  if @broadcast_callback

  broadcastToZone: (message, ignoreSelf) ->
    @broadcastzone_callback message, (if ignoreSelf? then ignoreSelf else true)  if @broadcastzone_callback

  onExit: (@exit_callback) ->

  onMove: (@move_callback) ->

  onLootMove: (@lootmove_callback) ->

  onZone: (@zone_callback) ->

  onOrient: (@orient_callback) ->

  onMessage: (@message_callback) ->

  onBroadcast: (@boradcast_callback) ->

  onBroadcastToZone: (@broadcastzone_callback) ->

  equip: (item) -> new Messages.EquipItem(@, item)

  addHater: (mob) ->
    @haters[mob.id] = mob unless mob.id of @haters if mob

  removeHater: (mob) ->
    delete @haters[mob.id]  if mob and mob.id of @haters

  forEachHater: (callback) ->
    _.each @haters, (mob) ->
      callback mob

  equipArmor: (kind) ->
    @armor = kind
    @armorLevel = Properties.getArmorLevel(kind)

  equipAvatar: (kind) ->
    if kind
      @avatar = kind
    else
      @avatar = Types.Entities.CLOTHARMOR

  equipWeapon: (@weapon) ->
    @weaponLevel = Properties.getWeaponLevel(@weapon)

  equipItem: (itemKind, isAvatar) ->
    if itemKind
      log.debug @name + " equips " + Types.getKindAsString(itemKind)
      if Types.isArmor(itemKind)
        if isAvatar
          @databaseHandler.equipAvatar @name, Types.getKindAsString(itemKind)
          @equipAvatar itemKind
        else
          @databaseHandler.equipAvatar @name, Types.getKindAsString(itemKind)
          @equipAvatar itemKind
          @databaseHandler.equipArmor @name, Types.getKindAsString(itemKind)
          @equipArmor itemKind
        @updateHitPoints()
        @send new Messages.HitPoints(@maxHitPoints).serialize()
      else if Types.isWeapon(itemKind)
        @databaseHandler.equipWeapon @name, Types.getKindAsString(itemKind)
        @equipWeapon itemKind

  updateHitPoints: ->
    @resetHitPoints Formulas.hp(@armorLevel)

  updatePosition: ->
    if @requestpos_callback
      pos = @requestpos_callback()
      @setPosition pos.x, pos.y

  onRequestPosition: (@requestpos_callback) ->

  resetTimeout: ->
    clearTimeout @disconnectTimeout
    @disconnectTimeout = setTimeout(@timeout.bind(this), 1000 * 60 * 15) # 15 min.

  timeout: ->
    @connection.sendUTF8 "timeout"
    @connection.close "Player was idle for too long"

  incExp: (gotexp) ->
    @experience = parseInt(@experience) + (parseInt(gotexp))
    @databaseHandler.setExp @name, @experience
    origLevel = @level
    @level = Types.getLevel(@experience)
    if origLevel isnt @level
      @updateHitPoints()
      @send new Messages.HitPoints(@maxHitPoints).serialize()

  setGuildId: (id) ->
    if typeof @server.guilds[id] isnt "undefined"
      @guildId = id
    else
      log.error @id + " cannot add guild " + id + ", it does not exist"

  getGuild: ->
    if @hasGuild then @server.guilds[@guildId] else null

  hasGuild: ->
    typeof @guildId isnt "undefined"

  leaveGuild: ->
    if @hasGuild()
      leftGuild = @getGuild()
      leftGuild.removeMember this
      @server.pushToGuild leftGuild, new Messages.Guild(Types.Messages.GUILDACTION.LEAVE, [
        this.name
        this.id
        leftGuild.name
      ])
      delete @guildId

      @server.pushToPlayer this, new Messages.Guild(Types.Messages.GUILDACTION.LEAVE, [
        this.name
        this.id
        leftGuild.name
      ])
    else
      @server.pushToPlayer this, new Messages.GuildError(Types.Messages.GUILDERRORTYPE.NOLEAVE, "")

  checkName: (name) ->
    #TODO: make a better check, with regex maybe

    if not name? or name is "" or name is " "
      return false

    for i in [0...name.length]
      c = name.charCodeAt(i)
      return false unless (
        (0xAC00 <= c and c <= 0xD7A3) or
        # Korean (Unicode blocks "Hangul Syllables" and "Hangul Compatibility Jamo")
        (0x3131 <= c and c <= 0x318E) or
        # English (lowercase and uppercase)
        (0x61 <= c and c <= 0x7A) or
        # Numbers
        (0x41 <= c and c <= 0x5A) or
        # Space and underscore
        (0x30 <= c and c <= 0x39) or
        (c is 0x20) or (c is 0x5f) or
        # Parentheses
        (c is 0x28) or (c is 0x29) or
        # Caret
        (c is 0x5e))
    true

  sendWelcome: (armor, weapon, avatar, weaponAvatar, exp, admin,
                bannedTime, banUseTime, inventory, inventoryNumber,
                achievementFound, achievementProgress, x, y,
                chatBanEndTime) ->
    @kind = Types.Entities.WARRIOR
    @admin = admin
    @equipArmor Types.getKindFromString(armor)
    @equipAvatar Types.getKindFromString(avatar)
    @equipWeapon Types.getKindFromString(weapon)
    @inventory[0] = Types.getKindFromString(inventory[0])
    @inventory[1] = Types.getKindFromString(inventory[1])
    @inventoryCount[0] = inventoryNumber[0]
    @inventoryCount[1] = inventoryNumber[1]
    @achievement[1] =
      found: achievementFound[0]
      progress: achievementProgress[0]
    @achievement[2] =
      found: achievementFound[1]
      progress: achievementProgress[1]
    @achievement[3] =
      found: achievementFound[2]
      progress: achievementProgress[2]
    @achievement[4] =
      found: achievementFound[3]
      progress: achievementProgress[3]
    @achievement[5] =
      found: achievementFound[4]
      progress: achievementProgress[4]
    @achievement[6] =
      found: achievementFound[5]
      progress: achievementProgress[5]
    @achievement[7] =
      found: achievementFound[6]
      progress: achievementProgress[6]
    @achievement[8] =
      found: achievementFound[7]
      progress: achievementProgress[7]
    @bannedTime = bannedTime
    @banUseTime = banUseTime
    @experience = exp
    @level = Types.getLevel(@experience)
    @orientation = Utils.randomOrientation
    @updateHitPoints()
    if x is 0 and y is 0
      @updatePosition()
    else
      @setPosition x, y
    @chatBanEndTime = chatBanEndTime
    @server.addPlayer @
    @server.enter_callback @
    @send [
      Types.Messages.WELCOME
      @id
      @name
      @x
      @y
      @hitPoints
      armor
      weapon
      avatar
      weaponAvatar
      @experience
      @admin
      inventory[0]
      inventoryNumber[0]
      inventory[1]
      inventoryNumber[1]
      achievementFound[0]
      achievementProgress[0]
      achievementFound[1]
      achievementProgress[1]
      achievementFound[2]
      achievementProgress[2]
      achievementFound[3]
      achievementProgress[3]
      achievementFound[4]
      achievementProgress[4]
      achievementFound[5]
      achievementProgress[5]
      achievementFound[6]
      achievementProgress[6]
      achievementFound[7]
      achievementProgress[7]
    ]
    @hasEnteredGame = true
    @isDead = false

module.exports = Player
