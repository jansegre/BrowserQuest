Entity = require("./entity")
Types = require("./types")

class Item extends Entity
  constructor: (id, kind, @type) ->
    super id, kind
    @itemKind = Types.getKindAsString(kind)
    @wasDropped = false

  hasShadow: ->
    true

  onLoot: (player) ->
    if @type is "weapon"
      player.switchWeapon @itemKind
    else player.armorloot_callback @itemKind  if @type is "armor"

  getSpriteName: ->
    "item-#{@itemKind}"

  getLootMessage: ->
    @lootMessage

module.exports = Item
