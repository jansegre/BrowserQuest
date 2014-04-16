###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

_ = require("underscore")

Types =
  Messages:
    CREATE: 0
    LOGIN: 1
    WELCOME: 2
    SPAWN: 3
    DESPAWN: 4
    MOVE: 5
    LOOTMOVE: 6
    AGGRO: 7
    ATTACK: 8
    HIT: 9
    HURT: 10
    HEALTH: 11
    CHAT: 12
    LOOT: 13
    EQUIP: 14
    DROP: 15
    TELEPORT: 16
    DAMAGE: 17
    POPULATION: 18
    KILL: 19
    LIST: 20
    WHO: 21
    ZONE: 22
    DESTROY: 23
    HP: 24
    BLINK: 25
    OPEN: 26
    CHECK: 27
    PVP: 28
    GUILD: 29
    GUILDERROR: 30
    GUILDERRORTYPE:
      DOESNOTEXIST: 1
      BADNAME: 2
      ALREADYEXISTS: 3
      NOLEAVE: 4
      BADINVITE: 5
      GUILDRULES: 6
      IDWARNING: 7

    GUILDACTION:
      CONNECT: 8
      ONLINE: 9
      DISCONNECT: 10
      INVITE: 11
      LEAVE: 12
      CREATE: 13
      TALK: 14
      JOIN: 15
      POPULATION: 16

  Entities:
    WARRIOR: 1

    # Mobs
    RAT: 2
    SKELETON: 3
    GOBLIN: 4
    OGRE: 5
    SPECTRE: 6
    CRAB: 7
    BAT: 8
    WIZARD: 9
    EYE: 10
    SNAKE: 11
    SKELETON2: 12
    BOSS: 13
    DEATHKNIGHT: 14

    # Armors
    FIREFOX: 20
    CLOTHARMOR: 21
    LEATHERARMOR: 22
    MAILARMOR: 23
    PLATEARMOR: 24
    REDARMOR: 25
    GOLDENARMOR: 26

    # Objects
    FLASK: 35
    BURGER: 36
    CHEST: 37
    FIREPOTION: 38
    CAKE: 39

    # NPCs
    GUARD: 40
    KING: 41
    OCTOCAT: 42
    VILLAGEGIRL: 43
    VILLAGER: 44
    PRIEST: 45
    SCIENTIST: 46
    AGENT: 47
    RICK: 48
    NYAN: 49
    SORCERER: 50
    BEACHNPC: 51
    FORESTNPC: 52
    DESERTNPC: 53
    LAVANPC: 54
    CODER: 55

    # Weapons
    SWORD1: 60
    SWORD2: 61
    REDSWORD: 62
    GOLDENSWORD: 63
    MORNINGSTAR: 64
    AXE: 65
    BLUESWORD: 66

  Orientations:
    UP: 1
    DOWN: 2
    LEFT: 3
    RIGHT: 4

  Keys:
    ENTER: 13
    UP: 38
    DOWN: 40
    LEFT: 37
    RIGHT: 39
    W: 87
    A: 65
    S: 83
    D: 68
    SPACE: 32
    I: 73
    H: 72
    M: 77
    P: 80
    KEYPAD_4: 100
    KEYPAD_6: 102
    KEYPAD_8: 104
    KEYPAD_2: 98

