_ = require("underscore")
Item = require("./item")
Types = require("../shared/js/gametypes")
Utils = require("./utils")

class Chest extends Item
  constructor: (id, x, y) ->
    super id, Types.Entities.CHEST, x, y

  setItems: (@items) ->

  getRandomItem: ->
    nbItems = _.size(@items)
    item = null
    item = @items[Utils.random(nbItems)]  if nbItems > 0
    item

module.exports = Chest
