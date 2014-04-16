Log = require("log")
_ = require("underscore")
fs = require("fs")
ws = require("./ws")
WorldServer = require("./worldserver")
Metrics = require("./metrics")
DatabaseSelector = require("./databaseselector")
Player = require("./player")

main = (config) ->
  console.log(JSON.stringify(config))
  global.log = switch config.debug_level
    when "error" then new Log(Log.ERROR)
    when "debug" then new Log(Log.DEBUG)
    when "info"  then new Log(Log.INFO)
  server = new ws.MultiVersionWebsocketServer(config.port, config.use_one_port, config.ip)
  metrics = (if config.metrics_enabled then new Metrics(config) else null)
  worlds = []
  lastTotalPlayers = 0
  checkPopulationInterval = setInterval(->
    if metrics and metrics.isReady
      metrics.updateWorldCount()
      metrics.getTotalPlayers (totalPlayers) ->
        if totalPlayers isnt lastTotalPlayers
          lastTotalPlayers = totalPlayers
          _.each worlds, (world) ->
            world.updatePopulation totalPlayers
  , 1000)

  log.info "Starting BrowserQuest game server..."
  selector = DatabaseSelector(config)
  databaseHandler = new selector(config)
  server.onConnect (connection) ->
    world = undefined # the one in which the player will be spawned
    connect = ->
      world.connect_callback new Player(connection, world, databaseHandler) if world

    if metrics
      metrics.getOpenWorldCount (open_world_count) ->

        # choose the least populated world among open worlds
        world = _.min(_.first(worlds, open_world_count), (w) ->
          w.playerCount
        )
        connect()

    else
      # simply fill each world sequentially until they are full
      world = _.find worlds, (world) ->
        world.playerCount < config.nb_players_per_world
      world.updatePopulation()
      connect()

  server.onError ->
    log.error Array::join.call(arguments_, ", ")

  onPopulationChange = ->
    metrics.updatePlayerCounters worlds, (totalPlayers) ->
      _.each worlds, (world) ->
        world.updatePopulation totalPlayers

    metrics.updateWorldDistribution getWorldDistribution(worlds)

  _.each _.range(config.nb_worlds), (i) ->
    world = new WorldServer("world" + (i + 1), config.nb_players_per_world, server, databaseHandler)
    world.run config.map_filepath
    worlds.push world
    if metrics
      world.onPlayerAdded onPopulationChange
      world.onPlayerRemoved onPopulationChange

  server.onRequestStatus ->
    JSON.stringify getWorldDistribution(worlds)

  if config.metrics_enabled
    metrics.ready ->
      onPopulationChange() # initialize all counters to 0 when the server starts

  process.on "uncaughtException", (e) ->
    # Display the full error stack, to aid debugging
    log.error "uncaughtException: " + e.stack

getWorldDistribution = (worlds) ->
  distribution = []
  _.each worlds, (world) ->
    distribution.push world.playerCount
  distribution

main require("./config")
