Player = require("./player")
Types = require("../common/types")

class Warrior extends Player
  constructor: (id, name) ->
    super id, name, Types.Entities.WARRIOR

module.exports = Warrior