kinds =
  warrior: [
    Types.Entities.WARRIOR
    "player"
  ]
  rat: [
    Types.Entities.RAT
    "mob"
    5
    2
  ]
  skeleton: [
    Types.Entities.SKELETON
    "mob"
    15
    8
  ]
  goblin: [
    Types.Entities.GOBLIN
    "mob"
    8
    5
  ]
  ogre: [
    Types.Entities.OGRE
    "mob"
    27
    12
  ]
  spectre: [
    Types.Entities.SPECTRE
    "mob"
    53
    21
  ]
  deathknight: [
    Types.Entities.DEATHKNIGHT
    "mob"
    70
    24
  ]
  crab: [
    Types.Entities.CRAB
    "mob"
    1
    1
  ]
  snake: [
    Types.Entities.SNAKE
    "mob"
    25
    10
  ]
  bat: [
    Types.Entities.BAT
    "mob"
    6
    3
  ]
  wizard: [
    Types.Entities.WIZARD
    "mob"
    7
    1
  ]
  eye: [
    Types.Entities.EYE
    "mob"
    45
    18
  ]
  skeleton2: [
    Types.Entities.SKELETON2
    "mob"
    38
    15
  ]
  boss: [
    Types.Entities.BOSS
    "mob"
    140
    48
  ]
  sword1: [
    Types.Entities.SWORD1
    "weapon"
  ]
  sword2: [
    Types.Entities.SWORD2
    "weapon"
  ]
  axe: [
    Types.Entities.AXE
    "weapon"
  ]
  redsword: [
    Types.Entities.REDSWORD
    "weapon"
  ]
  bluesword: [
    Types.Entities.BLUESWORD
    "weapon"
  ]
  goldensword: [
    Types.Entities.GOLDENSWORD
    "weapon"
  ]
  morningstar: [
    Types.Entities.MORNINGSTAR
    "weapon"
  ]
  firefox: [
    Types.Entities.FIREFOX
    "armor"
  ]
  clotharmor: [
    Types.Entities.CLOTHARMOR
    "armor"
  ]
  leatherarmor: [
    Types.Entities.LEATHERARMOR
    "armor"
  ]
  mailarmor: [
    Types.Entities.MAILARMOR
    "armor"
  ]
  platearmor: [
    Types.Entities.PLATEARMOR
    "armor"
  ]
  redarmor: [
    Types.Entities.REDARMOR
    "armor"
  ]
  goldenarmor: [
    Types.Entities.GOLDENARMOR
    "armor"
  ]
  flask: [
    Types.Entities.FLASK
    "object"
  ]
  cake: [
    Types.Entities.CAKE
    "object"
  ]
  burger: [
    Types.Entities.BURGER
    "object"
  ]
  chest: [
    Types.Entities.CHEST
    "object"
  ]
  firepotion: [
    Types.Entities.FIREPOTION
    "object"
  ]
  guard: [
    Types.Entities.GUARD
    "npc"
  ]
  villagegirl: [
    Types.Entities.VILLAGEGIRL
    "npc"
  ]
  villager: [
    Types.Entities.VILLAGER
    "npc"
  ]
  coder: [
    Types.Entities.CODER
    "npc"
  ]
  scientist: [
    Types.Entities.SCIENTIST
    "npc"
  ]
  priest: [
    Types.Entities.PRIEST
    "npc"
  ]
  king: [
    Types.Entities.KING
    "npc"
  ]
  rick: [
    Types.Entities.RICK
    "npc"
  ]
  nyan: [
    Types.Entities.NYAN
    "npc"
  ]
  sorcerer: [
    Types.Entities.SORCERER
    "npc"
  ]
  agent: [
    Types.Entities.AGENT
    "npc"
  ]
  octocat: [
    Types.Entities.OCTOCAT
    "npc"
  ]
  beachnpc: [
    Types.Entities.BEACHNPC
    "npc"
  ]
  forestnpc: [
    Types.Entities.FORESTNPC
    "npc"
  ]
  desertnpc: [
    Types.Entities.DESERTNPC
    "npc"
  ]
  lavanpc: [
    Types.Entities.LAVANPC
    "npc"
  ]
  getType: (kind) ->
    kinds[Types.getKindAsString(kind)][1]

  getMobExp: (kind) ->
    kinds[Types.getKindAsString(kind)][2]

  getMobLevel: (kind) ->
    kinds[Types.getKindAsString(kind)][3]

Types.rankedWeapons = [
  Types.Entities.SWORD1
  Types.Entities.SWORD2
  Types.Entities.AXE
  Types.Entities.MORNINGSTAR
  Types.Entities.BLUESWORD
  Types.Entities.REDSWORD
  Types.Entities.GOLDENSWORD
]
Types.rankedArmors = [
  Types.Entities.CLOTHARMOR
  Types.Entities.LEATHERARMOR
  Types.Entities.MAILARMOR
  Types.Entities.PLATEARMOR
  Types.Entities.REDARMOR
  Types.Entities.GOLDENARMOR
]
Types.expForLevel = [
  1
  2
  5
  16
  39
  81 # 10
  150
  256
  410
  625
  915
  1296
  1785
  2401
  3164
  4096 # 20
  5220
  6561
  8145
  10000
  12155
  14641
  17490
  20736
  24414
  28561 # 30
  33215
  38416
  44205
  50625
  57720
  65536
  74120
  83521
  93789
  104976 # 40
  117135
  130321
  144590
  160000
  176610
  194481
  213675
  234256
  256289
  279841 # 50
  304980
  331776
  360300
  390625
  422825
  456976
  493155
  531441
  571914
  614656 # 60
  659750
  707281
  757335
  810000
  865365
  923521
  984560
  1048576
  1115664
  1185921 # 70
  1259445
  1336336
  1416695
  1500625
  1588230
  1679616
  1774890
  1874161
  1977539
  2085136 # 80
  2197065
  2313441
  2434380
  2560000
  2690420
  2825761
  2966145
  3111696
  3262539
  3418801 # 90
  3580610
  3748096
  3921390
  4100625
  4285935
  4477456
  4675325
  4879681
  5090664
  5318416 # 100
  5553080
  5804801
  6083725
  6410000
  6765201
  7311616
  7890481
  8503056
  9150625
  9834496 # 110
  10556001
  11316496
  12117361
  12960000
  13845841
  14776336
  15752961
  16777216
  17850625
  18974736 # 120
  20151121
  21381376
  22667121
  24010000
  25411681
  26873856
  28398241
  29986576
  31640625
  33362176 # 130
  35153041
  37015056
  38950081
  40960000
  43046721
  45212176
  47458321
  49787136
  52200625
  54700816 # 140
  57289761
  59969536
  62742241
  65610000
  68574961
  71639296
  74805201
  78074896
  81450625
  84934656 # 150
  88529281
  92236816
  96059601
  100000000
  108243216
]

