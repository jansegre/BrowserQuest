Npc = require("./npc")
Types = require("../common/types")

NPCs = {}

class NPCs.Guard extends Npc
  constructor: (id) ->
    super id, Types.Entities.GUARD, 1

class NPCs.King extends Npc
  constructor: (id) ->
    super id, Types.Entities.KING, 1

class NPCs.Agent extends Npc
  constructor: (id) ->
    super id, Types.Entities.AGENT, 1

class NPCs.Rick extends Npc
  constructor: (id) ->
    super id, Types.Entities.RICK, 1

class NPCs.VillageGirl extends Npc
  constructor: (id) ->
    super id, Types.Entities.VILLAGEGIRL, 1

class NPCs.Villager extends Npc
  constructor: (id) ->
    super id, Types.Entities.VILLAGER, 1

class NPCs.Coder extends Npc
  constructor: (id) ->
    super id, Types.Entities.CODER, 1

class NPCs.Scientist extends Npc
  constructor: (id) ->
    super id, Types.Entities.SCIENTIST, 1

class NPCs.Nyan extends Npc
  constructor: (id) ->
    super id, Types.Entities.NYAN, 1
    @idleSpeed = 50

class NPCs.Sorcerer extends Npc
  constructor: (id) ->
    super id, Types.Entities.SORCERER, 1
    @idleSpeed = 150

class NPCs.Priest extends Npc
  constructor: (id) ->
    super id, Types.Entities.PRIEST, 1

class NPCs.BeachNpc extends Npc
  constructor: (id) ->
    super id, Types.Entities.BEACHNPC, 1

class NPCs.ForestNpc extends Npc
  constructor: (id) ->
    super id, Types.Entities.FORESTNPC, 1

class NPCs.DesertNpc extends Npc
  constructor: (id) ->
    super id, Types.Entities.DESERTNPC, 1

class NPCs.LavaNpc extends Npc
  constructor: (id) ->
    super id, Types.Entities.LAVANPC, 1

class NPCs.Octocat extends Npc
  constructor: (id) ->
    super id, Types.Entities.OCTOCAT, 1

module.exports = NPCs
