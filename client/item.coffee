Entity = require("./entity")
Types = require("../common/types")

class Item extends Entity
  constructor: (id, kind, @type) ->
    super id, kind
    @itemKind = Types.getKindAsString(kind)
    @wasDropped = false

  hasShadow: -> true

  onLoot: (player) ->
    if @type is "weapon"
      player.switchWeapon @itemKind
    else if @type is "armor"
      player.armorloot_callback @itemKind

  getSpriteName: -> "item-#{@itemKind}"

  getLootMessage: -> @lootMessage

module.exports = Item
