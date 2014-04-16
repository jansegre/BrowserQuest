###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

_ = require("underscore")

class Metrics
  constructor: (config) ->
    @config = config
    @client = new (require("memcache")).Client(config.memcached_port, config.memcached_host)
    @client.connect()
    @isReady = false
    @client.on "connect", =>
      log.info "Metrics enabled: memcached client connected to " + config.memcached_host + ":" + config.memcached_port
      @isReady = true
      @readyCallback() if @readyCallback

  ready: (@readyCallback) ->

  updatePlayerCounters: (worlds, updatedCallback) ->
    numServers = _.size(@config.game_servers)
    playerCount = _.reduce(worlds, (sum, world) ->
      sum + world.playerCount
    , 0)
    if @isReady

      # Set the number of players on this server
      @client.set "player_count_" + @config.server_name, playerCount, ->
        totalPlayers = 0

        # Recalculate the total number of players and set it
        _.each @config.game_servers, (server) =>
          @client.get "player_count_" + server.name, (error, result) =>
            count = (if result then parseInt(result, 10) else 0)
            totalPlayers += count
            numServers -= 1
            if numServers is 0
              @client.set "total_players", totalPlayers, ->
                updatedCallback totalPlayers  if updatedCallback
    else
      log.error "Memcached client not connected"

  updateWorldDistribution: (worlds) ->
    @client.set "world_distribution_" + @config.server_name, worlds

  updateWorldCount: ->
    @client.set "world_count_" + @config.server_name, @config.nb_worlds

  getOpenWorldCount: (callback) ->
    @client.get "world_count_" + @config.server_name, (error, result) ->
      callback result

  getTotalPlayers: (callback) ->
    @client.get "total_players", (error, result) ->
      callback result

module.exports = Metrics
