Character = require("./character")

class Mob extends Character
  constructor: (id, kind) ->
    super id, kind
    @aggroRange = 1
    @isAggressive = true

module.exports = Mob
