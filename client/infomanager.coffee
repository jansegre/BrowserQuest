_ = require("underscore")

class InfoManager
  constructor: (@game) ->
    @infos = {}
    @destroyQueue = []

  addDamageInfo: (value, x, y, type, duration) ->
    time = @game.currentTime
    id = time + "" + ((if isNaN(value * 1) then value else value * 1)) + "" + x + "" + y
    info = new HoveringInfo(id, value, x, y, (if (duration) then duration else 1000), type)
    info.onDestroy (id) =>
      @destroyQueue.push id
    @infos[id] = info

  forEachInfo: (callback) ->
    _.each @infos, (info, id) ->
      callback info

  update: (time) ->
    @forEachInfo (info) ->
      info.update time

    _.each @destroyQueue, (id) =>
      delete @infos[id]

    @destroyQueue = []

damageInfoColors =
  received:
    fill: "rgb(255, 50, 50)"
    stroke: "rgb(255, 180, 180)"

  inflicted:
    fill: "white"
    stroke: "#373737"

  healed:
    fill: "rgb(80, 255, 80)"
    stroke: "rgb(50, 120, 50)"

  health:
    fill: "white"
    stroke: "#373737"

  exp:
    fill: "rgb(80, 80, 255)"
    stroke: "rgb(50, 50, 255)"

class HoveringInfo
  DURATION: 1000

  constructor: (@id, @value, @x, @y, @duration, type) ->
    @opacity = 1.0
    @lastTime = 0
    @speed = 100
    @fillColor = damageInfoColors[type].fill
    @strokeColor = damageInfoColors[type].stroke

  isTimeToAnimate: (time) ->
    (time - @lastTime) > @speed

  update: (time) ->
    if @isTimeToAnimate(time)
      @lastTime = time
      @tick()

  tick: ->
    @y -= 1  if @type isnt "health"
    @opacity -= (70 / @duration)
    @destroy()  if @opacity < 0

  onDestroy: (callback) ->
    @destroy_callback = callback

  destroy: ->
    @destroy_callback @id if @destroy_callback

module.exports = InfoManager
