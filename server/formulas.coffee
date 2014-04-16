###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

Utils = require("./utils")

Formulas = {}
Formulas.dmg = (weaponLevel, armorLevel) ->
  dealt = weaponLevel * Utils.randomInt(5, 10)
  absorbed = armorLevel * Utils.randomInt(1, 3)
  dmg = dealt - absorbed

  #console.log("abs: "+absorbed+"   dealt: "+ dealt+"   dmg: "+ (dealt - absorbed));
  if dmg <= 0
    Utils.randomInt 0, 3
  else
    dmg

Formulas.hp = (armorLevel) ->
  hp = 80 + ((armorLevel - 1) * 30)
  hp

module.exports = Formulas
