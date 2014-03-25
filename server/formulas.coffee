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
