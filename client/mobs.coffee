###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

Mob = require("./mob")
Timer = require("./timer")
Types = require("../common/types")

Mobs = {}

class Mobs.Rat extends Mob
  constructor: (id) ->
    super id, Types.Entities.RAT
    @moveSpeed = 350
    @idleSpeed = 700
    @shadowOffsetY = -2
    @isAggressive = false

class Mobs.Skeleton extends Mob
  constructor: (id) ->
    super id, Types.Entities.SKELETON
    @moveSpeed = 350
    @atkSpeed = 100
    @idleSpeed = 800
    @shadowOffsetY = 1
    @setAttackRate 1300

class Mobs.Skeleton2 extends Mob
  constructor: (id) ->
    super id, Types.Entities.SKELETON2
    @moveSpeed = 200
    @atkSpeed = 100
    @idleSpeed = 800
    @walkSpeed = 200
    @shadowOffsetY = 1
    @setAttackRate 1300

class Mobs.Spectre extends Mob
  constructor: (id) ->
    super id, Types.Entities.SPECTRE
    @moveSpeed = 150
    @atkSpeed = 50
    @idleSpeed = 200
    @walkSpeed = 200
    @shadowOffsetY = 1
    @setAttackRate 900

class Mobs.Deathknight extends Mob
  constructor: (id) ->
    super id, Types.Entities.DEATHKNIGHT
    @atkSpeed = 50
    @moveSpeed = 220
    @walkSpeed = 100
    @idleSpeed = 450
    @setAttackRate 800
    @aggroRange = 3

  idle: (orientation) ->
    unless @hasTarget()
      super Types.Orientations.DOWN
    else
      super orientation

class Mobs.Goblin extends Mob
  constructor: (id) ->
    super id, Types.Entities.GOBLIN
    @moveSpeed = 150
    @atkSpeed = 60
    @idleSpeed = 600
    @setAttackRate 700

class Mobs.Ogre extends Mob
  constructor: (id) ->
    super id, Types.Entities.OGRE
    @moveSpeed = 300
    @atkSpeed = 100
    @idleSpeed = 600

class Mobs.Crab extends Mob
  constructor: (id) ->
    super id, Types.Entities.CRAB
    @moveSpeed = 200
    @atkSpeed = 40
    @idleSpeed = 500

class Mobs.Snake extends Mob
  constructor: (id) ->
    super id, Types.Entities.SNAKE
    @moveSpeed = 200
    @atkSpeed = 40
    @idleSpeed = 250
    @walkSpeed = 100
    @shadowOffsetY = -4

class Mobs.Eye extends Mob
  constructor: (id) ->
    super id, Types.Entities.EYE
    @moveSpeed = 200
    @atkSpeed = 40
    @idleSpeed = 50

class Mobs.Bat extends Mob
  constructor: (id) ->
    super id, Types.Entities.BAT
    @moveSpeed = 120
    @atkSpeed = 90
    @idleSpeed = 90
    @walkSpeed = 85
    @isAggressive = false

class Mobs.Wizard extends Mob
  constructor: (id) ->
    super id, Types.Entities.WIZARD
    @moveSpeed = 200
    @atkSpeed = 100
    @idleSpeed = 150

class Mobs.Boss extends Mob
  constructor: (id) ->
    super id, Types.Entities.BOSS
    @moveSpeed = 300
    @atkSpeed = 50
    @idleSpeed = 400
    @atkRate = 2000
    @attackCooldown = new Timer(@atkRate)
    @aggroRange = 3

  idle: (orientation) ->
    unless @hasTarget()
      super Types.Orientations.DOWN
    else
      super orientation

module.exports = Mobs
