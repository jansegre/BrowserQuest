$ = require("jquery")
sprites = require("./sprites")
log = require("./log")
Animation = require("./animation")

class Sprite
  constructor: (@name, @scale) ->
    @isLoaded = false
    @offsetX = 0
    @offsetY = 0
    @loadJSON sprites[name]

  loadJSON: (data) ->
    @id = data.id
    @filepath = "img/" + @scale + "/" + @id + ".png"
    @animationData = data.animations
    @width = data.width
    @height = data.height
    @offsetX = data.offset_x or -16
    @offsetY = data.offset_y or -16
    @load()

  load: ->
    @image = new Image()
    @image.crossOrigin = "Anonymous"
    @image.src = @filepath
    @image.onload = =>
      @isLoaded = true
      @onload_func() if @onload_func

  createAnimations: ->
    animations = {}
    for name of @animationData
      a = @animationData[name]
      animations[name] = new Animation(name, a.length, a.row, @width, @height)
    animations

  createHurtSprite: ->
    canvas = document.createElement("canvas")
    ctx = canvas.getContext("2d")
    width = @image.width
    height = @image.height
    spriteData = undefined
    data = undefined
    canvas.width = width
    canvas.height = height
    ctx.drawImage @image, 0, 0, width, height

    #TODO: investigate the issue where width and height are 0 when ran here, but non-0 a while after
    try
      spriteData = ctx.getImageData(0, 0, width, height)
      data = spriteData.data

      i = 0
      while i < data.length
        data[i] = 255
        data[i + 1] = data[i + 2] = 75
        i += 4
      spriteData.data = data
      ctx.putImageData spriteData, 0, 0
      @whiteSprite =
        image: canvas
        isLoaded: true
        offsetX: @offsetX
        offsetY: @offsetY
        width: @width
        height: @height

    catch e
      log.error "Error getting image data for sprite:#{@name}"

  getHurtSprite: ->
    @whiteSprite

  createSilhouette: ->
    canvas = document.createElement("canvas")
    ctx = canvas.getContext("2d")
    width = @image.width
    height = @image.height
    spriteData = undefined
    finalData = undefined
    data = undefined
    canvas.width = width
    canvas.height = height
    try
      ctx.drawImage @image, 0, 0, width, height
      data = ctx.getImageData(0, 0, width, height).data
      finalData = ctx.getImageData(0, 0, width, height)
      fdata = finalData.data
      getIndex = (x, y) ->
        ((width * (y - 1)) + x - 1) * 4

      getPosition = (i) ->
        x = undefined
        y = undefined
        i = (i / 4) + 1
        x = i % width
        y = ((i - x) / width) + 1
        x: x
        y: y

      hasAdjacentPixel = (i) ->
        pos = getPosition(i)
        return true  if pos.x < width and not isBlankPixel(getIndex(pos.x + 1, pos.y))
        return true  if pos.x > 1 and not isBlankPixel(getIndex(pos.x - 1, pos.y))
        return true  if pos.y < height and not isBlankPixel(getIndex(pos.x, pos.y + 1))
        return true  if pos.y > 1 and not isBlankPixel(getIndex(pos.x, pos.y - 1))
        false

      isBlankPixel = (i) ->
        return true  if i < 0 or i >= data.length
        data[i] is 0 and data[i + 1] is 0 and data[i + 2] is 0 and data[i + 3] is 0

      i = 0
      while i < data.length
        if isBlankPixel(i) and hasAdjacentPixel(i)
          fdata[i] = fdata[i + 1] = 255
          fdata[i + 2] = 150
          fdata[i + 3] = 150
        i += 4

      finalData.data = fdata
      ctx.putImageData finalData, 0, 0
      @silhouetteSprite =
        image: canvas
        isLoaded: true
        offsetX: @offsetX
        offsetY: @offsetY
        width: @width
        height: @height
    catch e
      @silhouetteSprite = this

module.exports = Sprite
