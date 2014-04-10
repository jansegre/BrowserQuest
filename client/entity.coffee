Types = require("../common/types")
log = require("./log")

class Entity
  constructor: (@id, @kind) ->
    # Renderer
    @sprite = null
    @flipSpriteX = false
    @flipSpriteY = false
    @animations = null
    @currentAnimation = null
    @shadowOffsetY = 0

    # Position
    @setGridPosition 0, 0

    # Modes
    @isLoaded = false
    @isHighlighted = false
    @visible = true
    @isFading = false
    @setDirty()

  setName: (@name) ->

  setPosition: (@x, @y) ->

  setGridPosition: (@gridX, @gridY) ->
    @setPosition @gridX * 16, @gridY * 16

  setSprite: (sprite) ->
    unless sprite?
      log.error "#{@id}: sprite is #{sprite}", true
      throw new Error "Sprite error"
    return if @sprite and @sprite.name is sprite.name

    @sprite = sprite
    @normalSprite = @sprite

    @hurtSprite = sprite.getHurtSprite() if Types.isMob(@kind) or Types.isPlayer(@kind)

    @animations = sprite.createAnimations()

    @isLoaded = true
    @ready_func() if @ready_func

  getSprite: -> @sprite

  getSpriteName: -> Types.getKindAsString @kind

  getAnimationByName: (name) ->
    animation = null
    if name of @animations
      animation = @animations[name]
    else
      log.error "No animation called #{name}"
    animation

  setAnimation: (name, speed, count, onEndCount) ->
    if @isLoaded
      return if @currentAnimation and @currentAnimation.name is name
      s = @sprite
      a = @getAnimationByName(name)
      if a?
        @currentAnimation = a
        @currentAnimation.reset() if name.substr(0, 3) is "atk"
        @currentAnimation.setSpeed speed
        @currentAnimation.setCount (if count then count else 0), onEndCount or => @idle()
    else
      @log_error "Not ready for animation"

  hasShadow: ->
    false

  ready: (@ready_func) ->

  clean: -> @stopBlinking()

  log_info: (message) -> log.info "[#{@id}] #{message}"

  log_error: (message) -> log.error "[#{@id}] #{message}"

  setHighlight: (value) ->
    if value
      @sprite = @sprite.silhouetteSprite
      @isHighlighted = true
    else
      @sprite = @normalSprite
      @isHighlighted = false

  setVisible: (@visible) ->

  isVisible: -> @visible

  toggleVisibility: -> @setVisible not @visible

  getDistanceToEntity: (entity) ->
    distX = Math.abs(entity.gridX - @gridX)
    distY = Math.abs(entity.gridY - @gridY)
    Math.max(distX, distY)

  isCloseTo: (entity) ->
    close = false
    if entity?
      dx = Math.abs(entity.gridX - @gridX)
      dy = Math.abs(entity.gridY - @gridY)
      close = true  if dx < 30 and dy < 14
    close

  ###
  Returns true if the entity is adjacent to the given one.
  @returns {Boolean} Whether these two entities are adjacent.
  ###
  isAdjacent: (entity) ->
    return false unless entity?
    @getDistanceToEntity(entity) <= 1

  isAdjacentNonDiagonal: (entity) ->
    @isAdjacent(entity) and (@gridX is entity.gridX or @gridY is entity.gridY)

  isDiagonallyAdjacent: (entity) ->
    @isAdjacent(entity) and not @isAdjacentNonDiagonal(entity)

  forEachAdjacentNonDiagonalPosition: (callback) ->
    callback @gridX - 1, @gridY, Types.Orientations.LEFT
    callback @gridX, @gridY - 1, Types.Orientations.UP
    callback @gridX + 1, @gridY, Types.Orientations.RIGHT
    callback @gridX, @gridY + 1, Types.Orientations.DOWN

  fadeIn: (currentTime) ->
    @isFading = true
    @startFadingTime = currentTime

  blink: (speed, callback) ->
    @blinking = setInterval (=> @toggleVisibility()), speed

  stopBlinking: ->
    clearInterval @blinking if @blinking
    @setVisible true

  setDirty: ->
    @isDirty = true
    @dirty_callback this if @dirty_callback

  onDirty: (@dirty_callback) ->

module.exports = Entity
