sanitizer = require("sanitizer")
Types = require("../shared/js/gametypes")

Utils = {}

Utils.sanitize = (string) ->
  # Strip unsafe tags, then escape as html entities.
  sanitizer.escape sanitizer.sanitize(string)

Utils.random = (range) ->
  Math.floor Math.random() * range

Utils.randomRange = (min, max) ->
  min + (Math.random() * (max - min))

Utils.randomInt = (min, max) ->
  min + Math.floor(Math.random() * (max - min + 1))

Utils.clamp = (min, max, value) ->
  if value < min
    min
  else if value > max
    max
  else
    value

Utils.randomOrientation = ->
  switch Utils.random(4)
    when 0 then Types.Orientations.LEFT
    when 1 then Types.Orientations.RIGHT
    when 2 then Types.Orientations.UP
    when 3 then Types.Orientations.DOWN

Utils.Mixin = (target, source) ->
  if source
    key = undefined
    keys = Object.keys(source)
    l = keys.length
    while l--
      key = keys[l]
      target[key] = source[key]  if source.hasOwnProperty(key)
  target

Utils.distanceTo = (x, y, x2, y2) ->
  distX = Math.abs(x - x2)
  distY = Math.abs(y - y2)
  (if (distX > distY) then distX else distY)

Utils.NaN2Zero = (num) ->
  if isNaN(num * 1)
    0
  else
    num * 1

Utils.trueFalse = (bool) ->
  (if bool is "true" then true else false)

module.exports = Utils
