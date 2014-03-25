$ = require("jquery")
_ = require("underscore")
config = require("./config")
log = require("./log")
InfoManager = require("./infomanager")
BubbleManager = require("./bubble")
Renderer = require("./renderer")
Map = require("./map")
Animation = require("./animation")
Sprite = require("./sprite")
AnimatedTile = require("./tile")
Warrior = require("./warrior")
GameClient = require("./gameclient")
AudioManager = require("./audio")
Updater = require("./updater")
Transition = require("./transition")
Pathfinder = require("./pathfinder")
Item = require("./item")
Mob = require("./mob")
Npc = require("./npc")
Player = require("./player")
Character = require("./character")
Chest = require("./chest")
Mobs = require("./mobs")
Exceptions = require("./exceptions")
Guild = require("./guild")
Types = require("./types")
Util = require("./util")

class Game
  constructor: (@app) ->
    @app.config = config
    @ready = false
    @started = false
    @hasNeverStarted = true
    @renderer = null
    @updater = null
    @pathfinder = null
    @chatinput = null
    @bubbleManager = null
    @audioManager = null

    # Player
    @player = new Warrior("player", "")
    @player.moveUp = false
    @player.moveDown = false
    @player.moveLeft = false
    @player.moveRight = false
    @player.disableKeyboardNpcTalk = false

    # Game state
    @entities = {}
    @deathpositions = {}
    @entityGrid = null
    @pathingGrid = null
    @renderingGrid = null
    @itemGrid = null
    @currentCursor = null
    @mouse = x: 0, y: 0
    @zoningQueue = []
    @previousClickPosition = {}
    @cursorVisible = true
    @selectedX = 0
    @selectedY = 0
    @selectedCellVisible = false
    @targetColor = "rgba(255, 255, 255, 0.5)"
    @targetCellVisible = true
    @hoveringTarget = false
    @hoveringPlayer = false
    @hoveringMob = false
    @hoveringItem = false
    @hoveringCollidingTile = false

    # combat
    @infoManager = new InfoManager(this)

    # zoning
    @currentZoning = null
    @cursors = {}
    @sprites = {}

    # tile animation
    @animatedTiles = null

    # debug
    @debugPathing = false

    # pvp
    @pvpFlag = false

    # sprites
    @spriteNames = [
      "hand"
      "sword"
      "loot"
      "target"
      "talk"
      "sparks"
      "shadow16"
      "rat"
      "skeleton"
      "skeleton2"
      "spectre"
      "boss"
      "deathknight"
      "ogre"
      "crab"
      "snake"
      "eye"
      "bat"
      "goblin"
      "wizard"
      "guard"
      "king"
      "villagegirl"
      "villager"
      "coder"
      "agent"
      "rick"
      "scientist"
      "nyan"
      "priest"
      "sorcerer"
      "octocat"
      "beachnpc"
      "forestnpc"
      "desertnpc"
      "lavanpc"
      "clotharmor"
      "leatherarmor"
      "mailarmor"
      "platearmor"
      "redarmor"
      "goldenarmor"
      "firefox"
      "death"
      "sword1"
      "axe"
      "chest"
      "sword2"
      "redsword"
      "bluesword"
      "goldensword"
      "item-sword2"
      "item-axe"
      "item-redsword"
      "item-bluesword"
      "item-goldensword"
      "item-leatherarmor"
      "item-mailarmor"
      "item-platearmor"
      "item-redarmor"
      "item-goldenarmor"
      "item-flask"
      "item-cake"
      "item-burger"
      "morningstar"
      "item-morningstar"
      "item-firepotion"
    ]

  setup: ($bubbleContainer, canvas, background, foreground, input) ->
    @setBubbleManager new BubbleManager($bubbleContainer)
    @setRenderer new Renderer(this, canvas, background, foreground)
    @setChatInput input

  setStorage: (@storage) ->

  setRenderer: (@renderer) ->

  setUpdater: (@updater) ->

  setPathfinder: (@pathfinder) ->

  setChatInput: (@chatinput) ->

  setBubbleManager: (@bubbleManager) ->

  loadMap: ->
    @map = new Map(not @renderer.upscaledRendering, this)
    @map.ready =>
      log.info "Map loaded."
      tilesetIndex = (if @renderer.upscaledRendering then 0 else @renderer.scale - 1)
      @renderer.setTileset @map.tilesets[tilesetIndex]

  initPlayer: ->
    if @storage.hasAlreadyPlayed() and @storage.data.player
      if @storage.data.player.armor and @storage.data.player.weapon
        @player.setSpriteName @storage.data.player.armor
        @player.setWeaponName @storage.data.player.weapon
      @player.setGuild @storage.data.player.guild  if @storage.data.player.guild
    @player.setSprite @sprites[@player.getSpriteName()]
    @player.idle()
    log.debug "Finished initPlayer"

  initShadows: ->
    @shadows = {}
    @shadows["small"] = @sprites["shadow16"]

  initCursors: ->
    @cursors["hand"] = @sprites["hand"]
    @cursors["sword"] = @sprites["sword"]
    @cursors["loot"] = @sprites["loot"]
    @cursors["target"] = @sprites["target"]
    @cursors["arrow"] = @sprites["arrow"]
    @cursors["talk"] = @sprites["talk"]
    @cursors["join"] = @sprites["talk"]

  initAnimations: ->
    @targetAnimation = new Animation("idle_down", 4, 0, 16, 16)
    @targetAnimation.setSpeed 50
    @sparksAnimation = new Animation("idle_down", 6, 0, 16, 16)
    @sparksAnimation.setSpeed 120

  initHurtSprites: ->
    Types.forEachArmorKind (kind, kindName) =>
      @sprites[kindName].createHurtSprite()

  initSilhouettes: ->
    Types.forEachMobOrNpcKind (kind, kindName) =>
      @sprites[kindName].createSilhouette()
    @sprites["chest"].createSilhouette()
    @sprites["item-cake"].createSilhouette()

  initAchievements: ->
    @achievements =
      A_TRUE_WARRIOR:
        id: 1
        name: "A True Warrior"
        desc: "Find a new weapon"

      INTO_THE_WILD:
        id: 2
        name: "Into the Wild"
        desc: "Venture outside the village"

      ANGRY_RATS:
        id: 3
        name: "Angry Rats"
        desc: "Kill 10 rats"
        isCompleted: => @storage.getRatCount() >= 10

      SMALL_TALK:
        id: 4
        name: "Small Talk"
        desc: "Talk to a non-player character"

      FAT_LOOT:
        id: 5
        name: "Fat Loot"
        desc: "Get a new armor set"

      UNDERGROUND:
        id: 6
        name: "Underground"
        desc: "Explore at least one cave"

      AT_WORLDS_END:
        id: 7
        name: "At World's End"
        desc: "Reach the south shore"

      COWARD:
        id: 8
        name: "Coward"
        desc: "Successfully escape an enemy"

      TOMB_RAIDER:
        id: 9
        name: "Tomb Raider"
        desc: "Find the graveyard"

      SKULL_COLLECTOR:
        id: 10
        name: "Skull Collector"
        desc: "Kill 10 skeletons"
        isCompleted: => @storage.getSkeletonCount() >= 10

      NINJA_LOOT:
        id: 11
        name: "Ninja Loot"
        desc: "Get hold of an item you didn't fight for"

      NO_MANS_LAND:
        id: 12
        name: "No Man's Land"
        desc: "Travel through the desert"

      HUNTER:
        id: 13
        name: "Hunter"
        desc: "Kill 50 enemies"
        isCompleted: => @storage.getTotalKills() >= 50

      STILL_ALIVE:
        id: 14
        name: "Still Alive"
        desc: "Revive your character five times"
        isCompleted: => @storage.getTotalRevives() >= 5

      MEATSHIELD:
        id: 15
        name: "Meatshield"
        desc: "Take 5,000 points of damage"
        isCompleted: => @storage.getTotalDamageTaken() >= 5000

      HOT_SPOT:
        id: 16
        name: "Hot Spot"
        desc: "Enter the volcanic mountains"

      HERO:
        id: 17
        name: "Hero"
        desc: "Defeat the final boss"

      FOXY:
        id: 18
        name: "Foxy"
        desc: "Find the Firefox costume"
        hidden: true

      FOR_SCIENCE:
        id: 19
        name: "For Science"
        desc: "Enter into a portal"
        hidden: true

      RICKROLLD:
        id: 20
        name: "Rickroll'd"
        desc: "Take some singing lessons"
        hidden: true

    _.each @achievements, (obj) ->
      unless obj.isCompleted
        obj.isCompleted = -> true
      obj.hidden = false unless obj.hidden

    @app.initAchievementList @achievements
    @app.initUnlockedAchievements @storage.data.achievements.unlocked if @storage.hasAlreadyPlayed()

  getAchievementById: (id) ->
    found = null
    _.each @achievements, (achievement, key) ->
      found = achievement if achievement.id is parseInt(id)
    found

  loadSprite: (name) ->
    if @renderer.upscaledRendering
      @spritesets[0][name] = new Sprite(name, 1)
    else
      @spritesets[1][name] = new Sprite(name, 2)
      @spritesets[2][name] = new Sprite(name, 3) if not @renderer.mobile and not @renderer.tablet

  setSpriteScale: (scale) ->
    if @renderer.upscaledRendering
      @sprites = @spritesets[0]
    else
      @sprites = @spritesets[scale - 1]
      _.each @entities, (entity) ->
        entity.sprite = null
        entity.setSprite @sprites[entity.getSpriteName()]
      @initHurtSprites()
      @initShadows()
      @initCursors()

  loadSprites: ->
    log.info "Loading sprites..."
    @spritesets = []
    @spritesets[0] = {}
    @spritesets[1] = {}
    @spritesets[2] = {}
    _.map @spriteNames, @loadSprite, this

  spritesLoaded: ->
    not _.any(@sprites, (sprite) -> not sprite.isLoaded)

  setCursor: (name, orientation) ->
    if name of @cursors
      @currentCursor = @cursors[name]
      @currentCursorOrientation = orientation
    else
      log.error "Unknown cursor name :" + name

  updateCursorLogic: ->
    if @hoveringCollidingTile and @started
      @targetColor = "rgba(255, 50, 50, 0.5)"
    else
      @targetColor = "rgba(255, 255, 255, 0.5)"
    if @hoveringPlayer and @started
      if @pvpFlag
        @setCursor "sword"
      else
        @setCursor "hand"
      @hoveringTarget = false
      @hoveringMob = false
      @targetCellVisible = false
    else if @hoveringMob and @started
      @setCursor "sword"
      @hoveringTarget = false
      @hoveringPlayer = false
      @targetCellVisible = false
    else if @hoveringNpc and @started
      @setCursor "talk"
      @hoveringTarget = false
      @targetCellVisible = false
    else if (@hoveringItem or @hoveringChest) and @started
      @setCursor "loot"
      @hoveringTarget = false
      @targetCellVisible = true
    else
      @setCursor "hand"
      @hoveringTarget = false
      @hoveringPlayer = false
      @targetCellVisible = true

  focusPlayer: ->
    @renderer.camera.lookAt @player

  addEntity: (entity) ->
    unless @entities[entity.id]?
      @entities[entity.id] = entity
      @registerEntityPosition entity
      entity.fadeIn @currentTime if not (entity instanceof Item and entity.wasDropped) and not (@renderer.mobile or @renderer.tablet)
      if @renderer.mobile or @renderer.tablet
        entity.onDirty (e) =>
          if @camera.isVisible(e)
            e.dirtyRect = @renderer.getEntityBoundingRect(e)
            @checkOtherDirtyRects e.dirtyRect, e, e.gridX, e.gridY
    else
      log.error "This entity already exists : " + entity.id + " (" + entity.kind + ")"

  removeEntity: (entity) ->
    if entity.id of @entities
      @unregisterEntityPosition entity
      delete @entities[entity.id]
    else
      log.error "Cannot remove entity. Unknown ID : " + entity.id

  addItem: (item, x, y) ->
    item.setSprite @sprites[item.getSpriteName()]
    item.setGridPosition x, y
    item.setAnimation "idle", 150
    @addEntity item

  removeItem: (item) ->
    if item
      @removeFromItemGrid item, item.gridX, item.gridY
      @removeFromRenderingGrid item, item.gridX, item.gridY
      delete @entities[item.id]
    else
      log.error "Cannot remove item. Unknown ID : " + item.id

  initPathingGrid: ->
    @pathingGrid = []
    for i in [0...@map.height]
      @pathingGrid[i] = []
      for j in [0...@map.width]
        @pathingGrid[i][j] = @map.grid[i][j]

    log.info "Initialized the pathing grid with static colliding cells."

  initEntityGrid: ->
    @entityGrid = []
    for i in [0...@map.height]
      @entityGrid[i] = []
      for j in [0...@map.width]
        @entityGrid[i][j] = {}

    log.info "Initialized the entity grid."

  initRenderingGrid: ->
    @renderingGrid = []
    for i in [0...@map.height]
      @renderingGrid[i] = []
      for j in [0...@map.width]
        @renderingGrid[i][j] = {}

    log.info "Initialized the rendering grid."

  initItemGrid: ->
    @itemGrid = []
    for i in [0...@map.height]
      @itemGrid[i] = []
      for j in [0...@map.width]
        @itemGrid[i][j] = {}

    log.info "Initialized the item grid."

  initAnimatedTiles: ->
    @animatedTiles = []
    @forEachVisibleTile ((id, index) =>
      if @map.isAnimatedTile(id)
        tile = new AnimatedTile(id, @map.getTileAnimationLength(id), @map.getTileAnimationDelay(id), index)
        pos = @map.tileIndexToGridPosition(tile.index)
        tile.x = pos.x
        tile.y = pos.y
        @animatedTiles.push tile
    ), 1

    log.info "Initialized animated tiles."

  addToRenderingGrid: (entity, x, y) ->
    @renderingGrid[y][x][entity.id] = entity unless @map.isOutOfBounds(x, y)

  removeFromRenderingGrid: (entity, x, y) ->
    delete @renderingGrid[y][x][entity.id] if entity and @renderingGrid[y][x] and entity.id of @renderingGrid[y][x]

  removeFromEntityGrid: (entity, x, y) ->
    delete @entityGrid[y][x][entity.id] if @entityGrid[y][x][entity.id]

  removeFromItemGrid: (item, x, y) ->
    delete @itemGrid[y][x][item.id] if item and @itemGrid[y][x][item.id]

  removeFromPathingGrid: (x, y) ->
    @pathingGrid[y][x] = 0

  ###
  Registers the entity at two adjacent positions on the grid at the same time.
  This situation is temporary and should only occur when the entity is moving.
  This is useful for the hit testing algorithm used when hovering entities with the mouse cursor.

  @param {Entity} entity The moving entity
  ###
  registerEntityDualPosition: (entity) ->
    if entity
      @entityGrid[entity.gridY][entity.gridX][entity.id] = entity
      @addToRenderingGrid entity, entity.gridX, entity.gridY
      if entity.nextGridX >= 0 and entity.nextGridY >= 0
        @entityGrid[entity.nextGridY][entity.nextGridX][entity.id] = entity
        @pathingGrid[entity.nextGridY][entity.nextGridX] = 1  unless entity instanceof Player

  ###
  Clears the position(s) of this entity in the entity grid.

  @param {Entity} entity The moving entity
  ###
  unregisterEntityPosition: (entity) ->
    if entity
      @removeFromEntityGrid entity, entity.gridX, entity.gridY
      @removeFromPathingGrid entity.gridX, entity.gridY
      @removeFromRenderingGrid entity, entity.gridX, entity.gridY
      if entity.nextGridX >= 0 and entity.nextGridY >= 0
        @removeFromEntityGrid entity, entity.nextGridX, entity.nextGridY
        @removeFromPathingGrid entity.nextGridX, entity.nextGridY

  registerEntityPosition: (entity) ->
    x = entity.gridX
    y = entity.gridY
    if entity
      if entity instanceof Character or entity instanceof Chest
        @entityGrid[y][x][entity.id] = entity
        @pathingGrid[y][x] = 1  unless entity instanceof Player
      @itemGrid[y][x][entity.id] = entity  if entity instanceof Item
      @addToRenderingGrid entity, x, y

  setServerOptions: (host, port, username, userpw, email) ->
    @host = host
    @port = port
    @username = username
    @userpw = userpw
    @email = email

  loadAudio: ->
    @audioManager = new AudioManager(this)

  initMusicAreas: ->
    _.each @map.musicAreas, (area) =>
      @audioManager.addArea area.x, area.y, area.w, area.h, area.id

  run: (action, started_callback) ->
    @loadSprites()
    @setUpdater new Updater(this)
    @camera = @renderer.camera
    @setSpriteScale @renderer.scale
    wait = setInterval(=>
      if @map.isLoaded and @spritesLoaded()
        @ready = true
        log.debug "All sprites loaded."
        @loadAudio()
        @initMusicAreas()
        @initAchievements()
        @initCursors()
        @initAnimations()
        @initShadows()
        @initHurtSprites()
        @initSilhouettes()  if not @renderer.mobile and not @renderer.tablet and @renderer.upscaledRendering
        @initEntityGrid()
        @initItemGrid()
        @initPathingGrid()
        @initRenderingGrid()
        @setPathfinder new Pathfinder(@map.width, @map.height)
        @initPlayer()
        @setCursor "hand"
        @connect action, started_callback
        clearInterval wait
    , 100)

  tick: ->
    @currentTime = new Date().getTime()
    if @started
      @updateCursorLogic()
      @updater.update()
      @renderer.renderFrame()
    unless @isStopped
      #FIXME: should use the one from Util
      #Util.requestAnimFrame => @tick()
      requestAnimationFrame => @tick()

  start: ->
    @tick()
    @hasNeverStarted = false
    log.info "Game loop started."

  stop: ->
    log.info "Game stopped."
    @isStopped = true

  entityIdExists: (id) ->
    id of @entities

  getEntityById: (id) ->
    if id of @entities
      @entities[id]
    else
      #log.error "Unknown entity id: #{id}", true
      log.error "Unknown entity id: #{id}"
      null

  connect: (action, started_callback) ->
    connecting = false # always in dispatcher mode in the build version
    @client = new GameClient(@host, @port)
    @client.fail_callback = (reason) =>
      started_callback
        success: false
        reason: reason

      @started = false

    #>>excludeStart("prodHost", pragmas.prodHost);
    config = @app.config.local or @app.config.dev
    if config
      @client.connect config.dispatcher # false if the client connects directly to a game server
      connecting = true

    #>>excludeEnd("prodHost");
    #>>includeStart("prodHost", pragmas.prodHost);
    @client.connect false  unless connecting # dont use the dispatcher in production

    #>>includeEnd("prodHost");
    @client.onDispatched (host, port) =>
      log.debug "Dispatched to game server " + host + ":" + port
      @client.host = host
      @client.port = port
      @client.connect() # connect to actual game server

    @client.onConnected =>
      log.info "Starting client/server handshake"
      @player.name = @username
      @player.pw = @userpw
      @player.email = @email
      @started = true
      if action is "create"
        @client.sendCreate @player
      else
        @client.sendLogin @player

    @client.onEntityList (list) =>
      entityIds = _.pluck(@entities, "id")
      knownIds = _.intersection(entityIds, list)
      newIds = _.difference(list, knownIds)
      @obsoleteEntities = _.reject @entities, (entity) =>
        _.include(knownIds, entity.id) or entity.id is @player.id

      # Destroy entities outside of the player's zone group
      @removeObsoleteEntities()

      # Ask the server for spawn information about unknown entities
      @client.sendWho newIds  if _.size(newIds) > 0

    @client.onWelcome (id, name, x, y, hp, armor, weapon, avatar, weaponAvatar, experience) =>
      log.info "Received player ID from server : " + id
      @player.id = id
      @playerId = id

      # Always accept name received from the server which will
      # sanitize and shorten names exceeding the allowed length.
      @player.name = name
      @player.setGridPosition x, y
      @player.setMaxHitPoints hp
      @player.setArmorName armor
      @player.setSpriteName avatar
      @player.setWeaponName weapon
      @initPlayer()
      @player.experience = experience
      @player.level = Types.getLevel(experience)
      @updateBars()
      @updateExpBar()
      @resetCamera()
      @updatePlateauMode()
      @audioManager.updateMusic()
      @addEntity @player
      @player.dirtyRect = @renderer.getEntityBoundingRect(@player)
      setTimeout (=> @tryUnlockingAchievement "STILL_ALIVE"), 1500
      unless @storage.hasAlreadyPlayed()
        @storage.initPlayer @player.name
        @storage.savePlayer @renderer.getPlayerImage(), @player.getSpriteName(), @player.getWeaponName(), @player.getGuild()
        @showNotification "Welcome to BrowserQuest!"
      else
        @showNotification "Welcome Back. You are level " + @player.level + "."
        @storage.setPlayerName name

      @player.onStartPathing (path) =>
        i = path.length - 1
        x = path[i][0]
        y = path[i][1]
        if @player.isMovingToLoot()
          @player.isLootMoving = false
        else @client.sendMove x, y  unless @player.isAttacking()

        # Target cursor position
        @selectedX = x
        @selectedY = y
        @selectedCellVisible = true
        if @renderer.mobile or @renderer.tablet
          @drawTarget = true
          @clearTarget = true
          @renderer.targetRect = @renderer.getTargetBoundingRect()
          @checkOtherDirtyRects @renderer.targetRect, null, @selectedX, @selectedY

      @player.onCheckAggro =>
        @forEachMob (mob) =>
          @player.aggro mob  if mob.isAggressive and not mob.isAttacking() and @player.isNear(mob, mob.aggroRange)

      @player.onAggro (mob) =>
        if not mob.isWaitingToAttack(@player) and not @player.isAttackedBy(mob)
          @player.log_info "Aggroed by " + mob.id + " at (" + @player.gridX + ", " + @player.gridY + ")"
          @client.sendAggro mob
          mob.waitToAttack @player

      @player.onBeforeStep =>
        blockingEntity = @getEntityAt(@player.nextGridX, @player.nextGridY)
        log.debug "Blocked by " + blockingEntity.id  if blockingEntity and blockingEntity.id isnt @playerId
        @unregisterEntityPosition @player

      @player.onStep =>
        @registerEntityDualPosition @player  if @player.hasNextStep()
        @enqueueZoningFrom @player.gridX, @player.gridY  if @isZoningTile(@player.gridX, @player.gridY)
        @player.forEachAttacker @makeAttackerFollow
        item = @getItemAt(@player.gridX, @player.gridY)
        @tryLootingItem item  if item instanceof Item
        @tryUnlockingAchievement "INTO_THE_WILD"  if (@player.gridX <= 85 and @player.gridY <= 179 and @player.gridY > 178) or (@player.gridX <= 85 and @player.gridY <= 266 and @player.gridY > 265)
        @tryUnlockingAchievement "AT_WORLDS_END"  if @player.gridX <= 85 and @player.gridY <= 293 and @player.gridY > 292
        @tryUnlockingAchievement "NO_MANS_LAND"  if @player.gridX <= 85 and @player.gridY <= 100 and @player.gridY > 99
        @tryUnlockingAchievement "HOT_SPOT"  if @player.gridX <= 85 and @player.gridY <= 51 and @player.gridY > 50
        @tryUnlockingAchievement "TOMB_RAIDER"  if @player.gridX <= 27 and @player.gridY <= 123 and @player.gridY > 112
        @updatePlayerCheckpoint()
        @audioManager.updateMusic()  unless @player.isDead

      @player.onStopPathing (x, y) =>
        @player.lookAtTarget()  if @player.hasTarget()
        @selectedCellVisible = false
        if @isItemAt(x, y)
          item = @getItemAt(x, y)
          @tryLootingItem item
        if not @player.hasTarget() and @map.isDoor(x, y)
          dest = @map.getDoorDestination(x, y)
          @player.setGridPosition dest.x, dest.y
          @player.nextGridX = dest.x
          @player.nextGridY = dest.y
          @player.turnTo dest.orientation
          @client.sendTeleport dest.x, dest.y
          if @renderer.mobile and dest.cameraX and dest.cameraY
            @camera.setGridPosition dest.cameraX, dest.cameraY
            @resetZone()
          else
            if dest.portal
              @assignBubbleTo @player
            else
              @camera.focusEntity @player
              @resetZone()
          if _.size(@player.attackers) > 0
            setTimeout (=> @tryUnlockingAchievement "COWARD"), 500

          @player.forEachAttacker (attacker) ->
            attacker.disengage()
            attacker.idle()

          @updatePlateauMode()
          @checkUndergroundAchievement()

          # When rendering with dirty rects, clear the whole screen when entering a door.
          @renderer.clearScreen @renderer.context  if @renderer.mobile or @renderer.tablet
          @audioManager.playSound "teleport"  if dest.portal
          @audioManager.updateMusic()  unless @player.isDead

        if @player.target instanceof Npc
          @makeNpcTalk @player.target
        else if @player.target instanceof Chest
          @client.sendOpen @player.target
          @audioManager.playSound "chest"
        @player.forEachAttacker (attacker) =>
          attacker.follow @player  unless attacker.isAdjacentNonDiagonal(@player)

        @unregisterEntityPosition @player
        @registerEntityPosition @player

      @player.onRequestPath (x, y) =>
        ignored = [@player] # Always ignore self
        ignored.push @player.target  if @player.hasTarget()
        @findPath @player, x, y, ignored

      @player.onDeath =>
        log.info @playerId + " is dead"
        @player.stopBlinking()
        @player.setSprite @sprites["death"]
        @player.animate "death", 120, 1, =>
          log.info @playerId + " was removed"
          @removeEntity @player
          @removeFromRenderingGrid @player, @player.gridX, @player.gridY
          @player = null
          @client.disable()
          setTimeout (=> @playerdeath_callback()), 1000

        @player.forEachAttacker (attacker) ->
          attacker.disengage()
          attacker.idle()

        @audioManager.fadeOutCurrentMusic()
        @audioManager.playSound "death"

      @player.onHasMoved (player) =>
        @assignBubbleTo player

      @client.onPVPChange (pvpFlag) =>
        @player.flagPVP pvpFlag
        if pvpFlag
          @showNotification "PVP is on."
        else
          @showNotification "PVP is off."

      @player.onArmorLoot (armorName) =>
        @player.switchArmor @sprites[armorName]

      @player.onSwitchItem =>
        @storage.savePlayer @renderer.getPlayerImage(), @player.getArmorName(), @player.getWeaponName(), @player.getGuild()
        @equipment_callback()  if @equipment_callback

      @player.onInvincible ->
        @invincible_callback()
        @player.switchArmor @sprites["firefox"]

      @client.onSpawnItem (item, x, y) =>
        log.info "Spawned " + Types.getKindAsString(item.kind) + " (" + item.id + ") at " + x + ", " + y
        @addItem item, x, y

      @client.onSpawnChest (chest, x, y) =>
        log.info "Spawned chest (" + chest.id + ") at " + x + ", " + y
        chest.setSprite @sprites[chest.getSpriteName()]
        chest.setGridPosition x, y
        chest.setAnimation "idle_down", 150
        @addEntity chest, x, y
        chest.onOpen =>
          chest.stopBlinking()
          chest.setSprite @sprites["death"]
          chest.setAnimation "death", 120, 1, =>
            log.info chest.id + " was removed"
            @removeEntity chest
            @removeFromRenderingGrid chest, chest.gridX, chest.gridY
            @previousClickPosition = {}

      @client.onSpawnCharacter (entity, x, y, orientation, targetId) =>
        unless @entityIdExists(entity.id)
          try
            if entity.id isnt @playerId
              entity.setSprite @sprites[entity.getSpriteName()]
              entity.setGridPosition x, y
              entity.setOrientation orientation
              entity.idle()
              @addEntity entity
              log.debug "Spawned " + Types.getKindAsString(entity.kind) + " (" + entity.id + ") at " + entity.gridX + ", " + entity.gridY
              if entity instanceof Character
                entity.onBeforeStep =>
                  @unregisterEntityPosition entity

                entity.onStep =>
                  unless entity.isDying
                    @registerEntityDualPosition entity

                    #FIXME: when disconnecting "Uncaught TypeError: Cannot read property 'target' of null"
                    @makeAttackerFollow @player  if @player.target is entity
                    entity.forEachAttacker (attacker) ->
                      if attacker.isAdjacent(attacker.target)
                        attacker.lookAtTarget()
                      else
                        attacker.follow entity

                entity.onStopPathing (x, y) =>
                  unless entity.isDying
                    entity.lookAtTarget()  if entity.hasTarget() and entity.isAdjacent(entity.target)
                    if entity instanceof Player
                      gridX = entity.destination.gridX
                      gridY = entity.destination.gridY
                      if @map.isDoor(gridX, gridY)
                        dest = @map.getDoorDestination(gridX, gridY)
                        entity.setGridPosition dest.x, dest.y
                    entity.forEachAttacker (attacker) =>
                      attacker.follow entity  if not attacker.isAdjacentNonDiagonal(entity) and attacker.id isnt @playerId

                    @unregisterEntityPosition entity
                    @registerEntityPosition entity

                entity.onRequestPath (x, y) =>
                  ignored = [entity] # Always ignore self
                  ignoreTarget = (target) ->
                    ignored.push target

                    # also ignore other attackers of the target entity
                    target.forEachAttacker (attacker) ->
                      ignored.push attacker

                  if entity.hasTarget()
                    ignoreTarget entity.target

                  # If repositioning before attacking again, ignore previous target
                  # See: tryMovingToADifferentTile()
                  else ignoreTarget entity.previousTarget  if entity.previousTarget
                  @findPath entity, x, y, ignored

                entity.onDeath =>
                  log.info entity.id + " is dead"
                  if entity instanceof Mob

                    # Keep track of where mobs die in order to spawn their dropped items
                    # at the right position later.
                    @deathpositions[entity.id] =
                      x: entity.gridX
                      y: entity.gridY
                  entity.isDying = true
                  entity.setSprite @sprites[(if entity instanceof Mobs.Rat then "rat" else "death")]
                  entity.animate "death", 120, 1, =>
                    log.info entity.id + " was removed"
                    @removeEntity entity
                    @removeFromRenderingGrid entity, entity.gridX, entity.gridY

                  entity.forEachAttacker (attacker) ->
                    attacker.disengage()

                  @player.disengage()  if @player.target and @player.target.id is entity.id

                  # Upon death, this entity is removed from both grids, allowing the player
                  # to click very fast in order to loot the dropped item and not be blocked.
                  # The entity is completely removed only after the death animation has ended.
                  @removeFromEntityGrid entity, entity.gridX, entity.gridY
                  @removeFromPathingGrid entity.gridX, entity.gridY
                  @audioManager.playSound "kill" + Math.floor(Math.random() * 2 + 1)  if @camera.isVisible(entity)
                  @updateCursor()

                entity.onHasMoved (entity) =>
                  @assignBubbleTo entity # Make chat bubbles follow moving entities

                if entity instanceof Mob
                  if targetId
                    player = @getEntityById(targetId)
                    @createAttackLink entity, player  if player
          catch e
            log.error e
        else
          log.debug "Character " + entity.id + " already exists. Don't respawn."

      @client.onDespawnEntity (entityId) =>
        entity = @getEntityById(entityId)
        if entity
          log.info "Despawning " + Types.getKindAsString(entity.kind) + " (" + entity.id + ")"
          @previousClickPosition = {} if entity.gridX is @previousClickPosition.x and entity.gridY is @previousClickPosition.y
          if entity instanceof Item
            @removeItem entity
          else if entity instanceof Character
            entity.forEachAttacker (attacker) ->
              attacker.hit() if attacker.canReachTarget()
            entity.die()
          else entity.open() if entity instanceof Chest
          entity.clean()

      @client.onItemBlink (id) =>
        item = @getEntityById(id)
        item.blink 150 if item

      @client.onGuildError (errorType, info) =>
        if errorType is Types.Messages.GUILDERRORTYPE.BADNAME
          @showNotification info + " seems to be an inappropriate guild name…"
        else if errorType is Types.Messages.GUILDERRORTYPE.ALREADYEXISTS
          @showNotification info + " already exists…"
          setTimeout (=> @showNotification "Either change the name of YOUR guild"), 2500
          setTimeout (=> @showNotification "Or ask a member of #{info} if you can join them."), 5000
        else if errorType is Types.Messages.GUILDERRORTYPE.IDWARNING
          @showNotification "WARNING: the server was rebooted."
          setTimeout (=> @showNotification "#{info} has changed ID."), 2500
        else @showNotification "#{info} is ALREADY a member of “#{@player.getGuild().name}”" if errorType is Types.Messages.GUILDERRORTYPE.BADINVITE

      @client.onGuildCreate (guildId, guildName) =>
        @player.setGuild new Guild(guildId, guildName)
        @storage.setPlayerGuild @player.getGuild()
        @showNotification "You successfully created and joined…"
        setTimeout (=> @showNotification "…#{@player.getGuild().name}"), 2500

      @client.onGuildInvite (guildId, guildName, invitorName) =>
        @showNotification "#{invitorName} invited you to join “#{guildName}”."
        @player.addInvite guildId
        setTimeout (=>
          $("#chatinput").attr "placeholder", "Do you want to join #{guildName}? Type /guild accept yes or /guild accept no"
          @app.showChat()
        ), 2500

      @client.onGuildJoin (playerName, id, guildId, guildName) =>
        unless id?
          @showNotification "#{playerName} failed to answer to your invitation in time."
          setTimeout (=> @showNotification "Might have to send another invite…"), 2500
        else if id is false
          @showNotification "#{playerName} respectfully declined your offer…"
          setTimeout (=> @showNotification "…to join “#{@player.getGuild().name}”."), 2500
        else if id is @player.id
          @player.setGuild new Guild(guildId, guildName)
          @storage.setPlayerGuild @player.getGuild()
          @showNotification "You just joined “#{guildName}”."
        else
          @showNotification "#{playerName} is now a jolly member of “#{guildName}”."
          #TODO: updateguild

      @client.onGuildLeave (name, playerId, guildName) =>
        if @player.id is playerId
          if @player.hasGuild()
            if @player.getGuild().name is guildName #do not erase new guild on create
              @player.unsetGuild()
              @storage.setPlayerGuild()
              @showNotification "You successfully left “#{guildName}”."

        # missing elses above should not happen (errors)
        else
          @showNotification "#{name} has left “#{guildName}”."
          #TODO: updateguild

      @client.onGuildTalk (name, id, message) =>
        if id is @player.id
          @showNotification "YOU: #{message}"
        else
          @showNotification "#{name}: #{message}"

      @client.onMemberConnect (name) =>
        @showNotification "#{name} connected to your world."
        #TODO: updateguild

      @client.onMemberDisconnect (name) =>
        @showNotification "#{name} lost connection with your world."

      @client.onReceiveGuildMembers (memberNames) =>
        @showNotification "#{memberNames.join(", ")} #{if memberNames.length is 1 then "is" else "are"} currently online."
        #TODO: updateguild

      @client.onEntityMove (id, x, y) =>
        entity = null
        if id isnt @playerId
          entity = @getEntityById(id)
          if entity
            @tryUnlockingAchievement "COWARD" if @player.isAttackedBy(entity)
            entity.disengage()
            entity.idle()
            @makeCharacterGoTo entity, x, y

      @client.onEntityDestroy (id) =>
        entity = @getEntityById(id)
        if entity
          if entity instanceof Item
            @removeItem entity
          else
            @removeEntity entity
          log.debug "Entity was destroyed: #{entity.id}"

      @client.onPlayerMoveToItem (playerId, itemId) =>
        player = undefined
        item = undefined
        if playerId isnt @playerId
          player = @getEntityById(playerId)
          item = @getEntityById(itemId)
          @makeCharacterGoTo player, item.gridX, item.gridY  if player and item

      @client.onEntityAttack (attackerId, targetId) =>
        attacker = @getEntityById(attackerId)
        target = @getEntityById(targetId)
        if attacker and target and attacker.id isnt @playerId
          log.debug attacker.id + " attacks " + target.id
          if attacker and target instanceof Player and target.id isnt @playerId and target.target and target.target.id is attacker.id and attacker.getDistanceToEntity(target) < 3
            # delay to prevent other players attacking mobs from ending up on the same tile as they walk towards each other.
            setTimeout (=> @createAttackLink attacker, target), 200
          else
            @createAttackLink attacker, target

      @client.onPlayerDamageMob (mobId, points, healthPoints, maxHp) =>
        mob = @getEntityById(mobId)
        @infoManager.addDamageInfo points, mob.x, mob.y - 15, "inflicted"  if mob and points
        @updateTarget mobId, points, healthPoints, maxHp  if @player.hasTarget()

      @client.onPlayerKillMob (kind, level, exp) =>
        mobExp = Types.getMobExp(kind)
        @player.level = level
        @player.experience = exp
        @updateExpBar()
        @infoManager.addDamageInfo "+#{mobExp} exp", @player.x, @player.y - 15, "exp", 3000
        expInThisLevel = @player.experience - Types.expForLevel[@player.level - 1]
        expForLevelUp = Types.expForLevel[@player.level] - Types.expForLevel[@player.level - 1]
        expPercentThisLevel = (100 * expInThisLevel / expForLevelUp)
        @showNotification "Total xp: #{@player.experience}. #{expPercentThisLevel.toFixed(0)}% of this level done."
        mobName = Types.getKindAsString(kind)
        mobName = "greater skeleton" if mobName is "skeleton2"
        mobName = "evil eye" if mobName is "eye"
        mobName = "death knight" if mobName is "deathknight"
        @showNotification "You killed the skeleton king" if mobName is "boss"
        @storage.incrementTotalKills()
        @tryUnlockingAchievement "HUNTER"
        if kind is Types.Entities.RAT
          @storage.incrementRatCount()
          @tryUnlockingAchievement "ANGRY_RATS"
        if kind is Types.Entities.SKELETON or kind is Types.Entities.SKELETON2
          @storage.incrementSkeletonCount()
          @tryUnlockingAchievement "SKULL_COLLECTOR"
        @tryUnlockingAchievement "HERO"  if kind is Types.Entities.BOSS

      @client.onPlayerChangeHealth (points, isRegen) =>
        player = @player
        diff = undefined
        isHurt = undefined
        if player and not player.isDead and not player.invincible
          isHurt = points <= player.hitPoints
          diff = points - player.hitPoints
          player.hitPoints = points
          player.die()  if player.hitPoints <= 0
          if isHurt
            player.hurt()
            @infoManager.addDamageInfo diff, player.x, player.y - 15, "received"
            @audioManager.playSound "hurt"
            @storage.addDamage -diff
            @tryUnlockingAchievement "MEATSHIELD"
            @playerhurt_callback()  if @playerhurt_callback
          else @infoManager.addDamageInfo "+" + diff, player.x, player.y - 15, "healed"  unless isRegen
          @updateBars()

      @client.onPlayerChangeMaxHitPoints (hp) =>
        @player.maxHitPoints = hp
        @player.hitPoints = hp
        @updateBars()

      @client.onPlayerEquipItem (playerId, itemKind) =>
        player = @getEntityById(playerId)
        itemName = Types.getKindAsString(itemKind)
        if player
          if Types.isArmor(itemKind)
            player.setSprite @sprites[itemName]
          else player.setWeaponName itemName if Types.isWeapon(itemKind)

      @client.onPlayerTeleport (id, x, y) =>
        entity = null
        currentOrientation = undefined
        if id isnt @playerId
          entity = @getEntityById(id)
          if entity
            currentOrientation = entity.orientation
            @makeCharacterTeleportTo entity, x, y
            entity.setOrientation currentOrientation
            entity.forEachAttacker (attacker) ->
              attacker.disengage()
              attacker.idle()
              attacker.stop()

      @client.onDropItem (item, mobId) =>
        pos = @getDeadMobPosition(mobId)
        if pos
          @addItem item, pos.x, pos.y
          @updateCursor()

      @client.onChatMessage (entityId, message) =>
        entity = @getEntityById(entityId)
        @createBubble entityId, message
        @assignBubbleTo entity
        @audioManager.playSound "chat"

      @client.onPopulationChange (worldPlayers, totalPlayers) =>
        @nbplayers_callback worldPlayers, totalPlayers if @nbplayers_callback

      @client.onGuildPopulation (guildName, guildPopulation) =>
        @nbguildplayers_callback guildName, guildPopulation if @nbguildplayers_callback

      @client.onDisconnected (message) =>
        @player.die() if @player
        @disconnect_callback message if @disconnect_callback

      @gamestart_callback()
      if @hasNeverStarted
        @start()
        started_callback success: true

  ###
  Links two entities in an attacker<-->target relationship.
  This is just a utility method to wrap a set of instructions.

  @param {Entity} attacker The attacker entity
  @param {Entity} target The target entity
  ###
  createAttackLink: (attacker, target) ->
    attacker.removeTarget() if attacker.hasTarget()
    attacker.engage target
    target.addAttacker attacker if attacker.id isnt @playerId

  ###
  Converts the current mouse position on the screen to world grid coordinates.
  @returns {Object} An object containing x and y properties.
  ###
  getMouseGridPosition: ->
    mx = @mouse.x
    my = @mouse.y
    c = @renderer.camera
    s = @renderer.scale
    ts = @renderer.tilesize
    offsetX = mx % (ts * s)
    offsetY = my % (ts * s)
    x: ((mx - offsetX) / (ts * s)) + c.gridX
    y: ((my - offsetY) / (ts * s)) + c.gridY

  ###
  Moves a character to a given location on the world grid.

  @param {Number} x The x coordinate of the target location.
  @param {Number} y The y coordinate of the target location.
  ###
  makeCharacterGoTo: (character, x, y) ->
    character.go x, y unless @map.isOutOfBounds(x, y)

  makeCharacterTeleportTo: (character, x, y) ->
    unless @map.isOutOfBounds(x, y)
      @unregisterEntityPosition character
      character.setGridPosition x, y
      @registerEntityPosition character
      @assignBubbleTo character
    else
      log.debug "Teleport out of bounds: #{x}, #{y}"

  makePlayerAttackNext: ->
    pos =
      x: @player.gridX
      y: @player.gridY

    switch @player.orientation
      when Types.Orientations.DOWN
        pos.y += 1
        @makePlayerAttackTo pos
      when Types.Orientations.UP
        pos.y -= 1
        @makePlayerAttackTo pos
      when Types.Orientations.LEFT
        pos.x -= 1
        @makePlayerAttackTo pos
      when Types.Orientations.RIGHT
        pos.x += 1
        @makePlayerAttackTo pos

  makePlayerAttackTo: (pos) ->
    entity = @getEntityAt(pos.x, pos.y)
    @makePlayerAttack entity if entity instanceof Mob

  ###
  Moves the current player to a given target location.
  @see makeCharacterGoTo
  ###
  makePlayerGoTo: (x, y) ->
    @makeCharacterGoTo @player, x, y

  ###
  Moves the current player towards a specific item.
  @see makeCharacterGoTo
  ###
  makePlayerGoToItem: (item) ->
    if item
      @player.isLootMoving = true
      @makePlayerGoTo item.gridX, item.gridY
      @client.sendLootMove item, item.gridX, item.gridY

  makePlayerTalkTo: (npc) ->
    if npc
      @player.setTarget npc
      @player.follow npc

  makePlayerOpenChest: (chest) ->
    if chest
      @player.setTarget chest
      @player.follow chest

  makePlayerAttack: (mob) ->
    @createAttackLink @player, mob
    @client.sendAttack mob

  makeNpcTalk: (npc) ->
    msg = undefined
    if npc
      msg = npc.talk(this)
      @previousClickPosition = {}
      if msg
        @createBubble npc.id, msg
        @assignBubbleTo npc
        @audioManager.playSound "npc"
      else
        @destroyBubble npc.id
        @audioManager.playSound "npc-end"
      @tryUnlockingAchievement "SMALL_TALK"
      @tryUnlockingAchievement "RICKROLLD"  if npc.kind is Types.Entities.RICK

  ###
  Loops through all the entities currently present in the game.
  @param {Function} callback The function to call back (must accept one entity argument).
  ###
  forEachEntity: (callback) ->
    _.each @entities, (entity) ->
      callback entity

  ###
  Same as forEachEntity but only for instances of the Mob subclass.
  @see forEachEntity
  ###
  forEachMob: (callback) ->
    _.each @entities, (entity) ->
      callback entity  if entity instanceof Mob

  ###
  Loops through all entities visible by the camera and sorted by depth :
  Lower 'y' value means higher depth.
  Note: This is used by the Renderer to know in which order to render entities.
  ###
  forEachVisibleEntityByDepth: (callback) ->
    @camera.forEachVisiblePosition ((x, y) =>
      unless @map.isOutOfBounds(x, y)
        if @renderingGrid[y][x]
          _.each @renderingGrid[y][x], (entity) ->
            callback entity
    ), (if @renderer.mobile then 0 else 2)

  forEachVisibleTileIndex: (callback, extra) ->
    @camera.forEachVisiblePosition ((x, y) =>
      callback @map.GridPositionToTileIndex(x, y) - 1  unless @map.isOutOfBounds(x, y)
    ), extra

  forEachVisibleTile: (callback, extra) ->
    if @map.isLoaded
      @forEachVisibleTileIndex ((tileIndex) =>
        if _.isArray(@map.data[tileIndex])
          _.each @map.data[tileIndex], (id) ->
            callback id - 1, tileIndex
        else
          if _.isNaN(@map.data[tileIndex] - 1)
            #FIXME: this happens sometimes when entering certaing caves
            #throw new Error "Tile number for index:#{tileIndex} is NaN"
            log.error "Tile number for index:#{tileIndex} is NaN"
          else
            callback @map.data[tileIndex] - 1, tileIndex
      ), extra

  forEachAnimatedTile: (callback) ->
    if @animatedTiles
      _.each @animatedTiles, (tile) ->
        callback tile

  ###
  Returns the entity located at the given position on the world grid.
  @returns {Entity} the entity located at (x, y) or null if there is none.
  ###
  getEntityAt: (x, y) ->
    return null  if @map.isOutOfBounds(x, y) or not @entityGrid
    entities = @entityGrid[y][x]
    entity = null
    if _.size(entities) > 0
      entity = entities[_.keys(entities)[0]]
    else
      entity = @getItemAt(x, y)
    entity

  getMobAt: (x, y) ->
    entity = @getEntityAt(x, y)
    return entity if entity and (entity instanceof Mob)
    null

  getPlayerAt: (x, y) ->
    entity = @getEntityAt(x, y)
    return entity if entity and (entity instanceof Player) and (entity isnt @player) and @player.pvpFlag
    null

  getNpcAt: (x, y) ->
    entity = @getEntityAt(x, y)
    return entity if entity and (entity instanceof Npc)
    null

  getChestAt: (x, y) ->
    entity = @getEntityAt(x, y)
    return entity if entity and (entity instanceof Chest)
    null

  getItemAt: (x, y) ->
    return null if @map.isOutOfBounds(x, y) or not @itemGrid
    items = @itemGrid[y][x]
    item = null
    if _.size(items) > 0

      # If there are potions/burgers stacked with equipment items on the same tile, always get expendable items first.
      _.each items, (i) ->
        item = i  if Types.isExpendableItem(i.kind)

      # Else, get the first item of the stack
      item = items[_.keys(items)[0]]  unless item
    item

  ###
  Returns true if an entity is located at the given position on the world grid.
  @returns {Boolean} Whether an entity is at (x, y).
  ###
  isEntityAt: (x, y) ->
    not _.isNull(@getEntityAt(x, y))

  isMobAt: (x, y) ->
    not _.isNull(@getMobAt(x, y))

  isPlayerAt: (x, y) ->
    not _.isNull(@getPlayerAt(x, y))

  isItemAt: (x, y) ->
    not _.isNull(@getItemAt(x, y))

  isNpcAt: (x, y) ->
    not _.isNull(@getNpcAt(x, y))

  isChestAt: (x, y) ->
    not _.isNull(@getChestAt(x, y))

  ###
  Finds a path to a grid position for the specified character.
  The path will pass through any entity present in the ignore list.
  ###
  findPath: (character, x, y, ignoreList) ->
    path = []
    isPlayer = (character is @player)
    return path if @map.isColliding(x, y)
    if @pathfinder and character
      if ignoreList
        _.each ignoreList, (entity) =>
          @pathfinder.ignoreEntity entity
      path = @pathfinder.findPath(@pathingGrid, character, x, y, false)
      @pathfinder.clearIgnoreList()  if ignoreList
    else
      log.error "Error while finding the path to " + x + ", " + y + " for " + character.id
    path

  ###
  Toggles the visibility of the pathing grid for debugging purposes.
  ###
  togglePathingGrid: ->
    if @debugPathing
      @debugPathing = false
    else
      @debugPathing = true

  ###
  Toggles the visibility of the FPS counter and other debugging info.
  ###
  toggleDebugInfo: ->
    if @renderer and @renderer.isDebugInfoVisible
      @renderer.isDebugInfoVisible = false
    else
      @renderer.isDebugInfoVisible = true

  movecursor: ->
    mouse = @getMouseGridPosition()
    x = mouse.x
    y = mouse.y
    @cursorVisible = true
    if @player and not @renderer.mobile and not @renderer.tablet
      @hoveringCollidingTile = @map.isColliding(x, y)
      @hoveringPlateauTile = (if @player.isOnPlateau then not @map.isPlateau(x, y) else @map.isPlateau(x, y))
      @hoveringMob = @isMobAt(x, y)
      @hoveringPlayer = @isPlayerAt(x, y)
      @hoveringItem = @isItemAt(x, y)
      @hoveringNpc = @isNpcAt(x, y)
      @hoveringOtherPlayer = @isPlayerAt(x, y)
      @hoveringChest = @isChestAt(x, y)
      if @hoveringMob or @hoveringPlayer or @hoveringNpc or @hoveringChest or @hoveringOtherPlayer
        entity = @getEntityAt(x, y)
        @player.showTarget entity
        if not entity.isHighlighted and @renderer.supportsSilhouettes
          @lastHovered.setHighlight false  if @lastHovered
          entity.setHighlight true
        @lastHovered = entity
      else if @lastHovered
        @lastHovered.setHighlight null
        #if not @timeout? and not @player.hasTarget()
        unless @timeout? or @player.hasTarget()
          @timeout = setTimeout(=>
            $("#inspector").fadeOut "fast"
            $("#inspector .health").text ""
            @player.inspecting = null
          , 2000)
          #XXX: why's this?:
          @timeout = null
        @lastHovered = null

  ###
  Moves the player one space, if possible
  ###
  keys: (pos, orientation) ->
    @hoveringCollidingTile = false
    @hoveringPlateauTile = false
    if (pos.x is @previousClickPosition.x and pos.y is @previousClickPosition.y) or @isZoning()
      return
    else
      @previousClickPosition = pos  unless @player.disableKeyboardNpcTalk
    unless @player.isMoving()
      @cursorVisible = false
      @processInput pos
    return

  click: ->
    pos = @getMouseGridPosition()
    if pos.x is @previousClickPosition.x and pos.y is @previousClickPosition.y
      return
    else
      @previousClickPosition = pos
    @processInput pos

  ###
  Processes game logic when the user triggers a click/touch event during the game.
  ###
  processInput: (pos) ->
    entity = undefined
    if @started and @player and not @isZoning() and not @isZoningTile(@player.nextGridX, @player.nextGridY) and not @player.isDead and not @hoveringCollidingTile and not @hoveringPlateauTile
      entity = @getEntityAt(pos.x, pos.y)
      if entity instanceof Mob or (entity instanceof Player and entity isnt @player and @player.pvpFlag and @pvpFlag)
        @makePlayerAttack entity
      else if entity instanceof Item
        @makePlayerGoToItem entity
      else if entity instanceof Npc
        if @player.isAdjacentNonDiagonal(entity) is false
          @makePlayerTalkTo entity
        else
          unless @player.disableKeyboardNpcTalk
            @makeNpcTalk entity
            @player.disableKeyboardNpcTalk = true if @player.moveUp or @player.moveDown or @player.moveLeft or @player.moveRight
      else if entity instanceof Chest
        @makePlayerOpenChest entity
      else
        @makePlayerGoTo pos.x, pos.y

  isMobOnSameTile: (mob, x, y) ->
    X = x or mob.gridX
    Y = y or mob.gridY
    list = @entityGrid[Y][X]
    result = false
    _.each list, (entity) ->
      result = true if entity instanceof Mob and entity.id isnt mob.id
    result

  getFreeAdjacentNonDiagonalPosition: (entity) ->
    result = null
    entity.forEachAdjacentNonDiagonalPosition (x, y, orientation) =>
      if not result and not @map.isColliding(x, y) and not @isMobAt(x, y)
        result =
          x: x
          y: y
          o: orientation
    result

  tryMovingToADifferentTile: (character) ->
    attacker = character
    target = character.target
    if attacker and target and target instanceof Player
      if not target.isMoving() and attacker.getDistanceToEntity(target) is 0
        pos = undefined
        switch target.orientation
          when Types.Orientations.UP
            pos =
              x: target.gridX
              y: target.gridY - 1
              o: target.orientation
          when Types.Orientations.DOWN
            pos =
              x: target.gridX
              y: target.gridY + 1
              o: target.orientation
          when Types.Orientations.LEFT
            pos =
              x: target.gridX - 1
              y: target.gridY
              o: target.orientation
          when Types.Orientations.RIGHT
            pos =
              x: target.gridX + 1
              y: target.gridY
              o: target.orientation
        if pos
          attacker.previousTarget = target
          attacker.disengage()
          attacker.idle()
          @makeCharacterGoTo attacker, pos.x, pos.y
          target.adjacentTiles[pos.o] = true
          return true
      if not target.isMoving() and attacker.isAdjacentNonDiagonal(target) and @isMobOnSameTile(attacker)
        pos = @getFreeAdjacentNonDiagonalPosition(target)

        # avoid stacking mobs on the same tile next to a player
        # by making them go to adjacent tiles if they are available
        if pos and not target.adjacentTiles[pos.o]
          return false  if @player.target and attacker.id is @player.target.id # never unstack the player's target
          attacker.previousTarget = target
          attacker.disengage()
          attacker.idle()
          @makeCharacterGoTo attacker, pos.x, pos.y
          target.adjacentTiles[pos.o] = true
          return true
    false

  onCharacterUpdate: (character) ->
    time = @currentTime

    # If mob has finished moving to a different tile in order to avoid stacking, attack again from the new position.
    if character.previousTarget and not character.isMoving() and character instanceof Mob
      t = character.previousTarget
      if @getEntityById(t.id) # does it still exist?
        character.previousTarget = null
        @createAttackLink character, t
        return
    if character.isAttacking() and (not character.previousTarget or character.id is @playerId)
      isMoving = @tryMovingToADifferentTile(character) # Don't let multiple mobs stack on the same tile when attacking a player.
      if character.canAttack(time)
        unless isMoving # don't hit target if moving to a different tile.
          character.lookAtTarget()  if character.hasTarget() and character.getOrientationTo(character.target) isnt character.orientation
          character.hit()
          @client.sendHit character.target  if character.id is @playerId
          @audioManager.playSound "hit" + Math.floor(Math.random() * 2 + 1)  if character instanceof Player and @camera.isVisible(character)
          @client.sendHurt character  if character.hasTarget() and character.target.id is @playerId and @player and not @player.invincible
      else
        character.follow character.target  if character.hasTarget() and character.isDiagonallyAdjacent(character.target) and character.target instanceof Player and not character.target.isMoving()

  isZoningTile: (x, y) ->
    c = @camera
    x = x - c.gridX
    y = y - c.gridY
    return true  if x is 0 or y is 0 or x is c.gridW - 1 or y is c.gridH - 1
    false

  getZoningOrientation: (x, y) ->
    orientation = ""
    c = @camera
    x = x - c.gridX
    y = y - c.gridY
    if x is 0
      orientation = Types.Orientations.LEFT
    else if y is 0
      orientation = Types.Orientations.UP
    else if x is c.gridW - 1
      orientation = Types.Orientations.RIGHT
    else orientation = Types.Orientations.DOWN  if y is c.gridH - 1
    orientation

  startZoningFrom: (x, y) ->
    @zoningOrientation = @getZoningOrientation(x, y)
    if @renderer.mobile or @renderer.tablet
      z = @zoningOrientation
      c = @camera
      ts = @renderer.tilesize
      x = c.x
      y = c.y
      xoffset = (c.gridW - 2) * ts
      yoffset = (c.gridH - 2) * ts
      if z is Types.Orientations.LEFT or z is Types.Orientations.RIGHT
        x = (if (z is Types.Orientations.LEFT) then c.x - xoffset else c.x + xoffset)
      else y = (if (z is Types.Orientations.UP) then c.y - yoffset else c.y + yoffset)  if z is Types.Orientations.UP or z is Types.Orientations.DOWN
      c.setPosition x, y
      @renderer.clearScreen @renderer.context
      @endZoning()

      # Force immediate drawing of all visible entities in the new zone
      @forEachVisibleEntityByDepth (entity) -> entity.setDirty()

    else
      @currentZoning = new Transition()
    @bubbleManager.clean()
    @client.sendZone()

  enqueueZoningFrom: (x, y) ->
    @zoningQueue.push
      x: x
      y: y
    @startZoningFrom x, y  if @zoningQueue.length is 1

  endZoning: ->
    @currentZoning = null
    @resetZone()
    @zoningQueue.shift()
    if @zoningQueue.length > 0
      pos = @zoningQueue[0]
      @startZoningFrom pos.x, pos.y

  isZoning: ->
    not _.isNull(@currentZoning)

  resetZone: ->
    @bubbleManager.clean()
    @initAnimatedTiles()
    @renderer.renderStaticCanvases()

  resetCamera: ->
    @camera.focusEntity @player
    @resetZone()

  say: (message) ->
    ##cli guilds
    regexp = /^\/guild\ (invite|create|accept)\s+([^\s]*)|(guild:)\s*(.*)$|^\/guild\ (leave)$/i
    args = message.match(regexp)
    if args?
      switch args[1]
        when "invite"
          if @player.hasGuild()
            @client.sendGuildInvite args[2]
          else
            @showNotification "Invite #{args[2]} to where?"
        when "create"
          @client.sendNewGuild args[2]
        when undefined
          if args[5] is "leave"
            @client.sendLeaveGuild()
          else if @player.hasGuild()
            @client.talkToGuild args[4]
          else
            @showNotification "You got no-one to talk to…"
        when "accept"
          status = undefined
          if args[2] is "yes"
            status = @player.checkInvite()
            if status is false
              @showNotification "You were not invited anyway…"
            else if status < 0
              @showNotification "Sorry to say it's too late…"
              setTimeout (=> @showNotification "Find someone and ask for another invite."), 2500
            else
              @client.sendGuildInviteReply @player.invite.guildId, true
          else if args[2] is "no"
            status = @player.checkInvite()
            if status isnt false
              @client.sendGuildInviteReply @player.invite.guildId, false
              @player.deleteInvite()
            else
              @showNotification "Whatever…"
          else
            @showNotification "“guild accept” is a YES or NO question!!"
    @client.sendChat message

  createBubble: (id, message) ->
    @bubbleManager.create id, message, @currentTime

  destroyBubble: (id) ->
    @bubbleManager.destroyBubble id

  assignBubbleTo: (character) ->
    bubble = @bubbleManager.getBubbleById(character.id)
    if bubble
      s = @renderer.scale
      t = 16 * s # tile size
      x = ((character.x - @camera.x) * s)
      w = parseInt(bubble.element.css("width")) + 24
      offset = (w / 2) - (t / 2)
      offsetY = undefined
      y = undefined
      if character instanceof Npc
        offsetY = 0
      else
        if s is 2
          if @renderer.mobile
            offsetY = 0
          else
            offsetY = 15
        else
          offsetY = 12
      y = ((character.y - @camera.y) * s) - (t * 2) - offsetY
      bubble.element.css "left", x - offset + "px"
      bubble.element.css "top", y + "px"

  respawn: ->
    log.debug "Beginning respawn"
    @entities = {}
    @initEntityGrid()
    @initPathingGrid()
    @initRenderingGrid()
    @player = new Warrior("player", @username)
    @player.pw = @userpw
    @player.email = @email
    @initPlayer()
    @app.initTargetHud()
    @started = true
    @client.enable()
    @client.sendLogin @player
    @storage.incrementRevives()
    @renderer.clearScreen @renderer.context  if @renderer.mobile or @renderer.tablet
    log.debug "Finished respawn"

  onGameStart: (callback) ->
    @gamestart_callback = callback

  onDisconnect: (callback) ->
    @disconnect_callback = callback

  onPlayerDeath: (callback) ->
    @playerdeath_callback = callback

  onUpdateTarget: (callback) ->
    @updatetarget_callback = callback

  onPlayerExpChange: (callback) ->
    @playerexp_callback = callback

  onPlayerHealthChange: (callback) ->
    @playerhp_callback = callback

  onPlayerHurt: (callback) ->
    @playerhurt_callback = callback

  onPlayerEquipmentChange: (callback) ->
    @equipment_callback = callback

  onNbPlayersChange: (callback) ->
    @nbplayers_callback = callback

  onGuildPopulationChange: (callback) ->
    @nbguildplayers_callback = callback

  onNotification: (callback) ->
    @notification_callback = callback

  onPlayerInvincible: (callback) ->
    @invincible_callback = callback

  resize: ->
    x = @camera.x
    y = @camera.y
    currentScale = @renderer.scale
    newScale = @renderer.getScaleFactor()
    @renderer.rescale newScale
    @camera = @renderer.camera
    @camera.setPosition x, y
    @renderer.renderStaticCanvases()

  updateBars: ->
    @playerhp_callback @player.hitPoints, @player.maxHitPoints  if @player and @playerhp_callback

  updateExpBar: ->
    if @player and @playerexp_callback
      expInThisLevel = @player.experience - Types.expForLevel[@player.level - 1]
      expForLevelUp = Types.expForLevel[@player.level] - Types.expForLevel[@player.level - 1]
      @playerexp_callback expInThisLevel, expForLevelUp

  updateTarget: (targetId, points, healthPoints, maxHp) ->
    if @player.hasTarget() and @updatetarget_callback
      target = @getEntityById(targetId)
      if target?
        target.name = Types.getKindAsString(target.kind)
        target.points = points
        target.healthPoints = healthPoints
        target.maxHp = maxHp
        @updatetarget_callback target
      else
        log.error "Target of id:#{targetId} not found."

  getDeadMobPosition: (mobId) ->
    position = undefined
    if mobId of @deathpositions
      position = @deathpositions[mobId]
      delete @deathpositions[mobId]
    position

  onAchievementUnlock: (callback) ->
    @unlock_callback = callback

  tryUnlockingAchievement: (name) ->
    achievement = null
    if name of @achievements
      achievement = @achievements[name]
      if achievement.isCompleted() and @storage.unlockAchievement(achievement.id)
        if @unlock_callback
          @unlock_callback achievement.id, achievement.name, achievement.desc
          @audioManager.playSound "achievement"

  showNotification: (message) ->
    @notification_callback message if @notification_callback

  removeObsoleteEntities: ->
    nb = _.size(@obsoleteEntities)
    if nb > 0
      _.each @obsoleteEntities, (entity) =>
        # never remove yourself
        @removeEntity entity unless entity.id is @player.id

      log.debug "Removed " + nb + " entities: " + _.pluck(_.reject(@obsoleteEntities, (id) => id is @player.id), "id")
      @obsoleteEntities = null

  ###
  Fake a mouse move event in order to update the cursor.

  For instance, to get rid of the sword cursor in case the mouse is still hovering over a dying mob.
  Also useful when the mouse is hovering a tile where an item is appearing.
  ###
  updateCursor: ->
    keepCursorHidden = true unless @cursorVisible
    @movecursor()
    @updateCursorLogic()
    @cursorVisible = false if keepCursorHidden

  ###
  Change player plateau mode when necessary
  ###
  updatePlateauMode: ->
    if @map.isPlateau(@player.gridX, @player.gridY)
      @player.isOnPlateau = true
    else
      @player.isOnPlateau = false

  updatePlayerCheckpoint: ->
    checkpoint = @map.getCurrentCheckpoint(@player)
    if checkpoint
      lastCheckpoint = @player.lastCheckpoint
      if not lastCheckpoint or (lastCheckpoint and lastCheckpoint.id isnt checkpoint.id)
        @player.lastCheckpoint = checkpoint
        @client.sendCheck checkpoint.id

  checkUndergroundAchievement: ->
    music = @audioManager.getSurroundingMusic(@player)
    @tryUnlockingAchievement "UNDERGROUND"  if music.name is "cave"  if music

  makeAttackerFollow: (attacker) ->
    target = attacker.target
    if attacker.isAdjacent(attacker.target)
      attacker.lookAtTarget()
    else
      attacker.follow target

  forEachEntityAround: (x, y, r, callback) ->
    for i in [x - r..x + r]
      for j in [y - r..y + r]
        unless @map.isOutOfBounds(i, j)
          _.each @renderingGrid[j][i], (entity) ->
            callback entity

  checkOtherDirtyRects: (r1, source, x, y) ->
    r = @renderer
    @forEachEntityAround x, y, 2, (e2) ->
      return  if source and source.id and e2.id is source.id
      unless e2.isDirty
        r2 = r.getEntityBoundingRect(e2)
        e2.setDirty() if r.isIntersecting(r1, r2)

    if source and not (source.hasOwnProperty("index"))
      @forEachAnimatedTile (tile) ->
        unless tile.isDirty
          r2 = r.getTileBoundingRect(tile)
          tile.isDirty = true if r.isIntersecting(r1, r2)

    if not @drawTarget and @selectedCellVisible
      targetRect = r.getTargetBoundingRect()
      if r.isIntersecting(r1, targetRect)
        @drawTarget = true
        @renderer.targetRect = targetRect

  tryLootingItem: (item) ->
    try
      @player.loot item
      @client.sendLoot item # Notify the server that this item has been looted
      @removeItem item
      @showNotification item.getLootMessage()
      @tryUnlockingAchievement "FAT_LOOT"  if item.type is "armor"
      @tryUnlockingAchievement "A_TRUE_WARRIOR"  if item.type is "weapon"
      @tryUnlockingAchievement "FOR_SCIENCE"  if item.kind is Types.Entities.CAKE
      if item.kind is Types.Entities.FIREPOTION
        @tryUnlockingAchievement "FOXY"
        @audioManager.playSound "firefox"
      if Types.isHealingItem(item.kind)
        @audioManager.playSound "heal"
      else
        @audioManager.playSound "loot"
      @tryUnlockingAchievement "NINJA_LOOT"  if item.wasDropped and not _(item.playersInvolved).include(@playerId)
    catch e
      if e instanceof Exceptions.LootException
        @showNotification e.message
        @audioManager.playSound "noloot"
      else
        throw e

module.exports = Game