Types.getLevel = (exp) ->
  i = 1
  i = 1
  while i < 135
    return i  if exp < Types.expForLevel[i]
    i++
  135

Types.getWeaponRank = (weaponKind) ->
  _.indexOf Types.rankedWeapons, weaponKind

Types.getArmorRank = (armorKind) ->
  _.indexOf Types.rankedArmors, armorKind

Types.getMobExp = (mobKind) ->
  kinds.getMobExp mobKind

Types.getMobLevel = (mobKind) ->
  kinds.getMobLevel mobKind

Types.isPlayer = (kind) ->
  kinds.getType(kind) is "player"

Types.isMob = (kind) ->
  kinds.getType(kind) is "mob"

Types.isNpc = (kind) ->
  kinds.getType(kind) is "npc"

Types.isCharacter = (kind) ->
  Types.isMob(kind) or Types.isNpc(kind) or Types.isPlayer(kind)

Types.isArmor = (kind) ->
  kinds.getType(kind) is "armor"

Types.isWeapon = (kind) ->
  kinds.getType(kind) is "weapon"

Types.isObject = (kind) ->
  kinds.getType(kind) is "object"

Types.isChest = (kind) ->
  kind is Types.Entities.CHEST

Types.isItem = (kind) ->
  Types.isWeapon(kind) or Types.isArmor(kind) or (Types.isObject(kind) and not Types.isChest(kind))

Types.isHealingItem = (kind) ->
  kind is Types.Entities.FLASK or kind is Types.Entities.BURGER

Types.isExpendableItem = (kind) ->
  Types.isHealingItem(kind) or kind is Types.Entities.FIREPOTION or kind is Types.Entities.CAKE

Types.getKindFromString = (kind) ->
  kinds[kind][0]  if kind of kinds

Types.getKindAsString = (kind) ->
  for k of kinds
    return k if kinds[k][0] is kind

Types.forEachKind = (callback) ->
  for k of kinds
    callback kinds[k][0], k

Types.forEachArmor = (callback) ->
  Types.forEachKind (kind, kindName) ->
    callback kind, kindName if Types.isArmor(kind)

Types.forEachMobOrNpcKind = (callback) ->
  Types.forEachKind (kind, kindName) ->
    callback kind, kindName if Types.isMob(kind) or Types.isNpc(kind)

Types.forEachArmorKind = (callback) ->
  Types.forEachKind (kind, kindName) ->
    callback kind, kindName if Types.isArmor(kind)

Types.forEachWeaponKind = (callback) ->
  Types.forEachKind (kind, kindName) ->
    callback kind, kindName if Types.isWeapon(kind)

Types.getOrientationAsString = (orientation) ->
  switch orientation
    when Types.Orientations.LEFT
      return "left"
    when Types.Orientations.RIGHT
      return "right"
    when Types.Orientations.UP
      return "up"
    when Types.Orientations.DOWN
      return "down"

Types.getRandomItemKind = (item) ->
  all = _.union(@rankedWeapons, @rankedArmors)
  forbidden = [
    Types.Entities.SWORD1
    Types.Entities.CLOTHARMOR
  ]
  itemKinds = _.difference(all, forbidden)
  i = Math.floor(Math.random() * _.size(itemKinds))
  itemKinds[i]

Types.getMessageTypeAsString = (type) ->
  typeName = undefined
  _.each Types.Messages, (value, name) ->
    typeName = name  if value is type

  typeName = "UNKNOWN" unless typeName
  typeName

module.exports = Types
