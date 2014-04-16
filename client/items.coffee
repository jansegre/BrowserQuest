###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

Item = require("./item")
Types = require("../common/types")

Items = {}

class Items.Sword2 extends Item
  constructor: (id) ->
    super id, Types.Entities.SWORD2, "weapon"
    @lootMessage = "You pick up a steel sword"

class Items.Axe extends Item
  constructor: (id) ->
    super id, Types.Entities.AXE, "weapon"
    @lootMessage = "You pick up an axe"

class Items.RedSword extends Item
  constructor: (id) ->
    super id, Types.Entities.REDSWORD, "weapon"
    @lootMessage = "You pick up a blazing sword"

class Items.BlueSword extends Item
  constructor: (id) ->
    super id, Types.Entities.BLUESWORD, "weapon"
    @lootMessage = "You pick up a magic sword"

class Items.GoldenSword extends Item
  constructor: (id) ->
    super id, Types.Entities.GOLDENSWORD, "weapon"
    @lootMessage = "You pick up the ultimate sword"

class Items.MorningStar extends Item
  constructor: (id) ->
    super id, Types.Entities.MORNINGSTAR, "weapon"
    @lootMessage = "You pick up a morning star"

class Items.LeatherArmor extends Item
  constructor: (id) ->
    super id, Types.Entities.LEATHERARMOR, "armor"
    @lootMessage = "You equip a leather armor"

class Items.MailArmor extends Item
  constructor: (id) ->
    super id, Types.Entities.MAILARMOR, "armor"
    @lootMessage = "You equip a mail armor"

class Items.PlateArmor extends Item
  constructor: (id) ->
    super id, Types.Entities.PLATEARMOR, "armor"
    @lootMessage = "You equip a plate armor"

class Items.RedArmor extends Item
  constructor: (id) ->
    super id, Types.Entities.REDARMOR, "armor"
    @lootMessage = "You equip a ruby armor"

class Items.GoldenArmor extends Item
  constructor: (id) ->
    super id, Types.Entities.GOLDENARMOR, "armor"
    @lootMessage = "You equip a golden armor"

class Items.Flask extends Item
  constructor: (id) ->
    super id, Types.Entities.FLASK, "object"
    @lootMessage = "You drink a health potion"

class Items.Cake extends Item
  constructor: (id) ->
    super id, Types.Entities.CAKE, "object"
    @lootMessage = "You eat a cake"

class Items.Burger extends Item
  constructor: (id) ->
    super id, Types.Entities.BURGER, "object"
    @lootMessage = "You can haz rat burger"

class Items.FirePotion extends Item
  constructor: (id) ->
    super id, Types.Entities.FIREPOTION, "object"
    @lootMessage = "You feel the power of Firefox!"

  onLoot: (player) ->
    player.startInvincibility()

module.exports = Items
